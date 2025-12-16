// lib/omr_scanner_service.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// --- Models / Data containers ---
class BubblePosition {
  final double x;
  final double y;
  final double radius;
  final int value; // meaning depends on group (option index, digit, etc.)
  final int? column;
  final int? question;
  BubblePosition(this.x, this.y, this.radius, this.value, {this.column, this.question});
}

class OMRResult {
  int setNumber = 0;
  List<int> studentId = List.filled(10, -1);
  List<int> mobileNumber = List.filled(11, -1);
  List<String> answers = List.filled(40, '');
  @override
  String toString() {
    return '''
Set Number: $setNumber
Student ID: ${studentId.map((d) => d == -1 ? '?' : d).join()}
Mobile: ${mobileNumber.map((d) => d == -1 ? '?' : d).join()}
Answers: ${answers.asMap().entries.map((e) => 'Q${e.key+1}:${e.value.isEmpty ? '?' : e.value}').join(', ')}
''';
  }
}

/// --- OMR scanner service (TFLite + ML Kit text + fallback) ---
class OMRScannerService {
  // sheet constants (from your spec)
  static const int SHEET_W = 610;
  static const int SHEET_H = 863;
  static const double BUBBLE_FILL_THRESHOLD = 0.6;

  // TFLite
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  // ML Kit text recognizer (for image OCR)
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  // Bubble layout map (constructed from your pixel-perfect mapping)
  final Map<String, List<BubblePosition>> _bubblePositions = {
    'set_number': [
      BubblePosition(417, 140, 14, 0),
      BubblePosition(467, 140, 14, 1),
      BubblePosition(517, 140, 14, 2),
      BubblePosition(567, 140, 14, 3),
    ],
    'student_id': _generateStudentIdBubbles(),
    'mobile_number': _generateMobileBubbles(),
    'answers': _generateAnswerBubbles(),
  };

  static List<BubblePosition> _generateStudentIdBubbles() {
    final List<BubblePosition> out = [];
    double startX = 39.5, startY = 211; // centers as in spec
    for (int col = 0; col < 10; col++) {
      for (int row = 0; row < 10; row++) {
        out.add(BubblePosition(startX + col * 28, startY + row * 18, 12, row, column: col));
      }
    }
    return out;
  }

  static List<BubblePosition> _generateMobileBubbles() {
    final List<BubblePosition> out = [];
    double startX = 326.5, startY = 211;
    for (int col = 0; col < 11; col++) {
      for (int row = 0; row < 10; row++) {
        out.add(BubblePosition(startX + col * 25.5, startY + row * 18, 12, row, column: col));
      }
    }
    return out;
  }

  static List<BubblePosition> _generateAnswerBubbles() {
    final List<BubblePosition> out = [];
    _addAnswerColumn(out, 76, 435, 0, 14); // left (Q1-14)
    _addAnswerColumn(out, 256, 435, 14, 14); // middle (Q15-28)
    _addAnswerColumn(out, 433, 435, 28, 12); // right (Q29-40)
    return out;
  }

  static void _addAnswerColumn(List<BubblePosition> out, double startX, double startY, int startQ, int count) {
    final optionX = [startX, startX + 30, startX + 60, startX + 90];
    for (int q = 0; q < count; q++) {
      double y = startY + q * 20;
      for (int opt = 0; opt < 4; opt++) {
        out.add(BubblePosition(optionX[opt], y, 14, opt, question: startQ + q + 1));
      }
    }
  }

  /// --- Model load (use your asset path) ---
  Future<void> loadModel({String assetPath = 'assets/models/omr_bubble_classifier.tflite'}) async {
    if (_isModelLoaded) return;
    try {
      final opts = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(assetPath, options: opts);
      _isModelLoaded = true;
      print('TFLite model loaded: $assetPath');
    } catch (e, st) {
      _isModelLoaded = false;
      print('TFLite load failed: $e\n$st\nFalling back to traditional detection.');
    }
  }

  /// --- Main processing entry ---
  Future<OMRResult> processImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? inImg = img.decodeImage(bytes);
    if (inImg == null) throw Exception('Could not decode image');

    // Resize onto a canvas of 610x863 while keeping aspect ratio centered
    final canvas = _smartResizeToCanvas(inImg, SHEET_W, SHEET_H);

    // Preprocess: grayscale -> contrast -> adaptive binary
    final gray = img.grayscale(canvas);
    final enhanced = _enhanceContrast(gray, 1.4);
    final binary = _adaptiveThreshold(enhanced, blockSize: 15, c: 7);

    // Optionally detect corners and realign (if you want: code below tries by expected corner marks)
    final aligned = await _autoAlignIfCornerMarks(binary) ?? binary;

    // Hybrid extraction
    final result = OMRResult();

    // 1) set number via bubble classification
    result.setNumber = await _extractSetNumber(aligned);

    // 2) student id, mobile via bubble detection
    result.studentId = await _extractStudentId(aligned);
    result.mobileNumber = await _extractMobileNumber(aligned);

    // 3) answers
    result.answers = await _extractAnswers(aligned);

    // 4) Try OCR on student info region for extra safety (cropping approximate areas)
    // Example: crop "Name / ID" region, run text recognizer to verify numeric digits (optional)
    // result.studentId = await _ocrStudentId(aligned) OR merge with bubble detection results (advanced)

    return result;
  }

  // ---------------- Image helpers ----------------
  img.Image _smartResizeToCanvas(img.Image src, int targetW, int targetH) {
    final double aspect = src.width / src.height;
    final double targetAspect = targetW / targetH;
    int newW, newH;
    if (aspect > targetAspect) {
      newW = targetW;
      newH = (targetW / aspect).round();
    } else {
      newH = targetH;
      newW = (targetH * aspect).round();
    }
    final resized = img.copyResize(src, width: newW, height: newH);
    final canvas = img.Image(width: targetW, height: targetH, numChannels: 1);
    final offX = (targetW - newW) ~/ 2;
    final offY = (targetH - newH) ~/ 2;
    // fill white
    for (int y = 0; y < targetH; y++) {
      for (int x = 0; x < targetW; x++) {
        canvas.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
    for (int y = 0; y < newH; y++) {
      for (int x = 0; x < newW; x++) {
        final p = resized.getPixel(x, y);
        final lum = img.getLuminance(p).toInt();
        canvas.setPixelRgba(offX + x, offY + y, lum, lum, lum, 255);
      }
    }
    return canvas;
  }

  img.Image _enhanceContrast(img.Image image, double factor) {
    final out = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final lnum = img.getLuminance(image.getPixel(x, y));
        final l = lnum.toDouble();
        final intVal = ((l - 128) * factor + 128).clamp(0, 255).toInt();
        out.setPixelRgba(x, y, intVal, intVal, intVal, 255);
      }
    }
    return out;
  }

  img.Image _adaptiveThreshold(img.Image image, {int blockSize = 15, int c = 5}) {
    final out = img.Image(width: image.width, height: image.height);
    final half = blockSize ~/ 2;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int sum = 0, count = 0;
        for (int dy = -half; dy <= half; dy++) {
          for (int dx = -half; dx <= half; dx++) {
            final nx = x + dx, ny = y + dy;
            if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
              sum += img.getLuminance(image.getPixel(nx, ny)).toInt();
              count++;
            }
          }
        }
        final mean = count > 0 ? sum ~/ count : 0;
        final pix = img.getLuminance(image.getPixel(x, y)).toInt();
        final val = pix > mean - c ? 255 : 0;
        out.setPixelRgba(x, y, val, val, val, 255);
      }
    }
    return out;
  }

  // ---------------- Corner detection & alignment (simple) ----------------
  Future<img.Image?> _autoAlignIfCornerMarks(img.Image image) async {
    // Expected corner centers per spec:
    final expected = [
      Point(17, 17), // top-left
      Point(573, 17), // top-right
      Point(573, 823), // bottom-right
      Point(17, 823), // bottom-left
    ];

    final found = <Point>[];
    for (final e in expected) {
      final mark = _detectCornerMarkInRegion(image, e.x, e.y, searchRadius: 25, markRadius: 12);
      if (mark != null) found.add(mark);
    }

    if (found.length == 4) {
      // sort to top-left, top-right, bottom-right, bottom-left
      found.sort((a, b) {
        if (a.y == b.y) return a.x.compareTo(b.x);
        return a.y.compareTo(b.y);
      });
      final topLeft = found[0];
      final topRight = found[1];
      final bottomLeft = found[2];
      final bottomRight = found[3];

      // If displacement small, skip transform
      final totalDisp = (topLeft.distanceTo(Point(17, 17)) +
          topRight.distanceTo(Point(573, 17)) +
          bottomRight.distanceTo(Point(573, 823)) +
          bottomLeft.distanceTo(Point(17, 823)));
      if (totalDisp < 20) return null;

      // We perform simple four-corner bilinear remap (already implemented below)
      return _perspectiveRemap(image, topLeft, topRight, bottomRight, bottomLeft);
    }
    return null;
  }

  Point? _detectCornerMarkInRegion(img.Image image, int centerX, int centerY,
      {int searchRadius = 25, int markRadius = 12}) {
    int black = 0, total = 0;
    for (int y = centerY - searchRadius; y <= centerY + searchRadius; y++) {
      for (int x = centerX - searchRadius; x <= centerX + searchRadius; x++) {
        if (x < 0 || y < 0 || x >= image.width || y >= image.height) continue;
        final d = math.sqrt(math.pow(x - centerX, 2) + math.pow(y - centerY, 2));
        if (d <= markRadius) {
          total++;
          final p = img.getLuminance(image.getPixel(x, y)).toInt();
          if (p < 128) black++;
        }
      }
    }
    if (total == 0) return null;
    final ratio = black / total;
    if (ratio > 0.6) {
      return Point(centerX, centerY);
    }
    return null;
  }

  img.Image _perspectiveRemap(img.Image src, Point tl, Point tr, Point br, Point bl) {
    final out = img.Image(width: SHEET_W, height: SHEET_H);
    for (int y = 0; y < SHEET_H; y++) {
      for (int x = 0; x < SHEET_W; x++) {
        final u = x / (SHEET_W - 1);
        final v = y / (SHEET_H - 1);
        final srcX = (1 - u) * (1 - v) * tl.x + u * (1 - v) * tr.x + u * v * br.x + (1 - u) * v * bl.x;
        final srcY = (1 - u) * (1 - v) * tl.y + u * (1 - v) * tr.y + u * v * br.y + (1 - u) * v * bl.y;
        final ix = srcX.round();
        final iy = srcY.round();
        if (ix < 0 || iy < 0 || ix >= src.width || iy >= src.height) {
          out.setPixelRgba(x, y, 255, 255, 255, 255);
        } else {
          final lum = img.getLuminance(src.getPixel(ix, iy)).toInt();
          out.setPixelRgba(x, y, lum, lum, lum, 255);
        }
      }
    }
    return out;
  }

  // ---------------- Extraction helpers ----------------
  Future<int> _extractSetNumber(img.Image image) async {
    final bubbles = _bubblePositions['set_number']!;
    double maxC = 0;
    int sel = 0;
    for (int i = 0; i < bubbles.length; i++) {
      final c = await _analyzeBubble(image, bubbles[i]);
      if (c > maxC) {
        maxC = c;
        sel = i + 1;
      }
    }
    return maxC > BUBBLE_FILL_THRESHOLD ? sel : 0;
  }

  Future<List<int>> _extractStudentId(img.Image image) async {
    final bubbles = _bubblePositions['student_id']!;
    final result = List<int>.filled(10, -1);
    for (int col = 0; col < 10; col++) {
      double maxC = 0;
      int sel = -1;
      for (int row = 0; row < 10; row++) {
        final b = bubbles.firstWhere((bb) => bb.column == col && bb.value == row);
        final c = await _analyzeBubble(image, b);
        if (c > maxC) {
          maxC = c;
          sel = row;
        }
      }
      result[col] = maxC > BUBBLE_FILL_THRESHOLD ? sel : -1;
    }
    return result;
  }

  Future<List<int>> _extractMobileNumber(img.Image image) async {
    final bubbles = _bubblePositions['mobile_number']!;
    final result = List<int>.filled(11, -1);
    for (int col = 0; col < 11; col++) {
      double maxC = 0;
      int sel = -1;
      for (int row = 0; row < 10; row++) {
        final b = bubbles.firstWhere((bb) => bb.column == col && bb.value == row);
        final c = await _analyzeBubble(image, b);
        if (c > maxC) {
          maxC = c;
          sel = row;
        }
      }
      result[col] = maxC > BUBBLE_FILL_THRESHOLD ? sel : -1;
    }
    return result;
  }

  Future<List<String>> _extractAnswers(img.Image image) async {
    final bubbles = _bubblePositions['answers']!;
    final answers = List<String>.filled(40, '');
    for (int q = 1; q <= 40; q++) {
      final options = bubbles.where((b) => b.question == q).toList();
      double maxC = 0;
      int sel = -1;
      for (int i = 0; i < options.length; i++) {
        final c = await _analyzeBubble(image, options[i]);
        if (c > maxC) {
          maxC = c;
          sel = i;
        }
      }
      answers[q - 1] = maxC > BUBBLE_FILL_THRESHOLD ? String.fromCharCode(65 + sel) : '';
    }
    return answers;
  }

  // Analyze single bubble — try TFLite, otherwise fallback to pixel-fill
  Future<double> _analyzeBubble(img.Image image, BubblePosition b) async {
    if (_isModelLoaded && _interpreter != null) {
      try {
        return await _analyzeWithTFLite(image, b);
      } catch (e) {
        // fallback
        return _analyzeWithTraditional(image, b);
      }
    } else {
      return _analyzeWithTraditional(image, b);
    }
  }

  // Crop region, resize to 28x28 and run tflite model expecting shape [1,28,28,1] -> [1,2]
  Future<double> _analyzeWithTFLite(img.Image image, BubblePosition b) async {
    final region = _extractPatch(image, b);
    // prepare input as float32 [1,28,28,1]
    final input = List.generate(1, (_) => List.generate(28, (_) => List.generate(28, (_) => List.filled(1, 0.0))));
    for (int y = 0; y < 28; y++) {
      for (int x = 0; x < 28; x++) {
        final val = img.getLuminance(region.getPixel(x, y)).toInt();
        input[0][y][x][0] = val / 255.0;
      }
    }

    final output = List.filled(2, 0.0).reshape([1, 2]);
    _interpreter!.run(input, output);
    // probability of class index 1 = filled
    final prob = (output[0] as List)[1] as double;
    return prob;
  }

  // Traditional pixel analysis fallback
  Future<double> _analyzeWithTraditional(img.Image image, BubblePosition b) async {
    int cx = b.x.toInt(), cy = b.y.toInt(), r = b.radius.toInt();
    int black = 0, total = 0;
    for (int y = cy - r; y <= cy + r; y++) {
      for (int x = cx - r; x <= cx + r; x++) {
        if (x < 0 || y < 0 || x >= image.width || y >= image.height) continue;
        final d = math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2));
        if (d <= r) {
          total++;
          final p = img.getLuminance(image.getPixel(x, y)).toInt();
          if (p < 128) black++;
        }
      }
    }
    return total > 0 ? black / total : 0.0;
  }

  // Extract square patch centered on bubble, return resized 28x28 grayscale image
  img.Image _extractPatch(img.Image image, BubblePosition b) {
    final size = (b.radius * 2).toInt();
    final region = img.Image(width: size, height: size, numChannels: 1);
    final startX = b.x.toInt() - size ~/ 2;
    final startY = b.y.toInt() - size ~/ 2;
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final sx = startX + x, sy = startY + y;
        if (sx >= 0 && sy >= 0 && sx < image.width && sy < image.height) {
          final val = img.getLuminance(image.getPixel(sx, sy)).toInt();
          region.setPixelRgba(x, y, val, val, val, 255);
        } else {
          region.setPixelRgba(x, y, 255, 255, 255, 255);
        }
      }
    }
    return img.copyResize(region, width: 28, height: 28);
  }

  // Optional: OCR a cropped rectangular region with ML Kit text recognizer
  Future<String> _ocrRegion(img.Image image, int x, int y, int w, int h) async {
    // Convert img.Image -> InputImage via bytes
    final crop = img.copyCrop(image, x:  x, y:  y, width:  w, height:  h);
    final pngBytes = img.encodePng(crop);
    final inputImage = InputImage.fromFilePath(await _bytesToTempFile(pngBytes, 'ocr_crop.png'));
    final result = await _textRecognizer.processImage(inputImage);
    final text = result.text;
    return text;
  }

  Future<String> _bytesToTempFile(List<int> bytes, String name) async {
    final tmp = File('${Directory.systemTemp.path}/$name');
    await tmp.writeAsBytes(bytes, flush: true);
    return tmp.path;
  }
}

/// small helper for points
class Point {
  final int x;
  final int y;
  Point(this.x, this.y);
  double distanceTo(Point other) {
    return math.sqrt(math.pow(x - other.x, 2) + math.pow(y - other.y, 2));
  }
}











// import 'dart:io';
// import 'dart:math' as math;
// import 'package:image/image.dart' as img;
// import 'package:tflite_flutter/tflite_flutter.dart';
//
// class OMRScannerService {
//   static const int SHEET_WIDTH = 610;
//   static const int SHEET_HEIGHT = 863;
//   static const double BUBBLE_FILL_THRESHOLD = 0.6;
//   static const double CORNER_MARK_THRESHOLD = 0.6;
//
//   Interpreter? _interpreter;
//   bool _isModelLoaded = false;
//
//   final Map<String, List<BubblePosition>> _bubblePositions = {
//     'set_number': [
//       BubblePosition(417, 140, 14, 0),
//       BubblePosition(467, 140, 14, 1),
//       BubblePosition(517, 140, 14, 2),
//       BubblePosition(567, 140, 14, 3),
//     ],
//     'student_id': _generateStudentIdBubbles(),
//     'mobile_number': _generateMobileBubbles(),
//     'answers': _generateAnswerBubbles(),
//   };
//
//   /// ---------------- Bubble Generators ----------------
//   static List<BubblePosition> _generateStudentIdBubbles() {
//     List<BubblePosition> bubbles = [];
//     double startX = 39.5, startY = 211;
//     for (int col = 0; col < 10; col++) {
//       for (int row = 0; row < 10; row++) {
//         bubbles.add(BubblePosition(
//             startX + col * 28, startY + row * 18, 12, row,
//             column: col));
//       }
//     }
//     return bubbles;
//   }
//
//   static List<BubblePosition> _generateMobileBubbles() {
//     List<BubblePosition> bubbles = [];
//     double startX = 326.5, startY = 211;
//     for (int col = 0; col < 11; col++) {
//       for (int row = 0; row < 10; row++) {
//         bubbles.add(BubblePosition(
//             startX + col * 25.5, startY + row * 18, 12, row,
//             column: col));
//       }
//     }
//     return bubbles;
//   }
//
//   static List<BubblePosition> _generateAnswerBubbles() {
//     List<BubblePosition> bubbles = [];
//     _addAnswerColumn(bubbles, 76, 435, 0, 14);
//     _addAnswerColumn(bubbles, 256, 435, 14, 14);
//     _addAnswerColumn(bubbles, 433, 435, 28, 12);
//     return bubbles;
//   }
//
//   static void _addAnswerColumn(List<BubblePosition> bubbles, double startX,
//       double startY, int startQ, int count) {
//     List<double> optionX = [startX, startX + 30, startX + 60, startX + 90];
//     for (int q = 0; q < count; q++) {
//       double y = startY + q * 20;
//       for (int opt = 0; opt < 4; opt++) {
//         bubbles.add(BubblePosition(optionX[opt], y, 14, opt,
//             question: startQ + q + 1));
//       }
//     }
//   }
//
//   /// ---------------- Model Loading ----------------
//   Future<void> loadModel() async {
//     if (_isModelLoaded) return;
//     try {
//       _interpreter = await Interpreter.fromAsset(
//         'models/omr_model.tflite',
//         options: InterpreterOptions()..threads = 4,
//       );
//       _isModelLoaded = true;
//       print('TFLite model loaded successfully');
//     } catch (e) {
//       print('Error loading TFLite model: $e');
//     }
//   }
//
//   /// ---------------- Image Processing ----------------
//   Future<OMRResult> processImage(File imageFile) async {
//     if (!_isModelLoaded) await loadModel();
//     img.Image? original = img.decodeImage(await imageFile.readAsBytes());
//     if (original == null) throw Exception('Cannot decode image');
//
//     // Resize & grayscale
//     img.Image resized = img.copyResize(original, width: SHEET_WIDTH, height: SHEET_HEIGHT);
//     img.Image gray = img.grayscale(resized);
//     img.Image preprocessed = _adaptiveThreshold(_enhanceContrast(gray, 1.5),blockSize:  15, c:  7);
//
//     // Extract OMR data
//     OMRResult result = OMRResult();
//     result.setNumber = await _extractSetNumber(preprocessed);
//     result.studentId = await _extractStudentId(preprocessed);
//     result.mobileNumber = await _extractMobileNumber(preprocessed);
//     result.answers = await _extractAnswers(preprocessed);
//
//     return result;
//   }
//
//   img.Image _enhanceContrast(img.Image image, double factor) {
//     final output = img.Image(width: image.width, height: image.height);
//     for (int y = 0; y < image.height; y++) {
//       for (int x = 0; x < image.width; x++) {
//         num l = img.getLuminance(image.getPixel(x, y));
//         int val = ((l - 128) * factor + 128).clamp(0, 255).toInt();
//         output.setPixelRgba(x, y, val, val, val, 255); // <-- add alpha
//       }
//     }
//     return output;
//   }
//
//
//   img.Image _adaptiveThreshold(img.Image image, {int blockSize = 15, int c = 5}) {
//     final output = img.Image(width: image.width, height: image.height);
//     int half = blockSize ~/ 2;
//
//     for (int y = 0; y < image.height; y++) {
//       for (int x = 0; x < image.width; x++) {
//         int sum = 0, count = 0;
//
//         for (int dy = -half; dy <= half; dy++) {
//           for (int dx = -half; dx <= half; dx++) {
//             int nx = x + dx;
//             int ny = y + dy;
//
//             if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
//               sum += img.getLuminance(image.getPixel(nx, ny)).toInt(); // cast
//               count++;
//             }
//           }
//         }
//
//         int mean = count > 0 ? sum ~/ count : 0;
//         int pixel = img.getLuminance(image.getPixel(x, y)).toInt(); // cast
//         int val = (pixel > mean - c) ? 255 : 0;
//
//         output.setPixelRgba(x, y, val, val, val, 255); // alpha required
//       }
//     }
//
//     return output;
//   }
//
//
//
//   /// ---------------- Extraction ----------------
//   Future<int> _extractSetNumber(img.Image image) async {
//     double maxC = 0;
//     int selected = 0;
//     for (int i = 0; i < _bubblePositions['set_number']!.length; i++) {
//       double c = await _analyzeBubble(image, _bubblePositions['set_number']![i]);
//       if (c > maxC) {
//         maxC = c;
//         selected = i + 1;
//       }
//     }
//     return maxC > BUBBLE_FILL_THRESHOLD ? selected : 0;
//   }
//
//   Future<List<int>> _extractStudentId(img.Image image) async {
//     List<int> result = List.filled(10, -1);
//     for (int col = 0; col < 10; col++) {
//       double maxC = 0;
//       int sel = -1;
//       for (int row = 0; row < 10; row++) {
//         BubblePosition b = _bubblePositions['student_id']!
//             .firstWhere((b) => b.column == col && b.value == row);
//         double c = await _analyzeBubble(image, b);
//         if (c > maxC) {
//           maxC = c;
//           sel = row;
//         }
//       }
//       result[col] = maxC > BUBBLE_FILL_THRESHOLD ? sel : -1;
//     }
//     return result;
//   }
//
//   Future<List<int>> _extractMobileNumber(img.Image image) async {
//     List<int> result = List.filled(11, -1);
//     for (int col = 0; col < 11; col++) {
//       double maxC = 0;
//       int sel = -1;
//       for (int row = 0; row < 10; row++) {
//         BubblePosition b = _bubblePositions['mobile_number']!
//             .firstWhere((b) => b.column == col && b.value == row);
//         double c = await _analyzeBubble(image, b);
//         if (c > maxC) {
//           maxC = c;
//           sel = row;
//         }
//       }
//       result[col] = maxC > BUBBLE_FILL_THRESHOLD ? sel : -1;
//     }
//     return result;
//   }
//
//   Future<List<String>> _extractAnswers(img.Image image) async {
//     List<String> answers = List.filled(40, '');
//     for (int q = 1; q <= 40; q++) {
//       List<BubblePosition> options =
//       _bubblePositions['answers']!.where((b) => b.question == q).toList();
//       double maxC = 0;
//       int sel = -1;
//       for (int i = 0; i < options.length; i++) {
//         double c = await _analyzeBubble(image, options[i]);
//         if (c > maxC) {
//           maxC = c;
//           sel = i;
//         }
//       }
//       answers[q - 1] = maxC > BUBBLE_FILL_THRESHOLD ? String.fromCharCode(65 + sel) : '';
//     }
//     return answers;
//   }
//
//   /// ---------------- Bubble Analysis ----------------
//   Future<double> _analyzeBubble(img.Image image, BubblePosition bubble) async {
//     if (_isModelLoaded && _interpreter != null) {
//       try {
//         img.Image region = _extractRegion(image, bubble);
//         var input = _preprocessForTFLite(region);
//         var output = List.filled(2, 0.0).reshape([1, 2]);
//         _interpreter!.run(input, output);
//         return output[0][1];
//       } catch (_) {
//         return _analyzeWithTraditional(image, bubble);
//       }
//     } else {
//       return _analyzeWithTraditional(image, bubble);
//     }
//   }
//
//   img.Image _extractRegion(img.Image image, BubblePosition bubble) {
//     int size = (bubble.radius * 2).toInt();
//
//     // Grayscale image uses 1 channel
//     img.Image region = img.Image(
//       width: size,
//       height: size,
//       numChannels: 1,
//     );
//
//     int startX = bubble.x.toInt() - size ~/ 2;
//     int startY = bubble.y.toInt() - size ~/ 2;
//
//     for (int y = 0; y < size; y++) {
//       for (int x = 0; x < size; x++) {
//         int sx = startX + x;
//         int sy = startY + y;
//
//         if (sx >= 0 && sx < image.width && sy >= 0 && sy < image.height) {
//           int val = img.getLuminance(image.getPixel(sx, sy)).toInt();
//           region.setPixelRgba(x, y, val, val, val, 255); // add alpha
//         }
//       }
//     }
//
//     // Resize to 28x28 for model input
//     return img.copyResize(region, width: 28, height: 28);
//   }
//
//
//
//   List<List<List<List<double>>>> _preprocessForTFLite(img.Image image) {
//     List<List<List<List<double>>>> input = List.generate(
//       1,
//           (_) => List.generate(
//         28,
//             (_) => List.generate(
//           28,
//               (_) => List.filled(1, 0.0),
//         ),
//       ),
//     );
//
//     for (int y = 0; y < 28; y++) {
//       for (int x = 0; x < 28; x++) {
//         int val = img.getLuminance(image.getPixel(x, y)).toInt(); // cast to int
//         input[0][y][x][0] = val / 255.0;
//       }
//     }
//
//     return input;
//   }
//
//
//   Future<double> _analyzeWithTraditional(img.Image image, BubblePosition bubble) async {
//     int black = 0, total = 0;
//     int cx = bubble.x.toInt(), cy = bubble.y.toInt(), r = bubble.radius.toInt();
//     for (int y = cy - r; y <= cy + r; y++) {
//       for (int x = cx - r; x <= cx + r; x++) {
//         if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
//           if (math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2)) <= r) {
//             total++;
//             if (img.getLuminance(image.getPixel(x, y)) < 128) black++;
//           }
//         }
//       }
//     }
//     return total > 0 ? black / total : 0.0;
//   }
// }
//
// /// ---------------- Models ----------------
// class BubblePosition {
//   final double x, y, radius;
//   final int value;
//   final int? column, question;
//   BubblePosition(this.x, this.y, this.radius, this.value, {this.column, this.question});
// }
//
// class OMRResult {
//   int setNumber = 0;
//   List<int> studentId = List.filled(10, -1);
//   List<int> mobileNumber = List.filled(11, -1);
//   List<String> answers = List.filled(40, '');
//   @override
//   String toString() =>
//       'Set Number: $setNumber\nStudent ID: ${studentId.join()}\nMobile: ${mobileNumber.join()}\nAnswers: ${answers.asMap().entries.map((e) => 'Q${e.key + 1}:${e.value}').join(', ')}';
// }
//
//
//
//
//
//
// // import 'dart:io';
// // import 'dart:math' as math;
// // import 'dart:typed_data';
// // import 'package:image/image.dart' as img;
// // import 'package:tflite_flutter/tflite_flutter.dart';
// // import 'package:google_mlkit_commons/google_mlkit_commons.dart';
// //
// // class OMRScannerService {
// //   static const int SHEET_WIDTH = 610;
// //   static const int SHEET_HEIGHT = 863;
// //
// //   // Detection thresholds
// //   static const double BUBBLE_FILL_THRESHOLD = 0.6;
// //   static const double CORNER_MARK_THRESHOLD = 0.6;
// //
// //   // TensorFlow Lite
// //   Interpreter? _interpreter;
// //   bool _isModelLoaded = false;
// //
// //   // Bubble positions based on specification
// //   final Map<String, List<BubblePosition>> _bubblePositions = {
// //     'set_number': [
// //       BubblePosition(417, 140, 14, 0),
// //       BubblePosition(467, 140, 14, 1),
// //       BubblePosition(517, 140, 14, 2),
// //       BubblePosition(567, 140, 14, 3),
// //     ],
// //     'student_id': _generateStudentIdBubbles(),
// //     'mobile_number': _generateMobileBubbles(),
// //     'answers': _generateAnswerBubbles(),
// //   };
// //
// //   static List<BubblePosition> _generateStudentIdBubbles() {
// //     List<BubblePosition> bubbles = [];
// //     double startX = 39.5;
// //     double startY = 211;
// //
// //     for (int col = 0; col < 10; col++) {
// //       for (int row = 0; row < 10; row++) {
// //         double x = startX + col * 28;
// //         double y = startY + row * 18;
// //         bubbles.add(BubblePosition(x, y, 12, row, column: col));
// //       }
// //     }
// //     return bubbles;
// //   }
// //
// //   static List<BubblePosition> _generateMobileBubbles() {
// //     List<BubblePosition> bubbles = [];
// //     double startX = 326.5;
// //     double startY = 211;
// //
// //     for (int col = 0; col < 11; col++) {
// //       for (int row = 0; row < 10; row++) {
// //         double x = startX + col * 25.5;
// //         double y = startY + row * 18;
// //         bubbles.add(BubblePosition(x, y, 12, row, column: col));
// //       }
// //     }
// //     return bubbles;
// //   }
// //
// //   static List<BubblePosition> _generateAnswerBubbles() {
// //     List<BubblePosition> bubbles = [];
// //
// //     // Left column (Questions 1-14)
// //     _addAnswerColumn(bubbles, 76, 435, 0, 14);
// //
// //     // Middle column (Questions 15-28)
// //     _addAnswerColumn(bubbles, 256, 435, 14, 14);
// //
// //     // Right column (Questions 29-40)
// //     _addAnswerColumn(bubbles, 433, 435, 28, 12);
// //
// //     return bubbles;
// //   }
// //
// //   static void _addAnswerColumn(List<BubblePosition> bubbles, double startX, double startY, int startQ, int count) {
// //     List<double> optionX = [startX, startX + 30, startX + 60, startX + 90];
// //
// //     for (int q = 0; q < count; q++) {
// //       double y = startY + q * 20;
// //       for (int opt = 0; opt < 4; opt++) {
// //         bubbles.add(BubblePosition(
// //             optionX[opt],
// //             y,
// //             14,
// //             opt,
// //             question: startQ + q + 1
// //         ));
// //       }
// //     }
// //   }
// //
// //   Future<void> loadModel() async {
// //     try {
// //       // Create interpreter options for better performance
// //       final options = InterpreterOptions()
// //         ..threads = 4
// //         ..useNnApiForAndroid = true
// //         ..useMetalDelegateForIOS = true;
// //
// //       _interpreter = await Interpreter.fromAsset('models/omr_model.tflite', options: options);
// //       _isModelLoaded = true;
// //       print('TFLite model loaded successfully');
// //     } catch (e) {
// //       print('Error loading TFLite model: $e');
// //       // Continue without model - use traditional processing
// //     }
// //   }
// //
// //   Future<OMRResult> processImage(File imageFile) async {
// //     if (!_isModelLoaded) await loadModel();
// //
// //     // Step 1: Preprocess image
// //     img.Image? processedImage = await _preprocessImage(imageFile);
// //     if (processedImage == null) throw Exception('Image preprocessing failed');
// //
// //     // Step 2: Detect and align sheet
// //     img.Image? alignedImage = await _autoAlignSheet(processedImage);
// //     alignedImage ??= processedImage;
// //
// //     // Step 3: Extract data using hybrid approach (TFLite + traditional)
// //     OMRResult result = await _extractDataWithHybridApproach(alignedImage);
// //
// //     return result;
// //   }
// //
// //   Future<img.Image?> _preprocessImage(File imageFile) async {
// //     try {
// //       List<int> imageBytes = await imageFile.readAsBytes();
// //       img.Image? originalImage = img.decodeImage(imageBytes);
// //       if (originalImage == null) return null;
// //
// //       // Resize to target dimensions while maintaining aspect ratio
// //       img.Image resizedImage = _smartResize(originalImage, SHEET_WIDTH, SHEET_HEIGHT);
// //
// //       // Convert to grayscale
// //       img.Image grayscaleImage = img.grayscale(resizedImage);
// //
// //       // Apply advanced preprocessing
// //       return _advancedPreprocessing(grayscaleImage);
// //     } catch (e) {
// //       print('Preprocessing error: $e');
// //       return null;
// //     }
// //   }
// //
// //   img.Image _smartResize(img.Image image, int targetWidth, int targetHeight) {
// //     double aspectRatio = image.width / image.height;
// //     double targetAspect = targetWidth / targetHeight;
// //
// //     int newWidth, newHeight;
// //
// //     if (aspectRatio > targetAspect) {
// //       newWidth = targetWidth;
// //       newHeight = (targetWidth / aspectRatio).round();
// //     } else {
// //       newHeight = targetHeight;
// //       newWidth = (targetHeight * aspectRatio).round();
// //     }
// //
// //     img.Image resized = img.copyResize(image, width: newWidth, height: newHeight);
// //
// //     // Create canvas with target dimensions
// //     img.Image canvas = img.Image(targetWidth, targetHeight);
// //
// //     // Center the resized image on canvas
// //     int offsetX = (targetWidth - newWidth) ~/ 2;
// //     int offsetY = (targetHeight - newHeight) ~/ 2;
// //
// //     for (int y = 0; y < newHeight; y++) {
// //       for (int x = 0; x < newWidth; x++) {
// //         canvas.setPixel(offsetX + x, offsetY + y, resized.getPixel(x, y));
// //       }
// //     }
// //
// //     return canvas;
// //   }
// //
// //   img.Image _advancedPreprocessing(img.Image image) {
// //     // Step 1: Apply Gaussian blur to reduce noise
// //     img.Image blurred = img.gaussianBlur(image, radius: 1);
// //
// //     // Step 2: Apply contrast enhancement
// //     img.Image contrasted = _enhanceContrast(blurred, 1.5);
// //
// //     // Step 3: Apply adaptive threshold
// //     img.Image binary = _adaptiveThreshold(contrasted, blockSize: 15, c: 7);
// //
// //     return binary;
// //   }
// //
// //   img.Image _enhanceContrast(img.Image image, double factor) {
// //     final output = img.Image(width: image.width, height: image.height);
// //
// //     for (int y = 0; y < image.height; y++) {
// //       for (int x = 0; x < image.width; x++) {
// //         int pixel = img.getLuminance(image[x + y * image.width]);
// //         int enhanced = ((pixel - 128) * factor + 128).clamp(0, 255).round();
// //         output.setPixelRgba(x, y, enhanced, enhanced, enhanced);
// //       }
// //     }
// //
// //     return output;
// //   }
// //
// //   img.Image _adaptiveThreshold(img.Image image, {int blockSize = 15, int c = 5}) {
// //     final output = img.Image(width: image.width, height: image.height);
// //
// //     int halfBlock = blockSize ~/ 2;
// //
// //     for (int y = 0; y < image.height; y++) {
// //       for (int x = 0; x < image.width; x++) {
// //         int sum = 0;
// //         int count = 0;
// //
// //         // Calculate local mean with boundary checks
// //         for (int j = -halfBlock; j <= halfBlock; j++) {
// //           for (int i = -halfBlock; i <= halfBlock; i++) {
// //             int nx = x + i;
// //             int ny = y + j;
// //
// //             if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
// //               sum += img.getLuminance(image[nx + ny * image.width]);
// //               count++;
// //             }
// //           }
// //         }
// //
// //         int mean = count > 0 ? sum ~/ count : 0;
// //         int pixel = img.getLuminance(image[x + y * image.width]);
// //
// //         // Apply adaptive threshold
// //         int result = pixel > (mean - c) ? 255 : 0;
// //         output.setPixelRgba(x, y, result, result, result);
// //       }
// //     }
// //
// //     return output;
// //   }
// //
// //   Future<img.Image?> _autoAlignSheet(img.Image image) async {
// //     try {
// //       List<CornerMark> corners = await _detectCornerMarks(image);
// //
// //       if (corners.length == 4) {
// //         // Sort and validate corners
// //         corners.sort((a, b) => a.position.x.compareTo(b.position.x));
// //
// //         List<CornerMark> leftCorners = corners.sublist(0, 2);
// //         List<CornerMark> rightCorners = corners.sublist(2, 4);
// //
// //         leftCorners.sort((a, b) => a.position.y.compareTo(b.position.y));
// //         rightCorners.sort((a, b) => a.position.y.compareTo(b.position.y));
// //
// //         if (leftCorners.length == 2 && rightCorners.length == 2) {
// //           CornerMark topLeft = leftCorners[0];
// //           CornerMark bottomLeft = leftCorners[1];
// //           CornerMark topRight = rightCorners[0];
// //           CornerMark bottomRight = rightCorners[1];
// //
// //           return _perspectiveTransform(
// //               image,
// //               topLeft.position,
// //               topRight.position,
// //               bottomRight.position,
// //               bottomLeft.position
// //           );
// //         }
// //       }
// //     } catch (e) {
// //       print('Alignment error: $e');
// //     }
// //
// //     return image;
// //   }
// //
// //   Future<List<CornerMark>> _detectCornerMarks(img.Image image) async {
// //     List<CornerMark> corners = [];
// //
// //     List<Point> expectedCorners = [
// //       Point(17, 17),    // Top-left
// //       Point(573, 17),   // Top-right
// //       Point(17, 823),   // Bottom-left
// //       Point(573, 823),  // Bottom-right
// //     ];
// //
// //     for (var expected in expectedCorners) {
// //       CornerMark? mark = await _detectCornerInRegion(image, expected);
// //       if (mark != null) {
// //         corners.add(mark);
// //       }
// //     }
// //
// //     return corners;
// //   }
// //
// //   Future<CornerMark?> _detectCornerInRegion(img.Image image, Point center) async {
// //     const searchRadius = 25;
// //     const markRadius = 12.5;
// //
// //     int blackPixels = 0;
// //     int totalPixels = 0;
// //
// //     for (int y = center.y - searchRadius; y <= center.y + searchRadius; y++) {
// //       for (int x = center.x - searchRadius; x <= center.x + searchRadius; x++) {
// //         if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
// //           double distance = _calculateDistance(x, y, center.x, center.y);
// //
// //           if (distance <= markRadius) {
// //             totalPixels++;
// //             int pixel = img.getLuminance(image[x + y * image.width]);
// //             if (pixel < 128) {
// //               blackPixels++;
// //             }
// //           }
// //         }
// //       }
// //     }
// //
// //     double fillRatio = totalPixels > 0 ? blackPixels / totalPixels : 0;
// //
// //     if (fillRatio > CORNER_MARK_THRESHOLD) {
// //       return CornerMark(Point(center.x, center.y), fillRatio);
// //     }
// //
// //     return null;
// //   }
// //
// //   double _calculateDistance(int x1, int y1, int x2, int y2) {
// //     return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
// //   }
// //
// //   img.Image _perspectiveTransform(
// //       img.Image image,
// //       Point topLeft,
// //       Point topRight,
// //       Point bottomRight,
// //       Point bottomLeft
// //       ) {
// //     final output = img.Image(width: SHEET_WIDTH, height: SHEET_HEIGHT);
// //
// //     // Calculate transformation matrix (simplified affine transformation)
// //     for (int y = 0; y < SHEET_HEIGHT; y++) {
// //       for (int x = 0; x < SHEET_WIDTH; x++) {
// //         // Simple interpolation for basic alignment
// //         double srcX = x.toDouble();
// //         double srcY = y.toDouble();
// //
// //         // Add basic transformation if coordinates are significantly off
// //         if (_shouldTransform(topLeft, topRight, bottomRight, bottomLeft)) {
// //           srcX = _transformX(x, y, topLeft, topRight, bottomRight, bottomLeft);
// //           srcY = _transformY(x, y, topLeft, topRight, bottomRight, bottomLeft);
// //         }
// //
// //         int pixel = _bilinearInterpolate(image, srcX, srcY);
// //         output.setPixelRgba(x, y, pixel, pixel, pixel);
// //       }
// //     }
// //
// //     return output;
// //   }
// //
// //   bool _shouldTransform(Point tl, Point tr, Point br, Point bl) {
// //     // Check if corners are significantly displaced from expected positions
// //     List<Point> expected = [Point(17, 17), Point(573, 17), Point(573, 823), Point(17, 823)];
// //     List<Point> actual = [tl, tr, br, bl];
// //
// //     double totalDisplacement = 0;
// //     for (int i = 0; i < 4; i++) {
// //       totalDisplacement += _calculateDistance(
// //           expected[i].x, expected[i].y, actual[i].x, actual[i].y
// //       );
// //     }
// //
// //     return totalDisplacement > 20; // Threshold for transformation
// //   }
// //
// //   double _transformX(int x, int y, Point tl, Point tr, Point br, Point bl) {
// //     // Simplified perspective transformation
// //     double u = x / SHEET_WIDTH;
// //     double v = y / SHEET_HEIGHT;
// //
// //     return (1-u)*(1-v)*tl.x + u*(1-v)*tr.x + u*v*br.x + (1-u)*v*bl.x;
// //   }
// //
// //   double _transformY(int x, int y, Point tl, Point tr, Point br, Point bl) {
// //     double u = x / SHEET_WIDTH;
// //     double v = y / SHEET_HEIGHT;
// //
// //     return (1-u)*(1-v)*tl.y + u*(1-v)*tr.y + u*v*br.y + (1-u)*v*bl.y;
// //   }
// //
// //   int _bilinearInterpolate(img.Image image, double x, double y) {
// //     int x1 = x.floor();
// //     int y1 = y.floor();
// //     int x2 = x1 + 1;
// //     int y2 = y1 + 1;
// //
// //     double dx = x - x1;
// //     double dy = y - y1;
// //
// //     if (x1 < 0 || y1 < 0 || x2 >= image.width || y2 >= image.height) {
// //       return 255; // White for out-of-bounds
// //     }
// //
// //     int pixel11 = _safeGetPixel(image, x1, y1);
// //     int pixel21 = _safeGetPixel(image, x2, y1);
// //     int pixel12 = _safeGetPixel(image, x1, y2);
// //     int pixel22 = _safeGetPixel(image, x2, y2);
// //
// //     double interpolated =
// //         pixel11 * (1 - dx) * (1 - dy) +
// //             pixel21 * dx * (1 - dy) +
// //             pixel12 * (1 - dx) * dy +
// //             pixel22 * dx * dy;
// //
// //     return interpolated.round();
// //   }
// //
// //   int _safeGetPixel(img.Image image, int x, int y) {
// //     if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
// //       return img.getLuminance(image[x + y * image.width]);
// //     }
// //     return 255; // Return white for invalid coordinates
// //   }
// //
// //   Future<OMRResult> _extractDataWithHybridApproach(img.Image image) async {
// //     OMRResult result = OMRResult();
// //
// //     // Extract set number
// //     result.setNumber = await _extractSetNumber(image);
// //
// //     // Extract student ID
// //     result.studentId = await _extractStudentId(image);
// //
// //     // Extract mobile number
// //     result.mobileNumber = await _extractMobileNumber(image);
// //
// //     // Extract answers
// //     result.answers = await _extractAnswers(image);
// //
// //     return result;
// //   }
// //
// //   Future<int> _extractSetNumber(img.Image image) async {
// //     List<BubblePosition> setBubbles = _bubblePositions['set_number']!;
// //     List<double> confidences = [];
// //
// //     for (var bubble in setBubbles) {
// //       double confidence = await _analyzeBubbleWithTFLite(image, bubble);
// //       confidences.add(confidence);
// //     }
// //
// //     double maxConfidence = confidences.reduce((a, b) => a > b ? a : b);
// //     int maxIndex = confidences.indexWhere((c) => c == maxConfidence);
// //
// //     return maxConfidence > BUBBLE_FILL_THRESHOLD ? maxIndex + 1 : 0;
// //   }
// //
// //   Future<List<int>> _extractStudentId(img.Image image) async {
// //     List<BubblePosition> idBubbles = _bubblePositions['student_id']!;
// //     List<int> studentId = List.filled(10, -1);
// //
// //     for (int col = 0; col < 10; col++) {
// //       List<double> columnConfidences = [];
// //
// //       for (int row = 0; row < 10; row++) {
// //         var bubble = idBubbles.firstWhere((b) => b.column == col && b.value == row);
// //         double confidence = await _analyzeBubbleWithTFLite(image, bubble);
// //         columnConfidences.add(confidence);
// //       }
// //
// //       double maxConfidence = columnConfidences.reduce((a, b) => a > b ? a : b);
// //       int selectedRow = columnConfidences.indexWhere((c) => c == maxConfidence);
// //
// //       studentId[col] = maxConfidence > BUBBLE_FILL_THRESHOLD ? selectedRow : -1;
// //     }
// //
// //     return studentId;
// //   }
// //
// //   Future<List<int>> _extractMobileNumber(img.Image image) async {
// //     List<BubblePosition> mobileBubbles = _bubblePositions['mobile_number']!;
// //     List<int> mobileNumber = List.filled(11, -1);
// //
// //     for (int col = 0; col < 11; col++) {
// //       List<double> columnConfidences = [];
// //
// //       for (int row = 0; row < 10; row++) {
// //         var bubble = mobileBubbles.firstWhere((b) => b.column == col && b.value == row);
// //         double confidence = await _analyzeBubbleWithTFLite(image, bubble);
// //         columnConfidences.add(confidence);
// //       }
// //
// //       double maxConfidence = columnConfidences.reduce((a, b) => a > b ? a : b);
// //       int selectedRow = columnConfidences.indexWhere((c) => c == maxConfidence);
// //
// //       mobileNumber[col] = maxConfidence > BUBBLE_FILL_THRESHOLD ? selectedRow : -1;
// //     }
// //
// //     return mobileNumber;
// //   }
// //
// //   Future<List<String>> _extractAnswers(img.Image image) async {
// //     List<BubblePosition> answerBubbles = _bubblePositions['answers']!;
// //     List<String> answers = List.filled(40, '');
// //
// //     for (int question = 1; question <= 40; question++) {
// //       List<double> optionConfidences = [];
// //       List<BubblePosition> questionBubbles = answerBubbles.where((b) => b.question == question).toList();
// //
// //       for (var bubble in questionBubbles) {
// //         double confidence = await _analyzeBubbleWithTFLite(image, bubble);
// //         optionConfidences.add(confidence);
// //       }
// //
// //       double maxConfidence = optionConfidences.reduce((a, b) => a > b ? a : b);
// //       int selectedOption = optionConfidences.indexWhere((c) => c == maxConfidence);
// //
// //       answers[question - 1] = maxConfidence > BUBBLE_FILL_THRESHOLD ?
// //       String.fromCharCode(65 + selectedOption) : '';
// //     }
// //
// //     return answers;
// //   }
// //
// //   Future<double> _analyzeBubbleWithTFLite(img.Image image, BubblePosition bubble) async {
// //     if (_isModelLoaded && _interpreter != null) {
// //       try {
// //         return await _analyzeWithTFLite(image, bubble);
// //       } catch (e) {
// //         print('TFLite analysis failed: $e, falling back to traditional method');
// //         return await _analyzeWithTraditional(image, bubble);
// //       }
// //     } else {
// //       return await _analyzeWithTraditional(image, bubble);
// //     }
// //   }
// //
// //   Future<double> _analyzeWithTFLite(img.Image image, BubblePosition bubble) async {
// //     // Extract bubble region
// //     img.Image bubbleRegion = _extractBubbleRegion(image, bubble);
// //
// //     // Preprocess for TFLite model
// //     var input = _preprocessForTFLite(bubbleRegion);
// //
// //     // Run inference
// //     var output = List.filled(1 * 2, 0.0).reshape([1, 2]);
// //     _interpreter!.run(input, output);
// //
// //     // Return confidence for "filled" class (index 1)
// //     return output[0][1];
// //   }
// //
// //   Future<double> _analyzeWithTraditional(img.Image image, BubblePosition bubble) async {
// //     int blackPixels = 0;
// //     int totalPixels = 0;
// //
// //     int radius = bubble.radius.toInt();
// //     int centerX = bubble.x.toInt();
// //     int centerY = bubble.y.toInt();
// //
// //     for (int y = centerY - radius; y <= centerY + radius; y++) {
// //       for (int x = centerX - radius; x <= centerX + radius; x++) {
// //         if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
// //           double distance = _calculateDistance(x, y, centerX, centerY);
// //
// //           if (distance <= bubble.radius) {
// //             totalPixels++;
// //             int pixel = _safeGetPixel(image, x, y);
// //             if (pixel < 128) {
// //               blackPixels++;
// //             }
// //           }
// //         }
// //       }
// //     }
// //
// //     return totalPixels > 0 ? blackPixels / totalPixels : 0.0;
// //   }
// //
// //   img.Image _extractBubbleRegion(img.Image image, BubblePosition bubble) {
// //     int size = (bubble.radius * 2).toInt();
// //     img.Image region = img.Image(width: size, height: size, backgroundColor: img.ColorRgb8(255, 255, 255));
// //
// //     int centerX = bubble.x.toInt();
// //     int centerY = bubble.y.toInt();
// //     int startX = centerX - (size ~/ 2);
// //     int startY = centerY - (size ~/ 2);
// //
// //     for (int y = 0; y < size; y++) {
// //       for (int x = 0; x < size; x++) {
// //         int srcX = startX + x;
// //         int srcY = startY + y;
// //
// //         if (srcX >= 0 && srcX < image.width && srcY >= 0 && srcY < image.height) {
// //           int pixel = _safeGetPixel(image, srcX, srcY);
// //           region.setPixelRgba(x, y, pixel, pixel, pixel);
// //         }
// //       }
// //     }
// //
// //     return region;
// //   }
// //
// //   List<List<List<List<double>>>> _preprocessForTFLite(img.Image image) {
// //     // Resize to 28x28 for model input
// //     img.Image resized = img.copyResize(image, width: 28, height: 28);
// //
// //     // Normalize and prepare input tensor
// //     var input = List.generate(1,
// //             (i) => List.generate(28,
// //                 (j) => List.generate(28,
// //                     (k) => List.filled(1, _safeGetPixel(resized, k, j) / 255.0)
// //             )
// //         )
// //     );
// //
// //     return input;
// //   }
// // }
// //
// // class BubblePosition {
// //   final double x;
// //   final double y;
// //   final double radius;
// //   final int value;
// //   final int? column;
// //   final int? question;
// //
// //   BubblePosition(this.x, this.y, this.radius, this.value, {this.column, this.question});
// // }
// //
// // class Point {
// //   final int x;
// //   final int y;
// //
// //   Point(this.x, this.y);
// // }
// //
// // class CornerMark {
// //   final Point position;
// //   final double confidence;
// //
// //   CornerMark(this.position, this.confidence);
// // }
// //
// // class OMRResult {
// //   int setNumber = 0;
// //   List<int> studentId = [];
// //   List<int> mobileNumber = [];
// //   List<String> answers = [];
// //
// //   @override
// //   String toString() {
// //     return '''
// // Set Number: $setNumber
// // Student ID: ${studentId.join()}
// // Mobile: ${mobileNumber.join()}
// // Answers: ${answers.asMap().entries.map((e) => 'Q${e.key + 1}:${e.value}').join(', ')}
// // ''';
// //   }
// // }