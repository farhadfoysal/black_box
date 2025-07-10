import 'package:black_box/db/exam/quiz_result_dao.dart';
import 'package:black_box/db/firebase/exam_result_firebase_service.dart';
import 'package:black_box/model/exam/quiz_result_model.dart';
import 'package:black_box/quiz/LeaderBoardResult.dart';
import 'package:black_box/screen_page/exam/exam_leader_board.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/games/v1.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:lottie/lottie.dart';

class ExamResultsPage extends StatefulWidget {
  final String quizId; // Pass the quizId to the page

  ExamResultsPage({required this.quizId});

  @override
  _ExamResultsPageState createState() => _ExamResultsPageState();
}

class _ExamResultsPageState extends State<ExamResultsPage> {
  late Future<List<QuizResultModel>> quizResults;
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
        await QuizResultFirebaseService().getOnlineResults(widget.quizId);
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
      await QuizResultDAO().getResultsByQuizId(widget.quizId);
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
        actions: [
          // Leaderboard Icon in the top right corner
          IconButton(
            icon: Icon(Icons.leaderboard),
            onPressed: () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExamLeaderBoard(quizId: widget.quizId),
                ),
              );

            },
          ),
        ],
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
          child: FutureBuilder<List<QuizResultModel>>(
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
                scrollDirection:
                Axis.horizontal, // Allow horizontal scrolling
                child: DataTable(
                  columnSpacing: 20,
                  columns: [
                    DataColumn(label: Text('Phone Number')),
                    DataColumn(label: Text('Correct')),
                    DataColumn(label: Text('Incorrect')),
                    DataColumn(label: Text('Unanswered')),
                    DataColumn(label: Text('Score (%)')),
                    DataColumn(label: Text('Student ID')),
                    DataColumn(label: Text('Timestamp')),
                    DataColumn(label: Text('Quiz Name')),
                  ],
                  rows: results.map<DataRow>((result) {
                    return DataRow(
                      cells: [
                        DataCell(Text(result.phoneNumber)),
                        DataCell(Text(result.correctCount.toString())),
                        DataCell(Text(result.incorrectCount.toString())),
                        DataCell(Text(result.uncheckedCount.toString())),
                        DataCell(
                            Text(result.percentage.toStringAsFixed(2))),
                        DataCell(Text(result.studentId)),
                        DataCell(Text(result.timestamp.toString())),
                        DataCell(Text(result.quizName)),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:internet_connection_checker/internet_connection_checker.dart';
//
// import '../db/firebase/QuizFirestoreHelper.dart';
// import '../db/local/QuizResultDBHelper.dart';
// import '../model/quiz/QResult.dart';
//
// class ExamResultsPage extends StatefulWidget {
//   final String quizId; // Pass the quizId to the page
//
//   ExamResultsPage({required this.quizId});
//
//   @override
//   _ExamResultsPageState createState() => _ExamResultsPageState();
// }
//
// class _ExamResultsPageState extends State<ExamResultsPage> {
//   late Future<List<QResult>> quizResults;  // Declare quizResults as a Future
//
//   @override
//   void initState() {
//     super.initState();
//     quizResults = Future.value([]); // Initialize quizResults to an empty Future
//     loadResults();
//   }
//
//   // Load results based on internet connection
//   Future<void> loadResults() async {
//     if (await InternetConnectionChecker.instance.hasConnection) {
//       try {
//         // Fetch online results from Firestore
//         final results = await Quizfirestorehelper().getOnlineResults(widget.quizId);
//         setState(() {
//           quizResults = Future.value(results); // Set the online results
//         });
//       } catch (e) {
//         print("Error fetching online results: $e");
//         // Handle errors if needed
//       }
//     } else {
//       // Fetch offline results from SQLite database
//       final results = await Quizresultdbhelper().getResultsByQuizId(widget.quizId);
//       setState(() {
//         quizResults = Future.value(results); // Set the offline results
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Quiz Results'),
//         backgroundColor: Colors.teal[600],
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: FutureBuilder<List<QResult>>(
//             future: quizResults,  // Use the quizResults Future
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return Center(child: CircularProgressIndicator());
//               }
//
//               if (snapshot.hasError) {
//                 return Center(child: Text('Error: ${snapshot.error}'));
//               }
//
//               if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                 return Center(child: Text('No results found.'));
//               }
//
//               final results = snapshot.data!;
//
//               return SingleChildScrollView(
//                 child: DataTable(
//                   columnSpacing: 20,
//                   columns: [
//                     DataColumn(label: Text('Student ID')),
//                     DataColumn(label: Text('Phone Number')),
//                     DataColumn(label: Text('Quiz Name')),
//                     DataColumn(label: Text('Correct')),
//                     DataColumn(label: Text('Incorrect')),
//                     DataColumn(label: Text('Unanswered')),
//                     DataColumn(label: Text('Score (%)')),
//                     DataColumn(label: Text('Timestamp')),
//                   ],
//                   rows: results.map<DataRow>((result) {
//                     return DataRow(
//                       cells: [
//                         DataCell(Text(result.studentId)),
//                         DataCell(Text(result.phoneNumber)),
//                         DataCell(Text(result.quizName)),
//                         DataCell(Text(result.correctCount.toString())),
//                         DataCell(Text(result.incorrectCount.toString())),
//                         DataCell(Text(result.uncheckedCount.toString())),
//                         DataCell(Text(result.percentage.toStringAsFixed(2))),
//                         DataCell(Text(result.timestamp.toString())),
//                       ],
//                     );
//                   }).toList(),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
