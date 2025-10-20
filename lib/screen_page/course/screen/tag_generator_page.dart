import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TagGeneratorPage extends StatefulWidget {
  const TagGeneratorPage({Key? key}) : super(key: key);

  @override
  _TagGeneratorPageState createState() => _TagGeneratorPageState();
}

class _TagGeneratorPageState extends State<TagGeneratorPage> {
  final _studentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qCountController = TextEditingController(text: '20');
  final GlobalKey _previewKey = GlobalKey();

  int questionCount = 20;

  Future<void> _savePreviewAsImage() async {
    RenderRepaintBoundary boundary =
    _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/omr_tag_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(pngBytes);
    await Gal.putImage(file.path);
    await Share.shareXFiles([XFile(file.path)], text: 'OMR Tag');
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved & shared successfully.')));
  }

  void _generateNewTag() {
    setState(() {
      questionCount = int.tryParse(_qCountController.text) ?? 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentId = _studentController.text;
    final phone = _phoneController.text;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('🎓 OMR Tag Generator'),
        backgroundColor: Colors.blueGrey[800],
        elevation: 2,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt, color: Colors.white),
            onPressed: _savePreviewAsImage,
            tooltip: "Save & Share",
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shadowColor: Colors.grey.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _studentController,
                      decoration: InputDecoration(
                        labelText: 'Student ID (9 digits)',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone (9 digits)',
                        prefixIcon: const Icon(Icons.phone),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _qCountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Number of Questions (A–D)',
                        prefixIcon: const Icon(Icons.format_list_numbered),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Generate Tag"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                      onPressed: _generateNewTag,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            RepaintBoundary(
              key: _previewKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = width * 2.0;
                  return Container(
                    width: width,
                    height: height,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ],
                        border: Border.all(color: Colors.grey.shade300)
                    ),
                    child: CustomPaint(
                      size: Size(width, height),
                      painter: _ResponsiveOMRPainter(
                        studentId: studentId,
                        phone: phone,
                        questionCount: questionCount,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💡 Instructions: Scroll to see all questions. Print at high quality (A4 Portrait). Ensure QR code, bubbles, and ID fields are clearly visible. Use HB pencil to fill bubbles completely.',
                style: TextStyle(fontSize: 13, color: Colors.blueGrey, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveOMRPainter extends CustomPainter {
  final String studentId;
  final String phone;
  final int questionCount;

  _ResponsiveOMRPainter({
    required this.studentId,
    required this.phone,
    required this.questionCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0,0, size.width, size.height), bg);

    // Header with professional styling
    final headerPaint = Paint()..color = Colors.blueGrey[800]!;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 72), headerPaint);

    final title = TextPainter(
      text: const TextSpan(
        text: 'OMR ANSWER SHEET',
        style: TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5),
      ),
      textDirection: TextDirection.ltr,
    );
    title.layout();
    title.paint(canvas, Offset((size.width - title.width) / 1.4, 15));

    final subtitle = TextPainter(
      text: const TextSpan(
        text: 'COMPUTERIZED GRADING SYSTEM',
        style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3),
      ),
      textDirection: TextDirection.ltr,
    );
    subtitle.layout();
    subtitle.paint(canvas, Offset((size.width - subtitle.width) / 1.5, 38));

    // QR Code with professional styling
    final qrSize = size.width * 0.21;
    final qrRect = Rect.fromLTWH(25, 100, qrSize, qrSize);

    // QR background
    final qrBg = Paint()
      ..color = Colors.grey[50]!
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
        RRect.fromRectAndRadius(qrRect.inflate(8), const Radius.circular(8)),
        qrBg
    );

    final qrBorder = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
        RRect.fromRectAndRadius(qrRect.inflate(8), const Radius.circular(8)),
        qrBorder
    );

    final qrPainter = QrPainter(
      data: "$studentId|$phone",
      version: QrVersions.auto,
      color: Colors.blueGrey[800]!,
      emptyColor: Colors.white,
    );
    final qrSizeObj = Size(qrSize, qrSize);

    qrPainter.paint(canvas, qrSizeObj);


    // Information section
    final infoText = TextPainter(
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'STUDENT INFORMATION\n',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey),
          ),
          TextSpan(
            text: 'ID: ${studentId.isEmpty ? '__________' : studentId}\n',
            style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
          ),
          TextSpan(
            text: 'Phone: ${phone.isEmpty ? '__________' : phone}\n',
            style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
          ),
          TextSpan(
            text: 'Questions: $questionCount',
            style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    infoText.layout(maxWidth: size.width - qrSize - 60);
    infoText.paint(canvas, Offset(qrSize + 45, 100));

    // Divider
    final divider = Paint()
      ..color = Colors.blueGrey[300]!
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(20, qrSize + 120),
        Offset(size.width - 20, qrSize + 120),
        divider
    );

    double startY = qrSize + 130;

    // Student ID and Phone bubbles - UPDATED: No fill color
    startY = _drawDigitSection(canvas, size, "STUDENT ID", studentId, startY);
    startY = _drawDigitSection(canvas, size, "PHONE NUMBER", phone, startY + 30);

    // MCQ questions - UPDATED: No fill color
    _drawTwoColumnQuestions(canvas, size, startY + 40);
  }

  double _drawDigitSection(
      Canvas canvas, Size size, String label, String value, double startY) {
    // Label
    final labelText = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.blueGrey,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelText.layout();
    labelText.paint(canvas, Offset(20, startY - 5));

    const instructionText = "Write digits above, fill bubbles below";
    final instruction = TextPainter(
      text: const TextSpan(
        text: instructionText,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 10,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    instruction.layout();
    instruction.paint(canvas, Offset(size.width - instruction.width - 20, startY - 5));

    // Writing area (above bubbles)
    final linePaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    final radius = 11.0;
    final gap = (size.width - 60) / 10;

    for (int i = 0; i < 9; i++) {
      final cx = 40 + i * gap;
      final writingY = startY + 15;

      // Writing line
      canvas.drawLine(
          Offset(cx - 8, writingY),
          Offset(cx + 8, writingY),
          linePaint
      );
    }

    // Bubbles (UPDATED: No fill color)
    for (int i = 0; i < 9; i++) {
      final cx = 40 + i * gap;
      final cy = startY + 35;

      // Only stroke, no fill
      canvas.drawCircle(
          Offset(cx, cy),
          radius,
          Paint()
            ..color = Colors.blueGrey[800]!
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke);

      // Bubble number
      final number = TextPainter(
        text: TextSpan(
            text: '${i + 1}',
            style: const TextStyle(
                fontSize: 9,
                color: Colors.blueGrey,
                fontWeight: FontWeight.w500)),
        textDirection: TextDirection.ltr,
      );
      number.layout();
      number.paint(canvas, Offset(cx - 3, cy - 5));
    }

    return startY + 50;
  }

  void _drawTwoColumnQuestions(Canvas canvas, Size size, double startY) {
    final columnWidth = (size.width - 40) / 1.8;
    const bubbleRadius = 8.0;
    const gapY = 30.0;
    final options = ['A', 'B', 'C', 'D'];

    // Section title
    final sectionTitle = TextPainter(
      text: const TextSpan(
        text: 'MULTIPLE CHOICE QUESTIONS',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.blueGrey,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    sectionTitle.layout();
    sectionTitle.paint(canvas, Offset(05, startY - 25));

    for (int i = 0; i < questionCount; i++) {
      final col = i % 2;
      final row = i ~/ 2;

      final baseX = 5 + col * columnWidth;
      final baseY = startY + row * gapY;

      // Question number
      final qNum = TextPainter(
        text: TextSpan(
          text: '${i + 1}.',
          style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      qNum.layout();
      qNum.paint(canvas, Offset(baseX, baseY + 5));

      // Draw options with letters below bubbles (UPDATED: No fill color)
      for (int j = 0; j < options.length; j++) {
        final cx = baseX + 30 + j * (bubbleRadius * 4 + 8);
        final cy = baseY + 11;

        // Bubble - Only stroke, no fill
        final borderPaint = Paint()
          ..color = Colors.blueGrey[800]!
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(Offset(cx, cy), bubbleRadius, borderPaint);

        // Option letter below bubble
        final letter = TextPainter(
          text: TextSpan(
              text: options[j],
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey)),
          textDirection: TextDirection.ltr,
        );
        letter.layout();
        letter.paint(canvas, Offset(cx - 4, cy + bubbleRadius + 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}





// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:gal/gal.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:flutter/rendering.dart';
// import 'package:qr_flutter/qr_flutter.dart';
//
// class TagGeneratorPage extends StatefulWidget {
//   const TagGeneratorPage({Key? key}) : super(key: key);
//
//   @override
//   _TagGeneratorPageState createState() => _TagGeneratorPageState();
// }
//
// class _TagGeneratorPageState extends State<TagGeneratorPage> {
//   final _studentController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _examController = TextEditingController();
//   final _subjectController = TextEditingController();
//   final _qCountController = TextEditingController(text: '50');
//   final GlobalKey _previewKey = GlobalKey();
//
//   int questionCount = 50;
//   String _selectedExamType = 'MCQ';
//   String _selectedBoard = 'Dhaka';
//
//   Future<void> _savePreviewAsImage() async {
//     try {
//       RenderRepaintBoundary boundary =
//       _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
//       ui.Image image = await boundary.toImage(pixelRatio: 3.0);
//       ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//       Uint8List pngBytes = byteData!.buffer.asUint8List();
//
//       final dir = await getTemporaryDirectory();
//       final file = File(
//           '${dir.path}/omr_${DateTime.now().millisecondsSinceEpoch}.png');
//       await file.writeAsBytes(pngBytes);
//       await Gal.putImage(file.path);
//       await Share.shareXFiles([XFile(file.path)],
//           text: 'OMR Answer Sheet - ${_examController.text}');
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('OMR Sheet saved and shared successfully!')));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')));
//     }
//   }
//
//   void _generateNewTag() {
//     setState(() {
//       questionCount = int.tryParse(_qCountController.text) ?? 50;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       appBar: AppBar(
//         title: const Text('📝 OMR Answer Sheet Generator'),
//         backgroundColor: const Color(0xFF1A5276),
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.download),
//             onPressed: _savePreviewAsImage,
//             tooltip: "Download OMR Sheet",
//           )
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Input Section
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12)),
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     const Text(
//                       'Exam Information',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF1A5276),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: DropdownButtonFormField<String>(
//                             value: _selectedExamType,
//                             items: ['MCQ', 'Written', 'Practical', 'Viva']
//                                 .map((type) => DropdownMenuItem(
//                               value: type,
//                               child: Text(type),
//                             ))
//                                 .toList(),
//                             onChanged: (value) {
//                               setState(() {
//                                 _selectedExamType = value!;
//                               });
//                             },
//                             decoration: const InputDecoration(
//                               labelText: 'Exam Type',
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: DropdownButtonFormField<String>(
//                             value: _selectedBoard,
//                             items: ['Dhaka', 'Rajshahi', 'Chittagong', 'Comilla', 'Barishal', 'Sylhet', 'Dinajpur', 'Jessore', 'Mymensingh', 'Madrasah']
//                                 .map((board) => DropdownMenuItem(
//                               value: board,
//                               child: Text(board),
//                             ))
//                                 .toList(),
//                             onChanged: (value) {
//                               setState(() {
//                                 _selectedBoard = value!;
//                               });
//                             },
//                             decoration: const InputDecoration(
//                               labelText: 'Education Board',
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     TextField(
//                       controller: _examController,
//                       decoration: const InputDecoration(
//                         labelText: 'Exam Name (e.g., HSC Physics 1st Paper)',
//                         prefixIcon: Icon(Icons.school),
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     TextField(
//                       controller: _subjectController,
//                       decoration: const InputDecoration(
//                         labelText: 'Subject Code',
//                         prefixIcon: Icon(Icons.code),
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: _studentController,
//                             maxLength: 10,
//                             keyboardType: TextInputType.number,
//                             decoration: const InputDecoration(
//                               labelText: 'Student ID',
//                               prefixIcon: Icon(Icons.badge),
//                               border: OutlineInputBorder(),
//                               counterText: '',
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: TextField(
//                             controller: _phoneController,
//                             maxLength: 11,
//                             keyboardType: TextInputType.phone,
//                             decoration: const InputDecoration(
//                               labelText: 'Mobile Number',
//                               prefixIcon: Icon(Icons.phone_android),
//                               border: OutlineInputBorder(),
//                               counterText: '',
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     TextField(
//                       controller: _qCountController,
//                       keyboardType: TextInputType.number,
//                       decoration: const InputDecoration(
//                         labelText: 'Number of Questions',
//                         prefixIcon: Icon(Icons.format_list_numbered),
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton.icon(
//                       icon: const Icon(Icons.refresh),
//                       label: const Text("Generate OMR Sheet"),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF1A5276),
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10)),
//                       ),
//                       onPressed: _generateNewTag,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // Preview Section
//             const Text(
//               'OMR Sheet Preview',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1A5276),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: RepaintBoundary(
//                 key: _previewKey,
//                 child: LayoutBuilder(
//                   builder: (context, constraints) {
//                     final width = constraints.maxWidth;
//                     final height = width * 1.8;
//                     return Container(
//                       width: width,
//                       height: height,
//                       color: Colors.white,
//                       child: CustomPaint(
//                         size: Size(width, height),
//                         painter: _BangladeshOMRPainter(
//                           studentId: _studentController.text,
//                           phone: _phoneController.text,
//                           questionCount: questionCount,
//                           examName: _examController.text,
//                           subjectCode: _subjectController.text,
//                           examType: _selectedExamType,
//                           educationBoard: _selectedBoard,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Card(
//               color: Color(0xFFE8F4FD),
//               child: Padding(
//                 padding: EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       '📋 Instructions:',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(height: 8),
//                     Text('• Fill circles completely with black/blue ballpoint pen'),
//                     Text('• Do not make any stray marks on the sheet'),
//                     Text('• Ensure student ID and mobile number are bubbled correctly'),
//                     Text('• Each question has exactly one correct answer'),
//                     Text('• Use A4 size paper for printing with 300 DPI quality'),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _BangladeshOMRPainter extends CustomPainter {
//   final String studentId;
//   final String phone;
//   final int questionCount;
//   final String examName;
//   final String subjectCode;
//   final String examType;
//   final String educationBoard;
//
//   _BangladeshOMRPainter({
//     required this.studentId,
//     required this.phone,
//     required this.questionCount,
//     required this.examName,
//     required this.subjectCode,
//     required this.examType,
//     required this.educationBoard,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final bg = Paint()..color = Colors.white;
//     canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);
//
//     _drawHeader(canvas, size);
//     _drawStudentInfo(canvas, size);
//     _drawAnswerGrid(canvas, size);
//     _drawFooter(canvas, size);
//   }
//
//   void _drawHeader(Canvas canvas, Size size) {
//     // Header background
//     final headerPaint = Paint()..color = const Color(0xFF1A5276);
//     canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 80), headerPaint);
//
//     // Title
//     final title = TextPainter(
//       text: const TextSpan(
//         text: 'BANGLADESH EDUCATION BOARD',
//         style: TextStyle(
//           fontSize: 18,
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//           letterSpacing: 1,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     title.layout();
//     title.paint(canvas, Offset((size.width - title.width) / 2, 12));
//
//     // Subtitle
//     final subtitle = TextPainter(
//       text: const TextSpan(
//         text: 'OMR ANSWER SHEET',
//         style: TextStyle(
//           fontSize: 14,
//           color: Colors.white,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     subtitle.layout();
//     subtitle.paint(canvas, Offset((size.width - subtitle.width) / 2, 36));
//
//     // Exam info
//     final examInfo = TextPainter(
//       text: TextSpan(
//         text: '$examType Examination - $educationBoard Board',
//         style: const TextStyle(
//           fontSize: 12,
//           color: Colors.white,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     examInfo.layout();
//     examInfo.paint(canvas, Offset((size.width - examInfo.width) / 2, 56));
//   }
//
//   void _drawStudentInfo(Canvas canvas, Size size) {
//     double currentY = 100;
//
//     // Info boxes
//     final infoBox = Paint()
//       ..color = const Color(0xFFE8F4FD)
//       ..style = PaintingStyle.fill;
//     canvas.drawRect(Rect.fromLTWH(20, currentY, size.width - 40, 120), infoBox);
//     canvas.drawRect(Rect.fromLTWH(20, currentY, size.width - 40, 120),
//         Paint()..color = const Color(0xFF1A5276)..style = PaintingStyle.stroke..strokeWidth = 1);
//
//     // QR Code
//     final qrSize = 70.0;
//     final qrRect = Rect.fromLTWH(size.width - 100, currentY + 25, qrSize, qrSize);
//     final qrPainter = QrPainter(
//       data: "STUDENT:$studentId|PHONE:$phone|EXAM:$examName|SUB:$subjectCode",
//       version: QrVersions.auto,
//       color: const Color(0xFF1A5276),
//       emptyColor: Colors.white,
//     );
//     final qrOffset = Offset(size.width - 100, currentY + 25);
//     final qrSizeObj = Size(qrSize, qrSize);
//
//     qrPainter.paint(canvas, qrSizeObj);
//
//
//     // Student info text
//     final infoText = TextPainter(
//       text: TextSpan(
//         children: [
//           const TextSpan(
//             text: 'Student Information\n',
//             style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A5276)),
//           ),
//           TextSpan(
//             text: 'Exam: ${examName.isNotEmpty ? examName : "N/A"}\n',
//             style: const TextStyle(fontSize: 11, color: Colors.black87),
//           ),
//           TextSpan(
//             text: 'Subject Code: ${subjectCode.isNotEmpty ? subjectCode : "N/A"}\n',
//             style: const TextStyle(fontSize: 11, color: Colors.black87),
//           ),
//           TextSpan(
//             text: 'Student ID: $studentId\n',
//             style: const TextStyle(fontSize: 11, color: Colors.black87),
//           ),
//           TextSpan(
//             text: 'Mobile: $phone',
//             style: const TextStyle(fontSize: 11, color: Colors.black87),
//           ),
//         ],
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     infoText.layout(maxWidth: size.width - 140);
//     infoText.paint(canvas, Offset(30, currentY + 20));
//
//     currentY += 140;
//
//     // ID Bubbling Section
//     _drawBubbleSection(canvas, size, "STUDENT ID", studentId, currentY);
//     currentY += 50;
//     _drawBubbleSection(canvas, size, "MOBILE NUMBER", phone, currentY);
//   }
//
//   void _drawBubbleSection(Canvas canvas, Size size, String label, String value, double yPos) {
//     // Label
//     final labelText = TextPainter(
//       text: TextSpan(
//         text: '$label:',
//         style: const TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.bold,
//           color: Colors.black87,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     labelText.layout();
//     labelText.paint(canvas, Offset(30, yPos));
//
//     // Bubbles for digits 0-9
//     final bubbleRadius = 8.0;
//     final horizontalSpacing = (size.width - 100) / 10;
//
//     for (int digit = 0; digit < 10; digit++) {
//       final xPos = 40 + digit * horizontalSpacing;
//
//       // Digit label above bubble
//       final digitText = TextPainter(
//         text: TextSpan(
//           text: '$digit',
//           style: const TextStyle(fontSize: 10, color: Colors.black54),
//         ),
//         textDirection: TextDirection.ltr,
//       );
//       digitText.layout();
//       digitText.paint(canvas, Offset(xPos - 3, yPos + 15));
//
//       // Bubble
//       canvas.drawCircle(
//         Offset(xPos, yPos + 35),
//         bubbleRadius,
//         Paint()
//           ..color = Colors.white
//           ..style = PaintingStyle.fill
//           ..strokeWidth = 1,
//       );
//       canvas.drawCircle(
//         Offset(xPos, yPos + 35),
//         bubbleRadius,
//         Paint()
//           ..color = Colors.black
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 1,
//       );
//
//       // Fill bubble if digit matches student ID or phone
//       if (value.length > digit) {
//         try {
//           if (int.parse(value[digit]) == digit) {
//             canvas.drawCircle(
//               Offset(xPos, yPos + 35),
//               bubbleRadius - 2,
//               Paint()..color = Colors.black..style = PaintingStyle.fill,
//             );
//           }
//         } catch (e) {
//           // Ignore parsing errors
//         }
//       }
//     }
//
//     // Write digits above bubbles
//     final writeText = TextPainter(
//       text: const TextSpan(
//         text: '(Write digits above)',
//         style: TextStyle(fontSize: 9, color: Colors.grey, fontStyle: FontStyle.italic),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     writeText.layout();
//     writeText.paint(canvas, Offset(30, yPos + 50));
//   }
//
//   void _drawAnswerGrid(Canvas canvas, Size size) {
//     double startY = 320;
//     final columnWidth = (size.width - 60) / 2;
//     final options = ['A', 'B', 'C', 'D'];
//
//     // Grid header
//     final gridHeader = TextPainter(
//       text: const TextSpan(
//         text: 'ANSWER GRID (Fill the circle completely for your answer)',
//         style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A5276)),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     gridHeader.layout();
//     gridHeader.paint(canvas, Offset((size.width - gridHeader.width) / 2, startY));
//
//     startY += 25;
//
//     // Draw questions in two columns
//     for (int i = 0; i < questionCount; i++) {
//       final col = i % 2;
//       final row = i ~/ 2;
//
//       final xPos = 30 + col * columnWidth;
//       final yPos = startY + row * 28;
//
//       // Question number
//       final qNum = TextPainter(
//         text: TextSpan(
//           text: '${i + 1}.',
//           style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87),
//         ),
//         textDirection: TextDirection.ltr,
//       );
//       qNum.layout();
//       qNum.paint(canvas, Offset(xPos, yPos));
//
//       // Options A, B, C, D
//       for (int j = 0; j < options.length; j++) {
//         final optionX = xPos + 25 + j * 22;
//
//         // Option letter
//         final optionText = TextPainter(
//           text: TextSpan(
//             text: options[j],
//             style: const TextStyle(fontSize: 9, color: Colors.black54),
//           ),
//           textDirection: TextDirection.ltr,
//         );
//         optionText.layout();
//         optionText.paint(canvas, Offset(optionX - 3, yPos - 1));
//
//         // Bubble
//         canvas.drawCircle(
//           Offset(optionX, yPos + 10),
//           6,
//           Paint()
//             ..color = Colors.white
//             ..style = PaintingStyle.fill,
//         );
//         canvas.drawCircle(
//           Offset(optionX, yPos + 10),
//           6,
//           Paint()
//             ..color = Colors.black
//             ..style = PaintingStyle.stroke
//             ..strokeWidth = 1,
//         );
//       }
//     }
//   }
//
//   void _drawFooter(Canvas canvas, Size size) {
//     final footerY = size.height - 40;
//
//     // Signature lines
//     final linePaint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 1;
//
//     canvas.drawLine(Offset(40, footerY), Offset(140, footerY), linePaint);
//     canvas.drawLine(Offset(size.width - 140, footerY), Offset(size.width - 40, footerY), linePaint);
//
//     // Signature labels
//     final leftSign = TextPainter(
//       text: const TextSpan(
//         text: 'Student Signature',
//         style: TextStyle(fontSize: 9, color: Colors.black54),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     leftSign.layout();
//     leftSign.paint(canvas, Offset(50, footerY + 5));
//
//     final rightSign = TextPainter(
//       text: const TextSpan(
//         text: 'Invigilator Signature',
//         style: TextStyle(fontSize: 9, color: Colors.black54),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     rightSign.layout();
//     rightSign.paint(canvas, Offset(size.width - 130, footerY + 5));
//
//     // Footer text
//     final footer = TextPainter(
//       text: const TextSpan(
//         text: 'Official OMR Sheet - Do not fold or damage this sheet',
//         style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     footer.layout();
//     footer.paint(canvas, Offset((size.width - footer.width) / 2, footerY + 20));
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
//



// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:gal/gal.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:flutter/rendering.dart';
// import 'package:qr_flutter/qr_flutter.dart';
//
// class TagGeneratorPage extends StatefulWidget {
//   const TagGeneratorPage({Key? key}) : super(key: key);
//
//   @override
//   _TagGeneratorPageState createState() => _TagGeneratorPageState();
// }
//
// class _TagGeneratorPageState extends State<TagGeneratorPage> {
//   final _studentController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _qCountController = TextEditingController(text: '20');
//   final GlobalKey _previewKey = GlobalKey();
//
//   int questionCount = 20;
//
//   Future<void> _savePreviewAsImage() async {
//     RenderRepaintBoundary boundary =
//     _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
//     ui.Image image = await boundary.toImage(pixelRatio: 3.0);
//     ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//     Uint8List pngBytes = byteData!.buffer.asUint8List();
//
//     final dir = await getTemporaryDirectory();
//     final file = File(
//         '${dir.path}/omr_tag_${DateTime.now().millisecondsSinceEpoch}.png');
//     await file.writeAsBytes(pngBytes);
//     await Gal.putImage(file.path);
//     await Share.shareXFiles([XFile(file.path)], text: 'OMR Tag');
//     ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Saved & shared successfully.')));
//   }
//
//   void _generateNewTag() {
//     setState(() {
//       questionCount = int.tryParse(_qCountController.text) ?? 20;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final studentId = _studentController.text;
//     final phone = _phoneController.text;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F6F8),
//       appBar: AppBar(
//         title: const Text('🎓 Elegant OMR Tag Generator'),
//         backgroundColor: Colors.teal,
//         elevation: 4,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.save_alt),
//             onPressed: _savePreviewAsImage,
//             tooltip: "Save & Share",
//           )
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Card(
//               elevation: 6,
//               shadowColor: Colors.teal.withOpacity(0.3),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16)),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     TextField(
//                       controller: _studentController,
//                       decoration: const InputDecoration(
//                         labelText: 'Student ID (9 digits)',
//                         prefixIcon: Icon(Icons.badge_outlined),
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     TextField(
//                       controller: _phoneController,
//                       keyboardType: TextInputType.phone,
//                       decoration: const InputDecoration(
//                         labelText: 'Phone (9 digits)',
//                         prefixIcon: Icon(Icons.phone),
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     TextField(
//                       controller: _qCountController,
//                       keyboardType: TextInputType.number,
//                       decoration: const InputDecoration(
//                         labelText: 'Number of Questions (A–D)',
//                         prefixIcon: Icon(Icons.format_list_numbered),
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton.icon(
//                       icon: const Icon(Icons.refresh),
//                       label: const Text("Generate New Tag"),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.teal,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12)),
//                       ),
//                       onPressed: _generateNewTag,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             RepaintBoundary(
//               key: _previewKey,
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   final width = constraints.maxWidth;
//                   final height = width * 2.0; // Enough height for many questions
//                   return Container(
//                     width: width,
//                     height: height,
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                               color: Colors.grey.shade300,
//                               blurRadius: 10,
//                               offset: const Offset(0, 5))
//                         ]),
//                     child: CustomPaint(
//                       size: Size(width, height),
//                       painter: _ResponsiveOMRPainter(
//                         studentId: studentId,
//                         phone: phone,
//                         questionCount: questionCount,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               '💡 Tip: Scroll to see all questions. Print at high quality (A4 Portrait). Ensure QR, bubbles, and ID fields are clear.',
//               style: TextStyle(fontSize: 13, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _ResponsiveOMRPainter extends CustomPainter {
//   final String studentId;
//   final String phone;
//   final int questionCount;
//
//   _ResponsiveOMRPainter({
//     required this.studentId,
//     required this.phone,
//     required this.questionCount,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final bg = Paint()..color = Colors.white;
//     canvas.drawRect(Rect.fromLTWH(0,0, size.width, size.height), bg);
//
//     // Header
//     final headerPaint = Paint()..color = Colors.teal;
//     canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 70), headerPaint);
//
//     final title = TextPainter(
//       text:  TextSpan(
//         text: 'OMR ANSWER TAG',
//         style: TextStyle(
//             fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     title.layout();
//     title.paint(canvas, Offset((size.width - title.width) / 1.5, 20));
//
//     // QR
//     final qrSize = size.width * 0.20;
//     final qrRect = Rect.fromLTWH(20, 90, qrSize, qrSize);
//     final qrPainter = QrPainter(
//       data: "$studentId|$phone",
//       version: QrVersions.auto,
//       color: Colors.black,
//       emptyColor: Colors.white,
//     );
//     qrPainter.paint(canvas, qrRect.size);
//
//     // Info
//     // final infoText = TextPainter(
//     //   text: TextSpan(
//     //     text:
//     //     'Student ID: $studentId\nPhone: $phone\nQuestions: $questionCount',
//     //     style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.2),
//     //   ),
//     //   textDirection: TextDirection.ltr,
//     // );
//     // infoText.layout(maxWidth: size.width - qrSize - 60);
//     // infoText.paint(canvas, Offset(qrSize + 40, 120));
//
//     // Divider
//     final divider = Paint()
//       ..color = Colors.teal
//       ..strokeWidth = 2;
//     canvas.drawLine(Offset(20, qrSize + 140),
//         Offset(size.width - 20, qrSize + 140), divider);
//
//     double startY = qrSize + 30;
//
//     // Student ID and Phone bubbles
//     startY = _drawDigitSection(canvas, size, "STUDENT ID", studentId, startY);
//     startY = _drawDigitSection(canvas, size, "PHONE NUMBER", phone, startY + 20);
//
//     // MCQ questions
//     _drawTwoColumnQuestions(canvas, size, startY + 30);
//   }
//
//   double _drawDigitSection(
//       Canvas canvas, Size size, String label, String value, double startY) {
//     final labelText = TextPainter(
//       text: TextSpan(
//         text: '$label (Write above, fill below)',
//         style: const TextStyle(
//           color: Colors.teal,
//           fontWeight: FontWeight.bold,
//           fontSize: 14,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     labelText.layout();
//     labelText.paint(canvas, Offset(20, startY - 20));
//
//     final radius = 12.0;
//     final gap = (size.width - 60) / 10;
//     for (int i = 0; i < 9; i++) {
//       final cx = 40 + i * gap;
//       final cy = startY + 18;
//
//       canvas.drawCircle(
//           Offset(cx, cy),
//           radius,
//           Paint()
//             ..color = Colors.white
//             ..style = PaintingStyle.fill);
//       canvas.drawCircle(
//           Offset(cx, cy),
//           radius,
//           Paint()
//             ..color = Colors.teal
//             ..strokeWidth = 2
//             ..style = PaintingStyle.stroke);
//
//       if (value.length == 9) {
//         final digit = TextPainter(
//           text: TextSpan(
//               text: value[i],
//               style: const TextStyle(
//                   fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold)),
//           textDirection: TextDirection.ltr,
//         );
//         digit.layout();
//         digit.paint(canvas, Offset(cx - 5, cy - 8));
//       }
//     }
//     return startY + 40;
//   }
//
//   void _drawTwoColumnQuestions(Canvas canvas, Size size, double startY) {
//     final columnWidth = (size.width - 70) / 1.8;
//     final bubbleRadius = 10.0;
//     final gapY = 30.0;
//     final options = ['A', 'B', 'C', 'D'];
//
//     final qStyle = const TextStyle(fontSize: 12, color: Colors.black);
//
//     for (int i = 0; i < questionCount; i++) {
//       final col = i % 2;
//       final row = i ~/ 2;
//
//       final baseX = 10 + col * (columnWidth + 40);
//       final baseY = startY + row * gapY;
//
//       // Question number
//       final qNum = TextPainter(
//         text: TextSpan(text: '${i + 1}', style: qStyle),
//         textDirection: TextDirection.ltr,
//       );
//       qNum.layout();
//       qNum.paint(canvas, Offset(baseX-10, baseY - 1));
//
//       // Draw options with letters inside
//       for (int j = 0; j < options.length; j++) {
//         final cx = baseX + 20 + j * (bubbleRadius * 2.4 + 12);
//         final cy = baseY + 8;
//
//         final fillPaint = Paint()
//           ..color = Colors.tealAccent.shade100
//           ..style = PaintingStyle.fill;
//         final borderPaint = Paint()
//           ..color = Colors.teal
//           ..strokeWidth = 1.5
//           ..style = PaintingStyle.stroke;
//
//         canvas.drawCircle(Offset(cx, cy), bubbleRadius, fillPaint);
//         canvas.drawCircle(Offset(cx, cy), bubbleRadius, borderPaint);
//
//         final letter = TextPainter(
//           text: TextSpan(
//               text: options[j],
//               style: const TextStyle(
//                   fontSize: 10,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black)),
//           textDirection: TextDirection.ltr,
//         );
//         letter.layout();
//         letter.paint(canvas, Offset(cx - 4, cy - 6));
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }