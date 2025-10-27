// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:opencv_dart/opencv.dart' as cv;
// import 'package:share_plus/share_plus.dart';
//
//
// import 'omr_enhanced_service.dart';
// import 'omr_export_service.dart';
// // Import all previous services
//
//
// class OMRScannerApp extends StatefulWidget {
//   const OMRScannerApp({Key? key}) : super(key: key);
//
//   @override
//   State<OMRScannerApp> createState() => _OMRScannerAppState();
// }
//
// class _OMRScannerAppState extends State<OMRScannerApp> {
//   final EnhancedOMRScannerService _scanner = EnhancedOMRScannerService();
//   final OMRExportService _exporter = OMRExportService();
//   final ImagePicker _picker = ImagePicker();
//
//   EnhancedOMRResult? _currentResult;
//   Uint8List? _originalImage;
//   bool _isProcessing = false;
//   bool _showDebugView = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('OMR Scanner Pro'),
//         actions: [
//           if (_currentResult != null) ...[
//             IconButton(
//               icon: const Icon(Icons.bug_report),
//               onPressed: () => setState(() => _showDebugView = !_showDebugView),
//               tooltip: 'Toggle Debug View',
//             ),
//             PopupMenuButton<String>(
//               icon: const Icon(Icons.share),
//               onSelected: (format) => _shareResult(format),
//               itemBuilder: (context) => [
//                 const PopupMenuItem(value: 'json', child: Text('Share as JSON')),
//                 const PopupMenuItem(value: 'csv', child: Text('Share as CSV')),
//                 const PopupMenuItem(value: 'pdf', child: Text('Share as PDF')),
//                 const PopupMenuItem(value: 'text', child: Text('Share as Text')),
//               ],
//             ),
//           ],
//         ],
//       ),
//       body: _buildBody(),
//       floatingActionButton: _buildFAB(),
//       bottomNavigationBar: _currentResult != null ? _buildBottomBar() : null,
//     );
//   }
//
//   Widget _buildBody() {
//     if (_isProcessing) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const CircularProgressIndicator(strokeWidth: 3),
//             const SizedBox(height: 24),
//             const Text(
//               'Processing OMR Sheet...',
//               style: TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Please wait',
//               style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (_currentResult == null) {
//       return _buildEmptyState();
//     }
//
//     return _showDebugView ? _buildDebugView() : _buildResultView();
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(32),
//               decoration: BoxDecoration(
//                 color: Colors.indigo.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.document_scanner,
//                 size: 80,
//                 color: Colors.indigo[300],
//               ),
//             ),
//             const SizedBox(height: 32),
//             const Text(
//               'No OMR Sheet Scanned',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Capture or select an OMR answer sheet\nto get started with automated grading',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[600],
//                 height: 1.5,
//               ),
//             ),
//             const SizedBox(height: 40),
//             _buildFeaturesList(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFeaturesList() {
//     return Column(
//       children: [
//         _buildFeatureItem(Icons.camera_alt, 'Auto-detection of answer sheets'),
//         _buildFeatureItem(Icons.check_circle, 'Accurate bubble recognition'),
//         _buildFeatureItem(Icons.analytics, 'Confidence scoring'),
//         _buildFeatureItem(Icons.file_download, 'Export in multiple formats'),
//       ],
//     );
//   }
//
//   Widget _buildFeatureItem(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: 20, color: Colors.indigo),
//           const SizedBox(width: 12),
//           Text(text, style: const TextStyle(fontSize: 14)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildResultView() {
//     if (!_currentResult!.isValid) {
//       return _buildErrorView();
//     }
//
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           _buildImagePreview(),
//           _buildSheetTypeCard(),
//           _buildStudentInfoCard(),
//           _buildConfidenceCard(),
//           _buildAnswerSummaryCard(),
//           _buildAnswersGrid(),
//           const SizedBox(height: 100), // Space for FAB
//         ],
//       ),
//     );
//   }
//
//   Widget _buildErrorView() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, size: 80, color: Colors.red),
//             const SizedBox(height: 24),
//             const Text(
//               'Processing Failed',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               _currentResult?.errorMessage ?? 'Unknown error occurred',
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey[600]),
//             ),
//             const SizedBox(height: 32),
//             ElevatedButton.icon(
//               onPressed: () => setState(() {
//                 _currentResult = null;
//                 _originalImage = null;
//               }),
//               icon: const Icon(Icons.refresh),
//               label: const Text('Try Again'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildImagePreview() {
//     return Container(
//       height: 200,
//       width: double.infinity,
//       color: Colors.grey[100],
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
//             top: 12,
//             right: 12,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.black87,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.refresh, color: Colors.white),
//                     onPressed: _reprocessImage,
//                     tooltip: 'Reprocess',
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.fullscreen, color: Colors.white),
//                     onPressed: _showFullImage,
//                     tooltip: 'View Full',
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
//   Widget _buildSheetTypeCard() {
//     return Card(
//       margin: const EdgeInsets.all(16),
//       elevation: 2,
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: Colors.indigo.withOpacity(0.1),
//           child: const Icon(Icons.description, color: Colors.indigo),
//         ),
//         title: const Text('Sheet Type'),
//         subtitle: Text(
//           _currentResult!.detectedSheetType.toString().split('.').last,
//           style: const TextStyle(fontWeight: FontWeight.w600),
//         ),
//         trailing: Chip(
//           label: Text(
//             _currentResult!.isValid ? 'Valid' : 'Invalid',
//             style: const TextStyle(fontSize: 12),
//           ),
//           backgroundColor: _currentResult!.isValid
//               ? Colors.green.withOpacity(0.2)
//               : Colors.red.withOpacity(0.2),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStudentInfoCard() {
//     final info = _currentResult!.studentInfo;
//
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Row(
//               children: [
//                 Icon(Icons.person, color: Colors.indigo, size: 20),
//                 SizedBox(width: 8),
//                 Text(
//                   'Student Information',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const Divider(height: 24),
//             _buildInfoRow('Student ID', info.studentId ?? 'Not detected',
//                 info.confidenceScores['studentId']),
//             _buildInfoRow('Roll Number', info.rollNumber ?? 'Not detected',
//                 info.confidenceScores['rollNumber']),
//             _buildInfoRow('Mobile', info.mobileNumber ?? 'Not detected',
//                 info.confidenceScores['mobileNumber']),
//             _buildInfoRow('Set Number', info.setNumber ?? 'Not detected',
//                 info.confidenceScores['setNumber']),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value, double? confidence) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 110,
//             child: Text(
//               '$label:',
//               style: TextStyle(
//                 color: Colors.grey[700],
//                 fontSize: 14,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//           if (confidence != null && confidence > 0)
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: _getConfidenceColor(confidence).withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 '${(confidence * 100).toStringAsFixed(0)}%',
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: _getConfidenceColor(confidence),
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildConfidenceCard() {
//     final confidence = _currentResult!.overallConfidence;
//
//     return Card(
//       margin: const EdgeInsets.all(16),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Overall Confidence',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   '${(confidence * 100).toStringAsFixed(1)}%',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: _getConfidenceColor(confidence),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             LinearProgressIndicator(
//               value: confidence,
//               backgroundColor: Colors.grey[200],
//               valueColor: AlwaysStoppedAnimation(_getConfidenceColor(confidence)),
//               minHeight: 8,
//             ),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   _getConfidenceLabel(confidence),
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 if (_currentResult!.lowConfidenceQuestions.isNotEmpty)
//                   Text(
//                     '${_currentResult!.lowConfidenceQuestions.length} low conf.',
//                     style: const TextStyle(
//                       fontSize: 12,
//                       color: Colors.orange,
//                     ),
//                   ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAnswerSummaryCard() {
//     final total = _currentResult!.answers.length;
//     final answered = _currentResult!.answers
//         .where((a) => a.selectedOption != null)
//         .length;
//     final unanswered = _currentResult!.unansweredQuestions.length;
//     final multiple = _currentResult!.multipleMarkedQuestions.length;
//
//     return Card(
//       margin: const EdgeInsets.all(16),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Row(
//               children: [
//                 Icon(Icons.analytics, color: Colors.indigo, size: 20),
//                 SizedBox(width: 8),
//                 Text(
//                   'Answer Summary',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildSummaryItem(
//                     'Total',
//                     total.toString(),
//                     Colors.blue,
//                     Icons.help_outline,
//                   ),
//                 ),
//                 Expanded(
//                   child: _buildSummaryItem(
//                     'Answered',
//                     answered.toString(),
//                     Colors.green,
//                     Icons.check_circle,
//                   ),
//                 ),
//                 Expanded(
//                   child: _buildSummaryItem(
//                     'Blank',
//                     unanswered.toString(),
//                     Colors.orange,
//                     Icons.radio_button_unchecked,
//                   ),
//                 ),
//                 Expanded(
//                   child: _buildSummaryItem(
//                     'Multiple',
//                     multiple.toString(),
//                     Colors.red,
//                     Icons.warning,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, color: color, size: 24),
//         ),
//         const SizedBox(height: 8),
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
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Row(
//               children: [
//                 Icon(Icons.grid_on, color: Colors.indigo, size: 20),
//                 SizedBox(width: 8),
//                 Text(
//                   'Detected Answers',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             GridView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 5,
//                 childAspectRatio: 1.2,
//                 crossAxisSpacing: 8,
//                 mainAxisSpacing: 8,
//               ),
//               itemCount: _currentResult!.answers.length,
//               itemBuilder: (context, index) {
//                 final answer = _currentResult!.answers[index];
//                 return _buildAnswerChip(answer);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAnswerChip(EnhancedAnswer answer) {
//     Color backgroundColor;
//     Color textColor;
//     String displayText;
//     IconData? icon;
//
//     if (answer.isMultipleMarked) {
//       backgroundColor = Colors.red[100]!;
//       textColor = Colors.red[900]!;
//       displayText = '✕';
//       icon = Icons.warning_amber;
//     } else if (answer.selectedOption == null) {
//       backgroundColor = Colors.orange[100]!;
//       textColor = Colors.orange[900]!;
//       displayText = '—';
//       icon = Icons.help_outline;
//     } else if (answer.confidence < 0.7) {
//       backgroundColor = Colors.yellow[100]!;
//       textColor = Colors.orange[900]!;
//       displayText = answer.selectedOption!;
//       icon = Icons.error_outline;
//     } else {
//       backgroundColor = Colors.green[100]!;
//       textColor = Colors.green[900]!;
//       displayText = answer.selectedOption!;
//     }
//
//     return InkWell(
//       onTap: () => _showAnswerDetail(answer),
//       child: Container(
//         decoration: BoxDecoration(
//           color: backgroundColor,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: textColor.withOpacity(0.3),
//             width: 1.5,
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               '${answer.questionNumber}',
//               style: TextStyle(
//                 fontSize: 10,
//                 color: textColor.withOpacity(0.6),
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 2),
//             if (icon != null)
//               Icon(icon, size: 12, color: textColor.withOpacity(0.7)),
//             Text(
//               displayText,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: textColor,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDebugView() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Debug Information',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 16),
//           _buildDebugCard('Diagnostics', _currentResult!.diagnostics),
//           if (_currentResult!.debugImage != null) ...[
//             const SizedBox(height: 16),
//             const Text(
//               'Debug Visualization',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Image.memory(
//               Uint8List.fromList(
//                 cv.imencode('.png', _currentResult!.debugImage!).$2,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDebugCard(String title, Map<String, dynamic> data) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const Divider(height: 20),
//             ...data.entries.map((entry) => Padding(
//               padding: const EdgeInsets.symmetric(vertical: 4),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   SizedBox(
//                     width: 150,
//                     child: Text(
//                       '${entry.key}:',
//                       style: TextStyle(color: Colors.grey[700]),
//                     ),
//                   ),
//                   Expanded(
//                     child: Text(
//                       entry.value.toString(),
//                       style: const TextStyle(fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ],
//               ),
//             )),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBottomBar() {
//     return BottomAppBar(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 8),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             TextButton.icon(
//               onPressed: () => _showAnswersList(),
//               icon: const Icon(Icons.list),
//               label: const Text('View List'),
//             ),
//             TextButton.icon(
//               onPressed: () => _showStatistics(),
//               icon: const Icon(Icons.bar_chart),
//               label: const Text('Statistics'),
//             ),
//             TextButton.icon(
//               onPressed: () => _showTextSummary(),
//               icon: const Icon(Icons.text_snippet),
//               label: const Text('Summary'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFAB() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         if (_currentResult != null)
//           FloatingActionButton(
//             heroTag: 'clear',
//             onPressed: () => setState(() {
//               _currentResult = null;
//               _originalImage = null;
//               _showDebugView = false;
//             }),
//             backgroundColor: Colors.red,
//             child: const Icon(Icons.clear),
//           ),
//         const SizedBox(height: 16),
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
//   // Helper methods
//   Color _getConfidenceColor(double confidence) {
//     if (confidence >= 0.8) return Colors.green;
//     if (confidence >= 0.6) return Colors.orange;
//     return Colors.red;
//   }
//
//   String _getConfidenceLabel(double confidence) {
//     if (confidence >= 0.8) return 'Excellent';
//     if (confidence >= 0.6) return 'Good';
//     if (confidence >= 0.4) return 'Fair';
//     return 'Poor';
//   }
//
//   // Action methods
//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: source,
//         imageQuality: 90,
//       );
//
//       if (image == null) return;
//
//       final bytes = await image.readAsBytes();
//
//       setState(() {
//         _originalImage = bytes;
//         _isProcessing = true;
//         _showDebugView = false;
//       });
//
//       await _processImage(bytes);
//     } catch (e) {
//       _showSnackBar('Failed to pick image: $e', isError: true);
//       setState(() => _isProcessing = false);
//     }
//   }
//
//   Future<void> _processImage(Uint8List imageBytes) async {
//     try {
//       final result = await _scanner.processOMRSheet(imageBytes);
//
//       setState(() {
//         _currentResult = result;
//         _isProcessing = false;
//       });
//
//       if (!result.isValid) {
//         _showSnackBar(
//           result.errorMessage ?? 'Processing failed',
//           isError: true,
//         );
//       } else {
//         _showSnackBar(
//           'OMR processed successfully! Confidence: ${(result.overallConfidence * 100).toStringAsFixed(1)}%',
//         );
//       }
//     } catch (e) {
//       setState(() => _isProcessing = false);
//       _showSnackBar('Error: $e', isError: true);
//     }
//   }
//
//   Future<void> _reprocessImage() async {
//     if (_originalImage == null) return;
//
//     setState(() => _isProcessing = true);
//     await _processImage(_originalImage!);
//   }
//
//   void _showFullImage() {
//     if (_originalImage == null) return;
//
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             AppBar(
//               title: const Text('Original Image'),
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
//                 child: Image.memory(_originalImage!),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showAnswerDetail(EnhancedAnswer answer) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Question ${answer.questionNumber}'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildDetailRow('Selected Answer', answer.selectedOption ?? 'None'),
//             _buildDetailRow('Confidence',
//                 '${(answer.confidence * 100).toStringAsFixed(1)}%'),
//             _buildDetailRow('Status',
//                 answer.isMultipleMarked ? 'Multiple Marked' :
//                 answer.selectedOption == null ? 'Unanswered' : 'Answered'),
//             if (answer.detectedOptions.isNotEmpty)
//               _buildDetailRow('Detected Options',
//                   answer.detectedOptions.join(', ')),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               '$label:',
//               style: const TextStyle(fontWeight: FontWeight.w600),
//             ),
//           ),
//           Expanded(child: Text(value)),
//         ],
//       ),
//     );
//   }
//
//   void _showAnswersList() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) => DraggableScrollableSheet(
//         initialChildSize: 0.7,
//         maxChildSize: 0.95,
//         minChildSize: 0.5,
//         expand: false,
//         builder: (context, scrollController) => Column(
//           children: [
//             AppBar(
//               title: const Text('All Answers'),
//               automaticallyImplyLeading: false,
//               actions: [
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ],
//             ),
//             Expanded(
//               child: ListView.builder(
//                 controller: scrollController,
//                 itemCount: _currentResult!.answers.length,
//                 itemBuilder: (context, index) {
//                   final answer = _currentResult!.answers[index];
//                   return ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: answer.isMultipleMarked
//                           ? Colors.red
//                           : answer.selectedOption == null
//                           ? Colors.orange
//                           : Colors.green,
//                       child: Text(
//                         '${answer.questionNumber}',
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                     ),
//                     title: Text(
//                       'Answer: ${answer.selectedOption ?? "Not answered"}',
//                     ),
//                     subtitle: Text(
//                       'Confidence: ${(answer.confidence * 100).toStringAsFixed(0)}%',
//                     ),
//                     trailing: answer.isMultipleMarked
//                         ? const Icon(Icons.warning, color: Colors.red)
//                         : null,
//                     onTap: () => _showAnswerDetail(answer),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showStatistics() {
//     final answered = _currentResult!.answers
//         .where((a) => a.selectedOption != null)
//         .length;
//     final total = _currentResult!.answers.length;
//     final percentage = (answered / total * 100).toStringAsFixed(1);
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Statistics'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildStatRow('Completion Rate', '$percentage%'),
//               _buildStatRow('Total Questions', total.toString()),
//               _buildStatRow('Answered', answered.toString()),
//               _buildStatRow('Unanswered',
//                   _currentResult!.unansweredQuestions.length.toString()),
//               _buildStatRow('Multiple Marked',
//                   _currentResult!.multipleMarkedQuestions.length.toString()),
//               _buildStatRow('Low Confidence',
//                   _currentResult!.lowConfidenceQuestions.length.toString()),
//               _buildStatRow('Avg. Confidence',
//                   '${(_currentResult!.overallConfidence * 100).toStringAsFixed(1)}%'),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
//           Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }
//
//   void _showTextSummary() {
//     final summary = _exporter.generateTextSummary(_currentResult!);
//
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         child: Column(
//           children: [
//             AppBar(
//               title: const Text('Text Summary'),
//               automaticallyImplyLeading: false,
//               actions: [
//                 IconButton(
//                   icon: const Icon(Icons.share),
//                   onPressed: () {
//                     Navigator.pop(context);
//                     Share.share(summary);
//                   },
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ],
//             ),
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: SelectableText(
//                   summary,
//                   style: const TextStyle(
//                     fontFamily: 'monospace',
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _shareResult(String format) async {
//     try {
//       _showSnackBar('Preparing $format export...');
//
//       if (format == 'text') {
//         final summary = _exporter.generateTextSummary(_currentResult!);
//         await Share.share(summary, subject: 'OMR Scan Results');
//       } else {
//         await _exporter.shareResults(_currentResult!, format);
//       }
//
//       _showSnackBar('Shared successfully!');
//     } catch (e) {
//       _showSnackBar('Failed to share: $e', isError: true);
//     }
//   }
//
//   void _showSnackBar(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         behavior: SnackBarBehavior.floating,
//         duration: Duration(seconds: isError ? 4 : 2),
//       ),
//     );
//   }
// }