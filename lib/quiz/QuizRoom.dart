import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../data/quiz/questions.dart';
import '../model/quiz/quiz.dart';
import '../utility/player/VideoPlayerWidget.dart';
import '../utility/player/YoutubePlayerWidget.dart';

class QuizRoom extends StatefulWidget {
  final void Function(
          String answer, String questionText, int currentQuestionIndex)
      onSelectedAnswer;
  final Map<int, String> selectedAnswers;
  final void Function() switchResult;
  final String studentId;
  final String phoneNumber;
  final Quiz quiz;
  const QuizRoom({
    super.key,
    required this.onSelectedAnswer,
    required this.selectedAnswers,
    required this.switchResult,
    required this.studentId,
    required this.phoneNumber,
    required this.quiz,
  });

  @override
  State<QuizRoom> createState() => _QuizRoomState();
}

class _QuizRoomState extends State<QuizRoom> {
  var currentQuestionIndex = 0;
  List<String> _shuffledAnswers = [];
  bool hasFinished = false;
  Map<int, String?> selectedAnswersMap =
      {}; // Stores selected answers by question index
  Map<String, String> selectedAnswersMapTwo = {};

  late Timer _timer;
  int _remainingSeconds = 60;

  void getQuestion() {
    _shuffledAnswers = questions[currentQuestionIndex].getShuffledAnswers();
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _remainingSeconds = widget.quiz.minutes * 60;
    });
    getQuestion();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer.cancel();
        _onTimeUp();
      }
    });
  }

  void answerQuestion(String answer, String questionText, int index) {
    setState(() {
      if (currentQuestionIndex < questions.length) {
        if (!selectedAnswersMap.containsKey(currentQuestionIndex)) {
          selectedAnswersMap[currentQuestionIndex] = answer;
          widget.onSelectedAnswer(answer, questionText, index);
          currentQuestionIndex++;
        }
      }

      if (currentQuestionIndex < questions.length) {
        _shuffledAnswers = questions[currentQuestionIndex].getShuffledAnswers();
      } else {
        setState(() {
          finishedExam(context);
        });
      }
    });
  }

  void nextQuestion(int n) {
    setState(() {
      currentQuestionIndex = (currentQuestionIndex + n) % questions.length;
      if (currentQuestionIndex < questions.length) {
        _shuffledAnswers = questions[currentQuestionIndex].getShuffledAnswers();
      } else {
        setState(() {
          finishedExam(context);
        });
      }
    });
  }

  void prevQuestion(int n) {
    setState(() {
      currentQuestionIndex =
          (currentQuestionIndex - n + questions.length) % questions.length;
      if (currentQuestionIndex < questions.length) {
        _shuffledAnswers = questions[currentQuestionIndex].getShuffledAnswers();
      } else {
        setState(() {
          finishedExam(context);
        });
      }
    });
  }

  void finishedExam(BuildContext context) {
    if (hasFinished) return;

    // Show confirmation dialog
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent closing the dialog by tapping outside
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.all(16.0),
          title: Center(
            child: Text(
              'Are you sure you want to finish the exam?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie animation for confirmation
              Lottie.asset(
                'animation/10.json', // Your Lottie animation path
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 20),
              // Confirmation message
              Text(
                'Once you finish, you cannot change your answers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 16,
                ),
              ),
            ),
            // Confirm Button
            TextButton(
              onPressed: () {
                // Set hasFinished to true and switch to result screen
                setState(() {
                  hasFinished = true;
                });
                widget
                    .switchResult(); // Call the switchResult function to navigate
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                'Finish Exam',
                style: TextStyle(
                  color: Colors.green[600],
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // void finishedExam() {
  //   if (hasFinished) return;
  //   hasFinished = true;
  //   widget.switchResult();
  // }

  void _onTimeUp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Time's Up!"),
        content: const Text("You ran out of time for this question."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.switchResult();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  int getCorrectCount() {
    return selectedAnswersMap.values
        .where((answer) =>
            answer == questions[currentQuestionIndex].questionAnswers[0])
        .length;
  }

  int getIncorrectCount() {
    return selectedAnswersMap.values
        .where((answer) =>
            answer != questions[currentQuestionIndex].questionAnswers[0])
        .length;
  }

  int getUncheckedCount() {
    return questions.length - selectedAnswersMap.length;
  }

  double getPercentage() {
    int correctCount = getCorrectCount();
    int totalQuestions = questions.length;
    return (correctCount / totalQuestions) * 100;
  }

  bool isCorrectAnswer(String answer) {
    int inde = currentQuestionIndex;
    return questions[inde - 1].questionAnswers[0] == answer;
  }

  void showFeedbackSnackbar(
      BuildContext context, String message, bool isCorrect) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      backgroundColor: isCorrect ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    var currentQuestion = currentQuestionIndex < questions.length
        ? questions[currentQuestionIndex]
        : questions[questions.length - 1];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Time Left: ${_formatTime(_remainingSeconds)}",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _remainingSeconds <= 20 ? Colors.red : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer
            Center(
                // child: Text(
                //   "Time Left: ${_formatTime(_remainingSeconds)}",
                //   style: TextStyle(
                //     fontSize: 20,
                //     fontWeight: FontWeight.bold,
                //     color: _remainingSeconds <= 10 ? Colors.red : Colors.black,
                //   ),
                // ),
                ),
            const SizedBox(height: 16),
            // Progress Indicator (Horizontal Scroll View)
            // SingleChildScrollView(
            //   scrollDirection: Axis.horizontal,
            //   child: Row(
            //     children: List.generate(10, (index) {
            //       return Padding(
            //         padding: const EdgeInsets.only(
            //             right: 8.0), // Space between circles
            //         child: CircleAvatar(
            //           radius: 16,
            //           backgroundColor:
            //               index < 4 ? Colors.black : Colors.grey[300],
            //           child: Text(
            //             "${index + 1}",
            //             style: TextStyle(
            //               color: index < 4 ? Colors.white : Colors.black,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //         ),
            //       );
            //     }),
            //   ),
            // ),
            // Progress Indicator (Horizontal Scroll View)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(questions.length, (index) {
                  bool isCurrent = index == currentQuestionIndex;
                  bool isAnswered = selectedAnswersMap.containsKey(index);

                  Color backgroundColor;
                  Color textColor;

                  if (isCurrent) {
                    backgroundColor = Colors.blue; // Highlight current
                    textColor = Colors.white;
                  } else if (isAnswered) {
                    backgroundColor = Colors.green; // Answered
                    textColor = Colors.white;
                  } else {
                    backgroundColor = Colors.grey[300]!; // Unanswered
                    textColor = Colors.black;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          currentQuestionIndex = index;
                          _shuffledAnswers = questions[currentQuestionIndex]
                              .getShuffledAnswers();
                        });
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: backgroundColor,
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),
            // Question Text
            Text(
              currentQuestion.questionTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // Options
            Expanded(
              child: ListView(
                children: _shuffledAnswers.map((answer) {
                  final isSelected =
                      selectedAnswersMap[currentQuestionIndex] == answer;
                  return QuizOption(
                    optionText: answer,
                    isSelected: isSelected,
                    onPressed: () {
                      answerQuestion(answer, currentQuestion.questionTitle,
                          currentQuestionIndex);
                      if (isCorrectAnswer(answer)) {
                        showFeedbackSnackbar(context, "Correct!", true);
                      } else {
                        showFeedbackSnackbar(context, "Wrong!", false);
                      }
                    },
                  );
                }).toList(),
              ),
            ),

            // if (currentQuestion.type == "image" &&
            //     currentQuestion.url != null &&
            //     currentQuestion.url.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 16),
            //     child: Center(
            //       child: Image.network(
            //         currentQuestion.url,
            //         height: 200,
            //         fit: BoxFit.contain,
            //       ),
            //     ),
            //   ),

            if (currentQuestion.type == "IMAGE" &&
                currentQuestion.url != null &&
                currentQuestion.url.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: GestureDetector(
                    onDoubleTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.black,
                          child: InteractiveViewer(
                            // <-- user can zoom/pan
                            child: Image.network(
                              currentQuestion.url,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Image.network(
                      currentQuestion.url,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              )
            else if (currentQuestion.type == "VIDEO" &&
                currentQuestion.url != null &&
                currentQuestion.url.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: VideoPlayerWidget(url: currentQuestion.url),
                  ),
                ),
              )
            else if (currentQuestion.type == "YOUTUBE" &&
                currentQuestion.url.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: YoutubePlayerWidget(url: currentQuestion.url),
              ),

            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: currentQuestionIndex > 0
                          ? () {
                              prevQuestion(1);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: currentQuestionIndex < questions.length - 1
                          ? () {
                              nextQuestion(1);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      child:
                          const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Submit Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  finishedExam(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizOption extends StatelessWidget {
  final String optionText;
  final bool isSelected;
  final void Function() onPressed;

  const QuizOption({
    Key? key,
    required this.optionText,
    required this.isSelected,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey,
            width: 1.5,
          ),
          color: isSelected ? Colors.grey[300] : Colors.white,
        ),
        child: ListTile(
          title: Text(
            optionText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isSelected ? Colors.black : Colors.grey[700],
            ),
          ),
          onTap: onPressed,
        ),
      ),
    );
  }
}
