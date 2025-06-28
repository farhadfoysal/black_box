import 'package:black_box/quiz/QuizPanel.dart';
import 'package:black_box/quiz/quiz_main_v1.dart';
import 'package:black_box/screen_page/quiz/start_quiz.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

import '../data/quiz/questions.dart';
import '../model/quiz/question.dart';
import '../model/quiz/quiz.dart';
import 'QuizQuestionScreen.dart';
class QuizRoomScreen extends StatefulWidget {
  final String studentId;
  final String phoneNumber;
  const QuizRoomScreen({Key? key, required this.studentId, required this.phoneNumber}) : super(key: key);

  @override
  _QuizRoomScreenState createState() => _QuizRoomScreenState();
}

class _QuizRoomScreenState extends State<QuizRoomScreen> {
  final TextEditingController quizIdController = TextEditingController();
  List<Question> _questions = [];
  Quiz? _currentQuiz;

  Future<void> _enterQuizRoom() async {
    String quizId = quizIdController.text;

    if (quizId.isEmpty) {
      _showError('Please enter a quiz ID');
      return;
    }

    try {
      // Check if quiz exists in Firestore
      var quizSnapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId)
          .get();

      if (!quizSnapshot.exists) {
        _showError('Quiz not found');
      } else {
        // Navigate to quiz questions screen
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => QuizQuestionsScreen(
        //       quizId: quizId,
        //       studentId: widget.studentId,
        //     ),
        //   ),
        // );

        final data = quizSnapshot.data();
        if (data == null) {
          _showError('Quiz data is empty');
          return;
        }

        _currentQuiz = Quiz.fromJson(data);

        await _loadQuestions(quizId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizPanel(studentId: widget.studentId, phoneNumber: widget.phoneNumber, quiz: _currentQuiz!,),
          ),
        );
      }
    } catch (e) {
      _showError('Error entering quiz room: $e');
    }
  }

  Future<void> _loadQuestions(String quizId) async {
    try {
      print("Loading questions for quizId: ${quizId}");

      // Fetch questions from Firestore where quizId matches
      final querySnapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('quiz_id', isEqualTo: quizId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("No questions found for this quiz");
      }

      // Map the fetched documents to Question objects
      setState(() {
        _questions = querySnapshot.docs
            .map((doc) {
          // Check if the document contains the expected fields
          final data = doc.data() as Map<String, dynamic>;
          // print("Fetched question: ${data['questionTitle']}");

          // Convert the Firestore document into a Question object
          return Question.fromJson(data);
        })
            .toList();

        questions.clear();
        questions.addAll(_questions);



      });
    } catch (e) {
      print("Error loading questions: $e");
      _showError('Error loading questions: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF), // soft light background
      appBar: AppBar(
        title: const Text('Enter Quiz Room'),
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Lottie.asset(
                  'animation/ (7).json', // Your lottie file here
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                controller: quizIdController,
                label: 'Quiz ID',
                hintText: 'Enter the Quiz ID',
                icon: Icons.vpn_key_outlined,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _enterQuizRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black45,
                  ),
                  child: const Text(
                    'Enter Quiz',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Color(0xFF6C63FF)),
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(color: Color(0xFF6C63FF)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: Text('Enter Quiz Room')),
  //     body: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         children: [
  //           TextField(
  //             controller: quizIdController,
  //             decoration: InputDecoration(labelText: 'Quiz ID'),
  //           ),
  //           SizedBox(height: 20),
  //           ElevatedButton(
  //             onPressed: _enterQuizRoom,
  //             child: Text('Enter Quiz'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
