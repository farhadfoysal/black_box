import 'package:flutter/material.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../omr_v3/omr_model.dart';
import '../omr_v3/professional_omr_generator.dart';
import '../omr_v3/professional_omr_scanner.dart';
import 'omr_generator.dart';
// import 'omr_models.dart';
import 'omr_scanner.dart';


class OMRHomePage extends StatefulWidget {
  const OMRHomePage({super.key});

  @override
  State<OMRHomePage> createState() => _OMRHomePageState();
}

class _OMRHomePageState extends State<OMRHomePage> {
  int _currentIndex = 0;

  final OMRExamConfig sampleConfig = OMRExamConfig(
    examName: 'বি এ এফ শাহীন কলেজ যশোর',
    numberOfQuestions: 50,
    setNumber: 2,
    studentId: '2023001234',
    mobileNumber: '01712345678',
    examDate: DateTime.now(),
    correctAnswers: List.generate(50, (index) => ['A', 'B', 'C', 'D'][index % 4]),
    studentName: 'জন ডো',
    className: 'গ্রেড ১২ - সায়েন্স',
    subjectCode: '101',
    registrationNumber: '2023456789',
    subjectName: 'পদার্থবিজ্ঞান',
    department: 'বিজ্ঞান',
    roomNumber: '২০১',
    branch: 'ক',
  );

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      // ProfessionalOMRGenerator(config: _createConfig()),
      ProfessionalOMRScanner(config: _createConfig()),
    ]);
  }

  OMRExamConfig _createConfig() {
    return OMRExamConfig(
      examName: 'বি এ এফ শাহীন কলেজ যশোর',
      numberOfQuestions: 50,
      setNumber: 2,
      studentId: '2023001234',
      mobileNumber: '01712345678',
      examDate: DateTime.now(),
      correctAnswers: List.generate(50, (index) => ['A', 'B', 'C', 'D'][index % 4]),
      studentName: 'জন ডো',
      className: 'গ্রেড ১২ - সায়েন্স',
      subjectCode: '101',
      registrationNumber: '2023456789',
      subjectName: 'পদার্থবিজ্ঞান',
      department: 'বিজ্ঞান',
      roomNumber: '২০১',
      branch: 'ক',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF2C3E50),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'OMR Generator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.scanner),
            label: 'OMR Scanner',
          ),
        ],
      ),
    );
  }
}


// class OMRHomePage extends StatefulWidget {
//   @override
//   _OMRHomePageState createState() => _OMRHomePageState();
// }
//
// class _OMRHomePageState extends State<OMRHomePage> {
//   final _examNameController = TextEditingController(text: 'Mathematics Test');
//   final _questionsController = TextEditingController(text: '30');
//   final _setNumberController = TextEditingController(text: '1');
//   final _studentIdController = TextEditingController(text: '123456789');
//   final _mobileController = TextEditingController(text: '9876543210');
//
//   List<TextEditingController> _answerControllers = [];
//   bool _isGenerating = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeAnswerControllers();
//   }
//
//   void _initializeAnswerControllers() {
//     final questionCount = int.tryParse(_questionsController.text) ?? 30;
//     _answerControllers = List.generate(
//       questionCount,
//           (index) => TextEditingController(text: 'A'),
//     );
//   }
//
//   Future<void> _generateOMRSheet(bool isAnswerKey) async {
//     if (_examNameController.text.isEmpty) {
//       _showError('Please enter exam name');
//       return;
//     }
//
//     setState(() => _isGenerating = true);
//
//     try {
//       final config = OMRExamConfig(
//         examName: _examNameController.text,
//         numberOfQuestions: int.parse(_questionsController.text),
//         setNumber: int.parse(_setNumberController.text),
//         studentId: _studentIdController.text,
//         mobileNumber: _mobileController.text,
//         examDate: DateTime.now(),
//         correctAnswers: isAnswerKey ?
//         _answerControllers.map((c) => c.text).toList() : [],
//       );
//
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => OMRGenerator(config: config),
//         ),
//       );
//
//       // final file = await OMRGenerator.generateOMRSheet(config);
//
//       // _showPreviewDialog(file, isAnswerKey);
//     } catch (e) {
//       _showError('Failed to generate OMR sheet: $e');
//     } finally {
//       setState(() => _isGenerating = false);
//     }
//   }
//
//   void _showPreviewDialog(File file, bool isAnswerKey) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(isAnswerKey ? Icons.vpn_key : Icons.assignment, color: Colors.blue),
//             SizedBox(width: 8),
//             Text(isAnswerKey ? 'Answer Key Preview' : 'OMR Sheet Preview'),
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Image.file(file),
//               ),
//               SizedBox(height: 16),
//               Text(
//                 'Sheet generated successfully!',
//                 style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close'),
//           ),
//           TextButton(
//             onPressed: () => _saveToAppDirectory(file),
//             child: Text('Save Locally'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               _shareFile(file, isAnswerKey);
//               Navigator.pop(context);
//             },
//             child: Text('Share'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Enhanced Share File Implementation
//   Future<void> _shareFile(File file, bool isAnswerKey) async {
//     try {
//       final String subject = isAnswerKey
//           ? '${_examNameController.text} - Answer Key'
//           : '${_examNameController.text} - OMR Sheet';
//
//       final String text = isAnswerKey
//           ? 'Answer Key for ${_examNameController.text} - ${DateTime.now().toString().split(' ')[0]}'
//           : 'OMR Sheet for ${_examNameController.text} - ${DateTime.now().toString().split(' ')[0]}';
//
//       await Share.shareXFiles(
//         [XFile(file.path)],
//         subject: subject,
//         text: text,
//       );
//
//       _showSuccess('Sheet shared successfully!');
//     } catch (e) {
//       _showError('Failed to share file: $e');
//     }
//   }
//
//   // Save to app directory instead of gallery
//   Future<void> _saveToAppDirectory(File file) async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final fileName = 'omr_sheet_$timestamp.png';
//       final newPath = '${directory.path}/$fileName';
//
//       await file.copy(newPath);
//       _showSuccess('Sheet saved to app directory!\nPath: $newPath');
//     } catch (e) {
//       _showError('Failed to save file: $e');
//     }
//   }
//
//   Future<void> _saveToGallery(File file) async {
//     try {
//       await MediaScanner.loadMedia(path: file.path);
//       _showSuccess('Sheet saved to gallery!');
//     } catch (e) {
//       _showError('Failed to save to gallery: $e');
//     }
//   }
//
//   // Alternative: Save to Downloads folder (Android)
//   Future<void> _saveToDownloads(File file) async {
//     try {
//       final directory = await getExternalStorageDirectory();
//       if (directory != null) {
//         final downloadsPath = '${directory.path}/Download';
//         final downloadsDir = Directory(downloadsPath);
//         if (!await downloadsDir.exists()) {
//           await downloadsDir.create(recursive: true);
//         }
//
//         final timestamp = DateTime.now().millisecondsSinceEpoch;
//         final fileName = 'omr_sheet_$timestamp.png';
//         final newPath = '$downloadsPath/$fileName';
//
//         await file.copy(newPath);
//         _showSuccess('Sheet saved to Downloads folder!');
//       }
//     } catch (e) {
//       _showError('Failed to save to Downloads: $e');
//     }
//   }
//
//   void _navigateToScanner() {
//     final config = OMRExamConfig(
//       examName: _examNameController.text,
//       numberOfQuestions: int.parse(_questionsController.text),
//       setNumber: int.parse(_setNumberController.text),
//       studentId: _studentIdController.text,
//       mobileNumber: _mobileController.text,
//       examDate: DateTime.now(),
//       correctAnswers: _answerControllers.map((c) => c.text).toList(),
//     );
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => OMRScanner(examConfig: config),
//       ),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.error, color: Colors.white),
//             SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   void _showSuccess(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.check_circle, color: Colors.white),
//             SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('OMR System'),
//         backgroundColor: Colors.blue[800],
//         elevation: 2,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Exam Information Card
//               Card(
//                 elevation: 2,
//                 child: Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Exam Information',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue[800],
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       TextField(
//                         controller: _examNameController,
//                         decoration: InputDecoration(
//                           labelText: 'Exam Name',
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(Icons.assignment),
//                         ),
//                       ),
//                       SizedBox(height: 12),
//                       TextField(
//                         controller: _questionsController,
//                         decoration: InputDecoration(
//                           labelText: 'Number of Questions',
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(Icons.format_list_numbered),
//                         ),
//                         keyboardType: TextInputType.number,
//                         onChanged: (value) {
//                           final count = int.tryParse(value) ?? 30;
//                           setState(() {
//                             _answerControllers = List.generate(
//                               count,
//                                   (index) => index < _answerControllers.length ?
//                               _answerControllers[index] :
//                               TextEditingController(text: 'A'),
//                             );
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: 16),
//
//               // Student Information Card
//               Card(
//                 elevation: 2,
//                 child: Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Student Information',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue[800],
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextField(
//                               controller: _setNumberController,
//                               decoration: InputDecoration(
//                                 labelText: 'Set Number (0-9)',
//                                 border: OutlineInputBorder(),
//                               ),
//                               keyboardType: TextInputType.number,
//                             ),
//                           ),
//                           SizedBox(width: 12),
//                           Expanded(
//                             child: TextField(
//                               controller: _studentIdController,
//                               decoration: InputDecoration(
//                                 labelText: 'Student ID (9 digits)',
//                                 border: OutlineInputBorder(),
//                               ),
//                               keyboardType: TextInputType.number,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 12),
//                       TextField(
//                         controller: _mobileController,
//                         decoration: InputDecoration(
//                           labelText: 'Mobile Number (11 digits)',
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(Icons.phone),
//                         ),
//                         keyboardType: TextInputType.phone,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: 16),
//
//               // Answer Key Configuration Card
//               Card(
//                 elevation: 2,
//                 child: Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Answer Key Configuration',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue[800],
//                         ),
//                       ),
//                       SizedBox(height: 12),
//                       Text(
//                         'Set correct answers for answer key generation:',
//                         style: TextStyle(color: Colors.grey[600]),
//                       ),
//                       SizedBox(height: 16),
//                       Container(
//                         height: 200,
//                         child: GridView.builder(
//                           shrinkWrap: true,
//                           physics: NeverScrollableScrollPhysics(),
//                           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 5,
//                             crossAxisSpacing: 8.0,
//                             mainAxisSpacing: 8.0,
//                             childAspectRatio: 1.2,
//                           ),
//                           itemCount: _answerControllers.length,
//                           itemBuilder: (context, index) {
//                             return Container(
//                               decoration: BoxDecoration(
//                                 border: Border.all(color: Colors.grey[300]!),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     'Q${index + 1}',
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   SizedBox(height: 4),
//                                   DropdownButton<String>(
//                                     value: _answerControllers[index].text,
//                                     items: ['A', 'B', 'C', 'D', 'E']
//                                         .map((option) => DropdownMenuItem(
//                                       value: option,
//                                       child: Text(
//                                         option,
//                                         style: TextStyle(fontSize: 14),
//                                       ),
//                                     ))
//                                         .toList(),
//                                     onChanged: (value) {
//                                       setState(() {
//                                         _answerControllers[index].text = value!;
//                                       });
//                                     },
//                                     underline: Container(),
//                                     isDense: true,
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: 20),
//
//               // Action Buttons
//               if (_isGenerating) ...[
//                 Center(
//                   child: Column(
//                     children: [
//                       CircularProgressIndicator(),
//                       SizedBox(height: 16),
//                       Text('Generating OMR Sheet...'),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 16),
//               ],
//
//               Wrap(
//                 spacing: 12,
//                 runSpacing: 12,
//                 alignment: WrapAlignment.spaceEvenly,
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: _isGenerating ? null : () => _generateOMRSheet(false),
//                     icon: Icon(Icons.picture_as_pdf),
//                     label: Text('Generate OMR'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue[800],
//                       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: _isGenerating ? null : () => _generateOMRSheet(true),
//                     icon: Icon(Icons.vpn_key),
//                     label: Text('Answer Key'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: _navigateToScanner,
//                     icon: Icon(Icons.camera_alt),
//                     label: Text('Scan'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.purple,
//                       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     ),
//                   ),
//                 ],
//               ),
//
//               // File Management Section
//               SizedBox(height: 20),
//               Card(
//                 elevation: 2,
//                 child: Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'File Management',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue[800],
//                         ),
//                       ),
//                       SizedBox(height: 12),
//                       Text(
//                         'Generated sheets are saved in the app\'s document directory. '
//                             'Use the Share button to send sheets to other apps or save them to your preferred location.',
//                         style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
//
//   @override
//   void dispose() {
//     _examNameController.dispose();
//     _questionsController.dispose();
//     _setNumberController.dispose();
//     _studentIdController.dispose();
//     _mobileController.dispose();
//     for (var controller in _answerControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
// import 'dart:io';
// import 'omr_models.dart';
// import 'omr_generator.dart';
// import 'omr_scanner.dart';
//
// class OMRHomePage extends StatefulWidget {
//   @override
//   _OMRHomePageState createState() => _OMRHomePageState();
// }
//
// class _OMRHomePageState extends State<OMRHomePage> {
//   final _examNameController = TextEditingController(text: 'Mathematics Test');
//   final _questionsController = TextEditingController(text: '30');
//   final _setNumberController = TextEditingController(text: '1');
//   final _studentIdController = TextEditingController(text: '123456789');
//   final _mobileController = TextEditingController(text: '9876543210');
//
//   List<TextEditingController> _answerControllers = [];
//   bool _isGenerating = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeAnswerControllers();
//   }
//
//   void _initializeAnswerControllers() {
//     final questionCount = int.tryParse(_questionsController.text) ?? 30;
//     _answerControllers = List.generate(
//       questionCount,
//           (index) => TextEditingController(text: 'A'),
//     );
//   }
//
//   Future<void> _generateOMRSheet(bool isAnswerKey) async {
//     if (_examNameController.text.isEmpty) {
//       _showError('Please enter exam name');
//       return;
//     }
//
//     setState(() => _isGenerating = true);
//
//     try {
//       final config = OMRExamConfig(
//         examName: _examNameController.text,
//         numberOfQuestions: int.parse(_questionsController.text),
//         setNumber: int.parse(_setNumberController.text),
//         studentId: _studentIdController.text,
//         mobileNumber: _mobileController.text,
//         examDate: DateTime.now(),
//         correctAnswers: isAnswerKey ?
//         _answerControllers.map((c) => c.text).toList() : [],
//       );
//
//       final file = await OMRGenerator.generateOMRSheet(config);
//
//       // Show preview with enhanced options
//       _showPreviewDialog(file, isAnswerKey);
//     } catch (e) {
//       _showError('Failed to generate OMR sheet: $e');
//     } finally {
//       setState(() => _isGenerating = false);
//     }
//   }
//
//   void _showPreviewDialog(File file, bool isAnswerKey) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(isAnswerKey ? Icons.vpn_key : Icons.assignment, color: Colors.blue),
//             SizedBox(width: 8),
//             Text(isAnswerKey ? 'Answer Key Preview' : 'OMR Sheet Preview'),
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Image.file(file),
//               ),
//               SizedBox(height: 16),
//               Text(
//                 'Sheet generated successfully!',
//                 style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close'),
//           ),
//           TextButton(
//             onPressed: () => _saveToGallery(file),
//             child: Text('Save to Gallery'),
//           ),
//           ElevatedButton(
//             onPressed: () => _shareFile(file, isAnswerKey),
//             child: Text('Share'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Enhanced Share File Implementation
//   Future<void> _shareFile(File file, bool isAnswerKey) async {
//     try {
//       final String subject = isAnswerKey
//           ? '${_examNameController.text} - Answer Key'
//           : '${_examNameController.text} - OMR Sheet';
//
//       final String text = isAnswerKey
//           ? 'Answer Key for ${_examNameController.text} - ${DateTime.now().toString().split(' ')[0]}'
//           : 'OMR Sheet for ${_examNameController.text} - ${DateTime.now().toString().split(' ')[0]}';
//
//       // Share the file using share_plus
//       await Share.shareXFiles(
//         [XFile(file.path)],
//         subject: subject,
//         text: text,
//         sharePositionOrigin: Rect.fromPoints(
//           Offset.zero,
//           Offset(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
//         ),
//       );
//
//       _showSuccess('Sheet shared successfully!');
//     } catch (e) {
//       _showError('Failed to share file: $e');
//     }
//   }
//
//   // Save to device gallery
//   Future<void> _saveToGallery(File file) async {
//     try {
//       final result = await ImageGallerySaver.saveFile(file.path);
//
//       if (result['isSuccess']) {
//         _showSuccess('Sheet saved to gallery successfully!');
//       } else {
//         _showError('Failed to save to gallery');
//       }
//     } catch (e) {
//       _showError('Failed to save to gallery: $e');
//     }
//   }
//
//   // Share multiple files (for batch operations)
//   Future<void> _shareMultipleFiles(List<File> files, bool isAnswerKey) async {
//     try {
//       final xFiles = files.map((file) => XFile(file.path)).toList();
//
//       final String subject = isAnswerKey
//           ? '${_examNameController.text} - Multiple Answer Keys'
//           : '${_examNameController.text} - Multiple OMR Sheets';
//
//       await Share.shareXFiles(
//         xFiles,
//         subject: subject,
//         text: '${files.length} ${isAnswerKey ? 'answer keys' : 'OMR sheets'} for ${_examNameController.text}',
//       );
//
//       _showSuccess('${files.length} sheets shared successfully!');
//     } catch (e) {
//       _showError('Failed to share files: $e');
//     }
//   }
//
//   // Generate and share multiple OMR sheets with different set numbers
//   Future<void> _generateAndShareMultipleSheets() async {
//     setState(() => _isGenerating = true);
//
//     try {
//       final List<File> files = [];
//
//       // Generate sheets for set numbers 1-5
//       for (int setNumber = 1; setNumber <= 5; setNumber++) {
//         final config = OMRExamConfig(
//           examName: _examNameController.text,
//           numberOfQuestions: int.parse(_questionsController.text),
//           setNumber: setNumber,
//           studentId: _studentIdController.text,
//           mobileNumber: _mobileController.text,
//           examDate: DateTime.now(),
//           correctAnswers: [],
//         );
//
//         final file = await OMRGenerator.generateOMRSheet(config);
//         files.add(file);
//       }
//
//       // Share all files at once
//       await _shareMultipleFiles(files, false);
//
//     } catch (e) {
//       _showError('Failed to generate multiple sheets: $e');
//     } finally {
//       setState(() => _isGenerating = false);
//     }
//   }
//
//   void _navigateToScanner() {
//     final config = OMRExamConfig(
//       examName: _examNameController.text,
//       numberOfQuestions: int.parse(_questionsController.text),
//       setNumber: int.parse(_setNumberController.text),
//       studentId: _studentIdController.text,
//       mobileNumber: _mobileController.text,
//       examDate: DateTime.now(),
//       correctAnswers: _answerControllers.map((c) => c.text).toList(),
//     );
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => OMRScanner(examConfig: config),
//       ),
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.error, color: Colors.white),
//             SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   void _showSuccess(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.check_circle, color: Colors.white),
//             SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('OMR System'),
//         backgroundColor: Colors.blue[800],
//         elevation: 2,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Exam Information Card
//               Card(
//                 elevation: 2,
//                 child: Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Exam Information',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue[800],
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       TextField(
//                         controller: _examNameController,
//                         decoration: InputDecoration(
//                           labelText: 'Exam Name',
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(Icons.assignment),
//                         ),
//                       ),
//                       SizedBox(height: 12),
//                       TextField(
//                         controller: _questionsController,
//                         decoration: InputDecoration(
//                           labelText: 'Number of Questions',
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(Icons.format_list_numbered),
//                         ),
//                         keyboardType: TextInputType.number,
//                         onChanged: (value) {
//                           final count = int.tryParse(value) ?? 30;
//                           setState(() {
//                             _answerControllers = List.generate(
//                               count,
//                                   (index) => index < _answerControllers.length ?
//                               _answerControllers[index] :
//                               TextEditingController(text: 'A'),
//                             );
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: 16),
//
//               // Student Information Card
//               Card(
//                 elevation: 2,
//                 child: Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Student Information',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue[800],
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextField(
//                               controller: _setNumberController,
//                               decoration: InputDecoration(
//                                 labelText: 'Set Number (0-9)',
//                                 border: OutlineInputBorder(),
//                               ),
//                               keyboardType: TextInputType.number,
//                             ),
//                           ),
//                           SizedBox(width: 12),
//                           Expanded(
//                             child: TextField(
//                               controller: _studentIdController,
//                               decoration: InputDecoration(
//                                 labelText: 'Student ID (9 digits)',
//                                 border: OutlineInputBorder(),
//                               ),
//                               keyboardType: TextInputType.number,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 12),
//                       TextField(
//                         controller: _mobileController,
//                         decoration: InputDecoration(
//                           labelText: 'Mobile Number (11 digits)',
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(Icons.phone),
//                         ),
//                         keyboardType: TextInputType.phone,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: 16),
//
//               // Answer Key Configuration Card
//               Card(
//                 elevation: 2,
//                 child: Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Answer Key Configuration',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue[800],
//                         ),
//                       ),
//                       SizedBox(height: 12),
//                       Text(
//                         'Set correct answers for answer key generation:',
//                         style: TextStyle(color: Colors.grey[600]),
//                       ),
//                       SizedBox(height: 16),
//                       Container(
//                         height: 200,
//                         child: GridView.builder(
//                           shrinkWrap: true,
//                           physics: NeverScrollableScrollPhysics(),
//                           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 5,
//                             crossAxisSpacing: 8.0,
//                             mainAxisSpacing: 8.0,
//                             childAspectRatio: 1.2,
//                           ),
//                           itemCount: _answerControllers.length,
//                           itemBuilder: (context, index) {
//                             return Container(
//                               decoration: BoxDecoration(
//                                 border: Border.all(color: Colors.grey[300]!),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     'Q${index + 1}',
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   SizedBox(height: 4),
//                                   DropdownButton<String>(
//                                     value: _answerControllers[index].text,
//                                     items: ['A', 'B', 'C', 'D', 'E']
//                                         .map((option) => DropdownMenuItem(
//                                       value: option,
//                                       child: Text(
//                                         option,
//                                         style: TextStyle(fontSize: 14),
//                                       ),
//                                     ))
//                                         .toList(),
//                                     onChanged: (value) {
//                                       setState(() {
//                                         _answerControllers[index].text = value!;
//                                       });
//                                     },
//                                     underline: Container(),
//                                     isDense: true,
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: 20),
//
//               // Action Buttons
//               if (_isGenerating) ...[
//                 Center(
//                   child: Column(
//                     children: [
//                       CircularProgressIndicator(),
//                       SizedBox(height: 16),
//                       Text('Generating OMR Sheet...'),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 16),
//               ],
//
//               Wrap(
//                 spacing: 12,
//                 runSpacing: 12,
//                 alignment: WrapAlignment.spaceEvenly,
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: _isGenerating ? null : () => _generateOMRSheet(false),
//                     icon: Icon(Icons.picture_as_pdf),
//                     label: Text('Generate OMR'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue[800],
//                       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: _isGenerating ? null : () => _generateOMRSheet(true),
//                     icon: Icon(Icons.vpn_key),
//                     label: Text('Answer Key'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: _isGenerating ? null : _generateAndShareMultipleSheets,
//                     icon: Icon(Icons.share),
//                     label: Text('Multiple Sets'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: _navigateToScanner,
//                     icon: Icon(Icons.camera_alt),
//                     label: Text('Scan'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.purple,
//                       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _examNameController.dispose();
//     _questionsController.dispose();
//     _setNumberController.dispose();
//     _studentIdController.dispose();
//     _mobileController.dispose();
//     for (var controller in _answerControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }
// }
//


// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'omr_models.dart';
// import 'omr_generator.dart';
// import 'omr_scanner.dart';
//
// class OMRHomePage extends StatefulWidget {
//   @override
//   _OMRHomePageState createState() => _OMRHomePageState();
// }
//
// class _OMRHomePageState extends State<OMRHomePage> {
//   final _examNameController = TextEditingController(text: 'Mathematics Test');
//   final _questionsController = TextEditingController(text: '30');
//   final _setNumberController = TextEditingController(text: '1');
//   final _studentIdController = TextEditingController(text: '123456789');
//   final _mobileController = TextEditingController(text: '9876543210');
//
//   List<TextEditingController> _answerControllers = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeAnswerControllers();
//   }
//
//   void _initializeAnswerControllers() {
//     final questionCount = int.tryParse(_questionsController.text) ?? 30;
//     _answerControllers = List.generate(
//       questionCount,
//           (index) => TextEditingController(text: 'A'),
//     );
//   }
//
//   Future<void> _generateOMRSheet(bool isAnswerKey) async {
//     final config = OMRExamConfig(
//       examName: _examNameController.text,
//       numberOfQuestions: int.parse(_questionsController.text),
//       setNumber: int.parse(_setNumberController.text),
//       studentId: _studentIdController.text,
//       mobileNumber: _mobileController.text,
//       examDate: DateTime.now(),
//       correctAnswers: isAnswerKey ?
//       _answerControllers.map((c) => c.text).toList() : [],
//     );
//
//     final file = await OMRGenerator.generateOMRSheet(config);
//
//     // Show preview
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(isAnswerKey ? 'Answer Key' : 'OMR Sheet'),
//         content: Image.file(file),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close'),
//           ),
//           TextButton(
//             onPressed: () => _shareFile(file),
//             child: Text('Share'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _shareFile(File file) {
//     // Implement file sharing logic
//     // You can use share_plus package for this
//   }
//
//   void _navigateToScanner() {
//     final config = OMRExamConfig(
//       examName: _examNameController.text,
//       numberOfQuestions: int.parse(_questionsController.text),
//       setNumber: int.parse(_setNumberController.text),
//       studentId: _studentIdController.text,
//       mobileNumber: _mobileController.text,
//       examDate: DateTime.now(),
//       correctAnswers: _answerControllers.map((c) => c.text).toList(),
//     );
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => OMRScanner(examConfig: config),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('OMR System')),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               TextField(
//                 controller: _examNameController,
//                 decoration: InputDecoration(labelText: 'Exam Name'),
//               ),
//               TextField(
//                 controller: _questionsController,
//                 decoration: InputDecoration(labelText: 'Number of Questions'),
//                 keyboardType: TextInputType.number,
//                 onChanged: (value) {
//                   final count = int.tryParse(value) ?? 30;
//                   setState(() {
//                     _answerControllers = List.generate(
//                       count,
//                           (index) => index < _answerControllers.length ?
//                       _answerControllers[index] :
//                       TextEditingController(text: 'A'),
//                     );
//                   });
//                 },
//               ),
//               TextField(
//                 controller: _setNumberController,
//                 decoration: InputDecoration(labelText: 'Set Number (0-9)'),
//                 keyboardType: TextInputType.number,
//               ),
//               TextField(
//                 controller: _studentIdController,
//                 decoration: InputDecoration(labelText: 'Student ID (9 digits)'),
//                 keyboardType: TextInputType.number,
//               ),
//               TextField(
//                 controller: _mobileController,
//                 decoration: InputDecoration(labelText: 'Mobile Number (11 digits)'),
//                 keyboardType: TextInputType.phone,
//               ),
//
//               SizedBox(height: 20),
//               Text('Correct Answers (for Answer Key):', style: TextStyle(fontWeight: FontWeight.bold)),
//
//               GridView.builder(
//                 shrinkWrap: true,
//                 physics: NeverScrollableScrollPhysics(),
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 5,
//                   crossAxisSpacing: 8.0,
//                   mainAxisSpacing: 8.0,
//                 ),
//                 itemCount: _answerControllers.length,
//                 itemBuilder: (context, index) {
//                   return Column(
//                     children: [
//                       Text('Q${index + 1}'),
//                       DropdownButtonFormField<String>(
//                         value: _answerControllers[index].text,
//                         items: ['A', 'B', 'C', 'D', 'E']
//                             .map((option) => DropdownMenuItem(
//                           value: option,
//                           child: Text(option),
//                         ))
//                             .toList(),
//                         onChanged: (value) {
//                           setState(() {
//                             _answerControllers[index].text = value!;
//                           });
//                         },
//                       ),
//                     ],
//                   );
//                 },
//               ),
//
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () => _generateOMRSheet(false),
//                 child: Text('Generate Student OMR Sheet'),
//               ),
//               ElevatedButton(
//                 onPressed: () => _generateOMRSheet(true),
//                 child: Text('Generate Answer Key'),
//               ),
//               ElevatedButton(
//                 onPressed: _navigateToScanner,
//                 child: Text('Scan OMR Sheet'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _examNameController.dispose();
//     _questionsController.dispose();
//     _setNumberController.dispose();
//     _studentIdController.dispose();
//     _mobileController.dispose();
//     for (var controller in _answerControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }
// }