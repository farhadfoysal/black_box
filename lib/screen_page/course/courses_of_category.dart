import 'dart:convert';
import 'dart:io';

import 'package:black_box/routes/routes.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../db/course/course_dao.dart';
import '../../db/course/course_enrollment_dao.dart';
import '../../db/course/course_favorite_dao.dart';
import '../../model/course/enrollment.dart';
import '../../model/course/favorite.dart';
import '../../model/course/teacher.dart';
import '../../model/course/video_course.dart';
import '../../components/components.dart';
import '../../components/course/course_card.dart';
import '../../model/course/course_model.dart';
import '../../model/school/school.dart';
import '../../model/user/user.dart';
import '../../preference/logout.dart';
import '../../routes/app_router.dart';
import '../../utility/unique.dart';

class CoursesOfCategoryPage extends StatefulWidget {
  const CoursesOfCategoryPage({Key? key}) : super(key: key);

  @override
  State<CoursesOfCategoryPage> createState() => _CoursesOfCategoryPageState();
}

class _CoursesOfCategoryPageState extends State<CoursesOfCategoryPage> {
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

  late Category category;

  final TextEditingController controller = TextEditingController();

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

      Query query = teachersRef.orderByChild('category').equalTo(category.name);

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
          await CourseDAO().getCoursesByCategory(category.name);

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

  void _searchCourses(String query) {
    final results = allCourses.where((course) {
      final courseName = course.courseName?.toLowerCase() ?? '';
      return courseName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredCourses = results;
    });
  }


  @override
  Widget build(BuildContext context) {
    category = GoRouterState.of(context).extra as Category;

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
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
                                'No courses found in ${category.name}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredCourses.length,
                              itemBuilder: (context, index) {
                                final course = filteredCourses[index];
                                return Dismissible(
                                  key: ValueKey(course
                                      .uniqueId), // Use a unique identifier
                                  background: Container(
                                    color: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    alignment: Alignment.centerLeft,
                                    child: const Icon(Icons.favorite,
                                        color: Colors.white),
                                  ),
                                  secondaryBackground: Container(
                                    color: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    alignment: Alignment.centerRight,
                                    child: const Icon(Icons.check,
                                        color: Colors.white),
                                  ),
                                  confirmDismiss: (direction) async {
                                    if (direction ==
                                        DismissDirection.startToEnd) {
                                      // Swipe right to Edit
                                      markFavorite(course);
                                      return false; // Don't dismiss the tile
                                    } else if (direction ==
                                        DismissDirection.endToStart) {
                                      // Swipe left to Delete
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title:
                                              const Text('Confirm To Enroll'),
                                          content: Text(
                                              'Are you sure you want to enroll "${course.courseName}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Enroll',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        enrollCourse(course);
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
                                      trackingNumber:
                                          course.trackingNumber ?? '',
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
                            )

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
    );
  }

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


}

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
//
// import '../../components/components.dart';
// import '../../model/course/course_model.dart';
// import '../../model/course/video_course.dart';
//
// class CoursesOfCategoryPage extends StatelessWidget {
//   const CoursesOfCategoryPage({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final category = GoRouterState.of(context).extra as Category;
//
//     bool isEmpty = false;
//     TextEditingController controller = TextEditingController();
//
//     // final courses = <VideoCourse>[];
//
//     final List<CourseModel> allCourses = [
//       CourseModel(courseName: 'Flutter Beginner', totalVideo: 10),
//       CourseModel(courseName: 'Dart Fundamentals', totalVideo: 8),
//       CourseModel(courseName: 'Mobile App Security', totalVideo: 7),
//       CourseModel(courseName: 'Backend Development', totalVideo: 12),
//     ];
//
//     List<CourseModel> filteredCourses = [];
//
//
//
//     return Scaffold(
//       appBar: AppBar(title: Text(category.name)),
//       // body: courses.isEmpty
//       //     ? Center(child: Text('No courses found in ${category.name}'))
//       //     : ListView.builder(
//       //   itemCount: courses.length,
//       //   itemBuilder: (context, i) {
//       //     final c = courses[i];
//       //     return VideoCourseCard(
//       //       item: c,
//       //       onPressed: () {
//       //         // TODO: navigate to course preview or detail
//       //       },
//       //     );
//       //   },
//       // ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // const SearchBar(),
//             TextField(
//               controller: controller,
//               decoration: const InputDecoration(
//                 prefixIcon: Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.all(
//                     Radius.circular(20),
//                   ),
//                 ),
//                 hintText: 'Search course...',
//               ),
//               onChanged: (val) {
//
//               },
//             ),
//             const SizedBox(height: 8),
//
//             Expanded(
//               child: ListView.builder(
//                 physics: const BouncingScrollPhysics(),
//                 itemCount: course.allCourse?.length ?? 0,
//                 itemBuilder: (context, index) {
//                   return GestureDetector(
//                     onTap: () async {
//                       await Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => DetailCourseScreen(
//                             courseId: course.allCourse?[index],
//                           ),
//                         ),
//                       );
//                     },
//                     child: CourseCard(
//                       courseImage: course.allCourse?[index].courseImage ?? '',
//                       courseName: course.allCourse?[index].courseName ?? '',
//                       rating: course.allCourse?[index].totalRating ?? 0,
//                       totalTime: course.allCourse?[index].totalTime ?? '',
//                       totalVideo:
//                       course.allCourse?[index].totalVideo.toString() ?? '',
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
