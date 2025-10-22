import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

class BlankOMRConfig {
  final String examName;
  final String subjectName;
  final int numberOfQuestions;
  final int setNumber;
  final DateTime examDate;
  final String? instructions;

  BlankOMRConfig({
    required this.examName,
    required this.subjectName,
    required this.numberOfQuestions,
    required this.setNumber,
    required this.examDate,
    this.instructions,
  });
}

class BlankOMRGenerator {
  static const double A4_WIDTH = 595.0;
  static const double A4_HEIGHT = 842.0;
  static const double MARGIN = 20.0;
  static const double BUBBLE_RADIUS = 7;

  // Professional color scheme
  static final Color primaryColor = const Color(0xFF2C3E50);
  static final Color secondaryColor = const Color(0xFF34495E);
  static final Color accentColor = const Color(0xFFE74C3C);
  static final Color lightBgColor = const Color(0xFFF8F9FA);
  static final Color borderColor = const Color(0xFF2C3E50);
  static final Color textColor = const Color(0xFF2C3E50);

  static Future<File> generateBlankOMRSheet(BlankOMRConfig config) async {
    try {
      final Uint8List imageBytes = await _generateOMRImage(config);
      final file = await _saveOMRSheetWithGal(imageBytes, config);
      print('✅ Blank OMR Sheet generated successfully.');
      return file;
    } catch (e) {
      print('❌ Error generating blank OMR sheet: $e');
      rethrow;
    }
  }

  static Future<Uint8List> _generateOMRImage(BlankOMRConfig config) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT),
      paint..color = Colors.white,
    );

    // Main border
    _drawRoundedRect(
      canvas,
      Rect.fromLTWH(MARGIN, MARGIN, A4_WIDTH - 2 * MARGIN, A4_HEIGHT - 2 * MARGIN),
      8.0,
      borderColor,
      false,
    );

    // Draw sections
    _drawHeaderSection(canvas, config);
    _drawStudentInfoSection(canvas, config);
    _drawAnswerGridSection(canvas, config);
    _drawFooterSection(canvas);

    final picture = recorder.endRecording();
    final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _drawHeaderSection(Canvas canvas, BlankOMRConfig config) {
    final centerX = A4_WIDTH / 2;

    // Institution/Exam name
    _drawText(
      canvas,
      config.examName.toUpperCase(),
      centerX,
      MARGIN + 20,
      TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: 1.2,
      ),
      TextAlign.center,
    );

    // Subject name
    _drawText(
      canvas,
      config.subjectName,
      centerX,
      MARGIN + 40,
      TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
      ),
      TextAlign.center,
    );

    // Exam type subtitle
    _drawText(
      canvas,
      "MULTIPLE CHOICE ANSWER SHEET",
      centerX,
      MARGIN + 58,
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        letterSpacing: 1.0,
      ),
      TextAlign.center,
    );

    // Set number and date
    _drawText(
      canvas,
      "SET ${config.setNumber} | Date: ${_formatDate(config.examDate)}",
      centerX,
      MARGIN + 75,
      TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      TextAlign.center,
    );

    // Decorative line
    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX - 120, MARGIN + 85),
      Offset(centerX + 120, MARGIN + 85),
      linePaint,
    );
  }

  static void _drawStudentInfoSection(Canvas canvas, BlankOMRConfig config) {
    final startY = MARGIN + 95;
    final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;

    // Section background
    final bgPaint = Paint()..color = lightBgColor;
    canvas.drawRect(
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 80),
      bgPaint,
    );

    // Section border
    _drawRoundedRect(
      canvas,
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 80),
      4.0,
      borderColor,
      false,
    );

    // Title background
    final titleBgPaint = Paint()..color = primaryColor;
    canvas.drawRect(
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 20),
      titleBgPaint,
    );

    // Section title
    _drawText(
      canvas,
      "STUDENT INFORMATION (To be filled by student)",
      MARGIN + 20,
      startY + 10,
      TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: lightBgColor,
      ),
      TextAlign.left,
    );

    // Student fields
    _drawBlankField(canvas, MARGIN + 20, startY + 35, "Name:", 200);
    _drawBlankField(canvas, MARGIN + 240, startY + 35, "Roll No:", 100);
    _drawBlankField(canvas, MARGIN + 360, startY + 35, "Section:", 80);

    _drawBlankField(canvas, MARGIN + 20, startY + 55, "Student ID:", 150);
    _drawBlankField(canvas, MARGIN + 190, startY + 55, "Mobile No:", 150);
    _drawBlankField(canvas, MARGIN + 360, startY + 55, "Class:", 80);
  }

  static void _drawAnswerGridSection(Canvas canvas, BlankOMRConfig config) {
    final startY = MARGIN + 185;
    final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;
    final sectionHeight = 480;

    // Section background
    final bgPaint = Paint()..color = lightBgColor;
    canvas.drawRect(
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, sectionHeight.toDouble()),
      bgPaint,
    );

    // Section border
    _drawRoundedRect(
      canvas,
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, sectionHeight.toDouble()),
      4.0,
      borderColor,
      false,
    );

    // Title background
    final titleBgPaint = Paint()..color = primaryColor;
    canvas.drawRect(
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 25),
      titleBgPaint,
    );

    // Section title
    _drawText(
      canvas,
      "ANSWER GRID - MARK YOUR ANSWERS CLEARLY",
      A4_WIDTH / 2,
      startY + 12.5,
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: lightBgColor,
      ),
      TextAlign.center,
    );

    // Instructions
    if (config.instructions != null && config.instructions!.isNotEmpty) {
      _drawText(
        canvas,
        config.instructions!,
        A4_WIDTH / 2,
        startY + 35,
        TextStyle(
          fontSize: 9,
          color: accentColor,
          fontStyle: FontStyle.italic,
        ),
        TextAlign.center,
      );
    }

    // Draw answer grid
    _drawAnswerGrid(canvas, startY + 50, config.numberOfQuestions);
  }

  static void _drawAnswerGrid(Canvas canvas, double startY, int totalQuestions) {
    final questionsPerColumn = (totalQuestions / 3).ceil();
    final columnWidth = (A4_WIDTH - 2 * MARGIN - 40) / 3;

    // Column headers
    final options = ["A", "B", "C", "D"];

    for (int col = 0; col < 3; col++) {
      final colX = MARGIN + 20 + (col * columnWidth);

      // Questions and bubbles
      for (int i = 0; i < questionsPerColumn; i++) {
        final questionNum = col * questionsPerColumn + i + 1;
        if (questionNum > totalQuestions) break;

        final y = startY + (i * 25);

        // Alternate row background
        if (i % 2 == 0) {
          final rowBgPaint = Paint()..color = Colors.grey.withOpacity(0.05);
          canvas.drawRect(
            Rect.fromLTWH(colX - 5, y - 5, columnWidth - 10, 22),
            rowBgPaint,
          );
        }

        // Question number
        _drawText(
          canvas,
          questionNum.toString().padLeft(2, '0'),
          colX + 15,
          y + 8,
          TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          TextAlign.center,
        );

        // Answer bubbles
        for (int opt = 0; opt < 4; opt++) {
          final x = colX + 40 + (opt * 30);
          _drawBubbleWithOption(canvas, x, y, options[opt]);
        }
      }
    }

    // Bottom instructions
    _drawText(
      canvas,
      "INSTRUCTIONS: Use HB pencil only • Fill the bubble completely • Erase cleanly to change answer",
      A4_WIDTH / 2,
      startY + 410,
      TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        color: accentColor,
      ),
      TextAlign.center,
    );
  }

  static void _drawFooterSection(Canvas canvas) {
    final startY = A4_HEIGHT - MARGIN - 100;
    final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;

    // Section border
    _drawRoundedRect(
      canvas,
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 90),
      4.0,
      borderColor,
      false,
    );

    // Important note section
    final noteBgPaint = Paint()..color = accentColor.withOpacity(0.1);
    canvas.drawRect(
      Rect.fromLTWH(MARGIN + 20, startY + 10, sectionWidth - 20, 30),
      noteBgPaint,
    );

    _drawText(
      canvas,
      "IMPORTANT: Do not fold or damage this sheet • Ensure all marks are within the bubbles",
      A4_WIDTH / 2,
      startY + 25,
      TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: accentColor,
      ),
      TextAlign.center,
    );

    // Signature fields
    final signatures = [
      "Student's Signature",
      "Invigilator's Signature",
    ];

    final fieldWidth = (sectionWidth - 40) / 2;
    for (int i = 0; i < signatures.length; i++) {
      final x = MARGIN + 20 + (i * fieldWidth);

      _drawText(
        canvas,
        signatures[i],
        x + fieldWidth / 2,
        startY + 55,
        TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        TextAlign.center,
      );

      // Signature line
      final linePaint = Paint()
        ..color = borderColor
        ..strokeWidth = 0.8;

      canvas.drawLine(
        Offset(x + 20, startY + 75),
        Offset(x + fieldWidth - 20, startY + 75),
        linePaint,
      );
    }
  }

  // Helper Methods
  static void _drawText(Canvas canvas, String text, double x, double y, TextStyle style, TextAlign align) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    double offsetX = x;
    if (align == TextAlign.center) {
      offsetX -= textPainter.width / 2;
    } else if (align == TextAlign.right) {
      offsetX -= textPainter.width;
    }

    textPainter.paint(canvas, Offset(offsetX, y - textPainter.height / 2));
  }

  static void _drawRoundedRect(Canvas canvas, Rect rect, double radius, Color color, bool fill) {
    final paint = Paint()
      ..color = color
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, paint);
  }

  static void _drawBubbleWithOption(Canvas canvas, double x, double y, String option) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw bubble
    canvas.drawCircle(Offset(x + BUBBLE_RADIUS, y + BUBBLE_RADIUS), BUBBLE_RADIUS, borderPaint);

    // Draw option letter inside
    _drawText(
      canvas,
      option,
      x + BUBBLE_RADIUS,
      y + BUBBLE_RADIUS,
      TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      TextAlign.center,
    );
  }

  static void _drawBlankField(Canvas canvas, double x, double y, String label, double width) {
    _drawText(
      canvas,
      label,
      x,
      y,
      TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      TextAlign.left,
    );

    // Underline for value
    final linePaint = Paint()
      ..color = borderColor
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(x + 5, y + 12),
      Offset(x + width, y + 12),
      linePaint,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static Future<File> _saveOMRSheetWithGal(Uint8List bytes, BlankOMRConfig config) async {
    await _requestGalleryPermissions();

    try {
      // Create temporary file for gal package
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/_temp_blank_omr_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(bytes);

      // Save to gallery using gal package
      await Gal.putImage(tempFile.path, album: 'OMR Sheets');

      // Save a permanent copy
      final permanentFile = await _saveToPublicPictures(bytes, config);

      // Cleanup temp file
      await tempFile.delete();

      print('✅ Saved to gallery & Pictures folder');
      return permanentFile;
    } catch (e) {
      print('⚠️ Gal save failed: $e');
      // fallback: save manually
      return await _saveToPublicPictures(bytes, config);
    }
  }

  static Future<File> _saveToPublicPictures(Uint8List bytes, BlankOMRConfig config) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'Blank_OMR_${_sanitizeFileName(config.examName)}_Set${config.setNumber}_$timestamp.png';

    Directory? publicDir;
    if (Platform.isAndroid) {
      publicDir = Directory('/storage/emulated/0/Pictures/OMR_Sheets');
    } else {
      publicDir = await getApplicationDocumentsDirectory();
    }

    await publicDir.create(recursive: true);
    final file = File('${publicDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    return file;
  }

  static Future<void> _requestGalleryPermissions() async {
    if (Platform.isAndroid) {
      final storageStatus = await Permission.manageExternalStorage.status;
      if (!storageStatus.isGranted) {
        await Permission.manageExternalStorage.request();
      }
      final photosStatus = await Permission.photos.status;
      if (!photosStatus.isGranted) {
        await Permission.photos.request();
      }
    } else if (Platform.isIOS) {
      final photosStatus = await Permission.photos.status;
      if (!photosStatus.isGranted) {
        await Permission.photos.request();
      }
    }
  }

  static String _sanitizeFileName(String name) {
    final sanitized = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').replaceAll(RegExp(r'\s+'), '_');
    return sanitized.length > 50 ? sanitized.substring(0, 50) : sanitized;
  }

  // Print functionality
  static Future<void> printBlankOMRSheet(Uint8List imageBytes) async {
    try {
      await Printing.layoutPdf(onLayout: (format) async => imageBytes);
    } catch (e) {
      print('❌ Error printing OMR sheet: $e');
    }
  }
}