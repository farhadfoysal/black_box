import 'package:black_box/extra/quiz/result_screenn.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the time
import 'dart:async'; // For timer functionality

import 'models/questionn.dart';
import 'models/quizz.dart';
import 'models/userr.dart';

class QuizScreenn extends StatefulWidget {
  final Userr user;
  final Quizz quiz;

  QuizScreenn({required this.user, required this.quiz});

  @override
  _QuizScreennState createState() => _QuizScreennState();
}

class _QuizScreennState extends State<QuizScreenn> {
  Map<int, String?> selectedAnswers = {};
  late int remainingTime; // Timer in seconds
  late Timer _timer; // Timer instance

  @override
  void initState() {
    super.initState();
    // Initialize the timer from the quiz time in minutes, convert to seconds
    remainingTime = widget.quiz.times * 60;
    _startTimer();
  }

  // Start the countdown timer
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        _timer.cancel();
        // Handle the time up condition, e.g., submit the answers or show a dialog
      }
    });
  }

  // Format the time for displaying (e.g., 59:41)
  String get formattedTime {
    int minutes = remainingTime ~/ 60;
    int seconds = remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _submitQuiz() {
    int correctCount = 0;
    int incorrectCount = 0;
    int uncheckedCount = 0;

    for (int i = 0; i < widget.quiz.questions.length; i++) {
      Questionn question = widget.quiz.questions[i];
      String? selectedAnswer = selectedAnswers[i];

      if (selectedAnswer == null) {
        uncheckedCount++;
      } else if (selectedAnswer == question.correctAnswer) {
        correctCount++;
      } else {
        incorrectCount++;
      }
    }

    // Calculate the percentage of correct answers
    double percentage = (correctCount / widget.quiz.questions.length) * 100;

    // Navigate to the result screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreenn(
          questions: widget.quiz.questions,
          selectedAnswers: selectedAnswers,
          correctCount: correctCount,
          incorrectCount: incorrectCount,
          uncheckedCount: uncheckedCount,
          percentage: percentage,
        ),
      ),
    );

  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the screen is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        title: Text(
          widget.user.email,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.red,
              child: Text(
                '0', // Add unread notifications count here
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blueAccent,
            child: Column(
              children: [
                Text(
                  widget.quiz.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.help_outline, color: Colors.white),
                        Text(
                          "মোট প্রশ্ন",
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          widget.quiz.questions.length.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.timer, color: Colors.white),
                        Text(
                          "সময়",
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          formattedTime, // Show formatted time here
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.alarm, color: Colors.white),
                        Text(
                          "সময় বাকি",
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          formattedTime, // Same formatted time for remaining time
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: widget.quiz.questions.asMap().entries.map((entry) {
                int index = entry.key;
                Questionn question = entry.value;
                return _buildQuestion(
                  question: question,
                  questionIndex: index,
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _submitQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "সাবমিট করুন",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: "চাকরি",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: "এডুকেশন",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "হোম",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "সার্চ করুন",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: "আরও",
          ),
        ],
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildQuestion({
    required Questionn question,
    required int questionIndex,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        ...question.options.map(
              (option) => RadioListTile<String>(
            value: option,
            groupValue: selectedAnswers[questionIndex],
            onChanged: (value) {
              setState(() {
                selectedAnswers[questionIndex] = value;
              });
            },
            title: Text(option),
          ),
        ),
        Divider(),
      ],
    );
  }
}





// import 'package:flutter/material.dart';
//
// import 'models/questionn.dart';
// import 'models/quizz.dart';
// import 'models/userr.dart';
//
//
// class QuizScreenn extends StatefulWidget {
//   final Userr user;
//   final Quizz quiz;
//
//   QuizScreenn({required this.user, required this.quiz});
//
//   @override
//   _QuizScreennState createState() => _QuizScreennState();
// }
//
// class _QuizScreennState extends State<QuizScreenn> {
//   // Map to track the selected answers for each question
//   Map<int, String?> selectedAnswers = {};
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.blueAccent,
//         title: Text(
//           widget.user.email,
//           style: TextStyle(fontSize: 16),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: CircleAvatar(
//               backgroundColor: Colors.red,
//               child: Text(
//                 '0', // Add unread notifications count here
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Container(
//             padding: EdgeInsets.all(16),
//             color: Colors.blueAccent,
//             child: Column(
//               children: [
//                 Text(
//                   widget.quiz.title,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 20,
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     Column(
//                       children: [
//                         Icon(Icons.help_outline, color: Colors.white),
//                         Text(
//                           "মোট প্রশ্ন",
//                           style: TextStyle(color: Colors.white),
//                         ),
//                         Text(
//                           widget.quiz.questions.length.toString(),
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     Column(
//                       children: [
//                         Icon(Icons.timer, color: Colors.white),
//                         Text(
//                           "সময়",
//                           style: TextStyle(color: Colors.white),
//                         ),
//                         Text(
//                           "60 মি.",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     Column(
//                       children: [
//                         Icon(Icons.alarm, color: Colors.white),
//                         Text(
//                           "সময় বাকি",
//                           style: TextStyle(color: Colors.white),
//                         ),
//                         Text(
//                           "-59:41 মি.",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.all(16),
//               children: widget.quiz.questions.asMap().entries.map((entry) {
//                 int index = entry.key;
//                 Questionn question = entry.value;
//                 return _buildQuestion(
//                   question: question,
//                   questionIndex: index,
//                 );
//               }).toList(),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: ElevatedButton(
//               onPressed: () {
//                 // Handle the submit logic here
//                 print(selectedAnswers);
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blueAccent,
//                 padding: EdgeInsets.symmetric(vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: Text(
//                 "সাবমিট করুন",
//                 style: TextStyle(fontSize: 18),
//               ),
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.work),
//             label: "চাকরি",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.school),
//             label: "এডুকেশন",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: "হোম",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.search),
//             label: "সার্চ করুন",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.more_horiz),
//             label: "আরও",
//           ),
//         ],
//         selectedItemColor: Colors.blueAccent,
//         unselectedItemColor: Colors.grey,
//       ),
//     );
//   }
//
//   Widget _buildQuestion({
//     required Questionn question,
//     required int questionIndex,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           question.questionText,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         SizedBox(height: 8),
//         ...question.options.map(
//               (option) => RadioListTile<String>(
//             value: option,
//             groupValue: selectedAnswers[questionIndex],
//             onChanged: (value) {
//               setState(() {
//                 selectedAnswers[questionIndex] = value;
//               });
//             },
//             title: Text(option),
//           ),
//         ),
//         Divider(),
//       ],
//     );
//   }
// }
