import 'dart:convert';
import 'dart:io';

import 'package:black_box/model/school/class_model.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../db/local/db_manager.dart';
import '../../model/mess/mess_main.dart';
import '../../model/mess/mess_user.dart';
import '../../model/schedule/class_routine.dart';
import '../../model/schedule/schedule_item.dart';
import '../../model/school/school.dart';
import '../../model/school/teacher.dart';
import '../../model/user/user.dart';
import '../../preference/logout.dart';
import '../../utility/unique.dart';
import 'add_class_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class RoutinePage extends StatefulWidget {
  @override
  _RoutineScreenState createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutinePage> with SingleTickerProviderStateMixin {

  // final _auth = FirebaseAuth.instance;
  final _databaseRef = FirebaseDatabase.instance.ref();

  final messName = TextEditingController();
  final messPhone = TextEditingController();
  final messAddress = TextEditingController();
  final messCode = TextEditingController();
  final messPassword = TextEditingController();

  bool isJoining = false; // Toggle between create and join forms
  String _userName = 'Farhad Foysal';
  String? userName;
  String? userPhone;
  String? userEmail;
  User? _user, _user_data;
  MessUser? messUser, _mess_user_data;
  MessMain? messMain;
  String? sid;
  String? messId;
  School? school;
  Teacher? teacher;
  File? _selectedImage;
  bool _showSaveButton = false;
  int _currentIndex1 = 0;
  int _currentIndex2 = 0;
  DateTime selectedDate = DateTime.now();
  String? selectedMonthYear;

  late TabController _tabController;
  final List<String> _days = ["Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];
  Map<String, List<ClassRoutine>> _routinesByDay = {};

  @override
  void initState() {
    _loadUserName();
    _initializeData();
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
    fetchRoutines();
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

  Future<void> _initializeData() async {
    // First load user data
    await _loadUserData();
    // await _loadMessUserData();


  }

  void showConnectivitySnackBar(bool isOnline) {
    final message = isOnline ? "Internet Connected" : "Internet Not Connected";
    final color = isOnline ? Colors.green : Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }


  Future<void> fetchRoutines() async {
    final routines = await DBManager.getAllRoutines();
    final Map<String, List<ClassRoutine>> grouped = {
      for (var day in _days) day: routines.where((r) => r.day == day).toList(),
    };
    setState(() => _routinesByDay = grouped);
  }

  void _addRoutine(String day,BuildContext context) {
    _showAddClassBottomSheet(day,context);
  }

  void _showAddClassBottomSheet(String day, BuildContext context) {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.0)),
      ),
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddClassBottomSheet(
          onAddClass: (ClassRoutine newClass) {
            _addClass(day,newClass);  // Add class when the bottom sheet is closed
          },
        );
      },
    );
  }

  void _addClass(String day, ClassRoutine newClass) {
    saveNewSchedule(day,newClass);
  }

  void saveNewSchedule(String day, ClassRoutine newSchedule) async {
    await _loadUserData();

    final uuid = Uuid();
    final uniqueId = uuid.v4();
    final scheduleId = _user?.uniqueid;

    if(day==newSchedule.day){
      if (newSchedule.courseCode.isNotEmpty && newSchedule.teacher.isNotEmpty) {
        final routine = ClassRoutine(

          uniqueId: uniqueId,
          scheduleId: scheduleId,
          day: newSchedule.day,
          startTime: newSchedule.startTime,
          endTime: newSchedule.endTime,
          major: newSchedule.major,
          courseCode: newSchedule.courseCode,
          teacher: newSchedule.teacher,
          room: newSchedule.room,
          section: newSchedule.section,
          shift: newSchedule.shift,
        );

        if (await InternetConnectionChecker.instance.hasConnection) {
          // final DatabaseReference _database =
          // FirebaseDatabase.instance.ref("schedules").child(uniqueId);
          //
          // _database.set(routine.toMap()).then((_) {
          //   setState(() {
          //     // scheduleController.addSchedule(routine); // If you use a controller
          //   });
          //
          saveScheduleOffline(day,routine);
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(content: Text('Routine added successfully')),
          //   );
          // }).catchError((error) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(content: Text('Failed to add routine: $error')),
          //   );
          //   print("Firebase Error: $error");
          // });
        } else {
          saveScheduleOffline(day,routine);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No internet connection')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all required fields')),
        );
      }
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You provide the different day!')),
      );
    }

  }

  Future<void> saveScheduleOffline(String day, ClassRoutine schedule) async {

    int result = await DBManager.insertRoutine(schedule);

    if (result > 0) {
      if (mounted) {

        setState(() {
          if (_routinesByDay.containsKey(day)) {
            _routinesByDay[day]!.add(schedule);
          } else {
            _routinesByDay[day] = [schedule];
          }
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            showSnackBarMsg(context, 'Schedule Saved Successful in Offline');
          }
        });

      }
    } else {
      if (mounted) {
        showSnackBarMsg(context, 'Failed');
      }
    }

  }

  void showSnackBarMsg(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _deleteClass(ScheduleItem classToDelete) {
    // deleteSchedule(classToDelete);
    // classController.removeClass(classToDelete);
    // Notify listeners
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _days.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Class Schedule"),
          actions: [
            IconButton(
              icon: Icon(Icons.upload_file),
              onPressed: _exportToExcel,
              tooltip: 'Export to Excel',
            ),
            IconButton(
              icon: Icon(Icons.download),
              onPressed: _importFromExcel,
              tooltip: 'Import from Excel',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _days.map((day) => Tab(text: day)).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _days.map((day) {
            final routines = _routinesByDay[day] ?? [];
            return Column(
              children: [
                Expanded(
                  child: routines.isEmpty
                      ? Center(child: Text("No routine for $day"))
                      : ListView.builder(
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      final r = routines[index];
                      return Dismissible(
                        key: Key(r.uniqueId!),
                        direction: DismissDirection.endToStart, // Swipe left to delete
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          await DBManager.deleteRoutineById(r.uniqueId!);
                          routines.removeAt(index);
                          setState(() {});
                          showSnackBarMsg(context, "Routine deleted");
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          color: Colors.primaries[index % Colors.primaries.length].shade100,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            title: Text("${r.startTime} - ${r.endTime} | ${r.courseCode}"),
                            subtitle: Text("${r.teacher}\n${r.major}, Sec-${r.section}, ${r.shift}"),
                            trailing: Text("Room: ${r.room}"),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _addRoutine(day, context),
                    icon: Icon(Icons.add),
                    label: Text("Add Routine for $day"),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }


  // @override
  // Widget build(BuildContext context) {
  //   return DefaultTabController(
  //     length: _days.length,
  //     child: Scaffold(
  //       appBar: AppBar(
  //         title: Text("Class Schedule"),
  //         actions: [
  //           IconButton(
  //             icon: Icon(Icons.upload_file),
  //             onPressed: _exportToExcel,
  //             tooltip: 'Export to Excel',
  //           ),
  //           IconButton(
  //             icon: Icon(Icons.download),
  //             onPressed: _importFromExcel,
  //             tooltip: 'Import from Excel',
  //           ),
  //         ],
  //         bottom: TabBar(
  //           controller: _tabController,
  //           isScrollable: true,
  //           tabs: _days.map((day) => Tab(text: day)).toList(),
  //         ),
  //       ),
  //       body: TabBarView(
  //         controller: _tabController,
  //         children: _days.map((day) {
  //           final routines = _routinesByDay[day] ?? [];
  //           return Column(
  //             children: [
  //               Expanded(
  //                 child: routines.isEmpty
  //                     ? Center(child: Text("No routine for $day"))
  //                     : ListView.builder(
  //                   itemCount: routines.length,
  //                   itemBuilder: (context, index) {
  //                     final r = routines[index];
  //                     return Card(
  //                       margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //                       color: Colors.primaries[index % Colors.primaries.length].shade100,
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  //                       child: ListTile(
  //                         title: Text("${r.startTime} - ${r.endTime} | ${r.courseCode}"),
  //                         subtitle: Text("${r.teacher}\n${r.major}, Sec-${r.section}, ${r.shift}"),
  //                         trailing: Text("Room: ${r.room}"),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.all(12.0),
  //                 child: ElevatedButton.icon(
  //                   onPressed: () => _addRoutine(day,context),
  //                   icon: Icon(Icons.add),
  //                   label: Text("Add Routine for $day"),
  //                   style: ElevatedButton.styleFrom(
  //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //                   ),
  //                 ),
  //               )
  //             ],
  //           );
  //         }).toList(),
  //       ),
  //     ),
  //   );
  // }

  Future<void> _exportToExcel() async {
    // Request storage permission
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      showSnackBarMsg(context, "Storage permission required");
      return;
    }

    // Create a new Excel workbook
    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // Remove the default sheet

    // Iterate over each day's routines
    _routinesByDay.forEach((day, routines) {
      final Sheet sheet = excel[day]; // Access or create the sheet

      // Add header row
      sheet.appendRow([
        TextCellValue('Start Time'),
        TextCellValue('End Time'),
        TextCellValue('Major'),
        TextCellValue('Course Code'),
        TextCellValue('Teacher'),
        TextCellValue('Room'),
        TextCellValue('Section'),
        TextCellValue('Shift'),
      ]);

      // Add data rows
      for (var r in routines) {
        sheet.appendRow([
          TextCellValue(r.startTime ?? ''),
          TextCellValue(r.endTime ?? ''),
          TextCellValue(r.major ?? ''),
          TextCellValue(r.courseCode ?? ''),
          TextCellValue(r.teacher ?? ''),
          TextCellValue(r.room ?? ''),
          TextCellValue(r.section ?? ''),
          TextCellValue(r.shift ?? ''),
        ]);
      }
    });

    // Save the Excel file to the device
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        showSnackBarMsg(context, "Failed to get storage directory");
        return;
      }

      String outputPath = "${dir.path}/routine_export.xlsx";
      File(outputPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.save()!);

      Directory? downloadsDir;

      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download'); // Downloads folder
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory(); // iOS workaround
      }

      if (downloadsDir == null) {
        showSnackBarMsg(context, "Could not find download directory");
        await OpenFilex.open(outputPath);
      }else{
        String outputPa = "${downloadsDir.path}/blackbox_routine_export.xlsx";
        final file = File(outputPa)
          ..createSync(recursive: true)
          ..writeAsBytesSync(excel.save()!);
        await OpenFilex.open(file.path);
      }



      showSnackBarMsg(context, "Exported to $outputPath");
      // await OpenFilex.open(outputPath);
    } catch (e) {
      showSnackBarMsg(context, "Failed to export: $e");
      print("Failed to export: $e");
    }
  }

  Future<void> exportRoutineByDay(BuildContext context, Map<String, List<ClassRoutine>> routinesByDay) async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Storage permission required')));
      return;
    }

    final Excel excel = Excel.createExcel();
    final Sheet? defaultSheet = excel.sheets[excel.getDefaultSheet() ?? 'Sheet1'];
    if (defaultSheet != null) {
      excel.delete(excel.getDefaultSheet()!); // Delete default sheet
    }

    routinesByDay.forEach((day, routines) {
      final Sheet sheet = excel[day];

      // Add header row with TextCellValue
      sheet.appendRow([
        TextCellValue('Start Time'),
        TextCellValue('End Time'),
        TextCellValue('Major'),
        TextCellValue('Course Code'),
        TextCellValue('Teacher'),
        TextCellValue('Room'),
        TextCellValue('Section'),
        TextCellValue('Shift'),
      ]);

      // Add data rows
      for (var r in routines) {
        sheet.appendRow([
          TextCellValue(r.startTime ?? ''),
          TextCellValue(r.endTime ?? ''),
          TextCellValue(r.major ?? ''),
          TextCellValue(r.courseCode ?? ''),
          TextCellValue(r.teacher ?? ''),
          TextCellValue(r.room ?? ''),
          TextCellValue(r.section ?? ''),
          TextCellValue(r.shift ?? ''),
        ]);
      }
    });

    final dir = await getExternalStorageDirectory();
    final String filePath = '${dir!.path}/class_routine_export.xlsx';

    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.save()!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Routine exported to $filePath')),
    );
  }

  Future<void> _importFromExcel() async {
    try {
      // Pick .xlsx file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        showSnackBarMsg(context, "Import Cancelled");
        return;
      }

      final file = result.files.first;
      final filePath = file.path;

      if (filePath == null) {
        showSnackBarMsg(context, "Invalid file selected");
        return;
      }

      // Read file bytes manually
      final fileBytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(fileBytes);

      // Loop over each sheet (day)
      for (final sheetName in excel.tables.keys) {
        final table = excel.tables[sheetName];
        if (table == null || table.rows.length <= 1) continue; // Skip empty sheets

        for (int rowIndex = 1; rowIndex < table.rows.length; rowIndex++) {
          final row = table.rows[rowIndex];
          if (row.length < 8) continue; // Ensure row has all columns

          final routine = ClassRoutine(
            uniqueId: const Uuid().v4(),
            scheduleId: _user?.uniqueid ?? '',
            day: sheetName,
            startTime: row[0]?.value?.toString() ?? '',
            endTime: row[1]?.value?.toString() ?? '',
            major: row[2]?.value?.toString() ?? '',
            courseCode: row[3]?.value?.toString() ?? '',
            teacher: row[4]?.value?.toString() ?? '',
            room: row[5]?.value?.toString() ?? '',
            section: row[6]?.value?.toString() ?? '',
            shift: row[7]?.value?.toString() ?? '',
          );

          await DBManager.insertRoutine(routine);
        }
      }

      fetchRoutines(); // Refresh the UI
      showSnackBarMsg(context, "Imported Successfully");

    } catch (e) {
      showSnackBarMsg(context, "Import failed: $e");
    }
  }


  Future<void> _importFromExcelnot() async {
    try {
      // Pick .xlsx file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        showSnackBarMsg(context, "Import Cancelled");
        return;
      }

      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        showSnackBarMsg(context, "Invalid file selected");
        return;
      }

      final excel = Excel.decodeBytes(fileBytes);

      // Loop over each sheet (day)
      for (final sheetName in excel.tables.keys) {
        final table = excel.tables[sheetName];
        if (table == null || table.rows.length <= 1) continue; // Skip empty sheets

        for (int rowIndex = 1; rowIndex < table.rows.length; rowIndex++) {
          final row = table.rows[rowIndex];
          if (row.length < 8) continue; // Ensure row has all columns

          final routine = ClassRoutine(
            uniqueId: const Uuid().v4(),
            scheduleId: _user?.uniqueid ?? '',
            day: sheetName,
            startTime: row[0]?.value?.toString() ?? '',
            endTime: row[1]?.value?.toString() ?? '',
            major: row[2]?.value?.toString() ?? '',
            courseCode: row[3]?.value?.toString() ?? '',
            teacher: row[4]?.value?.toString() ?? '',
            room: row[5]?.value?.toString() ?? '',
            section: row[6]?.value?.toString() ?? '',
            shift: row[7]?.value?.toString() ?? '',
          );

          await DBManager.insertRoutine(routine);
        }
      }

      fetchRoutines(); // Refresh the UI
      showSnackBarMsg(context, "Imported Successfully");

    } catch (e) {
      showSnackBarMsg(context, "Import failed: $e");
    }
  }


  Future<void> _importFromExcell() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.isNotEmpty) {
      var fileBytes = result.files.first.bytes;
      var excel = Excel.decodeBytes(fileBytes!);

      for (var sheetName in excel.tables.keys) {
        var table = excel.tables[sheetName];
        if (table == null) continue;

        for (int rowIndex = 1; rowIndex < table.rows.length; rowIndex++) { // skip headers
          var row = table.rows[rowIndex];

          final routine = ClassRoutine(
            uniqueId: const Uuid().v4(),
            scheduleId: _user?.uniqueid,
            day: sheetName,
            startTime: row[0]?.value?.toString() ?? '',
            endTime: row[1]?.value?.toString() ?? '',
            major: row[2]?.value?.toString() ?? '',
            courseCode: row[3]?.value?.toString() ?? '',
            teacher: row[4]?.value?.toString() ?? '',
            room: row[5]?.value?.toString() ?? '',
            section: row[6]?.value?.toString() ?? '',
            shift: row[7]?.value?.toString() ?? '',
          );

          await DBManager.insertRoutine(routine);
        }
      }

      fetchRoutines(); // Refresh UI
      showSnackBarMsg(context, "Imported Successfully");
    } else {
      showSnackBarMsg(context, "Import Cancelled");
    }
  }

}
