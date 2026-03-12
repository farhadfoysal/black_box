import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../db/course/courseDbConfig.dart';
import '../models/exam_result_model.dart';

class StudentResultsPage extends StatefulWidget {

  final String schoolId;
  final String studentId;

  const StudentResultsPage({
    Key? key,
    required this.schoolId,
    required this.studentId,
  }) : super(key: key);

  @override
  State<StudentResultsPage> createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ExamResult> _results = [];

  bool _loading = true;
  bool _isOnline = true;

  double _average = 0;
  double _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _checkInternet();
    _loadResults();
  }

  Future<void> _checkInternet() async {

    final result = await Connectivity().checkConnectivity();

    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });

  }

  Future<void> _loadResults() async {

    setState(() => _loading = true);

    try {

      if (_isOnline) {
        await _loadFromFirebase();
      } else {
        await _loadFromSQLite();
      }

      _calculateStats();

    } catch (e) {

      print("Student result error: $e");

      await _loadFromSQLite();

    }

    setState(() => _loading = false);

  }

  /// FIREBASE
  Future<void> _loadFromFirebase() async {

    final snapshot = await _firestore
        .collection('courses')
        .doc(widget.schoolId)
        .collection('exam_results')
        .where('studentId', isEqualTo: widget.studentId)
        .orderBy('scannedAt', descending: true)
        .get();

    final results = snapshot.docs.map((doc) {

      final data = doc.data();

      return ExamResult.fromMap({
        ...data,
        'id': doc.id,
        'scannedAt': data['scannedAt'] is String
            ? data['scannedAt']
            : data['scannedAt'].toDate().toIso8601String(),
      });

    }).toList();

    setState(() {
      _results = results;
    });

    /// cache locally
    for (var r in results) {
      await StudentDatabase.insertExamResult(r);
    }

  }

  /// SQLITE
  Future<void> _loadFromSQLite() async {

    final results =
    await StudentDatabase.getResultsByStudent(widget.studentId);

    setState(() {
      _results = results;
    });

  }

  void _calculateStats() {

    if (_results.isEmpty) return;

    _average =
        _results.fold(0.0, (sum, r) => sum + r.percentage) / _results.length;

    _bestScore =
        _results.map((r) => r.percentage).reduce((a, b) => a > b ? a : b);

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Student Results"),
        backgroundColor: Color(0xFF2C3E50),
      ),

      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [

          _buildStudentHeader(),

          _buildStats(),

          Expanded(child: _buildResultsList()),

        ],
      ),

    );

  }

  /// STUDENT HEADER
  Widget _buildStudentHeader() {

    final student = _results.first;

    return Container(

      padding: EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3498DB), Color(0xFF2ECC71)],
        ),
      ),

      child: Row(

        children: [

          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 32),
          ),

          SizedBox(width: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                student.studentName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              Text(
                "ID: ${student.studentId}",
                style: TextStyle(color: Colors.white70),
              ),

            ],
          )

        ],
      ),
    );
  }

  /// STATS
  Widget _buildStats() {

    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [

          _stat("Average", "${_average.toStringAsFixed(1)}%"),
          _stat("Best", "${_bestScore.toStringAsFixed(1)}%"),
          _stat("Exams", "${_results.length}"),

        ],
      ),
    );
  }

  Widget _stat(String label, String value) {

    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [

              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(label)

            ],
          ),
        ),
      ),
    );
  }

  /// RESULT LIST
  Widget _buildResultsList() {

    return ListView.builder(

      itemCount: _results.length,

      itemBuilder: (context, index) {

        final r = _results[index];

        return Card(

          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),

          child: ListTile(

            leading: CircleAvatar(
              backgroundColor:
              r.percentage >= 60 ? Colors.green : Colors.red,
              child: Text("${r.percentage.toStringAsFixed(0)}"),
            ),

            title: Text(r.examName),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text("Score: ${r.correctCount}/${r.totalQuestions}"),

                LinearProgressIndicator(
                  value: r.percentage / 100,
                ),

              ],
            ),

            trailing: Text(
              "${r.percentage.toStringAsFixed(1)}%",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            onTap: () {
              _showDetails(r);
            },

          ),
        );

      },

    );
  }

  void _showDetails(ExamResult r) {

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(r.examName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Text("Correct: ${r.correctCount}"),
            Text("Wrong: ${r.wrongCount}"),
            Text("Unanswered: ${r.unansweredCount}"),

            SizedBox(height: 10),

            Text(
              "${r.percentage.toStringAsFixed(2)}%",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

          ],
        ),
      ),
    );

  }

  Widget _buildEmptyState() {

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Icon(Icons.person_search, size: 80, color: Colors.grey),

          SizedBox(height: 16),

          Text(
            "No results found for this student",
            style: TextStyle(fontSize: 16),
          ),

        ],
      ),
    );
  }
}