import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import '../models/exam_result_model.dart';
import '../models/omr_sheet_model.dart';
import '../models/student_model.dart';

class ScanResult {
  final String? studentId;
  final String? mobileNumber;
  final int? setNumber;
  final List<String> detectedAnswers;
  final double confidence;
  final String? errorMessage;

  ScanResult({
    this.studentId,
    this.mobileNumber,
    this.setNumber,
    required this.detectedAnswers,
    required this.confidence,
    this.errorMessage,
  });
}

class OMRScannerService {
  final textRecognizer = TextRecognizer();

  // Bubble detection parameters
  static const double BUBBLE_MIN_RADIUS = 8.0;
  static const double BUBBLE_MAX_RADIUS = 15.0;
  static const double DARKNESS_THRESHOLD = 0.3;

  Future<ScanResult> scanOMRSheet(File imageFile, OMRSheet omrSheet) async {
    try {
      // Read and process image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Pre-process image
      final processedImage = _preprocessImage(image);

      // Extract text information (student ID, mobile number)
      final textData = await _extractTextData(imageFile);

      // Detect filled bubbles
      final answers = _detectAnswers(processedImage, omrSheet.numberOfQuestions);

      // Calculate confidence score
      final confidence = _calculateConfidence(answers);

      return ScanResult(
        studentId: textData['studentId'],
        mobileNumber: textData['mobileNumber'],
        setNumber: textData['setNumber'] != null ? int.tryParse(textData['setNumber']!) : null,
        detectedAnswers: answers,
        confidence: confidence,
      );
    } catch (e) {
      return ScanResult(
        detectedAnswers: [],
        confidence: 0.0,
        errorMessage: e.toString(),
      );
    }
  }

  img.Image _preprocessImage(img.Image image) {
    // Convert to grayscale
    final grayscale = img.grayscale(image);

    // Apply adaptive threshold
    final threshold = _adaptiveThreshold(grayscale);

    // Remove noise
    final denoised = img.gaussianBlur(threshold, radius: 1);

    return denoised;
  }

  img.Image _adaptiveThreshold(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel);

        // Simple threshold - can be improved with adaptive methods
        final newPixel = luminance > 128 ? img.ColorRgb8(255, 255, 255) : img.ColorRgb8(0, 0, 0);
        result.setPixel(x, y, newPixel);
      }
    }

    return result;
  }

  Future<Map<String, String?>> _extractTextData(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    String? studentId;
    String? mobileNumber;
    String? setNumber;

    // Pattern matching for student ID and mobile number
    final studentIdPattern = RegExp(r'\b\d{10}\b');
    final mobilePattern = RegExp(r'\b\d{11}\b');
    final setPattern = RegExp(r'SET.*?(\d)');

    for (TextBlock block in recognizedText.blocks) {
      final text = block.text;

      // Extract student ID
      if (studentId == null) {
        final match = studentIdPattern.firstMatch(text);
        if (match != null) {
          studentId = match.group(0);
        }
      }

      // Extract mobile number
      if (mobileNumber == null) {
        final match = mobilePattern.firstMatch(text);
        if (match != null) {
          mobileNumber = match.group(0);
        }
      }

      // Extract set number
      if (setNumber == null) {
        final match = setPattern.firstMatch(text);
        if (match != null) {
          setNumber = match.group(1);
        }
      }
    }

    return {
      'studentId': studentId,
      'mobileNumber': mobileNumber,
      'setNumber': setNumber,
    };
  }

  List<String> _detectAnswers(img.Image image, int numberOfQuestions) {
    final answers = List<String>.filled(numberOfQuestions, '');

    // Define regions for answer bubbles based on standard OMR layout
    // This is a simplified version - in production, you'd need precise coordinates
    final answerRegions = _getAnswerRegions(image.width, image.height, numberOfQuestions);

    for (int i = 0; i < numberOfQuestions; i++) {
      final region = answerRegions[i];
      final detectedOption = _detectFilledBubble(image, region);
      answers[i] = detectedOption;
    }

    return answers;
  }

  List<AnswerRegion> _getAnswerRegions(int imageWidth, int imageHeight, int questions) {
    final regions = <AnswerRegion>[];

    // Calculate positions based on standard 3-column layout
    final questionsPerColumn = (questions / 3).ceil();
    final columnWidth = imageWidth / 3;
    final startY = imageHeight * 0.5; // Start from middle of page
    final rowHeight = (imageHeight * 0.4) / questionsPerColumn;

    for (int i = 0; i < questions; i++) {
      final column = i ~/ questionsPerColumn;
      final row = i % questionsPerColumn;

      final x = column * columnWidth + 50;
      final y = startY + row * rowHeight;

      regions.add(AnswerRegion(
        questionNumber: i + 1,
        x: x,
        y: y,
        width: columnWidth - 100,
        height: rowHeight - 5,
      ));
    }

    return regions;
  }

  String _detectFilledBubble(img.Image image, AnswerRegion region) {
    final options = ['A', 'B', 'C', 'D'];
    final bubbleWidth = region.width / 4;

    String detectedAnswer = '';
    double maxDarkness = 0;

    for (int i = 0; i < options.length; i++) {
      final bubbleX = region.x + i * bubbleWidth;
      final darkness = _calculateBubbleDarkness(
        image,
        bubbleX.toInt(),
        region.y.toInt(),
        bubbleWidth.toInt(),
        region.height.toInt(),
      );

      if (darkness > DARKNESS_THRESHOLD && darkness > maxDarkness) {
        maxDarkness = darkness;
        detectedAnswer = options[i];
      }
    }

    return detectedAnswer;
  }

  double _calculateBubbleDarkness(img.Image image, int x, int y, int width, int height) {
    int darkPixels = 0;
    int totalPixels = 0;

    for (int dy = 0; dy < height; dy++) {
      for (int dx = 0; dx < width; dx++) {
        final px = x + dx;
        final py = y + dy;

        if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
          final pixel = image.getPixel(px, py);
          final luminance = img.getLuminance(pixel);

          if (luminance < 128) {
            darkPixels++;
          }
          totalPixels++;
        }
      }
    }

    return totalPixels > 0 ? darkPixels / totalPixels : 0;
  }

  double _calculateConfidence(List<String> answers) {
    int validAnswers = answers.where((a) => a.isNotEmpty).length;
    return validAnswers / answers.length;
  }

  void dispose() {
    textRecognizer.close();
  }
}

class AnswerRegion {
  final int questionNumber;
  final double x;
  final double y;
  final double width;
  final double height;

  AnswerRegion({
    required this.questionNumber,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}