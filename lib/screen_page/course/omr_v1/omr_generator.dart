// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'omr_models.dart';
//
// class OMRGenerator {
//   // A4 dimensions in points (72 DPI)
//   static const double A4_WIDTH = 595.0;
//   static const double A4_HEIGHT = 842.0;
//
//   // Optimized margins and spacing
//   static const double PAGE_MARGIN = 20.0;
//   static const double BUBBLE_RADIUS = 3.5;
//   static const double BUBBLE_SPACING = 14.0;
//   static const double COLUMN_SPACING = 12.0;
//   static const double ANSWER_LINE_HEIGHT = 12.0;
//
//   // Section heights - carefully calculated to fit A4
//   static const double HEADER_HEIGHT = 100.0;
//   static const double STUDENT_INFO_HEIGHT = 70.0;
//   static const double ID_SECTION_HEIGHT = 130.0;
//   static const double ANSWER_SECTION_HEIGHT = 400.0;
//   static const double FOOTER_HEIGHT = 60.0;
//
//   static Future<File> generateOMRSheet(OMRExamConfig config) async {
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//
//     // White background
//     canvas.drawRect(
//         Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT),
//         Paint()..color = Colors.white
//     );
//
//     // Draw all sections with proper spacing
//     _drawBorder(canvas);
//     double currentY = _drawHeader(canvas, config);
//     currentY = _drawStudentInfoRow(canvas, config, currentY);
//     currentY = _drawIdAndPhoneSection(canvas, config, currentY);
//     currentY = _drawAnswerSection(canvas, config.numberOfQuestions, currentY);
//     _drawFooter(canvas, currentY);
//
//     // Draw answer key if provided
//     if (config.correctAnswers.isNotEmpty) {
//       _drawAnswerKey(canvas, config.correctAnswers, config.numberOfQuestions);
//     }
//
//     // Convert to image and save
//     final picture = recorder.endRecording();
//     final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
//     final bytes = byteData!.buffer.asUint8List();
//
//     final directory = await getTemporaryDirectory();
//     final file = File('${directory.path}/omr_sheet_${DateTime.now().millisecondsSinceEpoch}.png');
//     await file.writeAsBytes(bytes);
//
//     return file;
//   }
//
//   static void _drawBorder(Canvas canvas) {
//     final borderPaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.5;
//
//     canvas.drawRect(
//         Rect.fromLTWH(
//             PAGE_MARGIN,
//             PAGE_MARGIN,
//             A4_WIDTH - 2 * PAGE_MARGIN,
//             A4_HEIGHT - 2 * PAGE_MARGIN
//         ),
//         borderPaint
//     );
//
//     // Inner border for professional look
//     final innerBorderPaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;
//
//     canvas.drawRect(
//         Rect.fromLTWH(
//             PAGE_MARGIN + 5,
//             PAGE_MARGIN + 5,
//             A4_WIDTH - 2 * PAGE_MARGIN - 10,
//             A4_HEIGHT - 2 * PAGE_MARGIN - 10
//         ),
//         innerBorderPaint
//     );
//   }
//
//   static double _drawHeader(Canvas canvas, OMRExamConfig config) {
//     double y = PAGE_MARGIN + 8;
//
//     // Institution name
//     final institutionPainter = TextPainter(
//       text: TextSpan(
//         text: "PROFESSIONAL COACHING CENTER",
//         style: TextStyle(
//           fontSize: 14,
//           fontWeight: FontWeight.bold,
//           color: Colors.blue[900],
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     institutionPainter.layout();
//     institutionPainter.paint(
//         canvas,
//         Offset((A4_WIDTH - institutionPainter.width) / 2, y)
//     );
//
//     y += 18;
//
//     // Exam title
//     final titlePainter = TextPainter(
//       text: TextSpan(
//         text: config.examName.toUpperCase(),
//         style: TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//           color: Colors.black,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(
//         canvas,
//         Offset((A4_WIDTH - titlePainter.width) / 2, y)
//     );
//
//     y += 22;
//
//     // Exam details
//     _drawExamDetails(canvas, config, y);
//
//     y += 16;
//
//     // Instructions
//     _drawInstructions(canvas, y);
//
//     return PAGE_MARGIN + HEADER_HEIGHT;
//   }
//
//   static void _drawExamDetails(Canvas canvas, OMRExamConfig config, double y) {
//     final detailStyle = TextStyle(fontSize: 10, color: Colors.black87);
//
//     // Date
//     final datePainter = TextPainter(
//       text: TextSpan(
//         text: 'Date: ${_formatDate(config.examDate)}',
//         style: detailStyle,
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     datePainter.layout();
//     datePainter.paint(canvas, Offset(PAGE_MARGIN + 15, y));
//
//     // Total Questions
//     final questionsPainter = TextPainter(
//       text: TextSpan(
//         text: 'Questions: ${config.numberOfQuestions}',
//         style: detailStyle,
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     questionsPainter.layout();
//     questionsPainter.paint(
//         canvas,
//         Offset((A4_WIDTH - questionsPainter.width) / 2, y)
//     );
//
//     // Duration
//     final durationPainter = TextPainter(
//       text: TextSpan(text: 'Time: 3 Hours', style: detailStyle),
//       textDirection: TextDirection.ltr,
//     );
//     durationPainter.layout();
//     durationPainter.paint(
//         canvas,
//         Offset(A4_WIDTH - PAGE_MARGIN - 15 - durationPainter.width, y)
//     );
//   }
//
//   static void _drawInstructions(Canvas canvas, double y) {
//     // Instructions box background
//     final bgPaint = Paint()
//       ..color = Colors.grey[50]!
//       ..style = PaintingStyle.fill;
//     canvas.drawRect(
//         Rect.fromLTWH(PAGE_MARGIN + 10, y, A4_WIDTH - 2 * PAGE_MARGIN - 20, 28),
//         bgPaint
//     );
//
//     final borderPaint = Paint()
//       ..color = Colors.grey[400]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;
//     canvas.drawRect(
//         Rect.fromLTWH(PAGE_MARGIN + 10, y, A4_WIDTH - 2 * PAGE_MARGIN - 20, 28),
//         borderPaint
//     );
//
//     final instructions = [
//       "• Use BLACK/BLUE ball pen only",
//       "• Fill circles completely • No stray marks"
//     ];
//
//     final instructionStyle = TextStyle(fontSize: 8, color: Colors.black87, fontWeight: FontWeight.w500);
//     double instructionY = y + 8;
//
//     for (final instruction in instructions) {
//       final painter = TextPainter(
//         text: TextSpan(text: instruction, style: instructionStyle),
//         textDirection: TextDirection.ltr,
//       );
//       painter.layout();
//       painter.paint(canvas, Offset(PAGE_MARGIN + 15, instructionY));
//       instructionY += 10;
//     }
//   }
//
//   static double _drawStudentInfoRow(Canvas canvas, OMRExamConfig config, double startY) {
//     startY += 8;
//
//     // Section title
//     _drawSectionTitle(canvas, "STUDENT INFORMATION", startY);
//
//     startY += 22;
//
//     // Set number
//     final setLabelPainter = TextPainter(
//       text: TextSpan(
//         text: "SET:",
//         style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     setLabelPainter.layout();
//     setLabelPainter.paint(canvas, Offset(PAGE_MARGIN + 15, startY));
//
//     // Set bubbles (0-9)
//     double bubbleX = PAGE_MARGIN + 45;
//     for (int i = 0; i < 10; i++) {
//       _drawBubbleWithLabel(
//           canvas,
//           bubbleX + i * BUBBLE_SPACING,
//           startY - 2,
//           i.toString(),
//           i == config.setNumber
//       );
//     }
//
//     // Name field
//     final nameLabelPainter = TextPainter(
//       text: TextSpan(
//         text: "NAME:",
//         style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     nameLabelPainter.layout();
//     nameLabelPainter.paint(canvas, Offset(PAGE_MARGIN + 220, startY));
//
//     // Name line
//     canvas.drawLine(
//       Offset(PAGE_MARGIN + 260, startY + 10),
//       Offset(A4_WIDTH - PAGE_MARGIN - 15, startY + 10),
//       Paint()..color = Colors.black..strokeWidth = 0.8,
//     );
//
//     return startY + STUDENT_INFO_HEIGHT;
//   }
//
//   static double _drawIdAndPhoneSection(Canvas canvas, OMRExamConfig config, double startY) {
//     startY += 5;
//
//     final columnWidth = (A4_WIDTH - 2 * PAGE_MARGIN - 20) / 2;
//
//     // Student ID column
//     _drawIdColumn(canvas, config.studentId, PAGE_MARGIN + 10, startY, columnWidth);
//
//     // Mobile number column
//     _drawPhoneColumn(
//         canvas,
//         config.mobileNumber,
//         PAGE_MARGIN + 15 + columnWidth,
//         startY,
//         columnWidth - 5
//     );
//
//     return startY + ID_SECTION_HEIGHT;
//   }
//
//   static void _drawIdColumn(Canvas canvas, String studentId, double x, double y, double width) {
//     // Title
//     final titlePainter = TextPainter(
//       text: TextSpan(
//         text: "STUDENT ID (9 DIGITS)",
//         style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(x, y));
//
//     y += 15;
//
//     // Background
//     final bgPaint = Paint()
//       ..color = Colors.grey[100]!
//       ..style = PaintingStyle.fill;
//     canvas.drawRect(Rect.fromLTWH(x, y, width, 110), bgPaint);
//
//     // Border
//     final borderPaint = Paint()
//       ..color = Colors.grey[400]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;
//     canvas.drawRect(Rect.fromLTWH(x, y, width, 110), borderPaint);
//
//     // Draw digit columns
//     for (int digit = 0; digit < 9; digit++) {
//       double digitX = x + 5 + digit * BUBBLE_SPACING;
//
//       // Digit header
//       final digitPainter = TextPainter(
//         text: TextSpan(
//           text: (digit + 1).toString(),
//           style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue[800]),
//         ),
//         textDirection: TextDirection.ltr,
//       );
//       digitPainter.layout();
//       digitPainter.paint(canvas, Offset(digitX + 1, y + 5));
//
//       // Bubbles 0-9
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digit < studentId.length &&
//             studentId[digit] == num.toString();
//         _drawBubble(
//             canvas,
//             digitX,
//             y + 18 + num * 9,
//             isFilled
//         );
//
//         // Number labels on first column
//         if (digit == 0) {
//           final numPainter = TextPainter(
//             text: TextSpan(
//               text: num.toString(),
//               style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold),
//             ),
//             textDirection: TextDirection.ltr,
//           );
//           numPainter.layout();
//           numPainter.paint(canvas, Offset(x - 8, y + 20 + num * 9));
//         }
//       }
//     }
//   }
//
//   static void _drawPhoneColumn(Canvas canvas, String phoneNumber, double x, double y, double width) {
//     // Title
//     final titlePainter = TextPainter(
//       text: TextSpan(
//         text: "MOBILE NUMBER (11 DIGITS)",
//         style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(x, y));
//
//     y += 15;
//
//     // Background
//     final bgPaint = Paint()
//       ..color = Colors.grey[100]!
//       ..style = PaintingStyle.fill;
//     canvas.drawRect(Rect.fromLTWH(x, y, width, 110), bgPaint);
//
//     // Border
//     final borderPaint = Paint()
//       ..color = Colors.grey[400]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;
//     canvas.drawRect(Rect.fromLTWH(x, y, width, 110), borderPaint);
//
//     // Draw digit columns - adjusted for 11 digits
//     for (int digit = 0; digit < 11; digit++) {
//       double digitX = x + 5 + digit * (BUBBLE_SPACING - 0.5); // Slightly reduced spacing for 11 digits
//
//       // Digit header
//       final digitPainter = TextPainter(
//         text: TextSpan(
//           text: (digit + 1).toString(),
//           style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue[800]),
//         ),
//         textDirection: TextDirection.ltr,
//       );
//       digitPainter.layout();
//       digitPainter.paint(canvas, Offset(digitX + 1, y + 5));
//
//       // Bubbles 0-9
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digit < phoneNumber.length &&
//             phoneNumber[digit] == num.toString();
//         _drawBubble(
//             canvas,
//             digitX,
//             y + 18 + num * 9,
//             isFilled
//         );
//
//         // Number labels on first column
//         if (digit == 0) {
//           final numPainter = TextPainter(
//             text: TextSpan(
//               text: num.toString(),
//               style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold),
//             ),
//             textDirection: TextDirection.ltr,
//           );
//           numPainter.layout();
//           numPainter.paint(canvas, Offset(x - 8, y + 20 + num * 9));
//         }
//       }
//     }
//   }
//
//   static double _drawAnswerSection(Canvas canvas, int numberOfQuestions, double startY) {
//     startY += 8;
//
//     // Section title
//     _drawSectionTitle(canvas, "ANSWER SHEET", startY);
//
//     startY += 20;
//
//     // Options legend
//     final legendPainter = TextPainter(
//       text: TextSpan(
//         text: "OPTIONS: A • B • C • D • E",
//         style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue[800]),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     legendPainter.layout();
//     legendPainter.paint(canvas, Offset((A4_WIDTH - legendPainter.width) / 2, startY));
//
//     startY += 12;
//
//     // Calculate layout for three columns
//     final questionsPerColumn = (numberOfQuestions / 3).ceil();
//     final columnWidth = (A4_WIDTH - 2 * PAGE_MARGIN - 2 * COLUMN_SPACING) / 3;
//
//     // Calculate maximum questions that can fit in available height
//     final availableHeight = ANSWER_SECTION_HEIGHT - 40;
//     final maxQuestionsPerColumn = (availableHeight / ANSWER_LINE_HEIGHT).floor();
//
//     final actualQuestionsPerColumn = questionsPerColumn > maxQuestionsPerColumn
//         ? maxQuestionsPerColumn
//         : questionsPerColumn;
//
//     // Draw three columns
//     for (int col = 0; col < 3; col++) {
//       final columnX = PAGE_MARGIN + 10 + col * (columnWidth + COLUMN_SPACING);
//       _drawAnswerColumn(
//           canvas,
//           columnX,
//           startY,
//           col,
//           numberOfQuestions,
//           actualQuestionsPerColumn,
//           columnWidth
//       );
//     }
//
//     return startY + ANSWER_SECTION_HEIGHT;
//   }
//
//   static void _drawAnswerColumn(
//       Canvas canvas,
//       double x,
//       double y,
//       int colIndex,
//       int totalQuestions,
//       int questionsPerColumn,
//       double width
//       ) {
//     final startQuestion = colIndex * questionsPerColumn + 1;
//     int endQuestion = (colIndex + 1) * questionsPerColumn;
//
//     // Ensure we don't exceed total questions
//     if (endQuestion > totalQuestions) {
//       endQuestion = totalQuestions;
//     }
//
//     // Column header with background
//     final headerBgPaint = Paint()
//       ..color = Colors.grey[200]!
//       ..style = PaintingStyle.fill;
//     canvas.drawRect(Rect.fromLTWH(x, y, width, 12), headerBgPaint);
//
//     final headerPainter = TextPainter(
//       text: TextSpan(
//         text: "Q${startQuestion}-${endQuestion}",
//         style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     headerPainter.layout();
//     headerPainter.paint(canvas, Offset(x + 2, y));
//
//     y += 15;
//
//     // Draw questions
//     for (int q = startQuestion; q <= endQuestion; q++) {
//       if (q > totalQuestions) break;
//
//       // Question number with background
//       final qText = TextPainter(
//         text: TextSpan(
//           text: 'Q${q.toString().padLeft(2)}',
//           style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         textDirection: TextDirection.ltr,
//       );
//       qText.layout();
//
//       final qBgPaint = Paint()
//         ..color = Colors.blue[700]!
//         ..style = PaintingStyle.fill;
//       canvas.drawRect(Rect.fromLTWH(x, y, qText.width + 2, qText.height), qBgPaint);
//       qText.paint(canvas, Offset(x + 1, y));
//
//       // Options A, B, C, D, E
//       for (int opt = 0; opt < 5; opt++) {
//         final optionX = x + 22 + opt * 11;
//         final optionChar = String.fromCharCode(65 + opt);
//
//         // Option letter
//         final optPainter = TextPainter(
//           text: TextSpan(
//             text: optionChar,
//             style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold),
//           ),
//           textDirection: TextDirection.ltr,
//         );
//         optPainter.layout();
//         optPainter.paint(canvas, Offset(optionX + 1, y));
//
//         // Bubble
//         _drawBubble(canvas, optionX, y - 1, false);
//       }
//
//       y += ANSWER_LINE_HEIGHT;
//     }
//   }
//
//   static void _drawFooter(Canvas canvas, double startY) {
//     final footerTopY = startY + 10;
//
//     // Divider line
//     canvas.drawLine(
//       Offset(PAGE_MARGIN + 10, footerTopY),
//       Offset(A4_WIDTH - PAGE_MARGIN - 10, footerTopY),
//       Paint()..color = Colors.black..strokeWidth = 0.8,
//     );
//
//     final signatureY = footerTopY + 12;
//
//     // Student signature
//     _drawSignatureField(
//         canvas,
//         "STUDENT SIGNATURE",
//         PAGE_MARGIN + 15,
//         signatureY
//     );
//
//     // Invigilator signature
//     _drawSignatureField(
//         canvas,
//         "INVIGILATOR SIGNATURE",
//         A4_WIDTH / 2 - 50,
//         signatureY
//     );
//
//     // Date
//     _drawSignatureField(
//         canvas,
//         "DATE",
//         A4_WIDTH - PAGE_MARGIN - 80,
//         signatureY
//     );
//
//     // Footer note
//     final notePainter = TextPainter(
//       text: TextSpan(
//         text: "Ensure all bubbles are filled completely and correctly for accurate scanning",
//         style: TextStyle(fontSize: 7, color: Colors.grey[700], fontStyle: FontStyle.italic),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     notePainter.layout();
//     notePainter.paint(
//         canvas,
//         Offset((A4_WIDTH - notePainter.width) / 2, signatureY + 25)
//     );
//   }
//
//   static void _drawSignatureField(Canvas canvas, String label, double x, double y) {
//     final labelPainter = TextPainter(
//       text: TextSpan(
//         text: label,
//         style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     labelPainter.layout();
//     labelPainter.paint(canvas, Offset(x, y));
//
//     // Signature line
//     canvas.drawLine(
//       Offset(x, y + 10),
//       Offset(x + 75, y + 10),
//       Paint()..color = Colors.black..strokeWidth = 0.8,
//     );
//   }
//
//   static void _drawSectionTitle(Canvas canvas, String title, double y) {
//     final bgPaint = Paint()
//       ..color = Colors.blue[800]!
//       ..style = PaintingStyle.fill;
//
//     final titlePainter = TextPainter(
//       text: TextSpan(
//         text: title,
//         style: TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.bold,
//           color: Colors.white,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//
//     // Background rectangle
//     canvas.drawRect(
//         Rect.fromLTWH(
//             PAGE_MARGIN + 10,
//             y - 2,
//             titlePainter.width + 12,
//             titlePainter.height + 4
//         ),
//         bgPaint
//     );
//
//     // Title text
//     titlePainter.paint(canvas, Offset(PAGE_MARGIN + 16, y));
//   }
//
//   static void _drawBubble(Canvas canvas, double x, double y, bool filled) {
//     final paint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.8;
//
//     canvas.drawCircle(Offset(x + BUBBLE_RADIUS, y + BUBBLE_RADIUS), BUBBLE_RADIUS, paint);
//
//     if (filled) {
//       final fillPaint = Paint()
//         ..color = Colors.black
//         ..style = PaintingStyle.fill;
//       canvas.drawCircle(
//           Offset(x + BUBBLE_RADIUS, y + BUBBLE_RADIUS),
//           BUBBLE_RADIUS - 0.6,
//           fillPaint
//       );
//     }
//   }
//
//   static void _drawBubbleWithLabel(Canvas canvas, double x, double y, String label, bool filled) {
//     // Draw bubble
//     _drawBubble(canvas, x, y, filled);
//
//     // Draw label below
//     final labelPainter = TextPainter(
//       text: TextSpan(
//         text: label,
//         style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     labelPainter.layout();
//     labelPainter.paint(canvas, Offset(x + 1, y + 10));
//   }
//
//   static void _drawAnswerKey(Canvas canvas, List<String> correctAnswers, int totalQuestions) {
//     final questionsPerColumn = (totalQuestions / 3).ceil();
//     final columnWidth = (A4_WIDTH - 2 * PAGE_MARGIN - 2 * COLUMN_SPACING) / 3;
//
//     // Calculate answer section start position
//     final answerSectionStartY = PAGE_MARGIN + HEADER_HEIGHT + STUDENT_INFO_HEIGHT + ID_SECTION_HEIGHT + 45;
//
//     for (int i = 0; i < correctAnswers.length && i < totalQuestions; i++) {
//       final col = i ~/ questionsPerColumn;
//       final rowInColumn = i % questionsPerColumn;
//       final optionIndex = correctAnswers[i].codeUnitAt(0) - 65;
//
//       if (optionIndex >= 0 && optionIndex < 5) {
//         final columnX = PAGE_MARGIN + 10 + col * (columnWidth + COLUMN_SPACING);
//         final questionY = answerSectionStartY + rowInColumn * ANSWER_LINE_HEIGHT;
//         final optionX = columnX + 22 + optionIndex * 11;
//
//         // Fill correct answer in red
//         final redPaint = Paint()
//           ..color = Colors.red
//           ..style = PaintingStyle.fill;
//         canvas.drawCircle(
//             Offset(optionX + BUBBLE_RADIUS, questionY - 1 + BUBBLE_RADIUS),
//             BUBBLE_RADIUS - 0.5,
//             redPaint
//         );
//       }
//     }
//
//     // Draw watermark
//     final watermarkStyle = TextStyle(
//       fontSize: 50,
//       fontWeight: FontWeight.bold,
//       color: Colors.red.withOpacity(0.08),
//     );
//     final watermarkPainter = TextPainter(
//       text: TextSpan(text: "ANSWER KEY", style: watermarkStyle),
//       textDirection: TextDirection.ltr,
//     );
//     watermarkPainter.layout();
//     watermarkPainter.paint(canvas, Offset(
//       A4_WIDTH / 2 - watermarkPainter.width / 2,
//       A4_HEIGHT / 2 - watermarkPainter.height / 2,
//     ));
//   }
//
//   static String _formatDate(DateTime date) {
//     final months = [
//       'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
//       'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
//     ];
//     return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
//   }
// }




// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'omr_models.dart';
//
// class OMRGenerator {
//   // A4 dimensions in points (72 DPI)
//   static const double A4_WIDTH = 595.0;
//   static const double A4_HEIGHT = 842.0;
//
//   // Optimized margins and spacing
//   static const double PAGE_MARGIN = 20.0;
//   static const double BUBBLE_RADIUS = 3.5;
//   static const double BUBBLE_SPACING = 15.0;
//   static const double COLUMN_SPACING = 10.0;
//   static const double LINE_HEIGHT = 16.0;
//
//   // Section heights
//   static const double HEADER_HEIGHT = 100.0;
//   static const double STUDENT_INFO_HEIGHT = 60.0;
//   static const double ID_SECTION_HEIGHT = 140.0;
//   static const double FOOTER_HEIGHT = 60.0;
//
//   static Future<File> generateOMRSheet(OMRExamConfig config) async {
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//
//     // White background
//     canvas.drawRect(
//         Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT),
//         Paint()..color = Colors.white
//     );
//
//     // Draw all sections
//     _drawBorder(canvas);
//     double currentY = _drawHeader(canvas, config);
//     currentY = _drawStudentInfoRow(canvas, config, currentY);
//     currentY = _drawIdAndPhoneSection(canvas, config, currentY);
//     currentY = _drawAnswerSection(canvas, config.numberOfQuestions, currentY);
//     _drawFooter(canvas);
//
//     // Draw answer key if provided
//     if (config.correctAnswers.isNotEmpty) {
//       _drawAnswerKey(canvas, config.correctAnswers, config.numberOfQuestions);
//     }
//
//     // Convert to image and save
//     final picture = recorder.endRecording();
//     final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
//     final bytes = byteData!.buffer.asUint8List();
//
//     final directory = await getTemporaryDirectory();
//     final file = File('${directory.path}/omr_sheet_${DateTime.now().millisecondsSinceEpoch}.png');
//     await file.writeAsBytes(bytes);
//
//     return file;
//   }
//
//   static void _drawBorder(Canvas canvas) {
//     final borderPaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;
//
//     canvas.drawRect(
//         Rect.fromLTWH(
//             PAGE_MARGIN,
//             PAGE_MARGIN,
//             A4_WIDTH - 2 * PAGE_MARGIN,
//             A4_HEIGHT - 2 * PAGE_MARGIN
//         ),
//         borderPaint
//     );
//   }
//
//   static double _drawHeader(Canvas canvas, OMRExamConfig config) {
//     double y = PAGE_MARGIN + 10;
//
//     // Institution name
//     final institutionPainter = TextPainter(
//       text: TextSpan(
//         text: "PROFESSIONAL EXAMINATION CENTER",
//         style: TextStyle(
//           fontSize: 14,
//           fontWeight: FontWeight.bold,
//           color: Colors.blue[900],
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     institutionPainter.layout();
//     institutionPainter.paint(
//         canvas,
//         Offset((A4_WIDTH - institutionPainter.width) / 2, y)
//     );
//
//     y += 20;
//
//     // Exam title
//     final titlePainter = TextPainter(
//       text: TextSpan(
//         text: config.examName.toUpperCase(),
//         style: TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//           color: Colors.black,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(
//         canvas,
//         Offset((A4_WIDTH - titlePainter.width) / 2, y)
//     );
//
//     y += 25;
//
//     // Exam details
//     _drawExamDetails(canvas, config, y);
//
//     y += 20;
//
//     // Instructions
//     _drawInstructions(canvas, y);
//
//     return PAGE_MARGIN + HEADER_HEIGHT;
//   }
//
//   static void _drawExamDetails(Canvas canvas, OMRExamConfig config, double y) {
//     final detailStyle = TextStyle(fontSize: 10, color: Colors.black87);
//
//     // Date
//     final datePainter = TextPainter(
//       text: TextSpan(
//         text: 'Date: ${_formatDate(config.examDate)}',
//         style: detailStyle,
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     datePainter.layout();
//     datePainter.paint(canvas, Offset(PAGE_MARGIN + 20, y));
//
//     // Total Questions
//     final questionsPainter = TextPainter(
//       text: TextSpan(
//         text: 'Total Questions: ${config.numberOfQuestions}',
//         style: detailStyle,
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     questionsPainter.layout();
//     questionsPainter.paint(
//         canvas,
//         Offset((A4_WIDTH - questionsPainter.width) / 2, y)
//     );
//
//     // Duration
//     final durationPainter = TextPainter(
//       text: TextSpan(text: 'Duration: 3 Hours', style: detailStyle),
//       textDirection: TextDirection.ltr,
//     );
//     durationPainter.layout();
//     durationPainter.paint(
//         canvas,
//         Offset(A4_WIDTH - PAGE_MARGIN - 20 - durationPainter.width, y)
//     );
//   }
//
//   static void _drawInstructions(Canvas canvas, double y) {
//     final instructions = [
//       "• Use only BLACK/BLUE ball point pen",
//       "• Fill bubbles completely",
//       "• No correction fluid allowed",
//     ];
//
//     final instructionStyle = TextStyle(fontSize: 8, color: Colors.black87);
//     double instructionY = y;
//
//     for (final instruction in instructions) {
//       final painter = TextPainter(
//         text: TextSpan(text: instruction, style: instructionStyle),
//         textDirection: TextDirection.ltr,
//       );
//       painter.layout();
//       painter.paint(canvas, Offset(PAGE_MARGIN + 20, instructionY));
//       instructionY += 10;
//     }
//   }
//
//   static double _drawStudentInfoRow(Canvas canvas, OMRExamConfig config, double startY) {
//     startY += 10;
//
//     // Section title
//     _drawSectionTitle(canvas, "CANDIDATE INFORMATION", startY);
//
//     startY += 25;
//
//     // Set number
//     final setLabelPainter = TextPainter(
//       text: TextSpan(
//         text: "SET:",
//         style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     setLabelPainter.layout();
//     setLabelPainter.paint(canvas, Offset(PAGE_MARGIN + 20, startY));
//
//     // Set bubbles (0-9)
//     double bubbleX = PAGE_MARGIN + 60;
//     for (int i = 0; i < 10; i++) {
//       _drawBubbleWithLabel(
//           canvas,
//           bubbleX + i * BUBBLE_SPACING,
//           startY - 2,
//           i.toString(),
//           i == config.setNumber
//       );
//     }
//
//     // Name field
//     final nameLabelPainter = TextPainter(
//       text: TextSpan(
//         text: "NAME:",
//         style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     nameLabelPainter.layout();
//     nameLabelPainter.paint(canvas, Offset(PAGE_MARGIN + 250, startY));
//
//     // Name line
//     canvas.drawLine(
//       Offset(PAGE_MARGIN + 290, startY + 10),
//       Offset(A4_WIDTH - PAGE_MARGIN - 20, startY + 10),
//       Paint()..color = Colors.black..strokeWidth = 1.0,
//     );
//
//     return startY + STUDENT_INFO_HEIGHT;
//   }
//
//   static double _drawIdAndPhoneSection(Canvas canvas, OMRExamConfig config, double startY) {
//     final columnWidth = (A4_WIDTH - 2 * PAGE_MARGIN - 30) / 2;
//
//     // Student ID column
//     _drawIdColumn(canvas, config.studentId, PAGE_MARGIN + 10, startY, columnWidth);
//
//     // Mobile number column
//     _drawPhoneColumn(
//         canvas,
//         config.mobileNumber,
//         PAGE_MARGIN + 20 + columnWidth,
//         startY,
//         columnWidth
//     );
//
//     return startY + ID_SECTION_HEIGHT;
//   }
//
//   static void _drawIdColumn(Canvas canvas, String studentId, double x, double y, double width) {
//     // Title
//     final titlePainter = TextPainter(
//       text: TextSpan(
//         text: "STUDENT ID (9 DIGITS)",
//         style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(x, y));
//
//     y += 20;
//
//     // Background
//     final bgPaint = Paint()
//       ..color = Colors.grey[100]!
//       ..style = PaintingStyle.fill;
//     canvas.drawRect(Rect.fromLTWH(x, y, width, 110), bgPaint);
//
//     // Border
//     final borderPaint = Paint()
//       ..color = Colors.grey[400]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;
//     canvas.drawRect(Rect.fromLTWH(x, y, width, 110), borderPaint);
//
//     // Draw digit columns
//     for (int digit = 0; digit < 9; digit++) {
//       double digitX = x + 5 + digit * BUBBLE_SPACING;
//
//       // Digit header
//       final digitPainter = TextPainter(
//         text: TextSpan(
//           text: (digit + 1).toString(),
//           style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
//         ),
//         textDirection: TextDirection.ltr,
//       );
//       digitPainter.layout();
//       digitPainter.paint(canvas, Offset(digitX + 2, y + 5));
//
//       // Bubbles 0-9
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digit < studentId.length &&
//             studentId[digit] == num.toString();
//         _drawBubble(
//             canvas,
//             digitX,
//             y + 20 + num * 9,
//             isFilled
//         );
//
//         // Number labels on first column
//         if (digit == 0) {
//           final numPainter = TextPainter(
//             text: TextSpan(
//               text: num.toString(),
//               style: TextStyle(fontSize: 7),
//             ),
//             textDirection: TextDirection.ltr,
//           );
//           numPainter.layout();
//           numPainter.paint(canvas, Offset(x - 10, y + 20 + num * 9));
//         }
//       }
//     }
//   }
//
//   static void _drawPhoneColumn(Canvas canvas, String phoneNumber, double x, double y, double width) {
//     // Title
//     final titlePainter = TextPainter(
//       text: TextSpan(
//         text: "MOBILE NUMBER (11 DIGITS)",
//         style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(x, y));
//
//     y += 20;
//
//     // Background
//     final bgPaint = Paint()
//       ..color = Colors.grey[100]!
//       ..style = PaintingStyle.fill;
//     canvas.drawRect(Rect.fromLTWH(x, y, width, 110), bgPaint);
//
//     // Border
//     final borderPaint = Paint()
//       ..color = Colors.grey[400]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;
//     canvas.drawRect(Rect.fromLTWH(x, y, width, 110), borderPaint);
//
//     // Draw digit columns
//     for (int digit = 0; digit < 11; digit++) {
//       double digitX = x + 5 + digit * BUBBLE_SPACING;
//
//       // Digit header
//       final digitPainter = TextPainter(
//         text: TextSpan(
//           text: (digit + 1).toString(),
//           style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
//         ),
//         textDirection: TextDirection.ltr,
//       );
//       digitPainter.layout();
//       digitPainter.paint(canvas, Offset(digitX + 2, y + 5));
//
//       // Bubbles 0-9
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digit < phoneNumber.length &&
//             phoneNumber[digit] == num.toString();
//         _drawBubble(
//             canvas,
//             digitX,
//             y + 20 + num * 9,
//             isFilled
//         );
//       }
//     }
//   }
//
//   static double _drawAnswerSection(Canvas canvas, int numberOfQuestions, double startY) {
//     startY += 10;
//
//     // Section title
//     _drawSectionTitle(canvas, "ANSWER SECTION", startY);
//
//     startY += 25;
//
//     // Calculate layout
//     final questionsPerColumn = (numberOfQuestions / 3).ceil();
//     final columnWidth = (A4_WIDTH - 2 * PAGE_MARGIN - 40) / 3;
//
//     // Draw three columns
//     for (int col = 0; col < 3; col++) {
//       final columnX = PAGE_MARGIN + 10 + col * (columnWidth + COLUMN_SPACING);
//       _drawAnswerColumn(
//           canvas,
//           columnX,
//           startY,
//           col * questionsPerColumn + 1,
//           (col + 1) * questionsPerColumn > numberOfQuestions
//               ? numberOfQuestions
//               : (col + 1) * questionsPerColumn,
//           columnWidth
//       );
//     }
//
//     return A4_HEIGHT - PAGE_MARGIN - FOOTER_HEIGHT;
//   }
//
//   static void _drawAnswerColumn(
//       Canvas canvas,
//       double x,
//       double y,
//       int startQ,
//       int endQ,
//       double width
//       ) {
//     // Column header
//     final headerPainter = TextPainter(
//       text: TextSpan(
//         text: "Q${startQ.toString().padLeft(2, '0')} - Q${endQ.toString().padLeft(2, '0')}",
//         style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     headerPainter.layout();
//     headerPainter.paint(canvas, Offset(x, y));
//
//     y += 15;
//
//     // Draw questions
//     for (int q = startQ; q <= endQ; q++) {
//       // Question number
//       final qPainter = TextPainter(
//         text: TextSpan(
//           text: q.toString().padLeft(2, '0'),
//           style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
//         ),
//         textDirection: TextDirection.ltr,
//       );
//       qPainter.layout();
//       qPainter.paint(canvas, Offset(x, y));
//
//       // Options A, B, C, D, E
//       for (int opt = 0; opt < 5; opt++) {
//         final optionX = x + 20 + opt * 14;
//         final optionChar = String.fromCharCode(65 + opt);
//
//         // Option label
//         final optPainter = TextPainter(
//           text: TextSpan(
//             text: optionChar,
//             style: TextStyle(fontSize: 7),
//           ),
//           textDirection: TextDirection.ltr,
//         );
//         optPainter.layout();
//         optPainter.paint(canvas, Offset(optionX + 2, y - 8));
//
//         // Bubble
//         _drawBubble(canvas, optionX, y, false);
//       }
//
//       y += LINE_HEIGHT;
//     }
//   }
//
//   static void _drawFooter(Canvas canvas) {
//     final footerY = A4_HEIGHT - PAGE_MARGIN - FOOTER_HEIGHT;
//
//     // Divider line
//     canvas.drawLine(
//       Offset(PAGE_MARGIN + 10, footerY),
//       Offset(A4_WIDTH - PAGE_MARGIN - 10, footerY),
//       Paint()..color = Colors.black..strokeWidth = 1.0,
//     );
//
//     final signatureY = footerY + 15;
//
//     // Student signature
//     _drawSignatureField(
//         canvas,
//         "CANDIDATE'S SIGNATURE",
//         PAGE_MARGIN + 20,
//         signatureY
//     );
//
//     // Invigilator signature
//     _drawSignatureField(
//         canvas,
//         "INVIGILATOR'S SIGNATURE",
//         A4_WIDTH / 2 - 60,
//         signatureY
//     );
//
//     // Date
//     _drawSignatureField(
//         canvas,
//         "DATE",
//         A4_WIDTH - PAGE_MARGIN - 120,
//         signatureY
//     );
//
//     // Footer note
//     final notePainter = TextPainter(
//       text: TextSpan(
//         text: "Important: Fill bubbles completely with blue/black pen only",
//         style: TextStyle(fontSize: 7, color: Colors.grey[700], fontStyle: FontStyle.italic),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     notePainter.layout();
//     notePainter.paint(
//         canvas,
//         Offset((A4_WIDTH - notePainter.width) / 2, signatureY + 30)
//     );
//   }
//
//   static void _drawSignatureField(Canvas canvas, String label, double x, double y) {
//     final labelPainter = TextPainter(
//       text: TextSpan(
//         text: label,
//         style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     labelPainter.layout();
//     labelPainter.paint(canvas, Offset(x, y));
//
//     // Signature line
//     canvas.drawLine(
//       Offset(x, y + 12),
//       Offset(x + 100, y + 12),
//       Paint()..color = Colors.black..strokeWidth = 0.8,
//     );
//   }
//
//   static void _drawSectionTitle(Canvas canvas, String title, double y) {
//     final bgPaint = Paint()
//       ..color = Colors.blue[800]!
//       ..style = PaintingStyle.fill;
//
//     final titlePainter = TextPainter(
//       text: TextSpan(
//         text: title,
//         style: TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.bold,
//           color: Colors.white,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//
//     // Background rectangle
//     canvas.drawRect(
//         Rect.fromLTWH(
//             PAGE_MARGIN + 10,
//             y - 2,
//             titlePainter.width + 16,
//             titlePainter.height + 4
//         ),
//         bgPaint
//     );
//
//     // Title text
//     titlePainter.paint(canvas, Offset(PAGE_MARGIN + 18, y));
//   }
//
//   static void _drawBubble(Canvas canvas, double x, double y, bool filled) {
//     final paint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     canvas.drawCircle(Offset(x + BUBBLE_RADIUS, y + BUBBLE_RADIUS), BUBBLE_RADIUS, paint);
//
//     if (filled) {
//       final fillPaint = Paint()
//         ..color = Colors.black
//         ..style = PaintingStyle.fill;
//       canvas.drawCircle(
//           Offset(x + BUBBLE_RADIUS, y + BUBBLE_RADIUS),
//           BUBBLE_RADIUS - 0.5,
//           fillPaint
//       );
//     }
//   }
//
//   static void _drawBubbleWithLabel(Canvas canvas, double x, double y, String label, bool filled) {
//     // Draw bubble
//     _drawBubble(canvas, x, y, filled);
//
//     // Draw label below
//     final labelPainter = TextPainter(
//       text: TextSpan(
//         text: label,
//         style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     labelPainter.layout();
//     labelPainter.paint(canvas, Offset(x + 1, y + 10));
//   }
//
//   static void _drawAnswerKey(Canvas canvas, List<String> correctAnswers, int totalQuestions) {
//     final questionsPerColumn = (totalQuestions / 3).ceil();
//     final columnWidth = (A4_WIDTH - 2 * PAGE_MARGIN - 40) / 3;
//
//     // Calculate answer section start Y
//     final answerSectionY = PAGE_MARGIN + HEADER_HEIGHT + 10 + STUDENT_INFO_HEIGHT + ID_SECTION_HEIGHT + 10 + 25 + 15;
//
//     for (int i = 0; i < correctAnswers.length && i < totalQuestions; i++) {
//       final col = i ~/ questionsPerColumn;
//       final rowInColumn = i % questionsPerColumn;
//       final optionIndex = correctAnswers[i].codeUnitAt(0) - 65;
//
//       if (optionIndex >= 0 && optionIndex < 5) {
//         final columnX = PAGE_MARGIN + 10 + col * (columnWidth + COLUMN_SPACING);
//         final questionY = answerSectionY + rowInColumn * LINE_HEIGHT;
//         final optionX = columnX + 20 + optionIndex * 14;
//
//         // Fill correct answer in red
//         final redPaint = Paint()
//           ..color = Colors.red
//           ..style = PaintingStyle.fill;
//         canvas.drawCircle(
//             Offset(optionX + BUBBLE_RADIUS, questionY + BUBBLE_RADIUS),
//             BUBBLE_RADIUS - 0.5,
//             redPaint
//         );
//       }
//     }
//
//     // Draw watermark
//     canvas.save();
//     canvas.translate(A4_WIDTH / 2, A4_HEIGHT / 2);
//     canvas.rotate(-0.5);
//
//     final watermarkPainter = TextPainter(
//       text: TextSpan(
//         text: "ANSWER KEY",
//         style: TextStyle(
//           fontSize: 60,
//           fontWeight: FontWeight.bold,
//           color: Colors.red.withOpacity(0.1),
//           letterSpacing: 10,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     watermarkPainter.layout();
//     watermarkPainter.paint(
//         canvas,
//         Offset(-watermarkPainter.width / 2, -watermarkPainter.height / 2)
//     );
//
//     canvas.restore();
//   }
//
//   static String _formatDate(DateTime date) {
//     final months = [
//       'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
//       'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
//     ];
//     return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
//   }
// }




import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'omr_models.dart';

class OMRGenerator {
  static const double A4_WIDTH = 595.0;
  static const double A4_HEIGHT = 842.0;
  static const double MARGIN = 25.0;
  static const double BUBBLE_RADIUS = 4.0;
  static const double COLUMN_SPACING = 12.0;

  static Future<File> generateOMRSheet(OMRExamConfig config) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT), Paint()..color = Colors.white);

    _drawProfessionalBorder(canvas);
    _drawProfessionalHeader(canvas, config);
    _drawStudentInfoSection(canvas, config);
    _drawAnswerSectionWithThreeColumns(canvas, config.numberOfQuestions);
    _drawProfessionalFooter(canvas);

    if (config.correctAnswers.isNotEmpty) {
      _drawAnswerKey(canvas, config.correctAnswers, config.numberOfQuestions);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/omr_sheet_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);

    return file;
  }

  // === FRAME & HEADER ===
  static void _drawProfessionalBorder(Canvas canvas) {
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRect(
        Rect.fromLTWH(MARGIN, MARGIN, A4_WIDTH - 2 * MARGIN, A4_HEIGHT - 2 * MARGIN),
        borderPaint);
  }

  static void _drawProfessionalHeader(Canvas canvas, OMRExamConfig config) {
    // Header Title
    final headerPainter = TextPainter(
      text: TextSpan(
        text: "PROFESSIONAL EXAM OMR ANSWER SHEET",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[900]),
      ),
      textDirection: TextDirection.ltr,
    );
    headerPainter.layout();
    headerPainter.paint(canvas, Offset(A4_WIDTH / 2 - headerPainter.width / 2, MARGIN + 5));

    // Exam Name
    final examPainter = TextPainter(
      text: TextSpan(
        text: config.examName.toUpperCase(),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    );
    examPainter.layout();
    examPainter.paint(canvas, Offset(A4_WIDTH / 2 - examPainter.width / 2, MARGIN + 25));

    // Details
    final detailStyle = const TextStyle(fontSize: 9, color: Colors.black87);
    final datePainter = TextPainter(
      text: TextSpan(text: "Date: ${_formatDate(config.examDate)}", style: detailStyle),
      textDirection: TextDirection.ltr,
    );
    datePainter.layout();
    datePainter.paint(canvas, Offset(MARGIN + 10, MARGIN + 45));

    final totalPainter = TextPainter(
      text: TextSpan(text: "Total Questions: ${config.numberOfQuestions}", style: detailStyle),
      textDirection: TextDirection.ltr,
    );
    totalPainter.layout();
    totalPainter.paint(canvas, Offset(A4_WIDTH / 2 - totalPainter.width / 2, MARGIN + 45));

    final timePainter = TextPainter(
      text: const TextSpan(text: "Time: 3 Hours", style: TextStyle(fontSize: 9)),
      textDirection: TextDirection.ltr,
    );
    timePainter.layout();
    timePainter.paint(canvas, Offset(A4_WIDTH - MARGIN - 10 - timePainter.width, MARGIN + 45));

    _drawInstructionsBox(canvas, MARGIN + 62);
  }

  static void _drawInstructionsBox(Canvas canvas, double startY) {
    final boxPaint = Paint()..color = Colors.grey[100]!;
    final borderPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(MARGIN + 10, startY, A4_WIDTH - 2 * MARGIN - 20, 38), boxPaint);
    canvas.drawRect(Rect.fromLTWH(MARGIN + 10, startY, A4_WIDTH - 2 * MARGIN - 20, 38), borderPaint);

    final instructions = [
      "• Use BLACK/BLUE pen only. Fill bubbles completely.",
      "• Avoid stray marks. Erase fully to change answers."
    ];
    double y = startY + 10;
    for (var t in instructions) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: const TextStyle(fontSize: 8, color: Colors.black87)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(MARGIN + 18, y));
      y += 10;
    }
  }

  // === STUDENT INFO ===
  static void _drawStudentInfoSection(Canvas canvas, OMRExamConfig config) {
    final startY = MARGIN + 115;
    _drawSectionTitle(canvas, "STUDENT INFORMATION", startY - 5);

    // Row 1: Set Number + Student Name
    _drawSetNumberAndName(canvas, config, startY + 18);

    // Row 2: ID & Mobile
    _drawIdAndMobileRow(canvas, config, startY + 55);
  }

  static void _drawSectionTitle(Canvas canvas, String title, double y) {
    final bgPaint = Paint()..color = Colors.blue[800]!;
    canvas.drawRect(Rect.fromLTWH(MARGIN + 10, y, 180, 14), bgPaint);
    final tp = TextPainter(
      text: TextSpan(
          text: title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(MARGIN + 15, y + 2));
  }

  static void _drawSetNumberAndName(Canvas canvas, OMRExamConfig config, double y) {
    final setPainter = TextPainter(
      text: const TextSpan(
          text: "SET NO:",
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
      textDirection: TextDirection.ltr,
    );
    setPainter.layout();
    setPainter.paint(canvas, Offset(MARGIN + 15, y));

    double x = MARGIN + 65;
    for (int i = 0; i < 10; i++) {
      _drawProfessionalBubble(canvas, x + i * 15, y - 3, i == config.setNumber);
    }

    final namePainter = TextPainter(
      text: const TextSpan(
          text: "STUDENT NAME:",
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
      textDirection: TextDirection.ltr,
    );
    namePainter.layout();
    namePainter.paint(canvas, Offset(A4_WIDTH / 2 - 40, y));
    canvas.drawLine(Offset(A4_WIDTH / 2 + 55, y + 10), Offset(A4_WIDTH - MARGIN - 30, y + 10),
        Paint()..color = Colors.black);
  }

  static void _drawIdAndMobileRow(Canvas canvas, OMRExamConfig config, double y) {
    final leftX = MARGIN + 15;
    final rightX = A4_WIDTH / 2 + 5;

    _drawColumnWithBubbles(canvas, leftX, "STUDENT ID (9 digits)", config.studentId, 9, y);
    _drawColumnWithBubbles(canvas, rightX, "MOBILE NUMBER (11 digits)", config.mobileNumber, 11, y);
  }

  static void _drawColumnWithBubbles(Canvas canvas, double x, String label, String value,
      int length, double y) {
    final title = TextPainter(
      text: TextSpan(text: label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    title.layout();
    title.paint(canvas, Offset(x, y));

    for (int pos = 0; pos < length; pos++) {
      final dx = x + 8 + pos * 14;
      for (int n = 0; n < 10; n++) {
        final filled = pos < value.length && value[pos] == n.toString();
        _drawProfessionalBubble(canvas, dx, y + 14 + n * 11, filled);
        if (pos == 0) {
          final np = TextPainter(
              text: TextSpan(text: n.toString(), style: const TextStyle(fontSize: 7)),
              textDirection: TextDirection.ltr);
          np.layout();
          np.paint(canvas, Offset(x - 5, y + 14 + n * 11));
        }
      }
    }
  }

  // === ANSWER SECTION ===
  static void _drawAnswerSectionWithThreeColumns(Canvas canvas, int count) {
    final startY = MARGIN + 345;
    _drawSectionTitle(canvas, "ANSWER SHEET", startY - 5);
    _drawOptionsLegend(canvas, startY + 20);

    final perCol = (count / 3).ceil();
    final colWidth = (A4_WIDTH - 2 * MARGIN - 30) / 3;
    for (int col = 0; col < 3; col++) {
      final x = MARGIN + 15 + col * (colWidth + COLUMN_SPACING);
      final startQ = col * perCol + 1;
      final endQ = (startQ + perCol - 1).clamp(1, count);
      _drawQuestionColumn(canvas, x, startY + 40, startQ, endQ);
    }
  }

  static void _drawOptionsLegend(Canvas canvas, double y) {
    final tp = TextPainter(
      text: const TextSpan(
          text: "OPTIONS: A • B • C • D • E",
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(A4_WIDTH / 2 - tp.width / 2, y));
  }

  static void _drawQuestionColumn(Canvas canvas, double x, double y, int start, int end) {
    for (int q = start; q <= end; q++) {
      final yPos = y + (q - start) * 15;
      final qNum = TextPainter(
          text: TextSpan(
              text: "Q${q.toString().padLeft(2, '0')}",
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black)),
          textDirection: TextDirection.ltr);
      qNum.layout();
      qNum.paint(canvas, Offset(x, yPos));

      for (int o = 0; o < 5; o++) {
        final ox = x + 25 + o * 14;
        _drawProfessionalBubble(canvas, ox, yPos, false);
        final op = TextPainter(
            text: TextSpan(text: String.fromCharCode(65 + o), style: const TextStyle(fontSize: 7)),
            textDirection: TextDirection.ltr);
        op.layout();
        op.paint(canvas, Offset(ox + 2, yPos - 9));
      }
    }
  }

  // === FOOTER ===
  static void _drawProfessionalFooter(Canvas canvas) {
    final y = A4_HEIGHT - MARGIN - 45;
    canvas.drawLine(Offset(MARGIN + 15, y), Offset(A4_WIDTH - MARGIN - 15, y),
        Paint()..color = Colors.black);

    _drawSignature(canvas, "STUDENT’S SIGNATURE", MARGIN + 25, y + 10);
    _drawSignature(canvas, "INVIGILATOR’S SIGNATURE", A4_WIDTH / 2 - 60, y + 10);
    _drawSignature(canvas, "DATE", A4_WIDTH - MARGIN - 120, y + 10);

    final note = TextPainter(
      text: TextSpan(
        text: "Note: Ensure all bubbles are filled properly for machine evaluation.",
        style: TextStyle(fontSize: 7, color: Colors.grey[600], fontStyle: FontStyle.italic),
      ),
      textDirection: TextDirection.ltr,
    );
    note.layout();
    note.paint(canvas, Offset(A4_WIDTH / 2 - note.width / 2, y + 35));
  }

  static void _drawSignature(Canvas canvas, String label, double x, double y) {
    final tp = TextPainter(
      text: TextSpan(text: label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(x, y));
    canvas.drawLine(Offset(x, y + 12), Offset(x + 100, y + 12), Paint()..color = Colors.black);
  }

  // === SHARED DRAW METHODS ===
  static void _drawProfessionalBubble(Canvas canvas, double x, double y, bool filled) {
    final border = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final fill = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(x + 4, y + 4), BUBBLE_RADIUS, border);
    if (filled) canvas.drawCircle(Offset(x + 4, y + 4), BUBBLE_RADIUS - 0.8, fill);
  }

  static void _drawAnswerKey(Canvas canvas, List<String> answers, int count) {
    final red = Paint()..color = Colors.red;
    final perCol = (count / 3).ceil();
    final colWidth = (A4_WIDTH - 2 * MARGIN - 30) / 3;

    for (int i = 0; i < answers.length; i++) {
      final col = i ~/ perCol;
      final qInCol = i % perCol;
      final opt = answers[i].codeUnitAt(0) - 65;
      final x = MARGIN + 15 + col * (colWidth + COLUMN_SPACING) + 25 + opt * 14;
      final y = MARGIN + 385 + qInCol * 15;
      canvas.drawCircle(Offset(x + 4, y + 4), BUBBLE_RADIUS - 0.5, red);
    }
  }

  static String _formatDate(DateTime d) {
    const m = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}






// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'omr_models.dart';
//
// class OMRGenerator {
//   static const double A4_WIDTH = 595.0;
//   static const double A4_HEIGHT = 842.0;
//   static const double MARGIN = 20.0; // Reduced margin for more content space
//   static const double BUBBLE_RADIUS = 3.5;
//   static const double BUBBLE_SPACING = 14.0;
//   static const double COLUMN_SPACING = 10.0;
//
//   // Section heights calculated to fit A4
//   static const double HEADER_HEIGHT = 110.0;
//   static const double STUDENT_INFO_HEIGHT = 190.0;
//   static const double ANSWER_SECTION_HEIGHT = 400.0;
//   static const double FOOTER_HEIGHT = 80.0;
//
//   static Future<File> generateOMRSheet(OMRExamConfig config) async {
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//
//     // Set background to white
//     canvas.drawRect(Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT), Paint()..color = Colors.white);
//
//     // Draw professional border
//     _drawProfessionalBorder(canvas);
//
//     // Calculate section positions
//     double currentY = MARGIN;
//
//     // Draw sections with calculated positions
//     currentY = _drawProfessionalHeader(canvas, config, currentY);
//     currentY = _drawStudentInfoSection(canvas, config, currentY);
//     currentY = _drawAnswerSectionWithThreeColumns(canvas, config.numberOfQuestions, currentY);
//     _drawProfessionalFooter(canvas, currentY);
//
//     // Draw answer key if provided
//     if (config.correctAnswers.isNotEmpty) {
//       _drawAnswerKey(canvas, config.correctAnswers, config.numberOfQuestions);
//     }
//
//     final picture = recorder.endRecording();
//     final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
//     final bytes = byteData!.buffer.asUint8List();
//
//     final directory = await getTemporaryDirectory();
//     final file = File('${directory.path}/omr_sheet_${DateTime.now().millisecondsSinceEpoch}.png');
//     await file.writeAsBytes(bytes);
//
//     return file;
//   }
//
//   static void _drawProfessionalBorder(Canvas canvas) {
//     // Outer border
//     final outerBorderPaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.5;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN, MARGIN,
//         A4_WIDTH - 2*MARGIN, A4_HEIGHT - 2*MARGIN), outerBorderPaint);
//
//     // Inner border
//     final innerBorderPaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN+5, MARGIN+5,
//         A4_WIDTH - 2*MARGIN - 10, A4_HEIGHT - 2*MARGIN - 10), innerBorderPaint);
//   }
//
//   static double _drawProfessionalHeader(Canvas canvas, OMRExamConfig config, double startY) {
//     final double contentWidth = A4_WIDTH - 2 * MARGIN;
//
//     // Institution Header
//     final institutionStyle = TextStyle(
//       fontSize: 14,
//       fontWeight: FontWeight.bold,
//       color: Colors.blue[800],
//     );
//
//     final institutionPainter = TextPainter(
//       text: TextSpan(text: "PROFESSIONAL COACHING CENTER", style: institutionStyle),
//       textDirection: TextDirection.ltr,
//     );
//     institutionPainter.layout();
//     institutionPainter.paint(canvas, Offset(A4_WIDTH/2 - institutionPainter.width/2, startY));
//
//     // Exam Title
//     final titleStyle = TextStyle(
//       fontSize: 16,
//       fontWeight: FontWeight.bold,
//       color: Colors.black,
//     );
//
//     final titlePainter = TextPainter(
//       text: TextSpan(text: config.examName.toUpperCase(), style: titleStyle),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(A4_WIDTH/2 - titlePainter.width/2, startY + 22));
//
//     // Exam Details Row - Compact layout
//     final detailsStyle = TextStyle(
//       fontSize: 9,
//       fontWeight: FontWeight.normal,
//       color: Colors.black87,
//     );
//
//     // Date
//     final dateText = 'Date: ${_formatDate(config.examDate)}';
//     final datePainter = TextPainter(
//       text: TextSpan(text: dateText, style: detailsStyle),
//       textDirection: TextDirection.ltr,
//     );
//     datePainter.layout();
//     datePainter.paint(canvas, Offset(MARGIN + 10, startY + 50));
//
//     // Total Questions
//     final questionsText = 'Questions: ${config.numberOfQuestions}';
//     final questionsPainter = TextPainter(
//       text: TextSpan(text: questionsText, style: detailsStyle),
//       textDirection: TextDirection.ltr,
//     );
//     questionsPainter.layout();
//     questionsPainter.paint(canvas, Offset(A4_WIDTH/2 - questionsPainter.width/2, startY + 50));
//
//     // Time
//     final timeText = 'Time: 3 Hours';
//     final timePainter = TextPainter(
//       text: TextSpan(text: timeText, style: detailsStyle),
//       textDirection: TextDirection.ltr,
//     );
//     timePainter.layout();
//     timePainter.paint(canvas, Offset(A4_WIDTH - MARGIN - 10 - timePainter.width, startY + 50));
//
//     // Professional Instructions Box - More compact
//     final double instructionsY = startY + 65;
//     _drawInstructionsBox(canvas, instructionsY, contentWidth);
//
//     return startY + HEADER_HEIGHT;
//   }
//
//   static void _drawInstructionsBox(Canvas canvas, double startY, double width) {
//     // Box background
//     final boxPaint = Paint()
//       ..color = Colors.grey[50]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN + 5, startY, width - 10, 30), boxPaint);
//
//     // Box border
//     final borderPaint = Paint()
//       ..color = Colors.grey[400]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN + 5, startY, width - 10, 30), borderPaint);
//
//     // Compact instructions
//     final instructions = [
//       "• Use BLACK/BLUE ball pen • Fill circles completely",
//       "• No stray marks • Erase completely to change"
//     ];
//
//     double instructionY = startY + 10;
//     for (var instruction in instructions) {
//       final instructionPainter = TextPainter(
//         text: TextSpan(text: instruction, style: TextStyle(fontSize: 8, color: Colors.black87, fontWeight: FontWeight.w500)),
//         textDirection: TextDirection.ltr,
//       );
//       instructionPainter.layout();
//       instructionPainter.paint(canvas, Offset(MARGIN + 10, instructionY));
//       instructionY += 9;
//     }
//   }
//
//   static double _drawStudentInfoSection(Canvas canvas, OMRExamConfig config, double startY) {
//     final double contentWidth = A4_WIDTH - 2 * MARGIN;
//
//     // Section Title with background
//     _drawSectionTitleWithBackground(canvas, "STUDENT INFORMATION", startY, contentWidth);
//
//     // Set Number and Basic Info Row
//     _drawSetNumberAndBasicInfo(canvas, config, startY + 20, contentWidth);
//
//     // Student ID and Mobile Number in two columns - More compact
//     _drawStudentIdColumn(canvas, config.studentId, startY + 55, contentWidth);
//     _drawMobileNumberColumn(canvas, config.mobileNumber, startY + 55, contentWidth);
//
//     return startY + STUDENT_INFO_HEIGHT;
//   }
//
//   static void _drawSectionTitleWithBackground(Canvas canvas, String title, double y, double width) {
//     final style = TextStyle(
//       fontSize: 11,
//       fontWeight: FontWeight.bold,
//       color: Colors.white,
//     );
//
//     final painter = TextPainter(
//       text: TextSpan(text: title, style: style),
//       textDirection: TextDirection.ltr,
//     );
//     painter.layout();
//
//     // Background
//     final bgPaint = Paint()
//       ..color = Colors.blue[800]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(
//         MARGIN + 5,
//         y,
//         painter.width + 10,
//         painter.height + 4
//     ), bgPaint);
//
//     painter.paint(canvas, Offset(MARGIN + 10, y + 2));
//   }
//
//   static void _drawSetNumberAndBasicInfo(Canvas canvas, OMRExamConfig config, double startY, double width) {
//     // Set Number Label
//     final setLabelPainter = TextPainter(
//       text: TextSpan(text: "SET:", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     setLabelPainter.layout();
//     setLabelPainter.paint(canvas, Offset(MARGIN + 10, startY));
//
//     // Draw set number bubbles (0-9) - More compact
//     final double bubbleStartX = MARGIN + 40;
//     for (int i = 0; i < 10; i++) {
//       _drawProfessionalBubbleWithNumber(canvas, bubbleStartX + i * 12, startY - 2, i, i == config.setNumber);
//     }
//
//     // Student Name Label (Placeholder) - More compact
//     final nameLabelPainter = TextPainter(
//       text: TextSpan(text: "NAME:", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     nameLabelPainter.layout();
//     final nameLabelX = A4_WIDTH / 2 - 30;
//     nameLabelPainter.paint(canvas, Offset(nameLabelX, startY));
//
//     // Name Underline - Shorter
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 0.8;
//     canvas.drawLine(
//         Offset(nameLabelX, startY + 10),
//         Offset(nameLabelX + 120, startY + 10),
//         linePaint
//     );
//   }
//
//   static void _drawStudentIdColumn(Canvas canvas, String studentId, double startY, double width) {
//     final double columnWidth = (width - 20) / 2;
//     final double columnX = MARGIN + 10;
//
//     // Column Title
//     final titlePainter = TextPainter(
//       text: TextSpan(text: "STUDENT ID (9 digits)", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(columnX, startY));
//
//     // Column background - More compact
//     final bgPaint = Paint()
//       ..color = Colors.grey[50]!
//       ..style = PaintingStyle.fill;
//
//     final columnHeight = 120.0;
//     canvas.drawRect(Rect.fromLTWH(columnX - 2, startY + 8, columnWidth, columnHeight), bgPaint);
//
//     final borderPaint = Paint()
//       ..color = Colors.grey[300]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;
//
//     canvas.drawRect(Rect.fromLTWH(columnX - 2, startY + 8, columnWidth, columnHeight), borderPaint);
//
//     // Draw student ID bubbles - More compact
//     for (int digitPos = 0; digitPos < 9; digitPos++) {
//       final double digitX = columnX + 5 + digitPos * 11; // Reduced spacing
//
//       // Digit position number
//       final posPainter = TextPainter(
//         text: TextSpan(text: (digitPos + 1).toString(), style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.blue[800])),
//         textDirection: TextDirection.ltr,
//       );
//       posPainter.layout();
//       posPainter.paint(canvas, Offset(digitX + 1, startY + 18));
//
//       // Bubbles for this digit position - More compact
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digitPos < studentId.length &&
//             studentId[digitPos] == num.toString();
//         _drawProfessionalBubble(canvas, digitX, startY + 25 + num * 9, isFilled); // Reduced spacing
//
//         // Number label on left side
//         if (digitPos == 0) {
//           final numPainter = TextPainter(
//             text: TextSpan(text: num.toString(), style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold)),
//             textDirection: TextDirection.ltr,
//           );
//           numPainter.layout();
//           numPainter.paint(canvas, Offset(columnX, startY + 27 + num * 9));
//         }
//       }
//     }
//   }
//
//   static void _drawMobileNumberColumn(Canvas canvas, String mobileNumber, double startY, double width) {
//     final double columnWidth = (width - 20) / 2;
//     final double columnX = A4_WIDTH / 2 + 5;
//
//     // Column Title
//     final titlePainter = TextPainter(
//       text: TextSpan(text: "MOBILE NO. (11 digits)", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(columnX, startY));
//
//     // Column background - More compact
//     final bgPaint = Paint()
//       ..color = Colors.grey[50]!
//       ..style = PaintingStyle.fill;
//
//     final columnHeight = 120.0;
//     canvas.drawRect(Rect.fromLTWH(columnX - 2, startY + 8, columnWidth, columnHeight), bgPaint);
//
//     final borderPaint = Paint()
//       ..color = Colors.grey[300]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;
//
//     canvas.drawRect(Rect.fromLTWH(columnX - 2, startY + 8, columnWidth, columnHeight), borderPaint);
//
//     // Draw mobile number bubbles - More compact for 11 digits
//     for (int digitPos = 0; digitPos < 11; digitPos++) {
//       final double digitX = columnX + 5 + digitPos * 10; // Even more reduced spacing for 11 digits
//
//       // Digit position number
//       final posPainter = TextPainter(
//         text: TextSpan(text: (digitPos + 1).toString(), style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.blue[800])),
//         textDirection: TextDirection.ltr,
//       );
//       posPainter.layout();
//       posPainter.paint(canvas, Offset(digitX, startY + 18));
//
//       // Bubbles for this digit position - More compact
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digitPos < mobileNumber.length &&
//             mobileNumber[digitPos] == num.toString();
//         _drawProfessionalBubble(canvas, digitX, startY + 25 + num * 9, isFilled);
//
//         // Number label on left side
//         if (digitPos == 0) {
//           final numPainter = TextPainter(
//             text: TextSpan(text: num.toString(), style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold)),
//             textDirection: TextDirection.ltr,
//           );
//           numPainter.layout();
//           numPainter.paint(canvas, Offset(columnX, startY + 27 + num * 9));
//         }
//       }
//     }
//   }
//
//   static double _drawAnswerSectionWithThreeColumns(Canvas canvas, int numberOfQuestions, double startY) {
//     final double contentWidth = A4_WIDTH - 2 * MARGIN;
//
//     // Section Title with background
//     _drawSectionTitleWithBackground(canvas, "ANSWER SHEET", startY, contentWidth);
//
//     // Options Legend
//     _drawOptionsLegend(canvas, startY + 15);
//
//     // Draw questions in THREE columns with precise calculation
//     final questionsPerColumn = (numberOfQuestions / 3).ceil();
//     final columnWidth = (contentWidth - 2 * COLUMN_SPACING) / 3;
//
//     // Calculate available height for questions
//     final double availableHeight = ANSWER_SECTION_HEIGHT - 30; // Reserve space for title and legend
//     final int maxQuestionsPerColumn = (availableHeight / 14).floor().toInt();
//
//     final int actualQuestionsPerColumn = questionsPerColumn > maxQuestionsPerColumn
//         ? maxQuestionsPerColumn
//         : questionsPerColumn;
//
//     for (int col = 0; col < 3; col++) {
//       final columnX = MARGIN + col * (columnWidth + COLUMN_SPACING);
//       _drawQuestionColumnThreeCol(canvas, columnX, startY + 25, col, numberOfQuestions, actualQuestionsPerColumn, columnWidth);
//     }
//
//     return startY + ANSWER_SECTION_HEIGHT;
//   }
//
//   static void _drawOptionsLegend(Canvas canvas, double startY) {
//     final legendText = "OPTIONS: A • B • C • D • E";
//     final legendPainter = TextPainter(
//       text: TextSpan(
//           text: legendText,
//           style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue[800])
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     legendPainter.layout();
//     legendPainter.paint(canvas, Offset(A4_WIDTH/2 - legendPainter.width/2, startY));
//   }
//
//   static void _drawQuestionColumnThreeCol(Canvas canvas, double startX, double startY, int colIndex, int totalQuestions, int questionsPerColumn, double columnWidth) {
//     final startQuestion = colIndex * questionsPerColumn + 1;
//     int endQuestion = (colIndex + 1) * questionsPerColumn;
//
//     // Ensure we don't exceed total questions
//     if (endQuestion > totalQuestions) {
//       endQuestion = totalQuestions;
//     }
//
//     final actualEnd = endQuestion;
//
//     // Column header with background
//     final headerBgPaint = Paint()
//       ..color = Colors.grey[200]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(startX, startY - 2, columnWidth, 12), headerBgPaint);
//
//     final headerPainter = TextPainter(
//       text: TextSpan(
//           text: "Q${startQuestion}-${actualEnd}",
//           style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87)
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     headerPainter.layout();
//     headerPainter.paint(canvas, Offset(startX + 2, startY));
//
//     // Questions - Compact layout
//     for (int q = startQuestion; q <= actualEnd; q++) {
//       if (q > totalQuestions) break;
//
//       final yPos = startY + 15 + (q - startQuestion) * 12; // Reduced spacing
//
//       // Question number with background
//       final qText = TextPainter(
//         text: TextSpan(text: 'Q${q.toString().padLeft(2)}', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white)),
//         textDirection: TextDirection.ltr,
//       );
//       qText.layout();
//
//       final qBgPaint = Paint()
//         ..color = Colors.blue[700]!
//         ..style = PaintingStyle.fill;
//
//       canvas.drawRect(Rect.fromLTWH(startX, yPos, qText.width + 2, qText.height), qBgPaint);
//       qText.paint(canvas, Offset(startX + 1, yPos));
//
//       // Options A, B, C, D, E - Compact
//       for (int option = 0; option < 5; option++) {
//         final optionChar = String.fromCharCode(65 + option);
//         final optionX = startX + 20 + option * 11; // Reduced spacing
//
//         // Option letter
//         final optionText = TextPainter(
//           text: TextSpan(text: optionChar, style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold)),
//           textDirection: TextDirection.ltr,
//         );
//         optionText.layout();
//         optionText.paint(canvas, Offset(optionX + 1, yPos));
//
//         // Professional bubble
//         _drawProfessionalBubble(canvas, optionX, yPos - 1, false);
//       }
//     }
//   }
//
//   static void _drawProfessionalFooter(Canvas canvas, double startY) {
//     final double footerTopY = startY;
//     final double contentWidth = A4_WIDTH - 2 * MARGIN;
//
//     // Top border line
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 0.8;
//     canvas.drawLine(Offset(MARGIN + 5, footerTopY), Offset(A4_WIDTH - MARGIN - 5, footerTopY), linePaint);
//
//     // Signature fields in three columns - Compact
//     final leftSignatureX = MARGIN + 10;
//     final middleSignatureX = A4_WIDTH / 2 - 40;
//     final rightSignatureX = A4_WIDTH - MARGIN - 90;
//
//     // Student Signature
//     _drawProfessionalSignatureField(canvas, "STUDENT", leftSignatureX, footerTopY + 8);
//
//     // Invigilator Signature
//     _drawProfessionalSignatureField(canvas, "INVIGILATOR", middleSignatureX, footerTopY + 8);
//
//     // Date field
//     _drawProfessionalSignatureField(canvas, "DATE", rightSignatureX, footerTopY + 8);
//
//     // Bottom note - Compact
//     final notePainter = TextPainter(
//       text: TextSpan(
//           text: "Ensure all bubbles are filled correctly for electronic evaluation",
//           style: TextStyle(fontSize: 6, color: Colors.grey[600], fontStyle: FontStyle.italic)
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     notePainter.layout();
//     notePainter.paint(canvas, Offset(A4_WIDTH/2 - notePainter.width/2, footerTopY + 35));
//   }
//
//   static void _drawProfessionalSignatureField(Canvas canvas, String label, double x, double y) {
//     final labelPainter = TextPainter(
//       text: TextSpan(text: label, style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     labelPainter.layout();
//     labelPainter.paint(canvas, Offset(x, y));
//
//     // Signature line
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 0.8;
//     canvas.drawLine(Offset(x, y + 8), Offset(x + 70, y + 8), linePaint); // Reduced length
//   }
//
//   static void _drawAnswerKey(Canvas canvas, List<String> correctAnswers, int totalQuestions) {
//     final redPaint = Paint()..color = Colors.red;
//
//     final questionsPerColumn = (totalQuestions / 3).ceil();
//     final columnWidth = (A4_WIDTH - 2 * MARGIN - 20) / 3;
//
//     for (int i = 0; i < correctAnswers.length; i++) {
//       if (i >= totalQuestions) break;
//
//       final colIndex = i ~/ questionsPerColumn;
//       final questionInColumn = i % questionsPerColumn;
//       final optionIndex = correctAnswers[i].codeUnitAt(0) - 65;
//
//       final columnX = MARGIN + colIndex * (columnWidth + COLUMN_SPACING);
//       final yPos = MARGIN + HEADER_HEIGHT + STUDENT_INFO_HEIGHT + 40 + 15 + questionInColumn * 12;
//
//       final optionX = columnX + 20 + optionIndex * 11;
//
//       // Fill the correct answer bubble in red
//       canvas.drawCircle(Offset(optionX + 3.5, yPos - 1 + 3.5), BUBBLE_RADIUS - 0.5, redPaint);
//     }
//
//     // Add "ANSWER KEY" watermark
//     final watermarkStyle = TextStyle(
//       fontSize: 50,
//       fontWeight: FontWeight.bold,
//       color: Colors.red.withOpacity(0.06),
//     );
//     final watermarkPainter = TextPainter(
//       text: TextSpan(text: "ANSWER KEY", style: watermarkStyle),
//       textDirection: TextDirection.ltr,
//     );
//     watermarkPainter.layout();
//     watermarkPainter.paint(canvas, Offset(
//       A4_WIDTH / 2 - watermarkPainter.width / 2,
//       A4_HEIGHT / 2 - watermarkPainter.height / 2,
//     ));
//   }
//
//   static void _drawProfessionalBubble(Canvas canvas, double x, double y, bool filled) {
//     final paint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.8;
//
//     canvas.drawCircle(Offset(x + 3.5, y + 3.5), BUBBLE_RADIUS, paint);
//
//     if (filled) {
//       final fillPaint = Paint()..color = Colors.black;
//       canvas.drawCircle(Offset(x + 3.5, y + 3.5), BUBBLE_RADIUS - 0.6, fillPaint);
//     }
//   }
//
//   static void _drawProfessionalBubbleWithNumber(Canvas canvas, double x, double y, int number, bool filled) {
//     _drawProfessionalBubble(canvas, x, y, filled);
//
//     final numberPainter = TextPainter(
//       text: TextSpan(text: number.toString(), style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     numberPainter.layout();
//     numberPainter.paint(canvas, Offset(x, y + 9));
//   }
//
//   static String _formatDate(DateTime date) {
//     final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
//     return '${date.day} ${months[date.month - 1]} ${date.year}';
//   }
// }
//





// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'omr_models.dart';
//
// class OMRGenerator {
//   static const double A4_WIDTH = 595.0;
//   static const double A4_HEIGHT = 842.0;
//   static const double MARGIN = 25.0; // Reduced margin for more space
//   static const double BUBBLE_RADIUS = 4.0;
//   static const double BUBBLE_SPACING = 16.0; // Reduced spacing
//   static const double COLUMN_SPACING = 12.0; // Reduced column spacing
//
//   static Future<File> generateOMRSheet(OMRExamConfig config) async {
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//
//     // Set background to white
//     canvas.drawRect(Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT), Paint()..color = Colors.white);
//
//     // Draw professional border
//     _drawProfessionalBorder(canvas);
//
//     // Draw sections with overflow protection
//     _drawProfessionalHeader(canvas, config);
//     _drawStudentInfoSection(canvas, config);
//     _drawAnswerSectionWithThreeColumns(canvas, config.numberOfQuestions);
//     _drawProfessionalFooter(canvas);
//
//     // Draw answer key if provided
//     if (config.correctAnswers.isNotEmpty) {
//       _drawAnswerKey(canvas, config.correctAnswers, config.numberOfQuestions);
//     }
//
//     final picture = recorder.endRecording();
//     final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
//     final bytes = byteData!.buffer.asUint8List();
//
//     final directory = await getTemporaryDirectory();
//     final file = File('${directory.path}/omr_sheet_${DateTime.now().millisecondsSinceEpoch}.png');
//     await file.writeAsBytes(bytes);
//
//     return file;
//   }
//
//   static void _drawProfessionalBorder(Canvas canvas) {
//     // Outer border
//     final outerBorderPaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN-2, MARGIN-2,
//         A4_WIDTH - 2*MARGIN + 4, A4_HEIGHT - 2*MARGIN + 4), outerBorderPaint);
//
//     // Inner border
//     final innerBorderPaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN+8, MARGIN+8,
//         A4_WIDTH - 2*MARGIN - 16, A4_HEIGHT - 2*MARGIN - 16), innerBorderPaint);
//   }
//
//   static void _drawProfessionalHeader(Canvas canvas, OMRExamConfig config) {
//     // Institution Header
//     final institutionStyle = TextStyle(
//       fontSize: 14, // Reduced from 16
//       fontWeight: FontWeight.bold,
//       color: Colors.blue[800],
//     );
//
//     final institutionPainter = TextPainter(
//       text: TextSpan(text: "PROFESSIONAL COACHING CENTER", style: institutionStyle),
//       textDirection: TextDirection.ltr,
//     );
//     institutionPainter.layout();
//     institutionPainter.paint(canvas, Offset(A4_WIDTH/2 - institutionPainter.width/2, MARGIN + 10));
//
//     // Exam Title
//     final titleStyle = TextStyle(
//       fontSize: 18, // Reduced from 20
//       fontWeight: FontWeight.bold,
//       color: Colors.black,
//       letterSpacing: 1.0, // Reduced from 1.1
//     );
//
//     final titlePainter = TextPainter(
//       text: TextSpan(text: config.examName.toUpperCase(), style: titleStyle),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(A4_WIDTH/2 - titlePainter.width/2, MARGIN + 32));
//
//     // Exam Details Row
//     final detailsStyle = TextStyle(
//       fontSize: 10, // Reduced from 11
//       fontWeight: FontWeight.normal,
//       color: Colors.black87,
//     );
//
//     // Date
//     final dateText = 'Date: ${_formatDate(config.examDate)}';
//     final datePainter = TextPainter(
//       text: TextSpan(text: dateText, style: detailsStyle),
//       textDirection: TextDirection.ltr,
//     );
//     datePainter.layout();
//     datePainter.paint(canvas, Offset(MARGIN + 15, MARGIN + 58));
//
//     // Total Questions
//     final questionsText = 'Total Questions: ${config.numberOfQuestions}';
//     final questionsPainter = TextPainter(
//       text: TextSpan(text: questionsText, style: detailsStyle),
//       textDirection: TextDirection.ltr,
//     );
//     questionsPainter.layout();
//     questionsPainter.paint(canvas, Offset(A4_WIDTH/2 - questionsPainter.width/2, MARGIN + 58));
//
//     // Time
//     final timeText = 'Time: 3 Hours';
//     final timePainter = TextPainter(
//       text: TextSpan(text: timeText, style: detailsStyle),
//       textDirection: TextDirection.ltr,
//     );
//     timePainter.layout();
//     timePainter.paint(canvas, Offset(A4_WIDTH - MARGIN - 15 - timePainter.width, MARGIN + 58));
//
//     // Professional Instructions Box - Made more compact
//     _drawInstructionsBox(canvas, MARGIN + 72);
//   }
//
//   static void _drawInstructionsBox(Canvas canvas, double startY) {
//     // Box background
//     final boxPaint = Paint()
//       ..color = Colors.grey[50]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN + 10, startY, A4_WIDTH - 2*MARGIN - 20, 40), boxPaint); // Reduced height
//
//     // Box border
//     final borderPaint = Paint()
//       ..color = Colors.grey[400]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN + 10, startY, A4_WIDTH - 2*MARGIN - 20, 40), borderPaint);
//
//     // Instructions - More compact layout
//     final instructions = [
//       "• Use BLACK/BLUE ball point pen only • Fill circles completely",
//       "• No stray marks • Completely erase to change answer • Equal marks"
//     ];
//
//     double instructionY = startY + 12;
//     for (var instruction in instructions) {
//       final instructionPainter = TextPainter(
//         text: TextSpan(text: instruction, style: TextStyle(fontSize: 8, color: Colors.black87, fontWeight: FontWeight.w500)),
//         textDirection: TextDirection.ltr,
//       );
//       instructionPainter.layout();
//       instructionPainter.paint(canvas, Offset(MARGIN + 15, instructionY));
//       instructionY += 10; // Reduced spacing
//     }
//   }
//
//   static void _drawStudentInfoSection(Canvas canvas, OMRExamConfig config) {
//     final double startY = MARGIN + 125; // Adjusted start position
//
//     // Section Title with background
//     _drawSectionTitleWithBackground(canvas, "STUDENT INFORMATION", startY - 5);
//
//     // Set Number and Basic Info Row
//     _drawSetNumberAndBasicInfo(canvas, config, startY + 20); // Reduced spacing
//
//     // Student ID and Mobile Number in two columns - Made more compact
//     _drawStudentIdColumn(canvas, config.studentId, startY + 60);
//     _drawMobileNumberColumn(canvas, config.mobileNumber, startY + 60);
//   }
//
//   static void _drawSectionTitleWithBackground(Canvas canvas, String title, double y) {
//     final style = TextStyle(
//       fontSize: 12, // Reduced from 13
//       fontWeight: FontWeight.bold,
//       color: Colors.white,
//     );
//
//     final painter = TextPainter(
//       text: TextSpan(text: title, style: style),
//       textDirection: TextDirection.ltr,
//     );
//     painter.layout();
//
//     // Background
//     final bgPaint = Paint()
//       ..color = Colors.blue[800]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(
//         MARGIN + 10,
//         y,
//         painter.width + 15,
//         painter.height + 6 // Reduced padding
//     ), bgPaint);
//
//     painter.paint(canvas, Offset(MARGIN + 17, y + 3)); // Adjusted positioning
//   }
//
//   static void _drawSetNumberAndBasicInfo(Canvas canvas, OMRExamConfig config, double startY) {
//     // Set Number Label
//     final setLabelPainter = TextPainter(
//       text: TextSpan(text: "SET NUMBER:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), // Reduced font
//       textDirection: TextDirection.ltr,
//     );
//     setLabelPainter.layout();
//     setLabelPainter.paint(canvas, Offset(MARGIN + 15, startY));
//
//     // Draw set number bubbles (0-9) - More compact
//     final double bubbleStartX = MARGIN + 95; // Adjusted positioning
//     for (int i = 0; i < 10; i++) {
//       _drawProfessionalBubbleWithNumber(canvas, bubbleStartX + i * 15, startY - 3, i, i == config.setNumber); // Reduced spacing
//     }
//
//     // Student Name Label (Placeholder)
//     final nameLabelPainter = TextPainter(
//       text: TextSpan(text: "STUDENT NAME:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     nameLabelPainter.layout();
//     nameLabelPainter.paint(canvas, Offset(A4_WIDTH/2 - 40, startY)); // Adjusted positioning
//
//     // Name Underline
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 1.0;
//     canvas.drawLine(
//         Offset(A4_WIDTH/2 - 40, startY + 12), // Reduced spacing
//         Offset(A4_WIDTH/2 + 80, startY + 12), // Reduced length
//         linePaint
//     );
//   }
//
//   static void _drawStudentIdColumn(Canvas canvas, String studentId, double startY) {
//     final double columnX = MARGIN + 15;
//     final double columnWidth = (A4_WIDTH - 2*MARGIN - 30) / 2; // Adjusted width
//
//     // Column Title
//     final titlePainter = TextPainter(
//       text: TextSpan(text: "STUDENT ID (9 digits)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)), // Reduced font
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(columnX, startY));
//
//     // Column background - Made more compact
//     final bgPaint = Paint()
//       ..color = Colors.grey[50]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(columnX - 3, startY + 8, columnWidth, 150), bgPaint); // Reduced height
//
//     final borderPaint = Paint()
//       ..color = Colors.grey[300]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     canvas.drawRect(Rect.fromLTWH(columnX - 3, startY + 8, columnWidth, 150), borderPaint);
//
//     // Draw student ID bubbles - More compact
//     for (int digitPos = 0; digitPos < 9; digitPos++) {
//       final double digitX = columnX + 8 + digitPos * 14; // Reduced spacing
//
//       // Digit position number
//       final posPainter = TextPainter(
//         text: TextSpan(text: (digitPos + 1).toString(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue[800])),
//         textDirection: TextDirection.ltr,
//       );
//       posPainter.layout();
//       posPainter.paint(canvas, Offset(digitX + 2, startY + 20)); // Adjusted positioning
//
//       // Bubbles for this digit position - More compact
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digitPos < studentId.length &&
//             studentId[digitPos] == num.toString();
//         _drawProfessionalBubble(canvas, digitX, startY + 30 + num * 12, isFilled); // Reduced spacing
//
//         // Number label on left side
//         if (digitPos == 0) {
//           final numPainter = TextPainter(
//             text: TextSpan(text: num.toString(), style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold)), // Reduced font
//             textDirection: TextDirection.ltr,
//           );
//           numPainter.layout();
//           numPainter.paint(canvas, Offset(columnX, startY + 32 + num * 12)); // Adjusted positioning
//         }
//       }
//     }
//   }
//
//   static void _drawMobileNumberColumn(Canvas canvas, String mobileNumber, double startY) {
//     final double columnX = A4_WIDTH / 2 + 5; // Adjusted positioning
//     final double columnWidth = (A4_WIDTH - 2*MARGIN - 30) / 2;
//
//     // Column Title
//     final titlePainter = TextPainter(
//       text: TextSpan(text: "MOBILE NUMBER (11 digits)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(columnX, startY));
//
//     // Column background - Made more compact
//     final bgPaint = Paint()
//       ..color = Colors.grey[50]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(columnX - 3, startY + 8, columnWidth, 150), bgPaint);
//
//     final borderPaint = Paint()
//       ..color = Colors.grey[300]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     canvas.drawRect(Rect.fromLTWH(columnX - 3, startY + 8, columnWidth, 150), borderPaint);
//
//     // Draw mobile number bubbles - More compact
//     for (int digitPos = 0; digitPos < 11; digitPos++) {
//       final double digitX = columnX + 8 + digitPos * 13; // Reduced spacing for 11 digits
//
//       // Digit position number
//       final posPainter = TextPainter(
//         text: TextSpan(text: (digitPos + 1).toString(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue[800])),
//         textDirection: TextDirection.ltr,
//       );
//       posPainter.layout();
//       posPainter.paint(canvas, Offset(digitX + 2, startY + 20));
//
//       // Bubbles for this digit position - More compact
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digitPos < mobileNumber.length &&
//             mobileNumber[digitPos] == num.toString();
//         _drawProfessionalBubble(canvas, digitX, startY + 30 + num * 12, isFilled);
//
//         // Number label on left side
//         if (digitPos == 0) {
//           final numPainter = TextPainter(
//             text: TextSpan(text: num.toString(), style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold)),
//             textDirection: TextDirection.ltr,
//           );
//           numPainter.layout();
//           numPainter.paint(canvas, Offset(columnX, startY + 32 + num * 12));
//         }
//       }
//     }
//   }
//
//   static void _drawAnswerSectionWithThreeColumns(Canvas canvas, int numberOfQuestions) {
//     final double startY = MARGIN + 240; // Adjusted start position
//
//     // Section Title with background
//     _drawSectionTitleWithBackground(canvas, "ANSWER SHEET", startY - 5);
//
//     // Options Legend
//     _drawOptionsLegend(canvas, startY + 20); // Reduced spacing
//
//     // Draw questions in THREE columns with overflow protection
//     final questionsPerColumn = (numberOfQuestions / 3).ceil();
//     final columnWidth = (A4_WIDTH - 2 * MARGIN - 30) / 3; // Adjusted width
//
//     // Calculate maximum possible questions that can fit
//     final double maxQuestionsHeight = A4_HEIGHT - startY - 80; // Reserve space for footer
//     final double availableHeightPerColumn = maxQuestionsHeight - 50; // Reserve for header and spacing
//     final int maxQuestionsPerColumn = (availableHeightPerColumn / 16).floor(); // 16px per question
//
//     final int actualQuestionsPerColumn = questionsPerColumn > maxQuestionsPerColumn
//         ? maxQuestionsPerColumn
//         : questionsPerColumn;
//
//     for (int col = 0; col < 3; col++) {
//       final columnX = MARGIN + 15 + col * (columnWidth + COLUMN_SPACING);
//       _drawQuestionColumnThreeCol(canvas, columnX, startY + 35, col, numberOfQuestions, actualQuestionsPerColumn); // Adjusted spacing
//     }
//   }
//
//   static void _drawOptionsLegend(Canvas canvas, double startY) {
//     final legendText = "OPTIONS: A • B • C • D • E";
//     final legendPainter = TextPainter(
//       text: TextSpan(
//           text: legendText,
//           style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue[800]) // Reduced font
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     legendPainter.layout();
//     legendPainter.paint(canvas, Offset(A4_WIDTH/2 - legendPainter.width/2, startY));
//   }
//
//   static void _drawQuestionColumnThreeCol(Canvas canvas, double startX, double startY, int colIndex, int totalQuestions, int questionsPerColumn) {
//     final startQuestion = colIndex * questionsPerColumn + 1;
//     int endQuestion = (colIndex + 1) * questionsPerColumn;
//
//     // Ensure we don't exceed total questions
//     if (endQuestion > totalQuestions) {
//       endQuestion = totalQuestions;
//     }
//
//     final actualEnd = endQuestion > totalQuestions ? totalQuestions : endQuestion;
//
//     // Column header with background
//     final headerBgPaint = Paint()
//       ..color = Colors.grey[200]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(startX - 3, startY - 3, 140, 16), headerBgPaint); // More compact
//
//     final headerPainter = TextPainter(
//       text: TextSpan(
//           text: "Q${startQuestion}-${actualEnd}",
//           style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87) // Reduced font
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     headerPainter.layout();
//     headerPainter.paint(canvas, Offset(startX, startY));
//
//     // Questions - More compact layout
//     for (int q = startQuestion; q <= actualEnd; q++) {
//       if (q > totalQuestions) break;
//
//       final yPos = startY + 18 + (q - startQuestion) * 16; // Reduced spacing
//
//       // Question number with background
//       final qText = TextPainter(
//         text: TextSpan(text: 'Q${q.toString().padLeft(2)}', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)), // Reduced font
//         textDirection: TextDirection.ltr,
//       );
//       qText.layout();
//
//       final qBgPaint = Paint()
//         ..color = Colors.blue[700]!
//         ..style = PaintingStyle.fill;
//
//       canvas.drawRect(Rect.fromLTWH(startX - 1, yPos - 1, qText.width + 2, qText.height + 1), qBgPaint); // More compact
//       qText.paint(canvas, Offset(startX, yPos));
//
//       // Options A, B, C, D, E - More compact
//       for (int option = 0; option < 5; option++) {
//         final optionChar = String.fromCharCode(65 + option);
//         final optionX = startX + 22 + option * 15; // Reduced spacing
//
//         // Option letter
//         final optionText = TextPainter(
//           text: TextSpan(text: optionChar, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)), // Reduced font
//           textDirection: TextDirection.ltr,
//         );
//         optionText.layout();
//         optionText.paint(canvas, Offset(optionX + 2, yPos)); // Adjusted positioning
//
//         // Professional bubble
//         _drawProfessionalBubble(canvas, optionX, yPos - 1, false);
//       }
//     }
//   }
//
//   static void _drawProfessionalFooter(Canvas canvas) {
//     final double footerY = A4_HEIGHT - MARGIN - 40; // Adjusted positioning
//
//     // Top border line
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 1.0;
//     canvas.drawLine(Offset(MARGIN + 15, footerY), Offset(A4_WIDTH - MARGIN - 15, footerY), linePaint);
//
//     // Signature fields in three columns - More compact
//     final leftSignatureX = MARGIN + 20;
//     final middleSignatureX = A4_WIDTH / 2 - 55;
//     final rightSignatureX = A4_WIDTH - MARGIN - 130;
//
//     // Student Signature
//     _drawProfessionalSignatureField(canvas, "STUDENT'S SIGNATURE", leftSignatureX, footerY + 8);
//
//     // Invigilator Signature
//     _drawProfessionalSignatureField(canvas, "INVIGILATOR'S SIGNATURE", middleSignatureX, footerY + 8);
//
//     // Date field
//     _drawProfessionalSignatureField(canvas, "DATE", rightSignatureX, footerY + 8);
//
//     // Bottom note
//     final notePainter = TextPainter(
//       text: TextSpan(
//           text: "Note: Ensure all bubbles are filled correctly for electronic evaluation.",
//           style: TextStyle(fontSize: 7, color: Colors.grey[600], fontStyle: FontStyle.italic) // Reduced font
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     notePainter.layout();
//     notePainter.paint(canvas, Offset(A4_WIDTH/2 - notePainter.width/2, footerY + 35));
//   }
//
//   static void _drawProfessionalSignatureField(Canvas canvas, String label, double x, double y) {
//     final labelPainter = TextPainter(
//       text: TextSpan(text: label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)), // Reduced font
//       textDirection: TextDirection.ltr,
//     );
//     labelPainter.layout();
//     labelPainter.paint(canvas, Offset(x, y));
//
//     // Signature line
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 1.0;
//     canvas.drawLine(Offset(x, y + 10), Offset(x + 100, y + 10), linePaint); // Reduced length
//   }
//
//   static void _drawAnswerKey(Canvas canvas, List<String> correctAnswers, int totalQuestions) {
//     final redPaint = Paint()..color = Colors.red;
//
//     final questionsPerColumn = (totalQuestions / 3).ceil();
//     final columnWidth = (A4_WIDTH - 2 * MARGIN - 30) / 3;
//
//     for (int i = 0; i < correctAnswers.length; i++) {
//       if (i >= totalQuestions) break;
//
//       final colIndex = i ~/ questionsPerColumn;
//       final questionInColumn = i % questionsPerColumn;
//       final optionIndex = correctAnswers[i].codeUnitAt(0) - 65;
//
//       final columnX = MARGIN + 15 + colIndex * (columnWidth + COLUMN_SPACING);
//       final yPos = MARGIN + 275 + 18 + questionInColumn * 16; // Adjusted to match new spacing
//
//       final optionX = columnX + 22 + optionIndex * 15; // Adjusted to match new spacing
//
//       // Fill the correct answer bubble in red
//       canvas.drawCircle(Offset(optionX + 5, yPos - 1 + 5), BUBBLE_RADIUS - 0.5, redPaint);
//     }
//
//     // Add "ANSWER KEY" watermark
//     final watermarkStyle = TextStyle(
//       fontSize: 60, // Reduced size
//       fontWeight: FontWeight.bold,
//       color: Colors.red.withOpacity(0.08),
//       letterSpacing: 6.0, // Reduced spacing
//     );
//     final watermarkPainter = TextPainter(
//       text: TextSpan(text: "ANSWER KEY", style: watermarkStyle),
//       textDirection: TextDirection.ltr,
//     );
//     watermarkPainter.layout();
//     watermarkPainter.paint(canvas, Offset(
//       A4_WIDTH / 2 - watermarkPainter.width / 2,
//       A4_HEIGHT / 2 - watermarkPainter.height / 2,
//     ));
//   }
//
//   static void _drawProfessionalBubble(Canvas canvas, double x, double y, bool filled) {
//     final paint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0; // Reduced stroke width
//
//     canvas.drawCircle(Offset(x + 4, y + 4), BUBBLE_RADIUS, paint); // Adjusted center
//
//     if (filled) {
//       final fillPaint = Paint()..color = Colors.black;
//       canvas.drawCircle(Offset(x + 4, y + 4), BUBBLE_RADIUS - 0.8, fillPaint);
//     }
//   }
//
//   static void _drawProfessionalBubbleWithNumber(Canvas canvas, double x, double y, int number, bool filled) {
//     _drawProfessionalBubble(canvas, x, y, filled);
//
//     final numberPainter = TextPainter(
//       text: TextSpan(text: number.toString(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)), // Reduced font
//       textDirection: TextDirection.ltr,
//     );
//     numberPainter.layout();
//     numberPainter.paint(canvas, Offset(x + 1, y + 11)); // Adjusted positioning
//   }
//
//   static String _formatDate(DateTime date) {
//     final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
//     return '${date.day} ${months[date.month - 1]} ${date.year}';
//   }
// }






// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'omr_models.dart';
//
// class OMRGenerator {
//   static const double A4_WIDTH = 595.0;
//   static const double A4_HEIGHT = 842.0;
//   static const double MARGIN = 25.0; // Reduced margin for more space
//   static const double BUBBLE_RADIUS = 4.0;
//   static const double BUBBLE_SPACING = 16.0; // Reduced spacing
//   static const double COLUMN_SPACING = 12.0; // Reduced column spacing
//
//   static Future<File> generateOMRSheet(OMRExamConfig config) async {
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//
//     // Set background to white
//     canvas.drawRect(Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT), Paint()..color = Colors.white);
//
//     // Draw professional border
//     _drawProfessionalBorder(canvas);
//
//     // Draw sections with overflow protection
//     _drawProfessionalHeader(canvas, config);
//     _drawStudentInfoSection(canvas, config);
//     _drawAnswerSectionWithThreeColumns(canvas, config.numberOfQuestions);
//     _drawProfessionalFooter(canvas);
//
//     // Draw answer key if provided
//     if (config.correctAnswers.isNotEmpty) {
//       _drawAnswerKey(canvas, config.correctAnswers, config.numberOfQuestions);
//     }
//
//     final picture = recorder.endRecording();
//     final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
//     final bytes = byteData!.buffer.asUint8List();
//
//     final directory = await getTemporaryDirectory();
//     final file = File('${directory.path}/omr_sheet_${DateTime.now().millisecondsSinceEpoch}.png');
//     await file.writeAsBytes(bytes);
//
//     return file;
//   }
//
//   static void _drawProfessionalBorder(Canvas canvas) {
//     // Outer border
//     final outerBorderPaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN-2, MARGIN-2,
//         A4_WIDTH - 2*MARGIN + 4, A4_HEIGHT - 2*MARGIN + 4), outerBorderPaint);
//
//     // Inner border
//     final innerBorderPaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN+8, MARGIN+8,
//         A4_WIDTH - 2*MARGIN - 16, A4_HEIGHT - 2*MARGIN - 16), innerBorderPaint);
//   }
//
//   static void _drawProfessionalHeader(Canvas canvas, OMRExamConfig config) {
//     // Institution Header
//     final institutionStyle = TextStyle(
//       fontSize: 14, // Reduced from 16
//       fontWeight: FontWeight.bold,
//       color: Colors.blue[800],
//     );
//
//     final institutionPainter = TextPainter(
//       text: TextSpan(text: "PROFESSIONAL COACHING CENTER", style: institutionStyle),
//       textDirection: TextDirection.ltr,
//     );
//     institutionPainter.layout();
//     institutionPainter.paint(canvas, Offset(A4_WIDTH/2 - institutionPainter.width/2, MARGIN + 10));
//
//     // Exam Title
//     final titleStyle = TextStyle(
//       fontSize: 18, // Reduced from 20
//       fontWeight: FontWeight.bold,
//       color: Colors.black,
//       letterSpacing: 1.0, // Reduced from 1.1
//     );
//
//     final titlePainter = TextPainter(
//       text: TextSpan(text: config.examName.toUpperCase(), style: titleStyle),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(A4_WIDTH/2 - titlePainter.width/2, MARGIN + 32));
//
//     // Exam Details Row
//     final detailsStyle = TextStyle(
//       fontSize: 10, // Reduced from 11
//       fontWeight: FontWeight.normal,
//       color: Colors.black87,
//     );
//
//     // Date
//     final dateText = 'Date: ${_formatDate(config.examDate)}';
//     final datePainter = TextPainter(
//       text: TextSpan(text: dateText, style: detailsStyle),
//       textDirection: TextDirection.ltr,
//     );
//     datePainter.layout();
//     datePainter.paint(canvas, Offset(MARGIN + 15, MARGIN + 58));
//
//     // Total Questions
//     final questionsText = 'Total Questions: ${config.numberOfQuestions}';
//     final questionsPainter = TextPainter(
//       text: TextSpan(text: questionsText, style: detailsStyle),
//       textDirection: TextDirection.ltr,
//     );
//     questionsPainter.layout();
//     questionsPainter.paint(canvas, Offset(A4_WIDTH/2 - questionsPainter.width/2, MARGIN + 58));
//
//     // Time
//     final timeText = 'Time: 3 Hours';
//     final timePainter = TextPainter(
//       text: TextSpan(text: timeText, style: detailsStyle),
//       textDirection: TextDirection.ltr,
//     );
//     timePainter.layout();
//     timePainter.paint(canvas, Offset(A4_WIDTH - MARGIN - 15 - timePainter.width, MARGIN + 58));
//
//     // Professional Instructions Box - Made more compact
//     _drawInstructionsBox(canvas, MARGIN + 72);
//   }
//
//   static void _drawInstructionsBox(Canvas canvas, double startY) {
//     // Box background
//     final boxPaint = Paint()
//       ..color = Colors.grey[50]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN + 10, startY, A4_WIDTH - 2*MARGIN - 20, 40), boxPaint); // Reduced height
//
//     // Box border
//     final borderPaint = Paint()
//       ..color = Colors.grey[400]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN + 10, startY, A4_WIDTH - 2*MARGIN - 20, 40), borderPaint);
//
//     // Instructions - More compact layout
//     final instructions = [
//       "• Use BLACK/BLUE ball point pen only • Fill circles completely",
//       "• No stray marks • Completely erase to change answer • Equal marks"
//     ];
//
//     double instructionY = startY + 12;
//     for (var instruction in instructions) {
//       final instructionPainter = TextPainter(
//         text: TextSpan(text: instruction, style: TextStyle(fontSize: 8, color: Colors.black87, fontWeight: FontWeight.w500)),
//         textDirection: TextDirection.ltr,
//       );
//       instructionPainter.layout();
//       instructionPainter.paint(canvas, Offset(MARGIN + 15, instructionY));
//       instructionY += 10; // Reduced spacing
//     }
//   }
//
//   static void _drawStudentInfoSection(Canvas canvas, OMRExamConfig config) {
//     final double startY = MARGIN + 125; // Adjusted start position
//
//     // Section Title with background
//     _drawSectionTitleWithBackground(canvas, "STUDENT INFORMATION", startY - 5);
//
//     // Set Number and Basic Info Row
//     _drawSetNumberAndBasicInfo(canvas, config, startY + 20); // Reduced spacing
//
//     // Student ID and Mobile Number in two columns - Made more compact
//     _drawStudentIdColumn(canvas, config.studentId, startY + 60);
//     _drawMobileNumberColumn(canvas, config.mobileNumber, startY + 60);
//   }
//
//   static void _drawSectionTitleWithBackground(Canvas canvas, String title, double y) {
//     final style = TextStyle(
//       fontSize: 12, // Reduced from 13
//       fontWeight: FontWeight.bold,
//       color: Colors.white,
//     );
//
//     final painter = TextPainter(
//       text: TextSpan(text: title, style: style),
//       textDirection: TextDirection.ltr,
//     );
//     painter.layout();
//
//     // Background
//     final bgPaint = Paint()
//       ..color = Colors.blue[800]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(
//         MARGIN + 10,
//         y,
//         painter.width + 15,
//         painter.height + 6 // Reduced padding
//     ), bgPaint);
//
//     painter.paint(canvas, Offset(MARGIN + 17, y + 3)); // Adjusted positioning
//   }
//
//   static void _drawSetNumberAndBasicInfo(Canvas canvas, OMRExamConfig config, double startY) {
//     // Set Number Label
//     final setLabelPainter = TextPainter(
//       text: TextSpan(text: "SET NUMBER:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), // Reduced font
//       textDirection: TextDirection.ltr,
//     );
//     setLabelPainter.layout();
//     setLabelPainter.paint(canvas, Offset(MARGIN + 15, startY));
//
//     // Draw set number bubbles (0-9) - More compact
//     final double bubbleStartX = MARGIN + 95; // Adjusted positioning
//     for (int i = 0; i < 10; i++) {
//       _drawProfessionalBubbleWithNumber(canvas, bubbleStartX + i * 15, startY - 3, i, i == config.setNumber); // Reduced spacing
//     }
//
//     // Student Name Label (Placeholder)
//     final nameLabelPainter = TextPainter(
//       text: TextSpan(text: "STUDENT NAME:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     nameLabelPainter.layout();
//     nameLabelPainter.paint(canvas, Offset(A4_WIDTH/2 - 40, startY)); // Adjusted positioning
//
//     // Name Underline
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 1.0;
//     canvas.drawLine(
//         Offset(A4_WIDTH/2 - 40, startY + 12), // Reduced spacing
//         Offset(A4_WIDTH/2 + 80, startY + 12), // Reduced length
//         linePaint
//     );
//   }
//
//   static void _drawStudentIdColumn(Canvas canvas, String studentId, double startY) {
//     final double columnX = MARGIN + 15;
//     final double columnWidth = (A4_WIDTH - 2*MARGIN - 30) / 2; // Adjusted width
//
//     // Column Title
//     final titlePainter = TextPainter(
//       text: TextSpan(text: "STUDENT ID (9 digits)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)), // Reduced font
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(columnX, startY));
//
//     // Column background - Made more compact
//     final bgPaint = Paint()
//       ..color = Colors.grey[50]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(columnX - 3, startY + 8, columnWidth, 150), bgPaint); // Reduced height
//
//     final borderPaint = Paint()
//       ..color = Colors.grey[300]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     canvas.drawRect(Rect.fromLTWH(columnX - 3, startY + 8, columnWidth, 150), borderPaint);
//
//     // Draw student ID bubbles - More compact
//     for (int digitPos = 0; digitPos < 9; digitPos++) {
//       final double digitX = columnX + 8 + digitPos * 14; // Reduced spacing
//
//       // Digit position number
//       final posPainter = TextPainter(
//         text: TextSpan(text: (digitPos + 1).toString(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue[800])),
//         textDirection: TextDirection.ltr,
//       );
//       posPainter.layout();
//       posPainter.paint(canvas, Offset(digitX + 2, startY + 20)); // Adjusted positioning
//
//       // Bubbles for this digit position - More compact
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digitPos < studentId.length &&
//             studentId[digitPos] == num.toString();
//         _drawProfessionalBubble(canvas, digitX, startY + 30 + num * 12, isFilled); // Reduced spacing
//
//         // Number label on left side
//         if (digitPos == 0) {
//           final numPainter = TextPainter(
//             text: TextSpan(text: num.toString(), style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold)), // Reduced font
//             textDirection: TextDirection.ltr,
//           );
//           numPainter.layout();
//           numPainter.paint(canvas, Offset(columnX, startY + 32 + num * 12)); // Adjusted positioning
//         }
//       }
//     }
//   }
//
//   static void _drawMobileNumberColumn(Canvas canvas, String mobileNumber, double startY) {
//     final double columnX = A4_WIDTH / 2 + 5; // Adjusted positioning
//     final double columnWidth = (A4_WIDTH - 2*MARGIN - 30) / 2;
//
//     // Column Title
//     final titlePainter = TextPainter(
//       text: TextSpan(text: "MOBILE NUMBER (11 digits)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(columnX, startY));
//
//     // Column background - Made more compact
//     final bgPaint = Paint()
//       ..color = Colors.grey[50]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(columnX - 3, startY + 8, columnWidth, 150), bgPaint);
//
//     final borderPaint = Paint()
//       ..color = Colors.grey[300]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     canvas.drawRect(Rect.fromLTWH(columnX - 3, startY + 8, columnWidth, 150), borderPaint);
//
//     // Draw mobile number bubbles - More compact
//     for (int digitPos = 0; digitPos < 11; digitPos++) {
//       final double digitX = columnX + 8 + digitPos * 13; // Reduced spacing for 11 digits
//
//       // Digit position number
//       final posPainter = TextPainter(
//         text: TextSpan(text: (digitPos + 1).toString(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue[800])),
//         textDirection: TextDirection.ltr,
//       );
//       posPainter.layout();
//       posPainter.paint(canvas, Offset(digitX + 2, startY + 20));
//
//       // Bubbles for this digit position - More compact
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digitPos < mobileNumber.length &&
//             mobileNumber[digitPos] == num.toString();
//         _drawProfessionalBubble(canvas, digitX, startY + 30 + num * 12, isFilled);
//
//         // Number label on left side
//         if (digitPos == 0) {
//           final numPainter = TextPainter(
//             text: TextSpan(text: num.toString(), style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold)),
//             textDirection: TextDirection.ltr,
//           );
//           numPainter.layout();
//           numPainter.paint(canvas, Offset(columnX, startY + 32 + num * 12));
//         }
//       }
//     }
//   }
//
//   static void _drawAnswerSectionWithThreeColumns(Canvas canvas, int numberOfQuestions) {
//     final double startY = MARGIN + 240; // Adjusted start position
//
//     // Section Title with background
//     _drawSectionTitleWithBackground(canvas, "ANSWER SHEET", startY - 5);
//
//     // Options Legend
//     _drawOptionsLegend(canvas, startY + 20); // Reduced spacing
//
//     // Draw questions in THREE columns with overflow protection
//     final questionsPerColumn = (numberOfQuestions / 3).ceil();
//     final columnWidth = (A4_WIDTH - 2 * MARGIN - 30) / 3; // Adjusted width
//
//     // Calculate maximum possible questions that can fit
//     final double maxQuestionsHeight = A4_HEIGHT - startY - 80; // Reserve space for footer
//     final double availableHeightPerColumn = maxQuestionsHeight - 50; // Reserve for header and spacing
//     final int maxQuestionsPerColumn = (availableHeightPerColumn / 16).floor(); // 16px per question
//
//     final int actualQuestionsPerColumn = questionsPerColumn > maxQuestionsPerColumn
//         ? maxQuestionsPerColumn
//         : questionsPerColumn;
//
//     for (int col = 0; col < 3; col++) {
//       final columnX = MARGIN + 15 + col * (columnWidth + COLUMN_SPACING);
//       _drawQuestionColumnThreeCol(canvas, columnX, startY + 35, col, numberOfQuestions, actualQuestionsPerColumn); // Adjusted spacing
//     }
//   }
//
//   static void _drawOptionsLegend(Canvas canvas, double startY) {
//     final legendText = "OPTIONS: A • B • C • D • E";
//     final legendPainter = TextPainter(
//       text: TextSpan(
//           text: legendText,
//           style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue[800]) // Reduced font
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     legendPainter.layout();
//     legendPainter.paint(canvas, Offset(A4_WIDTH/2 - legendPainter.width/2, startY));
//   }
//
//   static void _drawQuestionColumnThreeCol(Canvas canvas, double startX, double startY, int colIndex, int totalQuestions, int questionsPerColumn) {
//     final startQuestion = colIndex * questionsPerColumn + 1;
//     int endQuestion = (colIndex + 1) * questionsPerColumn;
//
//     // Ensure we don't exceed total questions
//     if (endQuestion > totalQuestions) {
//       endQuestion = totalQuestions;
//     }
//
//     final actualEnd = endQuestion > totalQuestions ? totalQuestions : endQuestion;
//
//     // Column header with background
//     final headerBgPaint = Paint()
//       ..color = Colors.grey[200]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(startX - 3, startY - 3, 140, 16), headerBgPaint); // More compact
//
//     final headerPainter = TextPainter(
//       text: TextSpan(
//           text: "Q${startQuestion}-${actualEnd}",
//           style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87) // Reduced font
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     headerPainter.layout();
//     headerPainter.paint(canvas, Offset(startX, startY));
//
//     // Questions - More compact layout
//     for (int q = startQuestion; q <= actualEnd; q++) {
//       if (q > totalQuestions) break;
//
//       final yPos = startY + 18 + (q - startQuestion) * 16; // Reduced spacing
//
//       // Question number with background
//       final qText = TextPainter(
//         text: TextSpan(text: 'Q${q.toString().padLeft(2)}', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)), // Reduced font
//         textDirection: TextDirection.ltr,
//       );
//       qText.layout();
//
//       final qBgPaint = Paint()
//         ..color = Colors.blue[700]!
//         ..style = PaintingStyle.fill;
//
//       canvas.drawRect(Rect.fromLTWH(startX - 1, yPos - 1, qText.width + 2, qText.height + 1), qBgPaint); // More compact
//       qText.paint(canvas, Offset(startX, yPos));
//
//       // Options A, B, C, D, E - More compact
//       for (int option = 0; option < 5; option++) {
//         final optionChar = String.fromCharCode(65 + option);
//         final optionX = startX + 22 + option * 15; // Reduced spacing
//
//         // Option letter
//         final optionText = TextPainter(
//           text: TextSpan(text: optionChar, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)), // Reduced font
//           textDirection: TextDirection.ltr,
//         );
//         optionText.layout();
//         optionText.paint(canvas, Offset(optionX + 2, yPos)); // Adjusted positioning
//
//         // Professional bubble
//         _drawProfessionalBubble(canvas, optionX, yPos - 1, false);
//       }
//     }
//   }
//
//   static void _drawProfessionalFooter(Canvas canvas) {
//     final double footerY = A4_HEIGHT - MARGIN - 40; // Adjusted positioning
//
//     // Top border line
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 1.0;
//     canvas.drawLine(Offset(MARGIN + 15, footerY), Offset(A4_WIDTH - MARGIN - 15, footerY), linePaint);
//
//     // Signature fields in three columns - More compact
//     final leftSignatureX = MARGIN + 20;
//     final middleSignatureX = A4_WIDTH / 2 - 55;
//     final rightSignatureX = A4_WIDTH - MARGIN - 130;
//
//     // Student Signature
//     _drawProfessionalSignatureField(canvas, "STUDENT'S SIGNATURE", leftSignatureX, footerY + 8);
//
//     // Invigilator Signature
//     _drawProfessionalSignatureField(canvas, "INVIGILATOR'S SIGNATURE", middleSignatureX, footerY + 8);
//
//     // Date field
//     _drawProfessionalSignatureField(canvas, "DATE", rightSignatureX, footerY + 8);
//
//     // Bottom note
//     final notePainter = TextPainter(
//       text: TextSpan(
//           text: "Note: Ensure all bubbles are filled correctly for electronic evaluation.",
//           style: TextStyle(fontSize: 7, color: Colors.grey[600], fontStyle: FontStyle.italic) // Reduced font
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     notePainter.layout();
//     notePainter.paint(canvas, Offset(A4_WIDTH/2 - notePainter.width/2, footerY + 35));
//   }
//
//   static void _drawProfessionalSignatureField(Canvas canvas, String label, double x, double y) {
//     final labelPainter = TextPainter(
//       text: TextSpan(text: label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)), // Reduced font
//       textDirection: TextDirection.ltr,
//     );
//     labelPainter.layout();
//     labelPainter.paint(canvas, Offset(x, y));
//
//     // Signature line
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 1.0;
//     canvas.drawLine(Offset(x, y + 10), Offset(x + 100, y + 10), linePaint); // Reduced length
//   }
//
//   static void _drawAnswerKey(Canvas canvas, List<String> correctAnswers, int totalQuestions) {
//     final redPaint = Paint()..color = Colors.red;
//
//     final questionsPerColumn = (totalQuestions / 3).ceil();
//     final columnWidth = (A4_WIDTH - 2 * MARGIN - 30) / 3;
//
//     for (int i = 0; i < correctAnswers.length; i++) {
//       if (i >= totalQuestions) break;
//
//       final colIndex = i ~/ questionsPerColumn;
//       final questionInColumn = i % questionsPerColumn;
//       final optionIndex = correctAnswers[i].codeUnitAt(0) - 65;
//
//       final columnX = MARGIN + 15 + colIndex * (columnWidth + COLUMN_SPACING);
//       final yPos = MARGIN + 275 + 18 + questionInColumn * 16; // Adjusted to match new spacing
//
//       final optionX = columnX + 22 + optionIndex * 15; // Adjusted to match new spacing
//
//       // Fill the correct answer bubble in red
//       canvas.drawCircle(Offset(optionX + 5, yPos - 1 + 5), BUBBLE_RADIUS - 0.5, redPaint);
//     }
//
//     // Add "ANSWER KEY" watermark
//     final watermarkStyle = TextStyle(
//       fontSize: 60, // Reduced size
//       fontWeight: FontWeight.bold,
//       color: Colors.red.withOpacity(0.08),
//       letterSpacing: 6.0, // Reduced spacing
//     );
//     final watermarkPainter = TextPainter(
//       text: TextSpan(text: "ANSWER KEY", style: watermarkStyle),
//       textDirection: TextDirection.ltr,
//     );
//     watermarkPainter.layout();
//     watermarkPainter.paint(canvas, Offset(
//       A4_WIDTH / 2 - watermarkPainter.width / 2,
//       A4_HEIGHT / 2 - watermarkPainter.height / 2,
//     ));
//   }
//
//   static void _drawProfessionalBubble(Canvas canvas, double x, double y, bool filled) {
//     final paint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0; // Reduced stroke width
//
//     canvas.drawCircle(Offset(x + 4, y + 4), BUBBLE_RADIUS, paint); // Adjusted center
//
//     if (filled) {
//       final fillPaint = Paint()..color = Colors.black;
//       canvas.drawCircle(Offset(x + 4, y + 4), BUBBLE_RADIUS - 0.8, fillPaint);
//     }
//   }
//
//   static void _drawProfessionalBubbleWithNumber(Canvas canvas, double x, double y, int number, bool filled) {
//     _drawProfessionalBubble(canvas, x, y, filled);
//
//     final numberPainter = TextPainter(
//       text: TextSpan(text: number.toString(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)), // Reduced font
//       textDirection: TextDirection.ltr,
//     );
//     numberPainter.layout();
//     numberPainter.paint(canvas, Offset(x + 1, y + 11)); // Adjusted positioning
//   }
//
//   static String _formatDate(DateTime date) {
//     final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
//     return '${date.day} ${months[date.month - 1]} ${date.year}';
//   }
// }






// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'omr_models.dart';
//
// class OMRGenerator {
//   static const double A4_WIDTH = 595.0; // A4 width in points
//   static const double A4_HEIGHT = 842.0; // A4 height in points
//   static const double MARGIN = 28.0;
//
//   static const double HEADER_HEIGHT = 100;
//   static const double STUDENT_INFO_HEIGHT = 150;
//   static const double ID_SECTION_HEIGHT = 140;
//   static const double ANSWER_SECTION_HEIGHT = 470;
//   static const double FOOTER_HEIGHT = 60;
//
//   static const double BUBBLE_RADIUS = 3.8;
//   static const double BUBBLE_SPACING = 17.0;
//   static const double COLUMN_SPACING = 18.0;
//
//   static Future<File> generateOMRSheet(OMRExamConfig config) async {
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//     final paint = Paint()..color = Colors.white;
//     canvas.drawRect(Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT), paint);
//
//     // === Draw Layout in A4 Flow ===
//     _drawProfessionalBorder(canvas);
//     double y = MARGIN;
//
//     y = _drawHeader(canvas, config, y);
//     y = _drawStudentSection(canvas, config, y + 10);
//     y = _drawIdAndPhone(canvas, config, y + 8);
//     y = _drawAnswerSection(canvas, config, y + 10);
//     _drawFooter(canvas);
//
//     if (config.correctAnswers.isNotEmpty) {
//       _drawAnswerKey(canvas, config.correctAnswers, config.numberOfQuestions);
//     }
//
//     // === Export as PNG ===
//     final picture = recorder.endRecording();
//     final img = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
//     final byteData = await img.toByteData(format: ImageByteFormat.png);
//     final bytes = byteData!.buffer.asUint8List();
//     final dir = await getTemporaryDirectory();
//     final file = File('${dir.path}/omr_${DateTime.now().millisecondsSinceEpoch}.png');
//     await file.writeAsBytes(bytes);
//     return file;
//   }
//
//   // ===== Border =====
//   static void _drawProfessionalBorder(Canvas canvas) {
//     final borderPaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.8;
//
//     canvas.drawRect(
//       Rect.fromLTWH(MARGIN - 3, MARGIN - 3, A4_WIDTH - 2 * (MARGIN - 3), A4_HEIGHT - 2 * (MARGIN - 3)),
//       borderPaint,
//     );
//   }
//
//   // ===== Header =====
//   static double _drawHeader(Canvas canvas, OMRExamConfig config, double y) {
//     final centerX = A4_WIDTH / 2;
//
//     final titlePainter = TextPainter(
//       text: TextSpan(
//         text: config.examName.toUpperCase(),
//         style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
//       ),
//       textDirection: TextDirection.ltr,
//     )..layout(maxWidth: A4_WIDTH - 2 * MARGIN);
//     titlePainter.paint(canvas, Offset(centerX - titlePainter.width / 2, y + 10));
//
//     final infoStyle = TextStyle(fontSize: 10, color: Colors.black);
//     final info = "Date: ${_formatDate(config.examDate)}      Total: ${config.numberOfQuestions} Qs      Time: 3 Hours";
//     final infoPainter = TextPainter(text: TextSpan(text: info, style: infoStyle), textDirection: TextDirection.ltr)
//       ..layout(maxWidth: A4_WIDTH - 2 * MARGIN);
//     infoPainter.paint(canvas, Offset(centerX - infoPainter.width / 2, y + 35));
//
//     _drawInstructionsBox(canvas, y + 55);
//     return y + HEADER_HEIGHT;
//   }
//
//   static void _drawInstructionsBox(Canvas canvas, double y) {
//     final bgPaint = Paint()..color = Colors.grey[100]!;
//     canvas.drawRect(Rect.fromLTWH(MARGIN + 10, y, A4_WIDTH - 2 * (MARGIN + 10), 38), bgPaint);
//
//     final borderPaint = Paint()
//       ..color = Colors.grey[400]!
//       ..style = PaintingStyle.stroke;
//     canvas.drawRect(Rect.fromLTWH(MARGIN + 10, y, A4_WIDTH - 2 * (MARGIN + 10), 38), borderPaint);
//
//     final lines = [
//       "• Use BLACK/BLUE pen only  • Fill circles completely",
//       "• No stray marks  • To change, erase completely  • Equal marks per question"
//     ];
//     double lineY = y + 8;
//     for (final text in lines) {
//       final p = TextPainter(
//         text: TextSpan(text: text, style: TextStyle(fontSize: 9, color: Colors.black87)),
//         textDirection: TextDirection.ltr,
//       )..layout(maxWidth: A4_WIDTH - 2 * MARGIN - 20);
//       p.paint(canvas, Offset(MARGIN + 15, lineY));
//       lineY += 12;
//     }
//   }
//
//   // ===== Student Info =====
//   static double _drawStudentSection(Canvas canvas, OMRExamConfig config, double y) {
//     _drawSectionTitle(canvas, "STUDENT INFORMATION", y);
//     y += 20;
//
//     final leftX = MARGIN + 20;
//     final rightX = A4_WIDTH / 2 + 20;
//
//     // SET NUMBER
//     final setLabel = TextPainter(
//       text: TextSpan(text: "SET:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     )..layout();
//     setLabel.paint(canvas, Offset(leftX, y));
//
//     double bubbleX = leftX + 45;
//     for (int i = 0; i < 10; i++) {
//       _drawBubble(canvas, bubbleX + i * 17, y - 3, i == config.setNumber);
//       final num = TextPainter(
//         text: TextSpan(text: "$i", style: TextStyle(fontSize: 8)),
//         textDirection: TextDirection.ltr,
//       )..layout();
//       num.paint(canvas, Offset(bubbleX + i * 17 + 2, y + 10));
//     }
//
//     // STUDENT NAME
//     final nameLabel = TextPainter(
//       text: TextSpan(text: "STUDENT NAME:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     )..layout();
//     nameLabel.paint(canvas, Offset(rightX, y));
//
//     final linePaint = Paint()..color = Colors.black..strokeWidth = 1;
//     canvas.drawLine(Offset(rightX + 90, y + 10), Offset(rightX + 250, y + 10), linePaint);
//     return y + 25;
//   }
//
//   // ===== ID + Phone Columns =====
//   static double _drawIdAndPhone(Canvas canvas, OMRExamConfig config, double y) {
//     _drawSectionTitle(canvas, "IDENTIFICATION", y);
//     y += 18;
//
//     final columnWidth = (A4_WIDTH - 2 * MARGIN - 20) / 2;
//
//     // Left: Student ID
//     _drawDigitColumn(canvas, "STUDENT ID (9 digits)", config.studentId, MARGIN + 10, y, 9, columnWidth - 10);
//
//     // Right: Mobile Number
//     _drawDigitColumn(canvas, "MOBILE NUMBER (11 digits)", config.mobileNumber,
//         MARGIN + columnWidth + 10, y, 11, columnWidth - 10);
//     return y + ID_SECTION_HEIGHT;
//   }
//
//   static void _drawDigitColumn(Canvas canvas, String title, String value, double x, double y, int digits, double width) {
//     final bg = Paint()..color = Colors.grey[50]!;
//     canvas.drawRect(Rect.fromLTWH(x, y, width, 120), bg);
//     final border = Paint()
//       ..color = Colors.grey[400]!
//       ..style = PaintingStyle.stroke;
//     canvas.drawRect(Rect.fromLTWH(x, y, width, 120), border);
//
//     final t = TextPainter(
//       text: TextSpan(text: title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     )..layout();
//     t.paint(canvas, Offset(x + 5, y - 12));
//
//     for (int pos = 0; pos < digits; pos++) {
//       final digitX = x + 15 + pos * 16;
//       for (int num = 0; num < 10; num++) {
//         final filled = pos < value.length && value[pos] == num.toString();
//         _drawBubble(canvas, digitX, y + 12 + num * 10, filled);
//       }
//     }
//   }
//
//   // ===== Answer Section =====
//   static double _drawAnswerSection(Canvas canvas, OMRExamConfig config, double y) {
//     _drawSectionTitle(canvas, "ANSWER SECTION (MAX 50 QUESTIONS)", y);
//     y += 18;
//
//     final columnWidth = (A4_WIDTH - 2 * MARGIN - 40) / 3;
//     final questionsPerCol = (config.numberOfQuestions / 3).ceil();
//
//     for (int col = 0; col < 3; col++) {
//       final startQ = col * questionsPerCol + 1;
//       final endQ = (col + 1) * questionsPerCol > config.numberOfQuestions
//           ? config.numberOfQuestions
//           : (col + 1) * questionsPerCol;
//       _drawAnswerColumn(canvas, startQ, endQ, MARGIN + 10 + col * (columnWidth + COLUMN_SPACING), y, columnWidth);
//     }
//
//     return y + ANSWER_SECTION_HEIGHT;
//   }
//
//   static void _drawAnswerColumn(Canvas canvas, int startQ, int endQ, double x, double y, double width) {
//     for (int q = startQ; q <= endQ; q++) {
//       final yPos = y + (q - startQ) * 18;
//       if (yPos > A4_HEIGHT - 150) break;
//
//       final qNum = TextPainter(
//         text: TextSpan(text: "Q${q.toString().padLeft(2, '0')}", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
//         textDirection: TextDirection.ltr,
//       )..layout();
//       qNum.paint(canvas, Offset(x, yPos));
//
//       for (int opt = 0; opt < 5; opt++) {
//         final optionX = x + 35 + opt * 16;
//         _drawBubble(canvas, optionX, yPos - 1, false);
//         final label = TextPainter(
//           text: TextSpan(text: String.fromCharCode(65 + opt), style: TextStyle(fontSize: 8)),
//           textDirection: TextDirection.ltr,
//         )..layout();
//         label.paint(canvas, Offset(optionX + 8, yPos));
//       }
//     }
//   }
//
//   // ===== Footer =====
//   static void _drawFooter(Canvas canvas) {
//     final y = A4_HEIGHT - MARGIN - 60;
//     final line = Paint()..color = Colors.black..strokeWidth = 1;
//     canvas.drawLine(Offset(MARGIN, y), Offset(A4_WIDTH - MARGIN, y), line);
//
//     _drawSignature(canvas, "STUDENT SIGNATURE", MARGIN + 20, y + 10);
//     _drawSignature(canvas, "INVIGILATOR SIGNATURE", A4_WIDTH / 2 - 60, y + 10);
//     _drawSignature(canvas, "DATE", A4_WIDTH - MARGIN - 130, y + 10);
//   }
//
//   static void _drawSignature(Canvas canvas, String label, double x, double y) {
//     final p = TextPainter(
//       text: TextSpan(text: label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     )..layout();
//     p.paint(canvas, Offset(x, y));
//     final line = Paint()..color = Colors.black..strokeWidth = 1;
//     canvas.drawLine(Offset(x, y + 10), Offset(x + 110, y + 10), line);
//   }
//
//   // ===== Utility Drawing =====
//   static void _drawSectionTitle(Canvas canvas, String title, double y) {
//     final bg = Paint()..color = Colors.blue[800]!;
//     canvas.drawRect(Rect.fromLTWH(MARGIN, y, 230, 15), bg);
//
//     final txt = TextPainter(
//       text: TextSpan(text: title, style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     )..layout(maxWidth: 230);
//     txt.paint(canvas, Offset(MARGIN + 8, y + 2));
//   }
//
//   static void _drawBubble(Canvas canvas, double x, double y, bool filled) {
//     final paint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//     canvas.drawCircle(Offset(x + 4, y + 4), BUBBLE_RADIUS, paint);
//     if (filled) {
//       final fill = Paint()..color = Colors.black;
//       canvas.drawCircle(Offset(x + 4, y + 4), BUBBLE_RADIUS - 0.8, fill);
//     }
//   }
//
//   static void _drawAnswerKey(Canvas canvas, List<String> answers, int totalQs) {
//     final red = Paint()..color = Colors.red;
//     final colWidth = (A4_WIDTH - 2 * MARGIN - 40) / 3;
//     final qPerCol = (totalQs / 3).ceil();
//
//     for (int i = 0; i < totalQs && i < answers.length; i++) {
//       final col = i ~/ qPerCol;
//       final inCol = i % qPerCol;
//       final opt = answers[i].toUpperCase().codeUnitAt(0) - 65;
//       final x = MARGIN + 10 + col * (colWidth + COLUMN_SPACING) + 35 + opt * 16;
//       final y = MARGIN + HEADER_HEIGHT + STUDENT_INFO_HEIGHT + ID_SECTION_HEIGHT + 40 + inCol * 18;
//       canvas.drawCircle(Offset(x + 4, y + 4), BUBBLE_RADIUS - 0.8, red);
//     }
//
//     final mark = TextPainter(
//       text: TextSpan(
//         text: "ANSWER KEY",
//         style: TextStyle(fontSize: 60, color: Colors.red.withOpacity(0.07), fontWeight: FontWeight.bold, letterSpacing: 8),
//       ),
//       textDirection: TextDirection.ltr,
//     )..layout();
//     mark.paint(canvas, Offset(A4_WIDTH / 2 - mark.width / 2, A4_HEIGHT / 2 - mark.height / 2));
//   }
//
//   static String _formatDate(DateTime d) =>
//       "${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}";
// }





// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'omr_models.dart';
//
// class OMRGenerator {
//   static const double A4_WIDTH = 595.0;
//   static const double A4_HEIGHT = 842.0;
//   static const double MARGIN = 30.0;
//   static const double BUBBLE_RADIUS = 4.0;
//   static const double BUBBLE_SPACING = 18.0;
//   static const double COLUMN_SPACING = 15.0;
//
//   static Future<File> generateOMRSheet(OMRExamConfig config) async {
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//
//     // Set background to white
//     canvas.drawRect(Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT), Paint()..color = Colors.white);
//
//     // Draw professional border
//     _drawProfessionalBorder(canvas);
//
//     // Draw sections
//     _drawProfessionalHeader(canvas, config);
//     _drawStudentInfoSection(canvas, config);
//     _drawAnswerSectionWithThreeColumns(canvas, config.numberOfQuestions);
//     _drawProfessionalFooter(canvas);
//
//     // Draw answer key if provided
//     if (config.correctAnswers.isNotEmpty) {
//       _drawAnswerKey(canvas, config.correctAnswers, config.numberOfQuestions);
//     }
//
//     final picture = recorder.endRecording();
//     final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
//     final bytes = byteData!.buffer.asUint8List();
//
//     final directory = await getTemporaryDirectory();
//     final file = File('${directory.path}/omr_sheet_${DateTime.now().millisecondsSinceEpoch}.png');
//     await file.writeAsBytes(bytes);
//
//     return file;
//   }
//
//   static void _drawProfessionalBorder(Canvas canvas) {
//     // Outer border
//     final outerBorderPaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN-2, MARGIN-2,
//         A4_WIDTH - 2*MARGIN + 4, A4_HEIGHT - 2*MARGIN + 4), outerBorderPaint);
//
//     // Inner border
//     final innerBorderPaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN+8, MARGIN+8,
//         A4_WIDTH - 2*MARGIN - 16, A4_HEIGHT - 2*MARGIN - 16), innerBorderPaint);
//   }
//
//   static void _drawProfessionalHeader(Canvas canvas, OMRExamConfig config) {
//     // Institution Header
//     final institutionStyle = TextStyle(
//       fontSize: 16,
//       fontWeight: FontWeight.bold,
//       color: Colors.blue[800],
//     );
//
//     final institutionPainter = TextPainter(
//       text: TextSpan(text: "PROFESSIONAL COACHING CENTER", style: institutionStyle),
//       textDirection: TextDirection.ltr,
//     );
//     institutionPainter.layout();
//     institutionPainter.paint(canvas, Offset(A4_WIDTH/2 - institutionPainter.width/2, MARGIN + 15));
//
//     // Exam Title
//     final titleStyle = TextStyle(
//       fontSize: 20,
//       fontWeight: FontWeight.bold,
//       color: Colors.black,
//       letterSpacing: 1.1,
//     );
//
//     final titlePainter = TextPainter(
//       text: TextSpan(text: config.examName.toUpperCase(), style: titleStyle),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(A4_WIDTH/2 - titlePainter.width/2, MARGIN + 40));
//
//     // Exam Details Row
//     final detailsStyle = TextStyle(
//       fontSize: 11,
//       fontWeight: FontWeight.normal,
//       color: Colors.black87,
//     );
//
//     // Date
//     final dateText = 'Date: ${_formatDate(config.examDate)}';
//     final datePainter = TextPainter(
//       text: TextSpan(text: dateText, style: detailsStyle),
//       textDirection: TextDirection.ltr,
//     );
//     datePainter.layout();
//     datePainter.paint(canvas, Offset(MARGIN + 20, MARGIN + 70));
//
//     // Total Questions
//     final questionsText = 'Total Questions: ${config.numberOfQuestions}';
//     final questionsPainter = TextPainter(
//       text: TextSpan(text: questionsText, style: detailsStyle),
//       textDirection: TextDirection.ltr,
//     );
//     questionsPainter.layout();
//     questionsPainter.paint(canvas, Offset(A4_WIDTH/2 - questionsPainter.width/2, MARGIN + 70));
//
//     // Time
//     final timeText = 'Time: 3 Hours';
//     final timePainter = TextPainter(
//       text: TextSpan(text: timeText, style: detailsStyle),
//       textDirection: TextDirection.ltr,
//     );
//     timePainter.layout();
//     timePainter.paint(canvas, Offset(A4_WIDTH - MARGIN - 20 - timePainter.width, MARGIN + 70));
//
//     // Professional Instructions Box
//     _drawInstructionsBox(canvas, MARGIN + 85);
//   }
//
//   static void _drawInstructionsBox(Canvas canvas, double startY) {
//     // Box background
//     final boxPaint = Paint()
//       ..color = Colors.grey[50]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN + 15, startY, A4_WIDTH - 2*MARGIN - 30, 50), boxPaint);
//
//     // Box border
//     final borderPaint = Paint()
//       ..color = Colors.grey[400]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN + 15, startY, A4_WIDTH - 2*MARGIN - 30, 50), borderPaint);
//
//     // Instructions
//     final instructions = [
//       "• Use BLACK/BLUE ball point pen only",
//       "• Fill circles completely • No stray marks",
//       "• Completely erase to change answer",
//       "• Each question carries equal marks"
//     ];
//
//     double instructionX = MARGIN + 25;
//     double instructionY = startY + 15;
//
//     for (var instruction in instructions) {
//       final instructionPainter = TextPainter(
//         text: TextSpan(text: instruction, style: TextStyle(fontSize: 9, color: Colors.black87, fontWeight: FontWeight.w500)),
//         textDirection: TextDirection.ltr,
//       );
//       instructionPainter.layout();
//       instructionPainter.paint(canvas, Offset(instructionX, instructionY));
//       instructionY += 12;
//     }
//   }
//
//   static void _drawStudentInfoSection(Canvas canvas, OMRExamConfig config) {
//     final double startY = MARGIN + 150;
//
//     // Section Title with background
//     _drawSectionTitleWithBackground(canvas, "STUDENT INFORMATION", startY - 5);
//
//     // Set Number and Basic Info Row
//     _drawSetNumberAndBasicInfo(canvas, config, startY + 25);
//
//     // Student ID and Mobile Number in two columns
//     _drawStudentIdColumn(canvas, config.studentId, startY + 75);
//     _drawMobileNumberColumn(canvas, config.mobileNumber, startY + 75);
//   }
//
//   static void _drawSectionTitleWithBackground(Canvas canvas, String title, double y) {
//     final style = TextStyle(
//       fontSize: 13,
//       fontWeight: FontWeight.bold,
//       color: Colors.white,
//     );
//
//     final painter = TextPainter(
//       text: TextSpan(text: title, style: style),
//       textDirection: TextDirection.ltr,
//     );
//     painter.layout();
//
//     // Background
//     final bgPaint = Paint()
//       ..color = Colors.blue[800]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(
//         MARGIN + 15,
//         y,
//         painter.width + 20,
//         painter.height + 8
//     ), bgPaint);
//
//     painter.paint(canvas, Offset(MARGIN + 25, y + 4));
//   }
//
//   static void _drawSetNumberAndBasicInfo(Canvas canvas, OMRExamConfig config, double startY) {
//     // Set Number Label
//     final setLabelPainter = TextPainter(
//       text: TextSpan(text: "SET NUMBER:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     setLabelPainter.layout();
//     setLabelPainter.paint(canvas, Offset(MARGIN + 25, startY));
//
//     // Draw set number bubbles (0-9)
//     final double bubbleStartX = MARGIN + 110;
//     for (int i = 0; i < 10; i++) {
//       _drawProfessionalBubbleWithNumber(canvas, bubbleStartX + i * BUBBLE_SPACING, startY - 3, i, i == config.setNumber);
//     }
//
//     // Student Name Label (Placeholder)
//     final nameLabelPainter = TextPainter(
//       text: TextSpan(text: "STUDENT NAME:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     nameLabelPainter.layout();
//     nameLabelPainter.paint(canvas, Offset(A4_WIDTH/2 - 50, startY));
//
//     // Name Underline
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 1.0;
//     canvas.drawLine(
//         Offset(A4_WIDTH/2 - 50, startY + 15),
//         Offset(A4_WIDTH/2 + 100, startY + 15),
//         linePaint
//     );
//   }
//
//   static void _drawStudentIdColumn(Canvas canvas, String studentId, double startY) {
//     final double columnX = MARGIN + 25;
//     final double columnWidth = (A4_WIDTH - 2*MARGIN - 50) / 2;
//
//     // Column Title
//     final titlePainter = TextPainter(
//       text: TextSpan(text: "STUDENT IDENTIFICATION NUMBER (9 digits)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(columnX, startY));
//
//     // Column background
//     final bgPaint = Paint()
//       ..color = Colors.grey[50]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(columnX - 5, startY + 10, columnWidth, 175), bgPaint);
//
//     final borderPaint = Paint()
//       ..color = Colors.grey[300]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     canvas.drawRect(Rect.fromLTWH(columnX - 5, startY + 10, columnWidth, 175), borderPaint);
//
//     // Draw student ID bubbles
//     for (int digitPos = 0; digitPos < 9; digitPos++) {
//       final double digitX = columnX + 10 + digitPos * BUBBLE_SPACING;
//
//       // Digit position number
//       final posPainter = TextPainter(
//         text: TextSpan(text: (digitPos + 1).toString(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue[800])),
//         textDirection: TextDirection.ltr,
//       );
//       posPainter.layout();
//       posPainter.paint(canvas, Offset(digitX + 3, startY + 25));
//
//       // Bubbles for this digit position
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digitPos < studentId.length &&
//             studentId[digitPos] == num.toString();
//         _drawProfessionalBubble(canvas, digitX, startY + 35 + num * 14, isFilled);
//
//         // Number label on left side
//         if (digitPos == 0) {
//           final numPainter = TextPainter(
//             text: TextSpan(text: num.toString(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
//             textDirection: TextDirection.ltr,
//           );
//           numPainter.layout();
//           numPainter.paint(canvas, Offset(columnX, startY + 37 + num * 14));
//         }
//       }
//     }
//   }
//
//   static void _drawMobileNumberColumn(Canvas canvas, String mobileNumber, double startY) {
//     final double columnX = A4_WIDTH / 2 + 10;
//     final double columnWidth = (A4_WIDTH - 2*MARGIN - 50) / 2;
//
//     // Column Title
//     final titlePainter = TextPainter(
//       text: TextSpan(text: "MOBILE NUMBER (11 digits)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(columnX, startY));
//
//     // Column background
//     final bgPaint = Paint()
//       ..color = Colors.grey[50]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(columnX - 5, startY + 10, columnWidth, 175), bgPaint);
//
//     final borderPaint = Paint()
//       ..color = Colors.grey[300]!
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     canvas.drawRect(Rect.fromLTWH(columnX - 5, startY + 10, columnWidth, 175), borderPaint);
//
//     // Draw mobile number bubbles
//     for (int digitPos = 0; digitPos < 11; digitPos++) {
//       final double digitX = columnX + 10 + digitPos * BUBBLE_SPACING;
//
//       // Digit position number
//       final posPainter = TextPainter(
//         text: TextSpan(text: (digitPos + 1).toString(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue[800])),
//         textDirection: TextDirection.ltr,
//       );
//       posPainter.layout();
//       posPainter.paint(canvas, Offset(digitX + 3, startY + 25));
//
//       // Bubbles for this digit position
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digitPos < mobileNumber.length &&
//             mobileNumber[digitPos] == num.toString();
//         _drawProfessionalBubble(canvas, digitX, startY + 35 + num * 14, isFilled);
//
//         // Number label on left side
//         if (digitPos == 0) {
//           final numPainter = TextPainter(
//             text: TextSpan(text: num.toString(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
//             textDirection: TextDirection.ltr,
//           );
//           numPainter.layout();
//           numPainter.paint(canvas, Offset(columnX, startY + 37 + num * 14));
//         }
//       }
//     }
//   }
//
//   static void _drawAnswerSectionWithThreeColumns(Canvas canvas, int numberOfQuestions) {
//     final double startY = MARGIN + 270;
//
//     // Section Title with background
//     _drawSectionTitleWithBackground(canvas, "ANSWER SHEET - MARK YOUR ANSWERS", startY - 5);
//
//     // Options Legend
//     _drawOptionsLegend(canvas, startY + 25);
//
//     // Draw questions in THREE columns
//     final questionsPerColumn = (numberOfQuestions / 3).ceil();
//     final columnWidth = (A4_WIDTH - 2 * MARGIN - 40) / 3;
//
//     for (int col = 0; col < 3; col++) {
//       final columnX = MARGIN + 20 + col * (columnWidth + COLUMN_SPACING);
//       _drawQuestionColumnThreeCol(canvas, columnX, startY + 50, col, numberOfQuestions, questionsPerColumn);
//     }
//   }
//
//   static void _drawOptionsLegend(Canvas canvas, double startY) {
//     final legendText = "OPTIONS: A • B • C • D • E";
//     final legendPainter = TextPainter(
//       text: TextSpan(
//           text: legendText,
//           style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue[800])
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     legendPainter.layout();
//     legendPainter.paint(canvas, Offset(A4_WIDTH/2 - legendPainter.width/2, startY));
//   }
//
//   static void _drawQuestionColumnThreeCol(Canvas canvas, double startX, double startY, int colIndex, int totalQuestions, int questionsPerColumn) {
//     final startQuestion = colIndex * questionsPerColumn + 1;
//     final endQuestion = (colIndex + 1) * questionsPerColumn;
//     final actualEnd = endQuestion > totalQuestions ? totalQuestions : endQuestion;
//
//     // Column header with background
//     final headerBgPaint = Paint()
//       ..color = Colors.grey[200]!
//       ..style = PaintingStyle.fill;
//
//     canvas.drawRect(Rect.fromLTWH(startX - 5, startY - 5, 160, 20), headerBgPaint);
//
//     final headerPainter = TextPainter(
//       text: TextSpan(
//           text: "QUESTIONS ${startQuestion}-${actualEnd}",
//           style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     headerPainter.layout();
//     headerPainter.paint(canvas, Offset(startX, startY));
//
//     // Questions
//     for (int q = startQuestion; q <= actualEnd; q++) {
//       if (q > totalQuestions) break;
//
//       final yPos = startY + 25 + (q - startQuestion) * 20;
//
//       // Question number with background
//       final qText = TextPainter(
//         text: TextSpan(text: 'Q${q.toString().padLeft(2)}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
//         textDirection: TextDirection.ltr,
//       );
//       qText.layout();
//
//       final qBgPaint = Paint()
//         ..color = Colors.blue[700]!
//         ..style = PaintingStyle.fill;
//
//       canvas.drawRect(Rect.fromLTWH(startX - 2, yPos - 1, qText.width + 4, qText.height + 2), qBgPaint);
//       qText.paint(canvas, Offset(startX, yPos));
//
//       // Options A, B, C, D, E
//       for (int option = 0; option < 5; option++) {
//         final optionChar = String.fromCharCode(65 + option);
//         final optionX = startX + 25 + option * 18;
//
//         // Option letter
//         final optionText = TextPainter(
//           text: TextSpan(text: optionChar, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
//           textDirection: TextDirection.ltr,
//         );
//         optionText.layout();
//         optionText.paint(canvas, Offset(optionX + 3, yPos));
//
//         // Professional bubble
//         _drawProfessionalBubble(canvas, optionX, yPos - 1, false);
//       }
//     }
//   }
//
//   static void _drawProfessionalFooter(Canvas canvas) {
//     final double footerY = A4_HEIGHT - MARGIN - 50;
//
//     // Top border line
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 1.0;
//     canvas.drawLine(Offset(MARGIN + 20, footerY), Offset(A4_WIDTH - MARGIN - 20, footerY), linePaint);
//
//     // Signature fields in three columns
//     final leftSignatureX = MARGIN + 30;
//     final middleSignatureX = A4_WIDTH / 2 - 60;
//     final rightSignatureX = A4_WIDTH - MARGIN - 150;
//
//     // Student Signature
//     _drawProfessionalSignatureField(canvas, "STUDENT'S SIGNATURE", leftSignatureX, footerY + 10);
//
//     // Invigilator Signature
//     _drawProfessionalSignatureField(canvas, "INVIGILATOR'S SIGNATURE", middleSignatureX, footerY + 10);
//
//     // Date field
//     _drawProfessionalSignatureField(canvas, "DATE", rightSignatureX, footerY + 10);
//
//     // Bottom note
//     final notePainter = TextPainter(
//       text: TextSpan(
//           text: "Note: This OMR sheet will be electronically evaluated. Ensure all bubbles are filled correctly.",
//           style: TextStyle(fontSize: 8, color: Colors.grey[600], fontStyle: FontStyle.italic)
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     notePainter.layout();
//     notePainter.paint(canvas, Offset(A4_WIDTH/2 - notePainter.width/2, footerY + 45));
//   }
//
//   static void _drawProfessionalSignatureField(Canvas canvas, String label, double x, double y) {
//     final labelPainter = TextPainter(
//       text: TextSpan(text: label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     labelPainter.layout();
//     labelPainter.paint(canvas, Offset(x, y));
//
//     // Signature line
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 1.0;
//     canvas.drawLine(Offset(x, y + 12), Offset(x + 120, y + 12), linePaint);
//   }
//
//   static void _drawAnswerKey(Canvas canvas, List<String> correctAnswers, int totalQuestions) {
//     final redPaint = Paint()..color = Colors.red;
//
//     final questionsPerColumn = (totalQuestions / 3).ceil();
//
//     for (int i = 0; i < correctAnswers.length; i++) {
//       if (i >= totalQuestions) break;
//
//       final colIndex = i ~/ questionsPerColumn;
//       final questionInColumn = i % questionsPerColumn;
//       final optionIndex = correctAnswers[i].codeUnitAt(0) - 65;
//
//       final columnWidth = (A4_WIDTH - 2 * MARGIN - 40) / 3;
//       final columnX = MARGIN + 20 + colIndex * (columnWidth + COLUMN_SPACING);
//       final yPos = MARGIN + 325 + 25 + questionInColumn * 20;
//
//       final optionX = columnX + 25 + optionIndex * 18;
//
//       // Fill the correct answer bubble in red
//       canvas.drawCircle(Offset(optionX + 5, yPos - 1 + 5), BUBBLE_RADIUS - 0.5, redPaint);
//     }
//
//     // Add "ANSWER KEY" watermark
//     final watermarkStyle = TextStyle(
//       fontSize: 72,
//       fontWeight: FontWeight.bold,
//       color: Colors.red.withOpacity(0.08),
//       letterSpacing: 8.0,
//     );
//     final watermarkPainter = TextPainter(
//       text: TextSpan(text: "ANSWER KEY", style: watermarkStyle),
//       textDirection: TextDirection.ltr,
//     );
//     watermarkPainter.layout();
//     watermarkPainter.paint(canvas, Offset(
//       A4_WIDTH / 2 - watermarkPainter.width / 2,
//       A4_HEIGHT / 2 - watermarkPainter.height / 2,
//     ));
//   }
//
//   static void _drawProfessionalBubble(Canvas canvas, double x, double y, bool filled) {
//     final paint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.2;
//
//     canvas.drawCircle(Offset(x + 5, y + 5), BUBBLE_RADIUS, paint);
//
//     if (filled) {
//       final fillPaint = Paint()..color = Colors.black;
//       canvas.drawCircle(Offset(x + 5, y + 5), BUBBLE_RADIUS - 0.8, fillPaint);
//     }
//   }
//
//   static void _drawProfessionalBubbleWithNumber(Canvas canvas, double x, double y, int number, bool filled) {
//     _drawProfessionalBubble(canvas, x, y, filled);
//
//     final numberPainter = TextPainter(
//       text: TextSpan(text: number.toString(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     numberPainter.layout();
//     numberPainter.paint(canvas, Offset(x + 2, y + 13));
//   }
//
//   static String _formatDate(DateTime date) {
//     final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
//     return '${date.day} ${months[date.month - 1]} ${date.year}';
//   }
// }



// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'omr_models.dart';
//
// class OMRGenerator {
//   static const double pageWidth = 595; // A4 width @ 72 DPI
//   static const double pageHeight = 842; // A4 height
//   static const double margin = 30.0;
//
//   static Future<File> generateOMRSheet(OMRExamConfig config) async {
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//     final bgPaint = Paint()..color = Colors.white;
//
//     // Draw background (A4 white sheet)
//     canvas.drawRect(Rect.fromLTWH(0, 0, pageWidth, pageHeight), bgPaint);
//
//     double yOffset = margin;
//
//     // 1️⃣ HEADER
//     yOffset = _drawHeader(canvas, config, yOffset);
//
//     // 2️⃣ STUDENT ID & MOBILE TAGS
//     yOffset = _drawIdAndMobile(canvas, config, yOffset + 15);
//
//     // 3️⃣ QUESTIONS (3 COLUMNS, 50 MAX)
//     yOffset = _drawQuestions(canvas, config, yOffset + 30);
//
//     // 4️⃣ FOOTER
//     _drawFooter(canvas, pageHeight - 80);
//
//     // Optional Answer Key Overlay
//     if (config.correctAnswers.isNotEmpty) {
//       _drawAnswerKey(canvas, config.correctAnswers);
//     }
//
//     // Convert to PNG
//     final picture = recorder.endRecording();
//     final image = await picture.toImage(pageWidth.toInt(), pageHeight.toInt());
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
//     final bytes = byteData!.buffer.asUint8List();
//
//     final directory = await getTemporaryDirectory();
//     final file = File('${directory.path}/omr_sheet_${DateTime.now().millisecondsSinceEpoch}.png');
//     await file.writeAsBytes(bytes);
//
//     return file;
//   }
//
//   // ================= HEADER =================
//   static double _drawHeader(Canvas canvas, OMRExamConfig config, double top) {
//     final titleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
//     final subStyle = TextStyle(fontSize: 12);
//
//     // Exam Title
//     _drawText(canvas, config.examName, Offset(margin, top), style: titleStyle);
//
//     // Date
//     final dateText = 'Date: ${config.examDate.day}/${config.examDate.month}/${config.examDate.year}';
//     _drawText(canvas, dateText, Offset(pageWidth - 160, top + 4), style: subStyle);
//
//     // Set No. Label
//     _drawText(canvas, 'Set No:', Offset(pageWidth - 160, top + 25), style: subStyle);
//
//     // Draw Set No bubbles (0–9)
//     for (int i = 0; i < 10; i++) {
//       _drawBubble(canvas, pageWidth - 110 + i * 13, top + 25, i == config.setNumber);
//       _drawText(canvas, i.toString(), Offset(pageWidth - 114 + i * 13, top + 37), size: 8);
//     }
//
//     // Student Name & Phone
//     _drawText(canvas, 'Student Name: ____________________________',
//         Offset(margin, top + 65), style: subStyle);
//     _drawText(canvas, 'Phone: ____________________________',
//         Offset(pageWidth / 2 + 10, top + 65), style: subStyle);
//
//     return top + 90;
//   }
//
//   // ================= ID + MOBILE SECTION =================
//   static double _drawIdAndMobile(Canvas canvas, OMRExamConfig config, double top) {
//     final labelStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
//
//     // Labels
//     _drawText(canvas, 'Student ID:', Offset(margin, top), style: labelStyle);
//     _drawText(canvas, 'Mobile Number:', Offset(pageWidth / 2 + 10, top), style: labelStyle);
//
//     // Student ID bubbles (Left)
//     for (int digit = 0; digit < 9; digit++) {
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digit < config.studentId.length &&
//             config.studentId[digit] == num.toString();
//         _drawBubble(canvas, margin + 80 + digit * 20, top + 15 + num * 16, isFilled);
//       }
//       _drawText(canvas, '${digit + 1}', Offset(margin + 82 + digit * 20, top + 180), size: 8);
//     }
//
//     // Mobile Number bubbles (Right)
//     for (int digit = 0; digit < 11; digit++) {
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digit < config.mobileNumber.length &&
//             config.mobileNumber[digit] == num.toString();
//         _drawBubble(canvas, pageWidth / 2 + 90 + digit * 20, top + 15 + num * 16, isFilled);
//       }
//       _drawText(canvas, '${digit + 1}', Offset(pageWidth / 2 + 92 + digit * 20, top + 180), size: 8);
//     }
//
//     return top + 200;
//   }
//
//   // ================= QUESTIONS SECTION =================
//   static double _drawQuestions(Canvas canvas, OMRExamConfig config, double top) {
//     final totalQuestions = config.numberOfQuestions.clamp(1, 50);
//     final questionsPerColumn = (totalQuestions / 3).ceil();
//     const colWidth = 180.0;
//     const rowHeight = 25.0;
//     const startX = margin;
//     final textStyle = TextStyle(fontSize: 10);
//
//     for (int col = 0; col < 3; col++) {
//       final startQ = col * questionsPerColumn;
//       final endQ = (col + 1) * questionsPerColumn;
//       for (int i = startQ; i < endQ && i < totalQuestions; i++) {
//         final qNum = i + 1;
//         final x = startX + col * colWidth;
//         final y = top + (i - startQ) * rowHeight;
//
//         // Question number
//         _drawText(canvas, qNum.toString().padLeft(2, '0'), Offset(x, y), style: textStyle);
//
//         // Draw bubbles for A–E
//         for (int opt = 0; opt < 5; opt++) {
//           final optChar = String.fromCharCode(65 + opt);
//           _drawText(canvas, optChar, Offset(x + 25 + opt * 28, y), size: 9);
//           _drawBubble(canvas, x + 35 + opt * 28, y - 4, false);
//         }
//       }
//     }
//
//     return top + (questionsPerColumn * rowHeight) + 20;
//   }
//
//   // ================= FOOTER =================
//   static void _drawFooter(Canvas canvas, double top) {
//     _drawText(canvas, 'Instructor Signature: ____________________________',
//         Offset(margin, top), size: 12);
//     _drawText(canvas, 'Exam Controller: ____________________________',
//         Offset(pageWidth / 2 + 10, top), size: 12);
//
//     _drawText(canvas, 'Generated by BlackBox OMR System',
//         Offset(pageWidth - 230, pageHeight - 25),
//         size: 8,
//         color: Colors.grey);
//   }
//
//   // ================= ANSWER KEY =================
//   static void _drawAnswerKey(Canvas canvas, List<String> correctAnswers) {
//     final paint = Paint()..color = Colors.red;
//     const colWidth = 180.0;
//     const startX = margin;
//     const top = 300.0;
//     const rowHeight = 25.0;
//
//     for (int i = 0; i < correctAnswers.length && i < 50; i++) {
//       final col = i ~/ 17; // 3 columns (approx)
//       final row = i % 17;
//       final x = startX + col * colWidth + 35;
//       final y = top + row * rowHeight;
//
//       final optIndex = correctAnswers[i].toUpperCase().codeUnitAt(0) - 65;
//       canvas.drawCircle(Offset(x + optIndex * 28 + 5, y + 5), 4, paint);
//     }
//   }
//
//   // ================= HELPERS =================
//   static void _drawBubble(Canvas canvas, double x, double y, bool filled) {
//     final stroke = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.8;
//     canvas.drawCircle(Offset(x, y), 6, stroke);
//
//     if (filled) {
//       final fill = Paint()..color = Colors.black;
//       canvas.drawCircle(Offset(x, y), 4, fill);
//     }
//   }
//
//   static void _drawText(Canvas canvas, String text, Offset offset,
//       {TextStyle? style, double? size, Color? color}) {
//     final effectiveStyle = style ??
//         TextStyle(
//           fontSize: size ?? 10,
//           color: color ?? Colors.black,
//           fontWeight: FontWeight.normal,
//         );
//     final tp = TextPainter(
//       text: TextSpan(text: text, style: effectiveStyle),
//       textDirection: TextDirection.ltr,
//     );
//     tp.layout();
//     tp.paint(canvas, offset);
//   }
// }
//




// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'omr_models.dart';
//
// class OMRGenerator {
//   static const double A4_WIDTH = 595.0;
//   static const double A4_HEIGHT = 842.0;
//   static const double MARGIN = 40.0;
//   static const double BUBBLE_RADIUS = 5.0;
//   static const double BUBBLE_SPACING = 20.0;
//   static const double COLUMN_SPACING = 60.0;
//
//   static Future<File> generateOMRSheet(OMRExamConfig config) async {
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//
//     // Set background to white
//     canvas.drawRect(Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT), Paint()..color = Colors.white);
//
//     // Draw border
//     _drawBorder(canvas);
//
//     // Draw sections
//     _drawHeader(canvas, config);
//     _drawStudentInfoSection(canvas, config);
//     _drawAnswerSection(canvas, config.numberOfQuestions);
//     _drawFooter(canvas);
//
//     // Draw answer key if provided
//     if (config.correctAnswers.isNotEmpty) {
//       _drawAnswerKey(canvas, config.correctAnswers);
//     }
//
//     final picture = recorder.endRecording();
//     final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
//     final bytes = byteData!.buffer.asUint8List();
//
//     final directory = await getTemporaryDirectory();
//     final file = File('${directory.path}/omr_sheet_${DateTime.now().millisecondsSinceEpoch}.png');
//     await file.writeAsBytes(bytes);
//
//     return file;
//   }
//
//   static void _drawBorder(Canvas canvas) {
//     final borderPaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;
//
//     canvas.drawRect(Rect.fromLTWH(MARGIN-5, MARGIN-5,
//         A4_WIDTH - 2*MARGIN + 10, A4_HEIGHT - 2*MARGIN + 10), borderPaint);
//   }
//
//   static void _drawHeader(Canvas canvas, OMRExamConfig config) {
//     final titleStyle = TextStyle(
//       fontSize: 18,
//       fontWeight: FontWeight.bold,
//       color: Colors.black,
//     );
//
//     final subtitleStyle = TextStyle(
//       fontSize: 12,
//       fontWeight: FontWeight.normal,
//       color: Colors.black,
//     );
//
//     // Exam Title
//     final titlePainter = TextPainter(
//       text: TextSpan(text: config.examName.toUpperCase(), style: titleStyle),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(A4_WIDTH/2 - titlePainter.width/2, MARGIN + 10));
//
//     // Exam Date
//     final dateText = 'Date: ${_formatDate(config.examDate)}';
//     final datePainter = TextPainter(
//       text: TextSpan(text: dateText, style: subtitleStyle),
//       textDirection: TextDirection.ltr,
//     );
//     datePainter.layout();
//     datePainter.paint(canvas, Offset(A4_WIDTH/2 - datePainter.width/2, MARGIN + 35));
//
//     // Instructions
//     final instructions = [
//       "INSTRUCTIONS: Use BLACK or BLUE ballpoint pen only.",
//       "Fill circles completely. Do not make any stray marks.",
//       "Erase completely if you want to change an answer."
//     ];
//
//     double instructionY = MARGIN + 60;
//     for (var instruction in instructions) {
//       final instructionPainter = TextPainter(
//         text: TextSpan(text: instruction, style: TextStyle(fontSize: 10, color: Colors.black54)),
//         textDirection: TextDirection.ltr,
//       );
//       instructionPainter.layout();
//       instructionPainter.paint(canvas, Offset(MARGIN + 20, instructionY));
//       instructionY += 15;
//     }
//   }
//
//   static void _drawStudentInfoSection(Canvas canvas, OMRExamConfig config) {
//     final double startY = MARGIN + 120;
//
//     // Section Title
//     _drawSectionTitle(canvas, "STUDENT INFORMATION", startY - 10);
//
//     // Set Number Row
//     _drawSetNumberRow(canvas, config.setNumber, startY);
//
//     // Student ID and Mobile in two columns
//     _drawStudentIdColumn(canvas, config.studentId, startY + 60);
//     _drawMobileNumberColumn(canvas, config.mobileNumber, startY + 60);
//   }
//
//   static void _drawSetNumberRow(Canvas canvas, int setNumber, double startY) {
//     final labelPainter = TextPainter(
//       text: TextSpan(text: "SET NUMBER:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     labelPainter.layout();
//     labelPainter.paint(canvas, Offset(MARGIN + 20, startY));
//
//     // Draw set number bubbles (0-9)
//     final double bubbleStartX = MARGIN + 120;
//     for (int i = 0; i < 10; i++) {
//       _drawBubbleWithNumber(canvas, bubbleStartX + i * BUBBLE_SPACING, startY - 5, i, i == setNumber);
//     }
//   }
//
//   static void _drawStudentIdColumn(Canvas canvas, String studentId, double startY) {
//     final double columnX = MARGIN + 20;
//
//     // Column Title
//     final titlePainter = TextPainter(
//       text: TextSpan(text: "STUDENT ID (9 digits)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(columnX, startY));
//
//     // Draw student ID bubbles
//     for (int digitPos = 0; digitPos < 9; digitPos++) {
//       final double digitX = columnX + digitPos * BUBBLE_SPACING;
//
//       // Digit position number
//       final posPainter = TextPainter(
//         text: TextSpan(text: (digitPos + 1).toString(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
//         textDirection: TextDirection.ltr,
//       );
//       posPainter.layout();
//       posPainter.paint(canvas, Offset(digitX + 3, startY + 15));
//
//       // Bubbles for this digit position
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digitPos < studentId.length &&
//             studentId[digitPos] == num.toString();
//         _drawBubble(canvas, digitX, startY + 25 + num * 15, isFilled);
//
//         // Number label
//         if (digitPos == 0) {
//           final numPainter = TextPainter(
//             text: TextSpan(text: num.toString(), style: TextStyle(fontSize: 8)),
//             textDirection: TextDirection.ltr,
//           );
//           numPainter.layout();
//           numPainter.paint(canvas, Offset(columnX - 10, startY + 28 + num * 15));
//         }
//       }
//     }
//   }
//
//   static void _drawMobileNumberColumn(Canvas canvas, String mobileNumber, double startY) {
//     final double columnX = A4_WIDTH / 2 + 20;
//
//     // Column Title
//     final titlePainter = TextPainter(
//       text: TextSpan(text: "MOBILE NUMBER (11 digits)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
//       textDirection: TextDirection.ltr,
//     );
//     titlePainter.layout();
//     titlePainter.paint(canvas, Offset(columnX, startY));
//
//     // Draw mobile number bubbles
//     for (int digitPos = 0; digitPos < 11; digitPos++) {
//       final double digitX = columnX + digitPos * BUBBLE_SPACING;
//
//       // Digit position number
//       final posPainter = TextPainter(
//         text: TextSpan(text: (digitPos + 1).toString(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
//         textDirection: TextDirection.ltr,
//       );
//       posPainter.layout();
//       posPainter.paint(canvas, Offset(digitX + 3, startY + 15));
//
//       // Bubbles for this digit position
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digitPos < mobileNumber.length &&
//             mobileNumber[digitPos] == num.toString();
//         _drawBubble(canvas, digitX, startY + 25 + num * 15, isFilled);
//
//         // Number label
//         if (digitPos == 0) {
//           final numPainter = TextPainter(
//             text: TextSpan(text: num.toString(), style: TextStyle(fontSize: 8)),
//             textDirection: TextDirection.ltr,
//           );
//           numPainter.layout();
//           numPainter.paint(canvas, Offset(columnX - 10, startY + 28 + num * 15));
//         }
//       }
//     }
//   }
//
//   static void _drawAnswerSection(Canvas canvas, int numberOfQuestions) {
//     final double startY = MARGIN + 280;
//
//     // Section Title
//     _drawSectionTitle(canvas, "ANSWER SHEET", startY - 10);
//
//     // Instructions for answers
//     final instructionPainter = TextPainter(
//       text: TextSpan(
//           text: "Choose the correct option by filling the corresponding circle completely",
//           style: TextStyle(fontSize: 10, color: Colors.black54)
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     instructionPainter.layout();
//     instructionPainter.paint(canvas, Offset(MARGIN + 20, startY + 10));
//
//     // Draw questions in two columns
//     final questionsPerColumn = 25;
//     final columns = (numberOfQuestions / questionsPerColumn).ceil();
//
//     for (int col = 0; col < columns; col++) {
//       final columnX = MARGIN + 20 + col * (A4_WIDTH - 2 * MARGIN - 40) / columns;
//       _drawQuestionColumn(canvas, columnX, startY + 30, col, numberOfQuestions);
//     }
//   }
//
//   static void _drawQuestionColumn(Canvas canvas, double startX, double startY, int colIndex, int totalQuestions) {
//     final questionsPerColumn = 25;
//     final startQuestion = colIndex * questionsPerColumn + 1;
//     final endQuestion = (colIndex + 1) * questionsPerColumn;
//     final actualEnd = endQuestion > totalQuestions ? totalQuestions : endQuestion;
//
//     // Column header
//     final headerPainter = TextPainter(
//       text: TextSpan(
//           text: "QUESTIONS ${startQuestion}-${actualEnd}",
//           style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     headerPainter.layout();
//     headerPainter.paint(canvas, Offset(startX, startY));
//
//     // Questions
//     for (int q = startQuestion; q <= actualEnd; q++) {
//       final yPos = startY + 20 + (q - startQuestion) * 22;
//
//       // Question number
//       final qText = TextPainter(
//         text: TextSpan(text: 'Q${q.toString().padLeft(2)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
//         textDirection: TextDirection.ltr,
//       );
//       qText.layout();
//       qText.paint(canvas, Offset(startX, yPos));
//
//       // Options A, B, C, D, E
//       for (int option = 0; option < 5; option++) {
//         final optionChar = String.fromCharCode(65 + option);
//         final optionX = startX + 40 + option * 25;
//
//         // Option letter
//         final optionText = TextPainter(
//           text: TextSpan(text: optionChar, style: TextStyle(fontSize: 9)),
//           textDirection: TextDirection.ltr,
//         );
//         optionText.layout();
//         optionText.paint(canvas, Offset(optionX + 3, yPos));
//
//         // Bubble
//         _drawBubble(canvas, optionX, yPos - 2, false);
//       }
//     }
//   }
//
//   static void _drawFooter(Canvas canvas) {
//     final double footerY = A4_HEIGHT - MARGIN - 40;
//
//     // Horizontal line
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 1.0;
//     canvas.drawLine(Offset(MARGIN + 20, footerY), Offset(A4_WIDTH - MARGIN - 20, footerY), linePaint);
//
//     // Signature fields in two columns
//     final leftSignatureX = MARGIN + 40;
//     final rightSignatureX = A4_WIDTH / 2 + 40;
//
//     // Student Signature
//     _drawSignatureField(canvas, "STUDENT'S SIGNATURE", leftSignatureX, footerY + 10);
//
//     // Instructor Signature
//     _drawSignatureField(canvas, "INSTRUCTOR'S SIGNATURE", rightSignatureX, footerY + 10);
//
//     // Date field
//     final datePainter = TextPainter(
//       text: TextSpan(text: "DATE: ________________", style: TextStyle(fontSize: 11)),
//       textDirection: TextDirection.ltr,
//     );
//     datePainter.layout();
//     datePainter.paint(canvas, Offset(A4_WIDTH - MARGIN - 150, footerY + 35));
//   }
//
//   static void _drawSignatureField(Canvas canvas, String label, double x, double y) {
//     final labelPainter = TextPainter(
//       text: TextSpan(text: label, style: TextStyle(fontSize: 10)),
//       textDirection: TextDirection.ltr,
//     );
//     labelPainter.layout();
//     labelPainter.paint(canvas, Offset(x, y));
//
//     // Signature line
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 1.0;
//     canvas.drawLine(Offset(x, y + 15), Offset(x + 150, y + 15), linePaint);
//   }
//
//   static void _drawAnswerKey(Canvas canvas, List<String> correctAnswers) {
//     final redPaint = Paint()..color = Colors.red;
//
//     for (int i = 0; i < correctAnswers.length; i++) {
//       final questionIndex = i ~/ 25;
//       final questionInColumn = i % 25;
//       final optionIndex = correctAnswers[i].codeUnitAt(0) - 65;
//
//       final columnX = MARGIN + 20 + questionIndex * (A4_WIDTH - 2 * MARGIN - 40) / 2;
//       final yPos = MARGIN + 330 + 20 + questionInColumn * 22;
//
//       final optionX = columnX + 40 + optionIndex * 25;
//
//       // Fill the correct answer bubble in red
//       canvas.drawCircle(Offset(optionX + 5, yPos - 2 + 5), BUBBLE_RADIUS - 1, redPaint);
//     }
//
//     // Add "ANSWER KEY" watermark
//     final watermarkStyle = TextStyle(
//       fontSize: 48,
//       fontWeight: FontWeight.bold,
//       color: Colors.red.withOpacity(0.1),
//     );
//     final watermarkPainter = TextPainter(
//       text: TextSpan(text: "ANSWER KEY", style: watermarkStyle),
//       textDirection: TextDirection.ltr,
//     );
//     watermarkPainter.layout();
//     watermarkPainter.paint(canvas, Offset(
//       A4_WIDTH / 2 - watermarkPainter.width / 2,
//       A4_HEIGHT / 2 - watermarkPainter.height / 2,
//     ));
//   }
//
//   static void _drawSectionTitle(Canvas canvas, String title, double y) {
//     final style = TextStyle(
//       fontSize: 14,
//       fontWeight: FontWeight.bold,
//       color: Colors.black,
//     );
//
//     final painter = TextPainter(
//       text: TextSpan(text: title, style: style),
//       textDirection: TextDirection.ltr,
//     );
//     painter.layout();
//     painter.paint(canvas, Offset(A4_WIDTH/2 - painter.width/2, y));
//
//     // Underline
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 1.0;
//     canvas.drawLine(
//         Offset(A4_WIDTH/2 - painter.width/2, y + painter.height + 2),
//         Offset(A4_WIDTH/2 + painter.width/2, y + painter.height + 2),
//         linePaint
//     );
//   }
//
//   static void _drawBubble(Canvas canvas, double x, double y, bool filled) {
//     final paint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     canvas.drawCircle(Offset(x + 5, y + 5), BUBBLE_RADIUS, paint);
//
//     if (filled) {
//       final fillPaint = Paint()..color = Colors.black;
//       canvas.drawCircle(Offset(x + 5, y + 5), BUBBLE_RADIUS - 1, fillPaint);
//     }
//   }
//
//   static void _drawBubbleWithNumber(Canvas canvas, double x, double y, int number, bool filled) {
//     _drawBubble(canvas, x, y, filled);
//
//     final numberPainter = TextPainter(
//       text: TextSpan(text: number.toString(), style: TextStyle(fontSize: 9)),
//       textDirection: TextDirection.ltr,
//     );
//     numberPainter.layout();
//     numberPainter.paint(canvas, Offset(x + 2, y + 12));
//   }
//
//   static String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }
// }
//



// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
//
// import 'omr_models.dart';
//
// class OMRGenerator {
//   static const double pageWidth = 595; // A4 @ 72 DPI
//   static const double pageHeight = 842;
//
//   static Future<File> generateOMRSheet(OMRExamConfig config) async {
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//     final bgPaint = Paint()..color = Colors.white;
//
//     // Draw background
//     canvas.drawRect(Rect.fromLTWH(0, 0, pageWidth, pageHeight), bgPaint);
//
//     // Margin boundaries
//     const margin = 30.0;
//
//     // === Header ===
//     _drawHeader(canvas, config, margin);
//
//     // === ID & Mobile Section ===
//     _drawIdAndMobile(canvas, config, margin + 130);
//
//     // === Questions Section (Max 50 Qs, 2 columns) ===
//     _drawQuestions(canvas, config, margin + 340);
//
//     // === Footer Section ===
//     _drawFooter(canvas, margin);
//
//     // If has correct answers (for answer key sheet)
//     if (config.correctAnswers.isNotEmpty) {
//       _drawAnswerKey(canvas, config.correctAnswers);
//     }
//
//     // Convert to image
//     final picture = recorder.endRecording();
//     final image = await picture.toImage(pageWidth.toInt(), pageHeight.toInt());
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
//     final bytes = byteData!.buffer.asUint8List();
//
//     final directory = await getTemporaryDirectory();
//     final file = File('${directory.path}/omr_sheet_${DateTime.now().millisecondsSinceEpoch}.png');
//     await file.writeAsBytes(bytes);
//     return file;
//   }
//
//   // ================== HEADER ===================
//   static void _drawHeader(Canvas canvas, OMRExamConfig config, double top) {
//     final titleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
//     final subtitleStyle = TextStyle(fontSize: 12);
//
//     // Exam Name
//     _drawText(canvas, config.examName, Offset(50, top), style: titleStyle);
//
//     // Exam Date
//     final dateText =
//         'Date: ${config.examDate.day}/${config.examDate.month}/${config.examDate.year}';
//     _drawText(canvas, dateText, Offset(pageWidth - 180, top + 5), style: subtitleStyle);
//
//     // Set Number Label
//     _drawText(canvas, 'SET NO:', Offset(pageWidth - 180, top + 30), style: subtitleStyle);
//
//     // Set Number Bubbles (0–9)
//     for (int i = 0; i < 10; i++) {
//       _drawBubble(canvas, pageWidth - 130 + (i * 15), top + 25, i == config.setNumber);
//       _drawText(canvas, i.toString(), Offset(pageWidth - 130 + (i * 15), top + 40),
//           size: 8);
//     }
//
//     // Student Name and Phone Line
//     _drawText(canvas, 'Student Name: ____________________________',
//         Offset(50, top + 70), style: subtitleStyle);
//     _drawText(canvas, 'Phone: ____________________',
//         Offset(pageWidth / 2 + 10, top + 70), style: subtitleStyle);
//   }
//
//   // ================ ID + MOBILE SECTION ==================
//   static void _drawIdAndMobile(Canvas canvas, OMRExamConfig config, double top) {
//     final labelStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
//
//     // Titles
//     _drawText(canvas, 'Student ID:', Offset(50, top), style: labelStyle);
//     _drawText(canvas, 'Mobile Number:', Offset(pageWidth / 2 + 20, top),
//         style: labelStyle);
//
//     // Student ID Bubbles (left)
//     for (int digitPos = 0; digitPos < 9; digitPos++) {
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digitPos < config.studentId.length &&
//             config.studentId[digitPos] == num.toString();
//         _drawBubble(canvas, 130 + digitPos * 20, top + 20 + num * 16, isFilled);
//       }
//       _drawText(canvas, '${digitPos + 1}', Offset(132 + digitPos * 20, top + 190),
//           size: 8);
//     }
//
//     // Mobile Number Bubbles (right)
//     for (int digitPos = 0; digitPos < 11; digitPos++) {
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digitPos < config.mobileNumber.length &&
//             config.mobileNumber[digitPos] == num.toString();
//         _drawBubble(canvas, pageWidth / 2 + 120 + digitPos * 20, top + 20 + num * 16,
//             isFilled);
//       }
//       _drawText(canvas, '${digitPos + 1}',
//           Offset(pageWidth / 2 + 122 + digitPos * 20, top + 190),
//           size: 8);
//     }
//   }
//
//   // ================ QUESTIONS SECTION ==================
//   static void _drawQuestions(Canvas canvas, OMRExamConfig config, double top) {
//     final questions = config.numberOfQuestions.clamp(1, 50);
//     const questionsPerColumn = 25;
//     const colWidth = 260.0;
//     const startX = 50.0;
//     const startY = 0.0;
//     const rowHeight = 26.0;
//
//     final textStyle = TextStyle(fontSize: 10);
//
//     for (int col = 0; col < 2; col++) {
//       final startQ = col * questionsPerColumn;
//       final endQ = (col + 1) * questionsPerColumn;
//
//       for (int i = startQ; i < endQ && i < questions; i++) {
//         final y = top + startY + (i - startQ) * rowHeight;
//         final x = startX + col * colWidth;
//
//         // Question number
//         _drawText(canvas, 'Q${(i + 1).toString().padLeft(2, '0')}', Offset(x, y),
//             style: textStyle);
//
//         // Draw options A–E
//         for (int opt = 0; opt < 5; opt++) {
//           final optChar = String.fromCharCode(65 + opt);
//           _drawText(canvas, optChar, Offset(x + 35 + opt * 35, y), size: 9);
//           _drawBubble(canvas, x + 45 + opt * 35, y - 5, false);
//         }
//       }
//     }
//   }
//
//   // ================ FOOTER SECTION ==================
//   static void _drawFooter(Canvas canvas, double margin) {
//     const y = pageHeight - 70;
//
//     _drawText(canvas, 'Instructor Signature: ______________________',
//         Offset(margin, y), size: 12);
//     _drawText(canvas, 'Exam Controller: ______________________',
//         Offset(pageWidth / 2 + 20, y), size: 12);
//
//     _drawText(canvas, 'Generated by BlackBox OMR System',
//         Offset(pageWidth - 220, pageHeight - 25),
//         size: 8,
//         color: Colors.grey);
//   }
//
//   // ================ ANSWER KEY (OPTIONAL) ==================
//   static void _drawAnswerKey(Canvas canvas, List<String> correctAnswers) {
//     final paint = Paint()..color = Colors.red;
//     const colWidth = 260.0;
//     const startX = 50.0;
//     const top = 340.0;
//     const rowHeight = 26.0;
//
//     for (int i = 0; i < correctAnswers.length && i < 50; i++) {
//       final col = i ~/ 25;
//       final row = i % 25;
//       final x = startX + col * colWidth + 45;
//       final y = top + row * rowHeight;
//
//       final optIndex = correctAnswers[i].toUpperCase().codeUnitAt(0) - 65;
//       canvas.drawCircle(Offset(x + optIndex * 35 + 5, y + 5), 4, paint);
//     }
//   }
//
//   // ================== HELPERS ===================
//   static void _drawBubble(Canvas canvas, double x, double y, bool filled) {
//     final stroke = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.8;
//     canvas.drawCircle(Offset(x, y), 6, stroke);
//
//     if (filled) {
//       final fill = Paint()..color = Colors.black;
//       canvas.drawCircle(Offset(x, y), 4, fill);
//     }
//   }
//
//   static void _drawText(Canvas canvas, String text, Offset offset,
//       {TextStyle? style, double? size, Color? color}) {
//     final effectiveStyle = style ??
//         TextStyle(
//             fontSize: size ?? 10,
//             color: color ?? Colors.black,
//             fontWeight: FontWeight.normal);
//     final painter = TextPainter(
//       text: TextSpan(text: text, style: effectiveStyle),
//       textDirection: TextDirection.ltr,
//     );
//     painter.layout();
//     painter.paint(canvas, offset);
//   }
// }
//



// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
//
// import 'omr_models.dart';
//
// class OMRGenerator {
//   static Future<File> generateOMRSheet(OMRExamConfig config) async {
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//     final paint = Paint();
//
//     // Set background to white
//     canvas.drawRect(Rect.fromLTWH(0, 0, 595, 842), Paint()..color = Colors.white);
//
//     _drawHeader(canvas, config);
//     _drawSetNumber(canvas, config.setNumber);
//     _drawStudentId(canvas, config.studentId);
//     _drawMobileNumber(canvas, config.mobileNumber);
//     _drawQuestions(canvas, config.numberOfQuestions);
//     _drawFooter(canvas);
//
//     if (config.correctAnswers.isNotEmpty) {
//       _drawAnswerKey(canvas, config.correctAnswers);
//     }
//
//     final picture = recorder.endRecording();
//     final image = await picture.toImage(595, 842);
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
//     final bytes = byteData!.buffer.asUint8List();
//
//     final directory = await getTemporaryDirectory();
//     final file = File('${directory.path}/omr_sheet_${DateTime.now().millisecondsSinceEpoch}.png');
//     await file.writeAsBytes(bytes);
//
//     return file;
//   }
//
//   static void _drawHeader(Canvas canvas, OMRExamConfig config) {
//     final textStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
//     final textPainter = TextPainter(
//       text: TextSpan(text: config.examName, style: textStyle),
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(150, 30));
//
//     // Draw exam date
//     final dateText = TextPainter(
//       text: TextSpan(
//         text: 'Date: ${config.examDate.day}/${config.examDate.month}/${config.examDate.year}',
//         style: TextStyle(fontSize: 12),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     dateText.layout();
//     dateText.paint(canvas, Offset(400, 35));
//   }
//
//   static void _drawSetNumber(Canvas canvas, int setNumber) {
//     final textPainter = TextPainter(
//       text: TextSpan(text: 'Set Number:', style: TextStyle(fontSize: 14)),
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(50, 80));
//
//     // Draw set number bubbles (0-9)
//     for (int i = 0; i < 10; i++) {
//       _drawBubble(canvas, 150 + i * 25, 80, i == setNumber);
//       _drawNumberBelowBubble(canvas, 150 + i * 25, 100, i);
//     }
//   }
//
//   static void _drawStudentId(Canvas canvas, String studentId) {
//     final textPainter = TextPainter(
//       text: TextSpan(text: 'Student ID:', style: TextStyle(fontSize: 14)),
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(50, 130));
//
//     // Draw 9 digits for student ID
//     for (int digitPos = 0; digitPos < 9; digitPos++) {
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digitPos < studentId.length &&
//             studentId[digitPos] == num.toString();
//         _drawBubble(canvas, 150 + digitPos * 25, 130 + num * 20, isFilled);
//       }
//
//       // Draw digit position numbers
//       _drawNumberBelowBubble(canvas, 150 + digitPos * 25, 330, digitPos + 1);
//     }
//   }
//
//   static void _drawMobileNumber(Canvas canvas, String mobileNumber) {
//     final textPainter = TextPainter(
//       text: TextSpan(text: 'Mobile Number:', style: TextStyle(fontSize: 14)),
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(50, 360));
//
//     // Draw 11 digits for mobile number
//     for (int digitPos = 0; digitPos < 11; digitPos++) {
//       for (int num = 0; num < 10; num++) {
//         final isFilled = digitPos < mobileNumber.length &&
//             mobileNumber[digitPos] == num.toString();
//         _drawBubble(canvas, 150 + digitPos * 25, 360 + num * 20, isFilled);
//       }
//
//       // Draw digit position numbers
//       _drawNumberBelowBubble(canvas, 150 + digitPos * 25, 560, digitPos + 1);
//     }
//   }
//
//   static void _drawQuestions(Canvas canvas, int numberOfQuestions) {
//     final questionsPerColumn = 25;
//     final columns = (numberOfQuestions / questionsPerColumn).ceil();
//
//     for (int col = 0; col < columns; col++) {
//       final startQuestion = col * questionsPerColumn + 1;
//       final endQuestion = (col + 1) * questionsPerColumn;
//       final actualEnd = endQuestion > numberOfQuestions ? numberOfQuestions : endQuestion;
//
//       for (int q = startQuestion; q <= actualEnd; q++) {
//         final yPos = 600 + (q - startQuestion) * 30;
//
//         // Question number
//         final qText = TextPainter(
//           text: TextSpan(text: 'Q${q.toString().padLeft(2)}', style: TextStyle(fontSize: 12)),
//           textDirection: TextDirection.ltr,
//         );
//         qText.layout();
//         qText.paint(canvas, Offset(50 + col * 250, yPos.toDouble()));
//
//         // Options A, B, C, D, E
//         for (int option = 0; option < 5; option++) {
//           final optionChar = String.fromCharCode(65 + option);
//           final optionText = TextPainter(
//             text: TextSpan(text: optionChar, style: TextStyle(fontSize: 10)),
//             textDirection: TextDirection.ltr,
//           );
//           optionText.layout();
//           optionText.paint(canvas, Offset(100 + col * 250 + option * 25, yPos.toDouble()));
//
//           _drawBubble(canvas, 115 + col * 250 + option * 25, yPos.toDouble(), false);
//         }
//       }
//     }
//   }
//
//   static void _drawFooter(Canvas canvas) {
//     // Instructor signature
//     final instructorText = TextPainter(
//       text: TextSpan(text: 'Instructor Signature: ________________', style: TextStyle(fontSize: 12)),
//       textDirection: TextDirection.ltr,
//     );
//     instructorText.layout();
//     instructorText.paint(canvas, Offset(50, 780));
//
//     // Exam controller signature
//     final controllerText = TextPainter(
//       text: TextSpan(text: 'Exam Controller: ________________', style: TextStyle(fontSize: 12)),
//       textDirection: TextDirection.ltr,
//     );
//     controllerText.layout();
//     controllerText.paint(canvas, Offset(350, 780));
//   }
//
//   static void _drawAnswerKey(Canvas canvas, List<String> correctAnswers) {
//     // Draw correct answers in red for answer key
//     final redPaint = Paint()..color = Colors.red;
//
//     for (int i = 0; i < correctAnswers.length; i++) {
//       final questionIndex = i ~/ 25;
//       final questionInColumn = i % 25;
//       final optionIndex = correctAnswers[i].codeUnitAt(0) - 65;
//
//       final x = 115 + questionIndex * 250 + optionIndex * 25;
//       final y = 600 + questionInColumn * 30;
//
//       // Fill the correct answer bubble
//       canvas.drawCircle(Offset(x + 5, y + 10), 4, redPaint);
//     }
//   }
//
//   static void _drawBubble(Canvas canvas, double x, double y, bool filled) {
//     final paint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1;
//
//     canvas.drawCircle(Offset(x + 5, y + 10), 6, paint);
//
//     if (filled) {
//       final fillPaint = Paint()..color = Colors.black;
//       canvas.drawCircle(Offset(x + 5, y + 10), 4, fillPaint);
//     }
//   }
//
//   static void _drawNumberBelowBubble(Canvas canvas, double x, double y, int number) {
//     final textPainter = TextPainter(
//       text: TextSpan(text: number.toString(), style: TextStyle(fontSize: 10)),
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(x + 2, y));
//   }
// }