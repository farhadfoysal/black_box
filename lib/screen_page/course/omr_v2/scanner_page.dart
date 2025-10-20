import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'advanced_omr_processor.dart';
import 'omr_database_manager.dart';
import 'perspective_corrector.dart';

class ScannerPage extends StatefulWidget {
  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitializing = true;
  bool _isScanning = false;
  List<Exam> _exams = [];
  Exam? _selectedExam;
  OMRResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadExams();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      _controller = CameraController(_cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      setState(() => _isInitializing = false);
    } catch (e) {
      print('Camera initialization error: $e');
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _loadExams() async {
    try {
      _exams = await DatabaseManager.getExams();
      if (_exams.isNotEmpty) {
        _selectedExam = _exams.first;
      }
      setState(() {});
    } catch (e) {
      _showError('Failed to load exams: $e');
    }
  }

  Future<void> _captureAndScan() async {
    if (_isScanning || _selectedExam == null) return;

    setState(() => _isScanning = true);

    try {
      final image = await _controller!.takePicture();
      final result = await _scanImage(image.path);

      if (result != null) {
        await DatabaseManager.insertResult(result);
        setState(() => _lastResult = result);
        _showScanResults(result);
      }
    } catch (e) {
      _showError('Scanning failed: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<OMRResult?> _scanImage(String imagePath) async {
    final imageFile = img.decodeImage(await File(imagePath).readAsBytes());
    if (imageFile == null) throw Exception('Could not load image');

    // Apply perspective correction
    final correctedImage = PerspectiveCorrector.correctPerspective(imageFile) ?? imageFile;

    // Generate bubble regions based on exam configuration
    final bubbleRegions = _generateBubbleRegions(_selectedExam!);

    // Detect bubbles with advanced processing
    final detectionResult = AdvancedOMRProcessor.detectBubbles(
      correctedImage,
      regions: bubbleRegions,
      useAdaptiveThreshold: true,
    );

    // Extract data from detection
    final answers = _extractAnswers(detectionResult, _selectedExam!.totalQuestions);
    final setNumber = _extractSetNumber(detectionResult);
    final studentId = _extractStudentId(detectionResult);
    final mobileNumber = _extractMobileNumber(detectionResult);

    // Calculate confidence and score
    final confidence = _calculateOverallConfidence(detectionResult);
    final score = _calculateScore(answers, _selectedExam!.correctAnswers);

    return OMRResult(
      examId: _selectedExam!.id!,
      studentId: studentId,
      setNumber: setNumber,
      mobileNumber: mobileNumber,
      answers: answers,
      score: score,
      scannedAt: DateTime.now(),
      confidence: confidence,
    );
  }

  List<BubbleRegion> _generateBubbleRegions(Exam exam) {
    final regions = <BubbleRegion>[];
    final totalQuestions = exam.totalQuestions;

    // Set number bubbles
    for (int i = 0; i < 10; i++) {
      regions.add(BubbleRegion(
        x: 150 + i * 25,
        y: 80,
        width: 12,
        height: 12,
        identifier: 'SET_$i',
      ));
    }

    // Student ID bubbles
    for (int digit = 0; digit < 9; digit++) {
      for (int num = 0; num < 10; num++) {
        regions.add(BubbleRegion(
          x: 150 + digit * 25,
          y: 130 + num * 20,
          width: 12,
          height: 12,
          identifier: 'ID_${digit}_$num',
        ));
      }
    }

    // Question bubbles
    final questionsPerColumn = 25;
    final columns = (totalQuestions / questionsPerColumn).ceil();

    for (int col = 0; col < columns; col++) {
      for (int q = 0; q < questionsPerColumn; q++) {
        final questionNum = col * questionsPerColumn + q + 1;
        if (questionNum > totalQuestions) break;

        for (int option = 0; option < 5; option++) {
          regions.add(BubbleRegion(
            x: 115 + col * 250 + option * 25,
            y: 600 + q * 30,
            width: 12,
            height: 12,
            identifier: 'Q${questionNum}_${String.fromCharCode(65 + option)}',
          ));
        }
      }
    }

    return regions;
  }

  List<int> _extractAnswers(BubbleDetectionResult result, int totalQuestions) {
    final answers = List<int>.filled(totalQuestions, 0);

    for (int i = 0; i < totalQuestions; i++) {
      for (int option = 0; option < 5; option++) {
        final identifier = 'Q${i + 1}_${String.fromCharCode(65 + option)}';
        final bubble = result.getBubbleByIdentifier(identifier);

        if (bubble != null && bubble.isFilled) {
          answers[i] = 65 + option;
          break;
        }
      }
    }

    return answers;
  }

  int _extractSetNumber(BubbleDetectionResult result) {
    for (int i = 0; i < 10; i++) {
      final bubble = result.getBubbleByIdentifier('SET_$i');
      if (bubble != null && bubble.isFilled) return i;
    }
    return 0;
  }

  String _extractStudentId(BubbleDetectionResult result) {
    final idDigits = List<String>.filled(9, '0');
    for (int digit = 0; digit < 9; digit++) {
      for (int num = 0; num < 10; num++) {
        final bubble = result.getBubbleByIdentifier('ID_${digit}_$num');
        if (bubble != null && bubble.isFilled) {
          idDigits[digit] = num.toString();
          break;
        }
      }
    }
    return idDigits.join();
  }

  String _extractMobileNumber(BubbleDetectionResult result) {
    // Similar implementation to student ID
    return 'Not implemented';
  }

  double _calculateOverallConfidence(BubbleDetectionResult result) {
    if (result.detectedBubbles.isEmpty) return 0.0;
    return result.detectedBubbles
        .map((bubble) => bubble.confidence)
        .reduce((a, b) => a + b) / result.detectedBubbles.length;
  }

  double _calculateScore(List<int> answers, List<String> correctAnswers) {
    int correct = 0;
    for (int i = 0; i < answers.length; i++) {
      if (i < correctAnswers.length &&
          String.fromCharCode(answers[i]) == correctAnswers[i]) {
        correct++;
      }
    }
    return (correct / answers.length) * 100;
  }

  void _showScanResults(OMRResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scan Results', style: TextStyle(color: Colors.blue[800])),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResultItem('Student ID', result.studentId),
              _buildResultItem('Set Number', result.setNumber.toString()),
              _buildResultItem('Mobile', result.mobileNumber ?? 'N/A'),
              _buildResultItem('Score', '${result.score.toStringAsFixed(2)}%'),
              _buildResultItem('Confidence', '${(result.confidence * 100).toStringAsFixed(1)}%'),
              SizedBox(height: 16),
              Text('Answers:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: result.answers.asMap().entries.map((e) {
                  final isCorrect = e.key < _selectedExam!.correctAnswers.length &&
                      String.fromCharCode(e.value) == _selectedExam!.correctAnswers[e.key];
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: isCorrect ? Colors.green : Colors.red),
                    ),
                    child: Text(
                      'Q${e.key + 1}: ${String.fromCharCode(e.value)}',
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Optionally navigate to results page
            },
            child: Text('View Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Exam selection
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.assignment, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<Exam>(
                      value: _selectedExam,
                      isExpanded: true,
                      items: _exams.map((exam) {
                        return DropdownMenuItem(
                          value: exam,
                          child: Text('${exam.name} (${exam.totalQuestions} questions)'),
                        );
                      }).toList(),
                      onChanged: (exam) => setState(() => _selectedExam = exam),
                      hint: Text('Select Exam'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Camera preview
          Expanded(
            child: _isInitializing
                ? Center(child: CircularProgressIndicator())
                : _controller == null || !_controller!.value.isInitialized
                ? Center(child: Text('Camera not available'))
                : Stack(
              children: [
                CameraPreview(_controller!),
                // Add scanning guides
                _buildScanningOverlay(),
              ],
            ),
          ),

          // Controls
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                if (_lastResult != null) ...[
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Last Scan:', style: TextStyle(fontSize: 12)),
                              Text('ID: ${_lastResult!.studentId}',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Score:', style: TextStyle(fontSize: 12)),
                              Text('${_lastResult!.score.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _lastResult!.score >= 60 ? Colors.green : Colors.red,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _captureAndScan,
                        icon: _isScanning
                            ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Icon(Icons.camera_alt),
                        label: Text(_isScanning ? 'Scanning...' : 'Scan OMR Sheet'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
        ),
        child: CustomPaint(
          painter: _ScanningGuidePainter(),
        ),
      ),
    );
  }
}

class _ScanningGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw corner marks
    const cornerLength = 20.0;

    // Top-left
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerLength), paint);

    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}