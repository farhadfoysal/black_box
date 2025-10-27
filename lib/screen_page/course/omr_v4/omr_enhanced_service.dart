// import 'dart:typed_data';
// import 'package:opencv_dart/opencv_dart.dart' as cv;
// import 'dart:math' as math;
//
// /// Enum for different OMR sheet types
// enum OMRSheetType {
//   type1_40Questions, // First image type (40 questions, 4 options)
//   type2_40Questions, // Second image type (40 questions, 4 options, different layout)
//   unknown
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
// class EnhancedOMRScannerService {
//   EnhancedOMRConfig config;
//
//   EnhancedOMRScannerService({EnhancedOMRConfig? config})
//       : config = config ?? EnhancedOMRConfig();
//
//   /// Main processing method with automatic sheet type detection
//   Future<EnhancedOMRResult> processOMRSheet(Uint8List imageBytes) async {
//     try {
//       final diagnostics = <String, dynamic>{};
//       final startTime = DateTime.now();
//
//       // Decode image
//       final mat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
//       diagnostics['originalSize'] = '${mat.cols}x${mat.rows}';
//
//       // Preprocess
//       final preprocessed = await _preprocessImage(mat);
//
//       // Detect and align
//       final aligned = await _detectAndAlignSheet(mat, preprocessed);
//
//       // Detect sheet type
//       final sheetType = await _detectSheetType(aligned);
//       config = EnhancedOMRConfig.forType(sheetType);
//       diagnostics['detectedSheetType'] = sheetType.toString();
//
//       // Extract regions based on sheet type
//       final regions = await _extractRegions(aligned, sheetType);
//
//       // Process student info
//       final studentInfo = await _processStudentInfoEnhanced(
//         regions['studentInfo']!,
//       );
//
//       // Process answers
//       final answers = await _processAnswerGridEnhanced(
//         regions['answerGrid']!,
//         sheetType,
//       );
//
//       // Calculate overall confidence
//       final avgConfidence = answers.isEmpty
//           ? 0.0
//           : answers.map((a) => a.confidence).reduce((a, b) => a + b) /
//           answers.length;
//
//       // Create debug visualization
//       final debugImage = await _createDebugVisualization(
//         aligned,
//         regions['answerGrid']!,
//         answers,
//       );
//
//       final processingTime = DateTime.now().difference(startTime);
//       diagnostics['processingTime'] = '${processingTime.inMilliseconds}ms';
//       diagnostics['totalBubblesDetected'] = answers.length * config.optionsPerQuestion;
//
//       return EnhancedOMRResult(
//         studentInfo: studentInfo,
//         answers: answers,
//         detectedSheetType: sheetType,
//         processedImage: preprocessed,
//         alignedImage: aligned,
//         debugImage: debugImage,
//         isValid: true,
//         overallConfidence: avgConfidence,
//         diagnostics: diagnostics,
//       );
//     } catch (e, stackTrace) {
//       return EnhancedOMRResult(
//         studentInfo: EnhancedStudentInfo(),
//         answers: [],
//         isValid: false,
//         errorMessage: 'Error processing OMR: $e\n$stackTrace',
//         diagnostics: {'error': e.toString()},
//       );
//     }
//   }
//
//   /// Advanced preprocessing with multiple techniques
//   Future<cv.Mat> _preprocessImage(cv.Mat image) async {
//     // Convert to grayscale
//     final gray = cv.cvtColor(image, cv.COLOR_BGR2GRAY);
//
//     // Apply bilateral filter to preserve edges while reducing noise
//     final filtered = cv.bilateralFilter(gray, 9, 75, 75);
//
//     // Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)
//     final clahe = cv.CLAHE.create(2.0, (8, 8));
//     final enhanced = clahe.apply(filtered);
//
//     // Apply adaptive threshold
//     final thresh = cv.adaptiveThreshold(
//       enhanced,
//       255,
//       cv.ADAPTIVE_THRESH_GAUSSIAN_C,
//       cv.THRESH_BINARY_INV,
//       11,
//       2,
//     );
//
//     // Morphological operations to clean up
//     final kernel = cv.getStructuringElement(cv.MORPH_RECT, (2, 2));
//     final cleaned = cv.morphologyEx(thresh, cv.MORPH_CLOSE, kernel);
//
//     return cleaned;
//   }
//
//   /// Detect OMR sheet and align with perspective correction
//   Future<cv.Mat> _detectAndAlignSheet(cv.Mat original, cv.Mat processed) async {
//     // Find contours
//     final contours = cv.findContours(
//       processed,
//       cv.RETR_EXTERNAL,
//       cv.CHAIN_APPROX_SIMPLE,
//     );
//
//     if (contours.$1.isEmpty) {
//       return original;
//     }
//
//     // Find the largest rectangular contour
//     cv.VecPoint? sheetContour;
//     double maxArea = 0;
//     final minArea = original.rows * original.cols * 0.5; // At least 50% of image
//
//     for (final contour in contours.$1) {
//       final area = cv.contourArea(contour);
//       if (area < minArea) continue;
//
//       final peri = cv.arcLength(contour, true);
//       final approx = cv.approxPolyDP(contour, 0.02 * peri, true);
//
//       if (approx.length == 4 && area > maxArea) {
//         maxArea = area;
//         sheetContour = approx;
//       }
//     }
//
//     if (sheetContour == null || maxArea == 0) {
//       // Try edge detection approach
//       return await _detectSheetByEdges(original, processed);
//     }
//
//     // Apply perspective transform
//     return await _fourPointTransform(original, sheetContour);
//   }
//
//   /// Alternative detection using edge detection
//   Future<cv.Mat> _detectSheetByEdges(cv.Mat original, cv.Mat processed) async {
//     final edges = cv.canny(processed, 50, 150);
//
//     // Detect lines using Hough transform
//     final lines = cv.HoughLinesP(
//       edges,
//       1,
//       math.pi / 180,
//       100,
//       minLineLength: 100,
//       maxLineGap: 10,
//     );
//
//     if (lines.isEmpty) {
//       return original;
//     }
//
//     // Find document borders from lines (simplified)
//     return original; // Return original if edge detection fails
//   }
//
//   /// Four-point perspective transform
//   Future<cv.Mat> _fourPointTransform(cv.Mat image, cv.VecPoint points) async {
//     final pts = _orderPoints(points);
//
//     final widthA = _distance(pts[2], pts[3]);
//     final widthB = _distance(pts[1], pts[0]);
//     final maxWidth = math.max(widthA, widthB).toInt();
//
//     final heightA = _distance(pts[1], pts[2]);
//     final heightB = _distance(pts[0], pts[3]);
//     final maxHeight = math.max(heightA, heightB).toInt();
//
//     final dst = cv.Mat.fromList(
//       4,
//       1,
//       cv.MatType.CV_32FC2,
//       [0, 0, maxWidth - 1, 0, maxWidth - 1, maxHeight - 1, 0, maxHeight - 1],
//     );
//
//     final src = cv.Mat.fromList(
//       4,
//       1,
//       cv.MatType.CV_32FC2,
//       pts.expand((p) => [p.x.toDouble(), p.y.toDouble()]).toList(),
//     );
//
//     final matrix = cv.getPerspectiveTransform(src as cv.VecPoint, dst as cv.VecPoint);
//     final warped = cv.warpPerspective(image, matrix, (maxWidth, maxHeight));
//
//     return warped;
//   }
//
//   List<cv.Point> _orderPoints(cv.VecPoint points) {
//     final pts = points.toList();
//     pts.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
//
//     final topLeft = pts[0];
//     final bottomRight = pts[3];
//
//     final middle = [pts[1], pts[2]]
//       ..sort((a, b) => (a.y - a.x).compareTo(b.y - b.x));
//
//     return [topLeft, middle[0], bottomRight, middle[1]];
//   }
//
//   double _distance(cv.Point p1, cv.Point p2) {
//     return math.sqrt(math.pow(p2.x - p1.x, 2) + math.pow(p2.y - p1.y, 2));
//   }
//
//   /// Detect sheet type based on layout analysis
//   Future<OMRSheetType> _detectSheetType(cv.Mat image) async {
//     final height = image.rows;
//     final width = image.cols;
//
//     // Extract middle region for pattern analysis
//     final middleRegion = image.region(
//       cv.Rect(
//         (width * 0.1).toInt(),
//         (height * 0.3).toInt(),
//         (width * 0.8).toInt(),
//         (height * 0.4).toInt(),
//       ),
//     );
//
//     // Detect edges
//     final edges = cv.canny(middleRegion, 50, 150);
//
//     // Detect lines
//     final hLines = cv.HoughLinesP(edges, 1, math.pi / 180, 50);
//     final vLines = cv.HoughLinesP(edges, 1, math.pi / 2, 50);
//
//     // Count number of lines
//     final hCount = hLines.rows;
//     final vCount = vLines.rows;
//
//     // Decide OMR type based on structure
//     if (hCount > 15 && vCount < 10) {
//       return OMRSheetType.type1_40Questions;
//     } else {
//       return OMRSheetType.type2_40Questions;
//     }
//   }
//
//   /// Extract different regions based on sheet type
//   Future<Map<String, cv.Mat>> _extractRegions(
//       cv.Mat image,
//       OMRSheetType type,
//       ) async {
//     final height = image.rows;
//     final width = image.cols;
//
//     switch (type) {
//       case OMRSheetType.type1_40Questions:
//         return {
//           'studentInfo': image.region(
//             cv.Rect(0, 0, width, (height * 0.22).toInt()),
//           ),
//           'answerGrid': image.region(
//             cv.Rect(
//               0,
//               (height * 0.25).toInt(),
//               width,
//               (height * 0.65).toInt(),
//             ),
//           ),
//         };
//
//       case OMRSheetType.type2_40Questions:
//         return {
//           'studentInfo': image.region(
//             cv.Rect(0, 0, width, (height * 0.18).toInt()),
//           ),
//           'answerGrid': image.region(
//             cv.Rect(
//               0,
//               (height * 0.22).toInt(),
//               width,
//               (height * 0.70).toInt(),
//             ),
//           ),
//         };
//
//       default:
//         return {
//           'studentInfo': image.region(
//             cv.Rect(0, 0, width, (height * 0.20).toInt()),
//           ),
//           'answerGrid': image.region(
//             cv.Rect(
//               0,
//               (height * 0.25).toInt(),
//               width,
//               (height * 0.70).toInt(),
//             ),
//           ),
//         };
//     }
//   }
//
//   /// Enhanced student info processing
//   Future<EnhancedStudentInfo> _processStudentInfoEnhanced(
//       cv.Mat region,
//       ) async {
//     final bubbles = await _detectBubblesEnhanced(region);
//
//     // Separate into grid sections
//     final studentIdBubbles = <EnhancedBubble>[];
//     final mobileBubbles = <EnhancedBubble>[];
//
//     // Sort bubbles by position
//     bubbles.sort((a, b) {
//       final rowCompare = a.row.compareTo(b.row);
//       return rowCompare != 0 ? rowCompare : a.col.compareTo(b.col);
//     });
//
//     // Extract student ID (assuming 10 digits, 10 columns)
//     final studentIdDigits = <int>[];
//     for (int col = 0; col < 10; col++) {
//       final columnBubbles = bubbles.where((b) => b.col == col).toList();
//       final filled = columnBubbles.where((b) => b.isFilled).toList();
//
//       if (filled.length == 1) {
//         studentIdDigits.add(filled.first.row);
//       }
//     }
//
//     final studentId = studentIdDigits.isEmpty
//         ? null
//         : studentIdDigits.join();
//
//     return EnhancedStudentInfo(
//       studentId: studentId,
//       confidenceScores: {
//         'studentId': studentIdDigits.isEmpty ? 0.0 : 0.85,
//       },
//     );
//   }
//
//   /// Enhanced answer grid processing
//   Future<List<EnhancedAnswer>> _processAnswerGridEnhanced(
//       cv.Mat region,
//       OMRSheetType type,
//       ) async {
//     final bubbles = await _detectBubblesEnhanced(region);
//
//     // Group by rows
//     final rowGroups = <int, List<EnhancedBubble>>{};
//     for (final bubble in bubbles) {
//       rowGroups.putIfAbsent(bubble.row, () => []).add(bubble);
//     }
//
//     final answers = <EnhancedAnswer>[];
//     final optionLabels = config.optionLabels;
//
//     for (final entry in rowGroups.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
//       final questionNum = entry.key + 1;
//       if (questionNum > config.totalQuestions) break;
//
//       final rowBubbles = entry.value..sort((a, b) => a.col.compareTo(b.col));
//
//       // Find filled bubbles
//       final filledBubbles = rowBubbles.where((b) => b.isFilled).toList();
//
//       if (filledBubbles.isEmpty) {
//         answers.add(EnhancedAnswer(
//           questionNumber: questionNum,
//           confidence: 1.0,
//         ));
//       } else if (filledBubbles.length == 1) {
//         final filled = filledBubbles.first;
//         final optionIndex = rowBubbles.indexOf(filled);
//
//         answers.add(EnhancedAnswer(
//           questionNumber: questionNum,
//           selectedOption: optionLabels[optionIndex % optionLabels.length],
//           confidence: filled.confidence,
//           detectedOptions: [optionLabels[optionIndex % optionLabels.length]],
//         ));
//       } else {
//         // Multiple marks
//         final detectedOpts = filledBubbles
//             .map((b) => optionLabels[rowBubbles.indexOf(b) % optionLabels.length])
//             .toList();
//
//         answers.add(EnhancedAnswer(
//           questionNumber: questionNum,
//           isMultipleMarked: true,
//           confidence: 0.0,
//           detectedOptions: detectedOpts,
//         ));
//       }
//     }
//
//     return answers;
//   }
//
//   /// Enhanced bubble detection with confidence scoring
//   Future<List<EnhancedBubble>> _detectBubblesEnhanced(cv.Mat region) async {
//     final contours = cv.findContours(
//       region,
//       cv.RETR_EXTERNAL,
//       cv.CHAIN_APPROX_SIMPLE,
//     );
//
//     final bubbles = <EnhancedBubble>[];
//
//     for (final contour in contours.$1) {
//       final area = cv.contourArea(contour);
//
//       if (area < config.minBubbleArea || area > config.maxBubbleArea) {
//         continue;
//       }
//
//       final perimeter = cv.arcLength(contour, true);
//       final circularity = 4 * math.pi * area / (perimeter * perimeter);
//
//       if (circularity < config.minCircularity) {
//         continue;
//       }
//
//       final bbox = cv.boundingRect(contour);
//       final moments = cv.moments(contour as cv.Mat);
//       final center = cv.Point(
//         (moments.m10 / moments.m00).toInt(),
//         (moments.m01 / moments.m00).toInt(),
//       );
//
//       // Calculate fill percentage
//       final mask = cv.Mat.zeros(region.rows, region.cols, cv.MatType.CV_8UC1);
//       cv.drawContours(mask, [contour] as cv.Contours, -1, cv.Scalar.all(255), thickness: -1);
//
//       final roi = region.region(bbox);
//       final maskRoi = mask.region(bbox);
//
//       final filled = cv.countNonZero(cv.bitwiseAND(roi, maskRoi));
//       final total = cv.countNonZero(maskRoi);
//       final fillPercentage = total > 0 ? filled / total : 0.0;
//
//       // Calculate confidence based on circularity and fill consistency
//       final confidence = (circularity + (fillPercentage > 0.3 ? 1.0 : 0.0)) / 2;
//
//       final row = bbox.y ~/ (bbox.height + 10);
//       final col = bbox.x ~/ (bbox.width + 10);
//
//       bubbles.add(EnhancedBubble(
//         boundingBox: bbox,
//         center: center,
//         fillPercentage: fillPercentage,
//         confidence: confidence,
//         row: row,
//         col: col,
//         area: area,
//       ));
//     }
//
//     return bubbles;
//   }
//
//   /// Create debug visualization
//   Future<cv.Mat> _createDebugVisualization(
//       cv.Mat image,
//       cv.Mat answerRegion,
//       List<EnhancedAnswer> answers,
//       ) async {
//     final debug = cv.cvtColor(image, cv.COLOR_GRAY2BGR);
//
//     // Draw regions
//     final height = image.rows;
//     final width = image.cols;
//
//     // Student info region
//     cv.rectangle(
//       debug,
//       cv.Rect(0, 0, width, (height * 0.22).toInt()),
//       cv.Scalar(255, 0, 0, 0),
//       thickness: 3,
//     );
//
//     // Answer grid region
//     cv.rectangle(
//       debug,
//       cv.Rect(0, (height * 0.25).toInt(), width, (height * 0.65).toInt()),
//       cv.Scalar(0, 255, 0, 0),
//       thickness: 3,
//     );
//
//     return debug;
//   }
// }