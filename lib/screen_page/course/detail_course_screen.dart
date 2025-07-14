import 'dart:convert';
import 'dart:io';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:black_box/db/exam/exam_dao.dart';
import 'package:black_box/model/exam/exam_model.dart';
import 'package:black_box/screen_page/exam/exam_panel.dart';
import 'package:black_box/screen_page/exam/exam_question_management_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../components/course/review_card.dart';
import '../../components/course/tools_card.dart';
import '../../db/exam/question_dao.dart';
import '../../db/firebase/exam_firebase_service.dart';
import '../../model/course/course_model.dart';
import '../../model/course/teacher.dart';
import '../../model/school/school.dart';
import '../../model/user/user.dart';
import '../../preference/logout.dart';
import '../../quiz/QuestionManagementDetailPage.dart';
import '../../style/color/app_color.dart';
import '../../utility/unique.dart';
import '../exam/exam_results_page.dart';

class DetailCourseScreen extends StatefulWidget {
  final CourseModel course;
  const DetailCourseScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<DetailCourseScreen> createState() => _DetailCourseScreenState();
}

class _DetailCourseScreenState extends State<DetailCourseScreen>
    with SingleTickerProviderStateMixin {
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
    setState(() {
      isLoading = true;
    });

    try {
      final hasInternet =
          await InternetConnectionChecker.instance.hasConnection;

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
          isLoading = false;
        });
      } else {
        final localQuizzes =
            await ExamDAO().getExamsByCourseId(widget.course.uniqueId!);
        setState(() {
          _quizzes
            ..clear()
            ..addAll(localQuizzes);
          _quizzesLoadedOnce = true;
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading quizzes: $e')),
      );
    } finally {
      setState(() => _isQuizLoading = false);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _enterQuizRoom(ExamModel quiz) async {
    if (quiz.userId == _user?.userid){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamQuestionManagementPage(exam: quiz),
        ),
      );
    }else{
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamPanel(user: _user!, exam: quiz),
        ),
      );
    }
  }

  void _addExamOrQuiz(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController durationController = TextEditingController();
    final TextEditingController subjectIdController = TextEditingController();
    final TextEditingController mediaUrlController = TextEditingController();
    final TextEditingController mediaTypeController = TextEditingController();

    String selectedExamType = ExamTypes.quiz;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title bar
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Create New Exam / Quiz",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(titleController, 'Title', Icons.title),
                  const SizedBox(height: 12),

                  _buildTextField(
                      descriptionController, 'Description', Icons.description),
                  const SizedBox(height: 12),

                  _buildNumberField(
                      durationController, 'Duration (minutes)', Icons.timer),
                  const SizedBox(height: 12),

                  _buildTextField(
                      subjectIdController, 'Subject ID', Icons.book),
                  const SizedBox(height: 12),

                  _buildTextField(
                      mediaUrlController, 'Media URL (optional)', Icons.image),
                  const SizedBox(height: 12),

                  _buildTextField(mediaTypeController,
                      'Media Type (image, video, etc)', Icons.perm_media),
                  const SizedBox(height: 12),

                  // Exam Type Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedExamType,
                    decoration: InputDecoration(
                      labelText: 'Exam Type',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ExamTypes.values
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(e.toUpperCase())))
                        .toList(),
                    onChanged: (val) => setModalState(
                        () => selectedExamType = val ?? ExamTypes.quiz),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (titleController.text.isEmpty ||
                                  descriptionController.text.isEmpty ||
                                  durationController.text.isEmpty ||
                                  subjectIdController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "All fields except media are required")),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);

                              try {
                                String uniqueId = Unique().generateUniqueID();
                                String examId = uniqueId;

                                final exam = ExamModel(
                                  uniqueId: uniqueId,
                                  examId: examId,
                                  title: titleController.text.trim(),
                                  description:
                                      descriptionController.text.trim(),
                                  createdAt: DateTime.now().toIso8601String(),
                                  durationMinutes: int.tryParse(
                                          durationController.text.trim()) ??
                                      1,
                                  status: 1,
                                  examType: selectedExamType,
                                  subjectId: subjectIdController.text.trim(),
                                  courseId: widget.course.uniqueId,
                                  userId: _user?.userid,
                                  mediaUrl:
                                      mediaUrlController.text.trim().isEmpty
                                          ? null
                                          : mediaUrlController.text.trim(),
                                  mediaType:
                                      mediaTypeController.text.trim().isEmpty
                                          ? null
                                          : mediaTypeController.text.trim(),
                                );

                                await _createExam(exam);

                                setModalState(() => isSaving = false);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Exam/Quiz created successfully!")),
                                );

                                Navigator.pop(context);
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                print("Error creating exam: $e");
                              }
                            },
                      // onPressed: isSaving
                      //     ? null
                      //     : () async {
                      //         if (titleController.text.isEmpty ||
                      //             descriptionController.text.isEmpty ||
                      //             durationController.text.isEmpty ||
                      //             subjectIdController.text.isEmpty) {
                      //           ScaffoldMessenger.of(context).showSnackBar(
                      //             const SnackBar(
                      //                 content: Text(
                      //                     "All fields except media are required")),
                      //           );
                      //           return;
                      //         }
                      //
                      //         setModalState(() => isSaving = true);
                      //
                      //         String uniqueId = Unique().generateUniqueID();
                      //         String examId = uniqueId;
                      //
                      //         final exam = ExamModel(
                      //           uniqueId: uniqueId,
                      //           examId: examId,
                      //           title: titleController.text.trim(),
                      //           description: descriptionController.text.trim(),
                      //           createdAt: DateTime.now().toIso8601String(),
                      //           durationMinutes: int.tryParse(
                      //                   durationController.text.trim()) ??
                      //               1,
                      //           status: 1,
                      //           examType: selectedExamType,
                      //           subjectId: subjectIdController.text.trim(),
                      //           courseId: widget.course.uniqueId,
                      //           userId: _user?.userid,
                      //           mediaUrl: mediaUrlController.text.trim().isEmpty
                      //               ? null
                      //               : mediaUrlController.text.trim(),
                      //           mediaType:
                      //               mediaTypeController.text.trim().isEmpty
                      //                   ? null
                      //                   : mediaTypeController.text.trim(),
                      //           questions: [],
                      //         );
                      //
                      //         // await ExamDAO().insertExam(exam);
                      //
                      //         await _createExam(exam);
                      //
                      //         setModalState(() => isSaving = false);
                      //
                      //         ScaffoldMessenger.of(context).showSnackBar(
                      //           const SnackBar(
                      //               content: Text(
                      //                   "Exam/Quiz created successfully!")),
                      //         );
                      //
                      //         Navigator.pop(context);
                      //       },
                      icon: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label:
                          Text(isSaving ? 'Saving...' : 'Create Exam / Quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void copyExam(ExamModel exam) {
    String? tempNum = exam.uniqueId;

    if (tempNum != null && tempNum.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: tempNum)).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exam Code copied: $tempNum')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to copy: $error')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No Exam Code to copy')),
      );
    }
  }

  void shareExam(ExamModel exam) {
    String? tempNum = exam.uniqueId;
    String? tempCode = exam.uniqueId;

    if (tempNum != null && tempCode != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Share Exam'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Barcode for Tracking Number:'),
                SizedBox(height: 10),
                BarcodeWidget(
                  barcode: Barcode.code128(), // Choose the barcode format
                  data: tempNum,
                  width: 200,
                  height: 100,
                ),
                SizedBox(height: 20),
                Text('QR Code for Exam Code:'),
                SizedBox(height: 10),
                BarcodeWidget(
                  barcode: Barcode.qrCode(), // QR code format
                  data: tempCode,
                  width: 200,
                  height: 200,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exam data is incomplete for sharing')),
      );
    }
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
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textLight),
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
              icon: const Icon(Icons.dashboard_customize,
                  color: AppColors.textLight),
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
                        final firstVideoUrl =
                            course.sections?.first.materials?.first.url ?? '';
                        final videoId =
                            YoutubePlayer.convertUrlToId(firstVideoUrl);
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
                                      flags: const YoutubePlayerFlags(
                                          autoPlay: true),
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
                      icon: const Icon(Icons.play_circle_outline_outlined,
                          color: AppColors.textLight),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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
              style: const TextStyle(
                  fontSize: 16, height: 1.5, color: AppColors.textPrimary),
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
                        style:
                            TextStyle(fontSize: 16, color: AppColors.textMuted),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
                                style: TextStyle(
                                    color: Colors.deepPurple.shade700),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.timer,
                                      size: 16, color: Colors.deepPurple),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${quiz.durationMinutes} mins',
                                    style: TextStyle(
                                        color: Colors.deepPurple.shade800),
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'copy') {
                                        copyExam(quiz);
                                      } else if (value == 'room') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ExamPanel(user: _user!, exam: quiz),
                                          ),
                                        );
                                      } else if (value == 'result') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ExamResultsPage(quizId: quiz.uniqueId),
                                          ),
                                        );
                                      } else if (value == 'mentor') {
                                        // _openWhatsApp(student.phone??"");
                                      } else if (value == 'delete') {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Confirm'),
                                            content: Text(
                                                'Are you sure you want to Delete "${quiz.title}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  _deleteExamQuiz(quiz);
                                                  Navigator.pop(context, true);
                                                },
                                                child: const Text(
                                                  'Continue to Enroll',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else if (value == 'share') {
                                        shareExam(quiz);
                                      } else if (value == 'go') {
                                        // Navigator.push(
                                        //   context,
                                        //   MaterialPageRoute(
                                        //     builder: (context) =>
                                        //         TutorStudentMonthly(
                                        //             student: student),
                                        //   ),
                                        // );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                          value: 'room',
                                          child: Text('Enter Quiz Room')),
                                      const PopupMenuItem(
                                          value: 'result', child: Text('Result')),
                                      const PopupMenuItem(
                                          value: 'copy',
                                          child: Text('Copy')),
                                      const PopupMenuItem(
                                          value: 'share',
                                          child: Text('Share')),
                                      const PopupMenuItem(
                                          value: 'go',
                                          child: Text('Attendance')),
                                      const PopupMenuItem(
                                          value: 'mentor',
                                          child: Text('Mentor')),
                                      const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete')),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.deepPurple),
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
                    onPressed: () => _addExamOrQuiz(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, // Text color
                      backgroundColor: Colors.blue, // Button color
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(25), // Rounded edges
                      ),
                      elevation: 5, // Shadow effect
                    ),
                    // onPressed: () {  },
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
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
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

  Future<void> _deleteExamQuiz(ExamModel exam) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      // Delete from Firebase
      await ExamFirebaseService().deleteExam(exam.examId);

      // Delete related questions locally
      await QuestionDAO().deleteQuestionsByExamId(exam.examId);

      // Delete exam locally
      await ExamDAO().deleteExamByUniqueId(exam.examId);

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam and related data deleted successfully!')),
      );

      Navigator.pop(context);
    } catch (e, stacktrace) {
      print("Error deleting exam: $e\n$stacktrace");

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete exam. Please try again.')),
      );
    }
  }


  Future<void> _createExam(ExamModel exam) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      // Save exam online (Firebase) and get the generated examId if necessary
      final firebaseExam = await ExamFirebaseService().addOrUpdateExam(exam);

      // Save exam locally (SQLite)
      await ExamDAO().insertExam(firebaseExam);

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam Created Successfully!')),
      );

      Navigator.pop(context);
    } catch (e, stacktrace) {
      print("Error creating exam: $e\n$stacktrace");

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to create exam. Please try again.')),
      );
    }
  }
}



Widget _buildTextField(
    TextEditingController controller, String labelText, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.pinkAccent),
        prefixIcon: Icon(icon, color: Colors.pinkAccent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.pinkAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      ),
    ),
  );
}

Widget _buildNumberField(
    TextEditingController controller, String labelText, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.pinkAccent),
        prefixIcon: Icon(icon, color: Colors.pinkAccent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.pinkAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      ),
    ),
  );
}

Widget _buildComboTextDropdownField({
  required TextEditingController controller,
  required String labelText,
  required IconData icon,
  required List<String> items,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            color: Colors.pinkAccent,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Text input field
            Expanded(
              flex: 2,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: Colors.pinkAccent),
                  hintText: "Enter or pick",
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.pinkAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide:
                        const BorderSide(color: Colors.pinkAccent, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Searchable Dropdown Button
            SizedBox(
              width: 50,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.pinkAccent,
                ),
                child: DropdownSearch<String>(
                  popupProps: PopupProps.dialog(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                    itemBuilder: (context, item, isSelected) => ListTile(
                      title: Text(item),
                    ),
                  ),
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  items: items,
                  onChanged: (value) {
                    if (value != null) {
                      controller.text = value;
                    }
                  },
                  dropdownBuilder: (context, selectedItem) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_drop_down, color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
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
