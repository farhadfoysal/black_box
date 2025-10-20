import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../omr_v1/omr_generator.dart';
import '../omr_v1/omr_models.dart';
import 'omr_database_manager.dart';

class ExamManagementPage extends StatefulWidget {
  @override
  _ExamManagementPageState createState() => _ExamManagementPageState();
}

class _ExamManagementPageState extends State<ExamManagementPage> {
  final _examNameController = TextEditingController();
  final _questionsController = TextEditingController(text: '30');
  final _setNumberController = TextEditingController(text: '1');
  final _studentIdController = TextEditingController(text: '123456789');
  final _mobileController = TextEditingController(text: '9876543210');

  List<TextEditingController> _answerControllers = [];
  List<Exam> _exams = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnswerControllers();
    _loadExams();
  }

  void _initializeAnswerControllers() {
    final questionCount = int.tryParse(_questionsController.text) ?? 30;
    _answerControllers = List.generate(
      questionCount,
      (index) => TextEditingController(text: 'A'),
    );
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    try {
      _exams = await DatabaseManager.getExams();
    } catch (e) {
      _showError('Failed to load exams: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createExam() async {
    if (_examNameController.text.isEmpty) {
      _showError('Please enter exam name');
      return;
    }

    final exam = Exam(
      name: _examNameController.text,
      date: DateTime.now(),
      totalQuestions: int.parse(_questionsController.text),
      correctAnswers: _answerControllers.map((c) => c.text).toList(),
      createdAt: DateTime.now(),
    );

    try {
      await DatabaseManager.insertExam(exam);
      _examNameController.clear();
      _loadExams();
      _showSuccess('Exam created successfully!');
    } catch (e) {
      _showError('Failed to create exam: $e');
    }
  }

  Future<void> _generateOMRSheet(bool isAnswerKey, Exam? exam) async {
    if ((exam == null && _examNameController.text.isEmpty) || _isGenerating) {
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final config = OMRExamConfig(
        examName: exam?.name ?? _examNameController.text,
        numberOfQuestions:
            exam?.totalQuestions ?? int.parse(_questionsController.text),
        setNumber: int.parse(_setNumberController.text),
        studentId: _studentIdController.text,
        mobileNumber: _mobileController.text,
        examDate: exam?.date ?? DateTime.now(),
        correctAnswers: isAnswerKey
            ? (exam?.correctAnswers ??
                  _answerControllers.map((c) => c.text).toList())
            : [],
      );

      final file = await OMRGenerator.generateOMRSheet(config);
      _showPreviewDialog(file, isAnswerKey);
    } catch (e) {
      _showError('Failed to generate OMR sheet: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _showPreviewDialog(File file, bool isAnswerKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isAnswerKey ? Icons.vpn_key : Icons.assignment,
              color: Colors.blue,
            ),
            SizedBox(width: 8),
            Text(isAnswerKey ? 'Answer Key Preview' : 'OMR Sheet Preview'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.file(file),
              ),
              SizedBox(height: 16),
              Text(
                'Sheet generated successfully!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () {
              _saveToAppDirectory(file);
              Navigator.pop(context);
            },
            child: Text('Save Locally'),
          ),
          ElevatedButton(
            onPressed: () {
              _shareFile(file, isAnswerKey);
              Navigator.pop(context);
            },
            child: Text('Share'),
          ),
        ],
      ),
    );
  }

  // Enhanced Share File Implementation
  Future<void> _shareFile(File file, bool isAnswerKey) async {
    try {
      final String subject = isAnswerKey
          ? '${_examNameController.text} - Answer Key'
          : '${_examNameController.text} - OMR Sheet';

      final String text = isAnswerKey
          ? 'Answer Key for ${_examNameController.text}'
          : 'OMR Sheet for ${_examNameController.text}';

      await Share.shareXFiles([XFile(file.path)], subject: subject, text: text);

      _showSuccess('Sheet shared successfully!');
    } catch (e) {
      _showError('Failed to share file: $e');
    }
  }

  // Save to app directory instead of gallery
  Future<void> _saveToAppDirectory(File file) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'omr_${_examNameController.text.replaceAll(' ', '_')}_$timestamp.png';
      final newPath = '${directory.path}/$fileName';

      await file.copy(newPath);
      _showSuccess(
        'Sheet saved to app directory!\nYou can find it in your device\'s file manager under the app folder.',
      );
    } catch (e) {
      _showError('Failed to save file: $e');
    }
  }

  // Alternative method to save to Downloads folder (Android)
  Future<void> _saveToDownloads(File file) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final downloadsPath = '${directory.path}/Download/OMR_Sheets';
        final downloadsDir = Directory(downloadsPath);
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName =
            'omr_${_examNameController.text.replaceAll(' ', '_')}_$timestamp.png';
        final newPath = '$downloadsPath/$fileName';

        await file.copy(newPath);
        _showSuccess('Sheet saved to Downloads/OMR_Sheets folder!');
      } else {
        _saveToAppDirectory(file); // Fallback to app directory
      }
    } catch (e) {
      // Fallback to app directory if Downloads fails
      _saveToAppDirectory(file);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Exam creation form
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Create New Exam',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  TextField(
                                    controller: _examNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Exam Name',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.assignment),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  TextField(
                                    controller: _questionsController,
                                    decoration: InputDecoration(
                                      labelText: 'Number of Questions',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(
                                        Icons.format_list_numbered,
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final count = int.tryParse(value) ?? 30;
                                      setState(() {
                                        _answerControllers = List.generate(
                                          count,
                                          (index) =>
                                              index < _answerControllers.length
                                              ? _answerControllers[index]
                                              : TextEditingController(
                                                  text: 'A',
                                                ),
                                        );
                                      });
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _setNumberController,
                                          decoration: InputDecoration(
                                            labelText: 'Set Number (0-9)',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller: _studentIdController,
                                          decoration: InputDecoration(
                                            labelText: 'Student ID (9 digits)',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  TextField(
                                    controller: _mobileController,
                                    decoration: InputDecoration(
                                      labelText: 'Mobile Number (11 digits)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.phone),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Correct Answers (for Answer Key):',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 10),

                                  // Responsive Scrollable Grid with Scrollbar
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final crossAxisCount =
                                          (constraints.maxWidth ~/ 120).clamp(
                                            3,
                                            8,
                                          ); // Auto-fit columns

                                      return Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.35, // Responsive height
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Scrollbar(
                                          thumbVisibility: true,
                                          radius: Radius.circular(10),
                                          thickness: 8,
                                          interactive: true,
                                          child: GridView.builder(
                                            padding: EdgeInsets.all(8),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount:
                                                      crossAxisCount,
                                                  crossAxisSpacing: 8.0,
                                                  mainAxisSpacing: 8.0,
                                                  childAspectRatio: 1.6,
                                                ),
                                            itemCount:
                                                _answerControllers.length,
                                            itemBuilder: (context, index) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.05),
                                                      blurRadius: 2,
                                                      offset: Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Q${index + 1}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    DropdownButton<String>(
                                                      value:
                                                          _answerControllers[index]
                                                              .text,
                                                      underline: SizedBox(),
                                                      isDense: true,
                                                      items:
                                                          [
                                                                'A',
                                                                'B',
                                                                'C',
                                                                'D',
                                                                'E',
                                                              ]
                                                              .map(
                                                                (
                                                                  option,
                                                                ) => DropdownMenuItem(
                                                                  value: option,
                                                                  child: Text(
                                                                    option,
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _answerControllers[index]
                                                                  .text =
                                                              value!;
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  SizedBox(height: 20),

                                  // SizedBox(height: 20),
                                  // Text(
                                  //   'Correct Answers (for Answer Key):',
                                  //   style: TextStyle(
                                  //     fontWeight: FontWeight.bold,
                                  //     fontSize: 16,
                                  //   ),
                                  // ),
                                  // SizedBox(height: 10),
                                  // Container(
                                  //   height: 200,
                                  //   child: GridView.builder(
                                  //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  //       crossAxisCount: 5,
                                  //       crossAxisSpacing: 8.0,
                                  //       mainAxisSpacing: 8.0,
                                  //       childAspectRatio: 1.5,
                                  //     ),
                                  //     itemCount: _answerControllers.length,
                                  //     itemBuilder: (context, index) {
                                  //       return Container(
                                  //         decoration: BoxDecoration(
                                  //           border: Border.all(color: Colors.grey[300]!),
                                  //           borderRadius: BorderRadius.circular(8),
                                  //         ),
                                  //         child: Column(
                                  //           mainAxisAlignment: MainAxisAlignment.center,
                                  //           children: [
                                  //             Text(
                                  //               'Q${index + 1}',
                                  //               style: TextStyle(fontSize: 12),
                                  //             ),
                                  //             SizedBox(height: 4),
                                  //             DropdownButton<String>(
                                  //               value: _answerControllers[index].text,
                                  //               items: ['A', 'B', 'C', 'D', 'E']
                                  //                   .map((option) => DropdownMenuItem(
                                  //                 value: option,
                                  //                 child: Text(option),
                                  //               ))
                                  //                   .toList(),
                                  //               onChanged: (value) {
                                  //                 setState(() {
                                  //                   _answerControllers[index].text = value!;
                                  //                 });
                                  //               },
                                  //             ),
                                  //           ],
                                  //         ),
                                  //       );
                                  //     },
                                  //   ),
                                  // ),
                                  // SizedBox(height: 20),

                                  // Loading indicator for generation
                                  if (_isGenerating) ...[
                                    Center(
                                      child: Column(
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 16),
                                          Text('Generating OMR Sheet...'),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                  ],

                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _createExam,
                                          icon: Icon(Icons.save),
                                          label: Text('Save Exam'),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _isGenerating
                                              ? null
                                              : () => _generateOMRSheet(
                                                  false,
                                                  null,
                                                ),
                                          icon: Icon(Icons.picture_as_pdf),
                                          label: Text('Generate OMR'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: EdgeInsets.symmetric(
                                              vertical: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: _isGenerating
                                        ? null
                                        : () => _generateOMRSheet(true, null),
                                    icon: Icon(Icons.vpn_key),
                                    label: Text('Generate Answer Key'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right side - Exam list
                  SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Saved Exams',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            SizedBox(height: 16),
                            if (_exams.isEmpty)
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'No exams created yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _exams.length,
                                  itemBuilder: (context, index) {
                                    final exam = _exams[index];
                                    return Card(
                                      margin: EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.assignment,
                                          color: Colors.blue,
                                        ),
                                        title: Text(exam.name),
                                        subtitle: Text(
                                          '${exam.totalQuestions} questions • ${exam.date.day}/${exam.date.month}/${exam.date.year}',
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.picture_as_pdf,
                                                size: 20,
                                              ),
                                              onPressed: _isGenerating
                                                  ? null
                                                  : () => _generateOMRSheet(
                                                      false,
                                                      exam,
                                                    ),
                                              tooltip: 'Generate OMR Sheet',
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.vpn_key,
                                                size: 20,
                                              ),
                                              onPressed: _isGenerating
                                                  ? null
                                                  : () => _generateOMRSheet(
                                                      true,
                                                      exam,
                                                    ),
                                              tooltip: 'Generate Answer Key',
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _examNameController.dispose();
    _questionsController.dispose();
    _setNumberController.dispose();
    _studentIdController.dispose();
    _mobileController.dispose();
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

// import 'package:flutter/material.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
// import 'dart:io';
// import '../omr_v1/omr_generator.dart';
// import '../omr_v1/omr_models.dart';
// import 'omr_database_manager.dart';
//
// class ExamManagementPage extends StatefulWidget {
//   @override
//   _ExamManagementPageState createState() => _ExamManagementPageState();
// }
//
// class _ExamManagementPageState extends State<ExamManagementPage> {
//   final _examNameController = TextEditingController();
//   final _questionsController = TextEditingController(text: '30');
//   final _setNumberController = TextEditingController(text: '1');
//   final _studentIdController = TextEditingController(text: '123456789');
//   final _mobileController = TextEditingController(text: '9876543210');
//
//   List<TextEditingController> _answerControllers = [];
//   List<Exam> _exams = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeAnswerControllers();
//     _loadExams();
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
//   Future<void> _loadExams() async {
//     setState(() => _isLoading = true);
//     try {
//       _exams = await DatabaseManager.getExams();
//     } catch (e) {
//       _showError('Failed to load exams: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _createExam() async {
//     if (_examNameController.text.isEmpty) {
//       _showError('Please enter exam name');
//       return;
//     }
//
//     final exam = Exam(
//       name: _examNameController.text,
//       date: DateTime.now(),
//       totalQuestions: int.parse(_questionsController.text),
//       correctAnswers: _answerControllers.map((c) => c.text).toList(),
//       createdAt: DateTime.now(),
//     );
//
//     try {
//       await DatabaseManager.insertExam(exam);
//       _examNameController.clear();
//       _loadExams();
//       _showSuccess('Exam created successfully!');
//     } catch (e) {
//       _showError('Failed to create exam: $e');
//     }
//   }
//
//   Future<void> _generateOMRSheet(bool isAnswerKey, Exam? exam) async {
//     final config = OMRExamConfig(
//       examName: exam?.name ?? _examNameController.text,
//       numberOfQuestions: exam?.totalQuestions ?? int.parse(_questionsController.text),
//       setNumber: int.parse(_setNumberController.text),
//       studentId: _studentIdController.text,
//       mobileNumber: _mobileController.text,
//       examDate: exam?.date ?? DateTime.now(),
//       correctAnswers: isAnswerKey ?
//       (exam?.correctAnswers ?? _answerControllers.map((c) => c.text).toList()) : [],
//     );
//
//     try {
//       final file = await OMRGenerator.generateOMRSheet(config);
//
//       // Save to gallery
//       await ImageGallerySaver.saveFile(file.path);
//
//       _showPreviewDialog(file, isAnswerKey);
//     } catch (e) {
//       _showError('Failed to generate OMR sheet: $e');
//     }
//   }
//
//   void _showPreviewDialog(File file, bool isAnswerKey) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(isAnswerKey ? 'Answer Key Preview' : 'OMR Sheet Preview'),
//         content: Container(
//           width: double.maxFinite,
//           child: Image.file(file),
//         ),
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
//     // Implementation for sharing file
//     _showSuccess('Sheet saved to gallery!');
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//
//   void _showSuccess(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Left side - Exam creation form
//             Expanded(
//               flex: 2,
//               child: SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Card(
//                       elevation: 4,
//                       child: Padding(
//                         padding: EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.stretch,
//                           children: [
//                             Text(
//                               'Create New Exam',
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.blue[800],
//                               ),
//                             ),
//                             SizedBox(height: 20),
//                             TextField(
//                               controller: _examNameController,
//                               decoration: InputDecoration(
//                                 labelText: 'Exam Name',
//                                 border: OutlineInputBorder(),
//                                 prefixIcon: Icon(Icons.assignment),
//                               ),
//                             ),
//                             SizedBox(height: 16),
//                             TextField(
//                               controller: _questionsController,
//                               decoration: InputDecoration(
//                                 labelText: 'Number of Questions',
//                                 border: OutlineInputBorder(),
//                                 prefixIcon: Icon(Icons.format_list_numbered),
//                               ),
//                               keyboardType: TextInputType.number,
//                               onChanged: (value) {
//                                 final count = int.tryParse(value) ?? 30;
//                                 setState(() {
//                                   _answerControllers = List.generate(
//                                     count,
//                                         (index) => index < _answerControllers.length ?
//                                     _answerControllers[index] :
//                                     TextEditingController(text: 'A'),
//                                   );
//                                 });
//                               },
//                             ),
//                             SizedBox(height: 16),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: TextField(
//                                     controller: _setNumberController,
//                                     decoration: InputDecoration(
//                                       labelText: 'Set Number (0-9)',
//                                       border: OutlineInputBorder(),
//                                     ),
//                                     keyboardType: TextInputType.number,
//                                   ),
//                                 ),
//                                 SizedBox(width: 16),
//                                 Expanded(
//                                   child: TextField(
//                                     controller: _studentIdController,
//                                     decoration: InputDecoration(
//                                       labelText: 'Student ID (9 digits)',
//                                       border: OutlineInputBorder(),
//                                     ),
//                                     keyboardType: TextInputType.number,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             SizedBox(height: 16),
//                             TextField(
//                               controller: _mobileController,
//                               decoration: InputDecoration(
//                                 labelText: 'Mobile Number (11 digits)',
//                                 border: OutlineInputBorder(),
//                                 prefixIcon: Icon(Icons.phone),
//                               ),
//                               keyboardType: TextInputType.phone,
//                             ),
//                             SizedBox(height: 20),
//                             Text(
//                               'Correct Answers (for Answer Key):',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             SizedBox(height: 10),
//                             Container(
//                               height: 200,
//                               child: GridView.builder(
//                                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                                   crossAxisCount: 5,
//                                   crossAxisSpacing: 8.0,
//                                   mainAxisSpacing: 8.0,
//                                   childAspectRatio: 1.5,
//                                 ),
//                                 itemCount: _answerControllers.length,
//                                 itemBuilder: (context, index) {
//                                   return Container(
//                                     decoration: BoxDecoration(
//                                       border: Border.all(color: Colors.grey[300]!),
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     child: Column(
//                                       mainAxisAlignment: MainAxisAlignment.center,
//                                       children: [
//                                         Text(
//                                           'Q${index + 1}',
//                                           style: TextStyle(fontSize: 12),
//                                         ),
//                                         SizedBox(height: 4),
//                                         DropdownButton<String>(
//                                           value: _answerControllers[index].text,
//                                           items: ['A', 'B', 'C', 'D', 'E']
//                                               .map((option) => DropdownMenuItem(
//                                             value: option,
//                                             child: Text(option),
//                                           ))
//                                               .toList(),
//                                           onChanged: (value) {
//                                             setState(() {
//                                               _answerControllers[index].text = value!;
//                                             });
//                                           },
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                             SizedBox(height: 20),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: ElevatedButton.icon(
//                                     onPressed: _createExam,
//                                     icon: Icon(Icons.save),
//                                     label: Text('Save Exam'),
//                                     style: ElevatedButton.styleFrom(
//                                       padding: EdgeInsets.symmetric(vertical: 15),
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(width: 10),
//                                 Expanded(
//                                   child: ElevatedButton.icon(
//                                     onPressed: () => _generateOMRSheet(false, null),
//                                     icon: Icon(Icons.picture_as_pdf),
//                                     label: Text('Generate OMR'),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.green,
//                                       padding: EdgeInsets.symmetric(vertical: 15),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             SizedBox(height: 10),
//                             ElevatedButton.icon(
//                               onPressed: () => _generateOMRSheet(true, null),
//                               icon: Icon(Icons.vpn_key),
//                               label: Text('Generate Answer Key'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.orange,
//                                 padding: EdgeInsets.symmetric(vertical: 15),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             // Right side - Exam list
//             SizedBox(width: 20),
//             Expanded(
//               flex: 1,
//               child: Card(
//                 elevation: 4,
//                 child: Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       Text(
//                         'Saved Exams',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue[800],
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       if (_exams.isEmpty)
//                         Expanded(
//                           child: Center(
//                             child: Text(
//                               'No exams created yet',
//                               style: TextStyle(color: Colors.grey),
//                             ),
//                           ),
//                         )
//                       else
//                         Expanded(
//                           child: ListView.builder(
//                             itemCount: _exams.length,
//                             itemBuilder: (context, index) {
//                               final exam = _exams[index];
//                               return Card(
//                                 margin: EdgeInsets.only(bottom: 8),
//                                 child: ListTile(
//                                   leading: Icon(Icons.assignment, color: Colors.blue),
//                                   title: Text(exam.name),
//                                   subtitle: Text(
//                                     '${exam.totalQuestions} questions • ${exam.date.day}/${exam.date.month}/${exam.date.year}',
//                                   ),
//                                   trailing: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       IconButton(
//                                         icon: Icon(Icons.picture_as_pdf, size: 20),
//                                         onPressed: () => _generateOMRSheet(false, exam),
//                                         tooltip: 'Generate OMR Sheet',
//                                       ),
//                                       IconButton(
//                                         icon: Icon(Icons.vpn_key, size: 20),
//                                         onPressed: () => _generateOMRSheet(true, exam),
//                                         tooltip: 'Generate Answer Key',
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                     ],
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
