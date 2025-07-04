import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GKQuizPage extends StatelessWidget {
  const GKQuizPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GK Quizzes')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Start Quiz'),
          onPressed: () {
            // TODO: launch quiz flow
          },
        ),
      ),
    );
  }
}
