import 'package:black_box/db/exam/question_dao.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:black_box/model/exam/exam_model.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../model/exam/question_model.dart';
import '../../model/user/user.dart';
import 'ExamRoom.dart';
import 'exam_result_screen.dart';
import 'exam_start.dart';


class ExamPanel extends StatefulWidget {
  final User user;
  final ExamModel exam;

  const ExamPanel({super.key, required this.user, required this.exam});

  @override
  State<ExamPanel> createState() => _ExamPanelState();
}

class _ExamPanelState extends State<ExamPanel> {
  var activeScreen = "start-screen";
  Map<int, String> selectedAnswers = {};
  bool hasFinished = false;
  List<QuestionModel> _questions = [];

  @override
  void initState() {
    _loadQuestions(widget.exam.uniqueId);
  }

  void switchScreen() {
    setState(() {
      selectedAnswers = {};
      activeScreen = "question-screen";
    });
  }

  void switchResult() {
    setState(() {
      activeScreen = "result-screen";
    });
  }

  bool isExamComplete(int totalQuestions) {
    return selectedAnswers.length == totalQuestions;
  }

  void onSelectedAnswer(String answer, String questionText, int currentQuestionIndex, int totalQuestions) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = answer;
      if (isExamComplete(totalQuestions)) {
        finishedExam();
      }
    });
  }

  void finishedExam() {
    if (hasFinished) return;
    hasFinished = true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Are you sure?"),
        content: const Text("Do you want to finish your exam?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                activeScreen = "result-screen";
                hasFinished = false;
              });
            },
            child: const Text("SUBMIT"),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadQuestions(String quizId) async {
    try {
      print("Loading questions for quizId: $quizId");

      if (await InternetConnectionChecker.instance.hasConnection) {
        // Online mode: fetch from Firestore
        final querySnapshot = await FirebaseFirestore.instance
            .collection('questions')
            .where('quiz_id', isEqualTo: quizId)
            .get();

        if (querySnapshot.docs.isEmpty) {
          print("No questions found for this quiz in Firestore");
        }

        final fetchedQuestions = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return QuestionModel.fromJson(data);
        }).toList();

        // Store questions to local DB
        await QuestionDAO().deleteQuestionByUniqueId(quizId); // Clear previous if any
        for (var q in fetchedQuestions) {
          await QuestionDAO().insertQuestion(q);
        }

        // Update state
        setState(() {
          _questions = fetchedQuestions;
          widget.exam.questions?.clear();
          widget.exam.questions = _questions;
        });

      } else {
        // Offline mode: load from SQLite
        final offlineQuestions = await QuestionDAO().getQuestionsByQuizId(quizId);

        if (offlineQuestions.isEmpty) {
          _showError('No offline questions available for this quiz');
          return;
        }

        setState(() {
          _questions = offlineQuestions;
          widget.exam.questions?.clear();
          widget.exam.questions = _questions;
        });
      }
    } catch (e) {
      print("Error loading questions: $e");
      _showError('Error loading questions: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    // Determine the active screen widget based on activeScreen value
    final screenWidget = activeScreen == "start-screen"
        ? ExamStart(
      switchScreen: switchScreen,
      user: widget.user,
      exam: widget.exam,
    )
        : activeScreen == "question-screen"
        ? ExamRoom(
      selectedAnswers: selectedAnswers,
      onSelectedAnswer: onSelectedAnswer,
      switchResult: switchResult,
      user: widget.user,
      quiz: widget.exam, questions: _questions,
    )
        : ExamResultScreen(
      switchScreen: switchScreen,
      selectedAnswer: selectedAnswers,
      user: widget.user,
      quiz: widget.exam,
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 252, 242, 156),
            Color.fromARGB(255, 223, 247, 86),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // <-- very important
        body: screenWidget,
      ),
    );
  }


  // @override
  // Widget build(BuildContext context) {
  //   Widget screenWidget;
  //
  //   if (activeScreen == "start-screen") {
  //     screenWidget = ExamStart(
  //       switchScreen: switchScreen,
  //       user: widget.user,
  //       exam: widget.exam,
  //     );
  //   } else if (activeScreen == "question-screen") {
  //     screenWidget = ExamRoom(
  //       selectedAnswers: selectedAnswers,
  //       onSelectedAnswer: onSelectedAnswer,
  //       switchResult: switchResult,
  //       user: widget.user,
  //       quiz: widget.exam,
  //     );
  //   } else {
  //     screenWidget = ExamResultScreen(
  //       switchScreen: switchScreen,
  //       selectedAnswer: selectedAnswers,
  //       user: widget.user,
  //       quiz: widget.exam,
  //     );
  //   }
  //
  //   return Scaffold(
  //     body: Container(
  //       decoration: const BoxDecoration(
  //         gradient: LinearGradient(
  //           begin: Alignment.topCenter,
  //           end: Alignment.bottomCenter,
  //           colors: [
  //             Color.fromARGB(255, 252, 242, 156),
  //             Color.fromARGB(255, 223, 247, 86),
  //           ],
  //         ),
  //       ),
  //       child: screenWidget,
  //     ),
  //   );
  // }
}
