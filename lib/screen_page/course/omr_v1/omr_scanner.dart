import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'omr_models.dart';

class OMRScanner extends StatefulWidget {
  final OMRExamConfig examConfig;

  const OMRScanner({Key? key, required this.examConfig}) : super(key: key);

  @override
  _OMRScannerState createState() => _OMRScannerState();
}

class _OMRScannerState extends State<OMRScanner> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = false;

  Future<void> _captureAndScan() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    try {
      // Take a picture

      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final scannedResponse = await _scanImage(pickedFile.path as img.Image);
      }

      if (pickedFile == null) throw Exception("Failed to capture image");

      // Load image using `image` package
      final rawImage = img.decodeImage(await File(pickedFile.path).readAsBytes());
      if (rawImage == null) throw Exception('Could not decode image');

      // Scan the OMR sheet
      final response = await _scanImage(rawImage);

      _showScanResults(response);
    } catch (e) {
      print('Error scanning: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning OMR sheet: $e')),
      );
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<OMRResponse> _scanImage(img.Image image) async {
    final grayImage = img.grayscale(image);
    final resizedImage = img.copyResize(grayImage, width: 595, height: 842);

    List<int> answers = [];

    for (int i = 0; i < widget.examConfig.numberOfQuestions; i++) {
      final questionIndex = i ~/ 25;
      final questionInColumn = i % 25;

      String? detectedAnswer;

      for (int option = 0; option < 5; option++) {
        final x = (115 + questionIndex * 250 + option * 25).toInt();
        final y = (600 + questionInColumn * 30).toInt();

        if (_isBubbleFilled(resizedImage, x, y)) {
          detectedAnswer = String.fromCharCode(65 + option);
          break;
        }
      }

      answers.add(detectedAnswer?.codeUnitAt(0) ?? 0);
    }

    return OMRResponse(
      setNumber: _scanSetNumber(resizedImage),
      studentId: _scanStudentId(resizedImage),
      mobileNumber: _scanMobileNumber(resizedImage),
      answers: answers,
      score: _calculateScore(answers),
    );
  }

  bool _isBubbleFilled(img.Image image, int x, int y) {
    int darkPixels = 0;
    int totalPixels = 0;

    for (int dx = -3; dx <= 3; dx++) {
      for (int dy = -3; dy <= 3; dy++) {
        if (dx * dx + dy * dy <= 9) {
          final pixel = image.getPixel(x + dx, y + dy);
          final luminance = img.getLuminance(pixel);
          if (luminance < 128) darkPixels++;
          totalPixels++;
        }
      }
    }

    return (darkPixels / totalPixels) > 0.6;
  }

  int _scanSetNumber(img.Image image) {
    for (int i = 0; i < 10; i++) {
      final x = (150 + i * 25).toInt();
      if (_isBubbleFilled(image, x, 80)) return i;
    }
    return 0;
  }

  String _scanStudentId(img.Image image) {
    String studentId = '';
    for (int digitPos = 0; digitPos < 9; digitPos++) {
      for (int num = 0; num < 10; num++) {
        final x = (150 + digitPos * 25).toInt();
        final y = (130 + num * 20).toInt();
        if (_isBubbleFilled(image, x, y)) {
          studentId += num.toString();
          break;
        }
      }
    }
    return studentId;
  }

  String _scanMobileNumber(img.Image image) {
    String mobile = '';
    for (int digitPos = 0; digitPos < 11; digitPos++) {
      for (int num = 0; num < 10; num++) {
        final x = (150 + digitPos * 25).toInt();
        final y = (360 + num * 20).toInt();
        if (_isBubbleFilled(image, x, y)) {
          mobile += num.toString();
          break;
        }
      }
    }
    return mobile;
  }

  double _calculateScore(List<int> answers) {
    int correct = 0;
    for (int i = 0; i < answers.length; i++) {
      if (i < widget.examConfig.correctAnswers.length &&
          answers[i] == widget.examConfig.correctAnswers[i].codeUnitAt(0)) {
        correct++;
      }
    }
    return (correct / widget.examConfig.numberOfQuestions) * 100;
  }

  void _showScanResults(OMRResponse response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scan Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set Number: ${response.setNumber}'),
              Text('Student ID: ${response.studentId}'),
              Text('Mobile: ${response.mobileNumber}'),
              Text('Score: ${response.score.toStringAsFixed(2)}%'),
              SizedBox(height: 10),
              Text('Answers:'),
              for (int i = 0; i < response.answers.length; i++)
                Text('Q${i + 1}: ${String.fromCharCode(response.answers[i])}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OMR Scanner')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _scannerController,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: _isScanning
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _captureAndScan,
              child: Text('Scan OMR Sheet'),
            ),
          ),
        ],
      ),
    );
  }
}



// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:image/image.dart' as img;
//
// import 'omr_models.dart';
//
// class OMRScanner extends StatefulWidget {
//   final OMRExamConfig examConfig;
//
//   const OMRScanner({Key? key, required this.examConfig}) : super(key: key);
//
//   @override
//   _OMRScannerState createState() => _OMRScannerState();
// }
//
// class _OMRScannerState extends State<OMRScanner> {
//   CameraController? _controller;
//   List<CameraDescription>? _cameras;
//   bool _isScanning = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }
//
//   Future<void> _initializeCamera() async {
//     _cameras = await availableCameras();
//     _controller = CameraController(_cameras![0], ResolutionPreset.high);
//     await _controller!.initialize();
//     setState(() {});
//   }
//
//   Future<void> _captureAndScan() async {
//     if (_isScanning) return;
//
//     setState(() => _isScanning = true);
//
//     try {
//       final image = await _controller!.takePicture();
//       final scannedResponse = await _scanImage(image.path);
//
//       // Show results
//       _showScanResults(scannedResponse);
//     } catch (e) {
//       print('Error scanning: $e');
//     } finally {
//       setState(() => _isScanning = false);
//     }
//   }
//
//   Future<OMRResponse> _scanImage(String imagePath) async {
//     // Load image
//     final imageFile = img.decodeImage(await File(imagePath).readAsBytes());
//     if (imageFile == null) throw Exception('Could not load image');
//
//     // Convert to grayscale
//     final grayImage = img.grayscale(imageFile);
//
//     // Simple thresholding
//     final binaryImage = img.copyResize(grayImage, width: 595, height: 842);
//
//     List<int> answers = [];
//
//     // Scan questions (simplified logic)
//     for (int i = 0; i < widget.examConfig.numberOfQuestions; i++) {
//       final questionIndex = i ~/ 25;
//       final questionInColumn = i % 25;
//
//       String? detectedAnswer;
//
//       // Check each option for this question
//       for (int option = 0; option < 5; option++) {
//         final x = (115 + questionIndex * 250 + option * 25).toInt();
//         final y = (600 + questionInColumn * 30).toInt();
//
//         if (_isBubbleFilled(binaryImage, x, y)) {
//           detectedAnswer = String.fromCharCode(65 + option);
//           break;
//         }
//       }
//
//       answers.add(detectedAnswer?.codeUnitAt(0) ?? 0);
//     }
//
//     // Calculate score
//     double score = _calculateScore(answers);
//
//     return OMRResponse(
//       setNumber: _scanSetNumber(binaryImage),
//       studentId: _scanStudentId(binaryImage),
//       mobileNumber: _scanMobileNumber(binaryImage),
//       answers: answers,
//       score: score,
//     );
//   }
//
//   bool _isBubbleFilled(img.Image image, int x, int y) {
//     // Sample pixels in the bubble area
//     int darkPixels = 0;
//     int totalPixels = 0;
//
//     for (int dx = -3; dx <= 3; dx++) {
//       for (int dy = -3; dy <= 3; dy++) {
//         if (dx * dx + dy * dy <= 9) { // Circular area
//           final pixel = image.getPixel(x + dx, y + dy);
//           final luminance = img.getLuminance(pixel);
//           if (luminance < 128) darkPixels++;
//           totalPixels++;
//         }
//       }
//     }
//
//     // Consider filled if more than 60% dark
//     return (darkPixels / totalPixels) > 0.6;
//   }
//
//   int _scanSetNumber(img.Image image) {
//     for (int i = 0; i < 10; i++) {
//       final x = (150 + i * 25).toInt();
//       if (_isBubbleFilled(image, x, 80)) return i;
//     }
//     return 0;
//   }
//
//   String _scanStudentId(img.Image image) {
//     String studentId = '';
//     for (int digitPos = 0; digitPos < 9; digitPos++) {
//       for (int num = 0; num < 10; num++) {
//         final x = (150 + digitPos * 25).toInt();
//         final y = (130 + num * 20).toInt();
//         if (_isBubbleFilled(image, x, y)) {
//           studentId += num.toString();
//           break;
//         }
//       }
//     }
//     return studentId;
//   }
//
//   String _scanMobileNumber(img.Image image) {
//     String mobile = '';
//     for (int digitPos = 0; digitPos < 11; digitPos++) {
//       for (int num = 0; num < 10; num++) {
//         final x = (150 + digitPos * 25).toInt();
//         final y = (360 + num * 20).toInt();
//         if (_isBubbleFilled(image, x, y)) {
//           mobile += num.toString();
//           break;
//         }
//       }
//     }
//     return mobile;
//   }
//
//   double _calculateScore(List<int> answers) {
//     int correct = 0;
//     for (int i = 0; i < answers.length; i++) {
//       if (i < widget.examConfig.correctAnswers.length &&
//           answers[i] == widget.examConfig.correctAnswers[i].codeUnitAt(0)) {
//         correct++;
//       }
//     }
//     return (correct / widget.examConfig.numberOfQuestions) * 100;
//   }
//
//   void _showScanResults(OMRResponse response) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Scan Results'),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Set Number: ${response.setNumber}'),
//               Text('Student ID: ${response.studentId}'),
//               Text('Mobile: ${response.mobileNumber}'),
//               Text('Score: ${response.score.toStringAsFixed(2)}%'),
//               SizedBox(height: 10),
//               Text('Answers:'),
//               for (int i = 0; i < response.answers.length; i++)
//                 Text('Q${i + 1}: ${String.fromCharCode(response.answers[i])}'),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_controller == null || !_controller!.value.isInitialized) {
//       return Scaffold(
//         appBar: AppBar(title: Text('OMR Scanner')),
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(title: Text('OMR Scanner')),
//       body: Column(
//         children: [
//           Expanded(
//             child: CameraPreview(_controller!),
//           ),
//           Padding(
//             padding: EdgeInsets.all(16.0),
//             child: _isScanning
//                 ? CircularProgressIndicator()
//                 : ElevatedButton(
//               onPressed: _captureAndScan,
//               child: Text('Scan OMR Sheet'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }