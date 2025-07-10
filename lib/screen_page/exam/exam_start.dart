import 'package:black_box/db/exam/quiz_result_dao.dart';
import 'package:black_box/db/firebase/exam_firebase_service.dart';
import 'package:black_box/db/firebase/exam_result_firebase_service.dart';
import 'package:black_box/model/exam/quiz_result_model.dart';
import 'package:black_box/model/user/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../db/exam/question_dao.dart';
import '../../model/exam/exam_model.dart';
import '../../model/exam/question_model.dart';
import 'exam_results_page.dart';


class ExamStart extends StatefulWidget {
  final VoidCallback switchScreen;
  final User user;
  final ExamModel exam;

  const ExamStart({
    super.key,
    required this.switchScreen,
    required this.user,
    required this.exam,
  });

  @override
  State<ExamStart> createState() => _ExamStartState();
}

class _ExamStartState extends State<ExamStart> {
  bool _isExamPerformed = false;
  QuizResultModel? _examResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExamStatus();
  }



  Future<void> _checkExamStatus() async {
    setState(() => _isLoading = true);

    if (await InternetConnectionChecker.instance.hasConnection) {
      bool performed = await QuizResultFirebaseService().hasUserPerformedQuiz(
        widget.user.userid!,
        widget.user.phone,
        widget.exam.uniqueId,
      );
      if (performed) {
        _examResult = await QuizResultFirebaseService().getQuizResult(
          widget.user.userid!,
          widget.user.phone,
          widget.exam.uniqueId,
        );
      }
      setState(() {
        _isExamPerformed = performed;
        _isLoading = false;
      });
    } else {
      bool performed = await QuizResultDAO().hasUserPerformedQuiz(
        widget.user.userid!,
        widget.user.phone,
        widget.exam.uniqueId,
      );
      if (performed) {
        _examResult = await QuizResultDAO().getQuizResult(
          widget.user.userid!,
          widget.user.phone,
          widget.exam.uniqueId,
        );
      }
      setState(() {
        _isExamPerformed = performed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime createdAt = DateTime.tryParse(widget.exam.createdAt) ?? DateTime.now();

    String getDayWithSuffix(int day) {
      if (day >= 11 && day <= 13) return '${day}th';
      switch (day % 10) {
        case 1:
          return '${day}st';
        case 2:
          return '${day}nd';
        case 3:
          return '${day}rd';
        default:
          return '${day}th';
      }
    }

    final String formattedDate = "${getDayWithSuffix(createdAt.day)} ${DateFormat('MMMM, y').format(createdAt)}";
    final String formattedTime = DateFormat('h:mm a').format(createdAt);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset('animation/4.json', width: 250, height: 250),
                const SizedBox(height: 16),
                Text(
                  "Welcome to ${widget.exam.title}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.exam.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        "Duration: ${widget.exam.durationMinutes} minutes",
                        style: TextStyle(fontSize: 15, color: Colors.teal[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$formattedDate  |  $formattedTime",
                        style: TextStyle(fontSize: 16, color: Colors.teal[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                if (_isExamPerformed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "You have already attempted this exam.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_examResult != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Your Score: ${_examResult!.percentage}%",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Text("Correct: ${_examResult!.correctCount}", style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.cancel, color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Text("Incorrect: ${_examResult!.incorrectCount}", style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.help_outline, color: Colors.grey, size: 20),
                                      const SizedBox(width: 8),
                                      Text("Unanswered: ${_examResult!.uncheckedCount}", style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                _isLoading
                    ? Center(
                  child: Lottie.asset('animation/ (1).json', height: 120),
                )
                    : ElevatedButton(
                  onPressed: _isExamPerformed ? null : widget.switchScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    _isExamPerformed ? "Exam Completed" : "Start Exam",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExamResultsPage(quizId: widget.exam.uniqueId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text(
                    "Go to Exam Results",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
