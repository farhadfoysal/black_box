// attempt_exam_page.dart
import 'package:black_box/screen_page/exam/widget/question_card.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../model/exam/exam_model.dart';
import '../../model/exam/question_model.dart';

class AttemptExamPage extends StatefulWidget {
  final ExamModel exam;

  const AttemptExamPage({Key? key, required this.exam}) : super(key: key);

  @override
  _AttemptExamPageState createState() => _AttemptExamPageState();
}

class _AttemptExamPageState extends State<AttemptExamPage> {
  final PageController _pageController = PageController();
  final Map<int, String> _answers = {};
  int _currentPage = 0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.exam.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3A7BD5),
                Color(0xFF00D2FF),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentPage + 1}/${widget.exam.questions?.length ?? 0}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: widget.exam.questions != null && widget.exam.questions!.isNotEmpty
                ? (_currentPage + 1) / widget.exam.questions!.length
                : 0,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3A7BD5)),
            minHeight: 4,
          ),

          // Questions
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.exam.questions?.length ?? 0,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final question = widget.exam.questions![index];
                return SingleChildScrollView(
                  child: QuestionCard(
                    question: question,
                    questionNumber: index + 1,
                    onAnswerSelected: (answer) {
                      _answers[index] = answer!;
                    },
                  ),
                );
              },
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF3A7BD5)),
                      ),
                      child: const Text(
                        'Previous',
                        style: TextStyle(
                          color: Color(0xFF3A7BD5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                      if (_currentPage < (widget.exam.questions?.length ?? 0) - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _submitExam();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A7BD5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      _currentPage < (widget.exam.questions?.length ?? 0) - 1
                          ? 'Next'
                          : 'Submit Exam',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitExam() async {
    setState(() {
      _isSubmitting = true;
    });

    // Here you would typically send the answers to your backend
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    setState(() {
      _isSubmitting = false;
    });

    // Show result dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Exam Submitted'),
        content: const Text('Your exam has been submitted successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}