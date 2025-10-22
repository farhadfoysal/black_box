import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

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
  static final Color secondaryColor = const Color(0xFF34495E); // Slightly lighter
  static final Color accentColor = const Color(0xFFE74C3C); // Red for important elements
  static final Color lightBgColor = const Color(0xFFF8F9FA); // Light gray background
  static final Color borderColor = const Color(0xFF2C3E50);
  static final Color textColor = const Color(0xFF2C3E50);

  // static Future<File> generateOMRSheet(OMRExamConfig config) async {
  //   final recorder = PictureRecorder();
  //   final canvas = Canvas(recorder);
  //   final paint = Paint();
  //
  //   // Draw white background
  //   canvas.drawRect(
  //     Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT),
  //     paint..color = Colors.white,
  //   );
  //
  //   // Draw main border
  //   _drawRoundedRect(
  //     canvas,
  //     Rect.fromLTWH(MARGIN, MARGIN, A4_WIDTH - 2 * MARGIN, A4_HEIGHT - 2 * MARGIN),
  //     8.0,
  //     borderColor,
  //     false,
  //   );
  //
  //   // Draw all sections
  //   _drawHeaderSection(canvas, config);
  //   _drawStudentInfoSection(canvas, config);
  //   _drawSetSelectionSection(canvas, config);
  //   _drawIdNumberSection(canvas, config);
  //   _drawAnswerGridSection(canvas, config);
  //   _drawFooterSection(canvas);
  //
  //   final picture = recorder.endRecording();
  //   final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
  //   final byteData = await image.toByteData(format: ImageByteFormat.png);
  //   final bytes = byteData!.buffer.asUint8List();
  //
  //   final directory = await getTemporaryDirectory();
  //   final file = File('${directory.path}/professional_omr_${DateTime.now().millisecondsSinceEpoch}.png');
  //   await file.writeAsBytes(bytes);
  //
  //   return file;
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
      Colors.black,
      false,
    );

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
  }

  // ===========================================================
  // SAVE TO GALLERY + PERMANENT STORAGE
  // ===========================================================
  static Future<File> _saveOMRSheetWithGal(Uint8List bytes, OMRExamConfig config) async {
    await _requestGalleryPermissions();

    try {
      // 1️⃣ Attempt to save using Gal (safest)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/_temp_omr_${DateTime.now().millisecondsSinceEpoch}.png');
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
  static Future<File> _saveToPublicPictures(Uint8List bytes, OMRExamConfig config) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'OMR_${_sanitizeFileName(config.examName)}_$timestamp.png';

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
        await Process.run('am', ['broadcast', '-a', 'android.intent.action.MEDIA_SCANNER_SCAN_FILE', '-d', 'file://${file.path}']);
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
    final sanitized = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').replaceAll(RegExp(r'\s+'), '_');
    return sanitized.length > 50 ? sanitized.substring(0, 50) : sanitized;
  }



  // static Future<File> generateOMRSheet(OMRExamConfig config) async {
  //   try {
  //     // Generate the OMR sheet image
  //     final Uint8List imageBytes = await _generateOMRImage(config);
  //
  //     // Save to gallery and local storage
  //     return await _saveOMRSheetWithGal(imageBytes, config);
  //
  //   } catch (e) {
  //     print('Error generating OMR sheet: $e');
  //     rethrow;
  //   }
  // }
  //
  // static Future<Uint8List> _generateOMRImage(OMRExamConfig config) async {
  //   final recorder = PictureRecorder();
  //   final canvas = Canvas(recorder);
  //   final paint = Paint();
  //
  //   // Draw white background
  //   canvas.drawRect(
  //     Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT),
  //     paint..color = Colors.white,
  //   );
  //
  //   // Draw main border
  //   _drawRoundedRect(
  //     canvas,
  //     Rect.fromLTWH(MARGIN, MARGIN, A4_WIDTH - 2 * MARGIN, A4_HEIGHT - 2 * MARGIN),
  //     8.0,
  //     Colors.black,
  //     false,
  //   );
  //
  //   // Draw all sections (your existing methods)
  //   _drawHeaderSection(canvas, config);
  //   _drawStudentInfoSection(canvas, config);
  //   _drawSetSelectionSection(canvas, config);
  //   _drawIdNumberSection(canvas, config);
  //   _drawAnswerGridSection(canvas, config);
  //   _drawFooterSection(canvas);
  //
  //   // Convert to image bytes
  //   final picture = recorder.endRecording();
  //   final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
  //   final byteData = await image.toByteData(format: ImageByteFormat.png);
  //   return byteData!.buffer.asUint8List();
  // }
  //
  // static Future<File> _saveOMRSheetWithGal(Uint8List bytes, OMRExamConfig config) async {
  //   try {
  //     // Request permissions first
  //     await _requestGalleryPermissions();
  //
  //     // Create temporary file for gal package
  //     final tempDir = await getTemporaryDirectory();
  //     final tempFile = File('${tempDir.path}/_temp_omr_${DateTime.now().millisecondsSinceEpoch}.png');
  //     await tempFile.writeAsBytes(bytes);
  //
  //     // Save to gallery using gal package
  //     await Gal.putImage(tempFile.path, album: 'OMR Sheets');
  //
  //     // Also save to app's permanent storage with proper naming
  //     final permanentFile = await _saveToAppDirectory(bytes, config);
  //
  //     // Clean up temporary file
  //     await tempFile.delete();
  //
  //     print('OMR Sheet saved successfully to gallery and local storage');
  //     return permanentFile;
  //
  //   } catch (e) {
  //     print('Error saving with gal: $e');
  //     // Fallback: save only to app directory
  //     return await _saveToAppDirectory(bytes, config);
  //   }
  // }
  //
  // static Future<File> _saveToAppDirectory(Uint8List bytes, OMRExamConfig config) async {
  //   // Create meaningful filename
  //   final timestamp = DateTime.now().millisecondsSinceEpoch;
  //   final fileName = 'OMR_${_sanitizeFileName(config.examName)}_${config.examName}_$timestamp.png';
  //
  //   // Save to app documents directory
  //   final appDir = await getApplicationDocumentsDirectory();
  //   final omrSheetsDir = Directory('${appDir.path}/OMR_Sheets');
  //   await omrSheetsDir.create(recursive: true);
  //
  //   final permanentFile = File('${omrSheetsDir.path}/$fileName');
  //   await permanentFile.writeAsBytes(bytes);
  //
  //   return permanentFile;
  // }
  //
  // static Future<void> _requestGalleryPermissions() async {
  //   if (Platform.isAndroid) {
  //     // For Android, request storage permission
  //     final status = await Permission.storage.status;
  //     if (!status.isGranted) {
  //       final result = await Permission.storage.request();
  //       if (!result.isGranted) {
  //         throw Exception('Storage permission denied');
  //       }
  //     }
  //   } else if (Platform.isIOS) {
  //     // For iOS, request photos permission
  //     final status = await Permission.photos.status;
  //     if (!status.isGranted) {
  //       final result = await Permission.photos.request();
  //       if (!result.isGranted) {
  //         throw Exception('Photos permission denied');
  //       }
  //     }
  //   }
  //   // For other platforms, no permission needed
  // }
  //
  // static String _sanitizeFileName(String name) {
  //   // Remove invalid filename characters
  //   return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
  //       .replaceAll(RegExp(r'\s+'), '_')
  //       .substring(0, name.length < 50 ? name.length : 50);
  // }

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
      TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        // color: Colors.amber,
        color: lightBgColor,
      ),
      TextAlign.left,
    );


    // Student Name field
    _drawLabeledField(canvas, MARGIN + 20, startY + 30, "Student Name:", config.studentName, 200);

    // Class field
    _drawLabeledField(canvas, MARGIN + 250, startY + 30, "Class:", config.className, 120);

    // Date field
    final dateStr = "${config.examDate.day}/${config.examDate.month}/${config.examDate.year}";
    _drawLabeledField(canvas, MARGIN + 400, startY + 30, "Date:", dateStr, 120);
  }

  static void _drawSetSelectionSection(Canvas canvas, OMRExamConfig config) {
    final startY = MARGIN + 110;

    _drawText(
      canvas,
      "SET NUMBER:",
      MARGIN + 20,
      startY,
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
      final x = MARGIN + 120 + (i * 80);
      _drawBubbleWithLabel(canvas, x, startY - 5, setNumbers[i], config.setNumber == i + 1);
    }
  }

  static void _drawIdNumberSection(Canvas canvas, OMRExamConfig config) {
    final startY = MARGIN + 140;
    const double digitBoxSize = 20.0;
    const double bubbleRadius = 6.0;
    const double bubbleSpacing = 18.0;
    const double columnSpacing = 25.0;

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
          canvas.drawCircle(Offset(bubbleX, bubbleY), bubbleRadius - 1.5, fillPaint);
        }
      }
    }
  }

  /// Generic text drawer helper
  // static void _drawText(Canvas canvas, String text, double x, double y,
  //     TextStyle style, TextAlign align) {
  //   final textPainter = TextPainter(
  //     text: TextSpan(text: text, style: style),
  //     textAlign: align,
  //     textDirection: TextDirection.ltr,
  //   );
  //   textPainter.layout();
  //   Offset offset;
  //   switch (align) {
  //     case TextAlign.center:
  //       offset = Offset(x - textPainter.width / 2, y - textPainter.height / 2);
  //       break;
  //     case TextAlign.right:
  //       offset = Offset(x - textPainter.width, y);
  //       break;
  //     default:
  //       offset = Offset(x, y);
  //   }
  //   textPainter.paint(canvas, offset);
  // }


  // static void _drawIdNumberSection(Canvas canvas, OMRExamConfig config) {
  //   final startY = MARGIN + 150;
  //
  //   // Student ID section
  //   _drawText(
  //     canvas,
  //     "STUDENT ID NUMBER:",
  //     MARGIN + 20,
  //     startY,
  //     TextStyle(
  //       fontSize: 11,
  //       fontWeight: FontWeight.bold,
  //       color: textColor,
  //     ),
  //     TextAlign.left,
  //   );
  //
  //   // Student ID bubbles (10 digits)
  //   _drawDigitBubbles(canvas, MARGIN + 20, startY + 20, config.studentId.padLeft(10, '0'), "Student ID");
  //
  //   // Mobile Number section
  //   _drawText(
  //     canvas,
  //     "MOBILE NUMBER:",
  //     MARGIN + 300,
  //     startY,
  //     TextStyle(
  //       fontSize: 11,
  //       fontWeight: FontWeight.bold,
  //       color: textColor,
  //     ),
  //     TextAlign.left,
  //   );
  //
  //   // Mobile number bubbles (11 digits)
  //   _drawDigitBubbles(canvas, MARGIN + 300, startY + 20, config.mobileNumber.padLeft(11, '0'), "Mobile");
  // }

  static void _drawAnswerGridSection(Canvas canvas, OMRExamConfig config) {
    final startY = MARGIN + 362;
    final sectionWidth = A4_WIDTH - 2 * MARGIN - 20;
    final sectionHeight = 365;

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
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: lightBgColor,
      ),
      TextAlign.center,
    );


    // Draw answer grid with 3 columns
    _drawAnswerGrid(canvas, startY + 35, config.numberOfQuestions);
  }

  static void _drawAnswerGrid(Canvas canvas, double startY, int totalQuestions) {
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
      "Examiner's Signature"
    ];

    final fieldWidth = (sectionWidth - 40) / 3;
    for (int i = 0; i < signatures.length; i++) {
      final x = MARGIN + 20 + (i * fieldWidth);

      _drawText(
        canvas,
        signatures[i],
        x + fieldWidth / 2,
        startY + 15,
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
        TextStyle(
          fontSize: 9,
          color: textColor,
        ),
        TextAlign.left,
      );

      // Date line
      canvas.drawLine(
        Offset(x + 35, startY + 55),
        Offset(x + 80, startY + 55),
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

  static void _drawBubble(Canvas canvas, double x, double y, bool filled) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final fillPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x + BUBBLE_RADIUS, y + BUBBLE_RADIUS), BUBBLE_RADIUS, borderPaint);

    if (filled) {
      canvas.drawCircle(Offset(x + BUBBLE_RADIUS, y + BUBBLE_RADIUS), BUBBLE_RADIUS - 1.5, fillPaint);
    }
  }

  static void _drawBubbleWithLabel(Canvas canvas, double x, double y, String label, bool filled) {
    _drawBubble(canvas, x, y, filled);

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

  static void _drawDigitBubbles(Canvas canvas, double startX, double startY, String value, String label) {
    final digits = value.split('');

    // Draw digit labels (0-9)
    for (int i = 0; i < 10; i++) {
      _drawText(
        canvas,
        i.toString(),
        startX - 10,
        startY + 5 + (i * 15),
        TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
        TextAlign.center,
      );
    }

    // Draw bubbles for each digit position
    for (int pos = 0; pos < digits.length; pos++) {
      final posX = startX + 15 + (pos * 20);

      // Position number
      _drawText(
        canvas,
        (pos + 1).toString(),
        posX + SMALL_BUBBLE_RADIUS,
        startY - 10,
        TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
        TextAlign.center,
      );

      // Bubbles for digits 0-9
      for (int digit = 0; digit < 10; digit++) {
        final digitY = startY + 5 + (digit * 15);
        _drawSmallBubble(canvas, posX, digitY, digits[pos] == digit.toString());
      }
    }

    // Label
    _drawText(
      canvas,
      label,
      startX + (digits.length * 10),
      startY - 25,
      TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      TextAlign.center,
    );
  }

  static void _drawSmallBubble(Canvas canvas, double x, double y, bool filled) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x + SMALL_BUBBLE_RADIUS, y + SMALL_BUBBLE_RADIUS), SMALL_BUBBLE_RADIUS, borderPaint);

    if (filled) {
      canvas.drawCircle(Offset(x + SMALL_BUBBLE_RADIUS, y + SMALL_BUBBLE_RADIUS), SMALL_BUBBLE_RADIUS - 1.0, fillPaint);
    }
  }

  static void _drawLabeledField(Canvas canvas, double x, double y, String label, String value, double width) {
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
      Offset(x, y + 17),
      Offset(x + width, y + 17),
      linePaint,
    );

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
    correctAnswers: List.generate(50, (index) => "A"),
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
              'Generates A4 size OMR sheets with student information,\nanswer bubbles for 50 questions, and signature fields.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final file = await ProfessionalOMRGenerator.generateOMRSheet(config);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Professional OMR Sheet Generated!\nSaved to: ${file.path}'),
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
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
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
//   static Future<File> generateOMRSheet(OMRExamConfig config) async {
//     try {
//       // Generate the OMR sheet image
//       final Uint8List imageBytes = await _generateOMRImage(config);
//
//       // Save to gallery and local storage
//       return await _saveOMRSheetWithGal(imageBytes, config);
//
//     } catch (e) {
//       print('Error generating OMR sheet: $e');
//       rethrow;
//     }
//   }
//
//   static Future<Uint8List> _generateOMRImage(OMRExamConfig config) async {
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//     final paint = Paint();
//
//     // Draw white background
//     canvas.drawRect(
//       Rect.fromLTWH(0, 0, A4_WIDTH, A4_HEIGHT),
//       paint..color = Colors.white,
//     );
//
//     // Draw main border
//     _drawRoundedRect(
//       canvas,
//       Rect.fromLTWH(MARGIN, MARGIN, A4_WIDTH - 2 * MARGIN, A4_HEIGHT - 2 * MARGIN),
//       8.0,
//       Colors.black,
//       false,
//     );
//
//     // Draw all sections (your existing methods)
//     _drawHeaderSection(canvas, config);
//     _drawStudentInfoSection(canvas, config);
//     _drawSetSelectionSection(canvas, config);
//     _drawIdNumberSection(canvas, config);
//     _drawAnswerGridSection(canvas, config);
//     _drawFooterSection(canvas);
//
//     // Convert to image bytes
//     final picture = recorder.endRecording();
//     final image = await picture.toImage(A4_WIDTH.toInt(), A4_HEIGHT.toInt());
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
//     return byteData!.buffer.asUint8List();
//   }
//
//   static Future<File> _saveOMRSheetWithGal(Uint8List bytes, OMRExamConfig config) async {
//     try {
//       // Request permissions first
//       await _requestGalleryPermissions();
//
//       // Create temporary file for gal package
//       final tempDir = await getTemporaryDirectory();
//       final tempFile = File('${tempDir.path}/_temp_omr_${DateTime.now().millisecondsSinceEpoch}.png');
//       await tempFile.writeAsBytes(bytes);
//
//       // Save to gallery using gal package
//       await Gal.putImage(tempFile.path, album: 'OMR Sheets');
//
//       // Also save to app's permanent storage with proper naming
//       final permanentFile = await _saveToAppDirectory(bytes, config);
//
//       // Clean up temporary file
//       await tempFile.delete();
//
//       print('OMR Sheet saved successfully to gallery and local storage');
//       return permanentFile;
//
//     } catch (e) {
//       print('Error saving with gal: $e');
//       // Fallback: save only to app directory
//       return await _saveToAppDirectory(bytes, config);
//     }
//   }
//
//   static Future<File> _saveToAppDirectory(Uint8List bytes, OMRExamConfig config) async {
//     // Create meaningful filename
//     final timestamp = DateTime.now().millisecondsSinceEpoch;
//     final fileName = 'OMR_${_sanitizeFileName(config.examName)}_${config.examName}_$timestamp.png';
//
//     // Save to app documents directory
//     final appDir = await getApplicationDocumentsDirectory();
//     final omrSheetsDir = Directory('${appDir.path}/OMR_Sheets');
//     await omrSheetsDir.create(recursive: true);
//
//     final permanentFile = File('${omrSheetsDir.path}/$fileName');
//     await permanentFile.writeAsBytes(bytes);
//
//     return permanentFile;
//   }
//
//   static Future<void> _requestGalleryPermissions() async {
//     if (Platform.isAndroid) {
//       // For Android, request storage permission
//       final status = await Permission.storage.status;
//       if (!status.isGranted) {
//         final result = await Permission.storage.request();
//         if (!result.isGranted) {
//           throw Exception('Storage permission denied');
//         }
//       }
//     } else if (Platform.isIOS) {
//       // For iOS, request photos permission
//       final status = await Permission.photos.status;
//       if (!status.isGranted) {
//         final result = await Permission.photos.request();
//         if (!result.isGranted) {
//           throw Exception('Photos permission denied');
//         }
//       }
//     }
//     // For other platforms, no permission needed
//   }
//
//   static String _sanitizeFileName(String name) {
//     // Remove invalid filename characters
//     return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
//         .replaceAll(RegExp(r'\s+'), '_')
//         .substring(0, name.length < 50 ? name.length : 50);
//   }
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
//     final startY = MARGIN + 360;
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
//       Rect.fromLTWH(MARGIN + 10, startY, sectionWidth, 25),
//       titleBgPaint,
//     );
//
//     // Section title
//     _drawText(
//       canvas,
//       "ANSWER GRID - MARK YOUR ANSWERS CLEARLY",
//       A4_WIDTH / 2,
//       startY + 15,
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
//
// // Usage Example Widget
// class ProfessionalOMRGeneratorExample extends StatelessWidget {
//   final OMRExamConfig config = OMRExamConfig(
//     examName: "PRE-UNIVERSITY FINAL EXAMINATION",
//     numberOfQuestions: 40,
//     setNumber: 2,
//     studentId: "2023001234",
//     mobileNumber: "01712345678",
//     examDate: DateTime.now(),
//     correctAnswers: List.generate(50, (index) => "A"),
//     studentName: "John Doe",
//     className: "Grade XII - Science",
//   );
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Professional OMR Generator'),
//         backgroundColor: ProfessionalOMRGenerator.primaryColor,
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 200,
//               height: 200,
//               decoration: BoxDecoration(
//                 color: ProfessionalOMRGenerator.lightBgColor,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: ProfessionalOMRGenerator.borderColor),
//               ),
//               child: Icon(
//                 Icons.assignment,
//                 size: 80,
//                 color: ProfessionalOMRGenerator.primaryColor,
//               ),
//             ),
//             const SizedBox(height: 30),
//             const Text(
//               'Professional OMR Answer Sheet Generator',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               'Generates A4 size OMR sheets with student information,\nanswer bubbles for 50 questions, and signature fields.',
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey),
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton.icon(
//               onPressed: () async {
//                 try {
//                   final file = await ProfessionalOMRGenerator.generateOMRSheet(config);
//
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Professional OMR Sheet Generated!\nSaved to: ${file.path}'),
//                       backgroundColor: Colors.green,
//                       duration: const Duration(seconds: 3),
//                     ),
//                   );
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Error generating OMR sheet: $e'),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//               },
//               icon: const Icon(Icons.print),
//               label: const Text('Generate OMR Sheet'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: ProfessionalOMRGenerator.accentColor,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//                 textStyle: const TextStyle(fontSize: 16),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }