import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:sqflite/sqflite.dart';

import '../db/firebase/QuestionFirebaseService.dart';
import '../db/quiz/question_db_helper.dart';
import '../db/quiz/quiz_db_helper.dart';
import '../model/quiz/question.dart';
import '../model/quiz/quiz.dart';
import '../utility/unique.dart';

class QuestionManagementDetailPage extends StatefulWidget {
  final Quiz quiz;
  const QuestionManagementDetailPage({super.key, required this.quiz});

  @override
  _QuestionManagementDetailPageState createState() =>
      _QuestionManagementDetailPageState();
}

class _QuestionManagementDetailPageState
    extends State<QuestionManagementDetailPage> {
  bool _isLoading = false;
  List<Question> _questions = [];
  bool isOnline = true; // Online mode toggle
  final _scaffoldKey = GlobalKey<ScaffoldState>(); // Key for scaffold (for drawer)

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  // Load questions for the selected quiz
  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (isOnline) {
        // Fetch questions from Firebase when online
        List<Question> firebaseQuestions =
        await QuestionFirebaseService().getQuestionsByQuizId(widget.quiz.qId);

        setState(() {
          _questions = firebaseQuestions;
        });
      } else {
        // Fetch questions from SQLite when offline
        List<Question> offlineQuestions =
        await QuestionDBHelper.getQuestionsByQuizId(widget.quiz.qId);

        setState(() {
          _questions = offlineQuestions;
        });
      }
    } catch (e) {
      _showError("Error loading questions: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Delete question from Firebase or SQLite
  Future<void> _deleteQuestion(String questionId) async {
    try {
      if (isOnline) {
        await QuestionFirebaseService().deleteQuestion(questionId);
      } else {
        await QuestionDBHelper.deleteQuestionByUId(questionId);
      }

      _loadQuestions(); // Reload questions after deletion
      _showError("Question deleted successfully");
    } catch (e) {
      _showError("Error deleting question: $e");
    }
  }

  // Future<void> _addOrEditQuestion(Question? question) async {
  //   final TextEditingController questionTitleController = TextEditingController(text: question?.questionTitle);
  //   final TextEditingController explanationController = TextEditingController(text: question?.explanation);
  //   final TextEditingController sourceController = TextEditingController(text: question?.source);
  //
  //   // Default 2 options
  //   List<TextEditingController> optionControllers = question?.questionAnswers
  //       .map((answer) => TextEditingController(text: answer))
  //       .toList() ??
  //       [TextEditingController(), TextEditingController()];
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return Dialog(
  //             insetPadding: EdgeInsets.all(0), // Full screen dialog
  //             child: Scaffold(
  //               appBar: AppBar(
  //                 title: Text(question == null ? 'Add New Question' : 'Edit Question'),
  //                 backgroundColor: Colors.indigo,
  //               ),
  //               body: SingleChildScrollView(
  //                 child: Padding(
  //                   padding: const EdgeInsets.all(16.0),
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       // Question Title TextField
  //                       TextField(
  //                         controller: questionTitleController,
  //                         decoration: const InputDecoration(labelText: 'Question Title'),
  //                       ),
  //                       const SizedBox(height: 8.0),
  //
  //                       // Display options
  //                       for (int i = 0; i < optionControllers.length; i++)
  //                         Padding(
  //                           padding: const EdgeInsets.symmetric(vertical: 4.0),
  //                           child: TextField(
  //                             controller: optionControllers[i],
  //                             decoration: InputDecoration(labelText: 'Option ${i + 1}'),
  //                           ),
  //                         ),
  //                       const SizedBox(height: 8.0),
  //
  //                       // Add button to add more options
  //                       ElevatedButton(
  //                         onPressed: () {
  //                           setState(() {
  //                             // Add a new controller for an extra option
  //                             optionControllers.add(TextEditingController());
  //                           });
  //                         },
  //                         child: const Text('Add Option'),
  //                       ),
  //                       const SizedBox(height: 8.0),
  //
  //                       // Explanation TextArea
  //                       TextField(
  //                         controller: explanationController,
  //                         maxLines: 5, // Makes it a text area
  //                         decoration: const InputDecoration(labelText: 'Explanation'),
  //                       ),
  //                       const SizedBox(height: 8.0),
  //
  //                       // Source TextArea
  //                       TextField(
  //                         controller: sourceController,
  //                         maxLines: 5, // Makes it a text area
  //                         decoration: const InputDecoration(labelText: 'Source'),
  //                       ),
  //                       const SizedBox(height: 16.0),
  //
  //                       // Save button
  //                       ElevatedButton(
  //                         onPressed: () {
  //                           if (questionTitleController.text.isEmpty ||
  //                               optionControllers.any((controller) => controller.text.isEmpty) ||
  //                               explanationController.text.isEmpty ||
  //                               sourceController.text.isEmpty) {
  //                             _showError('Please fill in all fields.');
  //                           } else {
  //                             final newQuestion = Question(
  //                               qId: question?.qId ?? '',
  //                               quizId: widget.quiz.qId,
  //                               questionTitle: questionTitleController.text,
  //                               questionAnswers: optionControllers.map((controller) => controller.text).toList(),
  //                               explanation: explanationController.text,
  //                               source: sourceController.text,
  //                             );
  //
  //                             try {
  //                               if (isOnline) {
  //                                 QuestionFirebaseService().addOrUpdateQuestion(newQuestion);
  //                               } else {
  //                                 QuestionDBHelper.insertQuestion(newQuestion, widget.quiz.qId);
  //                               }
  //
  //                               _loadQuestions(); // Reload questions after adding/editing
  //                               Navigator.of(context).pop(); // Close dialog
  //                             } catch (e) {
  //                               _showError("Error adding/editing question: $e");
  //                             }
  //                           }
  //                         },
  //                         child: Text(question == null ? 'Add' : 'Save'),
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: Colors.indigo,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Future<void> _addOrEditQuestion(Question? question) async {
    final TextEditingController questionTitleController = TextEditingController(text: question?.questionTitle);
    final TextEditingController explanationController = TextEditingController(text: question?.explanation);
    final TextEditingController sourceController = TextEditingController(text: question?.source);
    final TextEditingController urlController = TextEditingController(text: question?.url ?? '');

    String selectedType = question?.type ?? "TEXT";

    List<TextEditingController> optionControllers = question?.questionAnswers
        .map((answer) => TextEditingController(text: answer))
        .toList() ?? [TextEditingController(), TextEditingController()];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Scaffold(
                backgroundColor: Colors.deepPurple.shade50,
                appBar: AppBar(
                  title: Text(question == null ? 'Add New Question' : 'Edit Question'),
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Lottie Animation
                      SizedBox(
                        height: 150,
                        child: Lottie.asset('animation/ (1).json'), // <-- Your lottie file here
                      ),
                      const SizedBox(height: 16),

                      // Question Title
                      TextFormField(
                        controller: questionTitleController,
                        maxLines: 4,
                        decoration: _styledInputDecoration('Question Title', Icons.edit_note),
                      ),
                      const SizedBox(height: 16),

                      // Options
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: optionControllers.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: optionControllers[index],
                              maxLines: 2,
                              decoration: _styledInputDecoration('Option ${index + 1}', Icons.list_alt),
                            ),
                          );
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              optionControllers.add(TextEditingController());
                            });
                          },
                          icon: Icon(Icons.add, color: Colors.deepPurple),
                          label: Text('Add Option', style: TextStyle(color: Colors.deepPurple)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: _styledInputDecoration('Question Type', Icons.category),
                        items: ["TEXT", "IMAGE", "VIDEO", "AUDIO","YOUTUBE"].map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedType = value ?? "TEXT";
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // URL Field
                      TextFormField(
                        controller: urlController,
                        maxLines: 2,
                        decoration: _styledInputDecoration('URL (Image/Video/Audio)', Icons.link),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: explanationController,
                        maxLines: 3,
                        decoration: _styledInputDecoration('Explanation', Icons.lightbulb_outline),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: sourceController,
                        maxLines: 3,
                        decoration: _styledInputDecoration('Source', Icons.source),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (questionTitleController.text.isEmpty ||
                                optionControllers.any((controller) => controller.text.isEmpty)) {
                              _showError('Please fill in all fields.');
                            } else {
                              String uniqueId = Unique().generateUniqueID();
                              final newQuestion = Question(
                                qId: uniqueId,
                                quizId: widget.quiz.qId,
                                questionTitle: questionTitleController.text,
                                questionAnswers: optionControllers.map((controller) => controller.text).toList(),
                                explanation: explanationController.text,
                                source: sourceController.text,
                                type: selectedType,
                                url: urlController.text,
                              );

                              try {
                                if (isOnline) {
                                  QuestionFirebaseService().addOrUpdateQuestion(newQuestion);
                                } else {
                                  QuestionDBHelper.insertQuestion(newQuestion, widget.quiz.qId);
                                }
                                _loadQuestions();
                                Navigator.of(context).pop();
                              } catch (e) {
                                _showError("Error adding/editing question: $e");
                              }
                            }
                          },
                          icon: Icon(Icons.save),
                          label: Text(question == null ? 'Add Question' : 'Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _styledInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Toggle online/offline mode using a Drawer
  void _toggleOnlineOffline() {
    setState(() {
      isOnline = !isOnline;
    });
    _loadQuestions(); // Reload questions after toggling mode
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog on back button press
        return (await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit'),
            content: const Text('Are you sure you want to exit?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        )) ??
            false; // If user presses Exit, return true to allow back action
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('${widget.quiz.quizName} - Questions'),
          backgroundColor: Colors.indigo,
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text(
                  'Quiz Manager',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
              ListTile(
                title: Text(isOnline ? 'Switch to Offline' : 'Switch to Online'),
                onTap: _toggleOnlineOffline,
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return Dismissible(
                    key: Key(question.qId ?? ''),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      _deleteQuestion(question.qId ?? '');
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(question.questionTitle),
                        subtitle: Text(
                            'Options: ${question.questionAnswers.join(", ")}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.indigo),
                          onPressed: () {
                            _addOrEditQuestion(question); // Edit existing question
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _addOrEditQuestion(null); // Add new question
          },
          child: const Icon(Icons.add),
          backgroundColor: Colors.green,
          tooltip: 'Add New Question',
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     key: _scaffoldKey,
  //     appBar: AppBar(
  //       title: Text('${widget.quiz.quizName} - Questions'),
  //       backgroundColor: Colors.indigo,
  //       actions: [
  //         IconButton(
  //           icon: Icon(Icons.settings),
  //           onPressed: () => _scaffoldKey.currentState?.openDrawer(),
  //         ),
  //       ],
  //     ),
  //     drawer: Drawer(
  //       child: ListView(
  //         children: <Widget>[
  //           const DrawerHeader(
  //             decoration: BoxDecoration(color: Colors.blue),
  //             child: Text(
  //               'Quiz Manager',
  //               style: TextStyle(fontSize: 24, color: Colors.white),
  //             ),
  //           ),
  //           ListTile(
  //             title: Text(isOnline ? 'Switch to Offline' : 'Switch to Online'),
  //             onTap: _toggleOnlineOffline,
  //           ),
  //         ],
  //       ),
  //     ),
  //     body: _isLoading
  //         ? const Center(child: CircularProgressIndicator())
  //         : Column(
  //       children: [
  //         Expanded(
  //           child: ListView.builder(
  //             itemCount: _questions.length,
  //             itemBuilder: (context, index) {
  //               final question = _questions[index];
  //               return Dismissible(
  //                 key: Key(question.qId ?? ''),
  //                 direction: DismissDirection.endToStart,
  //                 onDismissed: (direction) {
  //                   _deleteQuestion(question.qId ?? '');
  //                 },
  //                 background: Container(
  //                   color: Colors.red,
  //                   alignment: Alignment.centerRight,
  //                   padding: const EdgeInsets.only(right: 20.0),
  //                   child: const Icon(Icons.delete, color: Colors.white),
  //                 ),
  //                 child: Card(
  //                   margin: const EdgeInsets.symmetric(
  //                       vertical: 8.0, horizontal: 16.0),
  //                   elevation: 4,
  //                   child: ListTile(
  //                     contentPadding: const EdgeInsets.all(16),
  //                     title: Text(question.questionTitle),
  //                     subtitle: Text(
  //                         'Options: ${question.questionAnswers.join(", ")}'),
  //                     trailing: IconButton(
  //                       icon: const Icon(Icons.edit, color: Colors.indigo),
  //                       onPressed: () {
  //                         _addOrEditQuestion(question); // Edit existing question
  //                       },
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //     floatingActionButton: FloatingActionButton(
  //       onPressed: () {
  //         _addOrEditQuestion(null); // Add new question
  //       },
  //       child: const Icon(Icons.add),
  //       backgroundColor: Colors.green,
  //       tooltip: 'Add New Question',
  //     ),
  //   );
  // }
}



// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import 'package:sqflite/sqflite.dart';
//
// import '../db/firebase/QuestionFirebaseService.dart';
// import '../db/firebase/QuizFirebaseService.dart';
// import '../db/quiz/quiz_db_helper.dart';
// import '../model/quiz/question.dart';
// import '../model/quiz/quiz.dart';
//
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
//       // Set questions from Firebase
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
//       floatingActionButton: FloatingActionButton(
//         onPressed: _addQuestion,
//         child: const Icon(Icons.add),
//         backgroundColor: Colors.green,
//         tooltip: 'Add New Question',
//       ),
//     );
//   }
// }
