import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../db/course/courseDbConfig.dart';
import '../models/exam_result_model.dart';
import '../models/omr_sheet_model.dart';
import '../models/scanned_result.dart';


class StudentOMRMarkingPage extends StatefulWidget {
  final OMRSheet sheet;
  final String? studentId;
  final String? phone;

  const StudentOMRMarkingPage({Key? key, required this.sheet, this.studentId, this.phone})
      : super(key: key);

  @override
  State<StudentOMRMarkingPage> createState() => _StudentOMRMarkingPageState();
}

class _StudentOMRMarkingPageState extends State<StudentOMRMarkingPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  late List<String> _answers;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _studentIdController.text = widget.studentId!;
    _phoneController.text = widget.phone!;
    _answers = List.generate(widget.sheet.numberOfQuestions, (index) => '');

    _checkInternet();
    _syncResultsWithFirebase();
  }

  /// -----------------------------
  /// Internet Check
  /// -----------------------------
  Future<void> _checkInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  /// -----------------------------
  /// Select Answer
  /// -----------------------------
  // void _selectAnswer(int index, String option) {
  //   setState(() {
  //     _answers[index] = option;
  //   });
  // }

  void _selectAnswer(int index, String option) {
    setState(() {
      if (_answers[index] == option) {
        // If already selected → unmark
        _answers[index] = '';
      } else {
        // Otherwise select
        _answers[index] = option;
      }
    });
  }

  /// -----------------------------
  /// Upload Result To Firebase
  /// -----------------------------
  Future<void> _uploadResultToFirebase(ScannedResult result) async {
    try {
      final docRef = _firestore
          .collection('courses')
          .doc(result.sId ?? "defaultSchool")
          .collection('omr_results')
          .doc(result.id);

      await docRef.set(result.toMap());

      await StudentDatabase.updateResultSyncStatus(result.id!, 1);
    } catch (e) {
      debugPrint("Firebase Sync Error: $e");
    }
  }

  /// -----------------------------
  /// Sync Unsynced Results
  /// -----------------------------
  Future<void> _syncResultsWithFirebase() async {
    if (!_isOnline) return;

    final List<ScannedResult> unsynced =
    await StudentDatabase.getUnsyncedResults();

    for (var result in unsynced) {
      try {
        final docRef = _firestore
            .collection('courses')
            .doc(result.sId ?? "defaultSchool")
            .collection('omr_results')
            .doc(result.id);

        await docRef.set(result.toMap());

        await StudentDatabase.updateResultSyncStatus(result.id!, 1);
      } catch (e) {
        debugPrint("Sync error: $e");
      }
    }
  }

  /// -----------------------------
  /// Save Result
  /// -----------------------------
  Future<void> _saveResult() async {
    if (!_formKey.currentState!.validate()) return;

    final result = ScannedResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: _studentIdController.text,
      mobileNumber: _phoneController.text,
      setNumber: widget.sheet.setNumber,
      detectedAnswers: _answers,
      confidence: 1.0,
      // sheetId: widget.sheet.id,
      sheetId: widget.sheet.uniqueId,
      createdAt: DateTime.now(),
      syncStatus: 0,
      uniqueId: DateTime.now().millisecondsSinceEpoch.toString(),
      sId: widget.sheet.sId,
    );

    /// Save locally
    await StudentDatabase.insertScannedResult(result);

    /// Sync if online
    if (_isOnline) {
      await _uploadResultToFirebase(result);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isOnline
              ? "Result Saved & Synced"
              : "Saved Offline (Will Sync Later)",
        ),
      ),
    );

    await _saveExamResult();

    // Navigator.pop(context, true);
  }

  Future<void> _uploadExamResultToFirebase(ExamResult result) async {
    try {

      final docRef = _firestore
          .collection('courses')
          .doc(widget.sheet.sId ?? "defaultSchool")
          .collection('exam_results')
          .doc(result.id);

      await docRef.set(result.toJson());

      // SQLite syncStatus update
      await StudentDatabase.updateExamResultSyncStatus(result.id, 1);

    } catch (e) {
      debugPrint("Firebase Upload Error: $e");
    }
  }

  Future<void> _syncExamResults() async {

    if (!_isOnline) return;

    final unsynced =
    await StudentDatabase.getUnsyncedExamResults();

    for (var result in unsynced) {

      try {

        final docRef = _firestore
            .collection('courses')
            .doc(widget.sheet.sId ?? "defaultSchool")
            .collection('exam_results')
            .doc(result.id);

        await docRef.set(result.toJson());

        await StudentDatabase.updateExamResultSyncStatus(result.id, 1);

      } catch (e) {
        debugPrint("Sync error: $e");
      }
    }
  }

  Future<void> _saveExamResult() async {

    if (!_formKey.currentState!.validate()) return;

    int correct = 0;
    int wrong = 0;
    int unanswered = 0;

    final correctAnswers = widget.sheet.correctAnswers;

    for (int i = 0; i < _answers.length; i++) {

      if (_answers[i].isEmpty) {
        unanswered++;
      } else if (_answers[i] == correctAnswers[i]) {
        correct++;
      } else {
        wrong++;
      }

    }

    final percentage =
        (correct / widget.sheet.numberOfQuestions) * 100;

    final result = ExamResult(

      id: DateTime.now().millisecondsSinceEpoch.toString(),

      studentId: _studentIdController.text,

      omrSheetId: widget.sheet.uniqueId ?? widget.sheet.id,

      studentName: "",

      examName: widget.sheet.examName,

      studentAnswers: _answers,

      correctAnswers: correctAnswers,

      totalQuestions: widget.sheet.numberOfQuestions,

      correctCount: correct,

      wrongCount: wrong,

      unansweredCount: unanswered,

      percentage: percentage,

      scannedAt: DateTime.now(), schoolId: widget.sheet.sId ?? '',

    );

    /// Save locally
    await StudentDatabase.insertExamResult(result);

    /// Upload to Firebase if online
    if (_isOnline) {
      await _uploadExamResultToFirebase(result);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isOnline
              ? "Result Saved & Synced"
              : "Saved Offline (Will Sync Later)",
        ),
      ),
    );

    // _showResultDialog(result);

    Navigator.pop(context, result);
  }

  void _showResultDialog(ExamResult result) {

    Color resultColor;

    if (result.percentage >= 80) {
      resultColor = Colors.green;
    } else if (result.percentage >= 50) {
      resultColor = Colors.orange;
    } else {
      resultColor = Colors.red;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// Title
              Row(
                children: [
                  Icon(Icons.check_circle, color: resultColor, size: 32),
                  SizedBox(width: 10),
                  Text(
                    "Exam Result",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),

              SizedBox(height: 20),

              /// Student Info
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [

                    _resultRow("Student ID", result.studentId),
                    _resultRow("Student Name", result.studentName.isEmpty ? "Unknown" : result.studentName),
                    _resultRow("Exam", result.examName),

                  ],
                ),
              ),

              SizedBox(height: 16),

              /// Score Summary
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [

                    _resultRow("Total Questions", result.totalQuestions.toString()),
                    _resultRow("Correct", result.correctCount.toString()),
                    _resultRow("Wrong", result.wrongCount.toString()),
                    _resultRow("Unanswered", result.unansweredCount.toString()),

                  ],
                ),
              ),

              SizedBox(height: 20),

              /// Percentage
              Text(
                "${result.percentage.toStringAsFixed(2)} %",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: resultColor,
                ),
              ),

              SizedBox(height: 8),

              /// Progress bar
              LinearProgressIndicator(
                value: result.percentage / 100,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(resultColor),
              ),

              SizedBox(height: 20),

              /// Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close),
                    label: Text("Close"),
                  ),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: resultColor,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.done),
                    label: Text("Done"),
                  ),

                ],
              )

            ],
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),

          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),
    );
  }
  /// -----------------------------
  /// Question Widget
  /// -----------------------------
  Widget _buildQuestion(int index) {
    final options = ['A', 'B', 'C', 'D'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Text(
              "Q.${index + 1}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: options.map((op) {
                  final isSelected = _answers[index] == op;

                  return GestureDetector(
                    onTap: () => _selectAnswer(index, op),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Center(
                        child: Text(
                          op,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// -----------------------------
  /// UI
  /// -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("OMR Marking - ${widget.sheet.examName}"),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            /// Student Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextFormField(
                    controller: _studentIdController,
                    decoration: const InputDecoration(
                      labelText: "Student ID",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                    v!.isEmpty ? "Enter Student ID" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: "Mobile Number",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                    v!.isEmpty ? "Enter phone number" : null,
                  ),
                ],
              ),
            ),

            /// Question Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2,
                ),
                itemCount: widget.sheet.numberOfQuestions,
                itemBuilder: (context, index) => _buildQuestion(index),
              ),
            ),

            /// Save Button
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveResult,
                  child: const Text("Save Result"),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}