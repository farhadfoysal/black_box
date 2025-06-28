import 'dart:async';
import 'dart:convert';

import 'package:black_box/model/schedule/class_routine.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../preference/logout.dart';
import '../../../utility/unique.dart';
import '../../../web/internet_connectivity.dart';
import '../../model/schedule/schedule_item.dart';
import '../../model/school/school.dart';
import '../../model/user/user.dart';

class AddClassBottomSheet extends StatefulWidget {
  final void Function(ClassRoutine) onAddClass;

  AddClassBottomSheet({super.key, required this.onAddClass});

  @override
  State<AddClassBottomSheet> createState() => _AddClassBottomSheetState();
}

class _AddClassBottomSheetState extends State<AddClassBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final _courseNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _teacherController = TextEditingController();
  final _sectionController = TextEditingController();
  final _starttimeController = TextEditingController();
  final _endingtimeController = TextEditingController();
  final _classroomController = TextEditingController();
  final _majorController = TextEditingController();
  final _shiftController = TextEditingController();

  String selectedDay = 'Everyday';
  bool isConnected = false;

  final internetChecker = InternetConnectivity();
  StreamSubscription<InternetConnectionStatus>? connectionSubscription;

  final List<String> _majors = [
    'CSE', // Computer Science & Engineering
    'EEE', // Electrical & Electronic Engineering
    'ECE', // Electrical & Communication Engineering
    'ETE', // Electronics & Telecommunication Engineering
    'BBA', // Civil Engineering
    'HUM', // Civil Engineering
    'ME', // Mechanical Engineering
    'IPE', // Industrial & Production Engineering
    'ARCH', // Architecture
    'URP', // Urban & Regional Planning
    'Pharmacy',
    'Microbiology',
    'Biotechnology',
    'Genetic Engineering',
    'Physics',
    'Chemistry',
    'Mathematics',
    'Statistics',
    'Environmental Science',
    'Bangla',
    'English',
    'Economics',
    'Sociology',
    'Political Science',
    'Public Administration',
    'History',
    'Islamic Studies',
    'Islamic History & Culture',
    'Law',
    'Business Administration (BBA)',
    'Accounting',
    'Finance',
    'Marketing',
    'Management',
    'Tourism & Hospitality Management',
    'Journalism & Media Studies',
    'Anthropology',
    'Psychology',
    'Social Work',
    'Education',
    'Physical Education & Sports Science',
    'Food Engineering',
    'Textile Engineering',
    'Leather Engineering',
    'Fisheries',
    'Veterinary Science',
    'Agricultural Science',
    'Nutrition & Food Science',
  ];

  final List<String> _shifts = ['Day', 'Evening'];

  @override
  void initState() {
    super.initState();
    checkConnection();
    startListening();
  }

  void checkConnection() async {
    bool result = await internetChecker.hasInternetConnection();
    setState(() {
      isConnected = result;
    });
  }

  StreamSubscription<InternetConnectionStatus> checkConnectionContinuously() {
    return InternetConnectionChecker.instance.onStatusChange.listen((InternetConnectionStatus status) {
      setState(() {
        isConnected = status == InternetConnectionStatus.connected;
      });
    });
  }

  void startListening() {
    connectionSubscription = checkConnectionContinuously();
  }

  void stopListening() {
    connectionSubscription?.cancel();
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }

  void _submitForm(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final routine = ClassRoutine(
      day: selectedDay,
      startTime: _starttimeController.text,
      endTime: _endingtimeController.text,
      major: _majorController.text,
      courseCode: _courseCodeController.text,
      teacher: _teacherController.text,
      room: _classroomController.text,
      section: _sectionController.text,
      shift: _shiftController.text,
    );

    widget.onAddClass(routine);
    Navigator.pop(context);

    _courseNameController.clear();
    _courseCodeController.clear();
    _teacherController.clear();
    _sectionController.clear();
    _starttimeController.clear();
    _endingtimeController.clear();
    _classroomController.clear();
    _majorController.clear();
    _shiftController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Add Your Class",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 20),

              _buildDropdownField("Day of the Week", selectedDay, (value) {
                setState(() {
                  selectedDay = value!;
                });
              }),

              const SizedBox(height: 12),
              _buildTextField(_courseCodeController, "Course Code"),
              const SizedBox(height: 12),
              _buildTextField(_teacherController, "Teacher Initial"),
              const SizedBox(height: 12),
              _buildTextField(_sectionController, "Section"),
              const SizedBox(height: 12),
              _buildTimeField(context, _starttimeController, "Start Time"),
              const SizedBox(height: 12),
              _buildTimeField(context, _endingtimeController, "End Time"),
              const SizedBox(height: 12),
              _buildTextField(_classroomController, "Classroom"),
              const SizedBox(height: 12),
              // _buildTextField(_majorController, "Major"),
              // const SizedBox(height: 12),
              // _buildTextField(_shiftController, "Shift"),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_majorController, "Major"),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.arrow_drop_down),
                    onSelected: (value) {
                      setState(() {
                        _majorController.text = value;
                      });
                    },
                    itemBuilder: (context) => _majors.map((major) {
                      return PopupMenuItem(
                        value: major,
                        child: Text(major),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_shiftController, "Shift"),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.arrow_drop_down),
                    onSelected: (value) {
                      setState(() {
                        _shiftController.text = value;
                      });
                    },
                    itemBuilder: (context) => _shifts.map((shift) {
                      return PopupMenuItem(
                        value: shift,
                        child: Text(shift),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF005F73),
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _submitForm(context),
                icon: Icon(Icons.add),
                label: Text('Add Class', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String currentValue, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: [
        'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Everyday'
      ].map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
    );
  }

  Widget _buildTimeField(BuildContext context, TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectTime(context, controller),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(Icons.access_time),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Please select $label' : null,
    );
  }


  // @override
  // Widget build(BuildContext context) {
  //   return Container(
  //     padding: EdgeInsets.only(
  //       bottom: MediaQuery.of(context).viewInsets.bottom,
  //       left: 16,
  //       right: 16,
  //       top: 16,
  //     ),
  //     child: Form(
  //       key: _formKey,
  //       child: SingleChildScrollView(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Text("Add Your Class", style: Theme.of(context).textTheme.titleLarge),
  //             const SizedBox(height: 8),
  //             DropdownButtonFormField<String>(
  //               value: selectedDay,
  //               items: [
  //                 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Everyday'
  //               ].map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
  //               onChanged: (value) {
  //                 setState(() {
  //                   selectedDay = value!;
  //                 });
  //               },
  //             ),
  //             const SizedBox(height: 8),
  //             // TextFormField(
  //             //   controller: _courseNameController,
  //             //   decoration: const InputDecoration(labelText: 'Course Name'),
  //             //   validator: (value) => value == null || value.isEmpty ? 'Please enter a course name' : null,
  //             // ),
  //             // const SizedBox(height: 8),
  //             TextFormField(
  //               controller: _courseCodeController,
  //               decoration: const InputDecoration(labelText: 'Course Code'),
  //               validator: (value) => value == null || value.isEmpty ? 'Please enter a course code' : null,
  //             ),
  //             const SizedBox(height: 8),
  //             TextFormField(
  //               controller: _teacherController,
  //               decoration: const InputDecoration(labelText: 'Teacher Initial'),
  //               validator: (value) => value == null || value.isEmpty ? 'Please enter the teacher\'s initials' : null,
  //             ),
  //             const SizedBox(height: 8),
  //             TextFormField(
  //               controller: _sectionController,
  //               decoration: const InputDecoration(labelText: 'Section'),
  //               validator: (value) => value == null || value.isEmpty ? 'Please enter the section' : null,
  //             ),
  //             const SizedBox(height: 8),
  //             TextFormField(
  //               controller: _starttimeController,
  //               readOnly: true,
  //               onTap: () => _selectTime(context, _starttimeController),
  //               decoration: const InputDecoration(labelText: 'Start Time'),
  //               validator: (value) => value == null || value.isEmpty ? 'Please select the start time' : null,
  //             ),
  //             const SizedBox(height: 8),
  //             TextFormField(
  //               controller: _endingtimeController,
  //               readOnly: true,
  //               onTap: () => _selectTime(context, _endingtimeController),
  //               decoration: const InputDecoration(labelText: 'Ending Time'),
  //               validator: (value) => value == null || value.isEmpty ? 'Please select the end time' : null,
  //             ),
  //             const SizedBox(height: 8),
  //             TextFormField(
  //               controller: _classroomController,
  //               decoration: const InputDecoration(labelText: 'Classroom'),
  //               validator: (value) => value == null || value.isEmpty ? 'Please enter the classroom' : null,
  //             ),
  //             const SizedBox(height: 8),
  //             TextFormField(
  //               controller: _majorController,
  //               decoration: const InputDecoration(labelText: 'Major'),
  //               validator: (value) => value == null || value.isEmpty ? 'Please enter the major' : null,
  //             ),
  //             const SizedBox(height: 8),
  //             TextFormField(
  //               controller: _shiftController,
  //               decoration: const InputDecoration(labelText: 'Shift'),
  //               validator: (value) => value == null || value.isEmpty ? 'Please enter the shift' : null,
  //             ),
  //             const SizedBox(height: 20),
  //             ElevatedButton(
  //               onPressed: () => _submitForm(context),
  //               child: const Text('Add Class'),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _teacherController.dispose();
    _sectionController.dispose();
    _starttimeController.dispose();
    _endingtimeController.dispose();
    _classroomController.dispose();
    _majorController.dispose();
    _shiftController.dispose();
    stopListening();
    super.dispose();
  }
}
