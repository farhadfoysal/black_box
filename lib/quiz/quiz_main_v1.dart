import 'package:flutter/material.dart';

import '../data/quiz/questions.dart';
import '../screen_page/quiz/quiz_page_v1.dart';
import '../screen_page/quiz/result_page_v1.dart';
import '../screen_page/quiz/start_quiz.dart';

class QuizMainV1 extends StatefulWidget {
  const QuizMainV1({super.key});

  @override
  State<QuizMainV1> createState() => _QuizState();
}

class _QuizState extends State<QuizMainV1> {
  var activeScreen = "start-screen";
  Map<int, String> selectedAnswer = {};  // Changed to non-nullable String
  bool hasFinished = false;

  void switchScreen() {
    setState(() {
      selectedAnswer = {};  // Clear the selected answers when switching screens
      activeScreen = "question-screen";
    });
  }

  void switchResult() {
    setState(() {
      activeScreen = "result-screen";
    });
  }

  bool isQuizComplete() {
    return selectedAnswer.length == questions.length; // Ensure quiz is complete when all answers are selected
  }

  void onSelectedAnswer(String answer, String questionText, int currentQuestionIndex) {
    setState(() {
      selectedAnswer[currentQuestionIndex] = answer;  // Track selected answer for each question
      if (isQuizComplete()) {  // Check if quiz is complete
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
        content: const Text("Do you want to finish your quiz?"),
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
                hasFinished = false; // Reset finish flag after submission
              });
            },
            child: const Text("SUBMIT"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Choose the active screen widget based on the value of activeScreen
    final screenWidget = activeScreen == "start-screen"
        ? StartQuiz(switchScreen)
        : activeScreen == "question-screen"
        ? QuizPageV1(
        selectedAnswers: selectedAnswer,
        onSelectedAnswer: onSelectedAnswer,
        switchResult: switchResult)
        : ResultPageV1(
        switchScreen: switchScreen,
        selectedAnswer: selectedAnswer);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 252, 242, 156),
              const Color.fromARGB(255, 223, 247, 86),
            ],
          ),
        ),
        child: screenWidget,
      ),
    );
  }
}
