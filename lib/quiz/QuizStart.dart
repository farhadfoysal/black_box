import 'package:black_box/db/firebase/QuizFirestoreHelper.dart';
import 'package:black_box/quiz/QuizzesResult.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; // Import Lottie
import '../../quiz/StudentAuthenticationScreen.dart';
import '../db/local/QuizResultDBHelper.dart';
import '../model/quiz/QResult.dart';
import '../model/quiz/quiz.dart';
import '../model/quiz/QuizResult.dart'; // Import QuizResult model

class QuizStart extends StatefulWidget {
  final void Function() switchScreen;
  final String studentId;
  final String phoneNumber;
  final Quiz quiz;

  QuizStart(this.switchScreen, this.studentId, this.phoneNumber, this.quiz);

  @override
  _QuizStartState createState() => _QuizStartState();
}

class _QuizStartState extends State<QuizStart> {
  bool _isQuizPerformed = false;
  QResult? _quizResult; // Store the result if already performed
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _checkQuizStatus();
  }

  // Method to check if the quiz is already performed
  Future<void> _checkQuizStatus() async {
    setState(() {
      _isLoading = true;
    });

    if (await InternetConnectionChecker.instance.hasConnection) {
      bool performed = await Quizfirestorehelper().hasUserPerformedQuiz(
        widget.studentId,
        widget.phoneNumber,
        widget.quiz.qId,
      );
      if (performed) {
        // Fetch result from Firestore
        _quizResult = await Quizfirestorehelper().getQuizResult(
          widget.studentId,
          widget.phoneNumber,
          widget.quiz.qId,
        );
      }
      setState(() {
        _isQuizPerformed = performed;
          _isLoading = false;

      });
    } else {
      bool performed = await Quizresultdbhelper().hasUserPerformedQuiz(
        widget.studentId,
        widget.phoneNumber,
        widget.quiz.qId,
      );
      if (performed) {
        // Fetch result from SQLite
        _quizResult = await Quizresultdbhelper().getQuizResult(
          widget.studentId,
          widget.phoneNumber,
          widget.quiz.qId,
        );
      }
      setState(() {
        _isQuizPerformed = performed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final DateTime createdAt = DateTime.tryParse(widget.quiz.createdAt) ?? DateTime.now();

    String getDayWithSuffix(int day) {
      if (day >= 11 && day <= 13) return '${day}th';
      switch (day % 10) {
        case 1: return '${day}st';
        case 2: return '${day}nd';
        case 3: return '${day}rd';
        default: return '${day}th';
      }
    }

    final String formattedDate = "${getDayWithSuffix(createdAt.day)} ${DateFormat('MMMM, y').format(createdAt)}";
    final String formattedTime = DateFormat('h:mm a').format(createdAt);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child:  SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Lottie Animation for Quiz
                Lottie.asset(
                  'animation/4.json', // Replace with your animation file
                  width: 250,
                  height: 250,
                  fit: BoxFit.fill,
                ),
                SizedBox(height: 16),
          
                // Quiz Title with Dynamic Name
                Text(
                  "Welcome to ${widget.quiz.quizName}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                SizedBox(height: 16),
          
                // Quiz Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    widget.quiz.quizDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(height: 15),
          
                // Quiz Duration and Created Date
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Text(
                        "Duration: ${widget.quiz.minutes} minutes",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.teal[600],
                        ),
                      ),
                      SizedBox(height: 8),

                      Text(
                        "$formattedDate  Time: $formattedTime",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.teal[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                if (_isQuizPerformed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text(
                              "You have already performed.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 16),

                            if (_quizResult != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Your Score: ${_quizResult!.percentage}%",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        "Correct Answers: ${_quizResult!.correctCount}",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.cancel, color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        "Incorrect Answers: ${_quizResult!.incorrectCount}",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.help_outline, color: Colors.grey, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        "Unanswered: ${_quizResult!.uncheckedCount}",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),


                //
                // // Check if quiz has already been performed and update button state
                // if (_isQuizPerformed)
                //   Padding(
                //     padding: const EdgeInsets.all(8.0),
                //     child: Column(
                //       children: [
                //         Text(
                //           "You have already performed this quiz.",
                //           textAlign: TextAlign.center,
                //           style: TextStyle(
                //             fontSize: 12,
                //             color: Colors.red,
                //           ),
                //         ),
                //         SizedBox(height: 16),
                //
                //         // Show quiz result
                //         if (_quizResult != null)
                //           Column(
                //             children: [
                //               Text(
                //                 "Your Score: ${_quizResult!.percentage}%",
                //                 style: TextStyle(
                //                   fontSize: 20,
                //                   fontWeight: FontWeight.bold,
                //                   color: Colors.green,
                //                 ),
                //               ),
                //               SizedBox(height: 8),
                //               Text(
                //                 "Correct Answers: ${_quizResult!.correctCount}",
                //                 style: TextStyle(fontSize: 16),
                //               ),
                //               Text(
                //                 "Incorrect Answers: ${_quizResult!.incorrectCount}",
                //                 style: TextStyle(fontSize: 16),
                //               ),
                //               Text(
                //                 "Unanswered: ${_quizResult!.uncheckedCount}",
                //                 style: TextStyle(fontSize: 16),
                //               ),
                //             ],
                //           ),
                //       ],
                //     ),
                //   ),
                //
                // Start Quiz Button (will be disabled if quiz is already performed)

                _isLoading
                    ? Center(
                  child: Lottie.asset(
                    'animation/ (1).json', // Your Lottie loading animation
                    height: 120,
                  ),
                ) : ElevatedButton(
                  onPressed: _isQuizPerformed ? null : () {
                    widget.switchScreen();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _isQuizPerformed ? "Quiz Already Completed" : "Start Quiz",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 20),
          
                // Go to Quiz Room Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizzesResultPage(quizId: widget.quiz.qId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    "Go to the Quiz Room",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// import 'package:black_box/db/firebase/QuizFirestoreHelper.dart';
// import 'package:flutter/material.dart';
// import 'package:internet_connection_checker/internet_connection_checker.dart';
// import 'package:lottie/lottie.dart'; // Import Lottie
// import '../../quiz/StudentAuthenticationScreen.dart';
// import '../db/local/QuizResultDBHelper.dart';
// import '../model/quiz/quiz.dart';
//
// class QuizStart extends StatefulWidget {
//   final void Function() switchScreen;
//   final String studentId;
//   final String phoneNumber;
//   final Quiz quiz;
//
//   QuizStart(this.switchScreen, this.studentId, this.phoneNumber, this.quiz);
//
//   @override
//   _QuizStartState createState() => _QuizStartState();
// }
//
// class _QuizStartState extends State<QuizStart> {
//   bool _isQuizPerformed = false;
//   String _quizResult = "";
//
//   @override
//   void initState() {
//     super.initState();
//     _checkQuizStatus();
//   }
//
//   // Method to check if the quiz is already performed
//   Future<void> _checkQuizStatus() async {
//
//     if (await InternetConnectionChecker.instance.hasConnection){
//       bool performed = await Quizfirestorehelper().hasUserPerformedQuiz(
//         widget.studentId,
//         widget.phoneNumber,
//         widget.quiz.qId,
//       );
//       setState(() {
//         _isQuizPerformed = performed;
//       });
//     }else{
//       bool performed = await Quizresultdbhelper().hasUserPerformedQuiz(
//         widget.studentId,
//         widget.phoneNumber,
//         widget.quiz.qId,
//       );
//       setState(() {
//         _isQuizPerformed = performed;
//       });
//     }
//
//
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               // Lottie Animation for Quiz
//               Lottie.asset(
//                 'animation/4.json', // Replace with your animation file
//                 width: 250,
//                 height: 250,
//                 fit: BoxFit.fill,
//               ),
//               SizedBox(height: 16),
//
//               // Quiz Title with Dynamic Name
//               Text(
//                 "Welcome to ${widget.quiz.quizName}",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 17,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.teal[800],
//                 ),
//               ),
//               SizedBox(height: 16),
//
//               // Quiz Description
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Text(
//                   widget.quiz.quizDescription,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[700],
//                   ),
//                 ),
//               ),
//               SizedBox(height: 15),
//
//               // Quiz Duration and Created Date
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Column(
//                   children: [
//                     Text(
//                       "Duration: ${widget.quiz.minutes} minutes",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 15,
//                         color: Colors.teal[600],
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       "Created on: ${widget.quiz.createdAt}",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 18,
//                         color: Colors.teal[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 32),
//
//               // Check if quiz has already been performed and update button state
//               if (_isQuizPerformed)
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     "You have already performed this quiz.",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: Colors.red,
//                     ),
//                   ),
//                 ),
//
//               // Start Quiz Button (will be disabled if quiz is already performed)
//               ElevatedButton(
//                 onPressed: _isQuizPerformed ? null : () {
//                   widget.switchScreen();
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.teal[600],
//                   padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(18),
//                   ),
//                 ),
//                 child: Text(
//                   _isQuizPerformed ? "Quiz Already Completed" : "Start Quiz",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20),
//
//               // Go to Quiz Room Button
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => StudentAuthenticationScreen(),
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.orange[600],
//                   padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(18),
//                   ),
//                 ),
//                 child: Text(
//                   "Go to the Quiz Room",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
// // import 'package:flutter/material.dart';
// // import 'package:lottie/lottie.dart'; // Import Lottie
// // import '../../quiz/StudentAuthenticationScreen.dart';
// // import '../model/quiz/quiz.dart';
// //
// // class QuizStart extends StatelessWidget {
// //   final void Function() switchScreen;
// //   final String studentId;
// //   final String phoneNumber;
// //   final Quiz quiz;
// //
// //   QuizStart(this.switchScreen, this.studentId, this.phoneNumber, this.quiz);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: SafeArea(
// //         child: Padding(
// //           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             crossAxisAlignment: CrossAxisAlignment.center,
// //             children: [
// //               // Lottie Animation for Quiz (make sure to put a valid animation json)
// //               Lottie.asset(
// //                 'animation/4.json', // Replace with your animation file
// //                 width: 250,
// //                 height: 250,
// //                 fit: BoxFit.fill,
// //               ),
// //               SizedBox(height: 32),
// //
// //               // Quiz Title with Dynamic Name
// //               Text(
// //                 "Welcome to ${quiz.quizName}",
// //                 textAlign: TextAlign.center,
// //                 style: TextStyle(
// //                   fontSize: 34,
// //                   fontWeight: FontWeight.bold,
// //                   color: Colors.teal[800],
// //                 ),
// //               ),
// //               SizedBox(height: 16),
// //
// //               // Quiz Description
// //               Padding(
// //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
// //                 child: Text(
// //                   quiz.quizDescription,
// //                   textAlign: TextAlign.center,
// //                   style: TextStyle(
// //                     fontSize: 18,
// //                     color: Colors.grey[700],
// //                   ),
// //                 ),
// //               ),
// //               SizedBox(height: 32),
// //
// //               // Quiz Duration and Created Date
// //               Padding(
// //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
// //                 child: Column(
// //                   children: [
// //                     Text(
// //                       "Duration: ${quiz.minutes} minutes",
// //                       textAlign: TextAlign.center,
// //                       style: TextStyle(
// //                         fontSize: 18,
// //                         color: Colors.teal[600],
// //                       ),
// //                     ),
// //                     SizedBox(height: 8),
// //                     Text(
// //                       "Created on: ${quiz.createdAt}",
// //                       textAlign: TextAlign.center,
// //                       style: TextStyle(
// //                         fontSize: 18,
// //                         color: Colors.teal[600],
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               SizedBox(height: 32),
// //
// //               // Start Quiz Button
// //               ElevatedButton(
// //                 onPressed: () {
// //                   switchScreen();
// //                 },
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: Colors.teal[600], // Color change for a modern look
// //                   padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(18),
// //                   ),
// //                 ),
// //                 child: Text(
// //                   "Start Quiz",
// //                   style: TextStyle(
// //                     fontSize: 20,
// //                     fontWeight: FontWeight.bold,
// //                     color: Colors.white,
// //                   ),
// //                 ),
// //               ),
// //               SizedBox(height: 20),
// //
// //               // Go to Quiz Room Button
// //               ElevatedButton(
// //                 onPressed: () {
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (context) => StudentAuthenticationScreen(),
// //                     ),
// //                   );
// //                 },
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: Colors.orange[600], // Distinct color for the second button
// //                   padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(18),
// //                   ),
// //                 ),
// //                 child: Text(
// //                   "Go to the Quiz Room",
// //                   style: TextStyle(
// //                     fontSize: 20,
// //                     fontWeight: FontWeight.bold,
// //                     color: Colors.white,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
