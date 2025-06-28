import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:lottie/lottie.dart';

import '../db/firebase/QuizFirestoreHelper.dart';
import '../db/local/QuizResultDBHelper.dart';
import '../model/quiz/QResult.dart';

class Leaderboardresult extends StatefulWidget {
  final String quizId; // Pass the quizId to the page

  Leaderboardresult({required this.quizId});

  @override
  _QuizzesResultPageState createState() => _QuizzesResultPageState();
}

class _QuizzesResultPageState extends State<Leaderboardresult> {
  late Future<List<QResult>> quizResults;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    quizResults = Future.value([]); // Initialize quizResults to an empty Future
    loadResults();
  }

  // Load results based on internet connection
  Future<void> loadResults() async {
    setState(() {
      _isLoading = true;
    });
    if (await InternetConnectionChecker.instance.hasConnection) {
      try {
        // Fetch online results from Firestore
        final results =
        await Quizfirestorehelper().getOnlineResults(widget.quizId);
        setState(() {
          quizResults = Future.value(results); // Set the online results
        });
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print("Error fetching online results: $e");
        // Handle errors if needed
      }
    } else {
      // Fetch offline results from SQLite database
      final results =
      await Quizresultdbhelper().getResultsByQuizId(widget.quizId);
      setState(() {
        quizResults = Future.value(results); // Set the offline results
      });
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Results'),
        backgroundColor: Colors.teal[600],
      ),
      body: _isLoading
          ? Center(
        child: Lottie.asset(
          'animation/ (1).json', // Your Lottie loading animation
          height: 120,
        ),
      )
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<List<QResult>>(
            future: quizResults, // Use the quizResults Future
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No results found.'));
              }

              final results = snapshot.data!;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: results.map<Widget>((result) {
                    return _buildStudentCard(result);
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Build a custom card for each student
  Widget _buildStudentCard(QResult result) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank & Phone Number
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Phone: ${result.phoneNumber}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.teal[600],
                  ),
                ),
              ],
            ),
            Divider(color: Colors.teal[600]),
            SizedBox(height: 10),

            // Quiz Results
            Text(
              'Correct: ${result.correctCount}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green,
              ),
            ),
            Text(
              'Incorrect: ${result.incorrectCount}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
              ),
            ),
            Text(
              'Unanswered: ${result.uncheckedCount}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 8),

            // Score
            Text(
              'Score: ${result.percentage.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 8),

            // Timestamp and Quiz Name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Timestamp: ${result.timestamp}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Quiz: ${result.quizName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
