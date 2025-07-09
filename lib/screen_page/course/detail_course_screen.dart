import 'dart:convert';
import 'dart:io';

import 'package:black_box/db/exam/exam_dao.dart';
import 'package:black_box/model/exam/exam_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../components/course/review_card.dart';
import '../../components/course/tools_card.dart';
import '../../model/course/course_model.dart';
import '../../model/course/teacher.dart';
import '../../model/school/school.dart';
import '../../model/user/user.dart';
import '../../preference/logout.dart';
import '../../style/color/app_color.dart';

class DetailCourseScreen extends StatefulWidget {
  final CourseModel course;
  const DetailCourseScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<DetailCourseScreen> createState() => _DetailCourseScreenState();
}

class _DetailCourseScreenState extends State<DetailCourseScreen> with SingleTickerProviderStateMixin {

  String _userName = 'Farhad Foysal';
  String? userName;
  String? userPhone;
  String? userEmail;
  User? _user, _user_data;
  String? sid;
  School? school;
  Teacher? teacher;
  File? _selectedImage;
  bool _showSaveButton = false;

  int _currentIndex1 = 0;
  int _currentIndex2 = 0;
  bool isLoading = false;

  final _databaseRef = FirebaseDatabase.instance.ref();

  late final TabController _tabController;

  final List<ExamModel> _quizzes = [];
  bool _isQuizLoading = false;
  bool _quizzesLoadedOnce = false;

  @override
  void initState() {
    super.initState();

    _loadUserName();
    setState(() {
      isLoading = true;
      // isLoading = false;
    });
    _initializeData();

    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2 && !_quizzesLoadedOnce) {
        _loadQuizzesForCourse();
      }
    });
  }

  Future<void> _initializeData() async {
    // First load user data
    await _loadUserData();
    // _loadCoursesData();
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

  Future<void> _loadUser() async {
    Logout logout = Logout();
    User? user = await logout.getUserDetails(key: 'user_data');
    Map<String, dynamic>? userMap = await logout.getUser(key: 'user_logged_in');
    User user_data = User.fromMap(userMap!);
    setState(() {
      _user = user;
      _user_data = user_data;
    });
  }

  void showSnackBarMsg(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }


  Future<void> _loadQuizzesForCourse() async {
    setState(() => _isQuizLoading = true);

    try {
      final hasInternet = await InternetConnectionChecker.instance.hasConnection;

      if (hasInternet) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('quizzes')
            .where('course_id', isEqualTo: widget.course.uniqueId)
            .get();

        final fetchedQuizzes = querySnapshot.docs
            .map((doc) => ExamModel.fromJson(doc.data()))
            .toList();

        setState(() {
          _quizzes
            ..clear()
            ..addAll(fetchedQuizzes);
          _quizzesLoadedOnce = true;
        });
      } else {
        final localQuizzes = await ExamDAO().getExamsByCourseId(widget.course.uniqueId!);
        setState(() {
          _quizzes
            ..clear()
            ..addAll(localQuizzes);
          _quizzesLoadedOnce = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading quizzes: $e')),
      );
    } finally {
      setState(() => _isQuizLoading = false);
    }
  }

  Future<void> _enterQuizRoom(ExamModel quiz) async {
    // TODO: Add your quiz entry logic here
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(250),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textLight),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: const Text(
            'Course Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.dashboard_customize, color: AppColors.textLight),
              tooltip: 'Course Manager',
              onPressed: () {
                // TODO: Add navigation or action
              },
            ),
          ],
          flexibleSpace: Stack(
            fit: StackFit.expand,
            children: [
              if (course.courseImage != null && course.courseImage!.isNotEmpty)
                Image.network(
                  course.courseImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Image.asset('assets/background.jpg', fit: BoxFit.cover),
                )
              else
                Image.asset('assets/background.jpg', fit: BoxFit.cover),
              Container(color: Colors.black.withOpacity(0.5)),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Text(
                      course.courseName ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        final firstVideoUrl = course.sections?.first.materials?.first.url ?? '';
                        final videoId = YoutubePlayer.convertUrlToId(firstVideoUrl);
                        if (videoId != null) {
                          showDialog(
                            context: context,
                            builder: (_) => SimpleDialog(
                              contentPadding: EdgeInsets.zero,
                              children: [
                                SizedBox(
                                  height: 200,
                                  child: YoutubePlayer(
                                    controller: YoutubePlayerController(
                                      initialVideoId: videoId,
                                      flags: const YoutubePlayerFlags(autoPlay: true),
                                    ),
                                    bottomActions: const [
                                      CurrentPosition(),
                                      ProgressBar(isExpanded: true),
                                      RemainingDuration(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.play_circle_outline_outlined, color: AppColors.textLight),
                      label: const Text(
                        'Preview Course',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.textLight,
            labelColor: AppColors.textLight,
            unselectedLabelColor: AppColors.textMuted,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'About'),
              Tab(text: 'Lessons'),
              Tab(text: 'Quiz'),
              Tab(text: 'Tools'),
              Tab(text: 'Reviews'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // About
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Text(
              course.description ?? 'No description available.',
              style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textPrimary),
            ),
          ),

          // Lessons
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: course.sections?.length ?? 0,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final sec = course.sections![index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sec.sectionName ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sec.materials?.length ?? 0,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, subIndex) {
                      final mat = sec.materials![subIndex];
                      final icon = switch (mat.materialType) {
                        'slide' => Icons.slideshow_rounded,
                        'quiz' => Icons.quiz_outlined,
                        _ => Icons.play_circle_fill_rounded,
                      };
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Icon(icon, color: AppColors.primary),
                          title: Text(
                            mat.materialName ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),

          // Quiz
          Stack(
            children: [
              Builder(
                builder: (context) {
                  if (_isQuizLoading) {
                    return Center(
                      child: Lottie.asset('animation/ (1).json', height: 120),
                    );
                  }

                  if (_quizzes.isEmpty) {
                    return Center(
                      child: Text(
                        'No quizzes available for this course.',
                        style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _quizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = _quizzes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        color: Colors.deepPurple.shade50,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade200,
                            child: const Icon(Icons.quiz, color: Colors.white),
                          ),
                          title: Text(
                            quiz.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade900,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                quiz.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.deepPurple.shade700),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.timer, size: 16, color: Colors.deepPurple),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${quiz.durationMinutes} mins',
                                    style: TextStyle(color: Colors.deepPurple.shade800),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.deepPurple),
                          onTap: () => _enterQuizRoom(quiz),
                        ),
                      );
                    },
                  );
                },
              ),

              if (widget.course.userId == _user?.userid)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: ElevatedButton(
                    // onPressed: () => _addCourse(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, // Text color
                      backgroundColor: Colors.blue, // Button color
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25), // Rounded edges
                      ),
                      elevation: 5, // Shadow effect
                    ),
                    onPressed: () {  },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school, size: 20),
                        SizedBox(width: 10),
                        isLoading
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          "Add new Exam/Quiz",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

            ],
          ),


          // Tools
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: course.tools?.length ?? 0,
            itemBuilder: (context, index) {
              final tool = course.tools![index];
              return ToolsCard(
                toolsName: tool.toolsName,
                imgUrl: tool.toolsIcon,
                toolUrl: tool.url,
              );
            },
          ),

          // Reviews
          GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: course.reviews?.length ?? 0,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final r = course.reviews![index];
              return ReviewCard(
                img: 'https://via.placeholder.com/100',
                title: r.user?.uname ?? 'Anonymous',
                rating: r.rating ?? 0,
                desc: r.review ?? '',
              );
            },
          ),
        ],
      ),
    );
  }
}


// import 'package:black_box/db/exam/exam_dao.dart';
// import 'package:black_box/model/exam/exam_model.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:internet_connection_checker/internet_connection_checker.dart';
// import 'package:lottie/lottie.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
//
// import '../../components/course/review_card.dart';
// import '../../components/course/tools_card.dart';
// import '../../model/course/course_model.dart';
// import '../../style/color/app_color.dart';
//
// class DetailCourseScreen extends StatefulWidget {
//   final CourseModel course;
//   const DetailCourseScreen({Key? key, required this.course}) : super(key: key);
//
//   @override
//   State<DetailCourseScreen> createState() => _DetailCourseScreenState();
// }
//
// class _DetailCourseScreenState extends State<DetailCourseScreen> with SingleTickerProviderStateMixin {
//   late final TabController _tabController;
//
//   final List<ExamModel> _quizzes = [];
//   bool _isQuizLoading = false;
//   bool _quizzesLoadedOnce = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _tabController = TabController(length: 5, vsync: this);
//     _tabController.addListener(() {
//       if (_tabController.index == 2 && !_quizzesLoadedOnce) {
//         _loadQuizzesForCourse();
//       }
//     });
//   }
//
//   Future<void> _loadQuizzesForCourse() async {
//     setState(() => _isQuizLoading = true);
//
//     try {
//       final hasInternet = await InternetConnectionChecker().hasConnection;
//
//       if (hasInternet) {
//         final querySnapshot = await FirebaseFirestore.instance
//             .collection('quizzes')
//             .where('course_id', isEqualTo: widget.course.uniqueId)
//             .get();
//
//         final fetchedQuizzes = querySnapshot.docs
//             .map((doc) => ExamModel.fromJson(doc.data()))
//             .toList();
//
//         setState(() {
//           _quizzes
//             ..clear()
//             ..addAll(fetchedQuizzes);
//           _quizzesLoadedOnce = true;
//         });
//       } else {
//         final localQuizzes = await ExamDAO().getExamsByCourseId(widget.course.uniqueId!);
//         setState(() {
//           _quizzes
//             ..clear()
//             ..addAll(localQuizzes);
//           _quizzesLoadedOnce = true;
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading quizzes: $e')),
//       );
//     } finally {
//       setState(() => _isQuizLoading = false);
//     }
//   }
//
//   Future<void> _enterQuizRoom(ExamModel quiz) async {
//     // TODO: Implement your quiz navigation logic here.
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final course = widget.course;
//
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(250),
//         child: AppBar(
//           elevation: 0,
//           backgroundColor: Colors.transparent,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textLight),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//           centerTitle: true,
//           title: const Text(
//             'Course Details',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: AppColors.textLight,
//             ),
//           ),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.dashboard_customize, color: AppColors.textLight),
//               tooltip: 'Course Manager',
//               onPressed: () {
//                 // TODO: Add course manager action/navigation
//               },
//             ),
//           ],
//           flexibleSpace: Stack(
//             fit: StackFit.expand,
//             children: [
//               if (course.courseImage != null && course.courseImage!.isNotEmpty)
//                 Image.network(
//                   course.courseImage!,
//                   fit: BoxFit.cover,
//                   errorBuilder: (_, __, ___) =>
//                       Image.asset('assets/background.jpg', fit: BoxFit.cover),
//                 )
//               else
//                 Image.asset('assets/background.jpg', fit: BoxFit.cover),
//               Container(color: Colors.black.withOpacity(0.5)),
//               Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const SizedBox(height: 50),
//                     Text(
//                       course.courseName ?? '',
//                       style: const TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.textLight,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),
//                     TextButton.icon(
//                       onPressed: () {
//                         final firstVideoUrl = course.sections?.first.materials?.first.url ?? '';
//                         final videoId = YoutubePlayer.convertUrlToId(firstVideoUrl);
//                         if (videoId != null) {
//                           showDialog(
//                             context: context,
//                             builder: (_) => SimpleDialog(
//                               contentPadding: EdgeInsets.zero,
//                               children: [
//                                 SizedBox(
//                                   height: 200,
//                                   child: YoutubePlayer(
//                                     controller: YoutubePlayerController(
//                                       initialVideoId: videoId,
//                                       flags: const YoutubePlayerFlags(autoPlay: true),
//                                     ),
//                                     bottomActions: const [
//                                       CurrentPosition(),
//                                       ProgressBar(isExpanded: true),
//                                       RemainingDuration(),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }
//                       },
//                       icon: const Icon(Icons.play_circle_outline_outlined, color: AppColors.textLight),
//                       label: const Text(
//                         'Preview Course',
//                         style: TextStyle(
//                           color: AppColors.textLight,
//                           fontWeight: FontWeight.w500,
//                           fontSize: 14,
//                         ),
//                       ),
//                       style: TextButton.styleFrom(
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//             ],
//           ),
//           bottom: TabBar(
//             controller: _tabController,
//             indicatorColor: AppColors.textLight,
//             labelColor: AppColors.textLight,
//             unselectedLabelColor: AppColors.textMuted,
//             indicatorWeight: 3,
//             tabs: const [
//               Tab(text: 'About'),
//               Tab(text: 'Lessons'),
//               Tab(text: 'Quiz'),
//               Tab(text: 'Tools'),
//               Tab(text: 'Reviews'),
//             ],
//           ),
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           // About Tab
//           SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Text(
//               course.description ?? 'No description available.',
//               style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textPrimary),
//             ),
//           ),
//
//           // Lessons Tab
//           ListView.separated(
//             padding: const EdgeInsets.all(16),
//             itemCount: course.sections?.length ?? 0,
//             separatorBuilder: (_, __) => const SizedBox(height: 16),
//             itemBuilder: (context, index) {
//               final sec = course.sections![index];
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     sec.sectionName ?? '',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.textPrimary,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   ListView.separated(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: sec.materials?.length ?? 0,
//                     separatorBuilder: (_, __) => const SizedBox(height: 8),
//                     itemBuilder: (context, subIndex) {
//                       final mat = sec.materials![subIndex];
//                       final icon = switch (mat.materialType) {
//                         'slide' => Icons.slideshow_rounded,
//                         'quiz' => Icons.quiz_outlined,
//                         _ => Icons.play_circle_fill_rounded,
//                       };
//                       return Container(
//                         decoration: BoxDecoration(
//                           color: AppColors.surface,
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.05),
//                               blurRadius: 6,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: ListTile(
//                           leading: Icon(icon, color: AppColors.primary),
//                           title: Text(
//                             mat.materialName ?? '',
//                             style: const TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w500,
//                               color: AppColors.textPrimary,
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               );
//             },
//           ),
//
//           // Quiz Tab (no Builder - direct access to state)
//           if (_isQuizLoading)
//             Center(
//               child: Lottie.asset('animation/ (1).json', height: 120),
//             )
//           else if (_quizzes.isEmpty)
//             Center(
//               child: Text(
//                 'No quizzes available for this course.',
//                 style: TextStyle(fontSize: 16, color: AppColors.textMuted),
//               ),
//             )
//           else
//             ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _quizzes.length,
//               itemBuilder: (context, index) {
//                 final quiz = _quizzes[index];
//                 return Card(
//                   margin: const EdgeInsets.symmetric(vertical: 8),
//                   elevation: 5,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                   color: Colors.deepPurple.shade50,
//                   child: ListTile(
//                     contentPadding: const EdgeInsets.all(16),
//                     leading: CircleAvatar(
//                       backgroundColor: Colors.deepPurple.shade200,
//                       child: const Icon(Icons.quiz, color: Colors.white),
//                     ),
//                     title: Text(
//                       quiz.title,
//                       style: TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.deepPurple.shade900,
//                       ),
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const SizedBox(height: 6),
//                         Text(
//                           quiz.description,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(color: Colors.deepPurple.shade700),
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           children: [
//                             Icon(Icons.timer, size: 16, color: Colors.deepPurple),
//                             const SizedBox(width: 4),
//                             Text(
//                               '${quiz.durationMinutes} mins',
//                               style: TextStyle(color: Colors.deepPurple.shade800),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.deepPurple),
//                     onTap: () => _enterQuizRoom(quiz),
//                   ),
//                 );
//               },
//             ),
//
//           // Tools Tab
//           ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: course.tools?.length ?? 0,
//             itemBuilder: (context, index) {
//               final tool = course.tools![index];
//               return ToolsCard(
//                 toolsName: tool.toolsName,
//                 imgUrl: tool.toolsIcon,
//                 toolUrl: tool.url,
//               );
//             },
//           ),
//
//           // Reviews Tab
//           GridView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: course.reviews?.length ?? 0,
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               mainAxisSpacing: 16,
//               crossAxisSpacing: 16,
//               childAspectRatio: 0.85,
//             ),
//             itemBuilder: (context, index) {
//               final r = course.reviews![index];
//               return ReviewCard(
//                 img: 'https://via.placeholder.com/100',
//                 title: r.user?.uname ?? 'Anonymous',
//                 rating: r.rating ?? 0,
//                 desc: r.review ?? '',
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }



// import 'package:black_box/db/exam/exam_dao.dart';
// import 'package:black_box/model/exam/exam_model.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:internet_connection_checker/internet_connection_checker.dart';
// import 'package:lottie/lottie.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
//
// import '../../components/course/review_card.dart';
// import '../../components/course/tools_card.dart';
// import '../../model/course/course_model.dart';
// import '../../style/color/app_color.dart';
//
// class DetailCourseScreen extends StatefulWidget {
//   final CourseModel course;
//   const DetailCourseScreen({Key? key, required this.course}) : super(key: key);
//
//   @override
//   State<StatefulWidget> createState() => DetailCourseScreenState();
// }
//
//
// class DetailCourseScreenState extends State<DetailCourseScreen> with SingleTickerProviderStateMixin{
//
//   final List<ExamModel> _quizzes = [];
//   bool _isQuizLoading = false;
//
//   late TabController _tabController;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 5, vsync: this);
//     _tabController.addListener(() {
//       if (_tabController.index == 2) {
//         _loadQuizzesForCourse();
//       }
//     });
//   }
//
//
//   Future<void> _loadQuizzesForCourse() async {
//     setState(() {
//       _isQuizLoading = true;
//     });
//
//     try {
//       bool hasInternet = await InternetConnectionChecker.instance.hasConnection;
//
//       if (hasInternet) {
//         // Load quizzes for this course from Firestore
//         final querySnapshot = await FirebaseFirestore.instance
//             .collection('quizzes')
//             .where('course_id', isEqualTo: widget.course.uniqueId)
//             .get();
//
//         final fetchedQuizzes = querySnapshot.docs.map((doc) {
//           final data = doc.data();
//           return ExamModel.fromJson(data);
//         }).toList();
//
//         setState(() {
//           _quizzes.clear();
//           _quizzes.addAll(fetchedQuizzes);
//         });
//       } else {
//         // Load from SQLite offline
//         final localQuizzes = await ExamDAO().getExamsByCourseId(widget.course.uniqueId!);
//         setState(() {
//           _quizzes.clear();
//           _quizzes.addAll(localQuizzes);
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading quizzes: $e')),
//       );
//     } finally {
//       setState(() {
//         _isQuizLoading = false;
//       });
//     }
//   }
//
//   Future<void> _enterQuizRoom(ExamModel quiz) async {
//     // implement your existing enter quiz logic here, possibly injecting this method
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     CourseModel course = widget.course;
//
//     return DefaultTabController(
//       length: 5,
//       child: Scaffold(
//         backgroundColor: AppColors.background,
//         appBar: PreferredSize(
//           preferredSize: const Size.fromHeight(250),
//           child: AppBar(
//             elevation: 0,
//             backgroundColor: Colors.transparent,
//             leading: IconButton(
//               onPressed: () => Navigator.of(context).pop(),
//               icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textLight),
//             ),
//             centerTitle: true,
//             title: const Text(
//               'Course Details',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textLight),
//             ),
//             actions: [
//               IconButton(
//                 onPressed: () {
//                   // Navigator.push(
//                   //   context,
//                   //   MaterialPageRoute(
//                   //     builder: (context) =>
//                   //         TutorStudentMonthly(
//                   //             student: student),
//                   //   ),
//                   // );
//                 },
//                 icon: const Icon(Icons.dashboard_customize, color: AppColors.textLight),
//                 tooltip: 'Course Manager',
//               ),
//             ],
//             flexibleSpace: Container(
//               color: Colors.black54, // fallback background
//               child: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   // Background image with error handling
//                   (course.courseImage != null && course.courseImage!.isNotEmpty)
//                       ? Image.network(
//                     course.courseImage!,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Image.asset(
//                         'assets/background.jpg',
//                         fit: BoxFit.cover,
//                       );
//                     },
//                   )
//                       : Image.asset(
//                     'assets/background.jpg',
//                     fit: BoxFit.cover,
//                   ),
//
//                   // Dark overlay
//                   Container(
//                     color: Colors.black.withOpacity(0.5),
//                   ),
//
//                   // Foreground content
//                   Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const SizedBox(height: 50),
//                       Text(
//                         course.courseName ?? '',
//                         style: const TextStyle(
//                           fontSize: 24,
//                           color: AppColors.textLight,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 16),
//                       TextButton.icon(
//                         onPressed: () {
//                           final firstVideoUrl = course.sections?.first.materials?.first.url ?? '';
//                           final videoId = YoutubePlayer.convertUrlToId(firstVideoUrl);
//                           if (videoId != null) {
//                             showDialog(
//                               context: context,
//                               builder: (context) => SimpleDialog(
//                                 contentPadding: EdgeInsets.zero,
//                                 children: [
//                                   SizedBox(
//                                     height: 200,
//                                     child: YoutubePlayer(
//                                       controller: YoutubePlayerController(
//                                         initialVideoId: videoId,
//                                         flags: const YoutubePlayerFlags(autoPlay: true),
//                                       ),
//                                       bottomActions: const [
//                                         CurrentPosition(),
//                                         ProgressBar(isExpanded: true),
//                                         RemainingDuration(),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           }
//                         },
//                         icon: const Icon(Icons.play_circle_outline_outlined, color: AppColors.textLight),
//                         label: const Text(
//                           'Preview Course',
//                           style: TextStyle(
//                             color: AppColors.textLight,
//                             fontWeight: FontWeight.w500,
//                             fontSize: 14,
//                           ),
//                         ),
//                         style: TextButton.styleFrom(
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             bottom: TabBar(
//               indicatorColor: AppColors.textLight,
//               labelColor: AppColors.textLight,
//               unselectedLabelColor: AppColors.textMuted,
//               indicatorWeight: 3,
//               tabs: const [
//                 Tab(text: 'About'),
//                 Tab(text: 'Lessons'),
//                 Tab(text: 'Quiz'),
//                 Tab(text: 'Tools'),
//                 Tab(text: 'Reviews'),
//               ],
//             ),
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             // About
//             SingleChildScrollView(
//               padding: const EdgeInsets.all(24),
//               child: Text(
//                 course.description ?? 'No description available.',
//                 style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textPrimary),
//               ),
//             ),
//
//             // Lessons
//             ListView.separated(
//               padding: const EdgeInsets.all(16),
//               itemCount: course.sections?.length ?? 0,
//               separatorBuilder: (_, __) => const SizedBox(height: 16),
//               itemBuilder: (context, index) {
//                 final sec = course.sections![index];
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       sec.sectionName ?? '',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.textPrimary,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     ListView.separated(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: sec.materials?.length ?? 0,
//                       separatorBuilder: (_, __) => const SizedBox(height: 8),
//                       itemBuilder: (context, subIndex) {
//                         final mat = sec.materials![subIndex];
//                         final icon = switch (mat.materialType) {
//                           'slide' => Icons.slideshow_rounded,
//                           'quiz' => Icons.quiz_outlined,
//                           _ => Icons.play_circle_fill_rounded,
//                         };
//                         return Container(
//                           decoration: BoxDecoration(
//                             color: AppColors.surface,
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 6,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: ListTile(
//                             leading: Icon(icon, color: AppColors.primary),
//                             title: Text(
//                               mat.materialName ?? '',
//                               style: const TextStyle(
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.w500,
//                                 color: AppColors.textPrimary,
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                 );
//               },
//             ),
//
//             // Quiz
//             Builder(
//               builder: (context) {
//                 if (_isQuizLoading) {
//                   return Center(
//                     child: Lottie.asset(
//                       'animation/ (1).json',
//                       height: 120,
//                     ),
//                   );
//                 }
//
//                 if (_quizzes.isEmpty) {
//                   return Center(
//                     child: Text(
//                       'No quizzes available for this course.',
//                       style: TextStyle(fontSize: 16, color: AppColors.textMuted),
//                     ),
//                   );
//                 }
//
//                 return ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: _quizzes.length,
//                   itemBuilder: (context, index) {
//                     final quiz = _quizzes[index];
//                     return Card(
//                       margin: const EdgeInsets.symmetric(vertical: 8),
//                       elevation: 5,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                       color: Colors.deepPurple.shade50,
//                       child: ListTile(
//                         contentPadding: const EdgeInsets.all(16),
//                         leading: CircleAvatar(
//                           backgroundColor: Colors.deepPurple.shade200,
//                           child: const Icon(Icons.quiz, color: Colors.white),
//                         ),
//                         title: Text(
//                           quiz.title,
//                           style: TextStyle(
//                             fontSize: 17,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.deepPurple.shade900,
//                           ),
//                         ),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const SizedBox(height: 6),
//                             Text(
//                               quiz.description,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(color: Colors.deepPurple.shade700),
//                             ),
//                             const SizedBox(height: 8),
//                             Row(
//                               children: [
//                                 Icon(Icons.timer, size: 16, color: Colors.deepPurple),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   '${quiz.durationMinutes} mins',
//                                   style: TextStyle(color: Colors.deepPurple.shade800),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                         trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.deepPurple),
//                         onTap: () => _enterQuizRoom(quiz),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//
//
//
//             // Tools
//             ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: course.tools?.length ?? 0,
//               itemBuilder: (context, index) {
//                 final tool = course.tools![index];
//                 return ToolsCard(
//                   toolsName: tool.toolsName,
//                   imgUrl: tool.toolsIcon,
//                   toolUrl: tool.url,
//                 );
//               },
//             ),
//
//             // Reviews
//             GridView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: course.reviews?.length ?? 0,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 mainAxisSpacing: 16,
//                 crossAxisSpacing: 16,
//                 childAspectRatio: 0.85,
//               ),
//               itemBuilder: (context, index) {
//                 final r = course.reviews![index];
//                 return ReviewCard(
//                   img: 'https://via.placeholder.com/100',
//                   title: r.user?.uname ?? 'Anonymous',
//                   rating: r.rating ?? 0,
//                   desc: r.review ?? '',
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
// }

// import 'package:flutter/material.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
//
// import '../../components/course/review_card.dart';
// import '../../components/course/tools_card.dart';
// import '../../model/course/course_model.dart';
//
// class DetailCourseScreen extends StatelessWidget {
//   final CourseModel course;
//   const DetailCourseScreen({Key? key, required this.course}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 4,
//       child: Scaffold(
//         appBar: PreferredSize(
//           preferredSize: const Size.fromHeight(250),
//           child: AppBar(
//             leading: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 7),
//               child: CircleAvatar(
//                 backgroundColor: Colors.white30,
//                 child: IconButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   icon: const Icon(Icons.chevron_left_outlined, color: Colors.white),
//                 ),
//               ),
//             ),
//             centerTitle: true,
//             title: const Text('Details Course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             flexibleSpace: (course.courseImage != null && course.courseImage!.isNotEmpty)
//                 ? Container(
//               decoration: BoxDecoration(
//                 image: DecorationImage(
//                   image: NetworkImage(course.courseImage!),
//                   fit: BoxFit.cover,
//                   colorFilter: ColorFilter.mode(
//                     Colors.black.withOpacity(0.5),
//                     BlendMode.darken,
//                   ),
//                 ),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const SizedBox(height: 50),
//                   Text(course.courseName ?? '', style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 8),
//                   TextButton.icon(
//                     onPressed: () {
//                       final firstVideoUrl = course.sections?.first.materials?.first.url ?? '';
//                       final videoId = YoutubePlayer.convertUrlToId(firstVideoUrl);
//                       if (videoId != null) {
//                         showDialog(
//                           context: context,
//                           builder: (context) => SimpleDialog(
//                             contentPadding: EdgeInsets.zero,
//                             children: [
//                               SizedBox(
//                                 height: 200,
//                                 child: YoutubePlayer(
//                                   controller: YoutubePlayerController(
//                                     initialVideoId: videoId,
//                                     flags: const YoutubePlayerFlags(autoPlay: true),
//                                   ),
//                                   bottomActions: const [
//                                     CurrentPosition(),
//                                     ProgressBar(isExpanded: true),
//                                     RemainingDuration(),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       }
//                     },
//                     icon: const Icon(Icons.play_circle_outline_outlined, color: Colors.white),
//                     label: const Text('Preview Course', style: TextStyle(color: Colors.white)),
//                   ),
//                 ],
//               ),
//             )
//                 : null,
//             bottom: const TabBar(
//               indicatorColor: Colors.white,
//               labelColor: Colors.white,
//               tabs: [
//                 Tab(text: 'About'),
//                 Tab(text: 'Lesson'),
//                 Tab(text: 'Tools'),
//                 Tab(text: 'Reviews'),
//               ],
//             ),
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             SingleChildScrollView(
//               padding: const EdgeInsets.all(24),
//               child: Text(course.description ?? 'No description available.'),
//             ),
//             ListView.separated(
//               padding: const EdgeInsets.all(12),
//               itemCount: course.sections?.length ?? 0,
//               separatorBuilder: (_, __) => const SizedBox(height: 12),
//               itemBuilder: (context, index) {
//                 final sec = course.sections![index];
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(sec.sectionName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                     const SizedBox(height: 8),
//                     ListView.separated(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: sec.materials?.length ?? 0,
//                       separatorBuilder: (_, __) => const SizedBox(height: 6),
//                       itemBuilder: (context, subIndex) {
//                         final mat = sec.materials![subIndex];
//                         final icon = switch (mat.materialType) {
//                           'slide' => Icons.slideshow,
//                           'quiz' => Icons.quiz,
//                           _ => Icons.play_circle_fill,
//                         };
//                         return ListTile(
//                           tileColor: Colors.grey[200],
//                           leading: Icon(icon),
//                           title: Text(mat.materialName ?? ''),
//                         );
//                       },
//                     )
//                   ],
//                 );
//               },
//             ),
//             ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: course.tools?.length ?? 0,
//               itemBuilder: (context, index) {
//                 final tool = course.tools![index];
//                 return ToolsCard(
//                   toolsName: tool.toolsName,
//                   imgUrl: tool.toolsIcon,
//                   toolUrl: tool.url,
//                 );
//               },
//             ),
//             GridView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: course.reviews?.length ?? 0,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
//               itemBuilder: (context, index) {
//                 final r = course.reviews![index];
//                 return ReviewCard(
//                   img: 'https://via.placeholder.com/100',
//                   title: r.user?.uname ?? 'Anonymous',
//                   rating: r.rating ?? 0,
//                   desc: r.review ?? '',
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



// flexibleSpace: (course.courseImage != null && course.courseImage!.isNotEmpty)
// ? Container(
// decoration: BoxDecoration(
// image: DecorationImage(
// image: NetworkImage(course.courseImage!),
// errorBuilder: (context, Object exception, stackTrace) {
// return Image.asset(
// 'assets/empty_image.png',
// fit: BoxFit.cover,
// );
// },
// fit: BoxFit.cover,
// colorFilter: ColorFilter.mode(
// Colors.black.withOpacity(0.5),
// BlendMode.darken,
// ),
//
// ),
// ),
// child: Column(
// mainAxisAlignment: MainAxisAlignment.center,
// children: [
// const SizedBox(height: 50),
// Text(
// course.courseName ?? '',
// style: const TextStyle(
// fontSize: 24,
// color: AppColors.textLight,
// fontWeight: FontWeight.bold,
// ),
// textAlign: TextAlign.center,
// ),
// const SizedBox(height: 16),
// TextButton.icon(
// onPressed: () {
// final firstVideoUrl = course.sections?.first.materials?.first.url ?? '';
// final videoId = YoutubePlayer.convertUrlToId(firstVideoUrl);
// if (videoId != null) {
// showDialog(
// context: context,
// builder: (context) => SimpleDialog(
// contentPadding: EdgeInsets.zero,
// children: [
// SizedBox(
// height: 200,
// child: YoutubePlayer(
// controller: YoutubePlayerController(
// initialVideoId: videoId,
// flags: const YoutubePlayerFlags(autoPlay: true),
// ),
// bottomActions: const [
// CurrentPosition(),
// ProgressBar(isExpanded: true),
// RemainingDuration(),
// ],
// ),
// ),
// ],
// ),
// );
// }
// },
// icon: const Icon(Icons.play_circle_outline_outlined, color: AppColors.textLight),
// label: const Text(
// 'Preview Course',
// style: TextStyle(
// color: AppColors.textLight,
// fontWeight: FontWeight.w500,
// fontSize: 14,
// ),
// ),
// style: TextButton.styleFrom(
// foregroundColor: Colors.white,
// shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
// ),
// ),
// ],
// ),
// )
// : null,