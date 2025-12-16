import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'omr_scanner_service.dart';

class OMRScannerWidget extends StatefulWidget {
  @override
  _OMRScannerWidgetState createState() => _OMRScannerWidgetState();
}

class _OMRScannerWidgetState extends State<OMRScannerWidget> {
  final OMRScannerService _scannerService = OMRScannerService();
  final ImagePicker _picker = ImagePicker();

  bool _isProcessing = false;
  bool _isInitialized = false;
  OMRResult? _lastResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeScanner());
  }

  Future<void> _initializeScanner() async {
    try {
      await _scannerService.loadModel();
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _errorMessage = 'Scanner initialization failed: $e');
    }
  }

  /// ✅ Handles both camera and gallery permissions safely
  Future<void> _checkPermissions(ImageSource source) async {
    if (source == ImageSource.camera) {
      if (!await Permission.camera.isGranted) {
        await Permission.camera.request();
      }
      if (!await Permission.camera.isGranted) {
        throw Exception('Camera permission denied');
      }
    } else {
      // Storage or media images (Android 13+)
      if (Platform.isAndroid) {
        if (await Permission.photos.isDenied ||
            await Permission.photos.isPermanentlyDenied) {
          await Permission.photos.request();
        }

        // For Android < 13
        if (await Permission.storage.isDenied ||
            await Permission.storage.isPermanentlyDenied) {
          await Permission.storage.request();
        }
      } else if (Platform.isIOS) {
        if (await Permission.photos.isDenied) {
          await Permission.photos.request();
        }
      }

      if (!await Permission.photos.isGranted &&
          !await Permission.storage.isGranted) {
        throw Exception('Gallery permission denied');
      }
    }
  }

  /// ✅ Handles both Camera and Gallery pick
  Future<void> _pickAndProcessImage({required ImageSource source}) async {
    try {
      await _checkPermissions(source);

      final XFile? image = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (image == null) return;

      setState(() {
        _isProcessing = true;
        _errorMessage = null;
        _lastResult = null;
      });

      OMRResult result = await _scannerService.processImage(File(image.path));

      setState(() => _lastResult = result);
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value, style: TextStyle(fontFamily: 'Monospace', fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    if (_lastResult == null) return SizedBox();
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('স্ক্যান ফলাফল:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E324B))),
          SizedBox(height: 16),
          _buildResultRow('সেট নম্বর:', _lastResult!.setNumber.toString()),
          _buildResultRow('ছাত্র/ছাত্রী আইডি:', _lastResult!.studentId.map((d) => d == -1 ? '?' : d.toString()).join()),
          _buildResultRow('মোবাইল নম্বর:', _lastResult!.mobileNumber.map((d) => d == -1 ? '?' : d.toString()).join()),
          SizedBox(height: 16),
          Text('উত্তরসমূহ:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E324B))),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _lastResult!.answers.asMap().entries.map((entry) {
                return Chip(
                  label: Text('Q${entry.key + 1}: ${entry.value.isEmpty ? '?' : entry.value}', style: TextStyle(fontSize: 12)),
                  backgroundColor: entry.value.isEmpty ? Colors.orange : Color(0xFF1E324B),
                  labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('বাংলা OMR স্ক্যানার'),
        backgroundColor: Color(0xFF1E324B),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E324B), Color(0xFF2D4563)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.document_scanner, size: 48, color: Color(0xFF1E324B)),
                    SizedBox(height: 12),
                    Text('BANGLA QUIZ OMR SCANNER',
                        style: TextStyle(color: Color(0xFF1E324B), fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('AI-Powered Detection System',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                    SizedBox(height: 8),
                    _isInitialized
                        ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text('Scanner Ready', style: TextStyle(color: Colors.green, fontSize: 12)),
                    ])
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.sync, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text('Initializing...', style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Two Buttons: Camera & Gallery
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing || !_isInitialized
                        ? null
                        : () => _pickAndProcessImage(source: ImageSource.camera),
                    icon: Icon(Icons.camera_alt, size: 22),
                    label: Text('ক্যামেরা'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF4500),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing || !_isInitialized
                        ? null
                        : () => _pickAndProcessImage(source: ImageSource.gallery),
                    icon: Icon(Icons.photo_library, size: 22),
                    label: Text('গ্যালারি'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1E90FF),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            if (_isProcessing)
              Column(
                children: [
                  LinearProgressIndicator(
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
                  ),
                  SizedBox(height: 12),
                  Text('প্রসেসিং... দয়া করে অপেক্ষা করুন', style: TextStyle(color: Colors.white)),
                ],
              ),

            if (_errorMessage != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red))),
                  ]),
                ),
              ),

            Expanded(
              child: _lastResult != null
                  ? SingleChildScrollView(child: _buildResultCard())
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera_back, size: 54, color: Colors.white54),
                    SizedBox(height: 16),
                    Text('স্ক্যান করার জন্য ক্যামেরা বা গ্যালারি বাটন টিপুন',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}












// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// import 'omr_scanner_service.dart';
//
//
// class OMRScannerWidget extends StatefulWidget {
//   @override
//   _OMRScannerWidgetState createState() => _OMRScannerWidgetState();
// }
//
// class _OMRScannerWidgetState extends State<OMRScannerWidget> {
//   final OMRScannerService _scannerService = OMRScannerService();
//   final ImagePicker _picker = ImagePicker();
//   bool _isProcessing = false;
//   bool _isInitialized = false;
//   OMRResult? _lastResult;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeScanner();
//   }
//
//   Future<void> _initializeScanner() async {
//     try {
//       await _scannerService.loadModel();
//       setState(() {
//         _isInitialized = true;
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Scanner initialization failed: $e';
//       });
//     }
//   }
//
//   Future<void> _checkPermissions() async {
//     if (!await Permission.camera.isGranted) {
//       await Permission.camera.request();
//     }
//
//     if (!await Permission.storage.isGranted) {
//       await Permission.storage.request();
//     }
//
//     // Check again
//     if (!await Permission.camera.isGranted || !await Permission.storage.isGranted) {
//       throw Exception('Camera and storage permissions are required');
//     }
//   }
//
//
//   Future<void> _pickAndProcessImage() async {
//     try {
//       await _checkPermissions();
//
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.camera,
//         preferredCameraDevice: CameraDevice.rear,
//         maxWidth: 1920,
//         maxHeight: 1080,
//         imageQuality: 90,
//       );
//
//       if (image != null) {
//         setState(() {
//           _isProcessing = true;
//           _errorMessage = null;
//           _lastResult = null;
//         });
//
//         OMRResult result = await _scannerService.processImage(File(image.path));
//         setState(() {
//           _lastResult = result;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error: ${e.toString()}';
//       });
//     } finally {
//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }
//
//   Widget _buildResultCard() {
//     if (_lastResult == null) return SizedBox();
//
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'স্ক্যান ফলাফল:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1E324B),
//               ),
//             ),
//             SizedBox(height: 16),
//
//             _buildResultRow('সেট নম্বর:', _lastResult!.setNumber.toString()),
//
//             _buildResultRow(
//                 'ছাত্র/ছাত্রী আইডি:',
//                 _lastResult!.studentId.map((digit) => digit == -1 ? '?' : digit.toString()).join()
//             ),
//
//             _buildResultRow(
//                 'মোবাইল নম্বর:',
//                 _lastResult!.mobileNumber.map((digit) => digit == -1 ? '?' : digit.toString()).join()
//             ),
//
//             SizedBox(height: 16),
//
//             Text(
//               'উত্তরসমূহ:',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1E324B),
//               ),
//             ),
//             SizedBox(height: 8),
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Wrap(
//                 spacing: 8,
//                 runSpacing: 4,
//                 children: _lastResult!.answers.asMap().entries.map((entry) {
//                   return Chip(
//                     label: Text(
//                       'Q${entry.key + 1}: ${entry.value.isEmpty ? '?' : entry.value}',
//                       style: TextStyle(fontSize: 12),
//                     ),
//                     backgroundColor: entry.value.isEmpty ? Colors.orange : Color(0xFF1E324B),
//                     labelStyle: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildResultRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               label,
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontFamily: 'Monospace',
//                 fontSize: 16,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('বাংলা OMR স্ক্যানার'),
//         backgroundColor: Color(0xFF1E324B),
//         elevation: 0,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF1E324B),
//               Color(0xFF2D4563),
//             ],
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Header Card
//               Card(
//                 elevation: 8,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Column(
//                     children: [
//                       Icon(
//                         Icons.document_scanner,
//                         size: 48,
//                         color: Color(0xFF1E324B),
//                       ),
//                       SizedBox(height: 12),
//                       Text(
//                         'BANGLA QUIZ OMR SCANNER',
//                         style: TextStyle(
//                           color: Color(0xFF1E324B),
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       SizedBox(height: 8),
//                       Text(
//                         'AI-Powered Detection System',
//                         style: TextStyle(
//                           color: Colors.grey[700],
//                           fontSize: 14,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       _isInitialized
//                           ? Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.check_circle, color: Colors.green, size: 16),
//                           SizedBox(width: 4),
//                           Text(
//                             'Scanner Ready',
//                             style: TextStyle(color: Colors.green, fontSize: 12),
//                           ),
//                         ],
//                       )
//                           : Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.sync, color: Colors.orange, size: 16),
//                           SizedBox(width: 4),
//                           Text(
//                             'Initializing...',
//                             style: TextStyle(color: Colors.orange, fontSize: 12),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: 24),
//
//               // Scan Button
//               ElevatedButton.icon(
//                 onPressed: _isProcessing || !_isInitialized ? null : _pickAndProcessImage,
//                 icon: Icon(Icons.camera_alt, size: 24),
//                 label: Text(
//                   'OMR শীট স্ক্যান করুন',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   padding: EdgeInsets.symmetric(vertical: 18),
//                   backgroundColor: Color(0xFFFF4500),
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 4,
//                 ),
//               ),
//
//               SizedBox(height: 20),
//
//               // Processing Indicator
//               if (_isProcessing) ...[
//                 LinearProgressIndicator(
//                   backgroundColor: Colors.grey[300],
//                   valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
//                 ),
//                 SizedBox(height: 12),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     ),
//                     SizedBox(width: 12),
//                     Text(
//                       'প্রসেসিং... দয়া করে অপেক্ষা করুন',
//                       style: TextStyle(color: Colors.white, fontSize: 14),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 20),
//               ],
//
//               // Error Message
//               if (_errorMessage != null) ...[
//                 Card(
//                   color: Colors.red[50],
//                   elevation: 2,
//                   child: Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Row(
//                       children: [
//                         Icon(Icons.error_outline, color: Colors.red),
//                         SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             _errorMessage!,
//                             style: TextStyle(color: Colors.red),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 10),
//               ],
//
//               // Results Section
//               Expanded(
//                 child: _lastResult != null
//                     ? SingleChildScrollView(
//                   child: _buildResultCard(),
//                 )
//                     : Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.photo_camera_back,
//                         size: 54,
//                         color: Colors.white54,
//                       ),
//                       SizedBox(height: 16),
//                       Text(
//                         'স্ক্যান করার জন্য ক্যামেরা বাটন টিপুন',
//                         style: TextStyle(
//                           color: Colors.white54,
//                           fontSize: 16,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               // Instructions
//               Card(
//                 color: Color(0xFFFFF8F0),
//                 elevation: 2,
//                 child: Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Column(
//                     children: [
//                       Row(
//                         children: [
//                           Icon(Icons.info_outline, size: 16, color: Color(0xFFFF4500)),
//                           SizedBox(width: 4),
//                           Text(
//                             'নির্দেশনা:',
//                             style: TextStyle(
//                               color: Color(0xFFFF4500),
//                               fontWeight: FontWeight.bold,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         '• HB পেন্সিল ব্যবহার করুন\n• বাবল সম্পূর্ণ ভরাট করুন\n• ভুল হলে পরিষ্কার করে মুছুন\n• ভালো আলোয় স্ক্যান করুন',
//                         style: TextStyle(
//                           color: Color(0xFFFF4500),
//                           fontSize: 11,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }