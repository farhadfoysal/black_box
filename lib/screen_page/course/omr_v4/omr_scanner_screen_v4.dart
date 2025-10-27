// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:typed_data';
// import 'package:opencv_dart/opencv_dart.dart' as cv;
// import 'omr_scanner_service_v4.dart';
//
// // Import the OMRScannerService from the previous file
//
// class OMRScannerScreen extends StatefulWidget {
//   const OMRScannerScreen({Key? key}) : super(key: key);
//
//   @override
//   State<OMRScannerScreen> createState() => _OMRScannerScreenState();
// }
//
// class _OMRScannerScreenState extends State<OMRScannerScreen> {
//   final OMRScannerService _scannerService = OMRScannerService();
//   final ImagePicker _picker = ImagePicker();
//
//   OMRResult? _result;
//   Uint8List? _originalImage;
//   Uint8List? _processedImage;
//   bool _isProcessing = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('OMR Scanner'),
//         backgroundColor: Colors.indigo,
//         elevation: 0,
//       ),
//       body: _buildBody(),
//       floatingActionButton: _buildFABs(),
//     );
//   }
//
//   Widget _buildBody() {
//     if (_isProcessing) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Processing OMR Sheet...'),
//           ],
//         ),
//       );
//     }
//
//     if (_result == null) {
//       return _buildEmptyState();
//     }
//
//     return _buildResultView();
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.document_scanner,
//             size: 100,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 24),
//           Text(
//             'No OMR Sheet Scanned',
//             style: TextStyle(
//               fontSize: 20,
//               color: Colors.grey[600],
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Tap the camera or gallery button to get started',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildResultView() {
//     if (_result == null || !_result!.isValid) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, size: 60, color: Colors.red),
//             const SizedBox(height: 16),
//             Text(
//               'Error: ${_result?.errorMessage ?? "Unknown error"}',
//               style: const TextStyle(color: Colors.red),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }
//
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           _buildImagePreview(),
//           _buildStudentInfoCard(),
//           _buildAnswerSummaryCard(),
//           _buildAnswersGrid(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildImagePreview() {
//     return Container(
//       height: 250,
//       color: Colors.grey[200],
//       child: _originalImage != null
//           ? Stack(
//         children: [
//           Center(
//             child: Image.memory(
//               _originalImage!,
//               fit: BoxFit.contain,
//             ),
//           ),
//           Positioned(
//             top: 8,
//             right: 8,
//             child: Container(
//               padding: const EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 color: Colors.black54,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.refresh, color: Colors.white),
//                     onPressed: _processCurrentImage,
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.visibility, color: Colors.white),
//                     onPressed: _showProcessedImage,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       )
//           : const Center(child: Icon(Icons.image, size: 60)),
//     );
//   }
//
//   Widget _buildStudentInfoCard() {
//     final info = _result!.studentInfo;
//
//     return Card(
//       margin: const EdgeInsets.all(16),
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Row(
//               children: [
//                 Icon(Icons.person, color: Colors.indigo),
//                 SizedBox(width: 8),
//                 Text(
//                   'Student Information',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const Divider(height: 24),
//             _buildInfoRow('Student ID', info.studentId ?? 'Not detected'),
//             _buildInfoRow('Roll Number', info.rollNumber ?? 'Not detected'),
//             _buildInfoRow('Mobile', info.mobileNumber ?? 'Not detected'),
//             _buildInfoRow('Set Number', info.setNumber ?? 'Not detected'),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               '$label:',
//               style: TextStyle(
//                 color: Colors.grey[700],
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAnswerSummaryCard() {
//     final totalQuestions = _result!.answers.length;
//     final answered = _result!.answers
//         .where((a) => a.selectedOption != null)
//         .length;
//     final unanswered = _result!.unansweredQuestions.length;
//     final multipleMarked = _result!.multipleMarkedQuestions.length;
//
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Row(
//               children: [
//                 Icon(Icons.analytics, color: Colors.indigo),
//                 SizedBox(width: 8),
//                 Text(
//                   'Answer Summary',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const Divider(height: 24),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildSummaryItem(
//                   'Total',
//                   totalQuestions.toString(),
//                   Colors.blue,
//                 ),
//                 _buildSummaryItem(
//                   'Answered',
//                   answered.toString(),
//                   Colors.green,
//                 ),
//                 _buildSummaryItem(
//                   'Unanswered',
//                   unanswered.toString(),
//                   Colors.orange,
//                 ),
//                 _buildSummaryItem(
//                   'Multiple',
//                   multipleMarked.toString(),
//                   Colors.red,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSummaryItem(String label, String value, Color color) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[600],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildAnswersGrid() {
//     return Card(
//       margin: const EdgeInsets.all(16),
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Row(
//               children: [
//                 Icon(Icons.check_circle_outline, color: Colors.indigo),
//                 SizedBox(width: 8),
//                 Text(
//                   'Detected Answers',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const Divider(height: 24),
//             GridView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 5,
//                 childAspectRatio: 1.5,
//                 crossAxisSpacing: 8,
//                 mainAxisSpacing: 8,
//               ),
//               itemCount: _result!.answers.length,
//               itemBuilder: (context, index) {
//                 final answer = _result!.answers[index];
//                 return _buildAnswerChip(answer);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAnswerChip(Answer answer) {
//     Color backgroundColor;
//     Color textColor;
//     String displayText;
//
//     if (answer.isMultipleMarked) {
//       backgroundColor = Colors.red[100]!;
//       textColor = Colors.red[900]!;
//       displayText = '✕';
//     } else if (answer.selectedOption == null) {
//       backgroundColor = Colors.orange[100]!;
//       textColor = Colors.orange[900]!;
//       displayText = '—';
//     } else {
//       backgroundColor = Colors.green[100]!;
//       textColor = Colors.green[900]!;
//       displayText = answer.selectedOption!;
//     }
//
//     return Container(
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: textColor.withOpacity(0.3)),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             '${answer.questionNumber}',
//             style: TextStyle(
//               fontSize: 10,
//               color: textColor.withOpacity(0.7),
//             ),
//           ),
//           Text(
//             displayText,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: textColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFABs() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         FloatingActionButton(
//           heroTag: 'camera',
//           onPressed: () => _pickImage(ImageSource.camera),
//           backgroundColor: Colors.indigo,
//           child: const Icon(Icons.camera_alt),
//         ),
//         const SizedBox(height: 16),
//         FloatingActionButton(
//           heroTag: 'gallery',
//           onPressed: () => _pickImage(ImageSource.gallery),
//           backgroundColor: Colors.indigo,
//           child: const Icon(Icons.photo_library),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final XFile? image = await _picker.pickImage(source: source);
//       if (image == null) return;
//
//       final bytes = await image.readAsBytes();
//       setState(() {
//         _originalImage = bytes;
//         _isProcessing = true;
//       });
//
//       await _processImage(bytes);
//     } catch (e) {
//       _showError('Failed to pick image: $e');
//     }
//   }
//
//   Future<void> _processImage(Uint8List imageBytes) async {
//     try {
//       final result = await _scannerService.processOMRSheet(imageBytes);
//
//       setState(() {
//         _result = result;
//         _isProcessing = false;
//       });
//
//       if (!result.isValid) {
//         _showError(result.errorMessage ?? 'Processing failed');
//       }
//     } catch (e) {
//       setState(() {
//         _isProcessing = false;
//       });
//       _showError('Error processing OMR: $e');
//     }
//   }
//
//   Future<void> _processCurrentImage() async {
//     if (_originalImage == null) return;
//
//     setState(() {
//       _isProcessing = true;
//     });
//
//     await _processImage(_originalImage!);
//   }
//
//   void _showProcessedImage() {
//     if (_result?.processedImage == null) return;
//
//     final processedBytes = cv.imencode('.png', _result!.processedImage!);
//
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             AppBar(
//               title: const Text('Processed Image'),
//               automaticallyImplyLeading: false,
//               actions: [
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ],
//             ),
//             Flexible(
//               child: InteractiveViewer(
//                 child: Image.memory(Uint8List.fromList(processedBytes.$2)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 4),
//       ),
//     );
//   }
// }