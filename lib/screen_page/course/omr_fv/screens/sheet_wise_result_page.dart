import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../db/course/courseDbConfig.dart';
import '../models/exam_result_model.dart';

class SheetWiseResultsPage extends StatefulWidget {

  final String schoolId;
  final String sheetId;
  final String examName;

  const SheetWiseResultsPage({
    Key? key,
    required this.schoolId,
    required this.sheetId,
    required this.examName,
  }) : super(key: key);

  @override
  State<SheetWiseResultsPage> createState() => _SheetWiseResultsPageState();
}

class _SheetWiseResultsPageState extends State<SheetWiseResultsPage> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ExamResult> _results = [];
  List<ExamResult> _filtered = [];

  bool _loading = true;
  bool _isOnline = true;

  double _average = 0;
  int _pass = 0;
  int _fail = 0;

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

      print("Sheet result error: $e");

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
        .where('omrSheetId', isEqualTo: widget.sheetId)
        .orderBy('percentage', descending: true)
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
      _filtered = results;
    });

    /// cache locally
    for (var r in results) {
      await StudentDatabase.insertExamResult(r);
    }

  }

  /// SQLITE
  Future<void> _loadFromSQLite() async {

    final results =
    await StudentDatabase.getExamResultsBySheet(widget.sheetId);

    setState(() {
      _results = results;
      _filtered = results;
    });

  }

  void _calculateStats() {

    if (_results.isEmpty) return;

    _average =
        _results.fold(0.0, (sum, r) => sum + r.percentage) / _results.length;

    _pass = _results.where((e) => e.percentage >= 60).length;

    _fail = _results.length - _pass;

  }

  void _search(String text) {

    setState(() {

      _filtered = _results.where((r) {

        return r.studentName
            .toLowerCase()
            .contains(text.toLowerCase()) ||
            r.studentId.contains(text);

      }).toList();

    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.examName),
        backgroundColor: Color(0xFF2C3E50),
      ),

      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [

          _buildTopper(),

          _buildStats(),

          _buildSearch(),

          Expanded(child: _buildList()),

        ],
      ),
    );

  }

  /// TOPPER CARD
  Widget _buildTopper() {

    if (_results.isEmpty) return SizedBox();

    final topper = _results.first;

    return Container(

      margin: EdgeInsets.all(16),

      padding: EdgeInsets.all(20),

      decoration: BoxDecoration(

        gradient: LinearGradient(
          colors: [Color(0xFF3498DB), Color(0xFF2ECC71)],
        ),

        borderRadius: BorderRadius.circular(12),

      ),

      child: Row(

        children: [

          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.emoji_events, color: Colors.orange),
          ),

          SizedBox(width: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                "Topper",
                style: TextStyle(color: Colors.white70),
              ),

              Text(
                topper.studentName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              Text(
                "${topper.percentage.toStringAsFixed(1)}%",
                style: TextStyle(color: Colors.white),
              )

            ],
          )

        ],
      ),
    );
  }

  /// STATS
  Widget _buildStats() {

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [

          _stat("Average", "${_average.toStringAsFixed(1)}%"),
          _stat("Pass", "$_pass"),
          _stat("Fail", "$_fail"),

        ],
      ),
    );
  }

  Widget _stat(String title, String value) {

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

              Text(title)

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {

    return Padding(
      padding: EdgeInsets.all(16),
      child: TextField(

        decoration: InputDecoration(
          hintText: "Search student",
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),

        onChanged: _search,
      ),
    );

  }

  /// RESULT LIST
  Widget _buildList() {

    return ListView.builder(

      itemCount: _filtered.length,

      itemBuilder: (context, index) {

        final r = _filtered[index];

        return Card(

          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),

          child: ListTile(

            leading: CircleAvatar(
              child: Text("${index + 1}"),
            ),

            title: Text(r.studentName),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text("ID: ${r.studentId}"),

                LinearProgressIndicator(
                  value: r.percentage / 100,
                ),

              ],
            ),

            trailing: Text(
              "${r.percentage.toStringAsFixed(1)}%",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
        title: Text(r.studentName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Text("ID: ${r.studentId}"),
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
}