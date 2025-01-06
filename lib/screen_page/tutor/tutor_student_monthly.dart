import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:black_box/screen_page/tutor/tutor_student_dates.dart';
import 'package:black_box/screen_page/tutor/tutor_student_monthly_dates.dart';
import 'package:black_box/screen_page/tutor/tutor_student_payment.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../db/local/database_manager.dart';
import '../../model/school/school.dart';
import '../../model/school/teacher.dart';
import '../../model/tutor/tutor_month.dart';
import '../../model/tutor/tutor_student.dart';
import '../../model/tutor/tutor_date.dart';
import '../../model/user/user.dart';
import '../../preference/logout.dart';
import '../../utility/unique.dart';

class TutorStudentMonthly extends StatefulWidget {
  final TutorStudent student;

  TutorStudentMonthly({required this.student});

  @override
  State<TutorStudentMonthly> createState() => _TutorStudentMonthlyState();
}

class _TutorStudentMonthlyState extends State<TutorStudentMonthly> {
  List<TutorMonth> tutorMonths = [];

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

  @override
  void initState() {
    super.initState();
    _loadUserName();
    // _loadSampleData();
    setState(() {
      isLoading = true;
    });
    _initializeData();
  }

  Future<void> _initializeData() async {
    // First load user data
    await _loadUserData();

    _loadTutorMonthsData();
  }

  Future<void> _loadTutorMonthsData() async {
    if (await InternetConnectionChecker.instance.hasConnection) {
      setState(() {
        isLoading = true;
      });

      DatabaseReference teachersRef = _databaseRef.child('tutor_month');

      Query query = teachersRef
          .orderByChild('student_id')
          .equalTo(widget.student.uniqueId);

      query.once().then((DatabaseEvent event) {
        final dataSnapshot = event.snapshot;

        if (dataSnapshot.exists) {
          final Map<dynamic, dynamic> studentsData =
          dataSnapshot.value as Map<dynamic, dynamic>;

          setState(() {
            tutorMonths.clear();

            tutorMonths = studentsData.entries.map((entry) {
              // Convert each entry's value to Map<String, dynamic>
              final studentMap = Map<String, dynamic>.from(entry.value as Map);

              return TutorMonth.fromJson(studentMap);
            }).toList();

            isLoading = false;
          });
        } else {
          print(_user?.userid);
          print('No Month data available for the current Student.');
          setState(() {
            isLoading = false;
          });
        }
      }).catchError((error) {
        print('Failed to load Month data: $error');
        setState(() {
          isLoading = false;
        });
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

  // void _loadSampleData() {
  //   setState(() {
  //     tutorMonths = [
  //       TutorMonth(
  //         id: 1,
  //         uniqueId: "20250101_123456",
  //         studentId: "STU123",
  //         userId: "TUTOR001",
  //         month: "January",
  //         startDate: DateTime(2025, 1, 1),
  //         endDate: DateTime(2025, 1, 31),
  //         paid: 1,
  //         dates: generateDates(DateTime(2025, 1, 1), DateTime(2025, 1, 31)),
  //       ),
  //       TutorMonth(
  //         id: 2,
  //         uniqueId: "20250201_123457",
  //         studentId: "STU123",
  //         userId: "TUTOR001",
  //         month: "February",
  //         startDate: DateTime(2025, 2, 1),
  //         endDate: DateTime(2025, 2, 28),
  //         paid: 0,
  //         dates: generateDates(DateTime(2025, 2, 1), DateTime(2025, 2, 28)),
  //       ),
  //     ];
  //   });
  // }

  List<TutorDate> generateDates(DateTime startDate, DateTime endDate) {
    List<TutorDate> generatedDates = [];

    for (DateTime date = startDate;
    date.isBefore(endDate.add(Duration(days: 1)));
    date = date.add(Duration(days: 1))) {
      // Determine the day of the week (e.g., "Monday", "Tuesday")
      String dayOfWeek = date.weekday == 1
          ? "Monday"
          : date.weekday == 2
          ? "Tuesday"
          : date.weekday == 3
          ? "Wednesday"
          : date.weekday == 4
          ? "Thursday"
          : date.weekday == 5
          ? "Friday"
          : date.weekday == 6
          ? "Saturday"
          : "Sunday";

      generatedDates.add(
        TutorDate(
          id: generatedDates.length + 1,
          uniqueId:
          "${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_123${generatedDates.length + 1}",
          day: dayOfWeek,
          date: date
              .toString()
              .split(" ")[0], // Extract date in YYYY-MM-DD format
          dayDate: date,
          attendance: 0, // Initially absent
          minutes: 0, // No minutes initially
        ),
      );
    }

    return generatedDates;
  }

  void showMonthYearPicker() async {
    DateTime now = DateTime.now();
    int currentYear = now.year;

    List<String> months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];

    // Show a dialog to pick the month
    String? selectedMonth = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Month"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: months.map((month) {
              return ListTile(
                title: Text(month),
                onTap: () {
                  Navigator.pop(context, month);
                },
              );
            }).toList(),
          ),
        );
      },
    );

    if (selectedMonth != null) {
      int monthValue = months.indexOf(selectedMonth) + 1;

      setState(() {
        addMonth(selectedMonth, monthValue, currentYear);
      });
    }
  }

  Future<void> addMonth(String selectedMonth, int month, int year) async {
    DateTime startDate = DateTime(year, month, 1);
    DateTime endDate = DateTime(year, month + 1, 0);

    TutorMonth newMonth = TutorMonth(
      uniqueId:
      "${startDate.year}${startDate.month.toString().padLeft(2, '0')}_123${tutorMonths.length + 1}",
      studentId: widget.student.uniqueId,
      userId: _user?.userid,
      month: "${selectedMonth} ${year}",
      startDate: startDate,
      endDate: endDate,
      paid: 0,
      dates: generateDates(startDate, endDate),
    );

    await saveTutorMonth(newMonth);

    showSnackBarMsg(context, "$month $year added successfully!");
  }

  Future<void> saveTutorMonth(TutorMonth month) async {
    setState(() {
      isLoading = true;
    });

    var uuid = Uuid();
    String uniqueId = Unique().generateUniqueID();
    int ranId =
        Random().nextInt(1000000000) + DateTime.now().millisecondsSinceEpoch;
    // String referr = utf8.decode([Random().nextInt(256)]).toUpperCase();
    // String numberr = '$ranId$referr';

    month.uniqueId = uniqueId;
    month.userId = _user?.userid;

    if (await InternetConnectionChecker.instance.hasConnection) {
      final DatabaseReference dbRef =
      FirebaseDatabase.instance.ref("tutor_month").child(month.uniqueId!);

      try {
        await dbRef.set(month.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Month saved successfully!')),
        );

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        setState(() {
          tutorMonths.add(month);
        });
        saveTutorMonthOffline(month);
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const AdminLogin(),
        //   ),
        // );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Month: $e')),
        );
      }
    } else {
      final result = await DatabaseManager().insertTutorMonth(month);
      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Month saved successfully!')),
        );

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        setState(() {
          tutorMonths.add(month);
        });

        // context.push(Routes.messAdmin);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Month')),
        );
      }
    }

    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        isLoading = false;
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              "Ups, Successfully Saved!",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        shape: StadiumBorder(),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> saveTutorMonthOffline(TutorMonth month) async {
    final result = await DatabaseManager().insertTutorMonth(month);
    if (result > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Month saved successfully!')),
      );

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      setState(() {
        tutorMonths.add(month);
      });

      // context.push(Routes.messAdmin);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save Month')),
      );
    }
  }

  Future<void> updateTutorMonthDates(TutorMonth month) async {
    setState(() {
      isLoading = true;
    });

    var uuid = Uuid();
    String uniqueId = Unique().generateUniqueID();
    int ranId =
        Random().nextInt(1000000000) + DateTime.now().millisecondsSinceEpoch;

    month.uniqueId = uniqueId;
    month.userId = _user?.userid;

    if (await InternetConnectionChecker.instance.hasConnection) {
      final DatabaseReference dbRef =
      FirebaseDatabase.instance.ref("tutor_month").child(month.uniqueId!);

      try {
        // Update the dates field in Firebase
        await dbRef.update({
          'dates': month.dates?.map((date) => date.toMap()).toList(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tutor Month dates updated successfully!')),
        );

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        setState(() {
          tutorMonths.add(month);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update Tutor Month dates: $e')),
        );
      }
    } else {
      final result = await DatabaseManager().updateTutorMonthDates(month);
      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tutor Month dates updated successfully!')),
        );

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        setState(() {
          tutorMonths.add(month);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update Tutor Month dates')),
        );
      }
    }

    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        isLoading = false;
      });
      Navigator.pop(context);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              "Successfully Updated!",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.greenAccent,
        shape: StadiumBorder(),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.student.name}'s"),
        backgroundColor: Colors.blueAccent,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: showMonthYearPicker,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, // Text color
                backgroundColor: Colors.pinkAccent, // Button color
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25), // Rounded edges
                ),
                elevation: 5, // Shadow effect
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month, size: 20),
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
                    "Add Month",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(), // Show loading indicator
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // _buildProfileSection(),
            ProfileSection(student: widget.student),

            Divider(thickness: 1.5),

            _buildMonthlySchedule(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        // Profile Picture and Name
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 200,
              color: Colors.blueAccent,
            ),
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                widget.student.img ?? 'https://via.placeholder.com/150',
              ),
            ),
          ],
        ),
        SizedBox(height: 20),

        // Name and Status
        Text(
          widget.student.name ?? "Unknown",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Chip(
          label: Text(
            widget.student.activeStatus == 1 ? "Active" : "Inactive",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor:
          widget.student.activeStatus == 1 ? Colors.green : Colors.red,
        ),
        SizedBox(height: 20),

        // Personal Information
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoTile(
                icon: Icons.phone,
                label: "Phone",
                value: widget.student.phone ?? "N/A",
              ),
              InfoTile(
                icon: Icons.person,
                label: "Guardian Phone",
                value: widget.student.gaurdianPhone ?? "N/A",
              ),
              InfoTile(
                icon: Icons.calendar_today,
                label: "Date of Birth",
                value: widget.student.dob ?? "N/A",
              ),
              InfoTile(
                icon: Icons.school,
                label: "Education",
                value: widget.student.education ?? "N/A",
              ),
              InfoTile(
                icon: Icons.home,
                label: "Address",
                value: widget.student.address ?? "N/A",
              ),
              InfoTile(
                icon: Icons.date_range,
                label: "Admitted Date",
                value: widget.student.admittedDate
                    ?.toLocal()
                    .toString()
                    .split(' ')[0] ??
                    "N/A",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySchedule() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            "Monthly Schedule",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),
          SizedBox(height: 10),

          // List of monthly schedules
          tutorMonths.isNotEmpty
              ? ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: tutorMonths.length,
            itemBuilder: (context, index) {
              final month = tutorMonths[index];
              bool isExpanded = false; // Initial collapsed state

              return StatefulBuilder(
                builder: (context, setState) {
                  return GestureDetector(
                    onTap: () {
                      // Navigate to TutorStudentMonthlyDates page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TutorStudentDates(
                            student: widget.student,
                            month: month,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      color: Colors.pink.shade50,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Month and Paid Status
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${month.month ?? "N/A"}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink.shade900,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    month.paid == 1 ? "Paid" : "Unpaid",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: month.paid == 1
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ],
                            ),
                            SizedBox(height: 10),

                            // Start and End Dates
                            Text(
                              "Start: ${month.startDate?.toLocal().toString().split(' ')[0] ?? "N/A"}",
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              "End: ${month.endDate?.toLocal().toString().split(' ')[0] ?? "N/A"}",
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 10),

                            // Collapsible Dates Section
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Dates:",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.pink.shade700,
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: Colors.pink.shade700,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 5),

                            if (isExpanded)
                              month.dates != null &&
                                  month.dates!.isNotEmpty
                                  ? Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: month.dates!
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  int index = entry.key + 1;
                                  TutorDate date = entry.value;
                                  return Padding(
                                    padding:
                                    const EdgeInsets.symmetric(
                                        vertical: 2.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          "$index.",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight:
                                            FontWeight.bold,
                                            color: Colors
                                                .pink.shade800,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          "${date.day ?? "N/A"} (${date.date ?? "N/A"})",
                                          style: TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              )
                                  : Text(
                                "No specific dates available",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            SizedBox(height: 10),

                            // Payment and Others Buttons
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TutorStudentPayment(
                                          student: widget.student,
                                          month: month,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(10.0),
                                    ),
                                  ),
                                  icon: Icon(Icons.payment,
                                      color: Colors.white),
                                  label: Text("Payment"),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Handle Others action
                                    print("Others for ${month.month}");
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink.shade200,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(10.0),
                                    ),
                                  ),
                                  icon: Icon(Icons.more_horiz,
                                      color: Colors.white),
                                  label: Text("Others"),
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
          )
              : Center(
            child: Text(
              "No monthly schedules available",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

// Widget _buildMonthlySchedule() {
//   return Padding(
//     padding: const EdgeInsets.all(16.0),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Title
//         Text(
//           "Monthly Schedule",
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.pink,
//           ),
//         ),
//         SizedBox(height: 10),
//
//         // List of monthly schedules
//         tutorMonths.isNotEmpty
//             ? ListView.builder(
//           shrinkWrap: true,
//           physics: NeverScrollableScrollPhysics(),
//           itemCount: tutorMonths.length,
//           itemBuilder: (context, index) {
//             final month = tutorMonths[index];
//             return GestureDetector(
//               onTap: () {
//                 // Navigate to TutorStudentMonthlyDates page
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => TutorStudentMonthlyDates(
//                       student: widget.student,
//                       month: month,
//                     ),
//                   ),
//                 );
//               },
//               child: Card(
//                 elevation: 5,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15.0),
//                 ),
//                 color: Colors.pink.shade50,
//                 margin: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Month and Paid Status
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             "Month: ${month.month ?? "N/A"}",
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.pink.shade900,
//                             ),
//                           ),
//                           Chip(
//                             label: Text(
//                               month.paid == 1 ? "Paid" : "Unpaid",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             backgroundColor: month.paid == 1
//                                 ? Colors.green
//                                 : Colors.red,
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 10),
//
//                       // Start and End Dates
//                       Text(
//                         "Start Date: ${month.startDate?.toLocal().toString().split(' ')[0] ?? "N/A"}",
//                         style: TextStyle(fontSize: 14),
//                       ),
//                       Text(
//                         "End Date: ${month.endDate?.toLocal().toString().split(' ')[0] ?? "N/A"}",
//                         style: TextStyle(fontSize: 14),
//                       ),
//                       SizedBox(height: 10),
//
//                       // List of Dates
//                       if (month.dates != null && month.dates!.isNotEmpty)
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "Dates:",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.pink.shade700,
//                               ),
//                             ),
//                             SizedBox(height: 5),
//                             ...month.dates!.asMap().entries.map((entry) {
//                               int index = entry.key + 1;
//                               TutorDate date = entry.value;
//                               return Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                     vertical: 2.0),
//                                 child: Row(
//                                   children: [
//                                     Text(
//                                       "$index.",
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.pink.shade800,
//                                       ),
//                                     ),
//                                     SizedBox(width: 5),
//                                     Text(
//                                       "${date.day ?? "N/A"} (${date.date ?? "N/A"})",
//                                       style: TextStyle(fontSize: 14),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             }).toList(),
//                           ],
//                         )
//                       else
//                         Text(
//                           "No specific dates available",
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       SizedBox(height: 10),
//
//                       // Payment and Others Buttons
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               // Handle Payment action
//                               print("Payment for ${month.month}");
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.pink,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10.0),
//                               ),
//                             ),
//                             icon: Icon(Icons.payment, color: Colors.white),
//                             label: Text("Payment"),
//                           ),
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               // Handle Others action
//                               print("Others for ${month.month}");
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.pink.shade200,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10.0),
//                               ),
//                             ),
//                             icon: Icon(Icons.more_horiz, color: Colors.white),
//                             label: Text("Others"),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         )
//             : Center(
//           child: Text(
//             "No monthly schedules available",
//             style: TextStyle(color: Colors.grey),
//           ),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildMonthlySchedule() {
//   return Padding(
//     padding: const EdgeInsets.all(16.0),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Title
//         Text(
//           "Monthly Schedule",
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.pink,
//           ),
//         ),
//         SizedBox(height: 10),
//
//         // List of monthly schedules
//         tutorMonths.isNotEmpty
//             ? ListView.builder(
//           shrinkWrap: true,
//           physics: NeverScrollableScrollPhysics(),
//           itemCount: tutorMonths.length,
//           itemBuilder: (context, index) {
//             final month = tutorMonths[index];
//             return GestureDetector(
//               onTap: () {
//                 // Navigate to TutorStudentMonthlyDates page
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => TutorStudentMonthlyDates(
//                       student: widget.student,
//                       month: month,
//                     ),
//                   ),
//                 );
//               },
//               child: Card(
//                 elevation: 5,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15.0),
//                 ),
//                 color: Colors.pink.shade50,
//                 margin: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Month and Paid Status
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             "Month: ${month.month ?? "N/A"}",
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.pink.shade900,
//                             ),
//                           ),
//                           Chip(
//                             label: Text(
//                               month.paid == 1 ? "Paid" : "Unpaid",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             backgroundColor: month.paid == 1
//                                 ? Colors.green
//                                 : Colors.red,
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 10),
//
//                       // Start and End Dates
//                       Text(
//                         "Start Date: ${month.startDate?.toLocal().toString().split(' ')[0] ?? "N/A"}",
//                         style: TextStyle(fontSize: 14),
//                       ),
//                       Text(
//                         "End Date: ${month.endDate?.toLocal().toString().split(' ')[0] ?? "N/A"}",
//                         style: TextStyle(fontSize: 14),
//                       ),
//                       SizedBox(height: 10),
//
//                       // List of Dates
//                       if (month.dates != null && month.dates!.isNotEmpty)
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "Dates:",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.pink.shade700,
//                               ),
//                             ),
//                             SizedBox(height: 5),
//                             ...month.dates!.asMap().entries.map((entry) {
//                               int index = entry.key + 1;
//                               TutorDate date = entry.value;
//                               return Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                     vertical: 2.0),
//                                 child: Row(
//                                   children: [
//                                     Text(
//                                       "$index.",
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.pink.shade800,
//                                       ),
//                                     ),
//                                     SizedBox(width: 5),
//                                     Text(
//                                       "${date.day ?? "N/A"} (${date.date ?? "N/A"})",
//                                       style: TextStyle(fontSize: 14),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             }).toList(),
//                           ],
//                         )
//                       else
//                         Text(
//                           "No specific dates available",
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey,
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         )
//             : Center(
//           child: Text(
//             "No monthly schedules available",
//             style: TextStyle(color: Colors.grey),
//           ),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildMonthlySchedule() {
//   return Padding(
//     padding: const EdgeInsets.all(16.0),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Monthly Schedule",
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 10),
//         tutorMonths.isNotEmpty
//             ? ListView.builder(
//           shrinkWrap: true,
//           physics: NeverScrollableScrollPhysics(),
//           itemCount: tutorMonths.length,
//           itemBuilder: (context, index) {
//             final month = tutorMonths[index];
//             return GestureDetector(
//               onTap: () {
//                 // Navigate to TutorStudentMonthlyDates page with the selected month and student data
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => TutorStudentMonthlyDates(
//                       student: widget.student,  // Passing the student data
//                       month: month,              // Passing the selected month data
//                     ),
//                   ),
//                 );
//               },
//               child: Card(
//                 margin: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Month: ${month.month ?? "N/A"}",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(height: 5),
//                       Text(
//                         "Start Date: ${month.startDate?.toLocal().toString().split(' ')[0] ?? "N/A"}",
//                       ),
//                       Text(
//                         "End Date: ${month.endDate?.toLocal().toString().split(' ')[0] ?? "N/A"}",
//                       ),
//                       Text(
//                         "Paid: ${month.paid == 1 ? "Yes" : "No"}",
//                       ),
//                       if (month.dates != null && month.dates!.isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 8.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: month.dates!.map((date) {
//                               return Text(
//                                 "- ${date.day ?? "N/A"} (${date.date ?? "N/A"})",
//                                 style: TextStyle(fontSize: 14),
//                               );
//                             }).toList(),
//                           ),
//                         )
//                       else
//                         Text(
//                           "No specific dates available",
//                           style: TextStyle(color: Colors.grey),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         )
//             : Center(
//           child: Text(
//             "No monthly schedules available",
//             style: TextStyle(color: Colors.grey),
//           ),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildMonthlySchedule() {
//   return Padding(
//     padding: const EdgeInsets.all(16.0),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Monthly Schedule",
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 10),
//         tutorMonths.isNotEmpty
//             ? ListView.builder(
//           shrinkWrap: true,
//           physics: NeverScrollableScrollPhysics(),
//           itemCount: tutorMonths.length,
//           itemBuilder: (context, index) {
//             final month = tutorMonths[index];
//             return Card(
//               margin: const EdgeInsets.symmetric(vertical: 8.0),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Month: ${month.month ?? "N/A"}",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     SizedBox(height: 5),
//                     Text(
//                       "Start Date: ${month.startDate?.toLocal().toString().split(' ')[0] ?? "N/A"}",
//                     ),
//                     Text(
//                       "End Date: ${month.endDate?.toLocal().toString().split(' ')[0] ?? "N/A"}",
//                     ),
//                     Text(
//                       "Paid: ${month.paid == 1 ? "Yes" : "No"}",
//                     ),
//                     if (month.dates != null && month.dates!.isNotEmpty)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: month.dates!.map((date) {
//                             return Text(
//                               "- ${date.day ?? "N/A"} (${date.date ?? "N/A"})",
//                               style: TextStyle(fontSize: 14),
//                             );
//                           }).toList(),
//                         ),
//                       )
//                     else
//                       Text(
//                         "No specific dates available",
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         )
//             : Center(
//           child: Text(
//             "No monthly schedules available",
//             style: TextStyle(color: Colors.grey),
//           ),
//         ),
//       ],
//     ),
//   );
// }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileSection extends StatefulWidget {
  final TutorStudent student;

  const ProfileSection({Key? key, required this.student}) : super(key: key);

  @override
  _ProfileSectionState createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header (always visible)
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            color: Colors.blueAccent,
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                        widget.student.img ?? 'https://via.placeholder.com/150',
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      widget.student.name ?? "Unknown",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 20),
                    //   child: ElevatedButton(
                    //     onPressed: () => {},
                    //     style: ElevatedButton.styleFrom(
                    //       foregroundColor: Colors.white, // Text color
                    //       backgroundColor: Colors.pinkAccent, // Button color
                    //       padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(25), // Rounded edges
                    //       ),
                    //       elevation: 5, // Shadow effect
                    //     ),
                    //     child: Row(
                    //       mainAxisSize: MainAxisSize.min,
                    //       children: [
                    //         Icon(Icons.calendar_month, size: 20),
                    //         SizedBox(width: 10),
                    //         Text(
                    //           "Add Month",
                    //           style: TextStyle(
                    //               fontSize: 16, fontWeight: FontWeight.bold),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),

        // Expandable content
        if (_isExpanded)
          Column(
            children: [
              SizedBox(height: 10),
              Chip(
                label: Text(
                  widget.student.activeStatus == 1 ? "Active" : "Inactive",
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: widget.student.activeStatus == 1
                    ? Colors.green
                    : Colors.red,
              ),
              SizedBox(height: 20),

              // Personal Information
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoTile(
                      icon: Icons.phone,
                      label: "Phone",
                      value: widget.student.phone ?? "N/A",
                    ),
                    InfoTile(
                      icon: Icons.person,
                      label: "Guardian Phone",
                      value: widget.student.gaurdianPhone ?? "N/A",
                    ),
                    InfoTile(
                      icon: Icons.calendar_today,
                      label: "Date of Birth",
                      value: widget.student.dob ?? "N/A",
                    ),
                    InfoTile(
                      icon: Icons.school,
                      label: "Education",
                      value: widget.student.education ?? "N/A",
                    ),
                    InfoTile(
                      icon: Icons.home,
                      label: "Address",
                      value: widget.student.address ?? "N/A",
                    ),
                    InfoTile(
                      icon: Icons.date_range,
                      label: "Admitted Date",
                      value: widget.student.admittedDate
                          ?.toLocal()
                          .toString()
                          .split(' ')[0] ??
                          "N/A",
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
