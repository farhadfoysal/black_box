import 'dart:convert';
import 'dart:io';

import 'package:black_box/model/school/teacher.dart';
import 'package:black_box/routes/routes.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class MyCoursesPage  extends StatefulWidget {
  const MyCoursesPage ({Key? key}) : super(key: key);

  @override
  State<MyCoursesPage > createState() => _MyCoursesPageState ();
}

class _MyCoursesPageState  extends State<MyCoursesPage > {
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

  final List<CourseModel> allCourses = [
    CourseModel(
      courseName: 'Flutter Beginner',
      totalVideo: 10,
      totalRating: 4.5,
      totalTime: '2h 30m',
      courseImage: 'https://fastly.picsum.photos/id/870/200/300.jpg?blur=2&grayscale&hmac=ujRymp644uYVjdKJM7kyLDSsrqNSMVRPnGU99cKl6Vs',
      level: 'Beginner',
      countStudents: 120,
      createdAt: DateTime.now(),
    ),
    CourseModel(
      courseName: 'Dart Fundamentals',
      totalVideo: 8,
      totalRating: 4.2,
      totalTime: '1h 50m',
      courseImage: 'https://fastly.picsum.photos/id/50/200/300.jpg?hmac=wlHRGoenBSt-gzxGvJp3cBEIUD71NKbWEXmiJC2mQYE',
      level: 'Beginner',
      countStudents: 95,
      createdAt: DateTime.now(),
    ),
    CourseModel(
      courseName: 'Mobile App Security',
      totalVideo: 7,
      totalRating: 4.8,
      totalTime: '3h 20m',
      courseImage: 'https://fastly.picsum.photos/id/443/200/300.jpg?grayscale&hmac=3KGsrU5Oo_hghp3-Xuzs6myA2cu1cKEvgsz05yWhKWA',
      level: 'Intermediate',
      countStudents: 80,
      createdAt: DateTime.now(),
    ),
    CourseModel(
      courseName: 'Backend Development',
      totalVideo: 12,
      totalRating: 4.7,
      totalTime: '2h 45m',
      // courseImage: 'https://fastly.picsum.photos/id/866/200/300.jpg?hmac=rcadCENKh4rD6MAp6V_ma-AyWv641M4iiOpe1RyFHeI',
      level: 'Intermediate',
      countStudents: 150,
      createdAt: DateTime.now(),
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
    });
    _initializeData();
  }

  Future<void> _initializeData() async {
    // First load user data
    await _loadUserData();

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
    final TextEditingController uniqueIdController = TextEditingController();
    final TextEditingController userNameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController guardianPhoneController =
    TextEditingController();
    final TextEditingController phonePassController = TextEditingController();
    final TextEditingController dobController = TextEditingController();
    final TextEditingController educationController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController imgController = TextEditingController();
    final List<TutorWeekDay> weekDays = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void _addWeekDay() {
            final TextEditingController timeController =
            TextEditingController();
            final TextEditingController minutesController =
            TextEditingController();
            String? selectedDay;
            bool isAdding = false;
            String message = '';

            showDialog(
              context: context,
              builder: (context) => StatefulBuilder(
                builder: (context, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Add Week Day',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Message TextField at the top
                        if (message.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              message,
                              style: TextStyle(
                                color: message.startsWith('Please')
                                    ? Colors.red
                                    : Colors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        // Dropdown for Day
                        DropdownButtonFormField<String>(
                          value: selectedDay,
                          decoration: InputDecoration(
                            labelText: 'Day',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday',
                          ]
                              .map((day) => DropdownMenuItem(
                              value: day, child: Text(day)))
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedDay = value;
                              message = ''; // Clear any previous message
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: timeController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Time',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onTap: () async {
                                  TimeOfDay? selectedTime =
                                  await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (selectedTime != null) {
                                    setDialogState(() {
                                      timeController.text =
                                          selectedTime.format(context);
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: minutesController,
                                decoration: InputDecoration(
                                  labelText: 'Minutes',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Close',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      onPressed: isAdding
                          ? null
                          : () {
                        if (selectedDay != null) {
                          setDialogState(() {
                            isAdding = true;
                            message = ''; // Clear previous message
                          });
                          TutorWeekDay day = TutorWeekDay(
                            uniqueId: DateTime.now().toIso8601String(),
                            studentId: uniqueIdController.text,
                            userId: userNameController.text,
                            day: selectedDay!,
                            time: timeController.text,
                            minutes:
                            int.tryParse(minutesController.text) ?? 0,
                          );
                          setModalState(() {
                            weekDays.add(
                                day); // Add the day to the parent list
                          });
                          Future.delayed(Duration(seconds: 2), () {
                            setDialogState(() {
                              isAdding = false;
                              message =
                              'Week Day added successfully!'; // Success message
                            });
                          });
                          Future.delayed(Duration(seconds: 3), () {
                            // Navigator.pop(context);
                          });
                        } else {
                          setDialogState(() {
                            message =
                            'Please select a day'; // Error message
                          });
                        }
                      },
                      child: isAdding
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        'Add',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 10,
              right: 10,
              top: 20,
            ),
            child: Card(
              color: Colors.white,
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 50,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        color: Colors.pinkAccent,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(Icons.face_retouching_natural_outlined,
                              color: Colors.white),
                          const SizedBox(width: 12),
                          const Text(
                            "Add Student",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pop(); // Close the dialog or screen
                            },
                            icon: Icon(Icons.close, color: Colors.white),
                          ),
                          const SizedBox(
                              width:
                              12), // Optional, adds a little padding from the edge
                        ],
                      ),
                    ),

                    _buildTextField(userNameController, 'Name', Icons.person),
                    _buildTextField(phoneController, 'Phone', Icons.phone),
                    _buildTextField(guardianPhoneController, 'Guardian Phone',
                        Icons.phone_in_talk),
                    _buildTextField(phonePassController, 'Email', Icons.email),
                    _buildTextField(
                        educationController, 'Education', Icons.school),
                    _buildTextField(addressController, 'Address', Icons.home),
                    _buildTextField(imgController, 'Image URL', Icons.image),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment
                          .centerRight, // Aligns the button to the right
                      child: ElevatedButton(
                        onPressed: _addWeekDay,
                        style: ElevatedButton.styleFrom(
                          elevation: 5, // Adds shadow
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(30), // Rounded corners
                          ),
                          backgroundColor: Colors.pinkAccent, // Button color
                        ),
                        child: Row(
                          mainAxisSize:
                          MainAxisSize.min, // Keeps the button compact
                          children: [
                            const Icon(Icons.add,
                                color: Colors.white), // Icon on the left
                            const SizedBox(width: 8),
                            const Text(
                              'Add Day',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ListView.builder(
                    //   shrinkWrap: true,
                    //   itemCount: weekDays.length,
                    //   itemBuilder: (context, index) {
                    //     return Padding(
                    //       padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
                    //       child: Card(
                    //         shape: RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(12),
                    //         ),
                    //         elevation: 4,
                    //         child: ListTile(
                    //           contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 5),
                    //           title: Text(
                    //             'Day: ${weekDays[index].day}',
                    //             style: TextStyle(
                    //               fontWeight: FontWeight.bold,
                    //               fontSize: 16,
                    //             ),
                    //           ),
                    //           subtitle: Text(
                    //             'Time: ${weekDays[index].time}, Minutes: ${weekDays[index].minutes}',
                    //             style: TextStyle(
                    //               color: Colors.grey[600],
                    //               fontSize: 14,
                    //             ),
                    //           ),
                    //           trailing: IconButton(
                    //             onPressed: () {
                    //               setModalState(() {
                    //                 weekDays.removeAt(index);
                    //               });
                    //
                    //               ScaffoldMessenger.of(context).showSnackBar(
                    //                 SnackBar(
                    //                   content: Text('Item deleted successfully'),
                    //                   backgroundColor: Colors.redAccent,
                    //                 ),
                    //               );
                    //             },
                    //             icon: Icon(
                    //               Icons.delete,
                    //               color: Colors.redAccent,
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),

                    Wrap(
                      spacing: 8.0, // Horizontal space between items
                      runSpacing: 6.0, // Vertical space between lines
                      children: weekDays.map((weekDay) {
                        return Chip(
                          label: Row(
                            children: [
                              Text(
                                'Day: ${weekDay.day}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Time: ${weekDay.time}, Minutes: ${weekDay.minutes}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          deleteIcon: Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onDeleted: () {
                            setModalState(() {
                              weekDays.removeAt(weekDays.indexOf(weekDay));
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Item deleted successfully'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),

                    // GridView.builder(
                    //   shrinkWrap: true,
                    //   physics: NeverScrollableScrollPhysics(), // Prevents nested scroll behavior
                    //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    //     crossAxisCount: 2, // Number of columns in the grid
                    //     crossAxisSpacing: 8, // Space between columns
                    //     mainAxisSpacing: 8, // Space between rows
                    //   ),
                    //   itemCount: weekDays.length,
                    //   itemBuilder: (context, index) {
                    //     return Padding(
                    //       padding: const EdgeInsets.all(8),
                    //       child: Card(
                    //         shape: RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(12),
                    //         ),
                    //         elevation: 4,
                    //         child: Column(
                    //           mainAxisAlignment: MainAxisAlignment.center,
                    //           children: [
                    //             Text(
                    //               'Day: ${weekDays[index].day}',
                    //               style: TextStyle(
                    //                 fontWeight: FontWeight.bold,
                    //                 fontSize: 16,
                    //               ),
                    //             ),
                    //             SizedBox(height: 8),
                    //             Text(
                    //               'Time: ${weekDays[index].time}, Minutes: ${weekDays[index].minutes}',
                    //               style: TextStyle(
                    //                 color: Colors.grey[600],
                    //                 fontSize: 14,
                    //               ),
                    //             ),
                    //             IconButton(
                    //               onPressed: () {
                    //                 setModalState(() {
                    //                   weekDays.removeAt(index);
                    //                 });
                    //                 ScaffoldMessenger.of(context).showSnackBar(
                    //                   SnackBar(
                    //                     content: Text('Item deleted successfully'),
                    //                     backgroundColor: Colors.redAccent,
                    //                   ),
                    //                 );
                    //               },
                    //               icon: Icon(
                    //                 Icons.delete,
                    //                 color: Colors.redAccent,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),

                    SizedBox(
                        height: 10), // Adds some space between form and button
                    // Container(
                    //   alignment: Alignment.center,
                    //   margin: const EdgeInsets.all(10),
                    //   child: Material(
                    //     elevation: 3,
                    //     borderRadius: BorderRadius.circular(20),
                    //     child: Container(
                    //       width: MediaQuery.of(context).size.width,
                    //       height: 50,
                    //       decoration: BoxDecoration(
                    //         borderRadius: BorderRadius.circular(20),
                    //         color: Colors.white,
                    //       ),
                    //       child: Material(
                    //         borderRadius: BorderRadius.circular(20),
                    //         color: Colors.pinkAccent,
                    //         child: InkWell(
                    //           splashColor: Colors.pink,
                    //           borderRadius: BorderRadius.circular(20),
                    //           onTap: () {
                    //             setState(() {
                    //               students.add(TutorStudent(
                    //                 uniqueId: uniqueIdController.text,
                    //                 userId: userNameController.text,
                    //                 phone: phoneController.text,
                    //                 gaurdianPhone: guardianPhoneController.text,
                    //                 phonePass: phonePassController.text,
                    //                 dob: dobController.text,
                    //                 education: educationController.text,
                    //                 address: addressController.text,
                    //                 activeStatus: 1,
                    //                 admittedDate: DateTime.now(),
                    //                 img: imgController.text,
                    //                 days: weekDays,
                    //               ));
                    //             });
                    //             Navigator.pop(context);
                    //             ScaffoldMessenger.of(context).showSnackBar(
                    //               const SnackBar(
                    //                 content: Row(
                    //                   children: [
                    //                     Icon(
                    //                       Icons.info_outline,
                    //                       color: Colors.white,
                    //                     ),
                    //                     SizedBox(width: 10),
                    //                     Text(
                    //                       "Ups, foto dan inputan tidak boleh kosong!",
                    //                       style: TextStyle(color: Colors.white),
                    //                     ),
                    //                   ],
                    //                 ),
                    //                 backgroundColor: Colors.redAccent,
                    //                 shape: StadiumBorder(),
                    //                 behavior: SnackBarBehavior.floating,
                    //               ),
                    //             );
                    //           },
                    //           child: const Center(
                    //             child: Text(
                    //               " Save Student",
                    //               style: TextStyle(
                    //                 color: Colors.white,
                    //                 fontWeight: FontWeight.bold,
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.all(10),
                      child: Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: Material(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.pinkAccent,
                            child: InkWell(
                              splashColor: Colors.pink,
                              borderRadius: BorderRadius.circular(20),
                              onTap: isLoading
                                  ? null
                                  : () {
                                setModalState(() {});
                                setState(() {
                                  isLoading = true;

                                  TutorStudent student = TutorStudent(
                                    name: userNameController.text,
                                    phone: phoneController.text,
                                    gaurdianPhone:
                                    guardianPhoneController.text,
                                    phonePass: phonePassController.text,
                                    education: educationController.text,
                                    address: addressController.text,
                                    activeStatus: 1,
                                    admittedDate: DateTime.now(),
                                    img: imgController.text,
                                    days: weekDays,
                                  );
                                  // saveStudent(student);
                                });
                              },
                              child: Center(
                                child: isLoading
                                    ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : Text(
                                  " Save Student",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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

  @override
  Widget build(BuildContext context) {
    // category = GoRouterState.of(context).extra as Category;

    return Scaffold(
      appBar: AppBar(title: Text("My Courses")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
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
                  return GestureDetector(
                    onTap: () async {
                      context.push(Routes.courseDetailPage, extra: course);
                    },
                    child: CourseCard(
                      courseImage: course.courseImage ?? '',
                      courseName: course.courseName ?? '',
                      rating: course.totalRating ?? 0,
                      totalTime: course.totalTime ?? '',
                      totalVideo: course.totalVideo?.toString() ?? '0',
                    ),
                  );
                },
              ),
            ),



            Positioned(
              bottom: 20,
              right: 20,
              child: ElevatedButton(
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
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
