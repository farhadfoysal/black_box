import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../db/course/courseDbConfig.dart';
import '../models/omr_sheet_model.dart';
import '../models/scanned_result.dart';


class StudentOMRMarkingPage extends StatefulWidget {
  final OMRSheet sheet;

  const StudentOMRMarkingPage({Key? key, required this.sheet})
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
  void _selectAnswer(int index, String option) {
    setState(() {
      _answers[index] = option;
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
      sheetId: widget.sheet.id,
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

    Navigator.pop(context, true);
  }

  /// -----------------------------
  /// Question Widget
  /// -----------------------------
  Widget _buildQuestion(int index) {
    final options = ['A', 'B', 'C', 'D'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              "Q${index + 1}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
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
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.5,
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