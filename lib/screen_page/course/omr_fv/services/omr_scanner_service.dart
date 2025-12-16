import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import '../models/omr_sheet_model.dart';
import '../models/scan_result.dart';
import 'package:flutter/material.dart';
// import 'package:opencv_dart/opencv_dart.dart' as cv;
// import 'package:path_provider/path_provider.dart';


class OMRScannerService {
  final textRecognizer = TextRecognizer();

  // Enhanced detection parameters
  static const double FILLED_BUBBLE_THRESHOLD = 0.35;
  static const double MIN_CIRCULARITY = 0.7;
  static const int BUBBLE_SIZE_MIN = 8;
  static const int BUBBLE_SIZE_MAX = 30;

  Future<ScanResult> scanOMRSheet(File imageFile, OMRSheet omrSheet) async {
    try {
      // Read and decode image
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // First, try to extract text information using ML Kit
      final textData = await _extractTextData(imageFile);

      // Process image for bubble detection
      final processedImage = _preprocessImage(originalImage);

      // Detect regions of interest
      final regions = _detectRegions(processedImage);

      // Extract data from each region
      final studentId = await _extractStudentIdFromRegion(
          processedImage,
          regions['studentId']!,
          textData
      );

      final mobileNumber = await _extractMobileNumberFromRegion(
          processedImage,
          regions['mobileNumber']!,
          textData
      );

      final setNumber = await _extractSetNumberFromRegion(
          processedImage,
          regions['setNumber']!
      );

      final answers = await _extractAnswersFromRegion(
          processedImage,
          regions['answers']!,
          omrSheet.numberOfQuestions
      );

      // Calculate confidence
      final confidence = _calculateConfidence(
          studentId,
          mobileNumber,
          setNumber,
          answers,
          omrSheet.numberOfQuestions
      );

      return ScanResult(
        studentId: studentId,
        mobileNumber: mobileNumber,
        setNumber: setNumber != null ? int.tryParse(setNumber) : null,
        detectedAnswers: answers,
        confidence: confidence,
      );

    } catch (e) {
      print('Error scanning OMR sheet: $e');
      return ScanResult(
        detectedAnswers: [],
        confidence: 0.0,
        errorMessage: e.toString(),
      );
    }
  }

  Future<Map<String, String>> _extractTextData(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await textRecognizer.processImage(inputImage);

    final textData = <String, String>{};

    // Look for patterns in recognized text
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.toUpperCase();

        // Check for student ID pattern (10 digits)
        final studentIdMatch = RegExp(r'\b\d{10}\b').firstMatch(text);
        if (studentIdMatch != null) {
          textData['studentId'] = studentIdMatch.group(0)!;
        }

        // Check for mobile number pattern (11 digits)
        final mobileMatch = RegExp(r'\b\d{11}\b').firstMatch(text);
        if (mobileMatch != null) {
          textData['mobileNumber'] = mobileMatch.group(0)!;
        }

        // Check for set number
        if (text.contains('SET') && text.contains(RegExp(r'[A-D]'))) {
          final setMatch = RegExp(r'SET.*?([A-D])').firstMatch(text);
          if (setMatch != null) {
            textData['setNumber'] = setMatch.group(1)!;
          }
        }
      }
    }

    return textData;
  }

  img.Image _preprocessImage(img.Image image) {
    // Convert to grayscale
    var processed = img.grayscale(image);

    // Apply contrast enhancement
    processed = _enhanceContrast(processed);

    // Apply adaptive threshold
    processed = _adaptiveThreshold(processed, blockSize: 31, c: 10);

    // Clean up noise
    processed = _removeNoise(processed);

    return processed;
  }

  img.Image _enhanceContrast(img.Image image) {
    final enhanced = img.Image.from(image);

    // Calculate histogram
    final histogram = List<int>.filled(256, 0);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = img.getLuminance(pixel).toInt();
        histogram[gray]++;
      }
    }

    // Calculate cumulative distribution
    final cdf = List<int>.filled(256, 0);
    cdf[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i];
    }

    // Apply histogram equalization
    final totalPixels = image.width * image.height;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = img.getLuminance(pixel).toInt();
        final newValue = (cdf[gray] * 255 ~/ totalPixels).clamp(0, 255);
        enhanced.setPixel(x, y, img.ColorRgb8(newValue, newValue, newValue));
      }
    }

    return enhanced;
  }

  img.Image _adaptiveThreshold(img.Image image, {int blockSize = 31, int c = 10}) {
    final output = img.Image(width: image.width, height: image.height);
    final halfBlock = blockSize ~/ 2;

    // Create integral image for fast mean calculation
    final integral = _createIntegralImage(image);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        // Calculate local mean using integral image
        final x1 = max(0, x - halfBlock);
        final y1 = max(0, y - halfBlock);
        final x2 = min(image.width - 1, x + halfBlock);
        final y2 = min(image.height - 1, y + halfBlock);

        final area = (x2 - x1 + 1) * (y2 - y1 + 1);
        final sum = _getIntegralSum(integral, x1, y1, x2, y2);
        final mean = sum ~/ area;

        final pixel = image.getPixel(x, y);
        final value = img.getLuminance(pixel).toInt();

        final threshold = mean - c;
        final newValue = value < threshold ? 0 : 255;
        output.setPixel(x, y, img.ColorRgb8(newValue, newValue, newValue));
      }
    }

    return output;
  }

  List<List<int>> _createIntegralImage(img.Image image) {
    final integral = List.generate(
        image.height + 1,
            (_) => List<int>.filled(image.width + 1, 0)
    );

    for (int y = 1; y <= image.height; y++) {
      for (int x = 1; x <= image.width; x++) {
        final pixel = image.getPixel(x - 1, y - 1);
        final value = img.getLuminance(pixel).toInt();

        integral[y][x] = value +
            integral[y - 1][x] +
            integral[y][x - 1] -
            integral[y - 1][x - 1];
      }
    }

    return integral;
  }

  int _getIntegralSum(List<List<int>> integral, int x1, int y1, int x2, int y2) {
    return integral[y2 + 1][x2 + 1] -
        integral[y1][x2 + 1] -
        integral[y2 + 1][x1] +
        integral[y1][x1];
  }

  img.Image _removeNoise(img.Image image) {
    final cleaned = img.Image.from(image);

    // Remove small isolated components
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final pixel = image.getPixel(x, y);
        final value = img.getLuminance(pixel).toInt();

        if (value == 0) {
          // Count black neighbors
          int blackNeighbors = 0;
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dx == 0 && dy == 0) continue;
              final neighborPixel = image.getPixel(x + dx, y + dy);
              if (img.getLuminance(neighborPixel).toInt() == 0) {
                blackNeighbors++;
              }
            }
          }

          // Remove isolated pixels
          if (blackNeighbors < 2) {
            cleaned.setPixel(x, y, img.ColorRgb8(255, 255, 255));
          }
        }
      }
    }

    return cleaned;
  }

  Map<String, Rectangle<int>> _detectRegions(img.Image image) {
    // Define regions based on typical OMR sheet layout
    final regions = <String, Rectangle<int>>{};

    final width = image.width;
    final height = image.height;

    // Student ID region (typically in upper left)
    regions['studentId'] = Rectangle(
      (width * 0.05).toInt(),
      (height * 0.15).toInt(),
      (width * 0.4).toInt(),
      (height * 0.15).toInt(),
    );

    // Mobile number region (typically in upper right)
    regions['mobileNumber'] = Rectangle(
      (width * 0.5).toInt(),
      (height * 0.15).toInt(),
      (width * 0.45).toInt(),
      (height * 0.15).toInt(),
    );

    // Set number region (typically above student ID/mobile)
    regions['setNumber'] = Rectangle(
      (width * 0.1).toInt(),
      (height * 0.08).toInt(),
      (width * 0.8).toInt(),
      (height * 0.05).toInt(),
    );

    // Answers region (main grid area)
    regions['answers'] = Rectangle(
      (width * 0.05).toInt(),
      (height * 0.35).toInt(),
      (width * 0.9).toInt(),
      (height * 0.55).toInt(),
    );

    return regions;
  }

  Future<String> _extractStudentIdFromRegion(
      img.Image image,
      Rectangle<int> region,
      Map<String, String> textData
      ) async {
    // First check if we got it from text recognition
    if (textData.containsKey('studentId')) {
      return textData['studentId']!;
    }

    // Extract region
    final regionImage = _extractRegion(image, region);

    // Detect bubble grid
    final bubbleGrid = _detectBubbleGrid(regionImage, rows: 10, cols: 10);

    String studentId = '';
    for (int col = 0; col < 10; col++) {
      for (int row = 0; row < 10; row++) {
        final bubble = bubbleGrid[row][col];
        if (bubble != null && _isBubbleFilled(regionImage, bubble)) {
          studentId += row.toString();
          break;
        }
      }
    }

    return studentId;
  }

  Future<String> _extractMobileNumberFromRegion(
      img.Image image,
      Rectangle<int> region,
      Map<String, String> textData
      ) async {
    // First check if we got it from text recognition
    if (textData.containsKey('mobileNumber')) {
      return textData['mobileNumber']!;
    }

    // Extract region
    final regionImage = _extractRegion(image, region);

    // Detect bubble grid (11 columns for mobile number)
    final bubbleGrid = _detectBubbleGrid(regionImage, rows: 10, cols: 11);

    String mobileNumber = '';
    for (int col = 0; col < 11; col++) {
      for (int row = 0; row < 10; row++) {
        final bubble = bubbleGrid[row][col];
        if (bubble != null && _isBubbleFilled(regionImage, bubble)) {
          mobileNumber += row.toString();
          break;
        }
      }
    }

    return mobileNumber;
  }

  Future<String?> _extractSetNumberFromRegion(
      img.Image image,
      Rectangle<int> region
      ) async {
    // Extract region
    final regionImage = _extractRegion(image, region);

    // Detect horizontal bubble row (4 options: A, B, C, D)
    final bubbles = _detectHorizontalBubbles(regionImage, 4);

    final options = ['A', 'B', 'C', 'D'];
    for (int i = 0; i < bubbles.length && i < 4; i++) {
      if (_isBubbleFilled(regionImage, bubbles[i])) {
        return options[i];
      }
    }

    return null;
  }

  Future<List<String>> _extractAnswersFromRegion(
      img.Image image,
      Rectangle<int> region,
      int questionCount
      ) async {
    final answers = List<String>.filled(questionCount, '');

    // Extract region
    final regionImage = _extractRegion(image, region);

    // Detect answer grid
    final answerGrid = _detectAnswerGrid(regionImage, questionCount);

    for (int q = 0; q < questionCount && q < answerGrid.length; q++) {
      final options = ['A', 'B', 'C', 'D'];
      for (int opt = 0; opt < 4 && opt < answerGrid[q].length; opt++) {
        final bubble = answerGrid[q][opt];
        if (bubble != null && _isBubbleFilled(regionImage, bubble)) {
          answers[q] = options[opt];
          break;
        }
      }
    }

    return answers;
  }

  img.Image _extractRegion(img.Image image, Rectangle<int> region) {
    final extracted = img.Image(width: region.width, height: region.height);

    for (int y = 0; y < region.height; y++) {
      for (int x = 0; x < region.width; x++) {
        final srcX = region.left + x;
        final srcY = region.top + y;

        if (srcX >= 0 && srcX < image.width && srcY >= 0 && srcY < image.height) {
          final pixel = image.getPixel(srcX, srcY);
          extracted.setPixel(x, y, pixel);
        }
      }
    }

    return extracted;
  }

  List<List<Circle?>> _detectBubbleGrid(img.Image region, {required int rows, required int cols}) {
    // Initialize grid
    final grid = List.generate(
        rows,
            (_) => List<Circle?>.filled(cols, null)
    );

    // Calculate expected bubble positions
    final cellWidth = region.width / cols;
    final cellHeight = region.height / rows;
    final bubbleRadius = min(cellWidth, cellHeight) * 0.3;

    // Detect bubbles using Hough Circle Transform
    final circles = _detectCircles(region,
        minRadius: (bubbleRadius * 0.7).toInt(),
        maxRadius: (bubbleRadius * 1.3).toInt()
    );

    // Assign circles to grid positions
    for (final circle in circles) {
      final gridX = (circle.center.x / cellWidth).floor();
      final gridY = (circle.center.y / cellHeight).floor();

      if (gridX >= 0 && gridX < cols && gridY >= 0 && gridY < rows) {
        // Keep the best circle for each grid position
        if (grid[gridY][gridX] == null ||
            _getCircleScore(region, circle) > _getCircleScore(region, grid[gridY][gridX]!)) {
          grid[gridY][gridX] = circle;
        }
      }
    }

    // Fill missing bubbles with expected positions
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (grid[row][col] == null) {
          final centerX = (col + 0.5) * cellWidth;
          final centerY = (row + 0.5) * cellHeight;
          grid[row][col] = Circle(
            center: Point(centerX.toInt(), centerY.toInt()),
            radius: bubbleRadius.toInt(),
          );
        }
      }
    }

    return grid;
  }

  List<Circle> _detectHorizontalBubbles(img.Image region, int count) {
    final bubbles = <Circle>[];

    // Calculate expected positions
    final spacing = region.width / count;
    final centerY = region.height ~/ 2;
    final radius = (spacing * 0.3).toInt();

    // Detect circles
    final circles = _detectCircles(region,
        minRadius: (radius * 0.7).toInt(),
        maxRadius: (radius * 1.3).toInt()
    );

    // Sort by X position
    circles.sort((a, b) => a.center.x.compareTo(b.center.x));

    // If we found enough circles, use them
    if (circles.length >= count) {
      return circles.take(count).toList();
    }

    // Otherwise, create expected positions
    for (int i = 0; i < count; i++) {
      final centerX = ((i + 0.5) * spacing).toInt();
      bubbles.add(Circle(
        center: Point(centerX, centerY),
        radius: radius,
      ));
    }

    return bubbles;
  }

  List<List<Circle?>> _detectAnswerGrid(img.Image region, int questionCount) {
    // Typical answer sheet layout: questions in rows, options (A,B,C,D) in columns
    final questionsPerColumn = 20; // Adjust based on your sheet layout
    final columns = (questionCount / questionsPerColumn).ceil();

    final grid = List.generate(
        questionCount,
            (_) => List<Circle?>.filled(4, null) // 4 options per question
    );

    // Calculate dimensions
    final columnWidth = region.width / columns;
    final rowHeight = region.height / questionsPerColumn;
    final optionWidth = columnWidth / 4;
    final bubbleRadius = min(optionWidth, rowHeight) * 0.3;

    // Detect all circles
    final circles = _detectCircles(region,
        minRadius: (bubbleRadius * 0.7).toInt(),
        maxRadius: (bubbleRadius * 1.3).toInt()
    );

    // Assign circles to grid
    for (final circle in circles) {
      // Determine which column
      final col = (circle.center.x / columnWidth).floor();
      final localX = circle.center.x - (col * columnWidth);

      // Determine which option (A, B, C, D)
      final option = (localX / optionWidth).floor();

      // Determine which question
      final rowInColumn = (circle.center.y / rowHeight).floor();
      final questionIndex = col * questionsPerColumn + rowInColumn;

      if (questionIndex < questionCount && option < 4) {
        grid[questionIndex][option] = circle;
      }
    }

    return grid;
  }

  List<Circle> _detectCircles(img.Image image, {required int minRadius, required int maxRadius}) {
    final circles = <Circle>[];

    // Edge detection using Sobel operator
    final edges = _detectEdges(image);

    // Hough Circle Transform
    final accumulator = <String, int>{};

    // Vote for circles
    for (int y = 0; y < edges.height; y++) {
      for (int x = 0; x < edges.width; x++) {
        final pixel = edges.getPixel(x, y);
        if (img.getLuminance(pixel).toInt() > 128) {
          // This is an edge point
          for (int r = minRadius; r <= maxRadius; r++) {
            // Vote for all possible circle centers
            for (double angle = 0; angle < 2 * pi; angle += pi / 18) {
              final cx = (x - r * cos(angle)).round();
              final cy = (y - r * sin(angle)).round();

              if (cx >= 0 && cx < image.width && cy >= 0 && cy < image.height) {
                final key = '$cx,$cy,$r';
                accumulator[key] = (accumulator[key] ?? 0) + 1;
              }
            }
          }
        }
      }
    }

    // Find peaks in accumulator
    final threshold = 15; // Minimum votes
    accumulator.forEach((key, votes) {
      if (votes >= threshold) {
        final parts = key.split(',');
        circles.add(Circle(
          center: Point(int.parse(parts[0]), int.parse(parts[1])),
          radius: int.parse(parts[2]),
        ));
      }
    });

    // Remove duplicate/overlapping circles
    return _removeDuplicateCircles(circles);
  }

  img.Image _detectEdges(img.Image image) {
    final edges = img.Image(width: image.width, height: image.height);

    // Sobel operators
    final sobelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1]
    ];

    final sobelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1]
    ];

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        double gx = 0;
        double gy = 0;

        // Apply Sobel operators
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final pixel = image.getPixel(x + dx, y + dy);
            final value = img.getLuminance(pixel).toInt();

            gx += value * sobelX[dy + 1][dx + 1];
            gy += value * sobelY[dy + 1][dx + 1];
          }
        }

        // Calculate gradient magnitude
        final magnitude = sqrt(gx * gx + gy * gy).clamp(0, 255).toInt();
        edges.setPixel(x, y, img.ColorRgb8(magnitude, magnitude, magnitude));
      }
    }

    return edges;
  }

  List<Circle> _removeDuplicateCircles(List<Circle> circles) {
    final filtered = <Circle>[];

    for (final circle in circles) {
      bool isDuplicate = false;

      for (final existing in filtered) {
        final distance = sqrt(
            pow(circle.center.x - existing.center.x, 2) +
                pow(circle.center.y - existing.center.y, 2)
        );

        if (distance < (circle.radius + existing.radius) * 0.5) {
          isDuplicate = true;
          break;
        }
      }

      if (!isDuplicate) {
        filtered.add(circle);
      }
    }

    return filtered;
  }

  double _getCircleScore(img.Image image, Circle circle) {
    // Calculate how well-filled the circle is
    int darkPixels = 0;
    int totalPixels = 0;

    final r2 = circle.radius * circle.radius;

    for (int dy = -circle.radius; dy <= circle.radius; dy++) {
      for (int dx = -circle.radius; dx <= circle.radius; dx++) {
        if (dx * dx + dy * dy <= r2) {
          final x = circle.center.x + dx;
          final y = circle.center.y + dy;

          if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
            totalPixels++;
            final pixel = image.getPixel(x, y);
            if (img.getLuminance(pixel).toInt() < 128) {
              darkPixels++;
            }
          }
        }
      }
    }

    return totalPixels > 0 ? darkPixels / totalPixels.toDouble() : 0.0;
  }

  bool _isBubbleFilled(img.Image image, Circle circle) {
    final fillScore = _getCircleScore(image, circle);
    return fillScore > FILLED_BUBBLE_THRESHOLD;
  }

  double _calculateConfidence(
      String studentId,
      String mobileNumber,
      String? setNumber,
      List<String> answers,
      int totalQuestions
      ) {
    double confidence = 0.0;
    int factors = 0;

    // Student ID confidence
    if (studentId.isNotEmpty) {
      final digitCount = studentId.length;
      confidence += (digitCount / 10.0).clamp(0.0, 1.0);
      factors++;
    }

    // Mobile number confidence
    if (mobileNumber.isNotEmpty) {
      final digitCount = mobileNumber.length;
      confidence += (digitCount / 11.0).clamp(0.0, 1.0);
      factors++;
    }

    // Set number confidence
    if (setNumber != null && ['A', 'B', 'C', 'D'].contains(setNumber)) {
      confidence += 1.0;
      factors++;
    }

    // Answers confidence
    final answeredCount = answers.where((a) => a.isNotEmpty).length;
    if (totalQuestions > 0) {
      confidence += answeredCount / totalQuestions;
      factors++;
    }

    return factors > 0 ? confidence / factors : 0.0;
  }

  void dispose() {
    textRecognizer.close();
  }
}

class Circle {
  final Point<int> center;
  final int radius;

  Circle({required this.center, required this.radius});
}

// Enhanced scan result display widget
class OMRScanResultWidget extends StatelessWidget {
  final ScanResult result;

  const OMRScanResultWidget({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Results',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            _buildInfoRow('Student ID', result.studentId ?? 'Not detected'),
            _buildInfoRow(
              'Mobile Number',
              result.mobileNumber ?? 'Not detected',
            ),
            _buildInfoRow(
              'Set Number',
              result.setNumber?.toString() ?? 'Not detected',
            ),
            SizedBox(height: 16),
            Text(
              'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: result.confidence > 0.8 ? Colors.green : Colors.orange,
              ),
            ),
            if (result.errorMessage != null) ...[
              SizedBox(height: 16),
              Text(
                'Error: ${result.errorMessage}',
                style: TextStyle(color: Colors.red),
              ),
            ],
            SizedBox(height: 16),
            Text(
              'Detected Answers:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            _buildAnswersGrid(result.detectedAnswers),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildAnswersGrid(List<String> answers) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(answers.length, (index) {
        final answer = answers[index];
        return Container(
          width: 50,
          height: 30,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
            color: answer.isNotEmpty ? Colors.blue.withOpacity(0.2) : null,
          ),
          child: Center(
            child: Text(
              '${index + 1}: ${answer.isEmpty ? '-' : answer}',
              style: TextStyle(fontSize: 12),
            ),
          ),
        );
      }),
    );
  }
}

// import 'dart:io';
// import 'dart:math';
// import 'package:image/image.dart' as img;
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
//
// import '../models/omr_sheet_model.dart';
// import '../models/scan_result.dart';
//
// class OMRScannerService {
//   final textRecognizer = TextRecognizer();
//
//   // Detection parameters
//   static const double MIN_BUBBLE_FILL_RATIO = 0.3;
//   static const double MAX_BUBBLE_FILL_RATIO = 0.95;
//   static const int MIN_BUBBLE_RADIUS = 4;
//   static const int MAX_BUBBLE_RADIUS = 25;
//   static const double CIRCULARITY_THRESHOLD = 0.6;
//   static const double ASPECT_RATIO_THRESHOLD_MIN = 0.6;
//   static const double ASPECT_RATIO_THRESHOLD_MAX = 1.4;
//
//   Future<ScanResult> scanOMRSheet(File imageFile, OMRSheet omrSheet) async {
//     try {
//       final bytes = await imageFile.readAsBytes();
//       final originalImage = img.decodeImage(bytes);
//
//       if (originalImage == null) {
//         throw Exception('Failed to decode image');
//       }
//
//       // Pre-process image for better detection
//       final processedImage = _advancedPreprocessImage(originalImage);
//
//       // Detect all bubbles in the image
//       final allBubbles = _detectAllBubbles(processedImage);
//
//       // Classify bubbles by type and region
//       final classifiedBubbles = _classifyBubbles(allBubbles, processedImage);
//
//       // Extract data from classified bubbles
//       final studentId = _extractStudentId(classifiedBubbles['studentId'] ?? []);
//       final mobileNumber = _extractMobileNumber(classifiedBubbles['mobileNumber'] ?? []);
//       final setNumber = _extractSetNumber(classifiedBubbles['setNumber'] ?? []);
//       final answers = _extractAnswers(classifiedBubbles['answers'] ?? [], omrSheet.numberOfQuestions);
//
//       // Calculate overall confidence
//       final confidence = _calculateOverallConfidence(
//           studentId, mobileNumber, setNumber, answers, omrSheet.numberOfQuestions
//       );
//
//       return ScanResult(
//         studentId: studentId,
//         mobileNumber: mobileNumber,
//         setNumber: setNumber != null ? int.tryParse(setNumber) : null,
//         detectedAnswers: answers,
//         confidence: confidence,
//       );
//     } catch (e) {
//       return ScanResult(
//         detectedAnswers: [],
//         confidence: 0.0,
//         errorMessage: e.toString(),
//       );
//     }
//   }
//
//   img.Image _advancedPreprocessImage(img.Image image) {
//     // Convert to grayscale
//     var processed = img.grayscale(image);
//
//     // Apply Gaussian blur to reduce noise
//     processed = img.gaussianBlur(processed, radius: 1);
//
//     // Apply adaptive threshold for better bubble detection
//     processed = _adaptiveThreshold(processed, blockSize: 25, c: 7);
//
//     // Apply custom morphological operations to clean up the image
//     processed = _customDilate(processed, iterations: 1);
//     processed = _customErode(processed, iterations: 1);
//
//     return processed;
//   }
//
//   img.Image _adaptiveThreshold(img.Image image, {int blockSize = 15, int c = 5}) {
//     final output = img.Image(width: image.width, height: image.height);
//
//     final halfBlock = blockSize ~/ 2;
//
//     for (int y = 0; y < image.height; y++) {
//       for (int x = 0; x < image.width; x++) {
//         // Calculate local mean
//         int sum = 0;
//         int count = 0;
//
//         for (int dy = -halfBlock; dy <= halfBlock; dy++) {
//           for (int dx = -halfBlock; dx <= halfBlock; dx++) {
//             final nx = x + dx;
//             final ny = y + dy;
//
//             if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
//               final pixel = image.getPixel(nx, ny);
//               final luminance = img.getLuminance(pixel).toInt(); // FIX: Cast to int
//               sum += luminance;
//               count++;
//             }
//           }
//         }
//
//         final localMean = count > 0 ? sum ~/ count : 128;
//         final pixel = image.getPixel(x, y);
//         final luminance = img.getLuminance(pixel).toInt(); // FIX: Cast to int
//
//         // Apply adaptive threshold
//         final newValue = luminance < (localMean - c) ? 0 : 255;
//         output.setPixel(x, y, img.ColorRgb8(newValue, newValue, newValue));
//       }
//     }
//
//     return output;
//   }
//
//   // Custom dilation implementation
//   img.Image _customDilate(img.Image image, {int iterations = 1}) {
//     img.Image result = img.Image.from(image);
//
//     for (int iter = 0; iter < iterations; iter++) {
//       final temp = img.Image(width: image.width, height: image.height);
//
//       for (int y = 0; y < result.height; y++) {
//         for (int x = 0; x < result.width; x++) {
//           int maxValue = 0;
//
//           // 3x3 kernel for dilation
//           for (int dy = -1; dy <= 1; dy++) {
//             for (int dx = -1; dx <= 1; dx++) {
//               final nx = x + dx;
//               final ny = y + dy;
//
//               if (nx >= 0 && nx < result.width && ny >= 0 && ny < result.height) {
//                 final pixel = result.getPixel(nx, ny);
//                 final luminance = img.getLuminance(pixel).toInt(); // FIX: Cast to int
//                 if (luminance > maxValue) {
//                   maxValue = luminance;
//                 }
//               }
//             }
//           }
//
//           temp.setPixel(x, y, img.ColorRgb8(maxValue, maxValue, maxValue));
//         }
//       }
//       result = temp;
//     }
//
//     return result;
//   }
//
//   // Custom erosion implementation
//   img.Image _customErode(img.Image image, {int iterations = 1}) {
//     img.Image result = img.Image.from(image);
//
//     for (int iter = 0; iter < iterations; iter++) {
//       final temp = img.Image(width: image.width, height: image.height);
//
//       for (int y = 0; y < result.height; y++) {
//         for (int x = 0; x < result.width; x++) {
//           int minValue = 255;
//
//           // 3x3 kernel for erosion
//           for (int dy = -1; dy <= 1; dy++) {
//             for (int dx = -1; dx <= 1; dx++) {
//               final nx = x + dx;
//               final ny = y + dy;
//
//               if (nx >= 0 && nx < result.width && ny >= 0 && ny < result.height) {
//                 final pixel = result.getPixel(nx, ny);
//                 final luminance = img.getLuminance(pixel).toInt(); // FIX: Cast to int
//                 if (luminance < minValue) {
//                   minValue = luminance;
//                 }
//               }
//             }
//           }
//
//           temp.setPixel(x, y, img.ColorRgb8(minValue, minValue, minValue));
//         }
//       }
//       result = temp;
//     }
//
//     return result;
//   }
//
//   List<DetectedBubble> _detectAllBubbles(img.Image image) {
//     final bubbles = <DetectedBubble>[];
//
//     // Create a visited matrix to avoid duplicate detection
//     final visited = List.generate(
//         image.height,
//             (_) => List<bool>.filled(image.width, false)
//     );
//
//     for (int y = 0; y < image.height; y++) {
//       for (int x = 0; x < image.width; x++) {
//         if (!visited[y][x]) {
//           final pixel = image.getPixel(x, y);
//
//           // Look for dark pixels (potential bubbles)
//           if (img.getLuminance(pixel).toInt() < 128) { // FIX: Cast to int
//             final region = _floodFill(image, x, y, visited);
//
//             if (_isValidBubble(region)) {
//               bubbles.add(region);
//             }
//           }
//         }
//       }
//     }
//
//     // Remove overlapping bubbles (keep the one with better circularity)
//     return _removeOverlappingBubbles(bubbles);
//   }
//
//   DetectedBubble _floodFill(img.Image image, int startX, int startY, List<List<bool>> visited) {
//     final points = <Point<int>>[];
//     final queue = <Point<int>>[];
//
//     queue.add(Point(startX, startY));
//     visited[startY][startX] = true;
//
//     int minX = startX, maxX = startX;
//     int minY = startY, maxY = startY;
//
//     while (queue.isNotEmpty) {
//       final point = queue.removeAt(0);
//       points.add(point);
//
//       minX = min(minX, point.x);
//       maxX = max(maxX, point.x);
//       minY = min(minY, point.y);
//       maxY = max(maxY, point.y);
//
//       // Check 4-connected neighbors (more efficient for bubble detection)
//       final neighbors = [
//         Point(0, -1), Point(0, 1),  // top, bottom
//         Point(-1, 0), Point(1, 0),  // left, right
//       ];
//
//       for (final offset in neighbors) {
//         final nx = point.x + offset.x;
//         final ny = point.y + offset.y;
//
//         if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height &&
//             !visited[ny][nx]) {
//           final pixel = image.getPixel(nx, ny);
//           if (img.getLuminance(pixel).toInt() < 128) { // FIX: Cast to int
//             visited[ny][nx] = true;
//             queue.add(Point(nx, ny));
//           }
//         }
//       }
//     }
//
//     final centerX = (minX + maxX) ~/ 2;
//     final centerY = (minY + maxY) ~/ 2;
//     final width = maxX - minX + 1;
//     final height = maxY - minY + 1;
//     final radius = (width + height) ~/ 4;
//
//     return DetectedBubble(
//       center: Point(centerX, centerY),
//       radius: radius.toDouble(),
//       boundingBox: Rectangle(minX, minY, width, height),
//       points: points,
//       fillRatio: _calculateFillRatio(points, radius.toDouble()),
//       circularity: _calculateCircularity(points),
//       darkness: _calculateDarkness(points),
//     );
//   }
//
//   bool _isValidBubble(DetectedBubble bubble) {
//     // Check size constraints
//     if (bubble.radius < MIN_BUBBLE_RADIUS || bubble.radius > MAX_BUBBLE_RADIUS) {
//       return false;
//     }
//
//     // Check fill ratio (avoid overfilled or underfilled bubbles)
//     if (bubble.fillRatio < MIN_BUBBLE_FILL_RATIO ||
//         bubble.fillRatio > MAX_BUBBLE_FILL_RATIO) {
//       return false;
//     }
//
//     // Check circularity
//     if (bubble.circularity < CIRCULARITY_THRESHOLD) {
//       return false;
//     }
//
//     // Check aspect ratio
//     final aspectRatio = bubble.boundingBox.width.toDouble() / bubble.boundingBox.height.toDouble();
//     if (aspectRatio < ASPECT_RATIO_THRESHOLD_MIN || aspectRatio > ASPECT_RATIO_THRESHOLD_MAX) {
//       return false;
//     }
//
//     // Check darkness (should be sufficiently filled)
//     if (bubble.darkness < 0.4) {
//       return false;
//     }
//
//     return true;
//   }
//
//   List<DetectedBubble> _removeOverlappingBubbles(List<DetectedBubble> bubbles) {
//     final nonOverlapping = <DetectedBubble>[];
//
//     for (final bubble in bubbles) {
//       bool isOverlapping = false;
//
//       for (final existing in nonOverlapping) {
//         final distance = sqrt(
//             pow(bubble.center.x - existing.center.x, 2) +
//                 pow(bubble.center.y - existing.center.y, 2)
//         );
//
//         if (distance < (bubble.radius + existing.radius) * 0.8) {
//           // Keep the bubble with better circularity
//           if (bubble.circularity > existing.circularity) {
//             nonOverlapping.remove(existing);
//             nonOverlapping.add(bubble);
//           }
//           isOverlapping = true;
//           break;
//         }
//       }
//
//       if (!isOverlapping) {
//         nonOverlapping.add(bubble);
//       }
//     }
//
//     return nonOverlapping;
//   }
//
//   double _calculateFillRatio(List<Point<int>> points, double radius) {
//     final area = points.length.toDouble();
//     final circleArea = pi * radius * radius;
//     return area / circleArea;
//   }
//
//   double _calculateCircularity(List<Point<int>> points) {
//     if (points.length < 5) return 0.0;
//
//     // Calculate centroid
//     double sumX = 0, sumY = 0;
//     for (final point in points) {
//       sumX += point.x;
//       sumY += point.y;
//     }
//     final centroidX = sumX / points.length;
//     final centroidY = sumY / points.length;
//
//     // Calculate mean distance from centroid
//     double sumDistances = 0;
//     for (final point in points) {
//       final distance = sqrt(pow(point.x - centroidX, 2) + pow(point.y - centroidY, 2));
//       sumDistances += distance;
//     }
//     final meanDistance = sumDistances / points.length;
//
//     // Calculate standard deviation of distances
//     double sumSquaredDifferences = 0;
//     for (final point in points) {
//       final distance = sqrt(pow(point.x - centroidX, 2) + pow(point.y - centroidY, 2));
//       sumSquaredDifferences += pow(distance - meanDistance, 2);
//     }
//     final stdDev = sqrt(sumSquaredDifferences / points.length);
//
//     // Circularity is higher when standard deviation is low
//     final circularity = 1.0 / (1.0 + stdDev);
//     return circularity.clamp(0.0, 1.0);
//   }
//
//   double _calculateDarkness(List<Point<int>> points) {
//     // For simplicity, return 1.0 since we're working with binary images
//     // In a real implementation, you'd analyze the original image
//     return 1.0;
//   }
//
//   Map<String, List<DetectedBubble>> _classifyBubbles(
//       List<DetectedBubble> allBubbles, img.Image image) {
//
//     final classified = <String, List<DetectedBubble>>{
//       'studentId': [],
//       'mobileNumber': [],
//       'setNumber': [],
//       'answers': [],
//     };
//
//     // Sort bubbles by position (top to bottom, left to right)
//     allBubbles.sort((a, b) {
//       if (a.center.y != b.center.y) {
//         return a.center.y.compareTo(b.center.y);
//       }
//       return a.center.x.compareTo(b.center.x);
//     });
//
//     // Define regions based on image dimensions
//     final headerHeight = image.height * 0.3;
//
//     for (final bubble in allBubbles) {
//       if (bubble.center.y < headerHeight) {
//         // Header region - classify based on horizontal position
//         if (bubble.center.x < image.width * 0.3) {
//           // Left section - student ID
//           classified['studentId']!.add(bubble);
//         } else if (bubble.center.x < image.width * 0.6) {
//           // Middle section - mobile number
//           classified['mobileNumber']!.add(bubble);
//         } else {
//           // Right section - set number
//           classified['setNumber']!.add(bubble);
//         }
//       } else {
//         // Answer region
//         classified['answers']!.add(bubble);
//       }
//     }
//
//     return classified;
//   }
//
//   String _extractStudentId(List<DetectedBubble> bubbles) {
//     if (bubbles.isEmpty) return '';
//
//     // Sort by position (left to right, top to bottom)
//     bubbles.sort((a, b) {
//       if (a.center.y != b.center.y) {
//         return a.center.y.compareTo(b.center.y);
//       }
//       return a.center.x.compareTo(b.center.x);
//     });
//
//     // Group into digits (assuming 2 rows of 5 digits)
//     final digitGroups = _groupIntoDigits(bubbles, 10);
//
//     String studentId = '';
//     for (final digitBubbles in digitGroups) {
//       studentId += _detectFilledOption(digitBubbles, 10);
//     }
//
//     return studentId;
//   }
//
//   String _extractMobileNumber(List<DetectedBubble> bubbles) {
//     if (bubbles.isEmpty) return '';
//
//     bubbles.sort((a, b) {
//       if (a.center.y != b.center.y) {
//         return a.center.y.compareTo(b.center.y);
//       }
//       return a.center.x.compareTo(b.center.x);
//     });
//
//     final digitGroups = _groupIntoDigits(bubbles, 11);
//
//     String mobileNumber = '';
//     for (final digitBubbles in digitGroups) {
//       mobileNumber += _detectFilledOption(digitBubbles, 10);
//     }
//
//     return mobileNumber;
//   }
//
//   String? _extractSetNumber(List<DetectedBubble> bubbles) {
//     if (bubbles.isEmpty) return null;
//
//     // Sort set bubbles left to right
//     bubbles.sort((a, b) => a.center.x.compareTo(b.center.x));
//
//     // Options are typically A, B, C, D (4 options)
//     final options = ['A', 'B', 'C', 'D'];
//     for (int i = 0; i < min(bubbles.length, 4); i++) {
//       if (_isBubbleConfidentlyFilled(bubbles[i])) {
//         return options[i];
//       }
//     }
//
//     return null;
//   }
//
//   List<String> _extractAnswers(List<DetectedBubble> answerBubbles, int questionCount) {
//     final answers = List<String>.filled(questionCount, '');
//
//     if (answerBubbles.isEmpty) return answers;
//
//     // Group bubbles by question rows
//     final questionRows = _groupBubblesByRows(answerBubbles);
//
//     for (int i = 0; i < min(questionRows.length, questionCount); i++) {
//       final rowBubbles = questionRows[i];
//
//       // Sort left to right for options A, B, C, D
//       rowBubbles.sort((a, b) => a.center.x.compareTo(b.center.x));
//
//       // Check each option bubble
//       for (int j = 0; j < min(rowBubbles.length, 4); j++) {
//         if (_isBubbleConfidentlyFilled(rowBubbles[j])) {
//           final options = ['A', 'B', 'C', 'D'];
//           answers[i] = options[j];
//           break;
//         }
//       }
//     }
//
//     return answers;
//   }
//
//   List<List<DetectedBubble>> _groupIntoDigits(List<DetectedBubble> bubbles, int digitCount) {
//     if (bubbles.isEmpty) return List.generate(digitCount, (_) => []);
//
//     // Simple grouping: assume bubbles are already roughly in grid formation
//     final groups = <List<DetectedBubble>>[];
//
//     // Sort by X position and group by proximity
//     bubbles.sort((a, b) => a.center.x.compareTo(b.center.x));
//
//     double? lastX;
//     List<DetectedBubble> currentGroup = [];
//
//     for (final bubble in bubbles) {
//       if (lastX == null) {
//         currentGroup.add(bubble);
//         lastX = bubble.center.x.toDouble();
//       } else {
//         final xDiff = (bubble.center.x - lastX).abs();
//
//         if (xDiff < 30) { // Threshold for same digit column
//           currentGroup.add(bubble);
//         } else {
//           groups.add(List.from(currentGroup));
//           currentGroup = [bubble];
//           lastX = bubble.center.x.toDouble();
//         }
//       }
//     }
//
//     if (currentGroup.isNotEmpty) {
//       groups.add(currentGroup);
//     }
//
//     return groups;
//   }
//
//   List<List<DetectedBubble>> _groupBubblesByRows(List<DetectedBubble> bubbles) {
//     if (bubbles.isEmpty) return [];
//
//     // Sort by vertical position
//     bubbles.sort((a, b) => a.center.y.compareTo(b.center.y));
//
//     final rows = <List<DetectedBubble>>[];
//     List<DetectedBubble> currentRow = [];
//     double? lastY;
//
//     for (final bubble in bubbles) {
//       if (lastY == null) {
//         currentRow.add(bubble);
//         lastY = bubble.center.y.toDouble();
//       } else {
//         final yDiff = (bubble.center.y - lastY).abs();
//
//         if (yDiff < 25) { // Threshold for same row
//           currentRow.add(bubble);
//         } else {
//           rows.add(List.from(currentRow));
//           currentRow = [bubble];
//           lastY = bubble.center.y.toDouble();
//         }
//       }
//     }
//
//     if (currentRow.isNotEmpty) {
//       rows.add(currentRow);
//     }
//
//     return rows;
//   }
//
//   String _detectFilledOption(List<DetectedBubble> optionBubbles, int optionCount) {
//     if (optionBubbles.isEmpty) return '';
//
//     // Sort by vertical position (0-9 from top to bottom)
//     optionBubbles.sort((a, b) => a.center.y.compareTo(b.center.y));
//
//     for (int i = 0; i < min(optionBubbles.length, optionCount); i++) {
//       if (_isBubbleConfidentlyFilled(optionBubbles[i])) {
//         return i.toString();
//       }
//     }
//
//     return '';
//   }
//
//   bool _isBubbleConfidentlyFilled(DetectedBubble bubble) {
//     return bubble.fillRatio > MIN_BUBBLE_FILL_RATIO &&
//         bubble.circularity > CIRCULARITY_THRESHOLD &&
//         bubble.radius >= MIN_BUBBLE_RADIUS;
//   }
//
//   double _calculateOverallConfidence(
//       String studentId, String mobileNumber, String? setNumber,
//       List<String> answers, int totalQuestions) {
//
//     double confidence = 0.0;
//     int factors = 0;
//
//     // Student ID confidence (10 digits expected)
//     if (studentId.isNotEmpty) {
//       confidence += studentId.length / 10;
//       factors++;
//     }
//
//     // Mobile number confidence (11 digits expected)
//     if (mobileNumber.isNotEmpty) {
//       confidence += mobileNumber.length / 11;
//       factors++;
//     }
//
//     // Set number confidence
//     if (setNumber != null && setNumber.isNotEmpty) {
//       confidence += 1.0;
//       factors++;
//     }
//
//     // Answers confidence
//     final answeredQuestions = answers.where((a) => a.isNotEmpty).length;
//     if (totalQuestions > 0) {
//       confidence += answeredQuestions / totalQuestions;
//       factors++;
//     }
//
//     return factors > 0 ? confidence / factors : 0.0;
//   }
//
//   void dispose() {
//     textRecognizer.close();
//   }
// }
//
// class DetectedBubble {
//   final Point<int> center;
//   final double radius;
//   final Rectangle<int> boundingBox;
//   final List<Point<int>> points;
//   final double fillRatio;
//   final double circularity;
//   final double darkness;
//
//   DetectedBubble({
//     required this.center,
//     required this.radius,
//     required this.boundingBox,
//     required this.points,
//     required this.fillRatio,
//     required this.circularity,
//     required this.darkness,
//   });
//
//   @override
//   String toString() {
//     return 'Bubble(center: $center, radius: $radius, fill: ${(fillRatio * 100).toStringAsFixed(1)}%, circularity: ${(circularity * 100).toStringAsFixed(1)}%)';
//   }
// }

// Supporting classes
// class ScanResult {
//   final String? studentId;
//   final String? mobileNumber;
//   final int? setNumber;
//   final List<String> detectedAnswers;
//   final double confidence;
//   final String? errorMessage;
//
//   ScanResult({
//     this.studentId,
//     this.mobileNumber,
//     this.setNumber,
//     required this.detectedAnswers,
//     required this.confidence,
//     this.errorMessage,
//   });
// }
//
// class OMRSheet {
//   final String id;
//   final String examName;
//   final int numberOfQuestions;
//   final List<String> correctAnswers;
//   final int setNumber;
//
//   OMRSheet({
//     required this.id,
//     required this.examName,
//     required this.numberOfQuestions,
//     required this.correctAnswers,
//     required this.setNumber,
//   });
// }

// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
// import '../models/exam_result_model.dart';
// import '../models/omr_sheet_model.dart';
// import '../models/student_model.dart';
//
// class ScanResult {
//   final String? studentId;
//   final String? mobileNumber;
//   final int? setNumber;
//   final List<String> detectedAnswers;
//   final double confidence;
//   final String? errorMessage;
//
//   ScanResult({
//     this.studentId,
//     this.mobileNumber,
//     this.setNumber,
//     required this.detectedAnswers,
//     required this.confidence,
//     this.errorMessage,
//   });
// }
//
// class OMRScannerService {
//   final textRecognizer = TextRecognizer();
//
//   // Bubble detection parameters
//   static const double BUBBLE_MIN_RADIUS = 6.0;
//   static const double BUBBLE_MAX_RADIUS = 15.0;
//   static const double DARKNESS_THRESHOLD = 0.3;
//
//   Future<ScanResult> scanOMRSheet(File imageFile, OMRSheet omrSheet) async {
//     try {
//       // Read and process image
//       final bytes = await imageFile.readAsBytes();
//       final image = img.decodeImage(bytes);
//
//       if (image == null) {
//         throw Exception('Failed to decode image');
//       }
//
//       // Pre-process image
//       final processedImage = _preprocessImage(image);
//
//       // Extract text information (student ID, mobile number)
//       final textData = await _extractTextData(imageFile);
//
//       // Detect filled bubbles
//       final answers = _detectAnswers(processedImage, omrSheet.numberOfQuestions);
//
//       // Calculate confidence score
//       final confidence = _calculateConfidence(answers);
//
//       return ScanResult(
//         studentId: textData['studentId'],
//         mobileNumber: textData['mobileNumber'],
//         setNumber: textData['setNumber'] != null ? int.tryParse(textData['setNumber']!) : null,
//         detectedAnswers: answers,
//         confidence: confidence,
//       );
//     } catch (e) {
//       return ScanResult(
//         detectedAnswers: [],
//         confidence: 0.0,
//         errorMessage: e.toString(),
//       );
//     }
//   }
//
//   img.Image _preprocessImage(img.Image image) {
//     // Convert to grayscale
//     final grayscale = img.grayscale(image);
//
//     // Apply adaptive threshold
//     final threshold = _adaptiveThreshold(grayscale);
//
//     // Remove noise
//     final denoised = img.gaussianBlur(threshold, radius: 1);
//
//     return denoised;
//   }
//
//   img.Image _adaptiveThreshold(img.Image image) {
//     final result = img.Image(width: image.width, height: image.height);
//
//     for (int y = 0; y < image.height; y++) {
//       for (int x = 0; x < image.width; x++) {
//         final pixel = image.getPixel(x, y);
//         final luminance = img.getLuminance(pixel);
//
//         // Simple threshold - can be improved with adaptive methods
//         final newPixel = luminance > 128 ? img.ColorRgb8(255, 255, 255) : img.ColorRgb8(0, 0, 0);
//         result.setPixel(x, y, newPixel);
//       }
//     }
//
//     return result;
//   }
//
//   Future<Map<String, String?>> _extractTextData(File imageFile) async {
//     final inputImage = InputImage.fromFile(imageFile);
//     final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
//
//     String? studentId;
//     String? mobileNumber;
//     String? setNumber;
//
//     // Pattern matching for student ID and mobile number
//     final studentIdPattern = RegExp(r'\b\d{10}\b');
//     final mobilePattern = RegExp(r'\b\d{11}\b');
//     final setPattern = RegExp(r'SET.*?(\d)');
//
//     for (TextBlock block in recognizedText.blocks) {
//       final text = block.text;
//
//       // Extract student ID
//       if (studentId == null) {
//         final match = studentIdPattern.firstMatch(text);
//         if (match != null) {
//           studentId = match.group(0);
//         }
//       }
//
//       // Extract mobile number
//       if (mobileNumber == null) {
//         final match = mobilePattern.firstMatch(text);
//         if (match != null) {
//           mobileNumber = match.group(0);
//         }
//       }
//
//       // Extract set number
//       if (setNumber == null) {
//         final match = setPattern.firstMatch(text);
//         if (match != null) {
//           setNumber = match.group(1);
//         }
//       }
//     }
//
//     return {
//       'studentId': studentId,
//       'mobileNumber': mobileNumber,
//       'setNumber': setNumber,
//     };
//   }
//
//   List<String> _detectAnswers(img.Image image, int numberOfQuestions) {
//     final answers = List<String>.filled(numberOfQuestions, '');
//
//     // Define regions for answer bubbles based on standard OMR layout
//     // This is a simplified version - in production, you'd need precise coordinates
//     final answerRegions = _getAnswerRegions(image.width, image.height, numberOfQuestions);
//
//     for (int i = 0; i < numberOfQuestions; i++) {
//       final region = answerRegions[i];
//       final detectedOption = _detectFilledBubble(image, region);
//       answers[i] = detectedOption;
//     }
//
//     return answers;
//   }
//
//   List<AnswerRegion> _getAnswerRegions(int imageWidth, int imageHeight, int questions) {
//     final regions = <AnswerRegion>[];
//
//     // Calculate positions based on standard 3-column layout
//     final questionsPerColumn = (questions / 3).ceil();
//     final columnWidth = imageWidth / 3;
//     final startY = imageHeight * 0.5; // Start from middle of page
//     final rowHeight = (imageHeight * 0.4) / questionsPerColumn;
//
//     for (int i = 0; i < questions; i++) {
//       final column = i ~/ questionsPerColumn;
//       final row = i % questionsPerColumn;
//
//       final x = column * columnWidth + 50;
//       final y = startY + row * rowHeight;
//
//       regions.add(AnswerRegion(
//         questionNumber: i + 1,
//         x: x,
//         y: y,
//         width: columnWidth - 100,
//         height: rowHeight - 5,
//       ));
//     }
//
//     return regions;
//   }
//
//   String _detectFilledBubble(img.Image image, AnswerRegion region) {
//     final options = ['A', 'B', 'C', 'D'];
//     final bubbleWidth = region.width / 4;
//
//     String detectedAnswer = '';
//     double maxDarkness = 0;
//
//     for (int i = 0; i < options.length; i++) {
//       final bubbleX = region.x + i * bubbleWidth;
//       final darkness = _calculateBubbleDarkness(
//         image,
//         bubbleX.toInt(),
//         region.y.toInt(),
//         bubbleWidth.toInt(),
//         region.height.toInt(),
//       );
//
//       if (darkness > DARKNESS_THRESHOLD && darkness > maxDarkness) {
//         maxDarkness = darkness;
//         detectedAnswer = options[i];
//       }
//     }
//
//     return detectedAnswer;
//   }
//
//   double _calculateBubbleDarkness(img.Image image, int x, int y, int width, int height) {
//     int darkPixels = 0;
//     int totalPixels = 0;
//
//     for (int dy = 0; dy < height; dy++) {
//       for (int dx = 0; dx < width; dx++) {
//         final px = x + dx;
//         final py = y + dy;
//
//         if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
//           final pixel = image.getPixel(px, py);
//           final luminance = img.getLuminance(pixel);
//
//           if (luminance < 128) {
//             darkPixels++;
//           }
//           totalPixels++;
//         }
//       }
//     }
//
//     return totalPixels > 0 ? darkPixels / totalPixels : 0;
//   }
//
//   double _calculateConfidence(List<String> answers) {
//     int validAnswers = answers.where((a) => a.isNotEmpty).length;
//     return validAnswers / answers.length;
//   }
//
//   void dispose() {
//     textRecognizer.close();
//   }
// }
//
// class AnswerRegion {
//   final int questionNumber;
//   final double x;
//   final double y;
//   final double width;
//   final double height;
//
//   AnswerRegion({
//     required this.questionNumber,
//     required this.x,
//     required this.y,
//     required this.width,
//     required this.height,
//   });
// }
//

// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;
// import 'package:opencv_dart/opencv_dart.dart' as cv; // Add this import
// import '../models/exam_result_model.dart';
// import '../models/omr_sheet_model.dart';
// import '../models/student_model.dart';
//
// class ScanResult {
//   final String? studentId;
//   final String? mobileNumber;
//   final int? setNumber;
//   final List<String> detectedAnswers;
//   final double confidence;
//   final String? errorMessage;
//
//   ScanResult({
//     this.studentId,
//     this.mobileNumber,
//     this.setNumber,
//     required this.detectedAnswers,
//     required this.confidence,
//     this.errorMessage,
//   });
// }
//
// class OMRScannerService {
//   static const double FILL_THRESHOLD = 0.7; // 70% dark pixels = filled
//   static const int NUM_QUESTIONS = 40; // From your sheet
//
//   Future<ScanResult> scanOMRSheet(File imageFile, OMRSheet omrSheet) async {
//     try {
//       // Load image with OpenCV
//       final mat = await cv.imreadAsync(imageFile.path);
//       if (mat.isEmpty) throw Exception('Failed to load image');
//
//       // Preprocess: Grayscale, deskew, threshold
//       final gray = cv.cvtColor(mat, cv.COLOR_BGR2GRAY);
//       final deskewed = _deskewImage(gray); // Align tilted scans
//       final thresh = cv.adaptiveThreshold(deskewed, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY, 11, 2);
//
//       // Convert back to img.Image for compatibility
//       final processedImage = img.decodeImage(Uint8List.fromList(cv.imencode('.png', thresh).$2))!;
//
//       // Detect fields using bubble grids
//       final setNumber = _detectSetNumber(processedImage);
//       final studentId = _detectDigitField(processedImage, isStudentId: true); // 10 digits
//       final mobileNumber = _detectDigitField(processedImage, isStudentId: false); // 11 digits
//       final answers = _detectAnswers(processedImage, NUM_QUESTIONS);
//
//       // Confidence: Average fill confidence across all detected bubbles
//       final confidence = _calculateConfidence(answers, studentId, mobileNumber, setNumber);
//
//       return ScanResult(
//         studentId: studentId,
//         mobileNumber: mobileNumber,
//         setNumber: setNumber,
//         detectedAnswers: answers,
//         confidence: confidence,
//       );
//     } catch (e) {
//       return ScanResult(
//         detectedAnswers: [],
//         confidence: 0.0,
//         errorMessage: e.toString(),
//       );
//     }
//   }
//
//   cv.Mat _deskewImage(cv.Mat gray) {
//     final edges = cv.canny(gray, 50, 150);
//     final linesMat = cv.HoughLinesP(edges, 1, cv.CV_PI / 180, 100, minLineLength: 100, maxLineGap: 10);
//
//     final lines = <LineSegment>[];
//     for (int i = 0; i < linesMat.rows; i++) {
//       final line = linesMat.row(i);
//       final pt1 = cv.Point(line.at(0, 0), line.at(0, 1));
//       final pt2 = cv.Point(line.at(0, 2), line.at(0, 3));
//       lines.add(LineSegment(pt1: pt1, pt2: pt2));
//     }
//
//     if (lines.isNotEmpty) {
//       double angle = 0;
//       for (var line in lines) {
//         angle += (line.pt2.y - line.pt1.y) / (line.pt2.x - line.pt1.x);
//       }
//       angle = angle / lines.length * (180 / cv.CV_PI);
//       return cv.rotate(gray, angle.toInt());
//     }
//
//     return gray;
//   }
//
//
//
//
//   int? _detectSetNumber(img.Image image) {
//     // Set Number: 4 horizontal bubbles (1-4) at top (approx 10-15% from top)
//     final bubbles = _getBubblePositions(image, field: 'set', numOptions: 4);
//     for (int i = 0; i < bubbles.length; i++) {
//       if (_isBubbleFilled(image, bubbles[i])) return i + 1;
//     }
//     return null;
//   }
//
//   String _detectDigitField(img.Image image, {required bool isStudentId}) {
//     // Student ID: 10 digits, Mobile: 11 digits, each digit has 10 vertical bubbles (0-9)
//     final numDigits = isStudentId ? 10 : 11;
//     final digits = <int>[];
//     final fieldPositions = _getBubblePositions(image, field: isStudentId ? 'studentId' : 'mobile', numOptions: numDigits * 10);
//
//     for (int d = 0; d < numDigits; d++) {
//       int? detectedDigit;
//       for (int opt = 0; opt < 10; opt++) { // 0-9
//         final index = d * 10 + opt;
//         if (_isBubbleFilled(image, fieldPositions[index])) {
//           detectedDigit = opt;
//           break;
//         }
//       }
//       digits.add(detectedDigit ?? -1); // -1 for undetected
//     }
//     return digits.map((d) => d >= 0 ? d.toString() : '').join();
//   }
//
//   List<String> _detectAnswers(img.Image image, int numQuestions) {
//     final answers = List<String>.filled(numQuestions, '');
//     final bubbles = _getBubblePositions(image, field: 'answers', numOptions: numQuestions * 4); // 4 options per question
//
//     for (int q = 0; q < numQuestions; q++) {
//       final options = ['A', 'B', 'C', 'D'];
//       for (int opt = 0; opt < 4; opt++) {
//         final index = q * 4 + opt;
//         if (_isBubbleFilled(image, bubbles[index])) {
//           answers[q] = options[opt];
//           break;
//         }
//       }
//     }
//     return answers;
//   }
//
//   List<Rect> _getBubblePositions(img.Image image, {required String field, required int numOptions}) {
//     // Relative positions based on your sheet layout (calibrate these percentages from image analysis)
//     final regions = <Rect>[];
//     final w = image.width.toDouble();
//     final h = image.height.toDouble();
//
//     if (field == 'set') {
//       // Top, horizontal, 4 bubbles ~10% from top, spaced across 20-80% width
//       final y = h * 0.1;
//       final bubbleSize = w * 0.03;
//       for (int i = 0; i < 4; i++) {
//         final x = w * (0.2 + i * 0.15);
//         regions.add(Rect.fromLTWH(x, y, bubbleSize, bubbleSize));
//       }
//     } else if (field == 'studentId') {
//       // Below set, 10 digits, each with 10 vertical bubbles (0-9), left side ~15-25% from top
//       final startY = h * 0.15;
//       final digitWidth = w * 0.05;
//       final bubbleHeight = h * 0.02;
//       for (int d = 0; d < 10; d++) {
//         final x = w * 0.1 + d * digitWidth;
//         for (int opt = 0; opt < 10; opt++) {
//           final y = startY + opt * bubbleHeight;
//           regions.add(Rect.fromLTWH(x, y, digitWidth * 0.8, bubbleHeight * 0.8));
//         }
//       }
//     } else if (field == 'mobile') {
//       // Similar to studentId but right side, 11 digits
//       final startY = h * 0.15;
//       final digitWidth = w * 0.05;
//       final bubbleHeight = h * 0.02;
//       for (int d = 0; d < 11; d++) {
//         final x = w * 0.5 + d * digitWidth;
//         for (int opt = 0; opt < 10; opt++) {
//           final y = startY + opt * bubbleHeight;
//           regions.add(Rect.fromLTWH(x, y, digitWidth * 0.8, bubbleHeight * 0.8));
//         }
//       }
//     } else if (field == 'answers') {
//       // 3 columns, 40 questions, starting ~30% from top
//       final questionsPerCol = (NUM_QUESTIONS / 3).ceil();
//       final colWidth = w / 3;
//       final startY = h * 0.3;
//       final rowHeight = (h * 0.6) / questionsPerCol;
//       final optWidth = colWidth / 5; // A/B/C/D + question num space
//       for (int q = 0; q < NUM_QUESTIONS; q++) {
//         final col = q ~/ questionsPerCol;
//         final row = q % questionsPerCol;
//         final xBase = col * colWidth + optWidth;
//         final y = startY + row * rowHeight;
//         for (int opt = 0; opt < 4; opt++) {
//           final x = xBase + opt * optWidth;
//           regions.add(Rect.fromLTWH(x, y, optWidth * 0.8, rowHeight * 0.8));
//         }
//       }
//     }
//     return regions;
//   }
//
//   bool _isBubbleFilled(img.Image image, Rect region) {
//     int darkPixels = 0;
//     int totalPixels = 0;
//     for (int y = region.top.toInt(); y < region.bottom.toInt(); y++) {
//       for (int x = region.left.toInt(); x < region.right.toInt(); x++) {
//         if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
//           final pixel = image.getPixel(x, y);
//           totalPixels++;
//           if (img.getLuminance(pixel) < 128) darkPixels++;
//         }
//       }
//     }
//     return (darkPixels / totalPixels) > FILL_THRESHOLD;
//   }
//
//   double _calculateConfidence(List<String> answers, String studentId, String mobile, int? set) {
//     // Simple: % of detected fields
//     double score = 0;
//     score += answers.where((a) => a.isNotEmpty).length / answers.length;
//     score += (studentId.length == 10 ? 1 : 0);
//     score += (mobile.length == 11 ? 1 : 0);
//     score += (set != null ? 1 : 0);
//     return score / 4; // Average
//   }
//
// }
// class LineSegment {
//   final cv.Point pt1;
//   final cv.Point pt2;
//
//   LineSegment({required this.pt1, required this.pt2});
// }
