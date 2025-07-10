import 'package:black_box/db/exam/quiz_result_dao.dart';
import 'package:black_box/db/firebase/QuizFirestoreHelper.dart';
import 'package:black_box/db/firebase/exam_result_firebase_service.dart';
import 'package:black_box/db/local/QuizResultDBHelper.dart';
import 'package:black_box/model/exam/exam_model.dart';
import 'package:black_box/model/exam/quiz_result_model.dart';
import 'package:flutter/material.dart';
import '../../data/quiz/questions.dart';
import '../../model/user/user.dart';

class ExamResultScreen extends StatefulWidget {
  final void Function() switchScreen;
  final Map<int, String> selectedAnswer; // Changed to non-nullable String
  final User user;
  final ExamModel quiz;

  const ExamResultScreen({
    super.key,
    required this.switchScreen,
    required this.selectedAnswer, required this.user, required this.quiz,
  });

  @override
  State<ExamResultScreen> createState() => _QuizResultState();
}

class _QuizResultState extends State<ExamResultScreen> {
  List<QuestionResult> selectedAnswers = [];
  int correctCount = 0;
  int incorrectCount = 0;
  int uncheckedCount = 0;
  double percentage = 0;

  // Calculate the percentage based on correct answers
  double getPercentage() {
    int correctCount = selectedAnswers.where((result) => result.isCorrect).length;
    return (correctCount / selectedAnswers.length) * 100;
  }

  // Get the count of correct answers
  int getCorrectCount() {
    return selectedAnswers.where((result) => result.isCorrect).length;
  }

  // Get the count of incorrect answers
  int getIncorrectCount() {
    return selectedAnswers.where((result) => !result.isCorrect).length;
  }

  // Get the count of unanswered questions
  int getUncheckedCount() {
    return selectedAnswers.where((result) => result.selectedAnswer.isEmpty).length;
  }

  // Generate the summary of quiz results
  List<Map<String, Object>> getQuizSummary() {
    final List<Map<String, Object>> summary = [];

    for (var i = 0; i < selectedAnswers.length; i++) {
      summary.add({
        'question_number': i + 1,
        'question_title': widget.quiz.questions![i].questionTitle,
        'correct_answer': widget.quiz.questions![i].questionAnswers[0],
        'selected_answer': selectedAnswers[i].selectedAnswer,
        'color': selectedAnswers[i].isCorrect ? Colors.greenAccent : Colors.redAccent
      });
    }

    return summary;
  }

  // Populate the selected answers for each question
  void getResult() {
    for (var i = 0; i < widget.quiz.questions!.length; i++) {
      // for (var i = 0; i < widget.selectedAnswer.length; i++) {

      selectedAnswers.add(
        QuestionResult(
          questionText: widget.quiz.questions![i].questionTitle,
          selectedAnswer: widget.selectedAnswer[i] ?? '', // Use an empty string if the selected answer is null
          correctAnswer: widget.quiz.questions![i].questionAnswers[0],
          explanation: widget.quiz.questions![i].explanation,
          isUnChecked: widget.selectedAnswer[i] == null,
          isCorrect: widget.selectedAnswer[i] == widget.quiz.questions![i].questionAnswers[0],
        ),
      );
    }
  }

  void saveResult() async {
    // Create a QuizResult object with the necessary details
    final quizResult = QuizResultModel(
      studentId: widget.user.userid!,
      phoneNumber: widget.user.phone,
      quizId: widget.quiz.uniqueId,         // assuming your Quiz/ExamModel has an 'id' property
      quizName: widget.quiz.title,     // assuming your Quiz/ExamModel has a 'name' property
      correctCount: getCorrectCount(),
      incorrectCount: getIncorrectCount(),
      uncheckedCount: getUncheckedCount(),
      percentage: getPercentage(),
      timestamp: DateTime.now(),
    );


    try {

      await QuizResultFirebaseService().addQuizResult(quizResult);
      print('Quiz result saved to Firestore');


      await QuizResultDAO().insertResult(quizResult);
      print('Quiz result saved to SQLite');

    } catch (e) {
      print('Error saving quiz result: $e');
    }
  }


  @override
  void initState() {
    super.initState();
    getResult();
    saveResult();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            const Text(
              "Results",
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Score: ${getPercentage().toStringAsFixed(2)}% Correct: ${getCorrectCount()} | NOT: ${getIncorrectCount()} | UN: ${getUncheckedCount()}",
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: selectedAnswers.length,
          itemBuilder: (context, index) {
            final question = selectedAnswers[index];
            return ResultCard(
              question: question,
              onFavoriteToggle: () {
                setState(() {
                  question.isFavorite = !question.isFavorite;
                });
              },
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: widget.switchScreen,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
          child: const Text(
            "Retake Quiz",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}


class ResultCard extends StatelessWidget {
  final QuestionResult question;
  final VoidCallback onFavoriteToggle;

  const ResultCard({
    Key? key,
    required this.question,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text( question.isUnChecked
                ? "UNCHECKED" :
            "Your Answer: ${question.selectedAnswer}",
              style: TextStyle(
                fontSize: 16,
                color: question.isCorrect ? Colors.green : question.isUnChecked
                    ? Colors.orange : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Correct Answer: ${question.correctAnswer}",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Explanation: ${question.explanation}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onFavoriteToggle,
                icon: Icon(
                  question.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: question.isFavorite ? Colors.red : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuestionResult {
  final String questionText;
  final String selectedAnswer;
  final String correctAnswer;
  final String explanation;
  bool isUnChecked;
  bool isCorrect;
  bool isFavorite;

  QuestionResult({
    required this.questionText,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.explanation,
    required this.isUnChecked,
    required this.isCorrect,
    this.isFavorite = false,
  });
}
