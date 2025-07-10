import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../db/firebase/exam_result_firebase_service.dart';
import '../../db/exam/quiz_result_dao.dart';
import '../../model/exam/quiz_result_model.dart';

class ExamLeaderBoard extends StatefulWidget {
  final String quizId;
  const ExamLeaderBoard({super.key, required this.quizId});

  @override
  State<ExamLeaderBoard> createState() => _ExamLeaderBoardState();
}

class _ExamLeaderBoardState extends State<ExamLeaderBoard> {
  late Future<List<QuizResultModel>> results;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    results = Future.value([]);
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);

    if (await InternetConnectionChecker.instance.hasConnection) {
      try {
        final onlineResults = await QuizResultFirebaseService().getOnlineResults(widget.quizId);
        setState(() {
          results = Future.value(onlineResults);
          _isLoading = false;
        });
      } catch (e) {
        print("Error fetching online results: $e");
        setState(() => _isLoading = false);
      }
    } else {
      final offlineResults = await QuizResultDAO().getResultsByQuizId(widget.quizId);
      setState(() {
        results = Future.value(offlineResults);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Leaderboard'),
        backgroundColor: Colors.teal[600],
      ),
      body: _isLoading
          ? Center(child: Lottie.asset('animation/ (1).json', height: 120))
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<List<QuizResultModel>>(
            future: results,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No results found.'));
              }

              final resultList = snapshot.data!;
              resultList.sort((a, b) => b.percentage.compareTo(a.percentage));

              return ListView.separated(
                itemCount: resultList.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final result = resultList[index];
                  return _buildResultCard(result, index + 1);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(QuizResultModel result, int rank) {
    String formattedDateTime(String timestamp) {
      try {
        final dateTime = DateTime.parse(timestamp);
        final daySuffix = (int day) {
          if (day >= 11 && day <= 13) return 'th';
          switch (day % 10) {
            case 1:
              return 'st';
            case 2:
              return 'nd';
            case 3:
              return 'rd';
            default:
              return 'th';
          }
        }(dateTime.day);

        final formattedDate = "${dateTime.day}$daySuffix ${DateFormat('MMMM, yy').format(dateTime)}";
        final formattedTime = DateFormat('h:mm a').format(dateTime);

        return "$formattedDate, $formattedTime";
      } catch (e) {
        return timestamp; // fallback if parsing fails
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank & Phone
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#$rank',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                ),
                Text(
                  'Phone: ${result.phoneNumber}',
                  style: TextStyle(fontSize: 14, color: Colors.teal[600]),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Quiz Stats
            Text('Correct: ${result.correctCount}', style: const TextStyle(fontSize: 14, color: Colors.green)),
            Text('Incorrect: ${result.incorrectCount}', style: const TextStyle(fontSize: 14, color: Colors.red)),
            Text('Unanswered: ${result.uncheckedCount}', style: const TextStyle(fontSize: 14, color: Colors.orange)),
            const SizedBox(height: 8),

            // Score
            Text(
              'Score: ${result.percentage.toStringAsFixed(2)}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 8),

            // Timestamp & Quiz Name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${formattedDateTime(result.timestamp.toString())}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  result.quizName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
