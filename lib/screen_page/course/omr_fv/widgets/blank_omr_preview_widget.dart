import 'package:flutter/material.dart';
import '../utils/blank_omr_generator.dart';

class BlankOMRPreviewWidget extends StatelessWidget {
  final BlankOMRConfig config;

  const BlankOMRPreviewWidget({Key? key, required this.config}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blank OMR Preview'),
        backgroundColor: Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () async {
              try {
                await BlankOMRGenerator.generateBlankOMRSheet(config);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Blank OMR Sheet saved to gallery'),
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
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () async {
              try {
                final file = await BlankOMRGenerator.generateBlankOMRSheet(config);
                final bytes = await file.readAsBytes();
                await BlankOMRGenerator.printBlankOMRSheet(bytes);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error printing: ${e.toString()}'),
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
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 595 / 842, // A4 aspect ratio
              child: CustomPaint(
                painter: BlankOMRPreviewPainter(config),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BlankOMRPreviewPainter extends CustomPainter {
  final BlankOMRConfig config;

  BlankOMRPreviewPainter(this.config);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / BlankOMRGenerator.A4_WIDTH;
    canvas.scale(scale);

    // Draw white background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, BlankOMRGenerator.A4_WIDTH, BlankOMRGenerator.A4_HEIGHT),
      bgPaint,
    );

    // Draw main border
    final borderPaint = Paint()
      ..color = BlankOMRGenerator.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          BlankOMRGenerator.MARGIN,
          BlankOMRGenerator.MARGIN,
          BlankOMRGenerator.A4_WIDTH - 2 * BlankOMRGenerator.MARGIN,
          BlankOMRGenerator.A4_HEIGHT - 2 * BlankOMRGenerator.MARGIN,
        ),
        Radius.circular(8),
      ),
      borderPaint,
    );

    // Draw preview text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'BLANK OMR PREVIEW',
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
        (BlankOMRGenerator.A4_WIDTH - textPainter.width) / 2,
        (BlankOMRGenerator.A4_HEIGHT - textPainter.height) / 2,
      ),
    );

    // Draw basic info
    _drawText(
      canvas,
      config.examName,
      BlankOMRGenerator.A4_WIDTH / 2,
      100,
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );

    _drawText(
      canvas,
      config.subjectName,
      BlankOMRGenerator.A4_WIDTH / 2,
      130,
      TextStyle(fontSize: 16),
    );

    _drawText(
      canvas,
      'Questions: ${config.numberOfQuestions} | Set: ${config.setNumber}',
      BlankOMRGenerator.A4_WIDTH / 2,
      160,
      TextStyle(fontSize: 14),
    );

    _drawText(
      canvas,
      'Date: ${_formatDate(config.examDate)}',
      BlankOMRGenerator.A4_WIDTH / 2,
      180,
      TextStyle(fontSize: 14),
    );

    if (config.instructions != null) {
      _drawText(
        canvas,
        'Instructions: ${config.instructions}',
        BlankOMRGenerator.A4_WIDTH / 2,
        210,
        TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      );
    }
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}