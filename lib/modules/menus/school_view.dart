import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:black_box/components/common/photo_avatar.dart';
import 'package:black_box/cores/cores.dart';
import 'package:black_box/model/user/user.dart';
import 'package:black_box/routes/routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as b;
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/components.dart';
import '../../db/course/course_dao.dart';
import '../../db/course/course_enrollment_dao.dart';
import '../../db/course/course_favorite_dao.dart';
import '../../dummies/categories_d.dart';
import '../../dummies/video_courses_d.dart';
import '../../model/course/course_model.dart';
import '../../model/course/enrollment.dart';
import '../../model/course/teacher.dart';
import '../../model/course/video_course.dart';
import '../../model/school/school.dart';
import '../../preference/logout.dart';
import '../../routes/app_router.dart';
import '../../screen_page/course/scan_qr_page.dart';
import '../../services/course/supabse_service.dart';
import '../../utility/unique.dart';

class SchoolView extends StatefulWidget {
  const SchoolView({super.key});

  @override
  State<StatefulWidget> createState() {
    return SchoolViewState();
  }
}

class SchoolViewState extends State<SchoolView> {
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

  late User user;
  final categories = <Category>[];
  final newCourses = <VideoCourse>[];
  final popularCourses = <VideoCourse>[];

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
    CourseModel(
      courseName: 'Dart Fundamentals',
      totalVideo: 8,
      totalRating: 4.2,
      totalTime: '1h 50m',
      courseImage:
          'https://fastly.picsum.photos/id/50/200/300.jpg?hmac=wlHRGoenBSt-gzxGvJp3cBEIUD71NKbWEXmiJC2mQYE',
      level: 'Beginner',
      countStudents: 95,
      createdAt: DateTime.now(),
      status: 'active',
    ),
    CourseModel(
      courseName: 'Mobile App Security',
      totalVideo: 7,
      totalRating: 4.8,
      totalTime: '3h 20m',
      courseImage:
          'https://fastly.picsum.photos/id/443/200/300.jpg?grayscale&hmac=3KGsrU5Oo_hghp3-Xuzs6myA2cu1cKEvgsz05yWhKWA',
      level: 'Intermediate',
      countStudents: 80,
      createdAt: DateTime.now(),
      status: 'inactive',
    ),
    CourseModel(
      courseName: 'Backend Development',
      totalVideo: 12,
      totalRating: 4.7,
      totalTime: '2h 45m',
      courseImage:
          'https://fastly.picsum.photos/id/866/200/300.jpg?hmac=rcadCENKh4rD6MAp6V_ma-AyWv641M4iiOpe1RyFHeI',
      level: 'Intermediate',
      countStudents: 150,
      createdAt: DateTime.now(),
      status: 'active',
    ),
  ];

  List<CourseModel> filteredCourses = [];
  List<CourseModel> favoriteCourses = [];

  @override
  void initState() {
    filteredCourses = List.from(allCourses);
    favoriteCourses = List.from(allCourses);
    super.initState();
    _loadUserName();
    setState(() {
      isLoading = true;
      // isLoading = false;
    });
    loadData();
    _initializeData();
  }

  Future<void> loadData() async {
    final now = DateTime.now();
    final categories = categoriesJSON.map((e) => Category.fromJson(e));

    this.categories
      ..clear()
      ..addAll(categories);
  }

  Future<void> _initializeData() async {
    // First load user data
    await _loadUserData();
    loadEnrolledCourses();
    loadFavoriteCourses();
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
        _userName = userData['uname'] ?? 'Fihan Farique Wafi';
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

  Future<void> signOut() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully signed out')),
    );
    await AppRouter.logoutUser(context);
  }



  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      child: AppPullRefresh(
        onRefresh: _initializeData,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 25, top: 6),
          children: [
            _ProfileHeader(user: _user!),
            _CategoriesListView(categories: categories),
            _NewCoursesListView(newCourses: filteredCourses),
            _PopularCoursesListView(popularCourses: favoriteCourses),
          ],
        ),
      ),
    );
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

      final hasConnection =
          await InternetConnectionChecker.instance.hasConnection;

      if (hasConnection) {
        //  ONLINE: Load from Firebase
        final enrollRef = FirebaseDatabase.instance.ref("enrollments");
        final snapshot =
            await enrollRef.orderByChild("user_id").equalTo(userId).once();

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
        //  OFFLINE: Load from Sqflite
        final localCourseIds =
            await CourseEnrollmentDAO().getEnrolledCourseIds(userId);

        if (localCourseIds.isEmpty) {
          showSnackBarMsg(context, "Offline: No enrolled courses found.");
        } else {
          final localCourses =
              await CourseDAO().getCoursesByIds(localCourseIds);
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

      final hasConnection =
          await InternetConnectionChecker.instance.hasConnection;

      if (hasConnection) {
        //  ONLINE: Load from Firebase favorites
        final favRef = FirebaseDatabase.instance.ref("favorites");
        final snapshot =
            await favRef.orderByChild("user_id").equalTo(userId).once();

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
            final fCourses = allCoursesData.entries
                .where((entry) => courseIds.contains(entry.key))
                .map((entry) => CourseModel.fromJson(
                      Map<String, dynamic>.from(entry.value),
                    ))
                .toList();

            setState(() {
              favoriteCourses = fCourses;
            });
          } else {
            showSnackBarMsg(context, "No courses found in database.");
          }
        } else {
          showSnackBarMsg(context, "You have no favorite courses.");
        }
      } else {
        //  OFFLINE: Load from Sqflite
        final localCourseIds =
            await CourseFavoriteDAO().getFavoriteCourseIds(userId);

        if (localCourseIds.isEmpty) {
          showSnackBarMsg(context, "Offline: No favorite courses found.");
        } else {
          final localCourses =
              await CourseDAO().getCoursesByIds(localCourseIds);
          setState(() {
            favoriteCourses = localCourses;
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
}

class _ProfileHeader extends StatelessWidget {
  final User user;

  const _ProfileHeader({Key? key, required this.user}) : super(key: key);

  void showSnackBarMsg(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showEnrollCourseDialog(BuildContext context, Function(String uniqueId) onEnroll) {
    final TextEditingController _idController = TextEditingController();
    bool isProcessing = false; // Move this OUTSIDE of builder

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school_rounded, size: 50, color: Colors.deepPurple),
                      const SizedBox(height: 15),
                      const Text(
                        "Enroll in a Course",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Enter the course Tracking Number / Unique ID below or scan a QR code to enroll.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _idController,
                        enabled: !isProcessing,
                        decoration: InputDecoration(
                          labelText: "Tracking Number / Unique ID",
                          prefixIcon: const Icon(Icons.numbers_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isProcessing
                                  ? null
                                  : () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ScanQrPage()),
                                );
                              },
                              icon: const Icon(Icons.qr_code_scanner_rounded),
                              label: const Text("Scan QR"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.deepPurple.shade50,
                                foregroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () {
                                if (_idController.text.isNotEmpty) {
                                  setState(() {
                                    isProcessing = true;
                                  });

                                  Future.delayed(const Duration(seconds: 10), () {
                                    Navigator.pop(context);
                                    onEnroll(_idController.text.trim());
                                    showSnackBarMsg(context, "Please wait few seconds to process the enrollment");
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Please enter a Tracking Number.")),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isProcessing
                                  ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check_circle_rounded),
                                  SizedBox(width: 8),
                                  Text("Enroll"),
                                ],
                              ),
                            ),
                          ),
                        ],
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


  Future<void> _enrollCourseById(BuildContext context, String uniqueId) async {
    try {
      CourseModel? course;

      if (await InternetConnectionChecker.instance.hasConnection) {

        final dbRef = FirebaseDatabase.instance.ref("courses");

        final directSnapshot = await dbRef.child(uniqueId).get();

        if (directSnapshot.exists) {
          final courseMap = Map<String, dynamic>.from(directSnapshot.value as Map);
          course = CourseModel.fromJson(courseMap);
        } else {

          final query = dbRef.orderByChild('tracking_number').equalTo(uniqueId);
          final querySnapshot = await query.get();

          if (querySnapshot.exists) {
            final firstMatch = querySnapshot.children.first;
            final courseMap = Map<String, dynamic>.from(firstMatch.value as Map);
            course = CourseModel.fromJson(courseMap);
          }
        }


        // final dbRef = FirebaseDatabase.instance.ref("courses").child(uniqueId);
        // final snapshot = await dbRef.get();
        //
        // if (snapshot.exists) {
        //   final courseMap = Map<String, dynamic>.from(snapshot.value as Map);
        //   course = CourseModel.fromJson(courseMap);
        // }
      }

      if (course == null) {
        course = await CourseDAO().getCourseByUniqueId(uniqueId);
      }

      if (course != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnrollCoursePage(course: course!, user: user),
          ),
        );
      }else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Course not found for this Tracking ID.")),
        );
      }
    } catch (e) {
      print("Enrollment by ID failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to enroll by ID.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0.0),
      child: Row(
        children: [
          XAvatarCircle(
            photoURL:
            "https://gratisography.com/wp-content/uploads/2024/11/gratisography-augmented-reality-800x525.jpg",
            membership: "U",
            progress: 60,
            color: Theme.of(context).primaryColor,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.7),
                    child: Text(
                      "Courses",
                      style: p21.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      "${user.uname}",
                      style: p14.bold.grey,
                    ),
                  )
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              showEnrollCourseDialog(context, (uniqueId) {
                _enrollCourseById(context, uniqueId);
              });
            },
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Icon(
                Icons.add_circle_outline_rounded,
                size: 40,
              ),
            ),
          ),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: b.Badge(
                badgeStyle: b.BadgeStyle(
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                  badgeColor: Colors.redAccent,
                  borderRadius: BorderRadius.circular(13),
                  elevation: 0,
                ),
                badgeContent: const Text(
                  "7",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class EnrollCoursePage extends StatelessWidget {
  final CourseModel course;
  final User user;

  const EnrollCoursePage({super.key, required this.course, required this.user});

  void showSnackBarMsg(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }


  void enrollCourseAction(BuildContext context, CourseModel course) async {
    final uniqueEnrollId = Unique().generateUniqueID();
    final userId = user?.userid;

    if (userId == null) {
      showSnackBarMsg(context, "Please login first.");
      return;
    }

    final enrolledAt = DateTime.now();

    // Firebase
    final enrollRef = FirebaseDatabase.instance.ref("enrollments").child(uniqueEnrollId);

    await enrollRef.set({
      'unique_id': uniqueEnrollId,
      'user_id': userId,
      'course_id': course.uniqueId,
      'enrolled_at': enrolledAt.toIso8601String(),
      'status': 'active',
    });

    // Supabase
    // final enrollment = Enrollment(
    //   uniqueId: uniqueEnrollId,
    //   userId: userId,
    //   courseId: course.uniqueId!,
    //   enrolledAt: enrolledAt,
    //   status: 'active',
    // );
    // await SupabaseService().enrollCourse(enrollment);

    // Sqflite
    await CourseEnrollmentDAO().enrollCourse(
      uniqueId: uniqueEnrollId,
      userId: userId,
      courseId: course.uniqueId!,
      status: 'active',
    );

    showSnackBarMsg(context, "Successfully enrolled in ${course.courseName}!");
    Navigator.pop(context); // Close confirm page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Enrollment"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: course.courseImage ?? "",
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (ctx, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (ctx, url, error) => Image.asset('assets/background.jpg'),
              ),
            ),
            const SizedBox(height: 20),

            Text(course.courseName ?? "Unnamed Course", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text("Total Lessons: ${course.totalVideo}", style: const TextStyle(color: Colors.grey)),
            Text("Level: ${course.level}", style: const TextStyle(color: Colors.grey)),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScanQrPage()),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text("Scan QR"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade50,
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // confirm enrollment action
                      enrollCourseAction(context, course);
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Enroll"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesListView extends StatelessWidget {
  const _CategoriesListView({
    required this.categories,
  });

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      height: 100, // You can adjust height based on your UI
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories
              .map(
                (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _MenuButton(
                onPressed: () {
                  final slug = item.slug;

                  final router = GoRouter.of(context);

                  if (slug == 'courses') {
                    router.pushNamed(Routes.myCoursesPage);
                  } else if (slug == 'gk') {
                    router.pushNamed(Routes.gkQuizPage);
                  } else if (slug == 'notice') {
                    router.pushNamed(Routes.noticePage);
                  } else if (slug == 'exam') {
                    router.pushNamed(Routes.examPage);
                  } else {
                    router.pushNamed(
                      Routes.coursesOfCategoryPage,
                      extra: item,
                    );
                  }
                },
                title: item.name,
                imagePath: item.imagePath,
              ),
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.title,
    required this.imagePath,
    required this.onPressed,
  });

  final String title;
  final String imagePath;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const radius = 17.0;

    final hasImage = imagePath.isNotEmpty;

    final ignoreWords = {'and', 'of', 'the', '&'};

    String getFallbackIconText(String title) {
      final words = title
          .trim()
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((word) => !ignoreWords.contains(word))
          .toList();

      if (words.length == 1) {
        return words.first.length >= 3
            ? words.first.substring(0, 3).toUpperCase()
            : words.first.toUpperCase();
      } else {
        return words.map((w) => w[0].toUpperCase()).join();
      }
    }

    String _formatTitle(String title) {
      final words = title.trim().split(RegExp(r'\s+'));

      if (words.length > 2) {
        return '${words[0]} ${words[1]}...';
      }

      return title;
    }

    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            width: 65,
            height: 65,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF94BFF8).withOpacity(0.3),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: hasImage
                ? SvgPicture.asset(
              imagePath,
              width: 50,
              height: 50,
            )
                : Center(
              child: Text(
                getFallbackIconText(title),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            _formatTitle(title),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5),
          ),
        ),
      ],
    );
  }
}

class _NewCoursesListView extends StatelessWidget {
  const _NewCoursesListView({
    required this.newCourses,
  });

  final List<CourseModel> newCourses;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SubHeader(
              title: 'Enrolled Courses',
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            width: context.screenWidth,
            child: ListView(
              primary: false,
              padding: const EdgeInsets.symmetric(horizontal: 13.0),
              scrollDirection: Axis.horizontal,
              children: newCourses
                  .map(
                    (item) => NewCourseCard(
                  onPressed: () {
                    context.push(Routes.courseDetailPage,
                        extra: item);
                  },
                  title: item.courseName ?? "",
                  countPlays: item.totalVideo ?? 0,
                  imageUrl: item.courseImage ?? "",
                  courseModel: item,
                ),
              )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularCoursesListView extends StatelessWidget {
  const _PopularCoursesListView({
    required this.popularCourses,
  });

  final List<CourseModel> popularCourses;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 23),
      child: Column(
        children: [
          SubHeader(
            title: 'Popular Courses',
            onPressed: () {},
          ),
          const SizedBox(height: 20),
          ListView(
            primary: false,
            shrinkWrap: true,
            children: popularCourses
                .map(
                  (item) => VideoCourseCard(
                onPressed: () {
                  context.push(Routes.courseDetailPage,
                      extra: item);
                },
                item: item,
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }
}



// class _ProfileHeader extends StatelessWidget {
//   final User user;
//
//   void showEnrollCourseDialog(BuildContext context, Function(String uniqueId) onEnroll) {
//     final TextEditingController _idController = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//           insetPadding: const EdgeInsets.all(20),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(Icons.school_rounded, size: 50, color: Colors.deepPurple),
//                   const SizedBox(height: 15),
//                   const Text(
//                     "Enroll in a Course",
//                     style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
//                   ),
//                   const SizedBox(height: 10),
//                   const Text(
//                     "Enter the course Tracking Number / Unique ID below or scan a QR code to enroll.",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 14, color: Colors.grey),
//                   ),
//                   const SizedBox(height: 20),
//
//                   // Input field
//                   TextField(
//                     controller: _idController,
//                     decoration: InputDecoration(
//                       labelText: "Tracking Number / Unique ID",
//                       prefixIcon: const Icon(Icons.numbers_rounded),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//
//                   // Buttons
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.pop(context);
//                             // trigger your scanner screen here (e.g., push QR scanner page)
//                             // Navigator.push(context, MaterialPageRoute(builder: (context) => YourScannerScreen()));
//                           },
//                           icon: const Icon(Icons.qr_code_scanner_rounded),
//                           label: const Text("Scan QR"),
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             backgroundColor: Colors.deepPurple.shade50,
//                             foregroundColor: Colors.deepPurple,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             if (_idController.text.isNotEmpty) {
//                               Navigator.pop(context);
//                               onEnroll(_idController.text.trim());
//                             } else {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(content: Text("Please enter a Tracking Number.")),
//                               );
//                             }
//                           },
//                           icon: const Icon(Icons.check_circle_rounded),
//                           label: const Text("Enroll"),
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             backgroundColor: Colors.deepPurple,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//
//   const _ProfileHeader({required this.user, required BuildContext context});
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0.0),
//       child: Row(
//         children: [
//           XAvatarCircle(
//             photoURL:
//                 "https://gratisography.com/wp-content/uploads/2024/11/gratisography-augmented-reality-800x525.jpg",
//             membership: "U",
//             progress: 60,
//             color: context.themeD.primaryColor,
//           ),
//           Expanded(
//               child: Padding(
//             padding: EdgeInsets.all(5.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: EdgeInsets.symmetric(vertical: 1.7),
//                   child: Text(
//                     "Courses",
//                     style: p21.bold,
//                   ),
//                 ),
//                 Padding(
//                   padding: EdgeInsets.symmetric(vertical: 4),
//                   child: Text(
//                     "${user.uname}",
//                     style: p14.bold.grey,
//                   ),
//                 )
//               ],
//             ),
//           )),
//           InkWell(
//             onTap: () {
//               showEnrollCourseDialog(context, (uniqueId) {
//                 _enrollCourseById(uniqueId);
//               });
//             },
//             child: Padding(
//               padding: EdgeInsets.all(10.0),
//               child: Icon(
//                 Icons.add_circle_outline_rounded,
//                 size: 40,
//               ),
//             ),
//           ),
//           InkWell(
//             onTap: () {},
//             child: Padding(
//               padding: EdgeInsets.all(10.0),
//               child: b.Badge(
//                 badgeStyle: b.BadgeStyle(
//                   borderSide: const BorderSide(color: Colors.white, width: 2),
//                   badgeColor: Colors.red.withOpacity(0.9),
//                   borderRadius: BorderRadius.circular(13),
//                   elevation: 0,
//                 ),
//                 badgeContent: Text("7",
//                     style: TextStyle(color: Colors.white, fontSize: 12)),
//                 child: Icon(
//                   Icons.notifications_outlined,
//                   size: 40,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _enrollCourseById(String uniqueId) async {
//
//     try {
//       CourseModel? course;
//
//       if (await InternetConnectionChecker.instance.hasConnection) {
//         // Fetch from Firebase
//         final dbRef = FirebaseDatabase.instance.ref("courses").child(uniqueId);
//         final snapshot = await dbRef.get();
//
//         if (snapshot.exists) {
//           final courseMap = Map<String, dynamic>.from(snapshot.value as Map);
//           course = CourseModel.fromJson(courseMap);
//         }
//       }
//
//       // If not found online, try offline
//       if (course == null) {
//         course = await CourseDAO().getCourseByUniqueId(uniqueId);
//       }
//
//       if (course != null) {
//         // Navigate to EnrollCoursePage
//         if (mounted) {
//           // Navigator.push(
//           //   context,
//           //   MaterialPageRoute(
//           //     builder: (context) => EnrollCoursePage(course: course),
//           //   ),
//           // );
//         }
//       } else {
//         // showSnackBarMsg(context, "Course not found for this Tracking ID.");
//       }
//
//     } catch (e) {
//       print("Enrollment by ID failed: $e");
//       // showSnackBarMsg(context, "Failed to enroll by ID.");
//     } finally {
//       // if (mounted) setState(() => isLoading = false);
//     }
//   }
//
// }


// class _NewCoursesListView extends StatelessWidget {
//   const _NewCoursesListView({
//     required this.newCourses,
//   });
//
//   final List<VideoCourse> newCourses;
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20.0),
//             child: SubHeader(
//               title: 'Enrolled Courses',
//               onPressed: () {},
//             ),
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             height: 300,
//             width: context.screenWidth,
//             child: ListView(
//               primary: false,
//               padding: const EdgeInsets.symmetric(horizontal: 13.0),
//               scrollDirection: Axis.horizontal,
//               children: newCourses
//                   .map(
//                     (item) => NewCourseCard(
//                   onPressed: () {},
//                   title: item.title,
//                   countPlays: item.countPreviewVideoPlays,
//                   imageUrl: item.imageUrl,
//                 ),
//               )
//                   .toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _PopularCoursesListView extends StatelessWidget {
//   const _PopularCoursesListView({
//     required this.popularCourses,
//   });
//
//   final List<VideoCourse> popularCourses;
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 23),
//       child: Column(
//         children: [
//           SubHeader(
//             title: 'Popular Courses',
//             onPressed: () {},
//           ),
//           const SizedBox(height: 20),
//           ListView(
//             primary: false,
//             shrinkWrap: true,
//             children: popularCourses
//                 .map(
//                   (item) => VideoCourseCard(
//                 onPressed: () {},
//                 item: item,
//               ),
//             )
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CategoriesListView extends StatelessWidget {
//   const _CategoriesListView({
//     required this.categories,
//   });
//
//   final List<Category> categories;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: categories
//             .map(
//               (item) => _MenuButton(
//             onPressed: () {},
//             title: item.name,
//             imagePath: item.imagePath,
//           ),
//         )
//             .toList(),
//       ),
//     );
//   }
// }

// class _MenuButton extends StatelessWidget {
//   const _MenuButton({
//     required this.title,
//     required this.imagePath,
//     required this.onPressed,
//   });
//
//   final String title;
//   final String imagePath;
//   final VoidCallback onPressed;
//
//   @override
//   Widget build(BuildContext context) {
//     const radius = 17.00;
//
//     return Column(
//       children: [
//         InkWell(
//           onTap: onPressed,
//           borderRadius: BorderRadius.circular(radius),
//           child: Ink(
//             padding: const EdgeInsets.all(12),
//             width: 65,
//             height: 65,
//             decoration: BoxDecoration(
//               color: const Color(0xFF94BFF8).withOpacity(0.3),
//               borderRadius: BorderRadius.circular(radius),
//             ),
//             child: SvgPicture.asset(
//               imagePath,
//               width: 50,
//               height: 50,
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Text(
//             title,
//             style: const TextStyle(fontSize: 13.5),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _MenuButton extends StatelessWidget {
//   const _MenuButton({
//     required this.title,
//     required this.imagePath,
//     required this.onPressed,
//   });
//
//   final String title;
//   final String imagePath;
//   final VoidCallback onPressed;
//
//   @override
//   Widget build(BuildContext context) {
//     const radius = 17.00;
//
//     // final hasImage = imagePath.isNotEmpty;
//     final hasImage = imagePath.isNotEmpty;
//
//
//     return Column(
//       children: [
//         InkWell(
//           onTap: onPressed,
//           borderRadius: BorderRadius.circular(radius),
//           child: Ink(
//             padding: const EdgeInsets.all(12),
//             width: 65,
//             height: 65,
//             decoration: BoxDecoration(
//               color: const Color(0xFF94BFF8).withOpacity(0.3),
//               borderRadius: BorderRadius.circular(radius),
//             ),
//             child: hasImage
//                 ? SvgPicture.asset(
//               imagePath,
//               width: 50,
//               height: 50,
//             )
//                 : Center(
//               child: Text(
//                 title.length >= 3 ? title.substring(0, 3).toUpperCase() : title.toUpperCase(),
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1A1A1A),
//                 ),
//               ),
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Text(
//             title,
//             textAlign: TextAlign.center,
//             style: const TextStyle(fontSize: 13.5),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _MenuButton extends StatelessWidget {
//   const _MenuButton({
//     required this.title,
//     required this.imagePath,
//     required this.onPressed,
//   });
//
//   final String title;
//   final String imagePath;
//   final VoidCallback onPressed;
//
//   @override
//   Widget build(BuildContext context) {
//     const radius = 17.0;
//
//     final hasImage = imagePath.isNotEmpty;
//
//     String getFallbackIconText(String title) {
//       final words = title.trim().split(RegExp(r'\s+'));
//       if (words.length == 1) {
//         return words.first.length >= 3
//             ? words.first.substring(0, 3).toUpperCase()
//             : words.first.toUpperCase();
//       } else {
//         return words.map((w) => w[0].toUpperCase()).take(3).join();
//       }
//     }
//
//     return Column(
//       children: [
//         InkWell(
//           onTap: onPressed,
//           borderRadius: BorderRadius.circular(radius),
//           child: Ink(
//             width: 65,
//             height: 65,
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: const Color(0xFF94BFF8).withOpacity(0.3),
//               borderRadius: BorderRadius.circular(radius),
//             ),
//             child: hasImage
//                 ? SvgPicture.asset(
//               imagePath,
//               width: 50,
//               height: 50,
//             )
//                 : Center(
//               child: Text(
//                 getFallbackIconText(title),
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1A1A1A),
//                 ),
//               ),
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Text(
//             title,
//             textAlign: TextAlign.center,
//             style: const TextStyle(fontSize: 13.5),
//           ),
//         ),
//       ],
//     );
//   }
// }





// void showEnrollCourseDialog(BuildContext context, Function(String uniqueId) onEnroll) {
//   final TextEditingController _idController = TextEditingController();
//
//   showDialog(
//     context: context,
//     builder: (context) {
//       return Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         insetPadding: const EdgeInsets.all(20),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(Icons.school_rounded, size: 50, color: Colors.deepPurple),
//                 const SizedBox(height: 15),
//                 const Text(
//                   "Enroll in a Course",
//                   style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   "Enter the course Tracking Number / Unique ID below or scan a QR code to enroll.",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 14, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 20),
//
//                 // Input field
//                 TextField(
//                   controller: _idController,
//                   decoration: InputDecoration(
//                     labelText: "Tracking Number / Unique ID",
//                     prefixIcon: const Icon(Icons.numbers_rounded),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//
//                 // Buttons
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: () {
//                           Navigator.pop(context);
//                           Navigator.push(context, MaterialPageRoute(builder: (context) => ScanQrPage()));
//                         },
//                         icon: const Icon(Icons.qr_code_scanner_rounded),
//                         label: const Text("Scan QR"),
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           backgroundColor: Colors.deepPurple.shade50,
//                           foregroundColor: Colors.deepPurple,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: () {
//                           if (_idController.text.isNotEmpty) {
//                             // Navigator.pop(context);
//                             onEnroll(_idController.text.trim());
//                           } else {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(content: Text("Please enter a Tracking Number.")),
//                             );
//                           }
//                         },
//                         icon: const Icon(Icons.check_circle_rounded),
//                         label: const Text("Enroll"),
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           backgroundColor: Colors.deepPurple,
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }


// void showEnrollCourseDialog(BuildContext context, Function(String uniqueId) onEnroll) {
//   final TextEditingController _idController = TextEditingController();
//
//   showDialog(
//     context: context,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (context, setState) {
//           bool isProcessing = false;
//
//           return Dialog(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//             insetPadding: const EdgeInsets.all(20),
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(Icons.school_rounded, size: 50, color: Colors.deepPurple),
//                     const SizedBox(height: 15),
//                     const Text(
//                       "Enroll in a Course",
//                       style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
//                     ),
//                     const SizedBox(height: 10),
//                     const Text(
//                       "Enter the course Tracking Number / Unique ID below or scan a QR code to enroll.",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: 14, color: Colors.grey),
//                     ),
//                     const SizedBox(height: 20),
//
//                     // Input field
//                     TextField(
//                       controller: _idController,
//                       enabled: !isProcessing,
//                       decoration: InputDecoration(
//                         labelText: "Tracking Number / Unique ID",
//                         prefixIcon: const Icon(Icons.numbers_rounded),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//
//                     if (!isProcessing)
//                       Row(
//                         children: [
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: () {
//                                 Navigator.pop(context);
//                                 Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanQrPage()));
//                               },
//                               icon: const Icon(Icons.qr_code_scanner_rounded),
//                               label: const Text("Scan QR"),
//                               style: ElevatedButton.styleFrom(
//                                 padding: const EdgeInsets.symmetric(vertical: 14),
//                                 backgroundColor: Colors.deepPurple.shade50,
//                                 foregroundColor: Colors.deepPurple,
//                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: () {
//                                 if (_idController.text.isNotEmpty) {
//                                   setState(() {
//                                     isProcessing = true;
//                                   });
//
//                                   Future.delayed(const Duration(seconds: 3), () {
//                                     Navigator.pop(context);
//                                     onEnroll(_idController.text.trim());
//                                   });
//                                 } else {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(content: Text("Please enter a Tracking Number.")),
//                                   );
//                                 }
//                               },
//                               icon: const Icon(Icons.check_circle_rounded),
//                               label: const Text("Enroll"),
//                               style: ElevatedButton.styleFrom(
//                                 padding: const EdgeInsets.symmetric(vertical: 14),
//                                 backgroundColor: Colors.deepPurple,
//                                 foregroundColor: Colors.white,
//                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                               ),
//                             ),
//                           ),
//                         ],
//                       )
//                     else
//                       Column(
//                         children: const [
//                           CircularProgressIndicator(color: Colors.deepPurple),
//                           SizedBox(height: 20),
//                           Text(
//                             "Processing enrollment...",
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.deepPurple),
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );
// }
