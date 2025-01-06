import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:black_box/screen_page/tutor/tutor_student_month.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class TutorStudentMonthlyDates extends StatefulWidget {
  final TutorStudent student;
  final TutorMonth month;

  TutorStudentMonthlyDates({required this.student, required this.month});

  @override
  State<TutorStudentMonthlyDates> createState() =>
      _TutorStudentMonthlyDatesState();
}

class _TutorStudentMonthlyDatesState extends State<TutorStudentMonthlyDates> {
  late Map<int, TextEditingController> _minutesControllers;

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
    _minutesControllers = {};
    for (var date in widget.month.dates ?? []) {
      _minutesControllers[date.id!] = TextEditingController(
        text: date.minutes != null ? date.minutes.toString() : "",
      );
    }

    _loadUserName();
    // _loadSampleData();
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

  Future<void> updateTutorMonthDates(TutorMonth month) async {
    setState(() {
      isLoading = true;
    });

    if (await InternetConnectionChecker.instance.hasConnection) {
      final DatabaseReference dbRef =
      FirebaseDatabase.instance.ref("tutor_month").child(month.uniqueId!);

      try {
        // Update the dates field in Firebase
        await dbRef.update({
          'dates': month.dates?.map((date) => date.toMap()).toList(),
        });

        updateOfflline(month);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tutor Month dates updated successfully!')),
        );

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

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

  Future<void> updateOfflline(TutorMonth month) async {
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

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update Tutor Month dates')),
      );
    }
  }

  @override
  void dispose() {
    _minutesControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }
  void _toggleAttendance(TutorDate date) {
    setState(() {
      date.attendance = date.attendance == 1 ? 0 : 1;
      if (date.attendance == 0) {
        date.minutes = 0;
      }
    });
  }

  void _setMinutes(TutorDate date, String minutes) {
    setState(() {
      date.minutes = int.tryParse(minutes) ?? 0;
    });
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
    );
  }

  Widget _buildMonthlySchedule() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Title
          Center(
            child: Text(
              "${widget.month.month}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade700,
              ),
            ),
          ),
          SizedBox(height: 10),

          // Dates List
          widget.month.dates!.isNotEmpty
              ? ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.month.dates?.length,
            itemBuilder: (context, index) {
              final date = widget.month.dates?[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                color: Colors.pink.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Date and Day Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${date?.date ?? "N/A"}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink.shade900,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "${date?.day ?? "N/A"}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),

                      // Round Button Column
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Toggle logic for the round button
                              if (date != null) {
                                setState(() {
                                  date.attendance =
                                  (date.attendance == 1) ? 0 : 1;
                                });
                              }
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: date?.attendance == 1
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              child: Icon(
                                Icons.event,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Spacer(),

                      // Attendance Status and Minutes Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Attendance Status
                          GestureDetector(
                            onTap: () => _toggleAttendance(date!),
                            child: Text(
                              "${date?.attendance == 1 ? 'Present' : 'Absent'}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: date?.attendance == 1
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),

                          // Minutes Input
                          if (date?.attendance == 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(width: 8),
                                // Container(
                                //   width: 60,
                                //   child: TextField(
                                //     keyboardType: TextInputType.number,
                                //     decoration: InputDecoration(
                                //       hintText: "Minutes",
                                //       hintStyle: TextStyle(fontSize: 12),
                                //       contentPadding:
                                //       EdgeInsets.symmetric(
                                //           vertical: 0,
                                //           horizontal: 8.0),
                                //       border: OutlineInputBorder(
                                //         borderRadius:
                                //         BorderRadius.circular(10.0),
                                //       ),
                                //     ),
                                //     onChanged: (value) {
                                //       _setMinutes(date, value);
                                //     },
                                //     controller: TextEditingController(
                                //         text: date!.minutes! > 0
                                //             ? date.minutes.toString()
                                //             : ""),
                                //   ),
                                // ),
                                Container(
                                  width: 70,
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly, // Restrict to numbers only
                                      LengthLimitingTextInputFormatter(3), // Limit to 3 digits
                                    ],
                                    decoration: InputDecoration(
                                      hintText: "Minutes",
                                      hintStyle: TextStyle(fontSize: 12),
                                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8.0),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      _setMinutes(date!, value);
                                    },
                                    controller: _minutesControllers[date?.id!] ?? TextEditingController(),
                                  ),
                                ),

                              ],
                            )
                          else
                            Text(
                              "Minutes: N/A",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          )
              : Center(
            child: Text(
              "No dates available for this month",
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
  //         // Month Title
  //         Center(
  //           child: Text(
  //             "${widget.month.month}",
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.bold,
  //               color: Colors.pink.shade700,
  //             ),
  //           ),
  //         ),
  //         SizedBox(height: 10),
  //
  //         // Dates List
  //         widget.month.dates!.isNotEmpty
  //             ? ListView.builder(
  //           shrinkWrap: true,
  //           physics: NeverScrollableScrollPhysics(),
  //           itemCount: widget.month.dates?.length,
  //           itemBuilder: (context, index) {
  //             final date = widget.month.dates?[index];
  //             return Card(
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(15.0),
  //               ),
  //               elevation: 5,
  //               margin: const EdgeInsets.symmetric(vertical: 8.0),
  //               color: Colors.pink.shade50,
  //               child: Padding(
  //                 padding: const EdgeInsets.all(16.0),
  //                 child: Row(
  //                   crossAxisAlignment: CrossAxisAlignment.center,
  //                   children: [
  //                     // Date and Day Column
  //                     Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           "${date?.date ?? "N/A"}",
  //                           style: TextStyle(
  //                             fontSize: 16,
  //                             fontWeight: FontWeight.bold,
  //                             color: Colors.pink.shade900,
  //                           ),
  //                         ),
  //                         SizedBox(height: 5),
  //                         Text(
  //                           "${date?.day ?? "N/A"}",
  //                           style: TextStyle(
  //                             fontSize: 14,
  //                             color: Colors.grey.shade700,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     Spacer(),
  //
  //                     // Round Button Column
  //                     Column(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         GestureDetector(
  //                           onTap: () {
  //                             // Add logic for the button tap
  //                           },
  //                           child: Container(
  //                             width: 50,
  //                             height: 50,
  //                             decoration: BoxDecoration(
  //                               shape: BoxShape.circle,
  //                               color: Colors.pink.shade300,
  //                             ),
  //                             child: Icon(
  //                               Icons.event,
  //                               color: Colors.white,
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     Spacer(),
  //
  //                     // Attendance Status and Minutes Section
  //                     Column(
  //                       crossAxisAlignment: CrossAxisAlignment.end,
  //                       children: [
  //                         // Attendance Status
  //                         GestureDetector(
  //                           onTap: () => _toggleAttendance(date!),
  //                           child: Text(
  //                             "${date?.attendance == 1 ? 'Present' : 'Absent'}",
  //                             style: TextStyle(
  //                               fontSize: 14,
  //                               fontWeight: FontWeight.bold,
  //                               color: date?.attendance == 1
  //                                   ? Colors.green
  //                                   : Colors.red,
  //                             ),
  //                           ),
  //                         ),
  //                         SizedBox(height: 10),
  //
  //                         // Minutes Input
  //                         if (date?.attendance == 1)
  //                           Row(
  //                             mainAxisAlignment: MainAxisAlignment.end,
  //                             children: [
  //                               Text(
  //                                 "Mins:",
  //                                 style: TextStyle(
  //                                   fontSize: 14,
  //                                   color: Colors.grey.shade700,
  //                                 ),
  //                               ),
  //                               SizedBox(width: 8),
  //                               Container(
  //                                 width: 60,
  //                                 child: TextField(
  //                                   keyboardType: TextInputType.number,
  //                                   decoration: InputDecoration(
  //                                     hintText: "Mins",
  //                                     hintStyle: TextStyle(fontSize: 12),
  //                                     contentPadding:
  //                                     EdgeInsets.symmetric(
  //                                         vertical: 0,
  //                                         horizontal: 8.0),
  //                                     border: OutlineInputBorder(
  //                                       borderRadius:
  //                                       BorderRadius.circular(10.0),
  //                                     ),
  //                                   ),
  //                                   onChanged: (value) {
  //                                     _setMinutes(date, value);
  //                                   },
  //                                   controller: TextEditingController(
  //                                       text: date!.minutes! > 0
  //                                           ? date.minutes.toString()
  //                                           : ""),
  //                                 ),
  //                               ),
  //                             ],
  //                           )
  //                         else
  //                           Text(
  //                             "Mins: N/A",
  //                             style: TextStyle(
  //                               fontSize: 14,
  //                               color: Colors.grey.shade700,
  //                             ),
  //                           ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         )
  //             : Center(
  //           child: Text(
  //             "No dates available for this month",
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
  //         // Month Title
  //         Center(
  //           child: Text(
  //             "${widget.month.month}",
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.bold,
  //               color: Colors.pink.shade700,
  //             ),
  //           ),
  //         ),
  //         SizedBox(height: 10),
  //
  //         // Dates List
  //         widget.month.dates!.isNotEmpty
  //             ? ListView.builder(
  //           shrinkWrap: true,
  //           physics: NeverScrollableScrollPhysics(),
  //           itemCount: widget.month.dates?.length,
  //           itemBuilder: (context, index) {
  //             final date = widget.month.dates?[index];
  //             return Card(
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(15.0),
  //               ),
  //               elevation: 5,
  //               margin: const EdgeInsets.symmetric(vertical: 8.0),
  //               color: Colors.pink.shade50,
  //               child: Padding(
  //                 padding: const EdgeInsets.symmetric(
  //                     vertical: 16.0, horizontal: 12.0),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     // Date and Day
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             Text(
  //                               "${date?.date ?? "N/A"}",
  //                               style: TextStyle(
  //                                 fontSize: 16,
  //                                 fontWeight: FontWeight.bold,
  //                                 color: Colors.pink.shade900,
  //                               ),
  //                             ),
  //                             SizedBox(height: 5),
  //                             Text(
  //                               "${date?.day ?? "N/A"}",
  //                               style: TextStyle(
  //                                 fontSize: 14,
  //                                 color: Colors.grey.shade700,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                         // Absent/Present Status
  //                         Text(
  //                           date?.attendance == 1 ? "Present" : "Absent",
  //                           style: TextStyle(
  //                             fontSize: 14,
  //                             fontWeight: FontWeight.bold,
  //                             color: date?.attendance == 1
  //                                 ? Colors.green
  //                                 : Colors.red,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     SizedBox(height: 16),
  //
  //                     // Attendance Button in the Middle
  //                     Center(
  //                       child: ElevatedButton(
  //                         onPressed: () {
  //                           // Toggle attendance between Present and Absent
  //                           _toggleAttendance(date!);
  //                         },
  //                         style: ElevatedButton.styleFrom(
  //                           shape: CircleBorder(),
  //                           padding: EdgeInsets.all(20.0),
  //                           backgroundColor: date?.attendance == 1
  //                               ? Colors.green
  //                               : Colors.red,
  //                         ),
  //                         child: Text(
  //                           date?.attendance == 1 ? "P" : "A",
  //                           style: TextStyle(
  //                             fontSize: 18,
  //                             fontWeight: FontWeight.bold,
  //                             color: Colors.white,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                     SizedBox(height: 10),
  //
  //                     // Minutes Section
  //                     if (date?.attendance == 1)
  //                       Row(
  //                         children: [
  //                           Text(
  //                             "Mins:",
  //                             style: TextStyle(
  //                               fontSize: 14,
  //                               color: Colors.grey.shade700,
  //                             ),
  //                           ),
  //                           SizedBox(width: 8),
  //                           Container(
  //                             width: 60,
  //                             child: TextField(
  //                               keyboardType: TextInputType.number,
  //                               decoration: InputDecoration(
  //                                 hintText: "Mins",
  //                                 hintStyle: TextStyle(fontSize: 12),
  //                                 contentPadding: EdgeInsets.symmetric(
  //                                     vertical: 0, horizontal: 8.0),
  //                                 border: OutlineInputBorder(
  //                                   borderRadius:
  //                                   BorderRadius.circular(10.0),
  //                                 ),
  //                               ),
  //                               onChanged: (value) {
  //                                 _setMinutes(date, value);
  //                               },
  //                               controller: TextEditingController(
  //                                   text: date!.minutes! > 0
  //                                       ? date.minutes.toString()
  //                                       : ""),
  //                             ),
  //                           ),
  //                         ],
  //                       )
  //                     else
  //                       Text(
  //                         "Mins: N/A",
  //                         style: TextStyle(
  //                           fontSize: 14,
  //                           color: Colors.grey.shade700,
  //                         ),
  //                       ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         )
  //             : Center(
  //           child: Text(
  //             "No dates available for this month",
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
  //         // Month Title
  //         Center(
  //           child: Text(
  //             "${widget.month.month}",
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.bold,
  //               color: Colors.pink.shade700,
  //             ),
  //           ),
  //         ),
  //         SizedBox(height: 10),
  //
  //         // Dates List
  //         widget.month.dates!.isNotEmpty
  //             ? ListView.builder(
  //           shrinkWrap: true,
  //           physics: NeverScrollableScrollPhysics(),
  //           itemCount: widget.month.dates?.length,
  //           itemBuilder: (context, index) {
  //             final date = widget.month.dates?[index];
  //             return Card(
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(15.0),
  //               ),
  //               elevation: 5,
  //               margin: const EdgeInsets.symmetric(vertical: 8.0),
  //               color: Colors.pink.shade50,
  //               child: Padding(
  //                 padding: const EdgeInsets.symmetric(
  //                     vertical: 16.0, horizontal: 12.0),
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     // Date and Day Column
  //                     Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           "${date?.date ?? "N/A"}",
  //                           style: TextStyle(
  //                             fontSize: 16,
  //                             fontWeight: FontWeight.bold,
  //                             color: Colors.pink.shade900,
  //                           ),
  //                         ),
  //                         SizedBox(height: 5),
  //                         Text(
  //                           "${date?.day ?? "N/A"}",
  //                           style: TextStyle(
  //                             fontSize: 14,
  //                             color: Colors.grey.shade700,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //
  //                     // Attendance Button
  //                     Column(
  //                       children: [
  //                         ElevatedButton(
  //                           onPressed: () {
  //                             // Toggle attendance between Present and Absent
  //                             _toggleAttendance(date!);
  //                           },
  //                           style: ElevatedButton.styleFrom(
  //                             shape: CircleBorder(),
  //                             padding: EdgeInsets.all(16.0),
  //                             backgroundColor: date?.attendance == 1
  //                                 ? Colors.green
  //                                 : Colors.red,
  //                           ),
  //                           child: Text(
  //                             date?.attendance == 1 ? "P" : "A",
  //                             style: TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.bold,
  //                               color: Colors.white,
  //                             ),
  //                           ),
  //                         ),
  //                         SizedBox(height: 10),
  //
  //                         // Minutes Section
  //                         if (date?.attendance == 1)
  //                           Row(
  //                             children: [
  //                               Text(
  //                                 "Mins:",
  //                                 style: TextStyle(
  //                                   fontSize: 14,
  //                                   color: Colors.grey.shade700,
  //                                 ),
  //                               ),
  //                               SizedBox(width: 8),
  //                               Container(
  //                                 width: 60,
  //                                 child: TextField(
  //                                   keyboardType: TextInputType.number,
  //                                   decoration: InputDecoration(
  //                                     hintText: "Mins",
  //                                     hintStyle: TextStyle(fontSize: 12),
  //                                     contentPadding:
  //                                     EdgeInsets.symmetric(
  //                                         vertical: 0,
  //                                         horizontal: 8.0),
  //                                     border: OutlineInputBorder(
  //                                       borderRadius:
  //                                       BorderRadius.circular(10.0),
  //                                     ),
  //                                   ),
  //                                   onChanged: (value) {
  //                                     _setMinutes(date, value);
  //                                   },
  //                                   controller: TextEditingController(
  //                                       text: date!.minutes! > 0
  //                                           ? date.minutes.toString()
  //                                           : ""),
  //                                 ),
  //                               ),
  //                             ],
  //                           )
  //                         else
  //                           Text(
  //                             "Mins: N/A",
  //                             style: TextStyle(
  //                               fontSize: 14,
  //                               color: Colors.grey.shade700,
  //                             ),
  //                           ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         )
  //             : Center(
  //           child: Text(
  //             "No dates available for this month",
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
  //         Center(
  //           child: Text(
  //             "${widget.month.month}",
  //             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //           ),
  //         ),
  //         SizedBox(height: 10),
  //         widget.month.dates!.isNotEmpty
  //             ? ListView.builder(
  //           shrinkWrap: true,
  //           physics: NeverScrollableScrollPhysics(),
  //           itemCount: widget.month.dates?.length,
  //           itemBuilder: (context, index) {
  //             final date = widget.month.dates?[index];
  //             return Card(
  //               margin: const EdgeInsets.symmetric(vertical: 8.0),
  //               child: Padding(
  //                 padding: const EdgeInsets.all(16.0),
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           "${date?.date ?? "N/A"}",
  //                           style: TextStyle(fontSize: 14),
  //                         ),
  //                         SizedBox(height: 5),
  //                         Text(
  //                           "${date?.day ?? "N/A"}",
  //                           style: TextStyle(fontSize: 14),
  //                         ),
  //                       ],
  //                     ),
  //                     Column(
  //                       crossAxisAlignment: CrossAxisAlignment.end,
  //                       children: [
  //                         GestureDetector(
  //                           onTap: () => _toggleAttendance(date!),
  //                           child: Text(
  //                             "${date?.attendance == 1 ? 'Present' : 'Absent'}",
  //                             style: TextStyle(
  //                                 fontSize: 14,
  //                                 color: date?.attendance == 1
  //                                     ? Colors.green
  //                                     : Colors.red),
  //                           ),
  //                         ),
  //                         SizedBox(height: 5),
  //                         if (date?.attendance == 1)
  //                           Row(
  //                             children: [
  //                               Text(
  //                                 "Mins: ",
  //                                 style: TextStyle(
  //                                     fontSize: 14,
  //                                     color: Colors.grey[700]),
  //                               ),
  //                               SizedBox(width: 8),
  //                               Container(
  //                                 width: 50,
  //                                 child: TextField(
  //                                   keyboardType: TextInputType.number,
  //                                   decoration: InputDecoration(
  //                                     hintText: "Mins",
  //                                     hintStyle: TextStyle(fontSize: 12),
  //                                   ),
  //                                   onChanged: (value) {
  //                                     _setMinutes(date, value);
  //                                   },
  //                                   controller: TextEditingController(
  //                                       text: date!.minutes! > 0
  //                                           ? date.minutes.toString()
  //                                           : ""),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         if (date?.attendance == 0)
  //                           Text(
  //                             "Mins: N/A",
  //                             style: TextStyle(
  //                                 fontSize: 14, color: Colors.grey[700]),
  //                           ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         )
  //             : Center(
  //           child: Text(
  //             "No dates available for this month",
  //             style: TextStyle(color: Colors.grey),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.month.month}"),
        backgroundColor: Colors.blueAccent,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: (){
                updateTutorMonthDates(widget.month);
              },
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
                    "Save Please",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // _buildProfileSection(),
            ProfileSection(student: widget.student),


            Divider(thickness: 1.5),

            // Monthly Schedule Section
            _buildMonthlySchedule(),
          ],
        ),
      ),
    );
  }
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



// import 'package:flutter/material.dart';
//
// import '../../model/tutor/tutor_month.dart';
// import '../../model/tutor/tutor_student.dart';
// import '../../model/tutor/tutor_date.dart';
//
// class TutorStudentMonthlyDates extends StatefulWidget {
//   final TutorStudent student;
//   final TutorMonth month;
//
//   TutorStudentMonthlyDates({required this.student, required this.month});
//
//   @override
//   State<TutorStudentMonthlyDates> createState() =>
//       _TutorStudentMonthlyDatesState();
// }
//
// class _TutorStudentMonthlyDatesState extends State<TutorStudentMonthlyDates> {
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   Widget _buildProfileSection() {
//     return Column(
//       children: [
//         // Profile Picture and Name
//         Stack(
//           alignment: Alignment.bottomCenter,
//           children: [
//             Container(
//               height: 200,
//               color: Colors.blueAccent,
//             ),
//             CircleAvatar(
//               radius: 60,
//               backgroundImage: NetworkImage(
//                 widget.student.img ?? 'https://via.placeholder.com/150',
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: 20),
//
//         // Name and Status
//         Text(
//           widget.student.name ?? "Unknown",
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 10),
//         Chip(
//           label: Text(
//             widget.student.activeStatus == 1 ? "Active" : "Inactive",
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: widget.student.activeStatus == 1
//               ? Colors.green
//               : Colors.red,
//         ),
//         SizedBox(height: 20),
//
//         // Personal Information
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               InfoTile(
//                 icon: Icons.phone,
//                 label: "Phone",
//                 value: widget.student.phone ?? "N/A",
//               ),
//               InfoTile(
//                 icon: Icons.person,
//                 label: "Guardian Phone",
//                 value: widget.student.gaurdianPhone ?? "N/A",
//               ),
//               InfoTile(
//                 icon: Icons.calendar_today,
//                 label: "Date of Birth",
//                 value: widget.student.dob ?? "N/A",
//               ),
//               InfoTile(
//                 icon: Icons.school,
//                 label: "Education",
//                 value: widget.student.education ?? "N/A",
//               ),
//               InfoTile(
//                 icon: Icons.home,
//                 label: "Address",
//                 value: widget.student.address ?? "N/A",
//               ),
//               InfoTile(
//                 icon: Icons.date_range,
//                 label: "Admitted Date",
//                 value: widget.student.admittedDate
//                     ?.toLocal()
//                     .toString()
//                     .split(' ')[0] ??
//                     "N/A",
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildMonthlySchedule() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Monthly Schedule",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 10),
//           widget.month.dates!.isNotEmpty
//               ? ListView.builder(
//             shrinkWrap: true,
//             physics: NeverScrollableScrollPhysics(),
//             itemCount: widget.month.dates?.length,
//             itemBuilder: (context, index) {
//               final date = widget.month.dates?[index];
//               return Card(
//                 margin: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Date: ${date?.date ?? "N/A"}",
//                             style: TextStyle(fontSize: 14),
//                           ),
//                           SizedBox(height: 5),
//                           Text(
//                             "Day: ${date?.day ?? "N/A"}",
//                             style: TextStyle(fontSize: 14),
//                           ),
//                         ],
//                       ),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Text(
//                             "Attendance: ${date?.attendance == 1 ? 'Present' : 'Absent'}",
//                             style: TextStyle(
//                                 fontSize: 14,
//                                 color: date?.attendance == 1
//                                     ? Colors.green
//                                     : Colors.red),
//                           ),
//                           SizedBox(height: 5),
//                           Text(
//                             "Attended Time: ${date?.attendance == 1 ? '${date?.minutes} min' : 'N/A'}",
//                             style: TextStyle(
//                                 fontSize: 14, color: Colors.grey[700]),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           )
//               : Center(
//             child: Text(
//               "No dates available for this month",
//               style: TextStyle(color: Colors.grey),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("${widget.student.name}'s Profile"),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             // Profile Section
//             _buildProfileSection(),
//
//             Divider(thickness: 1.5),
//
//             // Monthly Schedule Section
//             _buildMonthlySchedule(),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class InfoTile extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//
//   InfoTile({required this.icon, required this.label, required this.value});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.blueAccent),
//           SizedBox(width: 15),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//                 SizedBox(height: 5),
//                 Text(
//                   value,
//                   style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
