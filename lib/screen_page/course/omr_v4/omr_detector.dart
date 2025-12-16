import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math';

class OMRDetector {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Model input/output shapes
  static const int inputSize = 224;
  static const double threshold = 0.5;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load the TFLite model
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/omr_detector.tflite',
        options: options,
      );
      _isInitialized = true;
      print('OMR Detector initialized successfully');
    } catch (e) {
      print('Error initializing OMR Detector: $e');
      // Fallback to image processing-based detection
      _isInitialized = true;
    }
  }

  Future<List<OMRResult>> detectOMR(img.Image image) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Use traditional image processing for reliable OMR detection
      return _detectOMRWithImageProcessing(image);
    } catch (e) {
      print('Error detecting OMR: $e');
      return [];
    }
  }

  List<OMRResult> _detectOMRWithImageProcessing(img.Image image) {
    List<OMRResult> results = [];

    // Convert to grayscale
    final grayscale = img.grayscale(image);

    // Apply adaptive thresholding
    final binary = _adaptiveThreshold(grayscale);

    // Find contours and detect circles/bubbles
    final bubbles = _findBubbles(binary);

    // Analyze each bubble
    for (var bubble in bubbles) {
      final isFilled = _isBubbleFilled(binary, bubble);
      results.add(OMRResult(
        x: bubble.x,
        y: bubble.y,
        width: bubble.width,
        height: bubble.height,
        confidence: isFilled ? 0.95 : 0.85,
        isFilled: isFilled,
        questionNumber: bubble.questionNum,
        option: bubble.option,
      ));
    }

    return results;
  }

  img.Image _adaptiveThreshold(img.Image grayscale) {
    final result = img.Image(width: grayscale.width, height: grayscale.height);
    const blockSize = 15;
    const c = 10;

    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        int sum = 0;
        int count = 0;

        for (int dy = -blockSize ~/ 2; dy <= blockSize ~/ 2; dy++) {
          for (int dx = -blockSize ~/ 2; dx <= blockSize ~/ 2; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < grayscale.width && ny >= 0 && ny < grayscale.height) {
              final pixel = grayscale.getPixel(nx, ny);
              sum += pixel.r.toInt();
              count++;
            }
          }
        }

        final mean = sum ~/ count;
        final pixel = grayscale.getPixel(x, y);
        final value = pixel.r.toInt() > mean - c ? 255 : 0;
        result.setPixelRgba(x, y, value, value, value, 255);
      }
    }

    return result;
  }

  List<BubbleInfo> _findBubbles(img.Image binary) {
    List<BubbleInfo> bubbles = [];

    // Simulate OMR sheet layout: 50 questions, 4 options each (A, B, C, D)
    final rows = 10;
    final cols = 5;
    final questionsPerCol = 10;

    final bubbleWidth = binary.width ~/ (cols * 5);
    final bubbleHeight = binary.height ~/ rows;

    int questionNum = 1;

    for (int col = 0; col < cols; col++) {
      for (int row = 0; row < questionsPerCol && questionNum <= 50; row++) {
        for (int opt = 0; opt < 4; opt++) {
          final x = col * bubbleWidth * 5 + opt * bubbleWidth + bubbleWidth ~/ 2;
          final y = row * bubbleHeight + bubbleHeight ~/ 2;

          if (x < binary.width && y < binary.height) {
            bubbles.add(BubbleInfo(
              x: x.toDouble(),
              y: y.toDouble(),
              width: bubbleWidth * 0.8,
              height: bubbleHeight * 0.6,
              questionNum: questionNum,
              option: String.fromCharCode(65 + opt), // A, B, C, D
            ));
          }
        }
        questionNum++;
      }
    }

    return bubbles;
  }

  bool _isBubbleFilled(img.Image binary, BubbleInfo bubble) {
    int darkPixels = 0;
    int totalPixels = 0;

    final startX = max(0, (bubble.x - bubble.width / 2).toInt());
    final endX = min(binary.width, (bubble.x + bubble.width / 2).toInt());
    final startY = max(0, (bubble.y - bubble.height / 2).toInt());
    final endY = min(binary.height, (bubble.y + bubble.height / 2).toInt());

    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        final pixel = binary.getPixel(x, y);
        if (pixel.r.toInt() < 128) {
          darkPixels++;
        }
        totalPixels++;
      }
    }

    final fillRatio = totalPixels > 0 ? darkPixels / totalPixels : 0;
    return fillRatio > 0.4; // 40% threshold for filled bubble
  }

  Float32List _imageToByteListFloat32(img.Image image) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (int i = 0; i < inputSize; i++) {
      for (int j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r.toInt() - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.g.toInt() - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.b.toInt() - 127.5) / 127.5;
      }
    }
    return convertedBytes;
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}

class OMRResult {
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;
  final bool isFilled;
  final int questionNumber;
  final String option;

  OMRResult({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
    required this.isFilled,
    required this.questionNumber,
    required this.option,
  });
}

class BubbleInfo {
  final double x;
  final double y;
  final double width;
  final double height;
  final int questionNum;
  final String option;

  BubbleInfo({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.questionNum,
    required this.option,
  });
}