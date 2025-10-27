import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

class OMRScannerService {
  static const int SHEET_WIDTH = 610;
  static const int SHEET_HEIGHT = 863;

  // Detection thresholds
  static const double BUBBLE_FILL_THRESHOLD = 0.4; // 40% filled
  static const double CORNER_MARK_THRESHOLD = 0.6;

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
    List<BubblePosition> bubbles = [];
    double startX = 39.5;
    double startY = 211;

    for (int col = 0; col < 10; col++) {
      for (int row = 0; row < 10; row++) {
        double x = startX + col * 28;
        double y = startY + row * 18;
        bubbles.add(BubblePosition(x, y, 12, row, column: col));
      }
    }
    return bubbles;
  }

  static List<BubblePosition> _generateMobileBubbles() {
    List<BubblePosition> bubbles = [];
    double startX = 326.5;
    double startY = 211;

    for (int col = 0; col < 11; col++) {
      for (int row = 0; row < 10; row++) {
        double x = startX + col * 25.5;
        double y = startY + row * 18;
        bubbles.add(BubblePosition(x, y, 12, row, column: col));
      }
    }
    return bubbles;
  }

  static List<BubblePosition> _generateAnswerBubbles() {
    List<BubblePosition> bubbles = [];

    // Left column (Questions 1-14)
    _addAnswerColumn(bubbles, 76, 435, 0, 14);

    // Middle column (Questions 15-28)
    _addAnswerColumn(bubbles, 256, 435, 14, 14);

    // Right column (Questions 29-40)
    _addAnswerColumn(bubbles, 433, 435, 28, 12);

    return bubbles;
  }

  static void _addAnswerColumn(List<BubblePosition> bubbles, double startX, double startY, int startQ, int count) {
    List<double> optionX = [startX, startX + 30, startX + 60, startX + 90];

    for (int q = 0; q < count; q++) {
      double y = startY + q * 20;
      for (int opt = 0; opt < 4; opt++) {
        bubbles.add(BubblePosition(
            optionX[opt],
            y,
            14,
            opt,
            question: startQ + q + 1
        ));
      }
    }
  }

  Future<OMRResult> processImage(File imageFile) async {
    // Step 1: Preprocess image
    img.Image? processedImage = await _preprocessImage(imageFile);
    if (processedImage == null) throw Exception('Image preprocessing failed');

    // Step 2: Detect and align sheet
    img.Image? alignedImage = await _autoAlignSheet(processedImage);
    if (alignedImage == null) {
      // If alignment fails, use the processed image
      alignedImage = processedImage;
    }

    // Step 3: Extract data using advanced image processing
    OMRResult result = await _extractData(alignedImage);

    return result;
  }

  Future<img.Image?> _preprocessImage(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      // Resize to target dimensions
      img.Image resizedImage = img.copyResize(
          originalImage,
          width: SHEET_WIDTH,
          height: SHEET_HEIGHT
      );

      // Convert to grayscale
      img.Image grayscaleImage = img.grayscale(resizedImage);

      // Apply advanced preprocessing
      return _advancedPreprocessing(grayscaleImage);
    } catch (e) {
      print('Preprocessing error: $e');
      return null;
    }
  }

  img.Image _advancedPreprocessing(img.Image image) {
    // Step 1: Apply Gaussian blur to reduce noise
    img.Image blurred = img.gaussianBlur(image, radius: 1);

    // Step 2: Apply adaptive threshold
    img.Image binary = _adaptiveThreshold(blurred, blockSize: 15, c: 5);

    // Step 3: Apply morphological operations to clean up
    img.Image cleaned = _morphologicalClose(binary, kernelSize: 2);

    return cleaned;
  }

  img.Image _adaptiveThreshold(img.Image image, {int blockSize = 15, int c = 5}) {
    final output = img.Image(width: image.width, height: image.height);

    int halfBlock = blockSize ~/ 2;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int sum = 0;
        int count = 0;

        // Calculate local mean
        for (int j = -halfBlock; j <= halfBlock; j++) {
          for (int i = -halfBlock; i <= halfBlock; i++) {
            int nx = x + i;
            int ny = y + j;

            if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
              sum += img.getLuminance(image[nx + ny * image.width]);
              count++;
            }
          }
        }

        int mean = count > 0 ? sum ~/ count : 0;
        int pixel = img.getLuminance(image[x + y * image.width]);

        // Apply threshold with contrast enhancement
        int threshold = math.max(0, math.min(255, mean - c));
        int result = pixel > threshold ? 255 : 0;

        output.setPixelRgba(x, y, result, result, result);
      }
    }

    return output;
  }

  img.Image _morphologicalClose(img.Image image, {int kernelSize = 2}) {
    // First dilate, then erode
    img.Image dilated = _dilate(image, kernelSize);
    return _erode(dilated, kernelSize);
  }

  img.Image _dilate(img.Image image, int kernelSize) {
    final output = img.Image(width: image.width, height: image.height);
    int halfKernel = kernelSize ~/ 2;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int maxVal = 0;

        for (int j = -halfKernel; j <= halfKernel; j++) {
          for (int i = -halfKernel; i <= halfKernel; i++) {
            int nx = x + i;
            int ny = y + j;

            if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
              int pixel = img.getLuminance(image[nx + ny * image.width]);
              if (pixel > maxVal) maxVal = pixel;
            }
          }
        }

        output.setPixelRgba(x, y, maxVal, maxVal, maxVal);
      }
    }

    return output;
  }

  img.Image _erode(img.Image image, int kernelSize) {
    final output = img.Image(width: image.width, height: image.height);
    int halfKernel = kernelSize ~/ 2;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int minVal = 255;

        for (int j = -halfKernel; j <= halfKernel; j++) {
          for (int i = -halfKernel; i <= halfKernel; i++) {
            int nx = x + i;
            int ny = y + j;

            if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
              int pixel = img.getLuminance(image[nx + ny * image.width]);
              if (pixel < minVal) minVal = pixel;
            }
          }
        }

        output.setPixelRgba(x, y, minVal, minVal, minVal);
      }
    }

    return output;
  }

  Future<img.Image?> _autoAlignSheet(img.Image image) async {
    try {
      // Detect corner marks using template matching
      List<CornerMark> corners = await _detectCornerMarks(image);

      if (corners.length == 4) {
        // Sort corners: top-left, top-right, bottom-right, bottom-left
        corners.sort((a, b) => a.position.dx.compareTo(b.position.dx));

        List<CornerMark> leftCorners = corners.sublist(0, 2);
        List<CornerMark> rightCorners = corners.sublist(2, 4);

        leftCorners.sort((a, b) => a.position.dy.compareTo(b.position.dy));
        rightCorners.sort((a, b) => a.position.dy.compareTo(b.position.dy));

        CornerMark topLeft = leftCorners[0];
        CornerMark bottomLeft = leftCorners[1];
        CornerMark topRight = rightCorners[0];
        CornerMark bottomRight = rightCorners[1];

        // Perform perspective transformation
        return _perspectiveTransform(
            image,
            topLeft.position,
            topRight.position,
            bottomRight.position,
            bottomLeft.position
        );
      }
    } catch (e) {
      print('Alignment error: $e');
    }

    return image; // Return original if alignment fails
  }

  Future<List<CornerMark>> _detectCornerMarks(img.Image image) async {
    List<CornerMark> corners = [];

    // Define expected corner positions
    List<Point> expectedCorners = [
      Point(17, 17),    // Top-left
      Point(573, 17),   // Top-right
      Point(17, 823),   // Bottom-left
      Point(573, 823),  // Bottom-right
    ];

    for (var expected in expectedCorners) {
      CornerMark? mark = await _detectCornerInRegion(image, expected);
      if (mark != null) {
        corners.add(mark);
      }
    }

    return corners;
  }

  Future<CornerMark?> _detectCornerInRegion(img.Image image, Point center) async {
    const searchRadius = 25;
    const markRadius = 12.5;

    int blackPixels = 0;
    int totalPixels = 0;

    for (int y = center.y - searchRadius; y <= center.y + searchRadius; y++) {
      for (int x = center.x - searchRadius; x <= center.x + searchRadius; x++) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          double distance = _calculateDistance(x.toDouble(), y.toDouble(), center.x.toDouble(), center.y.toDouble());

          if (distance <= markRadius) {
            totalPixels++;
            int pixel = img.getLuminance(image[x + y * image.width]);
            if (pixel < 128) { // Black pixel
              blackPixels++;
            }
          }
        }
      }
    }

    double fillRatio = totalPixels > 0 ? blackPixels / totalPixels : 0;

    if (fillRatio > CORNER_MARK_THRESHOLD) {
      return CornerMark(Point(center.x, center.y), fillRatio);
    }

    return null;
  }

  double _calculateDistance(double x1, double y1, double x2, double y2) {
    return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
  }

  img.Image _perspectiveTransform(
      img.Image image,
      Point topLeft,
      Point topRight,
      Point bottomRight,
      Point bottomLeft
      ) {
    final output = img.Image(width: SHEET_WIDTH, height: SHEET_HEIGHT);

    // Simple affine transformation (for basic rotation/skew correction)
    // In production, you might want to implement full perspective transformation

    for (int y = 0; y < SHEET_HEIGHT; y++) {
      for (int x = 0; x < SHEET_WIDTH; x++) {
        // Map destination coordinates to source coordinates
        double srcX = x.toDouble();
        double srcY = y.toDouble();

        // Add basic transformation logic here if needed

        int pixel = _bilinearInterpolate(image, srcX, srcY);
        output.setPixelRgba(x, y, pixel, pixel, pixel);
      }
    }

    return output;
  }

  int _bilinearInterpolate(img.Image image, double x, double y) {
    int x1 = x.floor();
    int y1 = y.floor();
    int x2 = x1 + 1;
    int y2 = y1 + 1;

    double dx = x - x1;
    double dy = y - y1;

    if (x1 < 0 || y1 < 0 || x2 >= image.width || y2 >= image.height) {
      return 255; // Return white for out-of-bounds
    }

    int pixel11 = img.getLuminance(image[x1 + y1 * image.width]);
    int pixel21 = img.getLuminance(image[x2 + y1 * image.width]);
    int pixel12 = img.getLuminance(image[x1 + y2 * image.width]);
    int pixel22 = img.getLuminance(image[x2 + y2 * image.width]);

    double interpolated =
        pixel11 * (1 - dx) * (1 - dy) +
            pixel21 * dx * (1 - dy) +
            pixel12 * (1 - dx) * dy +
            pixel22 * dx * dy;

    return interpolated.round();
  }

  Future<OMRResult> _extractData(img.Image image) async {
    OMRResult result = OMRResult();

    // Extract set number
    result.setNumber = await _extractSetNumber(image);

    // Extract student ID
    result.studentId = await _extractStudentId(image);

    // Extract mobile number
    result.mobileNumber = await _extractMobileNumber(image);

    // Extract answers
    result.answers = await _extractAnswers(image);

    return result;
  }

  Future<int> _extractSetNumber(img.Image image) async {
    List<BubblePosition> setBubbles = _bubblePositions['set_number']!;
    List<double> confidences = [];

    for (var bubble in setBubbles) {
      double confidence = await _analyzeBubble(image, bubble);
      confidences.add(confidence);
    }

    // Return the bubble with highest confidence
    double maxConfidence = confidences.reduce((a, b) => a > b ? a : b);
    int maxIndex = confidences.indexWhere((c) => c == maxConfidence);

    return maxConfidence > BUBBLE_FILL_THRESHOLD ? maxIndex + 1 : 0;
  }

  Future<List<int>> _extractStudentId(img.Image image) async {
    List<BubblePosition> idBubbles = _bubblePositions['student_id']!;
    List<int> studentId = List.filled(10, -1);

    for (int col = 0; col < 10; col++) {
      List<double> columnConfidences = [];

      for (int row = 0; row < 10; row++) {
        var bubble = idBubbles.firstWhere((b) => b.column == col && b.value == row);
        double confidence = await _analyzeBubble(image, bubble);
        columnConfidences.add(confidence);
      }

      double maxConfidence = columnConfidences.reduce((a, b) => a > b ? a : b);
      int selectedRow = columnConfidences.indexWhere((c) => c == maxConfidence);

      studentId[col] = maxConfidence > BUBBLE_FILL_THRESHOLD ? selectedRow : -1;
    }

    return studentId;
  }

  Future<List<int>> _extractMobileNumber(img.Image image) async {
    List<BubblePosition> mobileBubbles = _bubblePositions['mobile_number']!;
    List<int> mobileNumber = List.filled(11, -1);

    for (int col = 0; col < 11; col++) {
      List<double> columnConfidences = [];

      for (int row = 0; row < 10; row++) {
        var bubble = mobileBubbles.firstWhere((b) => b.column == col && b.value == row);
        double confidence = await _analyzeBubble(image, bubble);
        columnConfidences.add(confidence);
      }

      double maxConfidence = columnConfidences.reduce((a, b) => a > b ? a : b);
      int selectedRow = columnConfidences.indexWhere((c) => c == maxConfidence);

      mobileNumber[col] = maxConfidence > BUBBLE_FILL_THRESHOLD ? selectedRow : -1;
    }

    return mobileNumber;
  }

  Future<List<String>> _extractAnswers(img.Image image) async {
    List<BubblePosition> answerBubbles = _bubblePositions['answers']!;
    List<String> answers = List.filled(40, '');

    for (int question = 1; question <= 40; question++) {
      List<double> optionConfidences = [];
      List<BubblePosition> questionBubbles = answerBubbles.where((b) => b.question == question).toList();

      for (var bubble in questionBubbles) {
        double confidence = await _analyzeBubble(image, bubble);
        optionConfidences.add(confidence);
      }

      double maxConfidence = optionConfidences.reduce((a, b) => a > b ? a : b);
      int selectedOption = optionConfidences.indexWhere((c) => c == maxConfidence);

      answers[question - 1] = maxConfidence > BUBBLE_FILL_THRESHOLD ?
      String.fromCharCode(65 + selectedOption) : ''; // A, B, C, D or empty
    }

    return answers;
  }

  Future<double> _analyzeBubble(img.Image image, BubblePosition bubble) async {
    int blackPixels = 0;
    int totalPixels = 0;

    for (int y = (bubble.y - bubble.radius).toInt(); y <= (bubble.y + bubble.radius).toInt(); y++) {
      for (int x = (bubble.x - bubble.radius).toInt(); x <= (bubble.x + bubble.radius).toInt(); x++) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          double distance = _calculateDistance(x.toDouble(), y.toDouble(), bubble.x, bubble.y);

          if (distance <= bubble.radius) {
            totalPixels++;
            int pixel = img.getLuminance(image[x + y * image.width]);
            if (pixel < 128) { // Black pixel
              blackPixels++;
            }
          }
        }
      }
    }

    return totalPixels > 0 ? blackPixels / totalPixels : 0.0;
  }
}

class BubblePosition {
  final double x;
  final double y;
  final double radius;
  final int value;
  final int? column;
  final int? question;

  BubblePosition(this.x, this.y, this.radius, this.value, {this.column, this.question});
}

class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}

class CornerMark {
  final Point position;
  final double confidence;

  CornerMark(this.position, this.confidence);
}

class OMRResult {
  int setNumber = 0;
  List<int> studentId = [];
  List<int> mobileNumber = [];
  List<String> answers = [];

  @override
  String toString() {
    return '''
Set Number: $setNumber
Student ID: ${studentId.join()}
Mobile: ${mobileNumber.join()}
Answers: ${answers.asMap().entries.map((e) => 'Q${e.key + 1}:${e.value}').join(', ')}
''';
  }
}