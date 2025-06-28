import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../data/quiz/questions.dart';
import '../db/firebase/QuestionFirebaseService.dart';
import '../db/firebase/QuizFirebaseService.dart';
import '../db/quiz/question_db_helper.dart';
import '../db/quiz/quiz_db_helper.dart';
import '../model/mess/mess_main.dart';
import '../model/mess/mess_user.dart';
import '../model/quiz/question.dart';
import '../model/quiz/quiz.dart';
import '../model/school/school.dart';
import '../model/school/teacher.dart';
import '../model/user/user.dart';
import '../preference/logout.dart';
import 'QuestionManagementDetailPage.dart';
import 'QuizPanel.dart';

class QuizExamScreen extends StatefulWidget {
  const QuizExamScreen({super.key});

  @override
  _QuestionManagementPageState createState() =>
      _QuestionManagementPageState();
}

class _QuestionManagementPageState extends State<QuizExamScreen> {
  bool _isLoading = false;
  bool _Loading = false;
  List<Quiz> _quizzes = [];

  List<Question> _questions = [];
  Quiz? _currentQuiz;

  bool isJoining = false; // Toggle between create and join forms
  String _userName = 'Farhad Foysal';
  String? userName;
  String? userPhone;
  String? userEmail;
  User? _user, _user_data;
  MessUser? messUser, _mess_user_data;
  MessMain? messMain;
  String? sid;
  String? messId;
  School? school;
  Teacher? teacher;
  File? _selectedImage;
  bool _showSaveButton = false;
  late TabController _tabController;
  int _currentIndex1 = 0;
  int _currentIndex2 = 0;
  DateTime selectedDate = DateTime.now();
  String? selectedMonthYear;


  @override
  void initState() {
    _loadUserName();
    _initializeData();
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUserData = prefs.getString('user_logged_in');

    if (savedUserData != null) {
      Map<String, dynamic> userData = jsonDecode(savedUserData);
      setState(() {
        _userName = userData['uname'] ?? 'Tasnim';
      });
    }
  }

  Future<void> _loadUserData() async {
    Logout logout = Logout();
    User? user = await logout.getUserDetails(key: 'user_data');

    Map<String, dynamic>? userMap = await logout.getUser(key: 'user_logged_in');
    Map<String, dynamic>? schoolMap =
    await logout.getSchool(key: 'school_data');

    if (userMap != null) {
      User user_data = User.fromMap(userMap);
      setState(() {
        _user_data = user_data;
        _user = user_data;
      });
    } else {
      print("User map is null");
    }

    if (schoolMap != null) {
      School schoolData = School.fromMap(schoolMap);
      setState(() {
        _user = user;
        school = schoolData;
        sid = school?.sId;
        print(schoolData.sId);
      });
    } else {
      print("School data is null");
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('user_logged_in');
    String? imagePath = prefs.getString('profile_picture-${_user?.uniqueid!}');

    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      setState(() {
        userName = userData['uname'];
        userPhone = userData['phone'];
        userEmail = userData['email'];
        if (imagePath != null) {
          _selectedImage = File(imagePath);
        }
      });
    }
  }

  Future<void> _initializeData() async {
    // First load user data
    await _loadUserData();
    // await _loadMessUserData();


  }

  void showConnectivitySnackBar(bool isOnline) {
    final message = isOnline ? "Internet Connected" : "Internet Not Connected";
    final color = isOnline ? Colors.green : Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }



  // Future<void> _enterQuizRoom(Quiz quiz) async {
  //   String quizId = quiz.qId;
  //
  //   if (quizId.isEmpty) {
  //     _showError('Please enter a quiz ID');
  //     return;
  //   }
  //
  //   if (await InternetConnectionChecker.instance.hasConnection){
  //
  //     try {
  //       // Check if quiz exists in Firestore
  //       var quizSnapshot = await FirebaseFirestore.instance
  //           .collection('quizzes')
  //           .doc(quizId)
  //           .get();
  //
  //       if (!quizSnapshot.exists) {
  //         _showError('Quiz not found');
  //       } else {
  //         // Navigate to quiz questions screen
  //         // Navigator.push(
  //         //   context,
  //         //   MaterialPageRoute(
  //         //     builder: (context) => QuizQuestionsScreen(
  //         //       quizId: quizId,
  //         //       studentId: widget.studentId,
  //         //     ),
  //         //   ),
  //         // );
  //
  //         final data = quizSnapshot.data();
  //         if (data == null) {
  //           _showError('Quiz data is empty');
  //           return;
  //         }
  //
  //         _currentQuiz = Quiz.fromJson(data);
  //
  //         await _loadQuestions(quizId);
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => QuizPanel(studentId: _user!.uniqueid!, phoneNumber: _user!.phone!, quiz: _currentQuiz!,),
  //           ),
  //         );
  //       }
  //     } catch (e) {
  //       _showError('Error entering quiz room: $e');
  //     }
  //
  //   }else{
  //
  //
  //
  //   }
  //
  //
  // }

  Future<void> _enterQuizRoom(Quiz quiz) async {
    String quizId = quiz.qId;

    if (quizId.isEmpty) {
      _showError('Please enter a quiz ID');
      return;
    }

    // Check internet connection
    if (await InternetConnectionChecker.instance.hasConnection) {
      try {
        // Try fetching from Firestore
        var quizSnapshot = await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(quizId)
            .get();

        if (!quizSnapshot.exists) {
          _showError('Quiz not found online');
          return;
        }

        final data = quizSnapshot.data();
        if (data == null) {
          _showError('Quiz data is empty');
          return;
        }

        _currentQuiz = Quiz.fromJson(data);

        await _loadQuestions(quizId);
        setState(() {
          _Loading = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizPanel(
              studentId: _user!.uniqueid!,
              phoneNumber: _user!.phone!,
              quiz: _currentQuiz!,
            ),
          ),
        );
      } catch (e) {
        setState(() {
          _Loading = false;
        });
        _showError('Error fetching quiz online: $e');
      }
    } else {
      // Offline: Check SQLite
      try {
        final localQuiz = await QuizDBHelper.getQuizByQId(quizId);

        if (localQuiz == null) {
          _showError('Quiz not found offline');
          return;
        }

        _currentQuiz = localQuiz;

        await _loadQuestions(quizId);
        setState(() {
          _Loading = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizPanel(
              studentId: _user!.uniqueid!,
              phoneNumber: _user!.phone!,
              quiz: _currentQuiz!,
            ),
          ),
        );
      } catch (e) {
        setState(() {
          _Loading = false;
        });
        _showError('Error loading quiz offline: $e');
      }
    }
  }

  Future<void> _loadQuestions(String quizId) async {
    try {
      print("Loading questions for quizId: $quizId");

      if (await InternetConnectionChecker.instance.hasConnection) {
        // Online mode: fetch from Firestore
        final querySnapshot = await FirebaseFirestore.instance
            .collection('questions')
            .where('quiz_id', isEqualTo: quizId)
            .get();

        if (querySnapshot.docs.isEmpty) {
          print("No questions found for this quiz in Firestore");
        }

        final fetchedQuestions = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Question.fromJson(data);
        }).toList();

        // Store questions to local DB
        await QuestionDBHelper.deleteQuestionsByQuizId(quizId); // Clear previous if any
        for (var q in fetchedQuestions) {
          await QuestionDBHelper.insertQuestion(q, quizId);
        }

        // Update state
        setState(() {
          _questions = fetchedQuestions;
          questions.clear();
          questions.addAll(fetchedQuestions);
        });

      } else {
        // Offline mode: load from SQLite
        final offlineQuestions = await QuestionDBHelper.getQuestionsByQuizId(quizId);

        if (offlineQuestions.isEmpty) {
          _showError('No offline questions available for this quiz');
          return;
        }

        setState(() {
          _questions = offlineQuestions;
          questions.clear();
          questions.addAll(offlineQuestions);
        });
      }
    } catch (e) {
      print("Error loading questions: $e");
      _showError('Error loading questions: $e');
    }
  }


  // Future<void> _loadQuestions(String quizId) async {
  //   try {
  //     print("Loading questions for quizId: ${quizId}");
  //
  //     // Fetch questions from Firestore where quizId matches
  //     final querySnapshot = await FirebaseFirestore.instance
  //         .collection('questions')
  //         .where('quiz_id', isEqualTo: quizId)
  //         .get();
  //
  //     if (querySnapshot.docs.isEmpty) {
  //       print("No questions found for this quiz");
  //     }
  //
  //     // Map the fetched documents to Question objects
  //     setState(() {
  //       _questions = querySnapshot.docs
  //           .map((doc) {
  //         // Check if the document contains the expected fields
  //         final data = doc.data() as Map<String, dynamic>;
  //         // print("Fetched question: ${data['questionTitle']}");
  //
  //         // Convert the Firestore document into a Question object
  //         return Question.fromJson(data);
  //       })
  //           .toList();
  //
  //       questions.clear();
  //       questions.addAll(_questions);
  //
  //
  //
  //     });
  //   } catch (e) {
  //     print("Error loading questions: $e");
  //     _showError('Error loading questions: $e');
  //   }
  // }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }


  // Load quizzes from SQLite and Firebase
  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool hasInternet = await InternetConnectionChecker.instance.hasConnection;

      if (hasInternet) {
        // Load from Firestore if connected
        List<Quiz> firebaseQuizzes = await QuizFirebaseService().getAllQuizzes();
        setState(() {
          _quizzes = firebaseQuizzes;
        });
      } else {
        // Load from local DB if offline
        List<Quiz> localQuizzes = await QuizDBHelper.getQuizzes();
        setState(() {
          _quizzes = localQuizzes;
        });
      }
    } catch (e) {
      print("Error loading quizzes: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Future<void> _loadQuizzes() async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   try {
  //     // Fetch quizzes from SQLite
  //     List<Quiz> localQuizzes = await QuizDBHelper.getQuizzes();
  //
  //     // Fetch quizzes from Firebase
  //     List<Quiz> firebaseQuizzes = await QuizFirebaseService().getAllQuizzes();
  //
  //     // Combine quizzes from both sources
  //     setState(() {
  //       _quizzes = [...localQuizzes, ...firebaseQuizzes];
  //     });
  //   } catch (e) {
  //     print("Error loading quizzes: $e");
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  // Delete quiz from both SQLite and Firebase
  Future<void> _deleteQuiz(String quizId) async {
    try {
      // Delete from SQLite
      await QuizDBHelper.deleteQuizByUId(quizId);

      // Delete from Firebase
      await QuizFirebaseService().deleteQuiz(quizId);

      // Reload quizzes
      _loadQuizzes();
    } catch (e) {
      print("Error deleting quiz: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quizzes'),
        backgroundColor: Colors.deepPurple, // Elegant dark purple
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Lottie.asset(
          'animation/ (1).json', // Your Lottie loading animation
          height: 120,
        ),
      )
          : _quizzes.isEmpty
          ? Center(child: Text("No quizzes available.", style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
        itemCount: _quizzes.length,
        // itemBuilder: (context, index) {
        //   final quiz = _quizzes[index];
        //   return Dismissible(
        //     key: Key(quiz.qId),
        //     direction: DismissDirection.endToStart,
        //     onDismissed: (direction) {
        //       _deleteQuiz(quiz.qId);
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         SnackBar(content: Text('${quiz.quizName} deleted')),
        //       );
        //     },
        //     background: Container(
        //       color: Colors.redAccent,
        //       alignment: Alignment.centerRight,
        //       padding: const EdgeInsets.only(right: 20.0),
        //       child: const Icon(Icons.delete, color: Colors.white),
        //     ),
        //     child: Card(
        //       margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        //       elevation: 5,
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(16),
        //       ),
        //       child: ListTile(
        //         contentPadding: const EdgeInsets.all(16),
        //         title: Text(
        //           quiz.quizName,
        //           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
        //         ),
        //         subtitle: Text(quiz.quizDescription, style: TextStyle(color: Colors.grey[600])),
        //         trailing: IconButton(
        //           icon: const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
        //           onPressed: () {
        //             // Navigate to the question management page for this quiz
        //             Navigator.push(
        //               context,
        //               MaterialPageRoute(
        //                 builder: (context) => QuestionManagementDetailPage(quiz: quiz),
        //               ),
        //             );
        //           },
        //         ),
        //       ),
        //     ),
        //   );
        // },

        itemBuilder: (context, index) {
          final quiz = _quizzes[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.deepPurple.shade50, // soft purple background
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _Loading = true;
                  });
                  _enterQuizRoom(quiz);

                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => QuestionManagementDetailPage(quiz: quiz),
                  //   ),
                  // );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Leading Icon or avatar
                      CircleAvatar(
                        backgroundColor: Colors.deepPurple.shade200,
                        child: Icon(Icons.quiz, color: Colors.white),
                      ),
                      const SizedBox(width: 16),

                      // Quiz Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quiz.quizName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              quiz.quizDescription,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.deepPurple.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.timer, size: 16, color: Colors.deepPurple),
                                const SizedBox(width: 4),
                                Text(
                                  '${quiz.minutes} mins', // <-- assuming you have quizDuration field
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.deepPurple.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      _Loading
                          ? Center(
                        child: Lottie.asset(
                          'animation/ (1).json', // Your Lottie loading animation
                          height: 120,
                        ),
                      ) : Icon(Icons.arrow_forward_ios_rounded, color: Colors.deepPurple, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },


      ),
    );
  }

}
