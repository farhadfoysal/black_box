import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:sqflite/sqflite.dart';
import '../db/firebase/QuestionFirebaseService.dart';
import '../db/firebase/QuizFirebaseService.dart';
import '../db/quiz/quiz_db_helper.dart';
import '../model/quiz/question.dart';
import '../model/quiz/quiz.dart';
import 'QuestionManagementDetailPage.dart';

class QuestionManagementPage extends StatefulWidget {
  const QuestionManagementPage({super.key});

  @override
  _QuestionManagementPageState createState() =>
      _QuestionManagementPageState();
}

class _QuestionManagementPageState extends State<QuestionManagementPage> {
  bool _isLoading = false;
  List<Quiz> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  // Load quizzes from SQLite and Firebase
  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch quizzes from SQLite
      List<Quiz> localQuizzes = await QuizDBHelper.getQuizzes();

      // Fetch quizzes from Firebase
      List<Quiz> firebaseQuizzes = await QuizFirebaseService().getAllQuizzes();

      // Combine quizzes from both sources
      setState(() {
        _quizzes = [...localQuizzes, ...firebaseQuizzes];
      });
    } catch (e) {
      print("Error loading quizzes: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Delete quiz from both SQLite and Firebase
  Future<void> _deleteQuiz(String quizId) async {
    try {
      // Delete from SQLite
      await QuizDBHelper.deleteQuizByUId(quizId);

      // Delete from Firebase
      await QuizFirebaseService().deleteQuiz(quizId);

      // Reload quizzes
      _loadQuizzes();
    } catch (e) {
      print("Error deleting quiz: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quizzes'),
        backgroundColor: Colors.deepPurple, // Elegant dark purple
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Lottie.asset(
          'animation/ (1).json', // Your Lottie loading animation
          height: 120,
        ),
      )
          : _quizzes.isEmpty
          ? Center(child: Text("No quizzes available.", style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
        itemCount: _quizzes.length,
        itemBuilder: (context, index) {
          final quiz = _quizzes[index];
          return Dismissible(
            key: Key(quiz.qId),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _deleteQuiz(quiz.qId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${quiz.quizName} deleted')),
              );
            },
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  quiz.quizName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                subtitle: Text(quiz.quizDescription, style: TextStyle(color: Colors.grey[600])),
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
                  onPressed: () {
                    // Navigate to the question management page for this quiz
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuestionManagementDetailPage(quiz: quiz),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Manage Quizzes'),
  //       backgroundColor: Colors.indigo,
  //     ),
  //     body: _isLoading
  //         ? const Center(child: CircularProgressIndicator())
  //         : ListView.builder(
  //       itemCount: _quizzes.length,
  //       itemBuilder: (context, index) {
  //         final quiz = _quizzes[index];
  //         return Dismissible(
  //           key: Key(quiz.qId),
  //           direction: DismissDirection.endToStart,
  //           onDismissed: (direction) {
  //             _deleteQuiz(quiz.qId);
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               SnackBar(content: Text('${quiz.quizName} deleted')),
  //             );
  //           },
  //           background: Container(
  //             color: Colors.red,
  //             alignment: Alignment.centerRight,
  //             padding: const EdgeInsets.only(right: 20.0),
  //             child: const Icon(Icons.delete, color: Colors.white),
  //           ),
  //           child: Card(
  //             margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
  //             elevation: 4,
  //             child: ListTile(
  //               contentPadding: const EdgeInsets.all(16),
  //               title: Text(
  //                 quiz.quizName,
  //                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //               ),
  //               subtitle: Text(quiz.quizDescription),
  //               trailing: IconButton(
  //                 icon: const Icon(Icons.arrow_forward, color: Colors.indigo),
  //                 onPressed: () {
  //                   // Navigate to the question management page for this quiz
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => QuestionManagementDetailPage(quiz: quiz),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }
}

// class QuestionManagementDetailPage extends StatefulWidget {
//   final Quiz quiz;
//   const QuestionManagementDetailPage({super.key, required this.quiz});
//
//   @override
//   _QuestionManagementDetailPageState createState() =>
//       _QuestionManagementDetailPageState();
// }
//
// class _QuestionManagementDetailPageState
//     extends State<QuestionManagementDetailPage> {
//   bool _isLoading = false;
//   List<Question> _questions = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadQuestions();
//   }
//
//   // Load questions for the selected quiz
//   Future<void> _loadQuestions() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       // Fetch questions from Firebase
//       List<Question> firebaseQuestions =
//       await QuestionFirebaseService().getQuestionsByQuizId(widget.quiz.qId);
//
//       // Combine questions from Firebase
//       setState(() {
//         _questions = firebaseQuestions;
//       });
//     } catch (e) {
//       print("Error loading questions: $e");
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   // Delete question from Firebase
//   Future<void> _deleteQuestion(String questionId) async {
//     try {
//       await QuestionFirebaseService().deleteQuestion(questionId);
//
//       // Reload questions
//       _loadQuestions();
//     } catch (e) {
//       print("Error deleting question: $e");
//     }
//   }
//
//   // Add new question for the selected quiz
//   Future<void> _addQuestion() async {
//     final question = Question(
//       qId: '',
//       quizId: widget.quiz.qId,
//       questionTitle: 'New Question', // Replace with actual input from user
//       questionAnswers: ['Option 1', 'Option 2'], // Replace with actual input from user
//       explanation: 'Explanation here', // Replace with actual input from user
//       source: 'Source here', // Replace with actual input from user
//     );
//
//     try {
//       await QuestionFirebaseService().addOrUpdateQuestion(question);
//
//       // Reload questions
//       _loadQuestions();
//     } catch (e) {
//       print("Error adding question: $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${widget.quiz.quizName} - Questions'),
//         backgroundColor: Colors.indigo,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           ElevatedButton(
//             onPressed: _addQuestion,
//             child: const Text('Add New Question'),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: _questions.length,
//               itemBuilder: (context, index) {
//                 final question = _questions[index];
//                 return Dismissible(
//                   key: Key(question.qId ?? ''),
//                   direction: DismissDirection.endToStart,
//                   onDismissed: (direction) {
//                     _deleteQuestion(question.qId ?? '');
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Question deleted')),
//                     );
//                   },
//                   background: Container(
//                     color: Colors.red,
//                     alignment: Alignment.centerRight,
//                     padding: const EdgeInsets.only(right: 20.0),
//                     child: const Icon(Icons.delete, color: Colors.white),
//                   ),
//                   child: Card(
//                     margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//                     elevation: 4,
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.all(16),
//                       title: Text(question.questionTitle),
//                       subtitle: Text('Options: ${question.questionAnswers.join(", ")}'),
//                       trailing: IconButton(
//                         icon: const Icon(Icons.delete, color: Colors.red),
//                         onPressed: () {
//                           _deleteQuestion(question.qId ?? '');
//                         },
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
