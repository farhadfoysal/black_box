import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/question1.dart';

class QuizS extends StatelessWidget {
  final List<Question1> questions;

  QuizS({required this.questions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz')),
      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          return QuestionWidget(question: question);
        },
      ),
    );
  }
}

class QuestionWidget extends StatelessWidget {
  final Question1 question;

  QuestionWidget({required this.question});

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuestionType.mcq:
        return MCQWidget(question: question);
      case QuestionType.text:
        return TextQuestionWidget(question: question);
      case QuestionType.image:
        return ImageQuestionWidget(question: question);
      case QuestionType.url:
      case QuestionType.driveLink:
        return LinkQuestionWidget(question: question);
      default:
        return SizedBox.shrink();
    }
  }
}
class MCQWidget extends StatelessWidget {
  final Question1 question;

  MCQWidget({required this.question});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.questionText),
        ...?question.options?.map((option) => RadioListTile(
          title: Text(option),
          value: option,
          groupValue: null, // Manage with state
          onChanged: (value) {
            // Save answer
          },
        )),
      ],
    );
  }
}
class TextQuestionWidget extends StatelessWidget {
  final Question1 question;

  TextQuestionWidget({required this.question});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.questionText),
        TextField(
          onChanged: (value) {
            // Save answer
          },
        ),
      ],
    );
  }
}
class ImageQuestionWidget extends StatelessWidget {
  final Question1 question;

  ImageQuestionWidget({required this.question});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(question.questionText),
        if (question.mediaUrl != null) Image.network(question.mediaUrl!),
      ],
    );
  }
}
class LinkQuestionWidget extends StatelessWidget {
  final Question1 question;

  LinkQuestionWidget({required this.question});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.questionText),
        if (question.mediaUrl != null)
          GestureDetector(
            onTap: () {
              // Open link
            },
            child: Text(
              'Open Link',
              style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
            ),
          ),
      ],
    );
  }
}
class OptionsWidget extends StatelessWidget {
  final Question1 question;

  OptionsWidget({required this.question});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.questionText),
        if (question.mediaUrl != null && question.type != QuestionType.text)
          MediaDisplayWidget(mediaUrl: question.mediaUrl!, type: question.type),
        ...?question.options?.map((option) => RadioListTile(
          title: Text(option),
          value: option,
          groupValue: null, // Manage state to track selected option
          onChanged: (value) {
            // Save answer
          },
        )),
      ],
    );
  }
}

class MediaDisplayWidget extends StatelessWidget {
  final String mediaUrl;
  final QuestionType type;

  MediaDisplayWidget({required this.mediaUrl, required this.type});

  @override
  Widget build(BuildContext context) {
    if (type == QuestionType.image) {
      return Image.network(mediaUrl);
    } else if (type == QuestionType.driveLink || type == QuestionType.url) {
      return GestureDetector(
        onTap: () async {
          await _launchUrl(mediaUrl, context);
        },
        child: Container(
          padding: EdgeInsets.all(8.0),
          color: Colors.blue,
          child: Text(
            'Open File',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  // Method to launch the URL
  Future<void> _launchUrl(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Show a Snackbar if the URL cannot be opened
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open link: $url')),
      );
    }
  }
}

class TextInputWidget extends StatelessWidget {
  final Question1 question;

  TextInputWidget({required this.question});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.questionText),
        TextField(
          onChanged: (value) {
            // Save answer
          },
          decoration: InputDecoration(
            hintText: 'Enter your answer here',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
// class QuizScreen extends StatelessWidget {
//   final List<Question> questions;
//
//   QuizScreen({required this.questions});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Quiz')),
//       body: ListView.builder(
//         itemCount: questions.length,
//         itemBuilder: (context, index) {
//           final question = questions[index];
//           if (question.type == QuestionType.text) {
//             return TextInputWidget(question: question);
//           } else {
//             return OptionsWidget(question: question);
//           }
//         },
//       ),
//     );
//   }
// }


// Future<List<Question1>> fetchQuestions(String quizId) async {
//   final querySnapshot = await FirebaseFirestore.instance
//       .collection('questions')
//       .where('quizId', isEqualTo: quizId)
//       .get();
//
//   return querySnapshot.docs
//       .map((doc) => Question1.fromJson(doc.data()))
//       .toList();
// }

// FirebaseFirestore.instance.collection('questions').where('quizId', isEqualTo: quizId).get();
// FirebaseFirestore.instance.collection('userAnswers').add(userAnswer.toJson());

