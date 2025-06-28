import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../db/firebase/QuizFirebaseService.dart';
import '../db/quiz/quiz_db_helper.dart';
import '../model/quiz/quiz.dart';
import '../utility/unique.dart';
import 'QuestionManagementPage.dart';

class AdminQuizManagerPage extends StatelessWidget {
  const AdminQuizManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FC), // Soft background
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Quiz Manager',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AdminOptionCard(
              title: "Manage Quizzes",
              subtitle: "Create, Edit, Delete Quizzes",
              icon: Icons.quiz,
              color: Colors.deepPurple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuizManagementPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            AdminOptionCard(
              title: "Manage Questions",
              subtitle: "Add, Edit, Delete Questions",
              icon: Icons.question_answer,
              color: Colors.indigo,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuestionManagementPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdminOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const AdminOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizManagementPage extends StatefulWidget {
  const QuizManagementPage({super.key});

  @override
  _QuizManagementPageState createState() => _QuizManagementPageState();
}

class _QuizManagementPageState extends State<QuizManagementPage> {
  final _quizNameController = TextEditingController();
  final _quizDescriptionController = TextEditingController();
  final _quizMinutesController = TextEditingController();
  final _quizSubjectController = TextEditingController();
  bool _isLoading = false;

  // Create and save quiz locally and online
  void _createQuiz() async {
    String uniqueId = Unique().generateUniqueID();
    final quiz = Quiz(
      quizName: _quizNameController.text,
      quizDescription: _quizDescriptionController.text,
      createdAt: DateTime.now().toIso8601String(),
      qId: uniqueId, // Firebase will assign the qId
      minutes: int.tryParse(_quizMinutesController.text) ?? 1,
      status: 1,
      type: 1,
      subject: _quizNameController.text ?? "all"
    ,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      // Save quiz online (Firebase) and get the generated qId
      Quiz firebaseQuiz = await QuizFirebaseService().addOrUpdateQuiz(quiz);

      // Update local quiz with the Firebase generated ID
      quiz.qId = firebaseQuiz.qId;

      // Save quiz locally (SQLite) with the qId
      await QuizDBHelper.insertQuiz(quiz);

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz Created Successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("f$e");
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create quiz. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: const Text('Create Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Lottie animation at top
            SizedBox(
              height: 200,
              child: Lottie.asset('animation/ (9).json'), // Make sure you have a lottie file!
            ),
            const SizedBox(height: 30),

            // Quiz Name Field
            TextField(
              controller: _quizNameController,
              decoration: InputDecoration(
                labelText: 'Quiz Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.text_fields, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Quiz Description Field
            TextField(
              controller: _quizDescriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Quiz Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.description, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Minutes Field
            TextField(
              controller: _quizMinutesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Duration (Minutes)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.timer, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Quiz Name Field
            TextField(
              controller: _quizSubjectController,
              decoration: InputDecoration(
                labelText: 'Quiz Subject',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.text_fields, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // Create Quiz Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _createQuiz,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Create Quiz',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Create Quiz'),
  //       backgroundColor: Colors.deepPurple,
  //     ),
  //     body: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         children: [
  //           TextField(
  //             controller: _quizNameController,
  //             decoration: const InputDecoration(labelText: 'Quiz Name'),
  //           ),
  //           const SizedBox(height: 20),
  //           TextField(
  //             controller: _quizDescriptionController,
  //             decoration: const InputDecoration(labelText: 'Quiz Description'),
  //           ),
  //           const SizedBox(height: 20),
  //           ElevatedButton(
  //             onPressed: _isLoading ? null : _createQuiz,
  //             child: _isLoading
  //                 ? const CircularProgressIndicator()
  //                 : const Text('Create Quiz'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}


// class QuestionManagementPage extends StatelessWidget {
//   const QuestionManagementPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Question Management'),
//         backgroundColor: Colors.indigo,
//       ),
//       body: const Center(
//         child: Text('Add/Edit/Delete Questions Here', style: TextStyle(fontSize: 20)),
//       ),
//     );
//   }
// }
