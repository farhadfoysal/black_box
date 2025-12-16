import 'package:flutter/material.dart';
import 'omr_detector.dart';

class OMROverlayPainter extends CustomPainter {
  final List<OMRResult> detectionResults;

  OMROverlayPainter({
    required this.detectionResults,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw guide frame
    _drawGuideFrame(canvas, size);

    // Draw detected bubbles
    for (var result in detectionResults) {
      _drawBubble(canvas, size, result);
    }
  }

  void _drawGuideFrame(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final frameRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.9,
        height: size.height * 0.85,
      ),
      const Radius.circular(12),
    );

    canvas.drawRRect(frameRect, paint);

    // Draw corner guides
    _drawCornerGuides(canvas, frameRect);
  }

  void _drawCornerGuides(Canvas canvas, RRect frameRect) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const cornerLength = 30.0;

    // Top-left
    canvas.drawLine(
      Offset(frameRect.left, frameRect.top),
      Offset(frameRect.left + cornerLength, frameRect.top),
      paint,
    );
    canvas.drawLine(
      Offset(frameRect.left, frameRect.top),
      Offset(frameRect.left, frameRect.top + cornerLength),
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(frameRect.right, frameRect.top),
      Offset(frameRect.right - cornerLength, frameRect.top),
      paint,
    );
    canvas.drawLine(
      Offset(frameRect.right, frameRect.top),
      Offset(frameRect.right, frameRect.top + cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(frameRect.left, frameRect.bottom),
      Offset(frameRect.left + cornerLength, frameRect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(frameRect.left, frameRect.bottom),
      Offset(frameRect.left, frameRect.bottom - cornerLength),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(frameRect.right, frameRect.bottom),
      Offset(frameRect.right - cornerLength, frameRect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(frameRect.right, frameRect.bottom),
      Offset(frameRect.right, frameRect.bottom - cornerLength),
      paint,
    );
  }

  void _drawBubble(Canvas canvas, Size size, OMRResult result) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Set color based on whether bubble is filled
    if (result.isFilled) {
      paint.color = Colors.greenAccent;
      paint.style = PaintingStyle.fill;
    } else {
      paint.color = Colors.blue.withOpacity(0.5);
    }

    // Draw circle for bubble
    canvas.drawCircle(
      Offset(result.x, result.y),
      result.width / 2,
      paint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = result.isFilled ? Colors.green : Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      Offset(result.x, result.y),
      result.width / 2,
      borderPaint,
    );

    // Draw label for filled bubbles
    if (result.isFilled) {
      _drawLabel(canvas, result);
    }
  }

  void _drawLabel(Canvas canvas, OMRResult result) {
    final textSpan = TextSpan(
      text: '${result.questionNumber}: ${result.option}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black,
            offset: Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final offset = Offset(
      result.x - textPainter.width / 2,
      result.y - result.height / 2 - 20,
    );

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(OMROverlayPainter oldDelegate) {
    return oldDelegate.detectionResults != detectionResults;
  }
}