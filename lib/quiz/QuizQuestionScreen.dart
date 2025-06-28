import 'package:black_box/data/quiz/questions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/quiz/question.dart';

class QuizQuestionsScreen extends StatefulWidget {
  final String quizId;
  final String studentId;
  const QuizQuestionsScreen({Key? key, required this.quizId, required this.studentId}) : super(key: key);

  @override
  _QuizQuestionsScreenState createState() => _QuizQuestionsScreenState();
}

class _QuizQuestionsScreenState extends State<QuizQuestionsScreen> {
  List<Question> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  // Future<void> _loadQuestions() async {
  //   try {
  //     print("Loading questions where questionTitle is 'a'");
  //
  //     // Fetch questions from Firestore where questionTitle is equal to 'a'
  //     var questionSnapshot = await FirebaseFirestore.instance
  //         .doc(widget.quizId) // Get the specific quiz document by quizId
  //         .collection('questions') // Access the 'questions' subcollection
  //         .where('question_title', isEqualTo: 'a') // Filter questions where questionTitle equals 'a'
  //         .get();
  //
  //     if (questionSnapshot.docs.isEmpty) {
  //       print("No questions found with the title 'a'");
  //     }
  //
  //     // Map the fetched documents to Question objects
  //     setState(() {
  //       _questions = questionSnapshot.docs.map((doc) {
  //         return Question.fromFirestore(doc);
  //       }).toList();
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     print("Error loading questions: $e");
  //     _showError('Error loading questions: $e');
  //   }
  // }


  Future<void> _loadQuestions() async {
    try {
      print("Loading questions for quizId: ${widget.quizId}");

      // Fetch questions from Firestore where quizId matches
      final querySnapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('quiz_id', isEqualTo: widget.quizId)
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
          print("Fetched question: ${data['questionTitle']}");

          // Convert the Firestore document into a Question object
          return Question.fromJson(data);
        })
            .toList();

        questions.clear();
        questions.addAll(_questions);
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading questions: $e");
      _showError('Error loading questions: $e');
    }
  }


  void _submitQuiz() async {
    setState(() {
      _isSubmitting = true;
    });

    // Handle submission logic
    try {
      // Save student answers to Firestore or local database
      for (var question in _questions) {
        // You can save answers here, for example:
        // FirebaseFirestore.instance.collection('student_answers').add({
        //   'studentId': widget.studentId,
        //   'quizId': widget.quizId,
        //   'questionId': question.qId,
        //   'selectedAnswer': question.selectedAnswer,
        // });

        // You can also save answers to a local database if working offline
      }

      // Display success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quiz submitted successfully!')));
    } catch (e) {
      _showError('Error submitting quiz: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Questions'),
        actions: [
          if (_isSubmitting) CircularProgressIndicator(),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          final question = _questions[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text(question.questionTitle),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: question.questionAnswers
                    .map((answer) => RadioListTile<String>(
                  title: Text(answer),
                  value: answer,
                  // groupValue: question.selectedAnswer,
                  onChanged: (value) {
                    setState(() {
                      // question.selectedAnswer = value;
                    });
                  }, groupValue: null,
                ))
                    .toList(),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitQuiz,
        child: Icon(Icons.check),
        tooltip: 'Submit Answers',
      ),
    );
  }
}