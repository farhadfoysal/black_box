// import 'dart:typed_data';
// import 'package:opencv_dart/opencv_dart.dart' as cv;
// import 'dart:math' as math;
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
// class OMRScannerService {
//   final OMRConfig config;
//
//   OMRScannerService({OMRConfig? config})
//       : config = config ?? OMRConfig();
//
//   /// Main method to process OMR sheet
//   Future<OMRResult> processOMRSheet(Uint8List imageBytes) async {
//     try {
//       // Decode image
//       final mat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
//
//       // Preprocess image
//       final processed = await _preprocessImage(mat);
//
//       // Detect and perspective transform
//       final aligned = await _detectAndAlignSheet(processed);
//
//       // Extract regions
//       final studentInfoRegion = await _extractStudentInfoRegion(aligned);
//       final answerGridRegion = await _extractAnswerGridRegion(aligned);
//
//       // Process student information
//       final studentInfo = await _processStudentInfo(studentInfoRegion);
//
//       // Process answers
//       final answers = await _processAnswerGrid(answerGridRegion);
//
//       return OMRResult(
//         studentInfo: studentInfo,
//         answers: answers,
//         processedImage: aligned,
//         isValid: true,
//       );
//     } catch (e) {
//       return OMRResult(
//         studentInfo: StudentInfo(),
//         answers: [],
//         isValid: false,
//         errorMessage: 'Error processing OMR: $e',
//       );
//     }
//   }
//
//   /// Preprocess the image for better detection
//   Future<cv.Mat> _preprocessImage(cv.Mat image) async {
//     // Convert to grayscale
//     final gray = cv.cvtColor(image, cv.COLOR_BGR2GRAY);
//
//     // Apply Gaussian blur to reduce noise
//     final blurred = cv.gaussianBlur(gray, (5, 5), 0);
//
//     // Apply adaptive threshold
//     final thresh = cv.adaptiveThreshold(
//       blurred,
//       255,
//       cv.ADAPTIVE_THRESH_GAUSSIAN_C,
//       cv.THRESH_BINARY_INV,
//       11,
//       2,
//     );
//
//     return thresh;
//   }
//
//   /// Detect the OMR sheet and apply perspective transform
//   Future<cv.Mat> _detectAndAlignSheet(cv.Mat image) async {
//     // Find contours
//     final contours = cv.findContours(
//       image,
//       cv.RETR_EXTERNAL,
//       cv.CHAIN_APPROX_SIMPLE,
//     );
//
//     if (contours.$1.isEmpty) {
//       throw Exception('No contours found');
//     }
//
//     // Find the largest rectangular contour (the OMR sheet)
//     cv.VecPoint? sheetContour;
//     double maxArea = 0;
//
//     for (final contour in contours.$1) {
//       final area = cv.contourArea(contour);
//       final peri = cv.arcLength(contour, true);
//       final approx = cv.approxPolyDP(contour, 0.02 * peri, true);
//
//       if (approx.length == 4 && area > maxArea) {
//         maxArea = area;
//         sheetContour = approx;
//       }
//     }
//
//     if (sheetContour == null) {
//       // Return original if no sheet detected
//       return image;
//     }
//
//     // Apply perspective transform
//     final transformed = await _fourPointTransform(image, sheetContour);
//     return transformed;
//   }
//
//   /// Apply four-point perspective transform
//   // Future<cv.Mat> _fourPointTransform(cv.Mat image, cv.VecPoint points) async {
//   //   // Order points: top-left, top-right, bottom-right, bottom-left
//   //   final pts = _orderPoints(points);
//   //
//   //   // Calculate dimensions
//   //   final widthA = _distance(pts[2], pts[3]);
//   //   final widthB = _distance(pts[1], pts[0]);
//   //   final maxWidth = math.max(widthA, widthB).toInt();
//   //
//   //   final heightA = _distance(pts[1], pts[2]);
//   //   final heightB = _distance(pts[0], pts[3]);
//   //   final maxHeight = math.max(heightA, heightB).toInt();
//   //
//   //   // Destination points
//   //   final dst = cv.Mat.fromList(
//   //     4,
//   //     1,
//   //     cv.MatType.CV_32FC2,
//   //     [
//   //       0, 0,
//   //       maxWidth - 1, 0,
//   //       maxWidth - 1, maxHeight - 1,
//   //       0, maxHeight - 1,
//   //     ],
//   //   );
//   //
//   //   final src = cv.Mat.fromList(
//   //     4,
//   //     1,
//   //     cv.MatType.CV_32FC2,
//   //     pts.expand((p) => [p.x.toDouble(), p.y.toDouble()]).toList(),
//   //   );
//   //
//   //   // Get perspective transform matrix
//   //   final matrix = cv.getPerspectiveTransform(src as cv.VecPoint, dst as cv.VecPoint);
//   //
//   //   // Apply transform
//   //   final warped = cv.warpPerspective(
//   //     image,
//   //     matrix,
//   //     (maxWidth, maxHeight),
//   //   );
//   //
//   //   return warped;
//   // }
//
//
//   Future<cv.Mat> _fourPointTransform(cv.Mat image, cv.VecPoint points) async {
//     // Order points: top-left, top-right, bottom-right, bottom-left
//     final pts = _orderPoints(points);
//
//     // Calculate dimensions
//     final widthA = _distance(pts[2], pts[3]);
//     final widthB = _distance(pts[1], pts[0]);
//     final maxWidth = math.max(widthA, widthB).toInt();
//
//     final heightA = _distance(pts[1], pts[2]);
//     final heightB = _distance(pts[0], pts[3]);
//     final maxHeight = math.max(heightA, heightB).toInt();
//
//     // Destination points
//     final dst = cv.Mat.fromList(
//       4,
//       1,
//       cv.MatType.CV_32FC2,
//       [
//         0, 0,
//         maxWidth - 1, 0,
//         maxWidth - 1, maxHeight - 1,
//         0, maxHeight - 1,
//       ],
//     );
//
//     final src = cv.Mat.fromList(
//       4,
//       1,
//       cv.MatType.CV_32FC2,
//       pts.expand((p) => [p.x.toDouble(), p.y.toDouble()]).toList(),
//     );
//
//     // Get perspective transform matrix - REMOVE THE CASTS
//     final matrix = cv.getPerspectiveTransform(_matToVecPoint(src), _matToVecPoint(dst));
//
//     // Apply transform
//     final warped = cv.warpPerspective(
//       image,
//       matrix,
//       (maxWidth, maxHeight),
//     );
//
//     // Clean up matrices
//     src.release();
//     dst.release();
//     matrix.release();
//
//     return warped;
//   }
//
//   cv.VecPoint _matToVecPoint(cv.Mat mat) {
//     final vec = cv.VecPoint();
//
//     if (mat.type == cv.MatType.CV_32FC2) {
//       for (int i = 0; i < mat.rows; i++) {
//         final point = mat.at<cv.Vec2f>(i, 0);
//         vec.add(cv.Point(point.val1.toInt(), point.val2.toInt()));
//       }
//     }
//
//     return vec;
//   }
//
//   /// Order points in clockwise order starting from top-left
//   List<cv.Point> _orderPoints(cv.VecPoint points) {
//     final pts = points.toList();
//
//     // Sort by sum (top-left has smallest sum, bottom-right has largest)
//     pts.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
//     final topLeft = pts[0];
//     final bottomRight = pts[3];
//
//     // Sort middle two by difference
//     final middle = [pts[1], pts[2]]..sort((a, b) => (a.y - a.x).compareTo(b.y - b.x));
//     final topRight = middle[0];
//     final bottomLeft = middle[1];
//
//     return [topLeft, topRight, bottomRight, bottomLeft];
//   }
//
//   /// Calculate Euclidean distance between two points
//   double _distance(cv.Point p1, cv.Point p2) {
//     return math.sqrt(math.pow(p2.x - p1.x, 2) + math.pow(p2.y - p1.y, 2));
//   }
//
//   /// Extract student information region (top portion)
//   Future<cv.Mat> _extractStudentInfoRegion(cv.Mat image) async {
//     final height = image.rows;
//     final width = image.cols;
//
//     // Student info is typically in top 20% of the sheet
//     final roi = image.region(cv.Rect(0, 0, width, (height * 0.2).toInt()));
//     return roi;
//   }
//
//   /// Extract answer grid region (middle/bottom portion)
//   Future<cv.Mat> _extractAnswerGridRegion(cv.Mat image) async {
//     final height = image.rows;
//     final width = image.cols;
//
//     // Answer grid starts after student info (around 20% down)
//     final roi = image.region(
//       cv.Rect(0, (height * 0.25).toInt(), width, (height * 0.7).toInt()),
//     );
//     return roi;
//   }
//
//   /// Process student information bubbles
//   Future<StudentInfo> _processStudentInfo(cv.Mat region) async {
//     final bubbles = await _detectBubbles(region);
//
//     // Separate bubbles into different fields
//     final studentIdBubbles = <Bubble>[];
//     final mobileBubbles = <Bubble>[];
//     final setNumberBubbles = <Bubble>[];
//
//     // Group by vertical position (rows)
//     final groupedByRow = <int, List<Bubble>>{};
//     for (final bubble in bubbles) {
//       groupedByRow.putIfAbsent(bubble.row, () => []).add(bubble);
//     }
//
//     // Extract digits based on filled bubbles
//     String? studentId;
//     String? mobileNumber;
//     String? setNumber;
//
//     // Process each row to extract digits
//     // This is simplified - you'd need to identify which rows correspond to which field
//
//     return StudentInfo(
//       studentId: studentId,
//       mobileNumber: mobileNumber,
//       setNumber: setNumber,
//     );
//   }
//
//   /// Process answer grid and extract answers
//   Future<List<Answer>> _processAnswerGrid(cv.Mat region) async {
//     final bubbles = await _detectBubbles(region);
//
//     // Group bubbles by rows (questions)
//     final questionBubbles = <int, List<Bubble>>{};
//
//     for (final bubble in bubbles) {
//       questionBubbles.putIfAbsent(bubble.row, () => []).add(bubble);
//     }
//
//     final answers = <Answer>[];
//     final optionLabels = ['A', 'B', 'C', 'D'];
//
//     // Process each question
//     for (final entry in questionBubbles.entries) {
//       final questionNum = entry.key + 1;
//       final bubbleList = entry.value..sort((a, b) => a.col.compareTo(b.col));
//
//       // Find filled bubbles
//       final filledBubbles = bubbleList
//           .where((b) => b.fillPercentage > config.bubbleFillThreshold)
//           .toList();
//
//       if (filledBubbles.isEmpty) {
//         answers.add(Answer(questionNumber: questionNum));
//       } else if (filledBubbles.length == 1) {
//         final optionIndex = bubbleList.indexOf(filledBubbles[0]);
//         answers.add(Answer(
//           questionNumber: questionNum,
//           selectedOption: optionLabels[optionIndex % optionLabels.length],
//         ));
//       } else {
//         // Multiple answers marked
//         answers.add(Answer(
//           questionNumber: questionNum,
//           isMultipleMarked: true,
//         ));
//       }
//     }
//
//     return answers;
//   }
//
//   /// Detect bubbles in a region
//   Future<List<Bubble>> _detectBubbles(cv.Mat region) async {
//     // Find contours
//     final contours = cv.findContours(
//       region,
//       cv.RETR_EXTERNAL,
//       cv.CHAIN_APPROX_SIMPLE,
//     );
//
//     final bubbles = <Bubble>[];
//
//     for (final contour in contours.$1) {
//       final area = cv.contourArea(contour);
//
//       // Filter by area
//       if (area < config.minBubbleArea || area > config.maxBubbleArea) {
//         continue;
//       }
//
//       // Check circularity
//       final perimeter = cv.arcLength(contour, true);
//       final circularity = 4 * math.pi * area / (perimeter * perimeter);
//
//       if (circularity < config.minCircularity) {
//         continue;
//       }
//
//       // Get bounding box
//       final bbox = cv.boundingRect(contour);
//
//       // Calculate fill percentage
//       final mask = cv.Mat.zeros(region.rows, region.cols, cv.MatType.CV_8UC1);
//       cv.drawContours(mask, [contour] as cv.Contours, -1, cv.Scalar.all(255), thickness: -1);
//       // cv.drawContours(mask, [contour], -1, cv.Scalar.all(255), thickness: -1);
//
//       final roi = region.region(bbox);
//       final maskRoi = mask.region(bbox);
//
//       final filled = cv.countNonZero(cv.bitwiseAND(roi, maskRoi));
//       final total = cv.countNonZero(maskRoi);
//       final fillPercentage = filled / total;
//
//       // Estimate row and column
//       final row = bbox.y ~/ (bbox.height + 5);
//       final col = bbox.x ~/ (bbox.width + 5);
//
//       bubbles.add(Bubble(
//         boundingBox: bbox,
//         fillPercentage: fillPercentage,
//         row: row,
//         col: col,
//       ));
//     }
//
//     return bubbles;
//   }
//
//   /// Visualize detected bubbles on the image
//   cv.Mat visualizeBubbles(cv.Mat image, List<Bubble> bubbles) {
//     final output = image.clone();
//
//     for (final bubble in bubbles) {
//       final color = bubble.fillPercentage > config.bubbleFillThreshold
//           ? cv.Scalar(0, 255, 0, 0) // Green for filled
//           : cv.Scalar(0, 0, 255, 0); // Red for empty
//
//       cv.rectangle(output, bubble.boundingBox, color, thickness: 2);
//     }
//
//     return output;
//   }
// }
//
// /// Extension methods for easier usage
// extension OMRResultExtension on OMRResult {
//   /// Get answers as a map of question number to answer
//   Map<int, String?> get answersMap {
//     return {for (var ans in answers) ans.questionNumber: ans.selectedOption};
//   }
//
//   /// Get list of unanswered questions
//   List<int> get unansweredQuestions {
//     return answers
//         .where((ans) => ans.selectedOption == null && !ans.isMultipleMarked)
//         .map((ans) => ans.questionNumber)
//         .toList();
//   }
//
//   /// Get list of questions with multiple answers marked
//   List<int> get multipleMarkedQuestions {
//     return answers
//         .where((ans) => ans.isMultipleMarked)
//         .map((ans) => ans.questionNumber)
//         .toList();
//   }
// }