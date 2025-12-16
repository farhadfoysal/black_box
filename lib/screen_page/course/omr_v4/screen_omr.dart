// lib/main.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

List<CameraDescription> cameras = [];

class CameraOMRPage extends StatefulWidget {
  @override
  _CameraOMRPageState createState() => _CameraOMRPageState();
}

class _CameraOMRPageState extends State<CameraOMRPage> {
  CameraController? _controller;
  bool _processing = false;
  Uint8List? _annotatedImage;
  Map<String, dynamic>? _lastResult;

  // MethodChannel to native
  static const platform = MethodChannel('omr_processor');

  // throttle to ~5 fps
  final int frameSkip = 3;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) {
      debugPrint('No cameras available');
      return;
    }
    final cam = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(cam, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    await _controller!.setFocusMode(FocusMode.auto);

    _controller!.startImageStream(_processCameraImage);

    setState(() {});
  }

  // Convert CameraImage (YUV420) to NV21 byte array (Android's preferred)
  Uint8List _concatenatePlanes(CameraImage image) {
    // For android YUV420, planes[0]=Y, planes[1]=U, planes[2]=V
    // create NV21 (Y + interleaved VU)
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = width * height ~/ 2;

    final Uint8List nv21 = Uint8List(ySize + uvSize);
    int offset = 0;

    // copy Y
    final Plane planeY = image.planes[0];
    if (planeY.bytes.length == ySize) {
      nv21.setRange(0, ySize, planeY.bytes);
    } else {
      // copy row by row
      int dst = 0;
      for (int i = 0; i < planeY.bytes.length; i++) {
        nv21[dst++] = planeY.bytes[i];
        if (dst >= ySize) break;
      }
    }
    offset = ySize;

    // Interleave VU (Android NV21 -> V then U)
    final Plane planeU = image.planes[1];
    final Plane planeV = image.planes[2];

    // planeU and planeV might have rowStride, pixelStride; interleave properly
    final int halfHeight = (height / 2).floor();
    final int rowStrideU = planeU.bytesPerRow;
    final int pixelStrideU = planeU.bytesPerPixel ?? 1;
    final int rowStrideV = planeV.bytesPerRow;
    final int pixelStrideV = planeV.bytesPerPixel ?? 1;

    int pos = offset;
    for (int row = 0; row < halfHeight; row++) {
      int colU = row * rowStrideU;
      int colV = row * rowStrideV;
      for (int col = 0; col < width / 2; col++) {
        // NV21 expects V then U
        nv21[pos++] = planeV.bytes[colV];
        nv21[pos++] = planeU.bytes[colU];
        colU += pixelStrideU;
        colV += pixelStrideV;
      }
    }

    return nv21;
  }

  Future<void> _processCameraImage(CameraImage image) async {
    _frameCount++;
    if (_frameCount % frameSkip != 0) return;
    if (_processing) return;
    _processing = true;

    try {
      final nv21 = _concatenatePlanes(image);
      final args = {
        'bytes': nv21,
        'width': image.width,
        'height': image.height,
        'rotation': _controller?.description.sensorOrientation ?? 0,
        // configure grid expected size (tweak for your sheet)
        'expectedRows': 10,
        'expectedCols': 4,
        'minContourArea': 150, // tuning
      };

      // send to native via MethodChannel
      final result = await platform.invokeMethod('processFrame', args);
      if (result != null) {
        final Map<dynamic, dynamic> map = result;
        setState(() {
          _lastResult = Map<String, dynamic>.from(map['data'] ?? {});
          final List<dynamic>? imgBytes = map['annotatedImage'];
          if (imgBytes != null) {
            _annotatedImage = Uint8List.fromList(List<int>.from(imgBytes));
          }
        });
      }
    } on PlatformException catch (e) {
      debugPrint('Platform exception: $e');
    } catch (e) {
      debugPrint('Error processing frame: $e');
    } finally {
      _processing = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildResultPanel() {
    if (_lastResult == null) return SizedBox.shrink();
    final filled = _lastResult!['filled'] ?? [];
    return Container(
      color: Colors.black.withOpacity(0.5),
      padding: EdgeInsets.all(8),
      child: SingleChildScrollView(
        child: Text('Filled bubbles: ${jsonEncode(filled)}', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),
          if (_annotatedImage != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.9,
                child: Image.memory(_annotatedImage!, fit: BoxFit.cover),
              ),
            ),
          Positioned(top: 40, left: 8, right: 8, child: _buildResultPanel()),
          Positioned(bottom: 20, left: 8, child: Text('Realtime OMR Scanner', style: TextStyle(color: Colors.white, fontSize: 18))),
        ],
      ),
    );
  }
}
