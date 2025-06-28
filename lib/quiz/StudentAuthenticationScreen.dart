import 'package:black_box/quiz/quiz_main_v1.dart';
import 'package:black_box/screen_page/quiz/start_quiz.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

import '../data/quiz/questions.dart';
import '../model/quiz/question.dart';
import 'QuizQuestionScreen.dart';
import 'QuizRoomScreen.dart';

class StudentAuthenticationScreen extends StatefulWidget {
  @override
  _StudentAuthenticationScreenState createState() => _StudentAuthenticationScreenState();
}

class _StudentAuthenticationScreenState extends State<StudentAuthenticationScreen> {
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> _authenticateStudent() async {
    String studentId = studentIdController.text;
    String phoneNumber = phoneNumberController.text;

    if (studentId.isEmpty || phoneNumber.isEmpty) {
      _showError('Please enter both student ID and phone number');
      return;
    }

    try {
      // Check if student exists in Firestore
      var studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('studentId', isEqualTo: studentId)
          .where('phone', isEqualTo: phoneNumber)
          .get();

      if (studentSnapshot.docs.isEmpty) {
        _showError('Student not found');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizRoomScreen(studentId: studentId,phoneNumber: phoneNumber),
          ),
        );
      } else {
        // Navigate to quiz room if student is valid
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizRoomScreen(studentId: studentId,phoneNumber: phoneNumber),
          ),
        );
      }
    } catch (e) {
      _showError('Error authenticating student: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light elegant background
      appBar: AppBar(
        title: const Text('Student Authentication'),
        backgroundColor: const Color(0xFF6C63FF), // Beautiful purple tone
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Lottie animation in center
              Center(
                child: Lottie.asset(
                  'animation/ (6).json', // Put your lottie file here
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: studentIdController,
                      label: 'Student ID',
                      hintText: 'Enter your student ID',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: phoneNumberController,
                      label: 'Phone Number',
                      hintText: 'Enter your phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _authenticateStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: Colors.black38,
                        ),
                        child: const Text(
                          'Enter Quiz Room',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please fill out this field';
        }
        return null;
      },
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: Text('Student Authentication')),
  //     body: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Form(
  //         key: _formKey,
  //         child: Column(
  //           children: [
  //             TextFormField(
  //               controller: studentIdController,
  //               decoration: InputDecoration(labelText: 'Student ID'),
  //               validator: (value) {
  //                 if (value == null || value.isEmpty) {
  //                   return 'Please enter your student ID';
  //                 }
  //                 return null;
  //               },
  //             ),
  //             TextFormField(
  //               controller: phoneNumberController,
  //               decoration: InputDecoration(labelText: 'Phone Number'),
  //               validator: (value) {
  //                 if (value == null || value.isEmpty) {
  //                   return 'Please enter your phone number';
  //                 }
  //                 return null;
  //               },
  //             ),
  //             SizedBox(height: 20),
  //             ElevatedButton(
  //               onPressed: _authenticateStudent,
  //               child: Text('Enter Quiz Room'),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}