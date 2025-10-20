import 'dart:io';
import 'package:image/image.dart' as img;
import 'advanced_omr_processor.dart';
import 'perspective_corrector.dart';
import 'omr_database_manager.dart';

class BatchProcessor {
  static Future<BatchResult> processBatch(
      List<String> imagePaths,
      Exam exam, {
        bool usePerspectiveCorrection = true,
        double confidenceThreshold = 0.7,
      }) async {
    final results = <OMRResult>[];
    int successCount = 0;
    int failureCount = 0;

    for (final imagePath in imagePaths) {
      try {
        final result = await _processSingleImage(
          imagePath,
          exam,
          usePerspectiveCorrection: usePerspectiveCorrection,
          confidenceThreshold: confidenceThreshold,
        );

        if (result != null) {
          results.add(result);
          successCount++;
        } else {
          failureCount++;
        }
      } catch (e) {
        print('Error processing $imagePath: $e');
        failureCount++;
      }
    }

    return BatchResult(
      successfulResults: results,
      successCount: successCount,
      failureCount: failureCount,
    );
  }

  static Future<OMRResult?> _processSingleImage(
      String imagePath,
      Exam exam, {
        bool usePerspectiveCorrection = true,
        double confidenceThreshold = 0.7,
      }) async {
    final imageFile = img.decodeImage(await File(imagePath).readAsBytes());
    if (imageFile == null) return null;

    // Apply perspective correction
    img.Image processedImage = imageFile;
    if (usePerspectiveCorrection) {
      final corrected = PerspectiveCorrector.correctPerspective(imageFile);
      if (corrected != null) {
        processedImage = corrected;
      }
    }

    // Define bubble regions based on OMR template
    final bubbleRegions = _generateBubbleRegions(exam.totalQuestions);

    // Detect bubbles
    final detectionResult = AdvancedOMRProcessor.detectBubbles(
      processedImage,
      regions: bubbleRegions,
      useAdaptiveThreshold: true,
    );

    // Extract answers
    final answers = _extractAnswers(detectionResult, exam.totalQuestions);
    final setNumber = _extractSetNumber(detectionResult);
    final studentId = _extractStudentId(detectionResult);
    final mobileNumber = _extractMobileNumber(detectionResult);

    // Calculate confidence
    final confidence = _calculateOverallConfidence(detectionResult);

    if (confidence < confidenceThreshold) {
      return null; // Skip low-confidence results
    }

    // Calculate score
    final score = _calculateScore(answers, exam.correctAnswers);

    return OMRResult(
      examId: exam.id!,
      studentId: studentId,
      setNumber: setNumber,
      mobileNumber: mobileNumber,
      answers: answers,
      score: score,
      scannedAt: DateTime.now(),
      confidence: confidence,
    );
  }

  static List<BubbleRegion> _generateBubbleRegions(int totalQuestions) {
    final regions = <BubbleRegion>[];

    // Set number bubbles (0-9)
    for (int i = 0; i < 10; i++) {
      regions.add(BubbleRegion(
        x: 150 + i * 25,
        y: 80,
        width: 12,
        height: 12,
        identifier: 'SET_$i',
      ));
    }

    // Student ID bubbles (9 digits × 10 options)
    for (int digit = 0; digit < 9; digit++) {
      for (int num = 0; num < 10; num++) {
        regions.add(BubbleRegion(
          x: 150 + digit * 25,
          y: 130 + num * 20,
          width: 12,
          height: 12,
          identifier: 'ID_${digit}_$num',
        ));
      }
    }

    // Question bubbles
    final questionsPerColumn = 25;
    final columns = (totalQuestions / questionsPerColumn).ceil();

    for (int col = 0; col < columns; col++) {
      for (int q = 0; q < questionsPerColumn; q++) {
        final questionNum = col * questionsPerColumn + q + 1;
        if (questionNum > totalQuestions) break;

        for (int option = 0; option < 5; option++) {
          regions.add(BubbleRegion(
            x: 115 + col * 250 + option * 25,
            y: 600 + q * 30,
            width: 12,
            height: 12,
            identifier: 'Q${questionNum}_${String.fromCharCode(65 + option)}',
          ));
        }
      }
    }

    return regions;
  }

  static List<int> _extractAnswers(BubbleDetectionResult result, int totalQuestions) {
    final answers = List<int>.filled(totalQuestions, 0);

    for (int i = 0; i < totalQuestions; i++) {
      for (int option = 0; option < 5; option++) {
        final identifier = 'Q${i + 1}_${String.fromCharCode(65 + option)}';
        final bubble = result.getBubbleByIdentifier(identifier);

        if (bubble != null && bubble.isFilled) {
          answers[i] = 65 + option; // ASCII for 'A', 'B', etc.
          break;
        }
      }
    }

    return answers;
  }

  static int _extractSetNumber(BubbleDetectionResult result) {
    for (int i = 0; i < 10; i++) {
      final bubble = result.getBubbleByIdentifier('SET_$i');
      if (bubble != null && bubble.isFilled) {
        return i;
      }
    }
    return 0;
  }

  static String _extractStudentId(BubbleDetectionResult result) {
    final idDigits = List<String>.filled(9, '0');

    for (int digit = 0; digit < 9; digit++) {
      for (int num = 0; num < 10; num++) {
        final bubble = result.getBubbleByIdentifier('ID_${digit}_$num');
        if (bubble != null && bubble.isFilled) {
          idDigits[digit] = num.toString();
          break;
        }
      }
    }

    return idDigits.join();
  }

  static String _extractMobileNumber(BubbleDetectionResult result) {
    // Similar to student ID extraction
    // Implementation depends on your OMR template
    return '';
  }

  static double _calculateOverallConfidence(BubbleDetectionResult result) {
    if (result.detectedBubbles.isEmpty) return 0.0;

    final totalConfidence = result.detectedBubbles
        .map((bubble) => bubble.confidence)
        .reduce((a, b) => a + b);

    return totalConfidence / result.detectedBubbles.length;
  }

  static double _calculateScore(List<int> answers, List<String> correctAnswers) {
    int correct = 0;
    for (int i = 0; i < answers.length; i++) {
      if (i < correctAnswers.length &&
          String.fromCharCode(answers[i]) == correctAnswers[i]) {
        correct++;
      }
    }
    return (correct / answers.length) * 100;
  }
}

class BatchResult {
  final List<OMRResult> successfulResults;
  final int successCount;
  final int failureCount;

  BatchResult({
    required this.successfulResults,
    required this.successCount,
    required this.failureCount,
  });

  double get successRate => successCount / (successCount + failureCount);
}