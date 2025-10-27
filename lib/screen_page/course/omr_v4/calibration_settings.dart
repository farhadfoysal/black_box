// import 'package:opencv_dart/opencv_dart.dart' as cv;
//
// /// Enum for different OMR sheet types
// enum OMRSheetType {
//   type1_40Questions,
//   type2_40Questions,
//   unknown
// }
//
// /// Configuration for OMR processing
// class OMRConfig {
//   final double bubbleFillThreshold;
//   final double minBubbleArea;
//   final double maxBubbleArea;
//   final double minCircularity;
//   final int expectedBubblesPerRow;
//
//   OMRConfig({
//     this.bubbleFillThreshold = 0.35,
//     this.minBubbleArea = 50.0,
//     this.maxBubbleArea = 1000.0,
//     this.minCircularity = 0.6,
//     this.expectedBubblesPerRow = 4,
//   });
// }
//
// /// Enhanced configuration with sheet-specific settings
// class EnhancedOMRConfig {
//   final OMRSheetType sheetType;
//   final double bubbleFillThreshold;
//   final double minBubbleArea;
//   final double maxBubbleArea;
//   final double minCircularity;
//   final int totalQuestions;
//   final int optionsPerQuestion;
//   final List<String> optionLabels;
//
//   EnhancedOMRConfig({
//     this.sheetType = OMRSheetType.unknown,
//     this.bubbleFillThreshold = 0.35,
//     this.minBubbleArea = 50.0,
//     this.maxBubbleArea = 1000.0,
//     this.minCircularity = 0.65,
//     this.totalQuestions = 40,
//     this.optionsPerQuestion = 4,
//     this.optionLabels = const ['A', 'B', 'C', 'D'],
//   });
//
//   factory EnhancedOMRConfig.forType(OMRSheetType type) {
//     switch (type) {
//       case OMRSheetType.type1_40Questions:
//         return EnhancedOMRConfig(
//           sheetType: type,
//           totalQuestions: 40,
//           optionsPerQuestion: 4,
//           bubbleFillThreshold: 0.40,
//           minBubbleArea: 80.0,
//           maxBubbleArea: 800.0,
//         );
//       case OMRSheetType.type2_40Questions:
//         return EnhancedOMRConfig(
//           sheetType: type,
//           totalQuestions: 40,
//           optionsPerQuestion: 4,
//           bubbleFillThreshold: 0.38,
//           minBubbleArea: 70.0,
//           maxBubbleArea: 900.0,
//         );
//       default:
//         return EnhancedOMRConfig();
//     }
//   }
// }
//
// /// Represents a detected bubble/circle on the OMR sheet
// class Bubble {
//   final cv.Rect boundingBox;
//   final double fillPercentage;
//   final int row;
//   final int col;
//
//   Bubble({
//     required this.boundingBox,
//     required this.fillPercentage,
//     required this.row,
//     required this.col,
//   });
// }
//
// /// Enhanced bubble detection with confidence score
// class EnhancedBubble {
//   final cv.Rect boundingBox;
//   final cv.Point center;
//   final double fillPercentage;
//   final double confidence;
//   final int row;
//   final int col;
//   final double area;
//
//   EnhancedBubble({
//     required this.boundingBox,
//     required this.center,
//     required this.fillPercentage,
//     required this.confidence,
//     required this.row,
//     required this.col,
//     required this.area,
//   });
//
//   bool get isFilled => fillPercentage > 0.35;
// }
//
// /// Represents the extracted student information
// class StudentInfo {
//   final String? studentId;
//   final String? mobileNumber;
//   final String? setNumber;
//   final String? rollNumber;
//
//   StudentInfo({
//     this.studentId,
//     this.mobileNumber,
//     this.setNumber,
//     this.rollNumber,
//   });
// }
//
// /// Enhanced student info with confidence
// class EnhancedStudentInfo {
//   final String? studentId;
//   final String? mobileNumber;
//   final String? setNumber;
//   final String? rollNumber;
//   final Map<String, double> confidenceScores;
//
//   EnhancedStudentInfo({
//     this.studentId,
//     this.mobileNumber,
//     this.setNumber,
//     this.rollNumber,
//     this.confidenceScores = const {},
//   });
// }
//
// /// Represents a single answer
// class Answer {
//   final int questionNumber;
//   final String? selectedOption;
//   final bool isMultipleMarked;
//
//   Answer({
//     required this.questionNumber,
//     this.selectedOption,
//     this.isMultipleMarked = false,
//   });
// }
//
// /// Enhanced answer with more metadata
// class EnhancedAnswer {
//   final int questionNumber;
//   final String? selectedOption;
//   final bool isMultipleMarked;
//   final double confidence;
//   final List<String> detectedOptions;
//
//   EnhancedAnswer({
//     required this.questionNumber,
//     this.selectedOption,
//     this.isMultipleMarked = false,
//     this.confidence = 0.0,
//     this.detectedOptions = const [],
//   });
// }
//
// /// Main result class containing all extracted data
// class OMRResult {
//   final StudentInfo studentInfo;
//   final List<Answer> answers;
//   final cv.Mat? processedImage;
//   final bool isValid;
//   final String? errorMessage;
//
//   OMRResult({
//     required this.studentInfo,
//     required this.answers,
//     this.processedImage,
//     this.isValid = true,
//     this.errorMessage,
//   });
//
//   Map<int, String?> get answersMap {
//     return {for (var ans in answers) ans.questionNumber: ans.selectedOption};
//   }
//
//   List<int> get unansweredQuestions {
//     return answers
//         .where((ans) => ans.selectedOption == null && !ans.isMultipleMarked)
//         .map((ans) => ans.questionNumber)
//         .toList();
//   }
//
//   List<int> get multipleMarkedQuestions {
//     return answers
//         .where((ans) => ans.isMultipleMarked)
//         .map((ans) => ans.questionNumber)
//         .toList();
//   }
// }
//
// /// Enhanced result with diagnostics
// class EnhancedOMRResult {
//   final EnhancedStudentInfo studentInfo;
//   final List<EnhancedAnswer> answers;
//   final OMRSheetType detectedSheetType;
//   final cv.Mat? processedImage;
//   final cv.Mat? alignedImage;
//   final cv.Mat? debugImage;
//   final bool isValid;
//   final String? errorMessage;
//   final double overallConfidence;
//   final Map<String, dynamic> diagnostics;
//
//   EnhancedOMRResult({
//     required this.studentInfo,
//     required this.answers,
//     this.detectedSheetType = OMRSheetType.unknown,
//     this.processedImage,
//     this.alignedImage,
//     this.debugImage,
//     this.isValid = true,
//     this.errorMessage,
//     this.overallConfidence = 0.0,
//     this.diagnostics = const {},
//   });
//
//   Map<int, String?> get answersMap {
//     return {for (var ans in answers) ans.questionNumber: ans.selectedOption};
//   }
//
//   List<int> get unansweredQuestions {
//     return answers
//         .where((ans) => ans.selectedOption == null && !ans.isMultipleMarked)
//         .map((ans) => ans.questionNumber)
//         .toList();
//   }
//
//   List<int> get multipleMarkedQuestions {
//     return answers
//         .where((ans) => ans.isMultipleMarked)
//         .map((ans) => ans.questionNumber)
//         .toList();
//   }
//
//   List<int> get lowConfidenceQuestions {
//     return answers
//         .where((ans) => ans.confidence < 0.7)
//         .map((ans) => ans.questionNumber)
//         .toList();
//   }
// }
//
//
//
//
// // import 'dart:typed_data';
// // import 'package:opencv_dart/opencv_dart.dart' as cv;
// // import 'dart:math' as math;
// //
// // /// Calibration settings for fine-tuning OMR detection
// // class CalibrationSettings {
// //   double bubbleFillThreshold;
// //   double minBubbleArea;
// //   double maxBubbleArea;
// //   double minCircularity;
// //   int adaptiveThresholdBlockSize;
// //   int adaptiveThresholdC;
// //   double gaussianBlurSize;
// //
// //   CalibrationSettings({
// //     this.bubbleFillThreshold = 0.35,
// //     this.minBubbleArea = 50.0,
// //     this.maxBubbleArea = 1000.0,
// //     this.minCircularity = 0.65,
// //     this.adaptiveThresholdBlockSize = 11,
// //     this.adaptiveThresholdC = 2,
// //     this.gaussianBlurSize = 5.0,
// //   });
// //
// //   Map<String, dynamic> toJson() => {
// //     'bubbleFillThreshold': bubbleFillThreshold,
// //     'minBubbleArea': minBubbleArea,
// //     'maxBubbleArea': maxBubbleArea,
// //     'minCircularity': minCircularity,
// //     'adaptiveThresholdBlockSize': adaptiveThresholdBlockSize,
// //     'adaptiveThresholdC': adaptiveThresholdC,
// //     'gaussianBlurSize': gaussianBlurSize,
// //   };
// //
// //   factory CalibrationSettings.fromJson(Map<String, dynamic> json) {
// //     return CalibrationSettings(
// //       bubbleFillThreshold: json['bubbleFillThreshold'] ?? 0.35,
// //       minBubbleArea: json['minBubbleArea'] ?? 50.0,
// //       maxBubbleArea: json['maxBubbleArea'] ?? 1000.0,
// //       minCircularity: json['minCircularity'] ?? 0.65,
// //       adaptiveThresholdBlockSize: json['adaptiveThresholdBlockSize'] ?? 11,
// //       adaptiveThresholdC: json['adaptiveThresholdC'] ?? 2,
// //       gaussianBlurSize: json['gaussianBlurSize'] ?? 5.0,
// //     );
// //   }
// // }
// //
// // /// Calibration service for testing and fine-tuning
// // class OMRCalibrationService {
// //   CalibrationSettings settings;
// //
// //   OMRCalibrationService({CalibrationSettings? settings})
// //       : settings = settings ?? CalibrationSettings();
// //
// //   /// Test different threshold values and return results
// //   Future<Map<double, int>> testThresholdRange(
// //       Uint8List imageBytes,
// //       double minThreshold,
// //       double maxThreshold,
// //       double step,
// //       ) async {
// //     final results = <double, int>{};
// //     final mat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
// //     final preprocessed = await _preprocessImage(mat);
// //
// //     for (double threshold = minThreshold;
// //     threshold <= maxThreshold;
// //     threshold += step) {
// //       settings.bubbleFillThreshold = threshold;
// //       final bubbles = await _detectBubbles(preprocessed);
// //       final filled = bubbles.where((b) =>
// //       b?.fillPercentage > threshold).length;
// //       results[threshold] = filled;
// //     }
// //
// //     return results;
// //   }
// //
// //   /// Test different circularity values
// //   Future<Map<double, int>> testCircularityRange(
// //       Uint8List imageBytes,
// //       double minCirc,
// //       double maxCirc,
// //       double step,
// //       ) async {
// //     final results = <double, int>{};
// //     final mat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
// //     final preprocessed = await _preprocessImage(mat);
// //
// //     for (double circ = minCirc; circ <= maxCirc; circ += step) {
// //       settings.minCircularity = circ;
// //       final bubbles = await _detectBubbles(preprocessed);
// //       results[circ] = bubbles.length;
// //     }
// //
// //     return results;
// //   }
// //
// //   /// Analyze a sample sheet and suggest optimal settings
// //   Future<CalibrationSettings> autoCalibrate(Uint8List imageBytes) async {
// //     final mat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
// //     final preprocessed = await _preprocessImage(mat);
// //
// //     // Detect all contours
// //     final contours = cv.findContours(
// //       preprocessed,
// //       cv.RETR_EXTERNAL,
// //       cv.CHAIN_APPROX_SIMPLE,
// //     );
// //
// //     // Analyze bubble characteristics
// //     final bubbleAreas = <double>[];
// //     final circularities = <double>[];
// //     final fillPercentages = <double>[];
// //
// //     for (final contour in contours.$1) {
// //       final area = cv.contourArea(contour);
// //       if (area < 30 || area > 2000) continue;
// //
// //       final perimeter = cv.arcLength(contour, true);
// //       final circularity = 4 * math.pi * area / (perimeter * perimeter);
// //
// //       if (circularity > 0.5) {
// //         bubbleAreas.add(area);
// //         circularities.add(circularity);
// //
// //         // Calculate fill percentage
// //         final bbox = cv.boundingRect(contour);
// //         final mask = cv.Mat.zeros(
// //           preprocessed.rows,
// //           preprocessed.cols,
// //           cv.MatType.CV_8UC1,
// //         );
// //         cv.drawContours(mask, [contour] as cv.Contours, -1, cv.Scalar.all(255), thickness: -1);
// //
// //         final roi = preprocessed.region(bbox);
// //         final maskRoi = mask.region(bbox);
// //
// //         final filled = cv.countNonZero(cv.bitwiseAND(roi, maskRoi));
// //         final total = cv.countNonZero(maskRoi);
// //
// //         if (total > 0) {
// //           fillPercentages.add(filled / total);
// //         }
// //       }
// //     }
// //
// //     // Calculate optimal settings
// //     if (bubbleAreas.isEmpty) {
// //       return settings; // Return default if no bubbles found
// //     }
// //
// //     bubbleAreas.sort();
// //     circularities.sort();
// //     fillPercentages.sort();
// //
// //     // Use median and percentiles for robust estimates
// //     final medianArea = bubbleAreas[bubbleAreas.length ~/ 2];
// //     final minArea = bubbleAreas[(bubbleAreas.length * 0.1).toInt()];
// //     final maxArea = bubbleAreas[(bubbleAreas.length * 0.9).toInt()];
// //
// //     final medianCirc = circularities[circularities.length ~/ 2];
// //     final minCirc = circularities[(circularities.length * 0.2).toInt()];
// //
// //     // Find a good threshold between filled and empty bubbles
// //     final medianFill = fillPercentages[fillPercentages.length ~/ 2];
// //     final threshold = medianFill * 0.7; // 70% of median fill
// //
// //     return CalibrationSettings(
// //       minBubbleArea: math.max(minArea * 0.8, 40.0),
// //       maxBubbleArea: math.min(maxArea * 1.2, 1500.0),
// //       minCircularity: math.max(minCirc * 0.9, 0.5),
// //       bubbleFillThreshold: threshold.clamp(0.25, 0.45),
// //     );
// //   }
// //
// //   /// Generate a detailed calibration report
// //   Future<Map<String, dynamic>> generateCalibrationReport(
// //       Uint8List imageBytes,
// //       ) async {
// //     final mat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
// //     final preprocessed = await _preprocessImage(mat);
// //     final bubbles = await _detectBubbles(preprocessed);
// //
// //     // Separate filled and empty bubbles
// //     final filled = bubbles.where((b) =>
// //     b?.fillPercentage > settings.bubbleFillThreshold).toList();
// //     final empty = bubbles.where((b) =>
// //     b.fillPercentage <= settings.bubbleFillThreshold).toList();
// //
// //     // Calculate statistics
// //     final avgFillFilled = filled.isEmpty ? 0.0 :
// //     filled.map((b) => b.fillPercentage).reduce((a, b) => a + b) / filled.length;
// //     final avgFillEmpty = empty.isEmpty ? 0.0 :
// //     empty.map((b) => b.fillPercentage).reduce((a, b) => a + b) / empty.length;
// //
// //     final avgAreaFilled = filled.isEmpty ? 0.0 :
// //     filled.map((b) => b.area).reduce((a, b) => a + b) / filled.length;
// //     final avgAreaEmpty = empty.isEmpty ? 0.0 :
// //     empty.map((b) => b.area).reduce((a, b) => a + b) / empty.length;
// //
// //     return {
// //       'totalBubblesDetected': bubbles.length,
// //       'filledBubbles': filled.length,
// //       'emptyBubbles': empty.length,
// //       'avgFillPercentageFilled': avgFillFilled,
// //       'avgFillPercentageEmpty': avgFillEmpty,
// //       'avgAreaFilled': avgAreaFilled,
// //       'avgAreaEmpty': avgAreaEmpty,
// //       'separationQuality': _calculateSeparationQuality(filled, empty),
// //       'currentSettings': settings.toJson(),
// //     };
// //   }
// //
// //   double _calculateSeparationQuality(
// //       List<EnhancedBubble> filled,
// //       List<EnhancedBubble> empty,
// //       ) {
// //     if (filled.isEmpty || empty.isEmpty) return 0.0;
// //
// //     final avgFilled = filled.map((b) => b.fillPercentage)
// //         .reduce((a, b) => a + b) / filled.length;
// //     final avgEmpty = empty.map((b) => b.fillPercentage)
// //         .reduce((a, b) => a + b) / empty.length;
// //
// //     // Good separation means large difference between filled and empty
// //     final separation = (avgFilled - avgEmpty).abs();
// //
// //     // Normalize to 0-1 scale (0.5 difference is excellent)
// //     return (separation / 0.5).clamp(0.0, 1.0);
// //   }
// //
// //   /// Visualize calibration by highlighting bubbles
// //   Future<cv.Mat> visualizeCalibration(
// //       Uint8List imageBytes,
// //       {bool showFillPercentage = true}
// //       ) async {
// //     final mat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
// //     final preprocessed = await _preprocessImage(mat);
// //     final bubbles = await _detectBubbles(preprocessed);
// //
// //     final output = mat.clone();
// //
// //     for (final bubble in bubbles) {
// //       final isFilled = bubble.fillPercentage > settings.bubbleFillThreshold;
// //       final color = isFilled
// //           ? cv.Scalar(0, 255, 0, 0)  // Green for filled
// //           : cv.Scalar(0, 0, 255, 0); // Red for empty
// //
// //       // Draw rectangle
// //       cv.rectangle(output, bubble.boundingBox, color, thickness: 2);
// //
// //       if (showFillPercentage) {
// //         // Draw fill percentage text
// //         final text = '${(bubble.fillPercentage * 100).toStringAsFixed(0)}%';
// //         cv.putText(
// //           output,
// //           text,
// //           cv.Point(
// //             bubble.boundingBox.x,
// //             bubble.boundingBox.y - 5,
// //           ),
// //           cv.FONT_HERSHEY_SIMPLEX,
// //           0.4,
// //           color,
// //           thickness: 1,
// //         );
// //       }
// //     }
// //
// //     return output;
// //   }
// //
// //   Future<cv.Mat> _preprocessImage(cv.Mat image) async {
// //     final gray = cv.cvtColor(image, cv.COLOR_BGR2GRAY);
// //     final blurred = cv.GaussianBlur(
// //       gray,
// //       (settings.gaussianBlurSize.toInt(), settings.gaussianBlurSize.toInt()),
// //       0,
// //     );
// //
// //     final thresh = cv.adaptiveThreshold(
// //       blurred,
// //       255,
// //       cv.ADAPTIVE_THRESH_GAUSSIAN_C,
// //       cv.THRESH_BINARY_INV,
// //       settings.adaptiveThresholdBlockSize,
// //       settings.adaptiveThresholdC,
// //     );
// //
// //     return thresh;
// //   }
// //
// //   Future<List<EnhancedBubble>> _detectBubbles(cv.Mat region) async {
// //     final contours = cv.findContours(
// //       region,
// //       cv.RETR_EXTERNAL,
// //       cv.CHAIN_APPROX_SIMPLE,
// //     );
// //
// //     final bubbles = <EnhancedBubble>[];
// //
// //     for (final contour in contours.$1) {
// //       final area = cv.contourArea(contour);
// //
// //       if (area < settings.minBubbleArea || area > settings.maxBubbleArea) {
// //         continue;
// //       }
// //
// //       final perimeter = cv.arcLength(contour, true);
// //       final circularity = 4 * math.pi * area / (perimeter * perimeter);
// //
// //       if (circularity < settings.minCircularity) {
// //         continue;
// //       }
// //
// //       final bbox = cv.boundingRect(contour);
// //       final moments = cv.moments(contour);
// //       final center = cv.Point(
// //         (moments.m10 / moments.m00).toInt(),
// //         (moments.m01 / moments.m00).toInt(),
// //       );
// //
// //       // Calculate fill percentage
// //       final mask = cv.Mat.zeros(region.rows, region.cols, cv.MatType.CV_8UC1);
// //       cv.drawContours(mask, [contour], -1, cv.Scalar.all(255), thickness: -1);
// //
// //       final roi = region.region(bbox);
// //       final maskRoi = mask.region(bbox);
// //
// //       final filled = cv.countNonZero(cv.bitwise_and(roi, maskRoi));
// //       final total = cv.countNonZero(maskRoi);
// //       final fillPercentage = total > 0 ? filled / total : 0.0;
// //
// //       final confidence = (circularity + (fillPercentage > 0.3 ? 1.0 : 0.0)) / 2;
// //
// //       final row = bbox.y ~/ (bbox.height + 10);
// //       final col = bbox.x ~/ (bbox.width + 10);
// //
// //       bubbles.add(EnhancedBubble(
// //         boundingBox: bbox,
// //         center: center,
// //         fillPercentage: fillPercentage,
// //         confidence: confidence,
// //         row: row,
// //         col: col,
// //         area: area,
// //       ));
// //     }
// //
// //     return bubbles;
// //   }
// // }
// //
// // /// Test suite for validating OMR accuracy
// // class OMRTestSuite {
// //   final EnhancedOMRScannerService scanner;
// //
// //   OMRTestSuite({EnhancedOMRScannerService? scanner})
// //       : scanner = scanner ?? EnhancedOMRScannerService();
// //
// //   /// Test against known answer key
// //   Future<TestResult> testAccuracy(
// //       Uint8List imageBytes,
// //       Map<int, String> answerKey,
// //       ) async {
// //     final result = await scanner.processOMRSheet(imageBytes);
// //
// //     if (!result.isValid) {
// //       return TestResult(
// //         totalQuestions: answerKey.length,
// //         correct: 0,
// //         incorrect: 0,
// //         missed: answerKey.length,
// //         accuracy: 0.0,
// //         errors: ['Failed to process OMR sheet'],
// //       );
// //     }
// //
// //     int correct = 0;
// //     int incorrect = 0;
// //     int missed = 0;
// //     final errors = <String>[];
// //     final detailedResults = <int, ComparisonResult>{};
// //
// //     for (final entry in answerKey.entries) {
// //       final questionNum = entry.key;
// //       final expectedAnswer = entry.value;
// //
// //       final answer = result.answers.firstWhere(
// //             (a) => a.questionNumber == questionNum,
// //         orElse: () => EnhancedAnswer(questionNumber: questionNum),
// //       );
// //
// //       if (answer.isMultipleMarked) {
// //         incorrect++;
// //         errors.add('Q$questionNum: Multiple answers marked');
// //         detailedResults[questionNum] = ComparisonResult(
// //           questionNumber: questionNum,
// //           expected: expectedAnswer,
// //           detected: 'MULTIPLE',
// //           isCorrect: false,
// //           confidence: answer.confidence,
// //         );
// //       } else if (answer.selectedOption == null) {
// //         missed++;
// //         errors.add('Q$questionNum: No answer detected (expected $expectedAnswer)');
// //         detailedResults[questionNum] = ComparisonResult(
// //           questionNumber: questionNum,
// //           expected: expectedAnswer,
// //           detected: null,
// //           isCorrect: false,
// //           confidence: 0.0,
// //         );
// //       } else if (answer.selectedOption == expectedAnswer) {
// //         correct++;
// //         detailedResults[questionNum] = ComparisonResult(
// //           questionNumber: questionNum,
// //           expected: expectedAnswer,
// //           detected: answer.selectedOption,
// //           isCorrect: true,
// //           confidence: answer.confidence,
// //         );
// //       } else {
// //         incorrect++;
// //         errors.add('Q$questionNum: Expected $expectedAnswer, got ${answer.selectedOption}');
// //         detailedResults[questionNum] = ComparisonResult(
// //           questionNumber: questionNum,
// //           expected: expectedAnswer,
// //           detected: answer.selectedOption,
// //           isCorrect: false,
// //           confidence: answer.confidence,
// //         );
// //       }
// //     }
// //
// //     final accuracy = correct / answerKey.length;
// //
// //     return TestResult(
// //       totalQuestions: answerKey.length,
// //       correct: correct,
// //       incorrect: incorrect,
// //       missed: missed,
// //       accuracy: accuracy,
// //       errors: errors,
// //       detailedResults: detailedResults,
// //       overallConfidence: result.overallConfidence,
// //     );
// //   }
// //
// //   /// Batch test multiple sheets
// //   Future<BatchTestResult> batchTest(
// //       List<Uint8List> images,
// //       List<Map<int, String>> answerKeys,
// //       ) async {
// //     assert(images.length == answerKeys.length,
// //     'Number of images must match number of answer keys');
// //
// //     final results = <TestResult>[];
// //
// //     for (int i = 0; i < images.length; i++) {
// //       final result = await testAccuracy(images[i], answerKeys[i]);
// //       results.add(result);
// //     }
// //
// //     // Calculate batch statistics
// //     final totalSheets = results.length;
// //     final avgAccuracy = results.isEmpty ? 0.0 :
// //     results.map((r) => r.accuracy).reduce((a, b) => a + b) / totalSheets;
// //
// //     final totalCorrect = results.map((r) => r.correct).reduce((a, b) => a + b);
// //     final totalQuestions = results.map((r) => r.totalQuestions).reduce((a, b) => a + b);
// //
// //     return BatchTestResult(
// //       totalSheets: totalSheets,
// //       averageAccuracy: avgAccuracy,
// //       totalCorrect: totalCorrect,
// //       totalQuestions: totalQuestions,
// //       individualResults: results,
// //     );
// //   }
// //
// //   /// Generate comprehensive test report
// //   String generateTestReport(TestResult result) {
// //     final buffer = StringBuffer();
// //
// //     buffer.writeln('=' * 60);
// //     buffer.writeln('OMR ACCURACY TEST REPORT');
// //     buffer.writeln('=' * 60);
// //     buffer.writeln();
// //
// //     buffer.writeln('Overall Results:');
// //     buffer.writeln('  Total Questions: ${result.totalQuestions}');
// //     buffer.writeln('  Correct: ${result.correct} ✓');
// //     buffer.writeln('  Incorrect: ${result.incorrect} ✗');
// //     buffer.writeln('  Missed: ${result.missed} —');
// //     buffer.writeln('  Accuracy: ${(result.accuracy * 100).toStringAsFixed(2)}%');
// //     if (result.overallConfidence != null) {
// //       buffer.writeln('  Confidence: ${(result.overallConfidence! * 100).toStringAsFixed(2)}%');
// //     }
// //     buffer.writeln();
// //
// //     if (result.errors.isNotEmpty) {
// //       buffer.writeln('-' * 60);
// //       buffer.writeln('Errors (${result.errors.length}):');
// //       for (final error in result.errors) {
// //         buffer.writeln('  • $error');
// //       }
// //       buffer.writeln();
// //     }
// //
// //     if (result.detailedResults != null && result.detailedResults!.isNotEmpty) {
// //       buffer.writeln('-' * 60);
// //       buffer.writeln('Detailed Results:');
// //       buffer.writeln();
// //
// //       for (final entry in result.detailedResults!.entries.toList()
// //         ..sort((a, b) => a.key.compareTo(b.key))) {
// //         final comp = entry.value;
// //         final status = comp.isCorrect ? '✓' : '✗';
// //         final detected = comp.detected ?? '—';
// //
// //         buffer.writeln(
// //             'Q${comp.questionNumber.toString().padLeft(2)}: '
// //                 'Expected: ${comp.expected}, '
// //                 'Detected: $detected, '
// //                 'Confidence: ${(comp.confidence * 100).toStringAsFixed(0)}% '
// //                 '$status'
// //         );
// //       }
// //     }
// //
// //     buffer.writeln();
// //     buffer.writeln('=' * 60);
// //
// //     return buffer.toString();
// //   }
// // }
// //
// // /// Result of a single test
// // class TestResult {
// //   final int totalQuestions;
// //   final int correct;
// //   final int incorrect;
// //   final int missed;
// //   final double accuracy;
// //   final List<String> errors;
// //   final Map<int, ComparisonResult>? detailedResults;
// //   final double? overallConfidence;
// //
// //   TestResult({
// //     required this.totalQuestions,
// //     required this.correct,
// //     required this.incorrect,
// //     required this.missed,
// //     required this.accuracy,
// //     required this.errors,
// //     this.detailedResults,
// //     this.overallConfidence,
// //   });
// // }
// //
// // /// Comparison of expected vs detected answer
// // class ComparisonResult {
// //   final int questionNumber;
// //   final String expected;
// //   final String? detected;
// //   final bool isCorrect;
// //   final double confidence;
// //
// //   ComparisonResult({
// //     required this.questionNumber,
// //     required this.expected,
// //     required this.detected,
// //     required this.isCorrect,
// //     required this.confidence,
// //   });
// // }
// //
// // /// Result of batch testing
// // class BatchTestResult {
// //   final int totalSheets;
// //   final double averageAccuracy;
// //   final int totalCorrect;
// //   final int totalQuestions;
// //   final List<TestResult> individualResults;
// //
// //   BatchTestResult({
// //     required this.totalSheets,
// //     required this.averageAccuracy,
// //     required this.totalCorrect,
// //     required this.totalQuestions,
// //     required this.individualResults,
// //   });
// //
// //   double get overallAccuracy => totalCorrect / totalQuestions;
// //
// //   String generateReport() {
// //     final buffer = StringBuffer();
// //
// //     buffer.writeln('=' * 60);
// //     buffer.writeln('BATCH TEST REPORT');
// //     buffer.writeln('=' * 60);
// //     buffer.writeln();
// //
// //     buffer.writeln('Summary:');
// //     buffer.writeln('  Total Sheets Tested: $totalSheets');
// //     buffer.writeln('  Total Questions: $totalQuestions');
// //     buffer.writeln('  Total Correct: $totalCorrect');
// //     buffer.writeln('  Average Accuracy: ${(averageAccuracy * 100).toStringAsFixed(2)}%');
// //     buffer.writeln('  Overall Accuracy: ${(overallAccuracy * 100).toStringAsFixed(2)}%');
// //     buffer.writeln();
// //
// //     buffer.writeln('-' * 60);
// //     buffer.writeln('Individual Sheet Results:');
// //     buffer.writeln();
// //
// //     for (int i = 0; i < individualResults.length; i++) {
// //       final result = individualResults[i];
// //       buffer.writeln(
// //           'Sheet ${i + 1}: '
// //               '${result.correct}/${result.totalQuestions} correct '
// //               '(${(result.accuracy * 100).toStringAsFixed(1)}%)'
// //       );
// //     }
// //
// //     buffer.writeln();
// //     buffer.writeln('=' * 60);
// //
// //     return buffer.toString();
// //   }
// // }
// //
// // /// Utility for generating test OMR sheets programmatically
// // class OMRTestSheetGenerator {
// //   /// Generate a test OMR sheet image with specific answers filled
// //   Future<cv.Mat> generateTestSheet({
// //     required OMRSheetType type,
// //     required Map<int, String> filledAnswers,
// //     int width = 800,
// //     int height = 1200,
// //   }) async {
// //     // Create white canvas
// //     final sheet = cv.Mat.zeros(height, width, cv.MatType.CV_8UC3);
// //     sheet.setTo(cv.Scalar(255, 255, 255, 0));
// //
// //     // Draw header
// //     cv.putText(
// //       sheet,
// //       'TEST OMR SHEET',
// //       cv.Point(width ~/ 2 - 100, 40),
// //       cv.FONT_HERSHEY_SIMPLEX,
// //       1.0,
// //       cv.Scalar(0, 0, 0, 0),
// //       thickness: 2,
// //     );
// //
// //     // Draw answer bubbles
// //     final startY = 150;
// //     final bubbleRadius = 15;
// //     final spacing = 40;
// //     final questionsPerColumn = 14;
// //     final columnSpacing = 200;
// //
// //     for (final entry in filledAnswers.entries) {
// //       final questionNum = entry.key;
// //       final answer = entry.value;
// //
// //       // Calculate position
// //       final column = (questionNum - 1) ~/ questionsPerColumn;
// //       final row = (questionNum - 1) % questionsPerColumn;
// //
// //       final x = 100 + column * columnSpacing;
// //       final y = startY + row * spacing;
// //
// //       // Draw question number
// //       cv.putText(
// //         sheet,
// //         '$questionNum.',
// //         cv.Point(x - 30, y + 5),
// //         cv.FONT_HERSHEY_SIMPLEX,
// //         0.5,
// //         cv.Scalar(0, 0, 0, 0),
// //         thickness: 1,
// //       );
// //
// //       // Draw option bubbles (A, B, C, D)
// //       final options = ['A', 'B', 'C', 'D'];
// //       for (int i = 0; i < options.length; i++) {
// //         final optionX = x + i * 35;
// //
// //         // Draw bubble
// //         cv.circle(
// //           sheet,
// //           cv.Point(optionX, y),
// //           bubbleRadius,
// //           cv.Scalar(0, 0, 0, 0),
// //           thickness: 2,
// //         );
// //
// //         // Fill if this is the answer
// //         if (options[i] == answer) {
// //           cv.circle(
// //             sheet,
// //             cv.Point(optionX, y),
// //             bubbleRadius - 3,
// //             cv.Scalar(0, 0, 0, 0),
// //             thickness: -1,
// //           );
// //         }
// //
// //         // Draw option label
// //         cv.putText(
// //           sheet,
// //           options[i],
// //           cv.Point(optionX - 5, y - 20),
// //           cv.FONT_HERSHEY_SIMPLEX,
// //           0.4,
// //           cv.Scalar(0, 0, 0, 0),
// //           thickness: 1,
// //         );
// //       }
// //     }
// //
// //     return sheet;
// //   }
// // }
// //
// // /// Example usage and testing
// // void main() async {
// //   // Example: Auto-calibrate from a sample sheet
// //   print('OMR Calibration & Testing Utilities');
// //   print('====================================\n');
// //
// //   // This would be your actual image bytes
// //   // final imageBytes = await File('sample_omr.jpg').readAsBytes();
// //
// //   print('Available utilities:');
// //   print('1. OMRCalibrationService - Auto-calibrate detection parameters');
// //   print('2. OMRTestSuite - Test accuracy against answer keys');
// //   print('3. OMRTestSheetGenerator - Generate test sheets programmatically');
// //   print('\nRefer to the documentation for detailed usage examples.');
// // }