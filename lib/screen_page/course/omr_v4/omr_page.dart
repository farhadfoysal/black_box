import 'dart:async';
import 'dart:ui' as ui;
import 'package:black_box/screen_page/course/omr_v4/result_panel.dart';
import 'package:black_box/screen_page/course/omr_v4/screen_omr.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

import 'omr_detector.dart';
import 'omr_overlay_painter.dart';


class OMRScannerrScreen extends StatefulWidget {
  const OMRScannerrScreen({Key? key}) : super(key: key);

  @override
  State<OMRScannerrScreen> createState() => _OMRScannerScreenState();
}

class _OMRScannerScreenState extends State<OMRScannerrScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  OMRDetector? _omrDetector;

  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isScanning = false;

  List<OMRResult> _detectionResults = [];
  Map<int, String> _answers = {};

  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestPermissions();
    await _initializeCamera();
    await _initializeDetector();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'This app needs camera permission to scan OMR sheets.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) {
      print('No cameras available');
      return;
    }

    try {
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _initializeDetector() async {
    _omrDetector = OMRDetector();
    await _omrDetector!.initialize();
  }

  void _startScanning() {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _answers.clear();
    });

    _scanTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isProcessing && mounted) {
        _processFrame();
      }
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
    _scanTimer?.cancel();
  }

  Future<void> _processFrame() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        final results = await _omrDetector!.detectOMR(decodedImage);

        if (mounted) {
          setState(() {
            _detectionResults = results;
            _updateAnswers(results);
          });
        }
      }
    } catch (e) {
      print('Error processing frame: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _updateAnswers(List<OMRResult> results) {
    for (var result in results) {
      if (result.isFilled) {
        _answers[result.questionNumber] = result.option;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanTimer?.cancel();
    _cameraController?.dispose();
    _omrDetector?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'OMR Scanner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isScanning ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: _isScanning ? _stopScanning : _startScanning,
          ),
        ],
      ),
      body: _isInitialized
          ? Stack(
        children: [
          _buildCameraPreview(),
          _buildOverlay(),
          _buildStatusBar(),
          if (_isScanning) _buildResultsPanel(),
        ],
      )
          : const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null) {
      return const SizedBox();
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CameraPreview(_cameraController!),
    );
  }

  Widget _buildOverlay() {
    return CustomPaint(
      painter: OMROverlayPainter(
        detectionResults: _detectionResults,
      ),
      child: Container(),
    );
  }

  Widget _buildStatusBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _isScanning ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isScanning ? 'SCANNING' : 'READY',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Detected: ${_detectionResults.where((r) => r.isFilled).length} bubbles',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              'Answers: ${_answers.length}/50',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsPanel() {
    return ResultsPanel(
      answers: _answers,
      onClose: _stopScanning,
    );
  }
}