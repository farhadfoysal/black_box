import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum PageOrientation { portrait, landscape }

enum BubbleStyle { circle, square, diamond }

class OMRExamConfig {
  final String examName;
  final int numberOfQuestions;
  final int setNumber;
  final String studentId;
  final String mobileNumber;
  final DateTime examDate;
  final List<String> correctAnswers;
  final String studentName;
  final String className;

  OMRExamConfig({
    required this.examName,
    required this.numberOfQuestions,
    required this.setNumber,
    required this.studentId,
    required this.mobileNumber,
    required this.examDate,
    required this.correctAnswers,
    this.studentName = '',
    this.className = '',
  });
}

class ProfessionalOMRGenerator {
  static const double A4_WIDTH = 595.0; // 8.27 inches at 72 DPI
  static const double A4_HEIGHT = 842.0; // 11.69 inches at 72 DPI
  static const double MARGIN = 8.0;
  static const double BUBBLE_RADIUS = 6;
  static const double SMALL_BUBBLE_RADIUS = 5;

  // Professional color scheme
  static final Color primaryColor = const Color(0xFF2C3E50); // Dark blue-gray
  static final Color secondaryColor = const Color(
    0xFF34495E,
  ); // Slightly lighter
  static final Color accentColor = const Color(
    0xFFE74C3C,
  ); // Red for important elements
  static final Color lightBgColor = const Color(
    0xFFF8F9FA,
  ); // Light gray background
  static final Color borderColor = const Color(0xFF2C3E50);
  static final Color textColor = const Color(0xFF2C3E50);

  static Future<void> _drawQRCode(
    Canvas canvas,
    double x,
    double y,
    String data,
  ) async {
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
    );

    final size = 80.0;
    qrPainter.paint(canvas, Size(size, size));
  }

  static void _drawStyledBubble(
    Canvas canvas,
    double x,
    double y,
    bool filled,
    BubbleStyle style,
  ) {
    switch (style) {
      case BubbleStyle.circle:
        // existing circle code
        break;
      case BubbleStyle.square:
        // draw square bubble
        break;
      case BubbleStyle.diamond:
        // draw diamond bubble
        break;
    }
  }

  // static Future<Uint8List> _generateOMRImage(
  // OMRExamConfig config,
  // {PageOrientation orientation = PageOrientation.portrait}
  // ) async {
  // final width = orientation == PageOrientation.portrait ? A4_WIDTH : A4_HEIGHT;
  // final height = orientation == PageOrientation.portrait ? A4_HEIGHT : A4_WIDTH;
  // // ... adjust layout accordingly ...
  // }

  static Future<File> generateOMRSheet(OMRExamConfig config) async {
    try {
      // Generate OMR sheet bytes
      final Uint8List imageBytes = await _generateOMRImage(config);

      // Save to gallery and permanent directory
      final file = await _saveOMRSheetWithGal(imageBytes, config);

      print('✅ OMR Sheet generated successfully.');
      return file;
    } catch (e) {
      print('❌ Error generating OMR sheet: $e');
      rethrow;
    }
  }

  // ===========================================================
  // CANVAS IMAGE CREATION
  // ===========================================================
  static Future<Uint8List> _generateOMRImage(OMRExamConfig config) async {
    try {
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
        Rect.fromLTWH(
          MARGIN,
          MARGIN,
          A4_WIDTH - 2 * MARGIN,
          A4_HEIGHT - 2 * MARGIN,
        ),
        8.0,
        borderColor,
        false,
      );

      // Add bounds checking
      if (config.numberOfQuestions > 100) {
        throw ArgumentError('Too many questions for single page');
      }

      // Draw sections
      _drawHeaderSection(canvas, config);
      _drawStudentInfoSection(canvas, config);
      _drawSetSelectionSection(canvas, config);
      _drawIdNumberSection(canvas, config);
      _drawAnswerGridSection(canvas, config);
      _drawFooterSection(canvas);

      final picture = recorder.endRecording();
      final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      print('Error in canvas generation: $e');
      rethrow;
    }
  }

  // ===========================================================
  // SAVE TO GALLERY + PERMANENT STORAGE
  // ===========================================================
  static Future<File> _saveOMRSheetWithGal(
    Uint8List bytes,
    OMRExamConfig config,
  ) async {
    await _requestGalleryPermissions();

    try {
      // 1️⃣ Attempt to save using Gal (safest)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/_temp_omr_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(bytes);
      await Gal.putImage(tempFile.path, album: 'OMR Sheets');

      // 2️⃣ Save a permanent copy to Pictures/OMR_Sheets
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

  // ===========================================================
  // SAVE TO PUBLIC PICTURES DIRECTORY (VISIBLE IN GALLERY)
  // ===========================================================
  static Future<File> _saveToPublicPictures(
    Uint8List bytes,
    OMRExamConfig config,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName =
        'OMR_${_sanitizeFileName(config.examName)}_${config.studentName}_$timestamp.png';

    Directory? publicDir;
    if (Platform.isAndroid) {
      publicDir = Directory('/storage/emulated/0/Pictures/OMR_Sheets');
    } else {
      publicDir = await getApplicationDocumentsDirectory();
    }

    await publicDir.create(recursive: true);
    final file = File('${publicDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    // ✅ Trigger Android media scanner
    if (Platform.isAndroid) {
      try {
        await Process.run('am', [
          'broadcast',
          '-a',
          'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
          '-d',
          'file://${file.path}',
        ]);
      } catch (_) {
        // Ignore if unavailable
      }
    }

    return file;
  }

  // ===========================================================
  // PRINTING SUPPORT (PDF/Direct Print)
  // ===========================================================
  static Future<void> printOMRSheet(Uint8List imageBytes) async {
    try {
      await Printing.layoutPdf(onLayout: (format) async => imageBytes);
    } catch (e) {
      print('❌ Error printing OMR sheet: $e');
    }
  }

  // ===========================================================
  // PERMISSION HANDLER
  // ===========================================================
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

  // ===========================================================
  // HELPERS
  // ===========================================================
  static String _sanitizeFileName(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return sanitized.length > 50 ? sanitized.substring(0, 50) : sanitized;
  }

  static void _drawWatermark(Canvas canvas, String text) {
    final watermarkPaint = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 60,
          color: Colors.grey.withOpacity(0.1),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    watermarkPaint.layout();

    // Draw diagonally
    canvas.save();
    canvas.translate(A4_WIDTH / 2, A4_HEIGHT / 2);
    canvas.rotate(-0.5); // Rotate 45 degrees
    watermarkPaint.paint(
      canvas,
      Offset(-watermarkPaint.width / 2, -watermarkPaint.height / 2),
    );
    canvas.restore();
  }

  static Future<void> _drawTextWithCustomFont(
    Canvas canvas,
    String text,
    double x,
    double y,
    TextStyle style,
    String? fontFamily,
  ) async {
    final textStyle = style.copyWith(fontFamily: fontFamily);
    // ... existing text drawing code ...
  }

  static Stream<File> generateBatchOMRSheetsStream(
    List<OMRExamConfig> configs,
  ) async* {
    for (final config in configs) {
      try {
        final file = await generateOMRSheet(config);
        yield file;
      } catch (e) {
        print('Error generating OMR for ${config.studentName}: $e');
      }
    }
  }

  static void _drawHeaderSection(Canvas canvas, OMRExamConfig config) {
    final centerX = A4_WIDTH / 2;

    // Institution name - Main title
    _drawText(
      canvas,
      config.examName.toUpperCase(),
      centerX,
      MARGIN + 10,
      TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: 1.2,
      ),
      TextAlign.center,
    );

    // Exam type subtitle
    _drawText(
      canvas,
      "MULTIPLE CHOICE ANSWER SHEET",
      centerX,
      MARGIN + 25,
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        letterSpacing: 1.0,
      ),
      TextAlign.center,
    );

    // Decorative line
    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX - 100, MARGIN + 35),
      Offset(centerX + 100, MARGIN + 35),
      linePaint,
    );
  }

  static void _drawStudentInfoSection(Canvas canvas, OMRExamConfig config) {
    final startY = MARGIN + 40;
    final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;

    // Section background
    final bgPaint = Paint()..color = lightBgColor;
    canvas.drawRect(
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 60),
      bgPaint,
    );

    // Section border
    _drawRoundedRect(
      canvas,
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 60),
      4.0,
      borderColor,
      false,
    );

    // Fill the title background
    final titleBgPaint = Paint()..color = primaryColor;
    canvas.drawRect(
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 20),
      titleBgPaint,
    );

    // Section title
    _drawText(
      canvas,
      "STUDENT INFORMATION",
      MARGIN + 20,
      startY + 10,
      TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: lightBgColor),
      TextAlign.left,
    );

    // Student Name field
    _drawLabeledField(
      canvas,
      MARGIN + 20,
      startY + 30,
      "Student Name:",
      config.studentName,
      200,
    );

    // Class field
    _drawLabeledField(
      canvas,
      MARGIN + 250,
      startY + 30,
      "Class:",
      config.className,
      120,
    );

    // Date field
    final dateStr =
        "${config.examDate.day}/${config.examDate.month}/${config.examDate.year}";
    _drawLabeledField(canvas, MARGIN + 400, startY + 30, "Date:", dateStr, 120);
  }

  static void _drawSetSelectionSection(Canvas canvas, OMRExamConfig config) {
    final startY = MARGIN + 110;

    _drawText(
      canvas,
      "SET NUMBER:",
      MARGIN + 20,
      startY,
      TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
      TextAlign.left,
    );

    // Set number bubbles (1-4)
    final setNumbers = ["1", "2", "3", "4"];
    for (int i = 0; i < setNumbers.length; i++) {
      final x = MARGIN + 120 + (i * 80);
      _drawBubbleWithLabel(
        canvas,
        x,
        startY - 5,
        setNumbers[i],
        config.setNumber == i + 1,
      );
    }
  }

  static void _drawIdNumberSection(Canvas canvas, OMRExamConfig config) {
    final startY = MARGIN + 140;

    // ==== Titles ====
    _drawText(
      canvas,
      "STUDENT ID NUMBER:",
      MARGIN + 20,
      startY,
      TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
      TextAlign.left,
    );

    _drawText(
      canvas,
      "MOBILE NUMBER:",
      MARGIN + 300,
      startY,
      TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
      TextAlign.left,
    );

    // ==== Draw Student ID section (10 digits) ====
    _drawDigitEntrySection(
      canvas,
      offsetX: MARGIN + 20,
      offsetY: startY + 10,
      totalDigits: 10,
      userValue: config.studentId.padLeft(10, '0'),
      label: "Student ID",
    );

    // ==== Draw Mobile number section (11 digits) ====
    _drawDigitEntrySection(
      canvas,
      offsetX: MARGIN + 300,
      offsetY: startY + 10,
      totalDigits: 11,
      userValue: config.mobileNumber.padLeft(11, '0'),
      label: "Mobile Number",
    );
  }

  /// Draws a full digit entry section with boxes and bubbles
  static void _drawDigitEntrySection(
    Canvas canvas, {
    required double offsetX,
    required double offsetY,
    required int totalDigits,
    required String userValue,
    required String label,
  }) {
    const double digitBoxSize = 20.0;
    const double bubbleRadius = 6.0;
    const double bubbleSpacing = 18.0;
    const double columnSpacing = 25.0;
    const double leftIndexOffset = 15.0;

    final Paint boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.black;

    // === Draw header boxes for digits (for writing) ===
    for (int i = 0; i < totalDigits; i++) {
      final double x = offsetX + i * columnSpacing;
      final double y = offsetY;

      final Rect rect = Rect.fromLTWH(x, y, digitBoxSize, digitBoxSize);
      canvas.drawRect(rect, boxPaint);

      // Draw digit from userValue (if any)
      _drawText(
        canvas,
        userValue[i],
        x + digitBoxSize / 2,
        y + digitBoxSize / 2 - 2,
        TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
        TextAlign.center,
      );
    }

    // === Draw vertical bubbles (0–9) for each column ===
    for (int row = 0; row < 10; row++) {
      final double bubbleY = offsetY + digitBoxSize + 15 + row * bubbleSpacing;

      // Draw row index (0–9) on left side
      _drawText(
        canvas,
        row.toString(),
        offsetX - leftIndexOffset,
        bubbleY,
        TextStyle(fontSize: 8, color: textColor),
        TextAlign.center,
      );

      // Draw bubbles for each column
      for (int col = 0; col < totalDigits; col++) {
        final double bubbleX = offsetX + col * columnSpacing + digitBoxSize / 2;
        canvas.drawCircle(Offset(bubbleX, bubbleY), bubbleRadius, boxPaint);

        // Draw digit inside bubble
        _drawText(
          canvas,
          row.toString(),
          bubbleX,
          bubbleY - 1,
          TextStyle(fontSize: 7, color: textColor),
          TextAlign.center,
        );
        // Fill the correct bubble (if matches)
        if (int.tryParse(userValue[col]) == row) {
          final Paint fillPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.black;
          canvas.drawCircle(
            Offset(bubbleX, bubbleY),
            bubbleRadius - 1.5,
            fillPaint,
          );
        }
      }
    }
  }

  static void _drawAnswerGridSection(Canvas canvas, OMRExamConfig config) {
    final startY = MARGIN + 362;
    final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;
    final sectionHeight = 365;

    // Section background
    final bgPaint = Paint()..color = lightBgColor;
    canvas.drawRect(
      Rect.fromLTWH(
        MARGIN + 10,
        startY,
        sectionWidth,
        sectionHeight.toDouble(),
      ),
      bgPaint,
    );

    // Section border
    _drawRoundedRect(
      canvas,
      Rect.fromLTWH(
        MARGIN + 10,
        startY,
        sectionWidth,
        sectionHeight.toDouble(),
      ),
      4.0,
      borderColor,
      false,
    );

    // Fill the title background
    final titleBgPaint = Paint()..color = primaryColor;
    canvas.drawRect(
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 20),
      titleBgPaint,
    );

    // Section title
    _drawText(
      canvas,
      "ANSWER GRID - MARK YOUR ANSWERS CLEARLY",
      A4_WIDTH / 2,
      startY + 10,
      TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: lightBgColor),
      TextAlign.center,
    );

    // Draw answer grid with 3 columns
    _drawAnswerGrid(canvas, startY + 35, config.numberOfQuestions);
  }

  static void _drawAnswerGrid(
    Canvas canvas,
    double startY,
    int totalQuestions,
  ) {
    final questionsPerColumn = (totalQuestions / 3).ceil();
    final columnWidth = (A4_WIDTH - 2 * MARGIN - 40) / 3;

    // Column headers
    final options = ["A", "B", "C", "D"];
    for (int col = 0; col < 3; col++) {
      final colX = MARGIN + 20 + (col * columnWidth);

      // Column header background
      final headerPaint = Paint()..color = secondaryColor.withOpacity(0.8);
      canvas.drawRect(
        Rect.fromLTWH(colX, startY - 5, columnWidth - 10, 20),
        headerPaint,
      );

      // Question number and options header
      _drawText(
        canvas,
        "Q.No",
        colX + 25,
        startY + 5,
        TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        TextAlign.left,
      );

      for (int opt = 0; opt < 4; opt++) {
        _drawText(
          canvas,
          options[opt],
          colX + 65 + (opt * 25),
          startY + 5,
          TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          TextAlign.center,
        );
      }

      // Questions and bubbles
      for (int i = 0; i < questionsPerColumn; i++) {
        final questionNum = col * questionsPerColumn + i + 1;
        if (questionNum > totalQuestions) break;

        final y = startY + 25 + (i * 22);

        // Alternate row background
        if (i % 2 == 0) {
          final rowBgPaint = Paint()..color = Colors.grey.withOpacity(0.05);
          canvas.drawRect(
            Rect.fromLTWH(colX, y - 5, columnWidth - 10, 20),
            rowBgPaint,
          );
        }

        // Question number
        _drawText(
          canvas,
          questionNum.toString().padLeft(2, '0'),
          colX + 25,
          y + 4,
          TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          TextAlign.left,
        );

        // Answer bubbles
        for (int opt = 0; opt < 4; opt++) {
          final x = colX + 60 + (opt * 25);
          _drawBubble(canvas, x, y, false);

          // Draw option letter inside bubble
          _drawText(
            canvas,
            options[opt],
            x + BUBBLE_RADIUS,
            y + BUBBLE_RADIUS - 1,
            TextStyle(fontSize: 8, color: textColor.withOpacity(0.6)),
            TextAlign.center,
          );
        }
      }
    }

    // Instructions
    _drawText(
      canvas,
      "INSTRUCTIONS: Use HB pencil only. Completely darken the bubble. Erase completely to change.",
      A4_WIDTH / 2,
      startY + 340,
      TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        color: accentColor,
        fontStyle: FontStyle.italic,
      ),
      TextAlign.center,
    );
  }

  static void _drawFooterSection(Canvas canvas) {
    final startY = A4_HEIGHT - MARGIN - 80;
    final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;

    // Section border
    _drawRoundedRect(
      canvas,
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 70),
      4.0,
      borderColor,
      false,
    );

    // Signature fields
    final signatures = [
      "Student's Signature",
      "Invigilator's Signature",
      "Examiner's Signature",
    ];

    final fieldWidth = (sectionWidth - 40) / 3;
    for (int i = 0; i < signatures.length; i++) {
      final x = MARGIN + 20 + (i * fieldWidth);

      _drawText(
        canvas,
        signatures[i],
        x + fieldWidth / 2,
        startY + 15,
        TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
        TextAlign.center,
      );

      // Signature line
      final linePaint = Paint()
        ..color = borderColor
        ..strokeWidth = 0.8;

      canvas.drawLine(
        Offset(x + 10, startY + 40),
        Offset(x + fieldWidth - 10, startY + 40),
        linePaint,
      );

      // Date label
      _drawText(
        canvas,
        "Date:",
        x + 15,
        startY + 50,
        TextStyle(fontSize: 9, color: textColor),
        TextAlign.left,
      );

      // Date line
      canvas.drawLine(
        Offset(x + 45, startY + 55),
        Offset(x + fieldWidth - 20, startY + 55),
        linePaint,
      );
    }

    // Add barcode/QR code area (optional)
    // _drawBarcodeArea(canvas, MARGIN + 10, A4_HEIGHT - MARGIN - 30);
  }

  static void _drawBarcodeArea(Canvas canvas, double x, double y) {
    final width = 100.0;
    final height = 20.0;

    // Draw barcode placeholder
    final barcodePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw vertical lines to simulate barcode
    for (int i = 0; i < 30; i++) {
      final lineX = x + (i * 3.0) + 10;
      final lineWidth = (i % 2 == 0) ? 1.0 : 2.0;

      canvas.drawRect(
        Rect.fromLTWH(lineX, y, lineWidth, height),
        Paint()..color = Colors.black,
      );
    }

    // Draw border
    canvas.drawRect(Rect.fromLTWH(x, y, width, height), barcodePaint);
  }

  // Helper Methods
  static void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    TextStyle style,
    TextAlign align,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    );
    textPainter.layout();

    double offsetX = x;
    double offsetY = y;

    if (align == TextAlign.center) {
      offsetX -= textPainter.width / 2;
    } else if (align == TextAlign.right) {
      offsetX -= textPainter.width;
    }

    textPainter.paint(
      canvas,
      Offset(offsetX, offsetY - textPainter.height / 2),
    );
  }

  static void _drawRoundedRect(
    Canvas canvas,
    Rect rect,
    double radius,
    Color color,
    bool fill,
  ) {
    final paint = Paint()
      ..color = color
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, paint);
  }

  static void _drawBubble(Canvas canvas, double x, double y, bool filled) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final fillPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(x + BUBBLE_RADIUS, y + BUBBLE_RADIUS),
      BUBBLE_RADIUS,
      borderPaint,
    );

    if (filled) {
      canvas.drawCircle(
        Offset(x + BUBBLE_RADIUS, y + BUBBLE_RADIUS),
        BUBBLE_RADIUS - 1.5,
        fillPaint,
      );
    }
  }

  static void _drawBubbleWithLabel(
    Canvas canvas,
    double x,
    double y,
    String label,
    bool filled,
  ) {
    _drawBubble(canvas, x, y, filled);

    _drawText(
      canvas,
      label,
      x + BUBBLE_RADIUS,
      y + BUBBLE_RADIUS * 2 + 8,
      TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textColor),
      TextAlign.center,
    );
  }

  static void _drawLabeledField(
    Canvas canvas,
    double x,
    double y,
    String label,
    String value,
    double width,
  ) {
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

    canvas.drawLine(Offset(x, y + 17), Offset(x + width, y + 17), linePaint);

    if (value.isNotEmpty) {
      _drawText(
        canvas,
        value,
        x + 5,
        y + 11,
        TextStyle(fontSize: 10, color: textColor),
        TextAlign.left,
      );
    }
  }

  // Additional utility methods for enhanced functionality
  static Future<List<File>> generateBatchOMRSheets(
    List<OMRExamConfig> configs,
  ) async {
    final List<File> generatedFiles = [];

    for (final config in configs) {
      try {
        final file = await generateOMRSheet(config);
        generatedFiles.add(file);
      } catch (e) {
        print('Error generating OMR for ${config.studentName}: $e');
      }
    }

    return generatedFiles;
  }

  static Future<Uint8List> generateOMRPDF(OMRExamConfig config) async {
    final imageBytes = await _generateOMRImage(config);
    // Convert to PDF using the printing package
    final pdf = await Printing.convertHtml(
      format: PdfPageFormat.a4,
      html:
          '<img src="data:image/png;base64,${base64Encode(imageBytes)}" style="width: 100%; height: auto;"/>',
    );
    return pdf;
  }
}

// Usage Example Widget
class ProfessionalOMRGeneratorExample extends StatelessWidget {
  final OMRExamConfig config = OMRExamConfig(
    examName: "PRE-UNIVERSITY FINAL EXAMINATION",
    numberOfQuestions: 40,
    setNumber: 2,
    studentId: "2023001234",
    mobileNumber: "01712345678",
    examDate: DateTime.now(),
    correctAnswers: List.generate(40, (index) => "A"),
    studentName: "John Doe",
    className: "Grade XII - Science",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional OMR Generator'),
        backgroundColor: ProfessionalOMRGenerator.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: ProfessionalOMRGenerator.lightBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ProfessionalOMRGenerator.borderColor),
              ),
              child: Icon(
                Icons.assignment,
                size: 80,
                color: ProfessionalOMRGenerator.primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Professional OMR Answer Sheet Generator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Generates A4 size OMR sheets with student information,\nanswer bubbles, and signature fields.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final file = await ProfessionalOMRGenerator.generateOMRSheet(
                    config,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Professional OMR Sheet Generated!\nSaved to: ${file.path}',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error generating OMR sheet: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.print),
              label: const Text('Generate OMR Sheet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ProfessionalOMRGenerator.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      // Generate multiple OMR sheets for demonstration
                      final configs = List.generate(
                        5,
                        (index) => OMRExamConfig(
                          examName: "PRE-UNIVERSITY FINAL EXAMINATION",
                          numberOfQuestions: 40,
                          setNumber: (index % 4) + 1,
                          studentId: "202300${1234 + index}",
                          mobileNumber: "017123456${78 + index}",
                          examDate: DateTime.now(),
                          correctAnswers: List.generate(
                            40,
                            (i) => ["A", "B", "C", "D"][i % 4],
                          ),
                          studentName: "Student ${index + 1}",
                          className: "Grade XII - Science",
                        ),
                      );

                      final files =
                          await ProfessionalOMRGenerator.generateBatchOMRSheets(
                            configs,
                          );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Generated ${files.length} OMR Sheets!',
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error generating batch: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.library_books),
                  label: const Text('Batch Generate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProfessionalOMRGenerator.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final imageBytes =
                          await ProfessionalOMRGenerator._generateOMRImage(
                            config,
                          );
                      await ProfessionalOMRGenerator.printOMRSheet(imageBytes);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sent to printer!'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error printing: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Extension class for additional OMR features
class OMRGeneratorExtensions {
  // Generate OMR with custom answer pattern
  static Future<File> generateOMRWithAnswerKey(
    OMRExamConfig config,
    bool showAnswerKey,
  ) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Background
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        ProfessionalOMRGenerator.A4_WIDTH,
        ProfessionalOMRGenerator.A4_HEIGHT,
      ),
      paint..color = Colors.white,
    );

    // Draw standard OMR elements
    ProfessionalOMRGenerator._drawHeaderSection(canvas, config);
    ProfessionalOMRGenerator._drawStudentInfoSection(canvas, config);
    ProfessionalOMRGenerator._drawSetSelectionSection(canvas, config);
    ProfessionalOMRGenerator._drawIdNumberSection(canvas, config);

    // Draw answer grid with marked answers if showAnswerKey is true
    if (showAnswerKey) {
      _drawAnswerGridWithKey(canvas, config);
    } else {
      ProfessionalOMRGenerator._drawAnswerGridSection(canvas, config);
    }

    ProfessionalOMRGenerator._drawFooterSection(canvas);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      ProfessionalOMRGenerator.A4_WIDTH.toInt(),
      ProfessionalOMRGenerator.A4_HEIGHT.toInt(),
    );
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return await ProfessionalOMRGenerator._saveOMRSheetWithGal(bytes, config);
  }

  static void _drawAnswerGridWithKey(Canvas canvas, OMRExamConfig config) {
    final startY = ProfessionalOMRGenerator.MARGIN + 362;
    final sectionWidth =
        ProfessionalOMRGenerator.A4_WIDTH -
        2 * ProfessionalOMRGenerator.MARGIN -
        20;
    final sectionHeight = 365;

    // Section background
    final bgPaint = Paint()..color = ProfessionalOMRGenerator.lightBgColor;
    canvas.drawRect(
      Rect.fromLTWH(
        ProfessionalOMRGenerator.MARGIN + 10,
        startY,
        sectionWidth,
        sectionHeight.toDouble(),
      ),
      bgPaint,
    );

    // Section border
    ProfessionalOMRGenerator._drawRoundedRect(
      canvas,
      Rect.fromLTWH(
        ProfessionalOMRGenerator.MARGIN + 10,
        startY,
        sectionWidth,
        sectionHeight.toDouble(),
      ),
      4.0,
      ProfessionalOMRGenerator.borderColor,
      false,
    );

    // Title with "ANSWER KEY" label
    final titleBgPaint = Paint()..color = ProfessionalOMRGenerator.accentColor;
    canvas.drawRect(
      Rect.fromLTWH(
        ProfessionalOMRGenerator.MARGIN + 10,
        startY,
        sectionWidth,
        20,
      ),
      titleBgPaint,
    );

    ProfessionalOMRGenerator._drawText(
      canvas,
      "ANSWER KEY - CORRECT ANSWERS MARKED",
      ProfessionalOMRGenerator.A4_WIDTH / 2,
      startY + 10,
      TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      TextAlign.center,
    );

    // Draw answer grid with marked correct answers
    _drawAnswerGridWithMarks(canvas, startY + 35, config);
  }

  static void _drawAnswerGridWithMarks(
    Canvas canvas,
    double startY,
    OMRExamConfig config,
  ) {
    final questionsPerColumn = (config.numberOfQuestions / 3).ceil();
    final columnWidth =
        (ProfessionalOMRGenerator.A4_WIDTH -
            2 * ProfessionalOMRGenerator.MARGIN -
            40) /
        3;
    final options = ["A", "B", "C", "D"];

    for (int col = 0; col < 3; col++) {
      final colX = ProfessionalOMRGenerator.MARGIN + 20 + (col * columnWidth);

      // Column header
      final headerPaint = Paint()
        ..color = ProfessionalOMRGenerator.secondaryColor.withOpacity(0.8);
      canvas.drawRect(
        Rect.fromLTWH(colX, startY - 5, columnWidth - 10, 20),
        headerPaint,
      );

      // Headers
      ProfessionalOMRGenerator._drawText(
        canvas,
        "Q.No",
        colX + 25,
        startY + 5,
        TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        TextAlign.left,
      );

      for (int opt = 0; opt < 4; opt++) {
        ProfessionalOMRGenerator._drawText(
          canvas,
          options[opt],
          colX + 65 + (opt * 25),
          startY + 5,
          TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          TextAlign.center,
        );
      }

      // Questions and bubbles with correct answers marked
      for (int i = 0; i < questionsPerColumn; i++) {
        final questionNum = col * questionsPerColumn + i + 1;
        if (questionNum > config.numberOfQuestions) break;

        final y = startY + 25 + (i * 22);
        final correctAnswer = config.correctAnswers[questionNum - 1];

        // Question number
        ProfessionalOMRGenerator._drawText(
          canvas,
          questionNum.toString().padLeft(2, '0'),
          colX + 25,
          y + 4,
          TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: ProfessionalOMRGenerator.textColor,
          ),
          TextAlign.left,
        );

        // Answer bubbles
        for (int opt = 0; opt < 4; opt++) {
          final x = colX + 60 + (opt * 25);
          final isCorrect = options[opt] == correctAnswer;

          // Draw bubble (filled if correct)
          ProfessionalOMRGenerator._drawBubble(canvas, x, y, isCorrect);

          // Draw option letter
          ProfessionalOMRGenerator._drawText(
            canvas,
            options[opt],
            x + ProfessionalOMRGenerator.BUBBLE_RADIUS,
            y + ProfessionalOMRGenerator.BUBBLE_RADIUS - 1,
            TextStyle(
              fontSize: 8,
              color: isCorrect
                  ? Colors.white
                  : ProfessionalOMRGenerator.textColor.withOpacity(0.6),
              fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
            ),
            TextAlign.center,
          );
        }
      }
    }
  }

  // Generate blank OMR template
  static Future<File> generateBlankTemplate({
    required String examName,
    required int numberOfQuestions,
    required String className,
  }) async {
    final config = OMRExamConfig(
      examName: examName,
      numberOfQuestions: numberOfQuestions,
      setNumber: 1,
      studentId: '',
      mobileNumber: '',
      examDate: DateTime.now(),
      correctAnswers: List.generate(numberOfQuestions, (index) => ''),
      studentName: '',
      className: className,
    );

    return await ProfessionalOMRGenerator.generateOMRSheet(config);
  }

  // Export OMR configuration to JSON
  static Map<String, dynamic> exportOMRConfig(OMRExamConfig config) {
    return {
      'examName': config.examName,
      'numberOfQuestions': config.numberOfQuestions,
      'setNumber': config.setNumber,
      'studentId': config.studentId,
      'mobileNumber': config.mobileNumber,
      'examDate': config.examDate.toIso8601String(),
      'correctAnswers': config.correctAnswers,
      'studentName': config.studentName,
      'className': config.className,
    };
  }

  // Import OMR configuration from JSON
  static OMRExamConfig importOMRConfig(Map<String, dynamic> json) {
    return OMRExamConfig(
      examName: json['examName'],
      numberOfQuestions: json['numberOfQuestions'],
      setNumber: json['setNumber'],
      studentId: json['studentId'],
      mobileNumber: json['mobileNumber'],
      examDate: DateTime.parse(json['examDate']),
      correctAnswers: List<String>.from(json['correctAnswers']),
      studentName: json['studentName'] ?? '',
      className: json['className'] ?? '',
    );
  }
}

// Utility class for OMR validation
class OMRValidator {
  static bool isValidStudentId(String id) {
    return id.length == 10 && RegExp(r'^\d+$').hasMatch(id);
  }

  static bool isValidMobileNumber(String number) {
    return number.length == 11 && RegExp(r'^\d+$').hasMatch(number);
  }

  static bool isValidAnswerSet(List<String> answers, int expectedCount) {
    if (answers.length != expectedCount) return false;

    final validOptions = ['A', 'B', 'C', 'D', ''];
    return answers.every((answer) => validOptions.contains(answer));
  }

  static Map<String, String> validateOMRConfig(OMRExamConfig config) {
    final errors = <String, String>{};

    if (config.examName.isEmpty) {
      errors['examName'] = 'Exam name is required';
    }

    if (config.numberOfQuestions < 10 || config.numberOfQuestions > 100) {
      errors['numberOfQuestions'] =
          'Number of questions must be between 10 and 100';
    }

    if (config.setNumber < 1 || config.setNumber > 4) {
      errors['setNumber'] = 'Set number must be between 1 and 4';
    }

    if (!isValidStudentId(config.studentId)) {
      errors['studentId'] = 'Student ID must be 10 digits';
    }

    if (!isValidMobileNumber(config.mobileNumber)) {
      errors['mobileNumber'] = 'Mobile number must be 11 digits';
    }

    if (!isValidAnswerSet(config.correctAnswers, config.numberOfQuestions)) {
      errors['correctAnswers'] = 'Invalid answer set';
    }

    return errors;
  }
}

class OMRGenerationLogger {
  static final List<Map<String, dynamic>> _logs = [];

  static void logGeneration(OMRExamConfig config, bool success) {
    _logs.add({
      'timestamp': DateTime.now(),
      'examName': config.examName,
      'studentName': config.studentName,
      'success': success,
    });
  }

  static List<Map<String, dynamic>> getLogs() => List.unmodifiable(_logs);
}

class OMRLocalizations {
  final String studentName;
  final String className;
  final String date;
  final String mobileNumber;
  final String studentId;

  const OMRLocalizations({
    this.studentName = "Student Name:",
    this.className = "Class:",
    this.date = "Date:",
    this.mobileNumber = "Mobile Number:",
    this.studentId = "Student ID Number:",
  });
}

// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:gal/gal.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:printing/printing.dart';
//
// class OMRExamConfig {
//   final String examName;
//   final int numberOfQuestions;
//   final int setNumber;
//   final String studentId;
//   final String mobileNumber;
//   final DateTime examDate;
//   final List<String> correctAnswers;
//   final String studentName;
//   final String className;
//
//   OMRExamConfig({
//     required this.examName,
//     required this.numberOfQuestions,
//     required this.setNumber,
//     required this.studentId,
//     required this.mobileNumber,
//     required this.examDate,
//     required this.correctAnswers,
//     this.studentName = '',
//     this.className = '',
//   });
// }
//
// class ProfessionalOMRGenerator {
//   static const double A4_WIDTH = 595.0; // 8.27 inches at 72 DPI
//   static const double A4_HEIGHT = 842.0; // 11.69 inches at 72 DPI
//   static const double MARGIN = 8.0;
//   static const double BUBBLE_RADIUS = 6;
//   static const double SMALL_BUBBLE_RADIUS = 5;
//
//   // Professional color scheme
//   static final Color primaryColor = const Color(0xFF2C3E50); // Dark blue-gray
//   static final Color secondaryColor = const Color(0xFF34495E); // Slightly lighter
//   static final Color accentColor = const Color(0xFFE74C3C); // Red for important elements
//   static final Color lightBgColor = const Color(0xFFF8F9FA); // Light gray background
//   static final Color borderColor = const Color(0xFF2C3E50);
//   static final Color textColor = const Color(0xFF2C3E50);
//
//   // static Future<File> generateOMRSheet(OMRExamConfig config) async {
//   //   final recorder = PictureRecorder();
//   //   final canvas = Canvas(recorder);
//   //   final paint = Paint();
//   //
//   //   // Draw white background
//   //   canvas.drawRect(
//   //     Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT),
//   //     paint..color = Colors.white,
//   //   );
//   //
//   //   // Draw main border
//   //   _drawRoundedRect(
//   //     canvas,
//   //     Rect.fromLTWH(MARGIN, MARGIN, A4_WIDTH - 2 * MARGIN, A4_HEIGHT - 2 * MARGIN),
//   //     8.0,
//   //     borderColor,
//   //     false,
//   //   );
//   //
//   //   // Draw all sections
//   //   _drawHeaderSection(canvas, config);
//   //   _drawStudentInfoSection(canvas, config);
//   //   _drawSetSelectionSection(canvas, config);
//   //   _drawIdNumberSection(canvas, config);
//   //   _drawAnswerGridSection(canvas, config);
//   //   _drawFooterSection(canvas);
//   //
//   //   final picture = recorder.endRecording();
//   //   final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
//   //   final byteData = await image.toByteData(format: ImageByteFormat.png);
//   //   final bytes = byteData!.buffer.asUint8List();
//   //
//   //   final directory = await getTemporaryDirectory();
//   //   final file = File('${directory.path}/professional_omr_${DateTime.now().millisecondsSinceEpoch}.png');
//   //   await file.writeAsBytes(bytes);
//   //
//   //   return file;
//   // }
//
//
//
//   static Future<File> generateOMRSheet(OMRExamConfig config) async {
//     try {
//       // Generate OMR sheet bytes
//       final Uint8List imageBytes = await _generateOMRImage(config);
//
//       // Save to gallery and permanent directory
//       final file = await _saveOMRSheetWithGal(imageBytes, config);
//
//       print('✅ OMR Sheet generated successfully.');
//       return file;
//     } catch (e) {
//       print('❌ Error generating OMR sheet: $e');
//       rethrow;
//     }
//   }
//
//   // ===========================================================
//   // CANVAS IMAGE CREATION
//   // ===========================================================
//   static Future<Uint8List> _generateOMRImage(OMRExamConfig config) async {
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//     final paint = Paint();
//
//     // Background
//     canvas.drawRect(
//       Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT),
//       paint..color = Colors.white,
//     );
//
//     // Main border
//     _drawRoundedRect(
//       canvas,
//       Rect.fromLTWH(MARGIN, MARGIN, A4_WIDTH - 2 * MARGIN, A4_HEIGHT - 2 * MARGIN),
//       8.0,
//       Colors.black,
//       false,
//     );
//
//     // Draw sections
//     _drawHeaderSection(canvas, config);
//     _drawStudentInfoSection(canvas, config);
//     _drawSetSelectionSection(canvas, config);
//     _drawIdNumberSection(canvas, config);
//     _drawAnswerGridSection(canvas, config);
//     _drawFooterSection(canvas);
//
//     final picture = recorder.endRecording();
//     final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
//     return byteData!.buffer.asUint8List();
//   }
//
//   // ===========================================================
//   // SAVE TO GALLERY + PERMANENT STORAGE
//   // ===========================================================
//   static Future<File> _saveOMRSheetWithGal(Uint8List bytes, OMRExamConfig config) async {
//     await _requestGalleryPermissions();
//
//     try {
//       // 1️⃣ Attempt to save using Gal (safest)
//       final tempDir = await getTemporaryDirectory();
//       final tempFile = File('${tempDir.path}/_temp_omr_${DateTime.now().millisecondsSinceEpoch}.png');
//       await tempFile.writeAsBytes(bytes);
//       await Gal.putImage(tempFile.path, album: 'OMR Sheets');
//
//       // 2️⃣ Save a permanent copy to Pictures/OMR_Sheets
//       final permanentFile = await _saveToPublicPictures(bytes, config);
//
//       // Cleanup temp file
//       await tempFile.delete();
//
//       print('✅ Saved to gallery & Pictures folder');
//       return permanentFile;
//     } catch (e) {
//       print('⚠️ Gal save failed: $e');
//       // fallback: save manually
//       return await _saveToPublicPictures(bytes, config);
//     }
//   }
//
//   // ===========================================================
//   // SAVE TO PUBLIC PICTURES DIRECTORY (VISIBLE IN GALLERY)
//   // ===========================================================
//   static Future<File> _saveToPublicPictures(Uint8List bytes, OMRExamConfig config) async {
//     final timestamp = DateTime.now().millisecondsSinceEpoch;
//     final fileName = 'OMR_${_sanitizeFileName(config.examName)}_$timestamp.png';
//
//     Directory? publicDir;
//     if (Platform.isAndroid) {
//       publicDir = Directory('/storage/emulated/0/Pictures/OMR_Sheets');
//     } else {
//       publicDir = await getApplicationDocumentsDirectory();
//     }
//
//     await publicDir.create(recursive: true);
//     final file = File('${publicDir.path}/$fileName');
//     await file.writeAsBytes(bytes);
//
//     // ✅ Trigger Android media scanner
//     if (Platform.isAndroid) {
//       try {
//         await Process.run('am', ['broadcast', '-a', 'android.intent.action.MEDIA_SCANNER_SCAN_FILE', '-d', 'file://${file.path}']);
//       } catch (_) {
//         // Ignore if unavailable
//       }
//     }
//
//     return file;
//   }
//
//   // ===========================================================
//   // PRINTING SUPPORT (PDF/Direct Print)
//   // ===========================================================
//   static Future<void> printOMRSheet(Uint8List imageBytes) async {
//     try {
//       await Printing.layoutPdf(onLayout: (format) async => imageBytes);
//     } catch (e) {
//       print('❌ Error printing OMR sheet: $e');
//     }
//   }
//
//   // ===========================================================
//   // PERMISSION HANDLER
//   // ===========================================================
//   static Future<void> _requestGalleryPermissions() async {
//     if (Platform.isAndroid) {
//       final storageStatus = await Permission.manageExternalStorage.status;
//       if (!storageStatus.isGranted) {
//         await Permission.manageExternalStorage.request();
//       }
//       final photosStatus = await Permission.photos.status;
//       if (!photosStatus.isGranted) {
//         await Permission.photos.request();
//       }
//     } else if (Platform.isIOS) {
//       final photosStatus = await Permission.photos.status;
//       if (!photosStatus.isGranted) {
//         await Permission.photos.request();
//       }
//     }
//   }
//
//   // ===========================================================
//   // HELPERS
//   // ===========================================================
//   static String _sanitizeFileName(String name) {
//     final sanitized = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').replaceAll(RegExp(r'\s+'), '_');
//     return sanitized.length > 50 ? sanitized.substring(0, 50) : sanitized;
//   }
//
//
//
//   // static Future<File> generateOMRSheet(OMRExamConfig config) async {
//   //   try {
//   //     // Generate the OMR sheet image
//   //     final Uint8List imageBytes = await _generateOMRImage(config);
//   //
//   //     // Save to gallery and local storage
//   //     return await _saveOMRSheetWithGal(imageBytes, config);
//   //
//   //   } catch (e) {
//   //     print('Error generating OMR sheet: $e');
//   //     rethrow;
//   //   }
//   // }
//   //
//   // static Future<Uint8List> _generateOMRImage(OMRExamConfig config) async {
//   //   final recorder = PictureRecorder();
//   //   final canvas = Canvas(recorder);
//   //   final paint = Paint();
//   //
//   //   // Draw white background
//   //   canvas.drawRect(
//   //     Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT),
//   //     paint..color = Colors.white,
//   //   );
//   //
//   //   // Draw main border
//   //   _drawRoundedRect(
//   //     canvas,
//   //     Rect.fromLTWH(MARGIN, MARGIN, A4_WIDTH - 2 * MARGIN, A4_HEIGHT - 2 * MARGIN),
//   //     8.0,
//   //     Colors.black,
//   //     false,
//   //   );
//   //
//   //   // Draw all sections (your existing methods)
//   //   _drawHeaderSection(canvas, config);
//   //   _drawStudentInfoSection(canvas, config);
//   //   _drawSetSelectionSection(canvas, config);
//   //   _drawIdNumberSection(canvas, config);
//   //   _drawAnswerGridSection(canvas, config);
//   //   _drawFooterSection(canvas);
//   //
//   //   // Convert to image bytes
//   //   final picture = recorder.endRecording();
//   //   final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
//   //   final byteData = await image.toByteData(format: ImageByteFormat.png);
//   //   return byteData!.buffer.asUint8List();
//   // }
//   //
//   // static Future<File> _saveOMRSheetWithGal(Uint8List bytes, OMRExamConfig config) async {
//   //   try {
//   //     // Request permissions first
//   //     await _requestGalleryPermissions();
//   //
//   //     // Create temporary file for gal package
//   //     final tempDir = await getTemporaryDirectory();
//   //     final tempFile = File('${tempDir.path}/_temp_omr_${DateTime.now().millisecondsSinceEpoch}.png');
//   //     await tempFile.writeAsBytes(bytes);
//   //
//   //     // Save to gallery using gal package
//   //     await Gal.putImage(tempFile.path, album: 'OMR Sheets');
//   //
//   //     // Also save to app's permanent storage with proper naming
//   //     final permanentFile = await _saveToAppDirectory(bytes, config);
//   //
//   //     // Clean up temporary file
//   //     await tempFile.delete();
//   //
//   //     print('OMR Sheet saved successfully to gallery and local storage');
//   //     return permanentFile;
//   //
//   //   } catch (e) {
//   //     print('Error saving with gal: $e');
//   //     // Fallback: save only to app directory
//   //     return await _saveToAppDirectory(bytes, config);
//   //   }
//   // }
//   //
//   // static Future<File> _saveToAppDirectory(Uint8List bytes, OMRExamConfig config) async {
//   //   // Create meaningful filename
//   //   final timestamp = DateTime.now().millisecondsSinceEpoch;
//   //   final fileName = 'OMR_${_sanitizeFileName(config.examName)}_${config.examName}_$timestamp.png';
//   //
//   //   // Save to app documents directory
//   //   final appDir = await getApplicationDocumentsDirectory();
//   //   final omrSheetsDir = Directory('${appDir.path}/OMR_Sheets');
//   //   await omrSheetsDir.create(recursive: true);
//   //
//   //   final permanentFile = File('${omrSheetsDir.path}/$fileName');
//   //   await permanentFile.writeAsBytes(bytes);
//   //
//   //   return permanentFile;
//   // }
//   //
//   // static Future<void> _requestGalleryPermissions() async {
//   //   if (Platform.isAndroid) {
//   //     // For Android, request storage permission
//   //     final status = await Permission.storage.status;
//   //     if (!status.isGranted) {
//   //       final result = await Permission.storage.request();
//   //       if (!result.isGranted) {
//   //         throw Exception('Storage permission denied');
//   //       }
//   //     }
//   //   } else if (Platform.isIOS) {
//   //     // For iOS, request photos permission
//   //     final status = await Permission.photos.status;
//   //     if (!status.isGranted) {
//   //       final result = await Permission.photos.request();
//   //       if (!result.isGranted) {
//   //         throw Exception('Photos permission denied');
//   //       }
//   //     }
//   //   }
//   //   // For other platforms, no permission needed
//   // }
//   //
//   // static String _sanitizeFileName(String name) {
//   //   // Remove invalid filename characters
//   //   return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
//   //       .replaceAll(RegExp(r'\s+'), '_')
//   //       .substring(0, name.length < 50 ? name.length : 50);
//   // }
//
//   static void _drawHeaderSection(Canvas canvas, OMRExamConfig config) {
//     final centerX = A4_WIDTH / 2;
//
//     // Institution name - Main title
//     _drawText(
//       canvas,
//       config.examName.toUpperCase(),
//       centerX,
//       MARGIN + 10,
//       TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.bold,
//         color: primaryColor,
//         letterSpacing: 1.2,
//       ),
//       TextAlign.center,
//     );
//
//     // Exam type subtitle
//     _drawText(
//       canvas,
//       "MULTIPLE CHOICE ANSWER SHEET",
//       centerX,
//       MARGIN + 25,
//       TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w600,
//         color: secondaryColor,
//         letterSpacing: 1.0,
//       ),
//       TextAlign.center,
//     );
//
//     // Decorative line
//     final linePaint = Paint()
//       ..color = accentColor
//       ..strokeWidth = 1.5
//       ..style = PaintingStyle.stroke;
//
//     canvas.drawLine(
//       Offset(centerX - 100, MARGIN + 35),
//       Offset(centerX + 100, MARGIN + 35),
//       linePaint,
//     );
//   }
//
//   static void _drawStudentInfoSection(Canvas canvas, OMRExamConfig config) {
//     final startY = MARGIN + 40;
//     final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;
//
//     // Section background
//     final bgPaint = Paint()..color = lightBgColor;
//     canvas.drawRect(
//       Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 60),
//       bgPaint,
//     );
//
//     // Section border
//     _drawRoundedRect(
//       canvas,
//       Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 60),
//       4.0,
//       borderColor,
//       false,
//     );
//
//     // Fill the title background
//     final titleBgPaint = Paint()..color = primaryColor;
//     canvas.drawRect(
//       Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 20),
//       titleBgPaint,
//     );
//
//     // Section title
//     _drawText(
//       canvas,
//       "STUDENT INFORMATION",
//       MARGIN + 20,
//       startY + 10,
//       TextStyle(
//         fontSize: 10,
//         fontWeight: FontWeight.bold,
//         // color: Colors.amber,
//         color: lightBgColor,
//       ),
//       TextAlign.left,
//     );
//
//
//     // Student Name field
//     _drawLabeledField(canvas, MARGIN + 20, startY + 30, "Student Name:", config.studentName, 200);
//
//     // Class field
//     _drawLabeledField(canvas, MARGIN + 250, startY + 30, "Class:", config.className, 120);
//
//     // Date field
//     final dateStr = "${config.examDate.day}/${config.examDate.month}/${config.examDate.year}";
//     _drawLabeledField(canvas, MARGIN + 400, startY + 30, "Date:", dateStr, 120);
//   }
//
//   static void _drawSetSelectionSection(Canvas canvas, OMRExamConfig config) {
//     final startY = MARGIN + 110;
//
//     _drawText(
//       canvas,
//       "SET NUMBER:",
//       MARGIN + 20,
//       startY,
//       TextStyle(
//         fontSize: 11,
//         fontWeight: FontWeight.bold,
//         color: textColor,
//       ),
//       TextAlign.left,
//     );
//
//     // Set number bubbles (1-4)
//     final setNumbers = ["1", "2", "3", "4"];
//     for (int i = 0; i < setNumbers.length; i++) {
//       final x = MARGIN + 120 + (i * 80);
//       _drawBubbleWithLabel(canvas, x, startY - 5, setNumbers[i], config.setNumber == i + 1);
//     }
//   }
//
//   static void _drawIdNumberSection(Canvas canvas, OMRExamConfig config) {
//     final startY = MARGIN + 140;
//     const double digitBoxSize = 20.0;
//     const double bubbleRadius = 6.0;
//     const double bubbleSpacing = 18.0;
//     const double columnSpacing = 25.0;
//
//     // ==== Titles ====
//     _drawText(
//       canvas,
//       "STUDENT ID NUMBER:",
//       MARGIN + 20,
//       startY,
//       TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
//       TextAlign.left,
//     );
//
//     _drawText(
//       canvas,
//       "MOBILE NUMBER:",
//       MARGIN + 300,
//       startY,
//       TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
//       TextAlign.left,
//     );
//
//     // ==== Draw Student ID section (10 digits) ====
//     _drawDigitEntrySection(
//       canvas,
//       offsetX: MARGIN + 20,
//       offsetY: startY + 10,
//       totalDigits: 10,
//       userValue: config.studentId.padLeft(10, '0'),
//       label: "Student ID",
//     );
//
//     // ==== Draw Mobile number section (11 digits) ====
//     _drawDigitEntrySection(
//       canvas,
//       offsetX: MARGIN + 300,
//       offsetY: startY + 10,
//       totalDigits: 11,
//       userValue: config.mobileNumber.padLeft(11, '0'),
//       label: "Mobile Number",
//     );
//   }
//
//   /// Draws a full digit entry section with boxes and bubbles
//   static void _drawDigitEntrySection(
//       Canvas canvas, {
//         required double offsetX,
//         required double offsetY,
//         required int totalDigits,
//         required String userValue,
//         required String label,
//       }) {
//     const double digitBoxSize = 20.0;
//     const double bubbleRadius = 6.0;
//     const double bubbleSpacing = 18.0;
//     const double columnSpacing = 25.0;
//     const double leftIndexOffset = 15.0;
//
//     final Paint boxPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0
//       ..color = Colors.black;
//
//     // === Draw header boxes for digits (for writing) ===
//     for (int i = 0; i < totalDigits; i++) {
//       final double x = offsetX + i * columnSpacing;
//       final double y = offsetY;
//
//       final Rect rect = Rect.fromLTWH(x, y, digitBoxSize, digitBoxSize);
//       canvas.drawRect(rect, boxPaint);
//
//       // Draw digit from userValue (if any)
//       _drawText(
//         canvas,
//         userValue[i],
//         x + digitBoxSize / 2,
//         y + digitBoxSize / 2 - 2,
//         TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
//         TextAlign.center,
//       );
//     }
//
//     // === Draw vertical bubbles (0–9) for each column ===
//     for (int row = 0; row < 10; row++) {
//       final double bubbleY = offsetY + digitBoxSize + 15 + row * bubbleSpacing;
//
//       // Draw row index (0–9) on left side
//       _drawText(
//         canvas,
//         row.toString(),
//         offsetX - leftIndexOffset,
//         bubbleY,
//         TextStyle(fontSize: 8, color: textColor),
//         TextAlign.center,
//       );
//
//       // Draw bubbles for each column
//       for (int col = 0; col < totalDigits; col++) {
//         final double bubbleX = offsetX + col * columnSpacing + digitBoxSize / 2;
//         canvas.drawCircle(Offset(bubbleX, bubbleY), bubbleRadius, boxPaint);
//
//         // Draw digit inside bubble
//         _drawText(
//           canvas,
//           row.toString(),
//           bubbleX,
//           bubbleY - 1,
//           TextStyle(fontSize: 7, color: textColor),
//           TextAlign.center,
//         );
//
//         // Fill the correct bubble (if matches)
//         if (int.tryParse(userValue[col]) == row) {
//           final Paint fillPaint = Paint()
//             ..style = PaintingStyle.fill
//             ..color = Colors.black;
//           canvas.drawCircle(Offset(bubbleX, bubbleY), bubbleRadius - 1.5, fillPaint);
//         }
//       }
//     }
//   }
//
//   /// Generic text drawer helper
//   // static void _drawText(Canvas canvas, String text, double x, double y,
//   //     TextStyle style, TextAlign align) {
//   //   final textPainter = TextPainter(
//   //     text: TextSpan(text: text, style: style),
//   //     textAlign: align,
//   //     textDirection: TextDirection.ltr,
//   //   );
//   //   textPainter.layout();
//   //   Offset offset;
//   //   switch (align) {
//   //     case TextAlign.center:
//   //       offset = Offset(x - textPainter.width / 2, y - textPainter.height / 2);
//   //       break;
//   //     case TextAlign.right:
//   //       offset = Offset(x - textPainter.width, y);
//   //       break;
//   //     default:
//   //       offset = Offset(x, y);
//   //   }
//   //   textPainter.paint(canvas, offset);
//   // }
//
//
//   // static void _drawIdNumberSection(Canvas canvas, OMRExamConfig config) {
//   //   final startY = MARGIN + 150;
//   //
//   //   // Student ID section
//   //   _drawText(
//   //     canvas,
//   //     "STUDENT ID NUMBER:",
//   //     MARGIN + 20,
//   //     startY,
//   //     TextStyle(
//   //       fontSize: 11,
//   //       fontWeight: FontWeight.bold,
//   //       color: textColor,
//   //     ),
//   //     TextAlign.left,
//   //   );
//   //
//   //   // Student ID bubbles (10 digits)
//   //   _drawDigitBubbles(canvas, MARGIN + 20, startY + 20, config.studentId.padLeft(10, '0'), "Student ID");
//   //
//   //   // Mobile Number section
//   //   _drawText(
//   //     canvas,
//   //     "MOBILE NUMBER:",
//   //     MARGIN + 300,
//   //     startY,
//   //     TextStyle(
//   //       fontSize: 11,
//   //       fontWeight: FontWeight.bold,
//   //       color: textColor,
//   //     ),
//   //     TextAlign.left,
//   //   );
//   //
//   //   // Mobile number bubbles (11 digits)
//   //   _drawDigitBubbles(canvas, MARGIN + 300, startY + 20, config.mobileNumber.padLeft(11, '0'), "Mobile");
//   // }
//
//   static void _drawAnswerGridSection(Canvas canvas, OMRExamConfig config) {
//     final startY = MARGIN + 362;
//     final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;
//     final sectionHeight = 365;
//
//     // Section background
//     final bgPaint = Paint()..color = lightBgColor;
//     canvas.drawRect(
//       Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, sectionHeight.toDouble()),
//       bgPaint,
//     );
//
//     // Section border
//     _drawRoundedRect(
//       canvas,
//       Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, sectionHeight.toDouble()),
//       4.0,
//       borderColor,
//       false,
//     );
//
//     // Fill the title background
//     final titleBgPaint = Paint()..color = primaryColor;
//     canvas.drawRect(
//       Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 20),
//       titleBgPaint,
//     );
//
//     // Section title
//     _drawText(
//       canvas,
//       "ANSWER GRID - MARK YOUR ANSWERS CLEARLY",
//       A4_WIDTH / 2,
//       startY + 10,
//       TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.bold,
//         color: lightBgColor,
//       ),
//       TextAlign.center,
//     );
//
//
//     // Draw answer grid with 3 columns
//     _drawAnswerGrid(canvas, startY + 35, config.numberOfQuestions);
//   }
//
//   static void _drawAnswerGrid(Canvas canvas, double startY, int totalQuestions) {
//     final questionsPerColumn = (totalQuestions / 3).ceil();
//     final columnWidth = (A4_WIDTH - 2 * MARGIN - 40) / 3;
//
//     // Column headers
//     final options = ["A", "B", "C", "D"];
//     for (int col = 0; col < 3; col++) {
//       final colX = MARGIN + 20 + (col * columnWidth);
//
//       // Column header background
//       final headerPaint = Paint()..color = secondaryColor.withOpacity(0.8);
//       canvas.drawRect(
//         Rect.fromLTWH(colX, startY - 5, columnWidth - 10, 20),
//         headerPaint,
//       );
//
//       // Question number and options header
//       _drawText(
//         canvas,
//         "Q.No",
//         colX + 25,
//         startY + 5,
//         TextStyle(
//           fontSize: 10,
//           fontWeight: FontWeight.bold,
//           color: Colors.white,
//         ),
//         TextAlign.left,
//       );
//
//       for (int opt = 0; opt < 4; opt++) {
//         _drawText(
//           canvas,
//           options[opt],
//           colX + 65 + (opt * 25),
//           startY + 5,
//           TextStyle(
//             fontSize: 10,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//           TextAlign.center,
//         );
//       }
//
//       // Questions and bubbles
//       for (int i = 0; i < questionsPerColumn; i++) {
//         final questionNum = col * questionsPerColumn + i + 1;
//         if (questionNum > totalQuestions) break;
//
//         final y = startY + 25 + (i * 22);
//
//         // Question number
//         _drawText(
//           canvas,
//           questionNum.toString().padLeft(2, '0'),
//           colX + 25,
//           y + 4,
//           TextStyle(
//             fontSize: 10,
//             fontWeight: FontWeight.w600,
//             color: textColor,
//           ),
//           TextAlign.left,
//         );
//
//         // Answer bubbles
//         for (int opt = 0; opt < 4; opt++) {
//           final x = colX + 60 + (opt * 25);
//           _drawBubble(canvas, x, y, false);
//         }
//       }
//     }
//
//     // Instructions
//     _drawText(
//       canvas,
//       "INSTRUCTIONS: Use HB pencil only. Completely darken the bubble. Erase completely to change.",
//       A4_WIDTH / 2,
//       startY + 340,
//       TextStyle(
//         fontSize: 9,
//         fontWeight: FontWeight.w500,
//         color: accentColor,
//         fontStyle: FontStyle.italic,
//       ),
//       TextAlign.center,
//     );
//   }
//
//   static void _drawFooterSection(Canvas canvas) {
//     final startY = A4_HEIGHT - MARGIN - 80;
//     final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;
//
//     // Section border
//     _drawRoundedRect(
//       canvas,
//       Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 70),
//       4.0,
//       borderColor,
//       false,
//     );
//
//     // Signature fields
//     final signatures = [
//       "Student's Signature",
//       "Invigilator's Signature",
//       "Examiner's Signature"
//     ];
//
//     final fieldWidth = (sectionWidth - 40) / 3;
//     for (int i = 0; i < signatures.length; i++) {
//       final x = MARGIN + 20 + (i * fieldWidth);
//
//       _drawText(
//         canvas,
//         signatures[i],
//         x + fieldWidth / 2,
//         startY + 15,
//         TextStyle(
//           fontSize: 10,
//           fontWeight: FontWeight.w600,
//           color: textColor,
//         ),
//         TextAlign.center,
//       );
//
//       // Signature line
//       final linePaint = Paint()
//         ..color = borderColor
//         ..strokeWidth = 0.8;
//
//       canvas.drawLine(
//         Offset(x + 10, startY + 40),
//         Offset(x + fieldWidth - 10, startY + 40),
//         linePaint,
//       );
//
//       // Date label
//       _drawText(
//         canvas,
//         "Date:",
//         x + 15,
//         startY + 50,
//         TextStyle(
//           fontSize: 9,
//           color: textColor,
//         ),
//         TextAlign.left,
//       );
//
//       // Date line
//       canvas.drawLine(
//         Offset(x + 35, startY + 55),
//         Offset(x + 80, startY + 55),
//         linePaint,
//       );
//     }
//   }
//
//   // Helper Methods
//   static void _drawText(Canvas canvas, String text, double x, double y, TextStyle style, TextAlign align) {
//     final textPainter = TextPainter(
//       text: TextSpan(text: text, style: style),
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout();
//
//     double offsetX = x;
//     if (align == TextAlign.center) {
//       offsetX -= textPainter.width / 2;
//     } else if (align == TextAlign.right) {
//       offsetX -= textPainter.width;
//     }
//
//     textPainter.paint(canvas, Offset(offsetX, y - textPainter.height / 2));
//   }
//
//   static void _drawRoundedRect(Canvas canvas, Rect rect, double radius, Color color, bool fill) {
//     final paint = Paint()
//       ..color = color
//       ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
//       ..strokeWidth = 1.5;
//
//     final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
//     canvas.drawRRect(rrect, paint);
//   }
//
//   static void _drawBubble(Canvas canvas, double x, double y, bool filled) {
//     final borderPaint = Paint()
//       ..color = borderColor
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.2;
//
//     final fillPaint = Paint()
//       ..color = primaryColor
//       ..style = PaintingStyle.fill;
//
//     canvas.drawCircle(Offset(x + BUBBLE_RADIUS, y + BUBBLE_RADIUS), BUBBLE_RADIUS, borderPaint);
//
//     if (filled) {
//       canvas.drawCircle(Offset(x + BUBBLE_RADIUS, y + BUBBLE_RADIUS), BUBBLE_RADIUS - 1.5, fillPaint);
//     }
//   }
//
//   static void _drawBubbleWithLabel(Canvas canvas, double x, double y, String label, bool filled) {
//     _drawBubble(canvas, x, y, filled);
//
//     _drawText(
//       canvas,
//       label,
//       x + BUBBLE_RADIUS,
//       y + BUBBLE_RADIUS * 2 + 8,
//       TextStyle(
//         fontSize: 10,
//         fontWeight: FontWeight.w500,
//         color: textColor,
//       ),
//       TextAlign.center,
//     );
//   }
//
//   static void _drawDigitBubbles(Canvas canvas, double startX, double startY, String value, String label) {
//     final digits = value.split('');
//
//     // Draw digit labels (0-9)
//     for (int i = 0; i < 10; i++) {
//       _drawText(
//         canvas,
//         i.toString(),
//         startX - 10,
//         startY + 5 + (i * 15),
//         TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
//         TextAlign.center,
//       );
//     }
//
//     // Draw bubbles for each digit position
//     for (int pos = 0; pos < digits.length; pos++) {
//       final posX = startX + 15 + (pos * 20);
//
//       // Position number
//       _drawText(
//         canvas,
//         (pos + 1).toString(),
//         posX + SMALL_BUBBLE_RADIUS,
//         startY - 10,
//         TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
//         TextAlign.center,
//       );
//
//       // Bubbles for digits 0-9
//       for (int digit = 0; digit < 10; digit++) {
//         final digitY = startY + 5 + (digit * 15);
//         _drawSmallBubble(canvas, posX, digitY, digits[pos] == digit.toString());
//       }
//     }
//
//     // Label
//     _drawText(
//       canvas,
//       label,
//       startX + (digits.length * 10),
//       startY - 25,
//       TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
//       TextAlign.center,
//     );
//   }
//
//   static void _drawSmallBubble(Canvas canvas, double x, double y, bool filled) {
//     final borderPaint = Paint()
//       ..color = borderColor
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     final fillPaint = Paint()
//       ..color = primaryColor
//       ..style = PaintingStyle.fill;
//
//     canvas.drawCircle(Offset(x + SMALL_BUBBLE_RADIUS, y + SMALL_BUBBLE_RADIUS), SMALL_BUBBLE_RADIUS, borderPaint);
//
//     if (filled) {
//       canvas.drawCircle(Offset(x + SMALL_BUBBLE_RADIUS, y + SMALL_BUBBLE_RADIUS), SMALL_BUBBLE_RADIUS - 1.0, fillPaint);
//     }
//   }
//
//   static void _drawLabeledField(Canvas canvas, double x, double y, String label, String value, double width) {
//     _drawText(
//       canvas,
//       label,
//       x,
//       y,
//       TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
//       TextAlign.left,
//     );
//
//     // Underline for value
//     final linePaint = Paint()
//       ..color = borderColor
//       ..strokeWidth = 0.8;
//
//     canvas.drawLine(
//       Offset(x, y + 17),
//       Offset(x + width, y + 17),
//       linePaint,
//     );
//
//     if (value.isNotEmpty) {
//       _drawText(
//         canvas,
//         value,
//         x + 5,
//         y + 11,
//         TextStyle(fontSize: 10, color: textColor),
//         TextAlign.left,
//       );
//     }
//   }
// }
