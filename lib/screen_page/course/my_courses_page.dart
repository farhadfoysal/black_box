import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:black_box/db/course/course_dao.dart';
import 'package:black_box/db/course/course_enrollment_dao.dart';
import 'package:black_box/model/course/course_model_db_mapper.dart';
import 'package:black_box/model/school/teacher.dart';
import 'package:black_box/routes/routes.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../db/course/course_favorite_dao.dart';
import '../../dummies/categories_d.dart';
import '../../model/course/enrollment.dart';
import '../../model/course/favorite.dart';
import '../../model/course/video_course.dart';
import '../../components/components.dart';
import '../../components/course/course_card.dart';
import '../../model/course/course_model.dart';
import '../../model/school/school.dart';
import '../../model/tutor/tutor_student.dart';
import '../../model/tutor/tutor_week_day.dart';
import '../../model/user/user.dart';
import '../../preference/logout.dart';
import '../../routes/app_router.dart';
import '../../services/course/supabse_service.dart';
import '../../utility/unique.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({Key? key}) : super(key: key);

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
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
  final TextEditingController controller = TextEditingController();

  final List<String> categoryNames =
      categoriesJSON.map((e) => e['name'] as String).toList();

  final List<CourseModel> allCourses = [
    CourseModel(
      courseName: 'Flutter Beginner',
      totalVideo: 10,
      totalRating: 4.5,
      totalTime: '2h 30m',
      courseImage:
      'https://fastly.picsum.photos/id/870/200/300.jpg?blur=2&grayscale&hmac=ujRymp644uYVjdKJM7kyLDSsrqNSMVRPnGU99cKl6Vs',
      level: 'Beginner',
      countStudents: 120,
      createdAt: DateTime.now(),
      status: 'active',
    ),
  ];

  List<CourseModel> filteredCourses = [];

  @override
  void initState() {
    super.initState();
    filteredCourses = List.from(allCourses);
    _loadUserName();
    setState(() {
      isLoading = true;
      // isLoading = false;
    });
    _initializeData();
  }

  Future<void> _initializeData() async {
    // First load user data
    await _loadUserData();
    _loadCoursesData();
  }

  Future<void> _loadCoursesData() async {
    if (await InternetConnectionChecker.instance.hasConnection) {
      setState(() {
        isLoading = true;
      });

      DatabaseReference teachersRef = _databaseRef.child('courses');

      Query query = teachersRef.orderByChild('user_id').equalTo(_user?.userid);

      query.once().then((DatabaseEvent event) {
        final dataSnapshot = event.snapshot;

        if (dataSnapshot.exists) {
          final Map<dynamic, dynamic> coursesData =
              dataSnapshot.value as Map<dynamic, dynamic>;

          setState(() {
            filteredCourses.clear();

            filteredCourses = coursesData.entries.map((entry) {
              // Convert each entry's value to Map<String, dynamic>
              final courseMap = Map<String, dynamic>.from(entry.value as Map);

              return CourseModel.fromJson(courseMap);
            }).toList();

            // Convert the students data into a list of TutorStudent objects
            // students = studentsData.entries.map((entry) {
            //   Map<String, dynamic> studentMap = {
            //     'id': entry.value['id'] ?? null,
            //     'unique_id': entry.value['unique_id'] ?? null,
            //     'user_id': entry.value['user_id'] ?? null,
            //     'name': entry.value['name'] ?? null,
            //     'phone': entry.value['phone'] ?? null,
            //     'gaurdian_phone': entry.value['gaurdian_phone'] ?? null,
            //     'phone_pass': entry.value['phone_pass'] ?? null,
            //     'dob': entry.value['dob'] ?? null,
            //     'education': entry.value['education'] ?? null,
            //     'address': entry.value['address'] ?? null,
            //     'active_status': entry.value['active_status'] ?? null,
            //     'admitted_date': entry.value['admitted_date'] ?? null,
            //     'img': entry.value['img'] ?? null,
            //     'days': entry.value['days'] != null
            //         ? (entry.value['days'] as List)
            //         .map((day) => TutorWeekDay.fromJson(day))
            //         .toList()
            //         : null,
            //   };
            //   return TutorStudent.fromJson(studentMap);
            // }).toList();

            isLoading = false;
          });
        } else {
          print(_user?.userid);
          print('No Course data available for the current User.');
          setState(() {
            isLoading = false;
          });
        }
      }).catchError((error) {
        print('Failed to load Course data: $error');
        setState(() {
          isLoading = false;
        });
      });
    } else {
      List<CourseModel> courseList =
          await CourseDAO().getCoursesByUserId(_user!.userid!);

      if (!courseList.isEmpty) {
        setState(() {
          filteredCourses.clear();
          filteredCourses = courseList;
          isLoading = false;
        });
      } else {
        showSnackBarMsg(context,
            "You are in Offline mode now, Please, connect to the Internet!");
        setState(() {
          // teachers = data.map((json) => Teacher.fromJson(json)).toList();
          isLoading = false;
        });
      }
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

  void _onSwipe1(int index) {
    setState(() {
      _currentIndex1 = index;
    });
  }

  void _onSwipe2(int index) {
    setState(() {
      _currentIndex2 = index;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> signOut() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully signed out')),
    );
    await AppRouter.logoutUser(context);
  }

  void _addCourse(BuildContext context) {
    final TextEditingController courseNameController = TextEditingController();
    final TextEditingController bannerUrlController = TextEditingController();
    final TextEditingController aboutController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();
    final TextEditingController feeController = TextEditingController();
    final TextEditingController discountController = TextEditingController();

    String? selectedLevel;
    String? selectedStatus;
    bool isSaving = false; // local state for save button

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        "Add New Course",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                      courseNameController, 'Course Name', Icons.text_fields),
                  const SizedBox(height: 12),

                  _buildTextField(bannerUrlController,
                      'Course Banner Image URL', Icons.image),
                  const SizedBox(height: 12),

                  _buildComboTextDropdownField(
                    controller: categoryController,
                    labelText: 'Category (Enter or Pick)',
                    icon: Icons.category,
                    items: categoryNames,
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TextField(
                      controller: aboutController,
                      minLines: 5,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        labelText: 'About Course',
                        labelStyle: TextStyle(color: Colors.pinkAccent),
                        alignLabelWithHint: true,
                        prefixIcon:
                            Icon(Icons.description, color: Colors.pinkAccent),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.pinkAccent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide:
                              BorderSide(color: Colors.pinkAccent, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration: InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Beginner', 'Intermediate', 'Professional', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedLevel = val),
                  ),
                  const SizedBox(height: 12),

                  _buildNumberField(
                      feeController, 'Fee (৳)', Icons.attach_money),
                  const SizedBox(height: 12),

                  _buildNumberField(
                      discountController, 'Discount (%)', Icons.percent),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Active', 'Inactive', 'Draft']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedStatus = val),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () {
                              setModalState(() => isSaving = true);

                              var uuid = Uuid();
                              String uniqueId = Unique().generateUniqueID();
                              int ranId = Random().nextInt(1000000000) +
                                  DateTime.now().millisecondsSinceEpoch;
                              String referr = String.fromCharCode(
                                  65 + Random().nextInt(26));
                              String numberr = '$ranId$referr';

                              CourseModel courseModel = CourseModel(
                                courseName: courseNameController.text.trim(),
                                courseImage: bannerUrlController.text.trim(),
                                category: categoryController.text.trim(),
                                description: aboutController.text.trim(),
                                fee: double.tryParse(feeController.text),
                                discount:
                                    double.tryParse(discountController.text),
                                uniqueId: uniqueId,
                                userId: _user?.userid,
                                totalVideo: 0,
                                trackingNumber: numberr,
                                totalTime: "1.30",
                                totalRating: 4.7,
                                level: selectedLevel ?? 'Beginner',
                                countStudents: 0,
                                createdAt: DateTime.now(),
                                status: selectedStatus ?? 'Draft',
                              );

                              saveCourse(courseModel);

                              // setModalState(() => isSaving = false);
                              // Navigator.pop(context);
                            },
                      icon: isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.save),
                      label: Text(isSaving ? 'Saving...' : 'Save Course'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _searchCourses(String query) {
    final results = allCourses.where((course) {
      final courseName = course.courseName?.toLowerCase() ?? '';
      return courseName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredCourses = results;
    });
  }

  Future<void> _deleteCourse(CourseModel course) async {
    setState(() {
      isLoading = true;
    });

    try {
      if (await InternetConnectionChecker.instance.hasConnection) {
        // Delete from Firebase Realtime Database
        final DatabaseReference dbRef =
            FirebaseDatabase.instance.ref("courses").child(course.uniqueId!);

        await dbRef.remove();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course deleted from cloud!')),
        );
      }

      // Delete from local Sqflite
      final result = await CourseDAO().deleteCourseByUniqueId(course.uniqueId!);

      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course deleted from offline storage!')),
        );
      }

      // Remove from UI list
      setState(() {
        allCourses.removeWhere((c) => c.uniqueId == course.uniqueId);
        _searchCourses(controller.text);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete course: $e')),
      );
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _editCourse(BuildContext context, CourseModel course) {
    _eCourse(context, existingCourse: course);
  }

  void _eCourse(BuildContext context, {CourseModel? existingCourse}) {
    final TextEditingController courseNameController =
        TextEditingController(text: existingCourse?.courseName ?? '');
    final TextEditingController bannerUrlController =
        TextEditingController(text: existingCourse?.courseImage ?? '');
    final TextEditingController aboutController =
        TextEditingController(text: existingCourse?.description ?? '');
    final TextEditingController categoryController =
        TextEditingController(text: existingCourse?.category ?? '');
    final TextEditingController feeController =
        TextEditingController(text: existingCourse?.fee?.toString() ?? '');
    final TextEditingController discountController =
        TextEditingController(text: existingCourse?.discount?.toString() ?? '');

    String? selectedLevel = existingCourse?.level;
    String? selectedStatus = existingCourse?.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        existingCourse != null
                            ? "Edit Course"
                            : "Add New Course",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                      courseNameController, 'Course Name', Icons.text_fields),
                  const SizedBox(height: 12),
                  _buildTextField(
                      bannerUrlController, 'Banner Image URL', Icons.image),
                  const SizedBox(height: 12),
                  _buildComboTextDropdownField(
                    controller: categoryController,
                    labelText: 'Category (Enter or Pick)',
                    icon: Icons.category,
                    items: categoryNames,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TextField(
                      controller: aboutController,
                      minLines: 4,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        labelText: 'About Course',
                        labelStyle: const TextStyle(color: Colors.pinkAccent),
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.description,
                            color: Colors.pinkAccent),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                              color: Colors.pinkAccent, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration: InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Beginner', 'Intermediate', 'Professional', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedLevel = val),
                  ),
                  const SizedBox(height: 12),
                  _buildNumberField(
                      feeController, 'Fee (৳)', Icons.attach_money),
                  const SizedBox(height: 12),
                  _buildNumberField(
                      discountController, 'Discount (%)', Icons.percent),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Active', 'Inactive', 'Draft']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedStatus = val),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () {
                              setState(() {
                                isLoading = true;
                              });

                              String uniqueId = existingCourse?.uniqueId ??
                                  Unique().generateUniqueID();
                              String trackingNumber = existingCourse
                                      ?.trackingNumber ??
                                  '${Random().nextInt(1000000000)}${String.fromCharCode(65 + Random().nextInt(26))}';

                              final courseModel = CourseModel(
                                uniqueId: uniqueId,
                                trackingNumber: trackingNumber,
                                courseName: courseNameController.text.trim(),
                                courseImage: bannerUrlController.text.trim(),
                                category: categoryController.text.trim(),
                                description: aboutController.text.trim(),
                                fee: double.tryParse(feeController.text),
                                discount:
                                    double.tryParse(discountController.text),
                                totalVideo: existingCourse?.totalVideo ?? 0,
                                totalTime: existingCourse?.totalTime ?? '1.30',
                                totalRating: existingCourse?.totalRating ?? 4.7,
                                level: selectedLevel ?? 'Beginner',
                                countStudents:
                                    existingCourse?.countStudents ?? 0,
                                createdAt:
                                    existingCourse?.createdAt ?? DateTime.now(),
                                status: selectedStatus ?? 'Draft',
                                userId: _user?.userid,
                              );

                              updateCourse(courseModel);
                            },
                      icon: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(isLoading
                          ? 'Saving...'
                          : (existingCourse != null
                              ? 'Update Course'
                              : 'Save Course')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Courses")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(), // Show loading indicator
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      hintText: 'Search course...',
                    ),
                    onChanged: _searchCourses,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredCourses.isEmpty
                        ? Center(
                            child: Text(
                              'No courses found in Your Courses list',
                              style: const TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredCourses.length,
                            itemBuilder: (context, index) {
                              final course = filteredCourses[index];
                              return Dismissible(
                                key: ValueKey(
                                    course.uniqueId), // Use a unique identifier
                                background: Container(
                                  color: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  alignment: Alignment.centerLeft,
                                  child: const Icon(Icons.edit,
                                      color: Colors.white),
                                ),
                                secondaryBackground: Container(
                                  color: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  alignment: Alignment.centerRight,
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.startToEnd) {
                                    // Swipe right to Edit
                                    _editCourse(context, course);
                                    return false; // Don't dismiss the tile
                                  } else if (direction ==
                                      DismissDirection.endToStart) {
                                    // Swipe left to Delete
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Confirm Deletion'),
                                        content: Text(
                                            'Are you sure you want to delete "${course.courseName}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      _deleteCourse(course);
                                      return true; // Dismiss the tile
                                    } else {
                                      return false;
                                    }
                                  }
                                  return false;
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    context.push(Routes.courseDetailPage,
                                        extra: course);
                                  },
                                  child: CourseCard(
                                    courseModel: course,
                                    courseImage: course.courseImage ?? '',
                                    courseName: course.courseName ?? '',
                                    trackingNumber: course.trackingNumber ?? '',
                                    rating: course.totalRating ?? 0,
                                    totalTime: course.totalTime ?? '',
                                    totalVideo:
                                        course.totalVideo?.toString() ?? '0',
                                    onEnroll: () {
                                      // _enrollCourse(course);
                                      enrollCourse(course);
                                    },
                                    onMark: () {
                                      // _markCourse(context,course);
                                      markFavorite(course);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),

                    //     : ListView.builder(
                    //   physics: const BouncingScrollPhysics(),
                    //   itemCount: filteredCourses.length,
                    //   itemBuilder: (context, index) {
                    //     final course = filteredCourses[index];
                    //     return GestureDetector(
                    //       onTap: () async {
                    //         context.push(Routes.courseDetailPage, extra: course);
                    //       },
                    //       child: CourseCard(
                    //         courseModel: course,
                    //         courseImage: course.courseImage ?? '',
                    //         courseName: course.courseName ?? '',
                    //         trackingNumber: course.trackingNumber ?? '',
                    //         rating: course.totalRating ?? 0,
                    //         totalTime: course.totalTime ?? '',
                    //         totalVideo: course.totalVideo?.toString() ?? '0',
                    //       ),
                    //     );
                    //   },
                    // ),
                  ),
                ],
              ),
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () => _addCourse(context),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, // Text color
          backgroundColor: Colors.blue, // Button color
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // Rounded edges
          ),
          elevation: 5, // Shadow effect
        ),
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
                    "Create Course",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ],
        ),
      ),
    );
  }

  // void _enrollCourse(CourseModel course) async {
  //   setState(() => isLoading = true);
  //
  //   try {
  //     final uniqueEnrollId = Unique().generateUniqueID();
  //     final userId = _user?.userid;
  //     final courseId = course.uniqueId;
  //
  //     if (userId == null || courseId == null) {
  //       throw Exception("User ID or Course ID is null");
  //     }
  //
  //     final enrolledAt = DateTime.now();
  //
  //     // Firebase
  //     final enrollRef = FirebaseDatabase.instance
  //         .ref("enrollments")
  //         .child(uniqueEnrollId);
  //
  //     await enrollRef.set({
  //       'unique_id': uniqueEnrollId,
  //       'user_id': userId,
  //       'course_id': courseId,
  //       'enrolled_at': enrolledAt.toIso8601String(),
  //       'status': 'active',
  //     });
  //
  //     // Supabase
  //     final enrollment = Enrollment(
  //       uniqueId: uniqueEnrollId,
  //       userId: userId,
  //       courseId: courseId,
  //       enrolledAt: enrolledAt,
  //       status: 'active',
  //     );
  //     await SupabaseService().enrollCourse(enrollment);
  //
  //     // Sqflite
  //     await CourseEnrollmentDAO().enrollCourse(
  //       uniqueId: uniqueEnrollId,
  //       userId: userId,
  //       courseId: courseId,
  //       status: 'active',
  //     );
  //
  //     showSnackBarMsg(context, "Successfully enrolled in ${course.courseName}!");
  //
  //   } catch (e) {
  //     print("Enrollment failed: $e");
  //     showSnackBarMsg(context, "Failed to enroll in course.");
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }


  // void _markCourse(BuildContext context, CourseModel course) async {
  //   setState(() => isLoading = true);
  //
  //   try {
  //     final favoriteId = Unique().generateUniqueID();
  //     final userId = _user?.userid;
  //     final courseId = course.uniqueId;
  //
  //     if (userId == null || courseId == null) {
  //       throw Exception("User ID or Course ID is null");
  //     }
  //
  //     final markedAt = DateTime.now();
  //
  //     // Firebase
  //     final favRef = FirebaseDatabase.instance
  //         .ref("favorites")
  //         .child(favoriteId);
  //
  //     await favRef.set({
  //       'unique_id': favoriteId,
  //       'user_id': userId,
  //       'course_id': courseId,
  //       'marked_at': markedAt.toIso8601String(),
  //     });
  //
  //     // Supabase
  //     final favorite = Favorite(
  //       uniqueId: favoriteId,
  //       userId: userId,
  //       courseId: courseId,
  //     );
  //     await SupabaseService().favoriteCourse(favorite);
  //
  //     // Sqflite
  //     await CourseFavoriteDAO().favoriteCourse(
  //       uniqueId: favoriteId,
  //       userId: userId,
  //       courseId: courseId,
  //     );
  //
  //     showSnackBarMsg(context, "Marked ${course.courseName} as favorite!");
  //
  //   } catch (e) {
  //     print("Mark as favorite failed: $e");
  //     showSnackBarMsg(context, "Failed to mark as favorite.");
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }


  Future<void> enrollCourse(CourseModel course) async {
    setState(() => isLoading = true);

    final uniqueEnrollId = Unique().generateUniqueID();
    final userId = _user?.userid;
    final courseId = course.uniqueId;

    if (userId == null || courseId == null) {
      showSnackBarMsg(context, "User or Course ID missing.");
      return;
    }

    final enrolledAt = DateTime.now();
    final enrollment = Enrollment(
      uniqueId: uniqueEnrollId,
      userId: userId,
      courseId: courseId,
      enrolledAt: enrolledAt,
      status: 'active',
    );

    final hasConnection = await InternetConnectionChecker.instance.hasConnection;

    try {
      if (hasConnection) {
        //  Firebase
        final enrollRef = FirebaseDatabase.instance
            .ref("enrollments")
            .child(uniqueEnrollId);
        await enrollRef.set(enrollment.toMap());

        //  Supabase
        // await SupabaseService().enrollCourse(enrollment);
      }

      //  Local Sqflite always
      await CourseEnrollmentDAO().enrollCourse(
        uniqueId: uniqueEnrollId,
        userId: userId,
        courseId: courseId,
        status: 'active',
      );

      showSnackBarMsg(context, "Enrolled in ${course.courseName} successfully!");
    } catch (e) {
      print("Enrollment failed: $e");
      showSnackBarMsg(context, "Failed to enroll in course.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> markFavorite(CourseModel course) async {
    setState(() => isLoading = true);

    final favoriteId = Unique().generateUniqueID();
    final userId = _user?.userid;
    final courseId = course.uniqueId;

    if (userId == null || courseId == null) {
      showSnackBarMsg(context, "User or Course ID missing.");
      return;
    }

    final markedAt = DateTime.now();
    final favorite = Favorite(
      uniqueId: favoriteId,
      userId: userId,
      courseId: courseId,
    );

    final hasConnection = await InternetConnectionChecker.instance.hasConnection;

    try {
      if (hasConnection) {
        //  Firebase
        final favRef = FirebaseDatabase.instance
            .ref("favorites")
            .child(favoriteId);
        await favRef.set(favorite.toMap());

        //  Supabase
        // await SupabaseService().favoriteCourse(favorite);
      }

      //  Local Sqflite always
      await CourseFavoriteDAO().favoriteCourse(
        uniqueId: favoriteId,
        userId: userId,
        courseId: courseId,
      );

      showSnackBarMsg(context, "Marked ${course.courseName} as favorite!");
    } catch (e) {
      print("Mark favorite failed: $e");
      showSnackBarMsg(context, "Failed to mark favorite.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loadEnrolledCourses() async {
    setState(() => isLoading = true);

    try {
      final userId = _user?.userid;
      if (userId == null) {
        showSnackBarMsg(context, "User ID not found.");
        setState(() => isLoading = false);
        return;
      }

      final hasConnection = await InternetConnectionChecker.instance.hasConnection;

      if (hasConnection) {
        // ✅ ONLINE: Load from Firebase
        final enrollRef = FirebaseDatabase.instance.ref("enrollments");
        final snapshot = await enrollRef.orderByChild("user_id").equalTo(userId).once();

        if (snapshot.snapshot.exists) {
          final data = snapshot.snapshot.value as Map<dynamic, dynamic>;

          // Extract courseIds from enrollment entries
          final List<String> courseIds = data.values
              .map((e) => (e as Map)['course_id']?.toString())
              .where((id) => id != null)
              .cast<String>()
              .toList();

          // Fetch course details from Firebase "courses" node
          final coursesRef = FirebaseDatabase.instance.ref("courses");
          final allCoursesSnapshot = await coursesRef.once();

          if (allCoursesSnapshot.snapshot.exists) {
            final allCoursesData =
            allCoursesSnapshot.snapshot.value as Map<dynamic, dynamic>;

            // Filter by courseId list
            final enrolledCourses = allCoursesData.entries
                .where((entry) => courseIds.contains(entry.key))
                .map((entry) => CourseModel.fromJson(
              Map<String, dynamic>.from(entry.value),
            ))
                .toList();

            setState(() {
              filteredCourses = enrolledCourses;
            });
          } else {
            showSnackBarMsg(context, "No courses found in database.");
          }
        } else {
          showSnackBarMsg(context, "You have not enrolled in any courses.");
        }
      } else {
        // ✅ OFFLINE: Load from Sqflite
        final localCourseIds = await CourseEnrollmentDAO().getEnrolledCourseIds(userId);

        if (localCourseIds.isEmpty) {
          showSnackBarMsg(context, "Offline: No enrolled courses found.");
        } else {
          final localCourses = await CourseDAO().getCoursesByIds(localCourseIds);
          setState(() {
            filteredCourses = localCourses;
          });
        }
      }
    } catch (e) {
      print("Error loading enrolled courses: $e");
      showSnackBarMsg(context, "Something went wrong while loading courses.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadFavoriteCourses() async {
    setState(() => isLoading = true);

    try {
      final userId = _user?.userid;
      if (userId == null) {
        showSnackBarMsg(context, "User ID not found.");
        setState(() => isLoading = false);
        return;
      }

      final hasConnection = await InternetConnectionChecker.instance.hasConnection;

      if (hasConnection) {
        // ✅ ONLINE: Load from Firebase favorites
        final favRef = FirebaseDatabase.instance.ref("favorites");
        final snapshot = await favRef.orderByChild("user_id").equalTo(userId).once();

        if (snapshot.snapshot.exists) {
          final data = snapshot.snapshot.value as Map<dynamic, dynamic>;

          // Extract courseIds from favorites entries
          final List<String> courseIds = data.values
              .map((e) => (e as Map)['course_id']?.toString())
              .where((id) => id != null)
              .cast<String>()
              .toList();

          // Fetch course details from Firebase "courses"
          final coursesRef = FirebaseDatabase.instance.ref("courses");
          final allCoursesSnapshot = await coursesRef.once();

          if (allCoursesSnapshot.snapshot.exists) {
            final allCoursesData =
            allCoursesSnapshot.snapshot.value as Map<dynamic, dynamic>;

            // Filter by courseId list
            final favoriteCourses = allCoursesData.entries
                .where((entry) => courseIds.contains(entry.key))
                .map((entry) => CourseModel.fromJson(
              Map<String, dynamic>.from(entry.value),
            ))
                .toList();

            setState(() {
              filteredCourses = favoriteCourses;
            });
          } else {
            showSnackBarMsg(context, "No courses found in database.");
          }
        } else {
          showSnackBarMsg(context, "You have no favorite courses.");
        }
      } else {
        // ✅ OFFLINE: Load from Sqflite
        final localCourseIds = await CourseFavoriteDAO().getFavoriteCourseIds(userId);

        if (localCourseIds.isEmpty) {
          showSnackBarMsg(context, "Offline: No favorite courses found.");
        } else {
          final localCourses = await CourseDAO().getCoursesByIds(localCourseIds);
          setState(() {
            filteredCourses = localCourses;
          });
        }
      }
    } catch (e) {
      print("Error loading favorite courses: $e");
      showSnackBarMsg(context, "Something went wrong while loading courses.");
    } finally {
      setState(() => isLoading = false);
    }
  }


  Future<void> saveCourse(CourseModel courseModel) async {
    if (await InternetConnectionChecker.instance.hasConnection) {
      final DatabaseReference dbRef =
          FirebaseDatabase.instance.ref("courses").child(courseModel.uniqueId!);

      try {
        await dbRef.set(courseModel.toMap());

        // final updatedCount = await SupabaseService().createCourse(courseModel);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course saved successfully!')),
        );

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        setState(() {
          filteredCourses.add(courseModel);
        });

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const AdminLogin(),
        //   ),
        // );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Course: $e')),
        );
        print("$e");
      }
    } else {
      final result = await CourseDAO().insertCourse(courseModel);
      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course saved successfully!')),
        );

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        setState(() {
          filteredCourses.add(courseModel);
        });
        // context.push(Routes.messAdmin);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Course')),
        );
      }
    }

    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        isLoading = false;
      });
      Navigator.pop(context);
    });
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //     content: Row(
    //       children: [
    //         Icon(
    //           Icons.info_outline,
    //           color: Colors.white,
    //         ),
    //         SizedBox(width: 10),
    //         Text(
    //           "Ups, Successfully Saved!",
    //           style: TextStyle(color: Colors.white),
    //         ),
    //       ],
    //     ),
    //     backgroundColor: Colors.redAccent,
    //     shape: StadiumBorder(),
    //     behavior: SnackBarBehavior.floating,
    //   ),
    // );
  }

  Future<void> updateCourse(CourseModel courseModel) async {
    if (await InternetConnectionChecker.instance.hasConnection) {
      final DatabaseReference dbRef =
          FirebaseDatabase.instance.ref("courses").child(courseModel.uniqueId!);

      try {
        await dbRef.update(courseModel.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course updated successfully!')),
        );

        if (mounted) {
          setState(() {
            isLoading = false;
            // update local course list
            final index = filteredCourses
                .indexWhere((c) => c.uniqueId == courseModel.uniqueId);
            if (index != -1) {
              filteredCourses[index] = courseModel;
            }
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update course: $e')),
        );
        print("Error updating course: $e");
      }
    } else {
      final result = await CourseDAO().updateCourse(courseModel);
      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course updated successfully!')),
        );

        if (mounted) {
          setState(() {
            isLoading = false;
            final index = filteredCourses
                .indexWhere((c) => c.uniqueId == courseModel.uniqueId);
            if (index != -1) {
              filteredCourses[index] = courseModel;
            }
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update course offline')),
        );
      }
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      Navigator.pop(context);
    });
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
      keyboardType: TextInputType.numberWithOptions(decimal: true),
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

// Widget _buildComboTextDropdownField({
//   required TextEditingController controller,
//   required String labelText,
//   required IconData icon,
//   required List<String> items,
// }) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 10),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           labelText,
//           style: TextStyle(
//             color: Colors.pinkAccent,
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Expanded(
//               flex: 2,
//               child: TextField(
//                 controller: controller,
//                 decoration: InputDecoration(
//                   prefixIcon: Icon(icon, color: Colors.pinkAccent),
//                   hintText: "Enter or select",
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(15),
//                     borderSide: BorderSide(color: Colors.pinkAccent),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(15),
//                     borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
//                   ),
//                   filled: true,
//                   fillColor: Colors.white,
//                   contentPadding:
//                   const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             Container(
//               height: 50,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(15),
//                 color: Colors.pinkAccent,
//               ),
//               child: DropdownButtonHideUnderline(
//                 child: DropdownButton<String>(
//                   iconEnabledColor: Colors.white,
//                   dropdownColor: Colors.white,
//                   onChanged: (value) {
//                     if (value != null) {
//                       controller.text = value;
//                     }
//                   },
//                   items: items.map((String item) {
//                     return DropdownMenuItem<String>(
//                       value: item,
//                       child: Text(item),
//                     );
//                   }).toList(),
//                   hint: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 10),
//                     child: Icon(Icons.arrow_drop_down, color: Colors.white),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildTextField(TextEditingController controller, String labelText, IconData icon) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 10),
//     child: TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: labelText,
//         labelStyle: TextStyle(color: Colors.pinkAccent),
//         prefixIcon: Icon(icon, color: Colors.pinkAccent),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(15),
//           borderSide: BorderSide(color: Colors.pinkAccent),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(15),
//           borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//       ),
//     ),
//   );
// }

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// import '../../components/components.dart';
// import '../../model/course/video_course.dart';
//
// class MyCoursesPage extends StatelessWidget {
//   const MyCoursesPage({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     // TODO: fetch actual enrolled courses
//     final courses = <VideoCourse>[];
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('My Courses')),
//       body: courses.isEmpty
//           ? const Center(child: Text('No enrolled courses yet.'))
//           : ListView.builder(
//         itemCount: courses.length,
//         itemBuilder: (context, i) {
//           final c = courses[i];
//           return VideoCourseCard(
//             item: c,
//             onPressed: () {
//               // Navigate to course detail
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// void _addCourse(BuildContext context) {
//   final TextEditingController uniqueIdController = TextEditingController();
//   final TextEditingController userNameController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController guardianPhoneController =
//   TextEditingController();
//   final TextEditingController phonePassController = TextEditingController();
//   final TextEditingController dobController = TextEditingController();
//   final TextEditingController educationController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController imgController = TextEditingController();
//   final List<TutorWeekDay> weekDays = [];
//
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     builder: (context) => StatefulBuilder(
//       builder: (context, setModalState) {
//         void _addWeekDay() {
//           final TextEditingController timeController =
//           TextEditingController();
//           final TextEditingController minutesController =
//           TextEditingController();
//           String? selectedDay;
//           bool isAdding = false;
//           String message = '';
//
//           showDialog(
//             context: context,
//             builder: (context) => StatefulBuilder(
//               builder: (context, setDialogState) => AlertDialog(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 title: Text(
//                   'Add Week Day',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.pinkAccent,
//                   ),
//                 ),
//                 content: SingleChildScrollView(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Message TextField at the top
//                       if (message.isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.only(bottom: 10),
//                           child: Text(
//                             message,
//                             style: TextStyle(
//                               color: message.startsWith('Please')
//                                   ? Colors.red
//                                   : Colors.green,
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       // Dropdown for Day
//                       DropdownButtonFormField<String>(
//                         value: selectedDay,
//                         decoration: InputDecoration(
//                           labelText: 'Day',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                         items: [
//                           'Monday',
//                           'Tuesday',
//                           'Wednesday',
//                           'Thursday',
//                           'Friday',
//                           'Saturday',
//                           'Sunday',
//                         ]
//                             .map((day) => DropdownMenuItem(
//                             value: day, child: Text(day)))
//                             .toList(),
//                         onChanged: (value) {
//                           setDialogState(() {
//                             selectedDay = value;
//                             message = ''; // Clear any previous message
//                           });
//                         },
//                       ),
//                       const SizedBox(height: 15),
//                       Row(
//                         children: [
//                           Expanded(
//                             flex: 2,
//                             child: TextField(
//                               controller: timeController,
//                               readOnly: true,
//                               decoration: InputDecoration(
//                                 labelText: 'Time',
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                               onTap: () async {
//                                 TimeOfDay? selectedTime =
//                                 await showTimePicker(
//                                   context: context,
//                                   initialTime: TimeOfDay.now(),
//                                 );
//                                 if (selectedTime != null) {
//                                   setDialogState(() {
//                                     timeController.text =
//                                         selectedTime.format(context);
//                                   });
//                                 }
//                               },
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             flex: 1,
//                             child: TextField(
//                               controller: minutesController,
//                               decoration: InputDecoration(
//                                 labelText: 'Minutes',
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                               keyboardType: TextInputType.number,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     child: Text(
//                       'Close',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   ),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.pinkAccent,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 20, vertical: 10),
//                     ),
//                     onPressed: isAdding
//                         ? null
//                         : () {
//                       if (selectedDay != null) {
//                         setDialogState(() {
//                           isAdding = true;
//                           message = ''; // Clear previous message
//                         });
//                         TutorWeekDay day = TutorWeekDay(
//                           uniqueId: DateTime.now().toIso8601String(),
//                           studentId: uniqueIdController.text,
//                           userId: userNameController.text,
//                           day: selectedDay!,
//                           time: timeController.text,
//                           minutes:
//                           int.tryParse(minutesController.text) ?? 0,
//                         );
//                         setModalState(() {
//                           weekDays.add(
//                               day); // Add the day to the parent list
//                         });
//                         Future.delayed(Duration(seconds: 2), () {
//                           setDialogState(() {
//                             isAdding = false;
//                             message =
//                             'Week Day added successfully!'; // Success message
//                           });
//                         });
//                         Future.delayed(Duration(seconds: 3), () {
//                           // Navigator.pop(context);
//                         });
//                       } else {
//                         setDialogState(() {
//                           message =
//                           'Please select a day'; // Error message
//                         });
//                       }
//                     },
//                     child: isAdding
//                         ? SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(
//                         color: Colors.white,
//                         strokeWidth: 2,
//                       ),
//                     )
//                         : Text(
//                       'Add',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }
//
//         return Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//             left: 10,
//             right: 10,
//             top: 20,
//           ),
//           child: Card(
//             color: Colors.white,
//             margin: const EdgeInsets.fromLTRB(8, 8, 8, 30),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             elevation: 5,
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     height: 50,
//                     decoration: const BoxDecoration(
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(10),
//                         topRight: Radius.circular(10),
//                       ),
//                       color: Colors.pinkAccent,
//                     ),
//                     child: Row(
//                       children: [
//                         const SizedBox(width: 12),
//                         const Icon(Icons.face_retouching_natural_outlined,
//                             color: Colors.white),
//                         const SizedBox(width: 12),
//                         const Text(
//                           "Add Course",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         Spacer(),
//                         IconButton(
//                           onPressed: () {
//                             Navigator.of(context)
//                                 .pop(); // Close the dialog or screen
//                           },
//                           icon: Icon(Icons.close, color: Colors.white),
//                         ),
//                         const SizedBox(
//                             width:
//                             12), // Optional, adds a little padding from the edge
//                       ],
//                     ),
//                   ),
//
//                   _buildTextField(userNameController, 'Name', Icons.person),
//                   _buildTextField(phoneController, 'Phone', Icons.phone),
//                   _buildTextField(guardianPhoneController, 'Guardian Phone',
//                       Icons.phone_in_talk),
//                   _buildTextField(phonePassController, 'Email', Icons.email),
//                   _buildTextField(
//                       educationController, 'Education', Icons.school),
//                   _buildTextField(addressController, 'Address', Icons.home),
//                   _buildTextField(imgController, 'Image URL', Icons.image),
//                   SizedBox(height: 10),
//                   Align(
//                     alignment: Alignment
//                         .centerRight, // Aligns the button to the right
//                     child: ElevatedButton(
//                       onPressed: _addWeekDay,
//                       style: ElevatedButton.styleFrom(
//                         elevation: 5, // Adds shadow
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 20, vertical: 15),
//                         shape: RoundedRectangleBorder(
//                           borderRadius:
//                           BorderRadius.circular(30), // Rounded corners
//                         ),
//                         backgroundColor: Colors.pinkAccent, // Button color
//                       ),
//                       child: Row(
//                         mainAxisSize:
//                         MainAxisSize.min, // Keeps the button compact
//                         children: [
//                           const Icon(Icons.add,
//                               color: Colors.white), // Icon on the left
//                           const SizedBox(width: 8),
//                           const Text(
//                             'Add Day',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   // ListView.builder(
//                   //   shrinkWrap: true,
//                   //   itemCount: weekDays.length,
//                   //   itemBuilder: (context, index) {
//                   //     return Padding(
//                   //       padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
//                   //       child: Card(
//                   //         shape: RoundedRectangleBorder(
//                   //           borderRadius: BorderRadius.circular(12),
//                   //         ),
//                   //         elevation: 4,
//                   //         child: ListTile(
//                   //           contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 5),
//                   //           title: Text(
//                   //             'Day: ${weekDays[index].day}',
//                   //             style: TextStyle(
//                   //               fontWeight: FontWeight.bold,
//                   //               fontSize: 16,
//                   //             ),
//                   //           ),
//                   //           subtitle: Text(
//                   //             'Time: ${weekDays[index].time}, Minutes: ${weekDays[index].minutes}',
//                   //             style: TextStyle(
//                   //               color: Colors.grey[600],
//                   //               fontSize: 14,
//                   //             ),
//                   //           ),
//                   //           trailing: IconButton(
//                   //             onPressed: () {
//                   //               setModalState(() {
//                   //                 weekDays.removeAt(index);
//                   //               });
//                   //
//                   //               ScaffoldMessenger.of(context).showSnackBar(
//                   //                 SnackBar(
//                   //                   content: Text('Item deleted successfully'),
//                   //                   backgroundColor: Colors.redAccent,
//                   //                 ),
//                   //               );
//                   //             },
//                   //             icon: Icon(
//                   //               Icons.delete,
//                   //               color: Colors.redAccent,
//                   //             ),
//                   //           ),
//                   //         ),
//                   //       ),
//                   //     );
//                   //   },
//                   // ),
//
//                   Wrap(
//                     spacing: 8.0, // Horizontal space between items
//                     runSpacing: 6.0, // Vertical space between lines
//                     children: weekDays.map((weekDay) {
//                       return Chip(
//                         label: Row(
//                           children: [
//                             Text(
//                               'Day: ${weekDay.day}',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             SizedBox(width: 8),
//                             Text(
//                               'Time: ${weekDay.time}, Minutes: ${weekDay.minutes}',
//                               style: TextStyle(
//                                 color: Colors.grey[600],
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ],
//                         ),
//                         deleteIcon: Icon(
//                           Icons.delete,
//                           color: Colors.redAccent,
//                         ),
//                         onDeleted: () {
//                           setModalState(() {
//                             weekDays.removeAt(weekDays.indexOf(weekDay));
//                           });
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text('Item deleted successfully'),
//                               backgroundColor: Colors.redAccent,
//                             ),
//                           );
//                         },
//                       );
//                     }).toList(),
//                   ),
//
//                   // GridView.builder(
//                   //   shrinkWrap: true,
//                   //   physics: NeverScrollableScrollPhysics(), // Prevents nested scroll behavior
//                   //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   //     crossAxisCount: 2, // Number of columns in the grid
//                   //     crossAxisSpacing: 8, // Space between columns
//                   //     mainAxisSpacing: 8, // Space between rows
//                   //   ),
//                   //   itemCount: weekDays.length,
//                   //   itemBuilder: (context, index) {
//                   //     return Padding(
//                   //       padding: const EdgeInsets.all(8),
//                   //       child: Card(
//                   //         shape: RoundedRectangleBorder(
//                   //           borderRadius: BorderRadius.circular(12),
//                   //         ),
//                   //         elevation: 4,
//                   //         child: Column(
//                   //           mainAxisAlignment: MainAxisAlignment.center,
//                   //           children: [
//                   //             Text(
//                   //               'Day: ${weekDays[index].day}',
//                   //               style: TextStyle(
//                   //                 fontWeight: FontWeight.bold,
//                   //                 fontSize: 16,
//                   //               ),
//                   //             ),
//                   //             SizedBox(height: 8),
//                   //             Text(
//                   //               'Time: ${weekDays[index].time}, Minutes: ${weekDays[index].minutes}',
//                   //               style: TextStyle(
//                   //                 color: Colors.grey[600],
//                   //                 fontSize: 14,
//                   //               ),
//                   //             ),
//                   //             IconButton(
//                   //               onPressed: () {
//                   //                 setModalState(() {
//                   //                   weekDays.removeAt(index);
//                   //                 });
//                   //                 ScaffoldMessenger.of(context).showSnackBar(
//                   //                   SnackBar(
//                   //                     content: Text('Item deleted successfully'),
//                   //                     backgroundColor: Colors.redAccent,
//                   //                   ),
//                   //                 );
//                   //               },
//                   //               icon: Icon(
//                   //                 Icons.delete,
//                   //                 color: Colors.redAccent,
//                   //               ),
//                   //             ),
//                   //           ],
//                   //         ),
//                   //       ),
//                   //     );
//                   //   },
//                   // ),
//
//                   SizedBox(
//                       height: 10), // Adds some space between form and button
//                   // Container(
//                   //   alignment: Alignment.center,
//                   //   margin: const EdgeInsets.all(10),
//                   //   child: Material(
//                   //     elevation: 3,
//                   //     borderRadius: BorderRadius.circular(20),
//                   //     child: Container(
//                   //       width: MediaQuery.of(context).size.width,
//                   //       height: 50,
//                   //       decoration: BoxDecoration(
//                   //         borderRadius: BorderRadius.circular(20),
//                   //         color: Colors.white,
//                   //       ),
//                   //       child: Material(
//                   //         borderRadius: BorderRadius.circular(20),
//                   //         color: Colors.pinkAccent,
//                   //         child: InkWell(
//                   //           splashColor: Colors.pink,
//                   //           borderRadius: BorderRadius.circular(20),
//                   //           onTap: () {
//                   //             setState(() {
//                   //               students.add(TutorStudent(
//                   //                 uniqueId: uniqueIdController.text,
//                   //                 userId: userNameController.text,
//                   //                 phone: phoneController.text,
//                   //                 gaurdianPhone: guardianPhoneController.text,
//                   //                 phonePass: phonePassController.text,
//                   //                 dob: dobController.text,
//                   //                 education: educationController.text,
//                   //                 address: addressController.text,
//                   //                 activeStatus: 1,
//                   //                 admittedDate: DateTime.now(),
//                   //                 img: imgController.text,
//                   //                 days: weekDays,
//                   //               ));
//                   //             });
//                   //             Navigator.pop(context);
//                   //             ScaffoldMessenger.of(context).showSnackBar(
//                   //               const SnackBar(
//                   //                 content: Row(
//                   //                   children: [
//                   //                     Icon(
//                   //                       Icons.info_outline,
//                   //                       color: Colors.white,
//                   //                     ),
//                   //                     SizedBox(width: 10),
//                   //                     Text(
//                   //                       "Ups, foto dan inputan tidak boleh kosong!",
//                   //                       style: TextStyle(color: Colors.white),
//                   //                     ),
//                   //                   ],
//                   //                 ),
//                   //                 backgroundColor: Colors.redAccent,
//                   //                 shape: StadiumBorder(),
//                   //                 behavior: SnackBarBehavior.floating,
//                   //               ),
//                   //             );
//                   //           },
//                   //           child: const Center(
//                   //             child: Text(
//                   //               " Save Student",
//                   //               style: TextStyle(
//                   //                 color: Colors.white,
//                   //                 fontWeight: FontWeight.bold,
//                   //               ),
//                   //             ),
//                   //           ),
//                   //         ),
//                   //       ),
//                   //     ),
//                   //   ),
//                   // ),
//                   Container(
//                     alignment: Alignment.center,
//                     margin: const EdgeInsets.all(10),
//                     child: Material(
//                       elevation: 3,
//                       borderRadius: BorderRadius.circular(20),
//                       child: Container(
//                         width: MediaQuery.of(context).size.width,
//                         height: 50,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(20),
//                           color: Colors.white,
//                         ),
//                         child: Material(
//                           borderRadius: BorderRadius.circular(20),
//                           color: Colors.pinkAccent,
//                           child: InkWell(
//                             splashColor: Colors.pink,
//                             borderRadius: BorderRadius.circular(20),
//                             onTap: isLoading
//                                 ? null
//                                 : () {
//                               setModalState(() {});
//                               setState(() {
//                                 isLoading = true;
//
//                                 TutorStudent student = TutorStudent(
//                                   name: userNameController.text,
//                                   phone: phoneController.text,
//                                   gaurdianPhone:
//                                   guardianPhoneController.text,
//                                   phonePass: phonePassController.text,
//                                   education: educationController.text,
//                                   address: addressController.text,
//                                   activeStatus: 1,
//                                   admittedDate: DateTime.now(),
//                                   img: imgController.text,
//                                   days: weekDays,
//                                 );
//                                 // saveStudent(student);
//                               });
//                             },
//                             child: Center(
//                               child: isLoading
//                                   ? SizedBox(
//                                 height: 20,
//                                 width: 20,
//                                 child: CircularProgressIndicator(
//                                   color: Colors.white,
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                                   : Text(
//                                 " Save Course",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     ),
//   );
// }

// void _addCourse(BuildContext context) {
//   final TextEditingController courseNameController = TextEditingController();
//   final TextEditingController bannerUrlController = TextEditingController();
//   final TextEditingController aboutController = TextEditingController();
//   final TextEditingController categoryController = TextEditingController();
//   final TextEditingController feeController = TextEditingController();
//   final TextEditingController discountController = TextEditingController();
//
//   String? selectedLevel;
//   String? selectedStatus;
//
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     builder: (context) => StatefulBuilder(
//       builder: (context, setModalState) {
//         return Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//             left: 16,
//             right: 16,
//             top: 20,
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Title bar
//                 Container(
//                   height: 50,
//                   decoration: BoxDecoration(
//                     color: Colors.pinkAccent,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Center(
//                     child: Text(
//                       "Add New Course",
//                       style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//
//                 _buildTextField(
//                     courseNameController, 'Course Name', Icons.text_fields),
//                 const SizedBox(height: 12),
//
//                 _buildTextField(bannerUrlController,
//                     'Course Banner Image URL', Icons.image),
//                 const SizedBox(height: 12),
//
//                 _buildComboTextDropdownField(
//                   controller: categoryController,
//                   labelText: 'Category (Enter or Pick)',
//                   icon: Icons.category,
//                   items: categoryNames, // your List<String> of category names
//                 ),
//
//                 // _buildTextField(categoryController, 'Category (Enter or Pick)', Icons.category),
//                 const SizedBox(height: 12),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                   child: TextField(
//                     controller: aboutController,
//                     minLines: 5,
//                     maxLines: null, // Unlimited lines
//                     keyboardType: TextInputType.multiline,
//                     decoration: InputDecoration(
//                       labelText: 'About Course',
//                       labelStyle: TextStyle(color: Colors.pinkAccent),
//                       alignLabelWithHint: true,
//                       prefixIcon:
//                           Icon(Icons.description, color: Colors.pinkAccent),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(15),
//                         borderSide: BorderSide(color: Colors.pinkAccent),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(15),
//                         borderSide:
//                             BorderSide(color: Colors.pinkAccent, width: 2),
//                       ),
//                       filled: true,
//                       fillColor: Colors.white,
//                       contentPadding:
//                           EdgeInsets.symmetric(vertical: 15, horizontal: 15),
//                     ),
//                   ),
//                 ),
//
//                 // About Course
//                 // TextField(
//                 //   controller: aboutController,
//                 //   maxLines: 4,
//                 //   decoration: InputDecoration(
//                 //     labelText: 'About Course',
//                 //     border: OutlineInputBorder(
//                 //       borderRadius: BorderRadius.circular(10),
//                 //     ),
//                 //     alignLabelWithHint: true,
//                 //   ),
//                 // ),
//                 const SizedBox(height: 12),
//
//                 // Level Dropdown
//                 DropdownButtonFormField<String>(
//                   value: selectedLevel,
//                   decoration: InputDecoration(
//                     labelText: 'Level',
//                     border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10)),
//                   ),
//                   items: ['Beginner', 'Intermediate', 'Professional', 'Other']
//                       .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                       .toList(),
//                   onChanged: (val) =>
//                       setModalState(() => selectedLevel = val),
//                 ),
//                 const SizedBox(height: 12),
//
//                 _buildNumberField(
//                     feeController, 'Fee (৳)', Icons.attach_money),
//                 const SizedBox(height: 12),
//
//                 _buildNumberField(
//                     discountController, 'Discount (%)', Icons.percent),
//                 const SizedBox(height: 12),
//
//                 // Status Dropdown
//                 DropdownButtonFormField<String>(
//                   value: selectedStatus,
//                   decoration: InputDecoration(
//                     labelText: 'Status',
//                     border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10)),
//                   ),
//                   items: ['Active', 'Inactive', 'Draft']
//                       .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                       .toList(),
//                   onChanged: (val) =>
//                       setModalState(() => selectedStatus = val),
//                 ),
//                 const SizedBox(height: 20),
//
//                 // Save Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: isLoading
//                         ? null
//                         : () {
//                             setModalState(() {});
//                             setState(() {
//                               isLoading = true;
//                               // isLoading = false;
//                               var uuid = Uuid();
//                               String uniqueId = Unique().generateUniqueID();
//                               int ranId =
//                                   Random().nextInt(1000000000) + DateTime.now().millisecondsSinceEpoch;
//                               String referr = String.fromCharCode(65 + Random().nextInt(26));
//                               // String referrr = utf8.decode([Random().nextInt(256)]).toUpperCase();
//                               String numberr = '$ranId$referr';
//
//
//                               CourseModel courseModel = new CourseModel(
//                                   courseName: courseNameController.text.toString(),
//                                   courseImage: bannerUrlController.text.toString(),
//                                   category: categoryController.text.toString(),
//                                   description: aboutController.text.toString(),
//                                   fee: double.tryParse(feeController.text),
//                                   discount: double.tryParse(discountController.text),
//                                   uniqueId: uniqueId,
//                                   userId: _user?.userid,
//                                   totalVideo: 0,
//                                   trackingNumber: numberr,
//                                   totalTime: "1.30",
//                                   totalRating: double.tryParse("4.7"),
//                                   level: selectedLevel.toString(),
//                                   countStudents: 0,
//                                   createdAt: DateTime.now(),
//                                   status: selectedStatus.toString());
//
//                             });
//                             Navigator.pop(context);
//                           },
//                     icon: Icon(Icons.save),
//                     label: isLoading
//                         ? SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2,
//                             ),
//                           )
//                         : Text('Save Course'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.pinkAccent,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10)),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//               ],
//             ),
//           ),
//         );
//       },
//     ),
//   );
// }

// void _addCourse(BuildContext context) {
//   final TextEditingController courseNameController = TextEditingController();
//   final TextEditingController bannerUrlController = TextEditingController();
//   final TextEditingController aboutController = TextEditingController();
//   final TextEditingController categoryController = TextEditingController();
//   final TextEditingController feeController = TextEditingController();
//   final TextEditingController discountController = TextEditingController();
//
//   String? selectedLevel;
//   String? selectedStatus;
//
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     builder: (context) => StatefulBuilder(
//       builder: (context, setModalState) {
//         return Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//             left: 16,
//             right: 16,
//             top: 20,
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Title bar
//                 Container(
//                   height: 50,
//                   decoration: BoxDecoration(
//                     color: Colors.pinkAccent,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Center(
//                     child: Text(
//                       "Add New Course",
//                       style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//
//                 _buildTextField(
//                     courseNameController, 'Course Name', Icons.text_fields),
//                 const SizedBox(height: 12),
//
//                 _buildTextField(bannerUrlController, 'Course Banner Image URL',
//                     Icons.image),
//                 const SizedBox(height: 12),
//
//                 _buildComboTextDropdownField(
//                   controller: categoryController,
//                   labelText: 'Category (Enter or Pick)',
//                   icon: Icons.category,
//                   items: categoryNames,
//                 ),
//                 const SizedBox(height: 12),
//
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 10),
//                   child: TextField(
//                     controller: aboutController,
//                     minLines: 5,
//                     maxLines: null,
//                     keyboardType: TextInputType.multiline,
//                     decoration: InputDecoration(
//                       labelText: 'About Course',
//                       labelStyle: TextStyle(color: Colors.pinkAccent),
//                       alignLabelWithHint: true,
//                       prefixIcon:
//                       Icon(Icons.description, color: Colors.pinkAccent),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(15),
//                         borderSide: BorderSide(color: Colors.pinkAccent),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(15),
//                         borderSide:
//                         BorderSide(color: Colors.pinkAccent, width: 2),
//                       ),
//                       filled: true,
//                       fillColor: Colors.white,
//                       contentPadding:
//                       EdgeInsets.symmetric(vertical: 15, horizontal: 15),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//
//                 DropdownButtonFormField<String>(
//                   value: selectedLevel,
//                   decoration: InputDecoration(
//                     labelText: 'Level',
//                     border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10)),
//                   ),
//                   items: [
//                     'Beginner',
//                     'Intermediate',
//                     'Professional',
//                     'Other'
//                   ]
//                       .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                       .toList(),
//                   onChanged: (val) => setModalState(() => selectedLevel = val),
//                 ),
//                 const SizedBox(height: 12),
//
//                 _buildNumberField(feeController, 'Fee (৳)', Icons.attach_money),
//                 const SizedBox(height: 12),
//
//                 _buildNumberField(
//                     discountController, 'Discount (%)', Icons.percent),
//                 const SizedBox(height: 12),
//
//                 DropdownButtonFormField<String>(
//                   value: selectedStatus,
//                   decoration: InputDecoration(
//                     labelText: 'Status',
//                     border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10)),
//                   ),
//                   items: ['Active', 'Inactive', 'Draft']
//                       .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                       .toList(),
//                   onChanged: (val) =>
//                       setModalState(() => selectedStatus = val),
//                 ),
//                 const SizedBox(height: 20),
//
//                 // Save button placed naturally at the end
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: isLoading
//                         ? null
//                         : () {
//                       setState(() {
//                         isLoading = true;
//
//                         var uuid = Uuid();
//                         String uniqueId = Unique().generateUniqueID();
//                         int ranId = Random().nextInt(1000000000) +
//                             DateTime.now().millisecondsSinceEpoch;
//                         String referr = String.fromCharCode(
//                             65 + Random().nextInt(26));
//                         String numberr = '$ranId$referr';
//
//                         CourseModel courseModel = CourseModel(
//                           courseName: courseNameController.text.trim(),
//                           courseImage: bannerUrlController.text.trim(),
//                           category: categoryController.text.trim(),
//                           description: aboutController.text.trim(),
//                           fee: double.tryParse(feeController.text),
//                           discount:
//                           double.tryParse(discountController.text),
//                           uniqueId: uniqueId,
//                           userId: _user?.userid,
//                           totalVideo: 0,
//                           trackingNumber: numberr,
//                           totalTime: "1.30",
//                           totalRating: 4.7,
//                           level: selectedLevel ?? 'Beginner',
//                           countStudents: 0,
//                           createdAt: DateTime.now(),
//                           status: selectedStatus ?? 'Draft',
//                         );
//                         // Add your save logic here
//                       });
//
//                       Navigator.pop(context);
//                     },
//                     icon: isLoading
//                         ? SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(
//                         color: Colors.white,
//                         strokeWidth: 2,
//                       ),
//                     )
//                         : Icon(Icons.save),
//                     label: Text(isLoading ? 'Saving...' : 'Save Course'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.pinkAccent,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10)),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//               ],
//             ),
//           ),
//         );
//       },
//     ),
//   );
// }
