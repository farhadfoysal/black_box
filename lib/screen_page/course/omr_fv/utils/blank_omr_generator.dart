import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

enum CornerPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

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
  static const double MARGIN = 10.0;
  static const double BUBBLE_RADIUS = 7;
  static const double SMALL_BUBBLE_RADIUS = 7;

  // Professional color scheme
  static final Color primaryColor = const Color(0xFF2C3E50);
  static final Color secondaryColor = const Color(0xFF34495E);
  static final Color accentColor = const Color(0xFFE74C3C);
  static final Color lightBgColor = const Color(0xFFF8F9FA);
  static final Color borderColor = const Color(0xFF2C3E50);
  static final Color textColor = const Color(0xFF2C3E50);

  // OMR Scanner Symbols
  static const double SCANNER_SYMBOL_SIZE = 25.0;
  static const double CORNER_MARKER_SIZE = 15.0;


  // ===========================================================
  // ADVANCED OMR SCANNER SYMBOLS
  // ===========================================================

  /// Draws the main OMR scanner detection symbol (concentric pattern)
  static void _drawOMRScannerSymbol(Canvas canvas, double x, double y) {
    final center = Offset(x + SCANNER_SYMBOL_SIZE / 2, y + SCANNER_SYMBOL_SIZE / 2);

    // Outer filled square (black)
    final outerSquarePaint = Paint()..color = Colors.black;
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: SCANNER_SYMBOL_SIZE,
        height: SCANNER_SYMBOL_SIZE,
      ),
      outerSquarePaint,
    );

    // Middle white circle
    final middleCirclePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, SCANNER_SYMBOL_SIZE * 0.4, middleCirclePaint);

    // Inner black circle (unfilled - just border)
    final innerCirclePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, SCANNER_SYMBOL_SIZE * 0.25, innerCirclePaint);

    // Crosshair lines for precise alignment
    final crosshairPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - SCANNER_SYMBOL_SIZE * 0.2, center.dy),
      Offset(center.dx + SCANNER_SYMBOL_SIZE * 0.2, center.dy),
      crosshairPaint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - SCANNER_SYMBOL_SIZE * 0.2),
      Offset(center.dx, center.dy + SCANNER_SYMBOL_SIZE * 0.2),
      crosshairPaint,
    );
  }

  /// Draws corner alignment markers for scanner
  static void _drawCornerAlignmentMarker(Canvas canvas, double x, double y, CornerPosition position) {
    final center = Offset(x + CORNER_MARKER_SIZE / 2, y + CORNER_MARKER_SIZE / 2);
    final paint = Paint()..color = Colors.black;

    switch (position) {
      case CornerPosition.topLeft:
      // Draw L-shape
        canvas.drawRect(Rect.fromLTWH(x, y, CORNER_MARKER_SIZE * 0.3, CORNER_MARKER_SIZE), paint);
        canvas.drawRect(Rect.fromLTWH(x, y, CORNER_MARKER_SIZE, CORNER_MARKER_SIZE * 0.3), paint);
        break;
      case CornerPosition.topRight:
        canvas.drawRect(Rect.fromLTWH(x + CORNER_MARKER_SIZE * 0.7, y, CORNER_MARKER_SIZE * 0.3, CORNER_MARKER_SIZE), paint);
        canvas.drawRect(Rect.fromLTWH(x, y, CORNER_MARKER_SIZE, CORNER_MARKER_SIZE * 0.3), paint);
        break;
      case CornerPosition.bottomLeft:
        canvas.drawRect(Rect.fromLTWH(x, y, CORNER_MARKER_SIZE * 0.3, CORNER_MARKER_SIZE), paint);
        canvas.drawRect(Rect.fromLTWH(x, y + CORNER_MARKER_SIZE * 0.7, CORNER_MARKER_SIZE, CORNER_MARKER_SIZE * 0.3), paint);
        break;
      case CornerPosition.bottomRight:
        canvas.drawRect(Rect.fromLTWH(x + CORNER_MARKER_SIZE * 0.7, y, CORNER_MARKER_SIZE * 0.3, CORNER_MARKER_SIZE), paint);
        canvas.drawRect(Rect.fromLTWH(x, y + CORNER_MARKER_SIZE * 0.7, CORNER_MARKER_SIZE, CORNER_MARKER_SIZE * 0.3), paint);
        break;
    }
  }

  /// Draws timing track for scanner synchronization
  static void _drawTimingTrack(Canvas canvas, double startX, double startY, double length, bool horizontal) {
    final paint = Paint()..color = Colors.black;
    const double trackWidth = 2.0;
    const double segmentLength = 8.0;
    const double gapLength = 4.0;

    double position = 0;
    bool drawSegment = true;

    while (position < length) {
      if (drawSegment) {
        if (horizontal) {
          canvas.drawRect(
            Rect.fromLTWH(startX + position, startY, segmentLength, trackWidth),
            paint,
          );
        } else {
          canvas.drawRect(
            Rect.fromLTWH(startX, startY + position, trackWidth, segmentLength),
            paint,
          );
        }
      }
      position += drawSegment ? segmentLength : gapLength;
      drawSegment = !drawSegment;
    }
  }

  /// Draws all OMR scanner detection symbols
  static void _drawScannerSymbols(Canvas canvas) {
    // Main scanner symbols in corners
    _drawOMRScannerSymbol(canvas, MARGIN - 6, MARGIN - 6); // Top-left
    _drawOMRScannerSymbol(canvas, A4_WIDTH - MARGIN + 6 - SCANNER_SYMBOL_SIZE, MARGIN - 6); // Top-right
    _drawOMRScannerSymbol(canvas, MARGIN - 6, A4_HEIGHT - MARGIN + 6 - SCANNER_SYMBOL_SIZE); // Bottom-left
    _drawOMRScannerSymbol(canvas, A4_WIDTH - MARGIN + 6 - SCANNER_SYMBOL_SIZE, A4_HEIGHT - MARGIN + 6 - SCANNER_SYMBOL_SIZE); // Bottom-right

    // Corner alignment markers
    _drawCornerAlignmentMarker(canvas, MARGIN + 0, MARGIN + 110, CornerPosition.topLeft);
    _drawCornerAlignmentMarker(canvas, A4_WIDTH - MARGIN - 0 - CORNER_MARKER_SIZE, MARGIN + 110, CornerPosition.topRight);
    _drawCornerAlignmentMarker(canvas, MARGIN + 0, A4_HEIGHT - MARGIN - 80 - CORNER_MARKER_SIZE, CornerPosition.bottomLeft);
    _drawCornerAlignmentMarker(canvas, A4_WIDTH - MARGIN - 0 - CORNER_MARKER_SIZE, A4_HEIGHT - MARGIN - 80 - CORNER_MARKER_SIZE, CornerPosition.bottomRight);

    // Timing tracks around the edges
    _drawTimingTrack(canvas, MARGIN + 60, MARGIN + 110, A4_WIDTH - 2 * MARGIN - 120, true); // Top
    _drawTimingTrack(canvas, MARGIN + 60, A4_HEIGHT - MARGIN - 85, A4_WIDTH - 2 * MARGIN - 120, true); // Bottom
    _drawTimingTrack(canvas, MARGIN + 0, MARGIN + 140, A4_HEIGHT - 3 * MARGIN - 240, false); // Left
    _drawTimingTrack(canvas, A4_WIDTH - MARGIN - 0, MARGIN + 140, A4_HEIGHT - 3 * MARGIN - 240, false); // Right

    // Add scanner instruction text
    _drawText(
      canvas,
      "OMR SCANNER AREA - KEEP CLEAR",
      A4_WIDTH / 2,
      MARGIN + 115,
      TextStyle(
        fontSize: 8,
        color: Colors.grey,
        fontWeight: FontWeight.bold,
      ),
      TextAlign.center,
    );
  }

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
    // _drawRoundedRect(
    //   canvas,
    //   Rect.fromLTWH(MARGIN, MARGIN, A4_WIDTH - 2 * MARGIN, A4_HEIGHT - 2 * MARGIN),
    //   8.0,
    //   borderColor,
    //   false,
    // );



    // Draw sections
    _drawHeaderSection(canvas, config);
    _drawStudentInfoSection(canvas, config);
    _drawSetSelectionSection(canvas);  // New section
    _drawIdNumberSection(canvas);       // New section
    _drawAnswerGridSection(canvas, config);
    _drawFooterSection(canvas);

    // Draw OMR scanner symbols FIRST (so they're underneath other content)
    _drawScannerSymbols(canvas);

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
      MARGIN + 10,
      TextStyle(
        fontSize: 15,
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
      MARGIN + 23,
      TextStyle(
        fontSize: 10,
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
      MARGIN + 35,
      TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        letterSpacing: 1.0,
      ),
      TextAlign.center,
    );

    // Decorative line
    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX - 120, MARGIN + 42),
      Offset(centerX + 120, MARGIN + 42),
      linePaint,
    );
  }

  static void _drawStudentInfoSection(Canvas canvas, BlankOMRConfig config) {
    final startY = MARGIN + 46;
    final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;

    // Section background
    final bgPaint = Paint()..color = lightBgColor;
    canvas.drawRect(
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 57),
      bgPaint,
    );

    // Section border
    _drawRoundedRect(
      canvas,
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 57),
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
    _drawBlankField(canvas, MARGIN + 20, startY + 30, "Name:", 200);
    _drawBlankField(canvas, MARGIN + 240, startY + 30, "Roll No:", 100);
    _drawBlankField(canvas, MARGIN + 360, startY + 30, "Class:", 80);
    _drawBlankField(canvas, MARGIN + 460, startY + 30, "Date:", 90);
  }

  // New method for Set Selection Section
  static void _drawSetSelectionSection(Canvas canvas) {
    final startY = MARGIN + 130;

    _drawText(
      canvas,
      "SET NUMBER:",
      MARGIN + 300,
      startY + 2,
      TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      TextAlign.left,
    );

    // Set number bubbles (1-4)
    final setNumbers = ["1", "2", "3", "4"];
    for (int i = 0; i < setNumbers.length; i++) {
      final x = MARGIN + 400 + (i * 50);
      _drawBubbleWithLabel(canvas, x, startY - 5, setNumbers[i], false); // All bubbles empty
    }
  }

  // New method for ID Number Section
  static void _drawIdNumberSection(Canvas canvas) {
    final startY = MARGIN + 160;

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
    _drawBlankDigitEntrySection(
      canvas,
      offsetX: MARGIN + 25,
      offsetY: startY + 10,
      totalDigits: 10,
      label: "Student ID",
    );

    // ==== Draw Mobile number section (11 digits) ====
    _drawBlankDigitEntrySection(
      canvas,
      offsetX: MARGIN + 300,
      offsetY: startY + 10,
      totalDigits: 11,
      label: "Mobile Number",
    );
  }

  // New method for drawing blank digit entry sections
  static void _drawBlankDigitEntrySection(
      Canvas canvas, {
        required double offsetX,
        required double offsetY,
        required int totalDigits,
        required String label,
      }) {
    const double digitBoxSize = 20.0;
    const double bubbleRadius = 6.5;
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
          bubbleY - 0,
          TextStyle(fontSize: 7, color: textColor),
          TextAlign.center,
        );
      }
    }
  }

  static void _drawAnswerGridSection(Canvas canvas, BlankOMRConfig config) {
    final startY = MARGIN + 390;
    final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;
    final sectionHeight = 337;

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
    _drawAnswerGrid(canvas, startY + 30, config.numberOfQuestions);
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

        final y = startY + (i * 22);

        // Alternate row background
        if (i % 2 == 0) {
          final rowBgPaint = Paint()..color = Colors.grey.withOpacity(0.05);
          canvas.drawRect(
            Rect.fromLTWH(colX - 5, y - 5, columnWidth - 10, 20),
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
      startY + 340,
      TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        color: accentColor,
      ),
      TextAlign.center,
    );
  }

  static void _drawFooterSection(Canvas canvas) {
    final startY = A4_HEIGHT - MARGIN - 70;
    final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;

    // Section border
    _drawRoundedRect(
      canvas,
      Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 58),
      4.0,
      borderColor,
      false,
    );

    // Important note section (continued)
    final noteBgPaint = Paint()..color = accentColor.withOpacity(0.1);
    canvas.drawRect(
      Rect.fromLTWH(MARGIN + 20, startY + 55, sectionWidth - 20, 15),
      noteBgPaint,
    );

    _drawText(
      canvas,
      "IMPORTANT: Do not fold or damage this sheet • Ensure all marks are within the bubbles",
      A4_WIDTH / 2,
      startY + 65,
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
        startY + 50,
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
        Offset(x + 20, startY + 45),
        Offset(x + fieldWidth - 20, startY + 45),
        linePaint,
      );
    }
  }

  // Helper Methods
  static void _drawText(Canvas canvas, String text, double x, double y, TextStyle style, TextAlign align) {
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

    textPainter.paint(canvas, Offset(offsetX, offsetY - textPainter.height / 2));
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

  static void _drawBubbleWithLabel(Canvas canvas, double x, double y, String label, bool filled) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final fillPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Draw bubble
    canvas.drawCircle(Offset(x + BUBBLE_RADIUS, y + BUBBLE_RADIUS), BUBBLE_RADIUS, borderPaint);

    if (filled) {
      canvas.drawCircle(Offset(x + BUBBLE_RADIUS, y + BUBBLE_RADIUS), BUBBLE_RADIUS - 1.5, fillPaint);
    }

    // Draw label below bubble
    _drawText(
      canvas,
      label,
      x + BUBBLE_RADIUS,
      y + BUBBLE_RADIUS * 2 + 8,
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
      Offset(x + 5, y + 22),
      Offset(x + width, y + 22),
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
      final tempFile = File('${tempDir.path}/_WafiSphere_blank_omr_${DateTime.now().millisecondsSinceEpoch}.png');
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

    // Trigger Android media scanner
    if (Platform.isAndroid) {
      try {
        await Process.run('am', ['broadcast', '-a', 'android.intent.action.MEDIA_SCANNER_SCAN_FILE', '-d', 'file://${file.path}']);
      } catch (_) {
        // Ignore if unavailable
      }
    }

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

  // Batch generation support
  static Future<List<File>> generateBatchBlankOMRSheets(List<BlankOMRConfig> configs) async {
    final List<File> generatedFiles = [];

    for (final config in configs) {
      try {
        final file = await generateBlankOMRSheet(config);
        generatedFiles.add(file);
      } catch (e) {
        print('Error generating blank OMR for ${config.examName}: $e');
      }
    }

    return generatedFiles;
  }
}

// Example usage widget
class BlankOMRGeneratorExample extends StatelessWidget {
  final BlankOMRConfig config = BlankOMRConfig(
    examName: "FINAL EXAMINATION 2024",
    subjectName: "Mathematics",
    numberOfQuestions: 50,
    setNumber: 1,
    examDate: DateTime.now(),
    instructions: "Fill the bubbles completely with HB pencil. Do not use pen.",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blank OMR Generator'),
        backgroundColor: BlankOMRGenerator.primaryColor,
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
                color: BlankOMRGenerator.lightBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BlankOMRGenerator.borderColor),
              ),
              child: Icon(
                Icons.description_outlined,
                size: 80,
                color: BlankOMRGenerator.primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Blank OMR Sheet Generator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Generate blank OMR sheets with student ID,\nmobile number, and answer bubbles.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final file = await BlankOMRGenerator.generateBlankOMRSheet(config);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Blank OMR Sheet Generated!\nSaved to: ${file.path}'),
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
              icon: const Icon(Icons.create_new_folder),
              label: const Text('Generate Blank OMR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BlankOMRGenerator.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
                      // Generate multiple blank OMR sheets
                      final configs = List.generate(4, (index) => BlankOMRConfig(
                        examName: "FINAL EXAMINATION 2024",
                        subjectName: "Mathematics",
                        numberOfQuestions: 50,
                        setNumber: index + 1,
                        examDate: DateTime.now(),
                        instructions: "Fill the bubbles completely with HB pencil.",
                      ));

                      final files = await BlankOMRGenerator.generateBatchBlankOMRSheets(configs);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Generated ${files.length} Blank OMR Sheets!'),
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
                  label: const Text('Generate Sets 1-4'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BlankOMRGenerator.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final imageBytes = await BlankOMRGenerator._generateOMRImage(config);
                      await BlankOMRGenerator.printBlankOMRSheet(imageBytes);

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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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












// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:gal/gal.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:printing/printing.dart';
//
// class BlankOMRConfig {
//   final String examName;
//   final String subjectName;
//   final int numberOfQuestions;
//   final int setNumber;
//   final DateTime examDate;
//   final String? instructions;
//
//   BlankOMRConfig({
//     required this.examName,
//     required this.subjectName,
//     required this.numberOfQuestions,
//     required this.setNumber,
//     required this.examDate,
//     this.instructions,
//   });
// }
//
// class BlankOMRGenerator {
//   static const double A4_WIDTH = 595.0;
//   static const double A4_HEIGHT = 842.0;
//   static const double MARGIN = 20.0;
//   static const double BUBBLE_RADIUS = 7;
//
//   // Professional color scheme
//   static final Color primaryColor = const Color(0xFF2C3E50);
//   static final Color secondaryColor = const Color(0xFF34495E);
//   static final Color accentColor = const Color(0xFFE74C3C);
//   static final Color lightBgColor = const Color(0xFFF8F9FA);
//   static final Color borderColor = const Color(0xFF2C3E50);
//   static final Color textColor = const Color(0xFF2C3E50);
//
//   static Future<File> generateBlankOMRSheet(BlankOMRConfig config) async {
//     try {
//       final Uint8List imageBytes = await _generateOMRImage(config);
//       final file = await _saveOMRSheetWithGal(imageBytes, config);
//       print('✅ Blank OMR Sheet generated successfully.');
//       return file;
//     } catch (e) {
//       print('❌ Error generating blank OMR sheet: $e');
//       rethrow;
//     }
//   }
//
//   static Future<Uint8List> _generateOMRImage(BlankOMRConfig config) async {
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
//       borderColor,
//       false,
//     );
//
//     // Draw sections
//     _drawHeaderSection(canvas, config);
//     _drawStudentInfoSection(canvas, config);
//     _drawAnswerGridSection(canvas, config);
//     _drawFooterSection(canvas);
//
//     final picture = recorder.endRecording();
//     final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
//     return byteData!.buffer.asUint8List();
//   }
//
//   static void _drawHeaderSection(Canvas canvas, BlankOMRConfig config) {
//     final centerX = A4_WIDTH / 2;
//
//     // Institution/Exam name
//     _drawText(
//       canvas,
//       config.examName.toUpperCase(),
//       centerX,
//       MARGIN + 20,
//       TextStyle(
//         fontSize: 18,
//         fontWeight: FontWeight.bold,
//         color: primaryColor,
//         letterSpacing: 1.2,
//       ),
//       TextAlign.center,
//     );
//
//     // Subject name
//     _drawText(
//       canvas,
//       config.subjectName,
//       centerX,
//       MARGIN + 40,
//       TextStyle(
//         fontSize: 14,
//         fontWeight: FontWeight.w600,
//         color: secondaryColor,
//       ),
//       TextAlign.center,
//     );
//
//     // Exam type subtitle
//     _drawText(
//       canvas,
//       "MULTIPLE CHOICE ANSWER SHEET",
//       centerX,
//       MARGIN + 58,
//       TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w600,
//         color: secondaryColor,
//         letterSpacing: 1.0,
//       ),
//       TextAlign.center,
//     );
//
//     // Set number and date
//     _drawText(
//       canvas,
//       "SET ${config.setNumber} | Date: ${_formatDate(config.examDate)}",
//       centerX,
//       MARGIN + 75,
//       TextStyle(
//         fontSize: 11,
//         fontWeight: FontWeight.w500,
//         color: textColor,
//       ),
//       TextAlign.center,
//     );
//
//     // Decorative line
//     final linePaint = Paint()
//       ..color = accentColor
//       ..strokeWidth = 2
//       ..style = PaintingStyle.stroke;
//
//     canvas.drawLine(
//       Offset(centerX - 120, MARGIN + 85),
//       Offset(centerX + 120, MARGIN + 85),
//       linePaint,
//     );
//   }
//
//   static void _drawStudentInfoSection(Canvas canvas, BlankOMRConfig config) {
//     final startY = MARGIN + 95;
//     final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;
//
//     // Section background
//     final bgPaint = Paint()..color = lightBgColor;
//     canvas.drawRect(
//       Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 80),
//       bgPaint,
//     );
//
//     // Section border
//     _drawRoundedRect(
//       canvas,
//       Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 80),
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
//       "STUDENT INFORMATION (To be filled by student)",
//       MARGIN + 20,
//       startY + 10,
//       TextStyle(
//         fontSize: 10,
//         fontWeight: FontWeight.bold,
//         color: lightBgColor,
//       ),
//       TextAlign.left,
//     );
//
//     // Student fields
//     _drawBlankField(canvas, MARGIN + 20, startY + 35, "Name:", 200);
//     _drawBlankField(canvas, MARGIN + 240, startY + 35, "Roll No:", 100);
//     _drawBlankField(canvas, MARGIN + 360, startY + 35, "Section:", 80);
//
//     _drawBlankField(canvas, MARGIN + 20, startY + 55, "Student ID:", 150);
//     _drawBlankField(canvas, MARGIN + 190, startY + 55, "Mobile No:", 150);
//     _drawBlankField(canvas, MARGIN + 360, startY + 55, "Class:", 80);
//   }
//
//   static void _drawAnswerGridSection(Canvas canvas, BlankOMRConfig config) {
//     final startY = MARGIN + 185;
//     final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;
//     final sectionHeight = 480;
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
//       Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 25),
//       titleBgPaint,
//     );
//
//     // Section title
//     _drawText(
//       canvas,
//       "ANSWER SECTION - MARK YOUR ANSWERS CLEARLY",
//       A4_WIDTH / 2,
//       startY + 12.5,
//       TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.bold,
//         color: lightBgColor,
//       ),
//       TextAlign.center,
//     );
//
//     // Instructions
//     if (config.instructions != null && config.instructions!.isNotEmpty) {
//       _drawText(
//         canvas,
//         config.instructions!,
//         A4_WIDTH / 2,
//         startY + 35,
//         TextStyle(
//           fontSize: 9,
//           color: accentColor,
//           fontStyle: FontStyle.italic,
//         ),
//         TextAlign.center,
//       );
//     }
//
//     // Draw answer grid
//     _drawAnswerGrid(canvas, startY + 50, config.numberOfQuestions);
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
//       // Draw questions and bubbles
//       for (int i = 0; i < questionsPerColumn; i++) {
//         final questionNum = col * questionsPerColumn + i + 1;
//         if (questionNum > totalQuestions) break;
//
//         final y = startY + 10 + (i * 25);
//
//         // Question number background
//         final qNumBgPaint = Paint()..color = secondaryColor.withOpacity(0.1);
//         canvas.drawRRect(
//           RRect.fromRectAndRadius(
//             Rect.fromLTWH(colX, y - 5, 35, 20),
//             Radius.circular(3),
//           ),
//           qNumBgPaint,
//         );
//
//         // Question number
//         _drawText(
//           canvas,
//           questionNum.toString().padLeft(2, '0'),
//           colX + 17.5,
//           y + 5,
//           TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.bold,
//             color: textColor,
//           ),
//           TextAlign.center,
//         );
//
//         // Answer bubbles
//         for (int opt = 0; opt < 4; opt++) {
//           final x = colX + 45 + (opt * 30);
//           _drawBubbleWithOption(canvas, x, y, options[opt]);
//         }
//       }
//     }
//
//     // Bottom instructions
//     _drawText(
//       canvas,
//       "INSTRUCTIONS: Use HB pencil only • Fill the bubble completely • Erase cleanly to change answer",
//       A4_WIDTH / 2,
//       startY + 410,
//       TextStyle(
//         fontSize: 9,
//         fontWeight: FontWeight.w500,
//         color: accentColor,
//       ),
//       TextAlign.center,
//     );
//   }
//
//   static void _drawFooterSection(Canvas canvas) {
//     final startY = A4_HEIGHT - MARGIN - 100;
//     final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;
//
//     // Section border
//     _drawRoundedRect(
//       canvas,
//       Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 90),
//       4.0,
//       borderColor,
//       false,
//     );
//
//     // Signature fields
//     final signatures = [
//       "Student's Signature",
//       "Invigilator's Signature",
//     ];
//
//     final fieldWidth = (sectionWidth - 40) / 2;
//     for (int i = 0; i < signatures.length; i++) {
//       final x = MARGIN + 30 + (i * fieldWidth);
//
//       _drawText(
//         canvas,
//         signatures[i],
//         x + fieldWidth / 2,
//         startY + 20,
//         TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.w600,
//           color: textColor,
//         ),
//         TextAlign.center,
//       );
//
//       // Signature line
//       final linePaint = Paint()
//         ..color = borderColor
//         ..strokeWidth = 1;
//
//       canvas.drawLine(
//         Offset(x + 20, startY + 45),
//         Offset(x + fieldWidth - 20, startY + 45),
//         linePaint,
//       );
//
//       // Date field
//       _drawText(
//         canvas,
//         "Date: _______________",
//         x + fieldWidth / 2,
//         startY + 65,
//         TextStyle(
//           fontSize: 10,
//           color: textColor,
//         ),
//         TextAlign.center,
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
//   static void _drawBubbleWithOption(Canvas canvas, double x, double y, String option) {
//     final borderPaint = Paint()
//       ..color = borderColor
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.5;
//
//     // Draw circle
//     canvas.drawCircle(Offset(x + BUBBLE_RADIUS, y + BUBBLE_RADIUS), BUBBLE_RADIUS, borderPaint);
//
//     // Draw option letter inside
//     _drawText(
//       canvas,
//       option,
//       x + BUBBLE_RADIUS,
//       y + BUBBLE_RADIUS,
//       TextStyle(
//         fontSize: 10,
//         fontWeight: FontWeight.w600,
//         color: textColor,
//       ),
//       TextAlign.center,
//     );
//   }
//
//   static void _drawBlankField(Canvas canvas, double x, double y, String label, double width) {
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
//       ..strokeWidth = 1;
//
//     canvas.drawLine(
//       Offset(x + 40, y + 10),
//       Offset(x + width, y + 10),
//       linePaint,
//     );
//   }
//
//   static String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }
//
//   static Future<File> _saveOMRSheetWithGal(Uint8List bytes, BlankOMRConfig config) async {
//     await _requestGalleryPermissions();
//
//     try {
//       // Create temporary file for gal package
//       final tempDir = await getTemporaryDirectory();
//       final tempFile = File('${tempDir.path}/_temp_blank_omr_${DateTime.now().millisecondsSinceEpoch}.png');
//       await tempFile.writeAsBytes(bytes);
//
//       // Save to gallery using gal package
//       await Gal.putImage(tempFile.path, album: 'OMR Sheets');
//
//       // Save a permanent copy
//       final permanentFile = await _saveToPublicPictures(bytes, config);
//
//       // Cleanup temp file
//       await tempFile.delete();
//
//       print('✅ Saved to gallery & Pictures folder');
//       return permanentFile;
//     } catch (e) {
//       print('⚠️ Gal save failed: $e');
//       return await _saveToPublicPictures(bytes, config);
//     }
//   }
//
//   static Future<File> _saveToPublicPictures(Uint8List bytes, BlankOMRConfig config) async {
//     final timestamp = DateTime.now().millisecondsSinceEpoch;
//     final fileName = 'Blank_OMR_${_sanitizeFileName(config.examName)}_Set${config.setNumber}_$timestamp.png';
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
//     return file;
//   }
//
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
//   static String _sanitizeFileName(String name) {
//     final sanitized = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').replaceAll(RegExp(r'\s+'), '_');
//     return sanitized.length > 50 ? sanitized.substring(0, 50) : sanitized;
//   }
//
//   // Print functionality
//   static Future<void> printBlankOMRSheet(Uint8List imageBytes) async {
//     try {
//       await Printing.layoutPdf(onLayout: (format) async => imageBytes);
//     } catch (e) {
//       print('❌ Error printing OMR sheet: $e');
//     }
//   }
// }