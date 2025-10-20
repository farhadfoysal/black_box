import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'omr_processor.dart';
import 'omr_result.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController cameraController = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: true, // IMPORTANT: enables image capture from frames
  );

  bool _processing = false;
  String? _status;
  OMRResult? _lastResult;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _processBarcode(Barcode barcode, Uint8List? frameImage) async {
    if (_processing) return;
    _processing = true;
    setState(() => _status = 'QR detected, processing image...');

    final rawValue = barcode.rawValue ?? '';

    if (frameImage == null) {
      setState(() => _status = 'No camera frame available');
      _processing = false;
      return;
    }

    try {
      final processor = OMRProcessor();
      final result =
      await processor.processImageForOMR(frameImage, anchorQrData: rawValue);

      setState(() {
        _lastResult = result;
        _status = 'Done ✅';
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }

    _processing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan OMR Tag')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                final image = capture.image; // Uint8List frame
                if (barcodes.isNotEmpty && image != null) {
                  _processBarcode(barcodes.first, image);
                }
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${_status ?? "Waiting for QR..."}'),
                  const SizedBox(height: 8),
                  if (_lastResult != null) ...[
                    Text('Student: ${_lastResult!.studentId}'),
                    Text('Phone: ${_lastResult!.phone}'),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _lastResult!.answers.length,
                        itemBuilder: (context, i) {
                          return ListTile(
                            title: Text(
                                'Q${i + 1} → ${_lastResult!.answers[i] ?? "-"}'),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    const Text('No result yet. Align QR and wait...'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'omr_processor.dart';
// import 'omr_result.dart';
//
// class ScannerPage extends StatefulWidget {
//   const ScannerPage({Key? key}) : super(key: key);
//
//   @override
//   _ScannerPageState createState() => _ScannerPageState();
// }
//
// class _ScannerPageState extends State<ScannerPage> {
//   final MobileScannerController cameraController = MobileScannerController(
//     facing: CameraFacing.back,
//     detectionSpeed: DetectionSpeed.noDuplicates,
//   );
//
//   bool _processing = false;
//   String? _status;
//   OMRResult? _lastResult;
//
//   @override
//   void dispose() {
//     cameraController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _processBarcode(Barcode barcode, MobileScannerArguments? args) async {
//     if (_processing) return;
//     _processing = true;
//     setState(() => _status = 'QR detected, capturing image...');
//
//     final rawValue = barcode.rawValue ?? '';
//
//     // Take a picture
//     try {
//       final image = await cameraController.takePicture();
//       final bytes = await File(image.path).readAsBytes();
//
//       setState(() => _status = 'Processing image...');
//       final processor = OMRProcessor();
//       final result = await processor.processImageForOMR(bytes, anchorQrData: rawValue);
//
//       setState(() {
//         _lastResult = result;
//         _status = 'Done';
//       });
//     } catch (e) {
//       setState(() => _status = 'Error: \$e');
//     }
//
//     _processing = false;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Scan OMR Tag')),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 3,
//             child: MobileScanner(
//               controller: cameraController,
//               onDetect: (capture) {
//                 final List<Barcode> barcodes = capture.barcodes;
//                 if (barcodes.isNotEmpty) {
//                   _processBarcode(barcodes.first, capture);
//                 }
//               },
//             ),
//           ),
//           Expanded(
//             flex: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Status: ${_status ?? "Waiting for QR..."}'),
//                   const SizedBox(height: 8),
//                   if (_lastResult != null) ...[
//                     Text('Student: \${_lastResult!.studentId}'),
//                     Text('Phone: \${_lastResult!.phone}'),
//                     const SizedBox(height: 8),
//                     Expanded(
//                       child: ListView.builder(
//                         itemCount: _lastResult!.answers.length,
//                         itemBuilder: (context, i) {
//                           return ListTile(
//                             title: Text('Q\${i + 1} => \${_lastResult!.answers[i] ?? "-"}'),
//                           );
//                         },
//                       ),
//                     )
//                   ] else ...[
//                     const Text('No result yet. Align tag QR and wait.'),
//                   ]
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }