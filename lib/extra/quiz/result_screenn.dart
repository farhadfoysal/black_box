import 'package:flutter/material.dart';
import 'models/questionn.dart';

class ResultScreenn extends StatelessWidget {
  final List<Questionn> questions;
  final Map<int, String?> selectedAnswers;
  final int correctCount;
  final int incorrectCount;
  final int uncheckedCount;
  final double percentage;

  ResultScreenn({
    required this.questions,
    required this.selectedAnswers,
    required this.correctCount,
    required this.incorrectCount,
    required this.uncheckedCount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        title: Text('Quiz Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Results",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Correct Answers: $correctCount",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              "Incorrect Answers: $incorrectCount",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              "Unchecked Questions: $uncheckedCount",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              "Your Score: ${percentage.toStringAsFixed(2)}%",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  Questionn question = questions[index];
                  String? selectedAnswer = selectedAnswers[index];
                  bool isCorrect = selectedAnswer == question.correctAnswer;
                  bool isUnchecked = selectedAnswer == null;
                  bool isFavorite = false;

                  return _buildAnswerSheetItem(
                    question: question,
                    selectedAnswer: selectedAnswer,
                    isCorrect: isCorrect,
                    isUnchecked: isUnchecked,
                    isFavorite: isFavorite,
                    onFavoriteToggle: () {
                      // Handle favorite toggle action here
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerSheetItem({
    required Questionn question,
    required String? selectedAnswer,
    required bool isCorrect,
    required bool isUnchecked,
    required bool isFavorite,
    required VoidCallback onFavoriteToggle,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.questionText,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Your Answer: ${selectedAnswer ?? 'Not Answered'}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              "Correct Answer: ${question.correctAnswer}",
              style: TextStyle(fontSize: 16, color: Colors.green),
            ),
            SizedBox(height: 8),
            Text(
              isCorrect ? "Status: Correct" : (isUnchecked ? "Status: Unanswered" : "Status: Incorrect"),
              style: TextStyle(
                fontSize: 16,
                color: isCorrect
                    ? Colors.green
                    : isUnchecked
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: onFavoriteToggle,
                ),
                Text(
                  "Mark as Favorite",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



















// import 'package:flutter/material.dart';
// class ResultScreenn extends StatelessWidget {
//   final int correctCount;
//   final int incorrectCount;
//   final int uncheckedCount;
//   final double percentage;
//
//   ResultScreenn({
//     required this.correctCount,
//     required this.incorrectCount,
//     required this.uncheckedCount,
//     required this.percentage,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.blueAccent,
//         title: Text('Quiz Results'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Your Results",
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 24,
//                 color: Colors.blueAccent,
//               ),
//             ),
//             SizedBox(height: 20),
//             Text(
//               "Correct Answers: $correctCount",
//               style: TextStyle(fontSize: 18),
//             ),
//             SizedBox(height: 10),
//             Text(
//               "Incorrect Answers: $incorrectCount",
//               style: TextStyle(fontSize: 18),
//             ),
//             SizedBox(height: 10),
//             Text(
//               "Unchecked Questions: $uncheckedCount",
//               style: TextStyle(fontSize: 18),
//             ),
//             SizedBox(height: 20),
//             Text(
//               "Your Score: ${percentage.toStringAsFixed(2)}%",
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 22,
//                 color: Colors.blueAccent,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }