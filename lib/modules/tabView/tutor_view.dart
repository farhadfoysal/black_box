import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:black_box/screen_page/tutor/tutor_student_month.dart';
import 'package:black_box/screen_page/tutor/tutor_student_monthly.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:black_box/model/tutor/tutor_week_day.dart';
import 'package:black_box/model/tutor/tutor_student.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../db/local/database_manager.dart';
import '../../model/school/school.dart';
import '../../model/school/teacher.dart';
import '../../model/user/user.dart';
import '../../preference/logout.dart';
import '../../routes/app_router.dart';
import '../../screen_page/tutor/tutor_student_profile.dart';
import '../../utility/unique.dart';

class TutorView extends StatefulWidget {
  @override
  _TutorViewState createState() => _TutorViewState();
}

class _TutorViewState extends State<TutorView> {
  List<TutorStudent> students = [];

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
    setState(() {
      isLoading = true;
    });
    _initializeData();
  }

  Future<void> _initializeData() async {
    // First load user data
    await _loadUserData();

    _loadTutorStudentsData();
  }

  Future<void> _loadTutorStudentsData() async {
    if (await InternetConnectionChecker.instance.hasConnection) {
      setState(() {
        isLoading = true;
      });

      DatabaseReference teachersRef = _databaseRef.child('tutor_student');

      Query query = teachersRef.orderByChild('user_id').equalTo(_user?.userid);

      query.once().then((DatabaseEvent event) {
        final dataSnapshot = event.snapshot;

        if (dataSnapshot.exists) {
          final Map<dynamic, dynamic> studentsData =
              dataSnapshot.value as Map<dynamic, dynamic>;

          setState(() {
            students.clear();

            students = studentsData.entries.map((entry) {
              // Convert each entry's value to Map<String, dynamic>
              final studentMap = Map<String, dynamic>.from(entry.value as Map);

              return TutorStudent.fromJson(studentMap);
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
          print('No Student data available for the current User.');
          setState(() {
            isLoading = false;
          });
        }
      }).catchError((error) {
        print('Failed to load Student data: $error');
        setState(() {
          isLoading = false;
        });
      });
    } else {

      List<TutorStudent> studentList = await DatabaseManager().getTutorStudentsDay();

      if(!studentList.isEmpty){
        setState(() {
          students.clear();
          students = studentList;
          isLoading = false;
        });
      }else{
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

  void _addStudent(BuildContext context) {
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
                                        saveStudent(student);
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      print('Could not launch phone call for $phoneNumber');
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      print('Could not launch WhatsApp for $phoneNumber');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content that can scroll
          Positioned.fill(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(), // Show loading indicator
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          SizedBox(height: 1),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: students.length,
                            itemBuilder: (context, index) {
                              final student = students[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TutorStudentMonth(student: student),
                                    ),
                                  );
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  elevation: 5,
                                  margin: const EdgeInsets.all(10),
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        Container(
                                          margin:
                                              const EdgeInsets.only(right: 14),
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                          ),
                                          child: student.img?.isNotEmpty == true
                                              ? ClipOval(
                                            child: Image.network(
                                              student.img!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                // Fallback to asset image if there's an error
                                                return Image.asset(
                                                  'assets/1.jpg',
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            ),
                                          )
                                              : ClipOval(
                                            child: Image.asset(
                                              'assets/1.jpg',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          // decoration: BoxDecoration(
                                          //   shape: BoxShape.circle,
                                          //   image: DecorationImage(
                                          //     fit: BoxFit.cover,
                                          //     image: student.img?.isNotEmpty == true
                                          //         ? NetworkImage(student.img!) // Load the network image
                                          //         : AssetImage('assets/1.jpg') as ImageProvider, // Fallback image
                                          //     onError: (exception, stackTrace) {
                                          //       // This won't work in DecorationImage; use a fallback widget or logic below
                                          //     },
                                          //   ),
                                          // ),
                                          // child: student.img?.isNotEmpty != true
                                          //     ? Icon(Icons.person, size: 50) // Placeholder icon for fallback
                                          //     : null, // Keep null if the image is valid
                                          // decoration: BoxDecoration(
                                          //   shape: BoxShape.circle,
                                          //   image: DecorationImage(
                                          //     fit: BoxFit.cover,
                                          //     image: student.img?.isNotEmpty == true
                                          //         ? NetworkImage(student.img!)
                                          //         : AssetImage('assets/1.jpg') as ImageProvider,
                                          //
                                          //     // image: NetworkImage(
                                          //     //     "https://gratisography.com/wp-content/uploads/2024/11/gratisography-augmented-reality-800x525.jpg"
                                          //     //     // items[index].img.toString(),
                                          //     //     ),
                                          //   ),
                                          // ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                student.name.toString(),
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 18),
                                                maxLines: 2,
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                student.phone.toString(),
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14),
                                                maxLines: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              // Implement edit logic
                                            } else if (value == 'call') {
                                              _makePhoneCall(student.phone??"");
                                            } else if (value == 'whatsapp') {
                                              _openWhatsApp(student.phone??"");
                                            } else if (value == 'delete') {
                                              setState(() {
                                                students.remove(
                                                    student); // Assuming `students` is your list
                                              });
                                            } else if (value == 'profile') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      TutorStudentProfile(
                                                          student: student),
                                                ),
                                              );
                                              setState(() {});
                                            } else if (value == 'go') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      TutorStudentMonthly(
                                                          student: student),
                                                ),
                                              );
                                              setState(() {});
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                                value: 'call',
                                                child: Text('Call')),
                                            const PopupMenuItem(
                                                value: 'whatsapp',
                                                child: Text('WhatsApp')),
                                            const PopupMenuItem(
                                                value: 'profile',
                                                child: Text('Profile')),
                                            const PopupMenuItem(
                                                value: 'go',
                                                child: Text('Attendance')),
                                            const PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit')),
                                            const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Delete')),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Positioned button at the bottom-right corner
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () => _addStudent(context),
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
                  Icon(Icons.person, size: 20),
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
                          "Add Student",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: Stack(
  //       children: [
  //         SingleChildScrollView(
  //           child: Padding(
  //             padding: const EdgeInsets.all(8.0),
  //             child: Column(
  //               children: [
  //                 // ElevatedButton(
  //                 //   onPressed: () => _addStudent(context),
  //                 //   style: ElevatedButton.styleFrom(
  //                 //     foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color
  //                 //     padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
  //                 //     shape: RoundedRectangleBorder(
  //                 //       borderRadius: BorderRadius.circular(25), // Rounded edges
  //                 //     ),
  //                 //     elevation: 5, // Shadow effect
  //                 //   ),
  //                 //   child: Row(
  //                 //     mainAxisSize: MainAxisSize.min,
  //                 //     children: [
  //                 //       Icon(Icons.person, size: 20),
  //                 //       SizedBox(width: 10),
  //                 //       Text(
  //                 //         "Click to Add Student",
  //                 //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //                 //       ),
  //                 //     ],
  //                 //   ),
  //                 // ),
  //                 SizedBox(height: 10),
  //                 ListView.builder(
  //                   shrinkWrap: true,
  //                   physics: NeverScrollableScrollPhysics(),
  //                   itemCount: students.length,
  //                   itemBuilder: (context, index) {
  //                     final student = students[index];
  //                     return Card(
  //                       margin: EdgeInsets.symmetric(vertical: 8),
  //                       child: ListTile(
  //                         title: Text(student.userId),
  //                         subtitle: Text('Phone: ${student.phone}'),
  //                         trailing: PopupMenuButton<String>(
  //                           onSelected: (value) {
  //                             if (value == 'edit') {
  //                               // Implement edit logic
  //                             } else if (value == 'delete') {
  //                               setState(() {
  //                                 students.removeAt(index);
  //                               });
  //                             }
  //                           },
  //                           itemBuilder: (context) => [
  //                             PopupMenuItem(value: 'edit', child: Text('Edit')),
  //                             PopupMenuItem(value: 'delete', child: Text('Delete')),
  //                           ],
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //
  //
  //         Positioned(
  //           bottom: 20,
  //           right: 20,
  //           child: ElevatedButton(
  //             onPressed: () => _addStudent(context),
  //             style: ElevatedButton.styleFrom(
  //               foregroundColor: Colors.white, // Text color
  //               backgroundColor: Colors.blue, // Button color
  //               padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(25), // Rounded edges
  //               ),
  //               elevation: 5, // Shadow effect
  //             ),
  //             child: Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Icon(Icons.person, size: 20),
  //                 SizedBox(width: 10),
  //                 Text(
  //                   "Click to Add Student",
  //                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //
  //       ],
  //     ),
  //   );
  // }

  Future<void> saveStudent(TutorStudent student) async {
    var uuid = Uuid();
    String uniqueId = Unique().generateUniqueID();
    int ranId =
        Random().nextInt(1000000000) + DateTime.now().millisecondsSinceEpoch;
    // String referr = String.fromCharCode(65 + Random().nextInt(26));
    // String referr = utf8.decode([Random().nextInt(256)]).toUpperCase();
    // String numberr = '$ranId$referr';

    student.uniqueId = uniqueId;
    student.userId = _user?.userid;

    if (await InternetConnectionChecker.instance.hasConnection) {
      final DatabaseReference dbRef = FirebaseDatabase.instance
          .ref("tutor_student")
          .child(student.uniqueId!);

      try {
        await dbRef.set(student.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student saved successfully!')),
        );

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        setState(() {
          students.add(student);
        });
        await setUserTutorStudentOnline(
            _user ?? _user_data, student, "student");
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const AdminLogin(),
        //   ),
        // );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Student: $e')),
        );
      }
    } else {
      final result = await DatabaseManager().insertTutorStudentDays(student);
      if (result > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student saved successfully!')),
        );

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        setState(() {
          students.add(student);
        });
        // context.push(Routes.messAdmin);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Student')),
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

  setUserTutorStudentOnline(User? user, TutorStudent student, String s) async {
    // int result = await DatabaseManager().insertTutorStudentDay(student);
    int result = await DatabaseManager().insertTutorStudentDays(student);

    if (mounted) {
      setState(() {});
    }

    if (result > 0) {
      if (mounted) {
        showSnackBarMsg(context, 'Registration Successful');

        Future.delayed(const Duration(seconds: 0), () {
          setState(() {
            isLoading = false;
          });
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        showSnackBarMsg(context, 'Registration Failed');
      }
    }
  }
}
