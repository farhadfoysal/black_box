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

class TutorStudentPayment extends StatefulWidget {
  final TutorStudent student;
  final TutorMonth month;

  TutorStudentPayment({required this.student, required this.month});

  @override
  State<TutorStudentPayment> createState() =>
      _TutorStudentPaymentState();
}

class _TutorStudentPaymentState extends State<TutorStudentPayment> {
  late Map<int, TextEditingController> _minutesControllers;
  late TextEditingController _paymentAmountController;
  late TextEditingController _paidAmountController;

  double? payTk;
  double? paidTk;
  double? balance;

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


    _paymentAmountController = TextEditingController(
      text: widget.month.payTk == null
          ? '0'
          : (double.tryParse(widget.month.payTk ?? "0")! - double.tryParse(widget.month.paidTk ?? "0")!).toStringAsFixed(2),
    );


    // Set initial values for payTk and paidTk
    payTk = double.tryParse(widget.month.payTk ?? "0");
    paidTk = double.tryParse(widget.month.paidTk ?? "0");

    _updateBalance();

    _paidAmountController = TextEditingController();



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

  Future<void> updateTutorMonth(TutorMonth month) async {
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

  // Method to calculate balance
  void _updateBalance() {
    if (payTk != null && paidTk != null) {
      setState(() {
        balance = payTk! - paidTk!;
      });
    }
  }

  // Submit payment method to update month data
  Future<void> _submitPayment() async {
    // Update payTk and paidTk fields
    setState(() {
      payTk = double.tryParse(_paymentAmountController.text) ?? 0;
      paidTk = double.tryParse(_paidAmountController.text) ?? 0;
      widget.month.payTk = payTk?.toString();
      widget.month.paidTk = paidTk?.toString();
    });

    // Update the tutor month data
    await updateMonth(widget.month);
  }

  // Update TutorMonth data
  Future<void> updateMonth(TutorMonth month) async {

    final dbRef = FirebaseDatabase.instance.ref('tutor_month').child(month.uniqueId!);
    await dbRef.update({
      'pay_tk': month.payTk,
      'paid_tk': month.paidTk,
    });

    final result = await DatabaseManager().updateTutorStudentMonth(month);
    if (result > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment details updated successfully!')),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update Tutor Month')),
      );
    }

  }

  Widget _buildPayment() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display the total payment amount
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Total Payment: ${widget.month.payTk} TK",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),

          // Payment Form: Section to allow adding payment details
          SizedBox(height: 20),
          Text(
            "Add Payment",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          TextField(
            controller: _paymentAmountController,
            decoration: InputDecoration(
              labelText: "Payment Amount(Only First Time)",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _updateBalance();
            },
          ),
          SizedBox(height: 10),
          TextField(
            controller: _paidAmountController,
            decoration: InputDecoration(
              labelText: "Paid Amount",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _updateBalance();
            },
          ),
          SizedBox(height: 10),

          // Display balance
          Text(
            "Balance: ${balance ?? 0} TK",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),

          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitPayment,
            child: Text("Submit Payment"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }

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
                updateTutorMonth(widget.month);
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
            _buildPayment(),
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