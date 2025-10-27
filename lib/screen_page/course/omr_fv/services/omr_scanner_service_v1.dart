import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// Models
class OMRScanResult {
  final String? studentId;
  final String? mobileNumber;
  final int? setNumber;
  final List<String> answers;
  final double confidence;
  final String? errorMessage;
  final Map<String, dynamic>? evaluation;

  OMRScanResult({
    this.studentId,
    this.mobileNumber,
    this.setNumber,
    required this.answers,
    required this.confidence,
    this.errorMessage,
    this.evaluation,
  });
}

class BubbleRegion {
  final int row;
  final int col;
  final double x;
  final double y;
  final double radius;
  final String value;

  BubbleRegion({
    required this.row,
    required this.col,
    required this.x,
    required this.y,
    required this.radius,
    required this.value,
  });
}

class OMRSheetLayout {
  // Define precise coordinates for your OMR sheet layout
  static const double sheetWidth = 595.0;  // A4 width
  static const double sheetHeight = 842.0; // A4 height

  // Set number bubbles
  static const double setNumberY = 110.0;
  static const double setNumberStartX = 140.0;
  static const double setNumberSpacing = 80.0;

  // ID and Mobile number grid
  static const double idGridStartX = 40.0;
  static const double idGridStartY = 150.0;
  static const double mobileGridStartX = 320.0;
  static const double mobileGridStartY = 150.0;

  // Answer grid
  static const double answerGridStartY = 400.0;
  static const double answerColumnWidth = 180.0;
  static const double answerRowHeight = 22.0;

  // Bubble parameters
  static const double bubbleRadius = 7.0;
  static const double digitBubbleRadius = 5.0;
  static const double bubbleSpacing = 25.0;
  static const double digitBubbleSpacing = 18.0;
}

class AdvancedOMRScanner {
  final textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();

  // Scanning parameters
  static const double DARKNESS_THRESHOLD = 0.45;
  static const double MIN_CONFIDENCE = 0.7;
  static const int GAUSSIAN_BLUR_RADIUS = 1;
  static const int MORPHOLOGY_ITERATIONS = 2;

  Future<OMRScanResult> scanOMRSheet({
    required File imageFile,
    required List<String> answerKey,
    required int numberOfQuestions,
  }) async {
    try {
      // Load and decode image
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Pre-process image for better detection
      final processedImage = await _preprocessImage(originalImage);

      // Detect sheet corners and perform perspective correction
      final correctedImage = await _performPerspectiveCorrection(processedImage);

      // Scale image to standard size
      final standardImage = _scaleToStandardSize(correctedImage);

      // Detect all filled bubbles
      final setNumber = await _detectSetNumber(standardImage);
      final studentId = await _detectStudentId(standardImage);
      final mobileNumber = await _detectMobileNumber(standardImage);
      final answers = await _detectAnswers(standardImage, numberOfQuestions);

      // Calculate confidence
      final confidence = _calculateOverallConfidence(answers, studentId, mobileNumber);

      // Evaluate results if answer key provided
      Map<String, dynamic>? evaluation;
      if (answerKey.isNotEmpty) {
        evaluation = _evaluateAnswers(answers, answerKey);
      }

      return OMRScanResult(
        studentId: studentId,
        mobileNumber: mobileNumber,
        setNumber: setNumber,
        answers: answers,
        confidence: confidence,
        evaluation: evaluation,
      );

    } catch (e) {
      return OMRScanResult(
        answers: [],
        confidence: 0.0,
        errorMessage: 'Scanning failed: ${e.toString()}',
      );
    }
  }

  Future<img.Image> _preprocessImage(img.Image image) async {
    // Convert to grayscale
    var processed = img.grayscale(image);

    // Apply Gaussian blur to reduce noise
    processed = img.gaussianBlur(processed, radius: GAUSSIAN_BLUR_RADIUS);

    // Apply adaptive threshold
    processed = _adaptiveThreshold(processed);

    // Apply morphological operations to clean up
    processed = _morphologicalOperations(processed);

    return processed;
  }

  img.Image _adaptiveThreshold(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);
    const int windowSize = 15;
    const double k = 0.15;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        // Calculate local mean
        double sum = 0;
        int count = 0;

        for (int dy = -windowSize ~/ 2; dy <= windowSize ~/ 2; dy++) {
          for (int dx = -windowSize ~/ 2; dx <= windowSize ~/ 2; dx++) {
            final px = x + dx;
            final py = y + dy;

            if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
              final pixel = image.getPixel(px, py);
              sum += img.getLuminance(pixel);
              count++;
            }
          }
        }

        final mean = sum / count;
        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        final threshold = mean * (1 - k);

        final newPixel = luminance > threshold
            ? img.ColorRgb8(255, 255, 255)
            : img.ColorRgb8(0, 0, 0);
        result.setPixel(x, y, newPixel);
      }
    }

    return result;
  }

  img.Image _morphologicalOperations(img.Image image) {
    // Apply erosion followed by dilation (opening)
    var result = image;

    for (int i = 0; i < MORPHOLOGY_ITERATIONS; i++) {
      result = _erode(result);
    }

    for (int i = 0; i < MORPHOLOGY_ITERATIONS; i++) {
      result = _dilate(result);
    }

    return result;
  }

  img.Image _erode(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        bool isBlack = true;

        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final pixel = image.getPixel(x + dx, y + dy);
            if (img.getLuminance(pixel) > 128) {
              isBlack = false;
              break;
            }
          }
          if (!isBlack) break;
        }

        final newPixel = isBlack
            ? img.ColorRgb8(0, 0, 0)
            : img.ColorRgb8(255, 255, 255);
        result.setPixel(x, y, newPixel);
      }
    }

    return result;
  }

  img.Image _dilate(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        bool hasBlack = false;

        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final pixel = image.getPixel(x + dx, y + dy);
            if (img.getLuminance(pixel) < 128) {
              hasBlack = true;
              break;
            }
          }
          if (hasBlack) break;
        }

        final newPixel = hasBlack
            ? img.ColorRgb8(0, 0, 0)
            : img.ColorRgb8(255, 255, 255);
        result.setPixel(x, y, newPixel);
      }
    }

    return result;
  }

  Future<img.Image> _performPerspectiveCorrection(img.Image image) async {
    // Find sheet corners using edge detection
    final corners = _findSheetCorners(image);

    if (corners.length == 4) {
      // Apply perspective transformation
      return _applyPerspectiveTransform(image, corners);
    }

    return image;
  }

  List<Point> _findSheetCorners(img.Image image) {
    // Simplified corner detection
    // In production, use more sophisticated methods like Hough transform
    return [
      Point(0, 0),
      Point(image.width - 1, 0),
      Point(image.width - 1, image.height - 1),
      Point(0, image.height - 1),
    ];
  }

  img.Image _applyPerspectiveTransform(img.Image image, List<Point> corners) {
    // Simplified - in production, implement proper perspective transformation
    return image;
  }

  img.Image _scaleToStandardSize(img.Image image) {
    final targetWidth = OMRSheetLayout.sheetWidth.toInt();
    final targetHeight = OMRSheetLayout.sheetHeight.toInt();

    return img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );
  }

  Future<int?> _detectSetNumber(img.Image image) async {
    final setRegions = _getSetNumberRegions();

    for (final region in setRegions) {
      if (_isBubbleFilled(image, region)) {
        return int.parse(region.value);
      }
    }

    return null;
  }

  List<BubbleRegion> _getSetNumberRegions() {
    final regions = <BubbleRegion>[];

    for (int i = 0; i < 4; i++) {
      regions.add(BubbleRegion(
        row: 0,
        col: i,
        x: OMRSheetLayout.setNumberStartX + (i * OMRSheetLayout.setNumberSpacing),
        y: OMRSheetLayout.setNumberY,
        radius: OMRSheetLayout.bubbleRadius,
        value: (i + 1).toString(),
      ));
    }

    return regions;
  }

  Future<String?> _detectStudentId(img.Image image) async {
    final digits = <String>[];

    for (int col = 0; col < 10; col++) {
      final digit = await _detectDigitInColumn(
        image,
        OMRSheetLayout.idGridStartX + (col * OMRSheetLayout.bubbleSpacing),
        OMRSheetLayout.idGridStartY,
        10,
      );

      if (digit != null) {
        digits.add(digit);
      }
    }

    return digits.length == 10 ? digits.join() : null;
  }

  Future<String?> _detectMobileNumber(img.Image image) async {
    final digits = <String>[];

    for (int col = 0; col < 11; col++) {
      final digit = await _detectDigitInColumn(
        image,
        OMRSheetLayout.mobileGridStartX + (col * OMRSheetLayout.bubbleSpacing),
        OMRSheetLayout.mobileGridStartY,
        10,
      );

      if (digit != null) {
        digits.add(digit);
      }
    }

    return digits.length == 11 ? digits.join() : null;
  }

  Future<String?> _detectDigitInColumn(
      img.Image image,
      double x,
      double startY,
      int digits,
      ) async {
    for (int digit = 0; digit < digits; digit++) {
      final region = BubbleRegion(
        row: digit,
        col: 0,
        x: x,
        y: startY + 30 + (digit * OMRSheetLayout.digitBubbleSpacing),
        radius: OMRSheetLayout.digitBubbleRadius,
        value: digit.toString(),
      );

      if (_isBubbleFilled(image, region)) {
        return digit.toString();
      }
    }

    return null;
  }

  Future<List<String>> _detectAnswers(img.Image image, int numberOfQuestions) async {
    final answers = List<String>.filled(numberOfQuestions, '');
    final questionsPerColumn = (numberOfQuestions / 3).ceil();

    for (int q = 0; q < numberOfQuestions; q++) {
      final column = q ~/ questionsPerColumn;
      final row = q % questionsPerColumn;

      final baseX = OMRSheetLayout.idGridStartX + (column * OMRSheetLayout.answerColumnWidth);
      final baseY = OMRSheetLayout.answerGridStartY + (row * OMRSheetLayout.answerRowHeight);

      final options = ['A', 'B', 'C', 'D'];
      for (int opt = 0; opt < options.length; opt++) {
        final region = BubbleRegion(
          row: row,
          col: opt,
          x: baseX + 60 + (opt * 30),
          y: baseY,
          radius: OMRSheetLayout.bubbleRadius,
          value: options[opt],
        );

        if (_isBubbleFilled(image, region)) {
          answers[q] = options[opt];
          break;
        }
      }
    }

    return answers;
  }

  bool _isBubbleFilled(img.Image image, BubbleRegion region) {
    int darkPixels = 0;
    int totalPixels = 0;

    // Sample pixels within the bubble region
    final centerX = region.x.toInt();
    final centerY = region.y.toInt();
    final radius = region.radius.toInt();

    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        // Check if pixel is within circle
        if (dx * dx + dy * dy <= radius * radius) {
          final px = centerX + dx;
          final py = centerY + dy;

          if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
            final pixel = image.getPixel(px, py);
            final luminance = img.getLuminance(pixel);

            if (luminance < 128) {
              darkPixels++;
            }
            totalPixels++;
          }
        }
      }
    }

    // Calculate fill percentage
    final fillPercentage = totalPixels > 0 ? darkPixels / totalPixels : 0.0;

    // Bubble is considered filled if more than threshold percentage is dark
    return fillPercentage > DARKNESS_THRESHOLD;
  }

  double _calculateOverallConfidence(
      List<String> answers,
      String? studentId,
      String? mobileNumber,
      ) {
    double confidence = 0.0;
    int validFields = 0;

    // Check answer completeness
    final answeredQuestions = answers.where((a) => a.isNotEmpty).length;
    if (answers.isNotEmpty) {
      confidence += (answeredQuestions / answers.length) * 0.5;
      validFields++;
    }

    // Check student ID validity
    if (studentId != null && studentId.length == 10) {
      confidence += 0.25;
      validFields++;
    }

    // Check mobile number validity
    if (mobileNumber != null && mobileNumber.length == 11) {
      confidence += 0.25;
      validFields++;
    }

    return validFields > 0 ? confidence / validFields : 0.0;
  }

  Map<String, dynamic> _evaluateAnswers(
      List<String> studentAnswers,
      List<String> answerKey,
      ) {
    int correct = 0;
    int wrong = 0;
    int unanswered = 0;
    final List<int> wrongQuestions = [];
    final List<int> unansweredQuestions = [];

    for (int i = 0; i < studentAnswers.length && i < answerKey.length; i++) {
      if (studentAnswers[i].isEmpty) {
        unanswered++;
        unansweredQuestions.add(i + 1);
      } else if (studentAnswers[i] == answerKey[i]) {
        correct++;
      } else {
        wrong++;
        wrongQuestions.add(i + 1);
      }
    }

    final totalQuestions = answerKey.length;
    final percentage = totalQuestions > 0 ? (correct / totalQuestions) * 100 : 0.0;

    return {
      'totalQuestions': totalQuestions,
      'correct': correct,
      'wrong': wrong,
      'unanswered': unanswered,
      'percentage': percentage.toStringAsFixed(2),
      'wrongQuestions': wrongQuestions,
      'unansweredQuestions': unansweredQuestions,
      'marks': correct, // Can be modified based on marking scheme
    };
  }

  void dispose() {
    textRecognizer.close();
  }
}

// Point class for corner detection
class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}

// UI Widget for scanning
class OMRScannerScreen extends StatefulWidget {
  @override
  _OMRScannerScreenState createState() => _OMRScannerScreenState();
}

class _OMRScannerScreenState extends State<OMRScannerScreen> {
  final AdvancedOMRScanner _scanner = AdvancedOMRScanner();
  final ImagePicker _picker = ImagePicker();

  bool _isScanning = false;
  OMRScanResult? _scanResult;
  File? _selectedImage;

  // Answer key for evaluation
  final List<String> _answerKey = [
    'A', 'B', 'C', 'D', 'A', 'B', 'C', 'D', 'A', 'B',
    'C', 'D', 'A', 'B', 'C', 'D', 'A', 'B', 'C', 'D',
    'A', 'B', 'C', 'D', 'A', 'B', 'C', 'D', 'A', 'B',
    'C', 'D', 'A', 'B', 'C', 'D', 'A', 'B', 'C', 'D',
  ];

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _scanResult = null;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _scanOMRSheet() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      final result = await _scanner.scanOMRSheet(
        imageFile: _selectedImage!,
        answerKey: _answerKey,
        numberOfQuestions: 40,
      );

      setState(() {
        _scanResult = result;
        _isScanning = false;
      });

      if (result.errorMessage != null) {
        _showError(result.errorMessage!);
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showError('Scanning failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OMR Scanner'),
        backgroundColor: Color(0xFF2C3E50),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image selection section
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Select OMR Sheet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: Icon(Icons.camera_alt),
                          label: Text('Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3498DB),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: Icon(Icons.photo_library),
                          label: Text('Gallery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2ECC71),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Selected image preview
            if (_selectedImage != null)
              Card(
                elevation: 4,
                child: Column(
                  children: [
                    Container(
                      height: 300,
                      padding: EdgeInsets.all(8),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _isScanning ? null : _scanOMRSheet,
                        child: _isScanning
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Scan OMR Sheet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE74C3C),
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Scan results
            if (_scanResult != null && !_isScanning)
              _buildResultsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(top: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Results',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            Divider(height: 24),

            // Student Information
            _buildInfoRow('Student ID', _scanResult!.studentId ?? 'Not detected'),
            _buildInfoRow('Mobile Number', _scanResult!.mobileNumber ?? 'Not detected'),
            _buildInfoRow('Set Number', _scanResult!.setNumber?.toString() ?? 'Not detected'),
            _buildInfoRow(
              'Confidence',
              '${(_scanResult!.confidence * 100).toStringAsFixed(1)}%',
              color: _scanResult!.confidence > 0.7 ? Colors.green : Colors.orange,
            ),

            if (_scanResult!.evaluation != null) ...[
              Divider(height: 24),
              Text(
                'Evaluation Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              _buildEvaluationResults(_scanResult!.evaluation!),
            ],

            Divider(height: 24),

            // Detected Answers
            Text(
              'Detected Answers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            _buildAnswerGrid(_scanResult!.answers),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationResults(Map<String, dynamic> evaluation) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreItem('Correct', evaluation['correct'], Colors.green),
              _buildScoreItem('Wrong', evaluation['wrong'], Colors.red),
              _buildScoreItem('Unanswered', evaluation['unanswered'], Colors.orange),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF2C3E50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Score: ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${evaluation['percentage']}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerGrid(List<String> answers) {
    return Container(
        height: 200,
        child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: answers.length,
            itemBuilder: (context, index) {
              final answer = answers[index];
              final isCorrect = _answerKey.length > index &&
                  answer == _answerKey[index];

              return Container(
                  decoration: BoxDecoration(
                    color: answer.isEmpty
                        ? Colors.grey[300]
                        : isCorrect
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: answer.isEmpty
                          ? Colors.grey
                          : isCorrect
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Text(
                      '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                          answer.isEmpty ? '-' : answer,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: answer.isEmpty
                              ? Colors.grey
                              : isCorrect
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                        ],
                      ),
                  ),
              );
            },
        ),
    );
  }
}

// Enhanced Scanner Service with additional features
class EnhancedOMRScanner extends AdvancedOMRScanner {
  // Additional calibration parameters
  static const double SKEW_TOLERANCE = 5.0; // degrees
  static const double MIN_BUBBLE_FILL = 0.4;
  static const double MAX_BUBBLE_FILL = 0.9;

  // Cache for performance
  final Map<String, dynamic> _cache = {};

  // Enhanced scanning with auto-rotation and alignment
  @override
  Future<OMRScanResult> scanOMRSheet({
    required File imageFile,
    required List<String> answerKey,
    required int numberOfQuestions,
  }) async {
    try {
      // Clear cache
      _cache.clear();

      // Load image
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Auto-rotate if needed
      image = await _autoRotateImage(image);

      // Detect and correct skew
      image = await _correctSkew(image);

      // Enhance contrast
      image = _enhanceContrast(image);

      // Continue with standard processing
      return await super.scanOMRSheet(
        imageFile: await _imageToFile(image),
        answerKey: answerKey,
        numberOfQuestions: numberOfQuestions,
      );
    } catch (e) {
      return OMRScanResult(
        answers: [],
        confidence: 0.0,
        errorMessage: 'Enhanced scanning failed: ${e.toString()}',
      );
    }
  }

  Future<img.Image> _autoRotateImage(img.Image image) async {
    // Detect orientation based on aspect ratio
    if (image.width > image.height) {
      // Rotate 90 degrees if landscape
      return img.copyRotate(image, angle: 90);
    }
    return image;
  }

  Future<img.Image> _correctSkew(img.Image image) async {
    // Detect skew angle using Hough transform
    final skewAngle = await _detectSkewAngle(image);

    if (skewAngle.abs() > SKEW_TOLERANCE) {
      return img.copyRotate(image, angle: -skewAngle);
    }

    return image;
  }

  Future<double> _detectSkewAngle(img.Image image) async {
    // Simplified skew detection
    // In production, implement proper Hough transform
    return 0.0;
  }

  img.Image _enhanceContrast(img.Image image) {
    // Apply histogram equalization
    final histogram = List<int>.filled(256, 0);

    // Calculate histogram
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

    // Normalize
    final totalPixels = image.width * image.height;
    final lut = List<int>.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      lut[i] = ((cdf[i] * 255) / totalPixels).round();
    }

    // Apply lookup table
    final result = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = img.getLuminance(pixel).toInt();
        final newGray = lut[gray];
        result.setPixel(x, y, img.ColorRgb8(newGray, newGray, newGray));
      }
    }

    return result;
  }

  Future<File> _imageToFile(img.Image image) async {
    final tempDir = await Directory.systemTemp.createTemp('omr_scan');
    final file = File('${tempDir.path}/processed.png');
    await file.writeAsBytes(img.encodePng(image));
    return file;
  }

  // Advanced bubble detection with validation
  @override
  bool _isBubbleFilled(img.Image image, BubbleRegion region) {
    // Check cache first
    final cacheKey = '${region.x}_${region.y}_${region.value}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    int darkPixels = 0;
    int totalPixels = 0;
    int edgePixels = 0;

    final centerX = region.x.toInt();
    final centerY = region.y.toInt();
    final radius = region.radius.toInt();

    // Analyze bubble area
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance <= radius) {
          final px = centerX + dx;
          final py = centerY + dy;

          if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
            final pixel = image.getPixel(px, py);
            final luminance = img.getLuminance(pixel);

            // Count edge pixels for bubble detection
            if (distance > radius - 2 && distance <= radius) {
              if (luminance < 128) edgePixels++;
            }

            if (luminance < 128) {
              darkPixels++;
            }
            totalPixels++;
          }
        }
      }
    }

    // Calculate fill percentage
    final fillPercentage = totalPixels > 0 ? darkPixels / totalPixels : 0.0;

    // Validate bubble (check if it's actually a bubble shape)
    final hasValidEdge = edgePixels > (radius * 2 * math.pi * 0.5);

    // Determine if filled
    final isFilled = fillPercentage > MIN_BUBBLE_FILL &&
        fillPercentage < MAX_BUBBLE_FILL &&
        hasValidEdge;

    // Cache result
    _cache[cacheKey] = isFilled;

    return isFilled;
  }
}

// Result Export Service
class OMRResultExporter {
  static Future<String> exportToCSV(List<OMRScanResult> results) async {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Student ID,Mobile Number,Set Number,Score,Percentage,Correct,Wrong,Unanswered');

    // Data rows
    for (final result in results) {
      if (result.evaluation != null) {
        buffer.writeln(
            '${result.studentId ?? "N/A"},'
                '${result.mobileNumber ?? "N/A"},'
                '${result.setNumber ?? "N/A"},'
                '${result.evaluation!['marks']},'
                '${result.evaluation!['percentage']}%,'
                '${result.evaluation!['correct']},'
                '${result.evaluation!['wrong']},'
                '${result.evaluation!['unanswered']}'
        );
      }
    }

    return buffer.toString();
  }

  static Future<File> saveResultsToFile(List<OMRScanResult> results) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/omr_results_$timestamp.csv');

    final csv = await exportToCSV(results);
    await file.writeAsString(csv);

    return file;
  }
}

// Batch Processing Screen
class BatchOMRScannerScreen extends StatefulWidget {
  @override
  _BatchOMRScannerScreenState createState() => _BatchOMRScannerScreenState();
}

class _BatchOMRScannerScreenState extends State<BatchOMRScannerScreen> {
  final EnhancedOMRScanner _scanner = EnhancedOMRScanner();
  final List<File> _selectedImages = [];
  final List<OMRScanResult> _results = [];
  bool _isProcessing = false;
  double _progress = 0.0;

  // Answer key
  final List<String> _answerKey = List.generate(40, (i) => ['A', 'B', 'C', 'D'][i % 4]);

  Future<void> _pickMultipleImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(
      imageQuality: 100,
    );

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(images.map((img) => File(img.path)));
        _results.clear();
        _progress = 0.0;
      });
    }
  }

  Future<void> _processBatch() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _results.clear();
      _progress = 0.0;
    });

    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        final result = await _scanner.scanOMRSheet(
          imageFile: _selectedImages[i],
          answerKey: _answerKey,
          numberOfQuestions: 40,
        );

        setState(() {
          _results.add(result);
          _progress = (i + 1) / _selectedImages.length;
        });
      } catch (e) {
        print('Error processing image ${i + 1}: $e');
      }
    }

    setState(() {
      _isProcessing = false;
    });

    // Show completion dialog
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batch Processing Complete'),
        content: Text('Processed ${_results.length} OMR sheets successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: _exportResults,
            child: Text('Export Results'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportResults() async {
    try {
      final file = await OMRResultExporter.saveResultsToFile(_results);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Results exported to: ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Batch OMR Scanner'),
        backgroundColor: Color(0xFF2C3E50),
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              icon: Icon(Icons.download),
              onPressed: _exportResults,
            ),
        ],
      ),
      body: Column(
          children: [
      // Control panel
      Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _pickMultipleImages,
            icon: Icon(Icons.photo_library),
            label: Text('Select Multiple OMR Sheets'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3498DB),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          SizedBox(height: 16),
          if (_selectedImages.isNotEmpty)
            Text(
              '${_selectedImages.length} images selected',
              style: TextStyle(fontSize: 16),
            ),
          if (_selectedImages.isNotEmpty && !_isProcessing)
            ElevatedButton.icon(
              onPressed: _processBatch,
              icon: Icon(Icons.play_arrow),
              label: Text('Start Processing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2ECC71),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
        ],
      ),
    ),

    // Progress indicator
    if (_isProcessing)
    Padding(
    padding: EdgeInsets.all(16),
    child: Column(
    children: [
    LinearProgressIndicator(
    value: _progress,
    backgroundColor: Colors.grey[300],
    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3498DB)),
    ),
    SizedBox(height: 8),
    Text('Processing: ${(_progress * 100).toStringAsFixed(0)}%'),
    ],
    ),
    ),

    // Results list
    Expanded(
    child: ListView.builder(
    padding: EdgeInsets.all(16),
    itemCount: _results.length,
    itemBuilder: (context, index) {
    final result = _results[index];
    return Card(
    margin: EdgeInsets.only(bottom: 12),
    child: ListTile(
    leading: CircleAvatar(
    backgroundColor: result.confidence > 0.7
    ? Colors.green
        : Colors.orange,
    child: Text('${index + 1}'),
    ),
    title: Text(
    'Student ID: ${result.studentId ?? "Not detected"}',
    style: TextStyle(fontWeight: FontWeight.bold),
    ),
    subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text('Mobile: ${result.mobileNumber ?? "Not detected"}'),
    if (result.evaluation != null)
    Text(
    'Score: ${result.evaluation!['correct']}/${result.evaluation!['totalQuestions']} '
    '(${result.evaluation!['percentage']}%)',
    style: TextStyle(
    color: Colors.blue,
    fontWeight: FontWeight.w500,
    ),
    ),
    ],
    ),
    trailing: Icon(
    result.confidence > 0.7
    ? Icons.check_circle
        : Icons.warning,
      color: result.confidence > 0.7
          ? Colors.green
          : Colors.orange,
    ),
      onTap: () => _showDetailedResult(result),
    ),
    );
    },
    ),
    ),
          ],
      ),
    );
  }

  void _showDetailedResult(OMRScanResult result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(16),
          constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detailed Result',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(),
              _buildDetailRow('Student ID', result.studentId ?? 'Not detected'),
              _buildDetailRow('Mobile', result.mobileNumber ?? 'Not detected'),
              _buildDetailRow('Set', result.setNumber?.toString() ?? 'Not detected'),
              _buildDetailRow('Confidence', '${(result.confidence * 100).toStringAsFixed(1)}%'),
              if (result.evaluation != null) ...[
                Divider(),
                _buildDetailRow('Correct', result.evaluation!['correct'].toString()),
                _buildDetailRow('Wrong', result.evaluation!['wrong'].toString()),
                _buildDetailRow('Unanswered', result.evaluation!['unanswered'].toString()),
                _buildDetailRow('Score', '${result.evaluation!['percentage']}%'),
              ],
              Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }
}


// Home Screen with Navigation
class OMRScannerHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OMR Scanner System'),
        backgroundColor: Color(0xFF2C3E50),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Color(0xFF3498DB).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 60,
                  color: Color(0xFF3498DB),
                ),
              ),
              SizedBox(height: 40),

              // Title
              Text(
                'OMR Answer Sheet Scanner',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Scan and evaluate OMR sheets instantly',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 40),

              // Navigation Buttons
              _buildNavigationButton(
                context,
                'Single Sheet Scan',
                'Scan one OMR sheet at a time',
                Icons.document_scanner,
                Color(0xFF3498DB),
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OMRScannerScreen()),
                ),
              ),
              SizedBox(height: 16),
              _buildNavigationButton(
                context,
                'Batch Processing',
                'Process multiple sheets together',
                Icons.burst_mode,
                Color(0xFF2ECC71),
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BatchOMRScannerScreen()),
                ),
              ),
              SizedBox(height: 16),
              _buildNavigationButton(
                context,
                'Settings',
                'Configure scanner settings',
                Icons.settings,
                Color(0xFF95A5A6),
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ScannerSettingsScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color),
          ],
        ),
      ),
    );
  }
}

// Settings Screen
class ScannerSettingsScreen extends StatefulWidget {
  @override
  _ScannerSettingsScreenState createState() => _ScannerSettingsScreenState();
}

class _ScannerSettingsScreenState extends State<ScannerSettingsScreen> {
  double _darknessThreshold = 0.45;
  double _minConfidence = 0.7;
  bool _autoRotate = true;
  bool _enhanceContrast = true;
  bool _showDebugInfo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner Settings'),
        backgroundColor: Color(0xFF2C3E50),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSection(
            'Detection Settings',
            [
              _buildSliderSetting(
                'Darkness Threshold',
                'Sensitivity for bubble detection',
                _darknessThreshold,
                0.2,
                0.8,
                    (value) => setState(() => _darknessThreshold = value),
              ),
              _buildSliderSetting(
                'Minimum Confidence',
                'Required confidence for valid scan',
                _minConfidence,
                0.5,
                1.0,
                    (value) => setState(() => _minConfidence = value),
              ),
            ],
          ),
          _buildSection(
            'Image Processing',
            [
              _buildSwitchSetting(
                'Auto Rotate',
                'Automatically correct image orientation',
                _autoRotate,
                    (value) => setState(() => _autoRotate = value),
              ),
              _buildSwitchSetting(
                'Enhance Contrast',
                'Improve image contrast for better detection',
                _enhanceContrast,
                    (value) => setState(() => _enhanceContrast = value),
              ),
            ],
          ),
          _buildSection(
            'Developer Options',
            [
              _buildSwitchSetting(
                'Show Debug Info',
                'Display technical information during scan',
                _showDebugInfo,
                    (value) => setState(() => _showDebugInfo = value),
              ),
            ],
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _resetSettings,
            child: Text('Reset to Defaults'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE74C3C),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSliderSetting(
      String title,
      String subtitle,
      double value,
      double min,
      double max,
      ValueChanged<double> onChanged,
      ) {
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 20,
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
      String title,
      String subtitle,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  void _resetSettings() {
    setState(() {
      _darknessThreshold = 0.45;
      _minConfidence = 0.7;
      _autoRotate = true;
      _enhanceContrast = true;
      _showDebugInfo = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings reset to defaults'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Utility Functions
class OMRScannerUtils {
  // Validate student ID format
  static bool isValidStudentId(String? id) {
    if (id == null || id.isEmpty) return false;
    return RegExp(r'^\d{10}$').hasMatch(id);
  }

  // Validate mobile number format
  static bool isValidMobileNumber(String? number) {
    if (number == null || number.isEmpty) return false;
    return RegExp(r'^\d{11}$').hasMatch(number);
  }

  // Calculate grade based on percentage
  static String calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  // Format scan results for display
  static String formatScanResults(OMRScanResult result) {
    final buffer = StringBuffer();

    buffer.writeln('=== OMR Scan Results ===');
    buffer.writeln('Student ID: ${result.studentId ?? "Not detected"}');
    buffer.writeln('Mobile: ${result.mobileNumber ?? "Not detected"}');
    buffer.writeln('Set: ${result.setNumber ?? "Not detected"}');
    buffer.writeln('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');

    if (result.evaluation != null) {
      buffer.writeln('\n=== Evaluation ===');
      buffer.writeln('Correct: ${result.evaluation!['correct']}');
      buffer.writeln('Wrong: ${result.evaluation!['wrong']}');
      buffer.writeln('Unanswered: ${result.evaluation!['unanswered']}');
      buffer.writeln('Score: ${result.evaluation!['percentage']}%');
      buffer.writeln('Grade: ${calculateGrade(double.parse(result.evaluation!['percentage']))}');
    }

    return buffer.toString();
  }
}

// // Main function
// void main() {
//   runApp(OMRScannerApp());
// }




// // lib/omr/omr_scanner_service.dart
// import 'dart:io';
// import 'dart:math';
// import 'package:image/image.dart' as img;
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
// import 'package:path_provider/path_provider.dart';
//
// import '../models/omr_template.dart';
//
// class OMRScannerService {
//   final TextRecognizer _textRecognizer = TextRecognizer();
//   OMRTemplate template;
//   double circleDarkThreshold;
//   OMRScannerService({
//     this.template = OMRTemplate.defaultTemplate,
//     this.circleDarkThreshold = 0.45,
//   });
//
//   void dispose() {
//     _textRecognizer.close();
//   }
//
//   /// Launch ML Kit Document Scanner UI, returns path to cropped image (first page)
//   /// If scanner fails (emulator or missed support), throws an exception with details.
//   Future<String> launchDocumentScannerAndGetCroppedImagePath({
//     int maxPages = 1,
//     bool enableFilters = true,
//   }) async {
//     try {
//       final options = DocumentScannerOptions(
//         enableFilters: enableFilters,
//         // configure additional options if available in the plugin version you use
//       );
//       final scanner = DocumentScanner(options: options);
//
//       // scanDocument() returns a List<Map> or List<Document> depending on plugin version.
//       final scanned = await scanner.scanDocument(maxPages: maxPages);
//       // `scanned` structure may vary; try reading typical return shapes:
//       // - List<DocumentScan>
//       // - List<Map<String,dynamic>> where each element has 'imagePath' or 'croppedImage'
//       if (scanned == null) {
//         throw Exception('No document returned from scanner.');
//       }
//
//       // Support multiple shapes; get first image file path:
//       String? imagePath;
//       if (scanned is List && scanned.isNotEmpty) {
//         final first = scanned.first;
//         if (first is Map && first.containsKey('imagePath')) {
//           imagePath = first['imagePath'] as String?;
//         } else if (first is Map && first.containsKey('croppedImagePath')) {
//           imagePath = first['croppedImagePath'] as String?;
//         } else if (first is DocumentScan) {
//           // some versions may return typed objects; DocumentScan likely has `croppedImage` or `imagePath`
//           try {
//             // Access common property names
//             if ((first as dynamic).croppedImage != null) {
//               imagePath = (first as dynamic).croppedImage as String?;
//             } else if ((first as dynamic).imagePath != null) {
//               imagePath = (first as dynamic).imagePath as String?;
//             }
//           } catch (_) {
//             // ignore
//           }
//         }
//       }
//
//       if (imagePath == null) {
//         // Fallback: maybe scanned itself is a Map or typed with `imagePath`:
//         if (scanned is Map && scanned.containsKey('imagePath')) {
//           imagePath = scanned['imagePath'] as String?;
//         }
//       }
//
//       if (imagePath == null) {
//         throw Exception('Could not extract image path from scanned result. Raw: $scanned');
//       }
//       return imagePath;
//     } catch (e) {
//       // Re-throw with extra context
//       throw Exception('Document scanner failed: $e');
//     }
//   }
//
//   /// Main scanning entry. Accepts a path to an image file (already cropped)
//   Future<ScanResult> scanCroppedImage(String imagePath, {bool generateDebug = false}) async {
//     try {
//       final file = File(imagePath);
//       if (!await file.exists()) {
//         return ScanResult(detectedAnswers: [], confidence: 0.0, errorMessage: 'Cropped image not found.');
//       }
//       final bytes = await file.readAsBytes();
//       final image = img.decodeImage(bytes);
//       if (image == null) {
//         return ScanResult(detectedAnswers: [], confidence: 0.0, errorMessage: 'Could not decode image bytes.');
//       }
//
//       // grayscale + mild denoise
//       final gray = img.grayscale(image);
//       final proc = img.gaussianBlur(gray, 1);
//
//       // OCR fallback
//       final ocr = await _performOCR(file);
//
//       // set number
//       final setNum = _detectSetNumber(proc);
//
//       // student/mobile
//       final studentId = _detectDigitGrid(proc, template.studentIdRegion, digitsPerRow: 10, rows: 10);
//       final mobile = _detectDigitGrid(proc, template.mobileRegion, digitsPerRow: 11, rows: 10);
//
//       final finalStudent = (studentId != null && studentId.length == 10) ? studentId : (ocr['studentId'] ?? studentId);
//       final finalMobile = (mobile != null && mobile.length == 11) ? mobile : (ocr['mobile'] ?? mobile);
//
//       final answers = _detectAnswers(proc);
//
//       final confidence = _computeConfidence(answers, finalStudent, finalMobile, setNum);
//
//       if (generateDebug) {
//         final dbg = _visualizeDetection(image, finalStudent, finalMobile, setNum, answers);
//         final tmp = await getTemporaryDirectory();
//         final outPath = '${tmp.path}/omr_debug_${DateTime.now().millisecondsSinceEpoch}.jpg';
//         await File(outPath).writeAsBytes(img.encodeJpg(dbg, quality: 88));
//       }
//
//       return ScanResult(
//         studentId: finalStudent,
//         mobileNumber: finalMobile,
//         setNumber: setNum,
//         detectedAnswers: answers,
//         confidence: confidence,
//       );
//     } catch (e) {
//       return ScanResult(detectedAnswers: [], confidence: 0.0, errorMessage: e.toString());
//     }
//   }
//
//   /// A convenience method: launch scanner UI then scan returned cropped image
//   Future<ScanResult> scanWithDocumentScanner({bool generateDebug = false}) async {
//     try {
//       final croppedPath = await launchDocumentScannerAndGetCroppedImagePath();
//       return await scanCroppedImage(croppedPath, generateDebug: generateDebug);
//     } catch (e) {
//       return ScanResult(detectedAnswers: [], confidence: 0.0, errorMessage: e.toString());
//     }
//   }
//
//   /// OCR helper using ML Kit text recognizer
//   Future<Map<String, String?>> _performOCR(File f) async {
//     try {
//       final input = InputImage.fromFile(f);
//       final recognized = await _textRecognizer.processImage(input);
//       String? student;
//       String? mobile;
//       final studentPattern = RegExp(r'\b\d{10}\b');
//       final mobilePattern = RegExp(r'\b\d{11}\b');
//       for (var block in recognized.blocks) {
//         final t = block.text;
//         final sMatch = studentPattern.firstMatch(t);
//         final mMatch = mobilePattern.firstMatch(t);
//         if (sMatch != null && student == null) student = sMatch.group(0);
//         if (mMatch != null && mobile == null) mobile = mMatch.group(0);
//         // try cleaned numeric block
//         final cleaned = t.replaceAll(RegExp(r'[^0-9]'), '');
//         if (student == null && cleaned.length >= 10) {
//           final p = RegExp(r'\d{10}');
//           final mm = p.firstMatch(cleaned);
//           if (mm != null) student = mm.group(0);
//         }
//         if (mobile == null && cleaned.length >= 11) {
//           final p = RegExp(r'\d{11}');
//           final mm = p.firstMatch(cleaned);
//           if (mm != null) mobile = mm.group(0);
//         }
//       }
//       return {'studentId': student, 'mobile': mobile};
//     } catch (_) {
//       return {'studentId': null, 'mobile': null};
//     }
//   }
//
//   /// ---- Detection helpers (grid-based) ----
//
//   img.Image? _cropImage(img.Image src, Rect r) {
//     final left = r.left.round().clamp(0, src.width - 1);
//     final top = r.top.round().clamp(0, src.height - 1);
//     final w = r.width.round().clamp(1, src.width - left);
//     final h = r.height.round().clamp(1, src.height - top);
//     try {
//       return img.copyCrop(src, left, top, w, h);
//     } catch (_) {
//       return null;
//     }
//   }
//
//   int? _detectSetNumber(img.Image imgSrc) {
//     final rect = template.setRegion.toAbsolute(imgSrc.width, imgSrc.height);
//     final sub = _cropImage(imgSrc, rect);
//     if (sub == null) return null;
//     final options = 4;
//     final optW = sub.width / options;
//     double best = 0.0;
//     int bestIdx = -1;
//     for (int i = 0; i < options; i++) {
//       final region = Rect.fromLTWH(i * optW, 0, optW, sub.height.toDouble());
//       final part = _cropImage(sub, region);
//       if (part == null) continue;
//       final d = _circleDarkness(part);
//       if (d > best) {
//         best = d;
//         bestIdx = i;
//       }
//     }
//     if (best > circleDarkThreshold) return bestIdx + 1;
//     return null;
//   }
//
//   String? _detectDigitGrid(img.Image imgSrc, RelativeRect gridRect,
//       {required int digitsPerRow, required int rows}) {
//     final rect = gridRect.toAbsolute(imgSrc.width, imgSrc.height);
//     final gridImg = _cropImage(imgSrc, rect);
//     if (gridImg == null) return null;
//
//     final cellW = gridImg.width / digitsPerRow;
//     final cellH = gridImg.height / rows;
//     final sb = StringBuffer();
//
//     for (int col = 0; col < digitsPerRow; col++) {
//       double best = 0.0;
//       int bestRow = -1;
//       for (int row = 0; row < rows; row++) {
//         final r = Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH);
//         final c = _cropImage(gridImg, r);
//         if (c == null) continue;
//         final d = _circleDarkness(c);
//         if (d > best) {
//           best = d;
//           bestRow = row;
//         }
//       }
//       if (best > circleDarkThreshold && bestRow >= 0) {
//         // mapping: top row -> digit 0, adjust if your sheet maps differently
//         sb.write(bestRow.toString());
//       } else {
//         // if any digit missing, return null to use OCR fallback
//         return null;
//       }
//     }
//
//     final s = sb.toString();
//     return s.length == digitsPerRow ? s : null;
//   }
//
//   List<String> _detectAnswers(img.Image imgSrc) {
//     final rect = template.answersRegion.toAbsolute(imgSrc.width, imgSrc.height);
//     final gridImg = _cropImage(imgSrc, rect);
//     if (gridImg == null) return List.filled(template.questions, '');
//
//     final qPerColumn = (template.questions / template.columns).ceil();
//     final colW = gridImg.width / template.columns;
//     final rowH = gridImg.height / qPerColumn;
//     final optW = colW / template.optionsPerQuestion;
//
//     final answers = List<String>.filled(template.questions, '');
//
//     for (int qIndex = 0; qIndex < template.questions; qIndex++) {
//       final column = qIndex ~/ qPerColumn;
//       final row = qIndex % qPerColumn;
//       final baseX = (column * colW).round();
//       final baseY = (row * rowH).round();
//
//       int bestOpt = -1;
//       double bestD = 0.0;
//       for (int opt = 0; opt < template.optionsPerQuestion; opt++) {
//         final left = baseX + (opt * optW).round();
//         final r = Rect.fromLTWH(left.toDouble(), baseY.toDouble(), optW.roundToDouble(), rowH.toDouble());
//         final cell = _cropImage(gridImg, r);
//         if (cell == null) continue;
//         final d = _circleDarkness(cell);
//         if (d > bestD) {
//           bestD = d;
//           bestOpt = opt;
//         }
//       }
//
//       if (bestD > circleDarkThreshold && bestOpt >= 0) {
//         answers[qIndex] = String.fromCharCode('A'.codeUnitAt(0) + bestOpt);
//       } else {
//         answers[qIndex] = '';
//       }
//     }
//
//     return answers;
//   }
//
//   double _circleDarkness(img.Image cell) {
//     final w = cell.width;
//     final h = cell.height;
//     final cx = (w / 2).floor();
//     final cy = (h / 2).floor();
//     final r = max(1, (min(w, h) * 0.4).floor());
//     int dark = 0;
//     int total = 0;
//     for (int y = max(0, cy - r); y <= min(h - 1, cy + r); y++) {
//       for (int x = max(0, cx - r); x <= min(w - 1, cx + r); x++) {
//         final dx = x - cx;
//         final dy = y - cy;
//         if (dx * dx + dy * dy <= r * r) {
//           final px = cell.getPixel(x, y);
//           final lum = img.getLuminance(px);
//           if (lum < 130) dark++;
//           total++;
//         }
//       }
//     }
//     if (total == 0) return 0.0;
//     return dark / total;
//   }
//
//   double _computeConfidence(List<String> answers, String? studentId, String? mobile, int? setNum) {
//     double qC = answers.isEmpty ? 0.0 : (answers.where((a) => a.isNotEmpty).length / answers.length);
//     double idC = (studentId != null && studentId.length >= 8) ? 1.0 : 0.0;
//     double mC = (mobile != null && mobile.length >= 10) ? 1.0 : 0.0;
//     double sC = (setNum != null) ? 1.0 : 0.0;
//     final score = (qC * 0.6) + (idC * 0.15) + (mC * 0.15) + (sC * 0.1);
//     return double.parse(score.toStringAsFixed(3));
//   }
//
//   img.Image _visualizeDetection(img.Image src, String? studentId, String? mobile, int? setNum, List<String> answers) {
//     final out = img.copyResize(src, width: src.width);
//     final drawRect = (Rect r, int color) {
//       final left = r.left.round();
//       final top = r.top.round();
//       final right = (r.left + r.width).round();
//       final bottom = (r.top + r.height).round();
//       for (int x = left; x <= right; x++) {
//         if (top >= 0 && top < out.height) out.setPixelSafe(x, top, color);
//         if (bottom >= 0 && bottom < out.height) out.setPixelSafe(x, bottom, color);
//       }
//       for (int y = top; y <= bottom; y++) {
//         if (left >= 0 && left < out.width) out.setPixelSafe(left, y, color);
//         if (right >= 0 && right < out.width) out.setPixelSafe(right, y, color);
//       }
//     };
//
//     drawRect(template.setRegion.toAbsolute(out.width, out.height), img.getColor(255, 0, 0));
//     drawRect(template.studentIdRegion.toAbsolute(out.width, out.height), img.getColor(0, 255, 0));
//     drawRect(template.mobileRegion.toAbsolute(out.width, out.height), img.getColor(0, 0, 255));
//     drawRect(template.answersRegion.toAbsolute(out.width, out.height), img.getColor(255, 140, 0));
//
//     // mark answers
//     final answersRect = template.answersRegion.toAbsolute(out.width, out.height);
//     final gridImg = _cropImage(out, answersRect)!;
//     final qPerColumn = (template.questions / template.columns).ceil();
//     final colW = gridImg.width / template.columns;
//     final rowH = gridImg.height / qPerColumn;
//     final optW = colW / template.optionsPerQuestion;
//
//     for (int qIndex = 0; qIndex < answers.length && qIndex < template.questions; qIndex++) {
//       final column = qIndex ~/ qPerColumn;
//       final row = qIndex % qPerColumn;
//       final baseX = answersRect.left + column * colW;
//       final baseY = answersRect.top + row * rowH;
//
//       final ans = answers[qIndex];
//       if (ans.isNotEmpty) {
//         final opt = ans.codeUnitAt(0) - 'A'.codeUnitAt(0);
//         final left = (baseX + opt * optW).round();
//         final top = (baseY).round();
//         for (int y = top; y < top + 8 && y < out.height; y++) {
//           for (int x = left; x < left + 8 && x < out.width; x++) {
//             out.setPixelSafe(x, y, img.getColor(255, 0, 0));
//           }
//         }
//       }
//     }
//     return out;
//   }
//
//   /// --------------------------
//   /// Auto-template generator
//   /// Analyze a clean scanned image and attempt to locate bubble centers and compute relative boxes.
//   /// This function returns a new OMRTemplate built from discovered bounding boxes.
//   Future<OMRTemplate> generateTemplateFromPerfectScan(String imagePath, {int attempts = 3}) async {
//     final file = File(imagePath);
//     if (!await file.exists()) throw Exception('Image not found for template generation.');
//
//     final bytes = await file.readAsBytes();
//     final image = img.decodeImage(bytes);
//     if (image == null) throw Exception('Could not decode image.');
//
//     final gray = img.grayscale(image);
//     final thr = _globalThreshold(gray);
//
//     // We'll look for strong circular dark blobs in the top half for student/mobile/set
//     // and main body for answer bubbles. This generator is heuristic: inspect result and tune.
//
//     final w = image.width.toDouble();
//     final h = image.height.toDouble();
//
//     // heuristics: these relative boxes are derived by searching density of blobs
//     // We'll compute bounding boxes for three clusters: top-left cluster (student id),
//     // top-right cluster (mobile), top-middle cluster (set), and middle-lower cluster for answers.
//
//     // Use simple sliding-window blob counting to find densest rectangles
//     RelativeRect findBestCluster(img.Image src, double relLeft, double relTop, double relW, double relH, int rectCols, int rectRows) {
//       // search area in absolute coords
//       final area = Rect.fromLTWH(relLeft * w, relTop * h, relW * w, relH * h);
//       final areaImg = _cropImage(src, area);
//       if (areaImg == null) return RelativeRect(relLeft, relTop, relW, relH);
//       // partition into grid to locate densest sub-rect
//       int bestX = 0, bestY = 0;
//       double bestScore = -1;
//       for (int ry = 0; ry < rectRows; ry++) {
//         for (int rx = 0; rx < rectCols; rx++) {
//           final sx = (rx * areaImg.width / rectCols).round();
//           final sy = (ry * areaImg.height / rectRows).round();
//           final sw = (areaImg.width / rectCols).round();
//           final sh = (areaImg.height / rectRows).round();
//           final sub = _cropImage(areaImg, Rect.fromLTWH(sx.toDouble(), sy.toDouble(), sw.toDouble(), sh.toDouble()));
//           if (sub == null) continue;
//           final score = _blobDensity(sub, thr);
//           if (score > bestScore) {
//             bestScore = score; bestX = rx; bestY = ry;
//           }
//         }
//       }
//       // return the relative rect of the best cell
//       final cellLeft = relLeft + (bestX / rectCols) * relW;
//       final cellTop = relTop + (bestY / rectRows) * relH;
//       final cellW = relW / rectCols;
//       final cellH = relH / rectRows;
//       return RelativeRect(cellLeft, cellTop, cellW, cellH);
//     }
//
//     // run heuristics
//     final setRegion = findBestCluster(img.grayscale(image), 0.12, 0.08, 0.76, 0.08, 6, 2);
//     final studentRegion = findBestCluster(img.grayscale(image), 0.00, 0.14, 0.56, 0.2, 4, 3);
//     final mobileRegion = findBestCluster(img.grayscale(image), 0.44, 0.14, 0.56, 0.2, 4, 3);
//     final answersRegion = findBestCluster(img.grayscale(image), 0.02, 0.30, 0.96, 0.58, 4, 3);
//
//     return OMRTemplate(
//       setRegion: setRegion,
//       studentIdRegion: studentRegion,
//       mobileRegion: mobileRegion,
//       answersRegion: answersRegion,
//       questions: template.questions,
//       columns: template.columns,
//       optionsPerQuestion: template.optionsPerQuestion,
//     );
//   }
//
//   int _globalThreshold(img.Image gray) {
//     // quick Otsu-like: compute histogram and median threshold
//     final hist = List<int>.filled(256, 0);
//     for (int y = 0; y < gray.height; y++) {
//       for (int x = 0; x < gray.width; x++) {
//         hist[img.getLuminance(gray.getPixel(x, y)).round()]++;
//       }
//     }
//     // cumulative find median
//     final total = gray.width * gray.height;
//     int acc = 0;
//     for (int i = 0; i < 256; i++) {
//       acc += hist[i];
//       if (acc >= total / 2) return i;
//     }
//     return 128;
//   }
//
//   double _blobDensity(img.Image cell, int threshold) {
//     int count = 0;
//     for (int y = 0; y < cell.height; y++) {
//       for (int x = 0; x < cell.width; x++) {
//         final p = cell.getPixel(x, y);
//         final lum = img.getLuminance(p);
//         if (lum < threshold) count++;
//       }
//     }
//     return count / (cell.width * cell.height);
//   }
// }
//
//
//
//
//
//
//
// // // lib/omr/omr_scanner_service.dart
// // import 'dart:io';
// // import 'dart:ui' as ui;
// // import 'dart:math';
// // import 'package:image/image.dart' as img;
// // import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// //
// // import '../models/omr_template.dart';
// // import '../models/scan_result.dart';
// //
// // class OMRScannerService {
// //   final TextRecognizer _textRecognizer = TextRecognizer();
// //   final OMRTemplate template;
// //
// //   // thresholds you can tune
// //   double circleDarkThreshold = 0.45; // fraction of dark pixels inside bubble to call it filled
// //   int debugImageQuality = 90;
// //
// //   OMRScannerService({this.template = OMRTemplate.defaultTemplate});
// //
// //   /// Main entry: scan an image file (already cropped to page ideally).
// //   Future<ScanResult> scan(File inputFile, {bool generateDebug = false, String? debugOutPath}) async {
// //     try {
// //       final bytes = await inputFile.readAsBytes();
// //       final image = img.decodeImage(bytes);
// //       if (image == null) {
// //         return ScanResult(detectedAnswers: [], confidence: 0.0, errorMessage: 'Could not decode image.');
// //       }
// //
// //       // Work on a copy and create grayscale (for speed + simpler threshold)
// //       final gray = img.grayscale(image);
// //
// //       // Optionally apply mild blur to reduce noise
// //       final processed = img.gaussianBlur(gray, radius: 1);
// //
// //       // Extract numeric text via OCR as fallback (useful if bubble reading fails)
// //       final ocrData = await _extractNumericText(inputFile);
// //
// //       // Detect set number
// //       final setNum = _detectSetNumber(processed);
// //
// //       // Detect student id and mobile using grid detection
// //       final studentId = _detectDigitGrid(processed, template.studentIdRegion, digitsPerRow: 10, rows: 10, threshold: circleDarkThreshold);
// //       final mobile = _detectDigitGrid(processed, template.mobileRegion, digitsPerRow: 11, rows: 10, threshold: circleDarkThreshold);
// //
// //       // If OCR gave more reliable values, fallback
// //       final finalStudentId = (studentId?.length == 10) ? studentId : (ocrData['studentId'] ?? studentId);
// //       final finalMobile = (mobile?.length == 11) ? mobile : (ocrData['mobile'] ?? mobile);
// //
// //       // Detect answers
// //       final answers = _detectAnswersGrid(processed);
// //
// //       final confidence = _computeConfidence(answers, studentId, mobile, setNum);
// //
// //       // optional debug visualization
// //       if (generateDebug && debugOutPath != null) {
// //         final dbg = _visualizeDetection(image, studentId, mobile, setNum, answers);
// //         final dbgBytes = img.encodeJpg(dbg, quality: debugImageQuality);
// //         await File(debugOutPath).writeAsBytes(dbgBytes);
// //       }
// //
// //       return ScanResult(
// //         studentId: finalStudentId,
// //         mobileNumber: finalMobile,
// //         setNumber: setNum,
// //         detectedAnswers: answers,
// //         confidence: confidence,
// //       );
// //     } catch (e, st) {
// //       return ScanResult(detectedAnswers: [], confidence: 0.0, errorMessage: e.toString());
// //     }
// //   }
// //
// //   /// OCR pass to try and read printed numbers (fallback).
// //   Future<Map<String, String?>> _extractNumericText(File imageFile) async {
// //     final inputImage = InputImage.fromFile(imageFile);
// //     try {
// //       final recognized = await _textRecognizer.processImage(inputImage);
// //       String? studentId;
// //       String? mobile;
// //       // try patterns: 10-digit and 11-digit
// //       final studentPattern = RegExp(r'\b\d{10}\b');
// //       final mobilePattern = RegExp(r'\b\d{11}\b');
// //
// //       for (var block in recognized.blocks) {
// //         final t = block.text.replaceAll(RegExp(r'[^0-9]'), '');
// //         final m1 = studentPattern.firstMatch(block.text);
// //         final m2 = mobilePattern.firstMatch(block.text);
// //         if (m2 != null && mobile == null) mobile = m2.group(0);
// //         if (m1 != null && studentId == null) studentId = m1.group(0);
// //         // also check cleaned t
// //         if (mobile == null && mobilePattern.hasMatch(t)) {
// //           mobile = mobilePattern.firstMatch(t)!.group(0);
// //         }
// //         if (studentId == null && studentPattern.hasMatch(t)) {
// //           studentId = studentPattern.firstMatch(t)!.group(0);
// //         }
// //       }
// //       return {'studentId': studentId, 'mobile': mobile};
// //     } catch (_) {
// //       return {'studentId': null, 'mobile': null};
// //     }
// //   }
// //
// //   /// Detect the Set Number (4 radio-like bubbles in setRegion).
// //   int? _detectSetNumber(img.Image image) {
// //     final rect = template.setRegion.toAbsolute(image.width, image.height);
// //     final sub = _cropImage(image, rect);
// //     if (sub == null) return null;
// //
// //     // there are 4 options horizontally
// //     final options = 4;
// //     final optionWidth = sub.width / options;
// //     double bestDark = 0;
// //     int bestIndex = -1;
// //
// //     for (int i = 0; i < options; i++) {
// //       final sx = (i * optionWidth).round();
// //       final w = (optionWidth).round();
// //       final sxRect = ui.Rect.fromLTWH(sx.toDouble(), 0, w.toDouble(), sub.height.toDouble());
// //       final subOpt = _cropImage(sub, sxRect);
// //       if (subOpt == null) continue;
// //       final darkness = _calculateCircleDarkness(subOpt);
// //       if (darkness > bestDark) {
// //         bestDark = darkness;
// //         bestIndex = i;
// //       }
// //     }
// //
// //     if (bestDark > circleDarkThreshold) {
// //       return bestIndex + 1; // set numbers likely 1..4
// //     }
// //     return null;
// //   }
// //
// //   /// Detect a digit grid like studentId/mobile. returns string of digits or null if incomplete.
// //   String? _detectDigitGrid(img.Image image, RelativeRect gridRect, {required int digitsPerRow, required int rows, double threshold = 0.45}) {
// //     final rect = gridRect.toAbsolute(image.width, image.height);
// //     final gridImg = _cropImage(image, rect);
// //     if (gridImg == null) return null;
// //
// //     final cellW = gridImg.width / digitsPerRow;
// //     final cellH = gridImg.height / rows;
// //
// //     final digits = StringBuffer();
// //
// //     for (int col = 0; col < digitsPerRow; col++) {
// //       // Each column is a digit (0..9) vertically - we expect rows == 10 for digits 0..9 (top to bottom)
// //       int chosenDigit = -1;
// //       double bestDark = 0;
// //       for (int row = 0; row < rows; row++) {
// //         final left = (col * cellW).round();
// //         final top = (row * cellH).round();
// //         final w = cellW.round();
// //         final h = cellH.round();
// //         final regionRect = ui.Rect.fromLTWH(left.toDouble(), top.toDouble(), w.toDouble(), h.toDouble());
// //         final cellImg = _cropImage(gridImg, regionRect);
// //         if (cellImg == null) continue;
// //         final darkness = _calculateCircleDarkness(cellImg);
// //         if (darkness > bestDark) {
// //           bestDark = darkness;
// //           chosenDigit = row; // mapping: row 0 -> digit 0 (you might need to invert depending on sheet)
// //         }
// //       }
// //       if (bestDark > threshold && chosenDigit >= 0) {
// //         digits.write(chosenDigit.toString());
// //       } else {
// //         digits.write(''); // leave empty
// //       }
// //     }
// //
// //     final result = digits.toString();
// //     // basic sanity: return only if we got a full set (digitsPerRow long)
// //     if (result.length == digitsPerRow) return result;
// //     // else return null (OCR fallback used earlier)
// //     return null;
// //   }
// //
// //   /// Detect answers grid. Returns list length = questions with 'A'..'D' or ''.
// //   List<String> _detectAnswersGrid(img.Image image) {
// //     final rect = template.answersRegion.toAbsolute(image.width, image.height);
// //     final gridImg = _cropImage(image, rect);
// //     if (gridImg == null) return List.filled(template.questions, '');
// //
// //     final qPerColumn = (template.questions / template.columns).ceil();
// //     final columnWidth = gridImg.width / template.columns;
// //     final rowHeight = gridImg.height / qPerColumn;
// //     final optionWidth = columnWidth / template.optionsPerQuestion;
// //
// //     final answers = List<String>.filled(template.questions, '');
// //
// //     for (int qIndex = 0; qIndex < template.questions; qIndex++) {
// //       final column = qIndex ~/ qPerColumn;
// //       final row = qIndex % qPerColumn;
// //
// //       final baseX = (column * columnWidth).round();
// //       final baseY = (row * rowHeight).round();
// //
// //       double bestDark = 0;
// //       int bestOption = -1;
// //       for (int opt = 0; opt < template.optionsPerQuestion; opt++) {
// //         final left = baseX + (opt * optionWidth).round();
// //         final regionRect = ui.Rect.fromLTWH(left.toDouble(), baseY.toDouble(), optionWidth.roundToDouble(), rowHeight.toDouble());
// //         final cellImg = _cropImage(gridImg, regionRect);
// //         if (cellImg == null) continue;
// //         final darkness = _calculateCircleDarkness(cellImg);
// //         if (darkness > bestDark) {
// //           bestDark = darkness;
// //           bestOption = opt;
// //         }
// //       }
// //
// //       if (bestDark > circleDarkThreshold && bestOption >= 0) {
// //         answers[qIndex] = String.fromCharCode('A'.codeUnitAt(0) + bestOption);
// //       } else {
// //         answers[qIndex] = ''; // unanswered or ambiguous
// //       }
// //     }
// //
// //     return answers;
// //   }
// //
// //   /// Crop image (image package) using a Rect in pixel coordinates.
// //   img.Image? _cropImage(img.Image source, ui.Rect rect) {
// //     final left = rect.left.round().clamp(0, source.width - 1);
// //     final top = rect.top.round().clamp(0, source.height - 1);
// //     final w = rect.width.round().clamp(1, source.width - left);
// //     final h = rect.height.round().clamp(1, source.height - top);
// //     try {
// //       return img.copyCrop(source, left, top, w, h);
// //     } catch (_) {
// //       return null;
// //     }
// //   }
// //
// //   /// Compute darkness inside a circular inner area of the provided image.
// //   /// We will assume the bubble occupies most of the small cell; use circle mask.
// //   double _calculateCircleDarkness(img.Image cell) {
// //     final w = cell.width;
// //     final h = cell.height;
// //     final cx = (w / 2).floor();
// //     final cy = (h / 2).floor();
// //     final r = max(1, (min(w, h) * 0.4).floor()); // slightly conservative radius
// //     int dark = 0;
// //     int total = 0;
// //
// //     for (int y = max(0, cy - r); y <= min(h - 1, cy + r); y++) {
// //       for (int x = max(0, cx - r); x <= min(w - 1, cx + r); x++) {
// //         final dx = x - cx;
// //         final dy = y - cy;
// //         if (dx * dx + dy * dy <= r * r) {
// //           final px = cell.getPixel(x, y);
// //           final lum = img.getLuminance(px);
// //           if (lum < 130) dark++; // tuned threshold; black = 0, white = 255
// //           total++;
// //         }
// //       }
// //     }
// //     if (total == 0) return 0.0;
// //     return dark / total;
// //   }
// //
// //   /// Optional debug canvas: draw rectangles and filled marks on top of source and return an annotated image.
// //   img.Image _visualizeDetection(img.Image source, String? studentId, String? mobile, int? setNum, List<String> answers) {
// //     final out = img.copyResize(source, width: source.width); // copy
// //     final paintRect = (img.ColorInt8(255, 0, 0, 255).toInt());
// //     // Draw set region
// //     void drawRectRect(ui.Rect r, int color) {
// //       final left = r.left.round();
// //       final top = r.top.round();
// //       final right = (r.left + r.width).round();
// //       final bottom = (r.top + r.height).round();
// //       for (int x = left; x <= right; x++) {
// //         if (top >= 0 && top < out.height) out.setPixelSafe(x, top, color);
// //         if (bottom >= 0 && bottom < out.height) out.setPixelSafe(x, bottom, color);
// //       }
// //       for (int y = top; y <= bottom; y++) {
// //         if (left >= 0 && left < out.width) out.setPixelSafe(left, y, color);
// //         if (right >= 0 && right < out.width) out.setPixelSafe(right, y, color);
// //       }
// //     }
// //
// //     // draw template rects
// //     drawRectRect(template.setRegion.toAbsolute(out.width, out.height), img.getColor(255, 0, 0));
// //     drawRectRect(template.studentIdRegion.toAbsolute(out.width, out.height), img.getColor(0, 255, 0));
// //     drawRectRect(template.mobileRegion.toAbsolute(out.width, out.height), img.getColor(0, 0, 255));
// //     drawRectRect(template.answersRegion.toAbsolute(out.width, out.height), img.getColor(255, 140, 0));
// //
// //     // draw small markers for answers chosen
// //     final answersRect = template.answersRegion.toAbsolute(out.width, out.height);
// //     final gridImg = _cropImage(out, answersRect)!;
// //     final qPerColumn = (template.questions / template.columns).ceil();
// //     final columnWidth = gridImg.width / template.columns;
// //     final rowHeight = gridImg.height / qPerColumn;
// //     final optionWidth = columnWidth / template.optionsPerQuestion;
// //
// //     for (int qIndex = 0; qIndex < answers.length && qIndex < template.questions; qIndex++) {
// //       final column = qIndex ~/ qPerColumn;
// //       final row = qIndex % qPerColumn;
// //       final baseX = answersRect.left + column * columnWidth;
// //       final baseY = answersRect.top + row * rowHeight;
// //
// //       final ans = answers[qIndex];
// //       if (ans.isNotEmpty) {
// //         final opt = ans.codeUnitAt(0) - 'A'.codeUnitAt(0);
// //         final left = (baseX + opt * optionWidth).round();
// //         final top = (baseY).round();
// //         // draw small filled square to mark detection
// //         for (int y = top; y < top + 6 && y < out.height; y++) {
// //           for (int x = left; x < left + 6 && x < out.width; x++) {
// //             out.setPixelSafe(x, y, img.getColor(255, 0, 0));
// //           }
// //         }
// //       }
// //     }
// //     return out;
// //   }
// //
// //   /// Compute combined confidence (very simple heuristic)
// //   double _computeConfidence(List<String> answers, String? studentId, String? mobile, int? setNum) {
// //     double qConfidence = answers.isEmpty ? 0.0 : (answers.where((a) => a.isNotEmpty).length / answers.length);
// //     double idConfidence = (studentId != null && studentId.length >= 8) ? 1.0 : 0.0;
// //     double mobileConfidence = (mobile != null && mobile.length >= 10) ? 1.0 : 0.0;
// //     double setConfidence = (setNum != null) ? 1.0 : 0.0;
// //
// //     // weighted sum
// //     final score = (qConfidence * 0.6) + (idConfidence * 0.15) + (mobileConfidence * 0.15) + (setConfidence * 0.1);
// //     return double.parse(score.toStringAsFixed(3));
// //   }
// //
// //   void dispose() {
// //     _textRecognizer.close();
// //   }
// // }
