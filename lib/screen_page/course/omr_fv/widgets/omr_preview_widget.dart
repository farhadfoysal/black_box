import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../utils/omr_generator_fv.dart';

class OMRPreviewWidget extends StatelessWidget {
  final OMRExamConfig config;

  const OMRPreviewWidget({Key? key, required this.config}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('OMR Preview'),
          backgroundColor: Color(0xFF2C3E50),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(Icons.download),
              onPressed: () async {
                try {
                  final file = await ProfessionalOMRGenerator.generateOMRSheet(config);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('OMR Sheet saved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: Center(
            child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                    BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                    ),
                  ],
                ),
              child: AspectRatio(
                aspectRatio: 595 / 842, // A4 aspect ratio
                child: CustomPaint(
                  painter: OMRPreviewPainter(config),
                ),
              ),
            ),
        ),
    ),
    );
  }
}

class OMRPreviewPainter extends CustomPainter {
  final OMRExamConfig config;

  OMRPreviewPainter(this.config);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / ProfessionalOMRGenerator.A4_WIDTH;
    canvas.scale(scale);

    // Draw white background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, ProfessionalOMRGenerator.A4_WIDTH, ProfessionalOMRGenerator.A4_HEIGHT),
      bgPaint,
    );

    // Draw main border
    final borderPaint = Paint()
      ..color = ProfessionalOMRGenerator.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          ProfessionalOMRGenerator.MARGIN,
          ProfessionalOMRGenerator.MARGIN,
          ProfessionalOMRGenerator.A4_WIDTH - 2 * ProfessionalOMRGenerator.MARGIN,
          ProfessionalOMRGenerator.A4_HEIGHT - 2 * ProfessionalOMRGenerator.MARGIN,
        ),
        Radius.circular(8),
      ),
      borderPaint,
    );

    // Draw preview text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'OMR PREVIEW',
        style: TextStyle(
          fontSize: 48,
          color: Colors.grey.withOpacity(0.3),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (ProfessionalOMRGenerator.A4_WIDTH - textPainter.width) / 2,
        (ProfessionalOMRGenerator.A4_HEIGHT - textPainter.height) / 2,
      ),
    );

    // Draw basic info
    _drawText(
      canvas,
      config.examName,
      ProfessionalOMRGenerator.A4_WIDTH / 2,
      100,
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );

    _drawText(
      canvas,
      'Questions: ${config.numberOfQuestions} | Set: ${config.setNumber}',
      ProfessionalOMRGenerator.A4_WIDTH / 2,
      130,
      TextStyle(fontSize: 14),
    );

    _drawText(
      canvas,
      'Date: ${config.examDate.day}/${config.examDate.month}/${config.examDate.year}',
      ProfessionalOMRGenerator.A4_WIDTH / 2,
      150,
      TextStyle(fontSize: 14),
    );
  }

  void _drawText(Canvas canvas, String text, double x, double y, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}