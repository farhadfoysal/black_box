import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../db/attendance/attendance_database.dart';
import '../../../../db/course/courseDbConfig.dart';
import '../../../../model/attendance/attendance.dart';
import '../../../../model/school/student.dart';
import '../../../../services/attendance/attendance_serevice.dart';
import '../../../../services/attendance/attendance_sync.dart';

class AttendancePerformanceScreen extends StatefulWidget {
  final String courseId;

  const AttendancePerformanceScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<AttendancePerformanceScreen> createState() =>
      _AttendancePerformanceScreenState();
}

class _AttendancePerformanceScreenState
    extends State<AttendancePerformanceScreen> {
  DateTime selectedDate = DateTime.now();
  bool isOnline = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Student> _students = [];
  Map<String, Attendance> attendanceMap = {};

  bool _isLoadingStudents = false;
  bool _isLoadingAttendance = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ================= INIT =================

  Future<void> _init() async {
    final result = await Connectivity().checkConnectivity();
    isOnline = result != ConnectivityResult.none;

    await _loadStudents();

    // ✅ prevent race condition
    if (_students.isNotEmpty) {
      await _load();
    }
  }

  // ================= STUDENTS =================

  Future<void> _loadStudents() async {
    setState(() => _isLoadingStudents = true);

    try {
      if (isOnline) {
        await _loadFromFirebase();
      } else {
        await _loadFromLocal();
      }
    } catch (_) {
      await _loadFromLocal();
    }

    setState(() => _isLoadingStudents = false);
  }

  Future<void> _loadFromFirebase() async {
    final snapshot = await _firestore
        .collection('courses')
        .doc(widget.courseId)
        .collection('students')
        .orderBy('stdName')
        .get();

    _students = snapshot.docs
        .map((doc) => Student.fromMap({
      ...doc.data(),
      'uniqueId': doc.id,
    }))
        .toList();

    for (var s in _students) {
      await StudentDatabase.insertStudent(s.toMap());
    }
  }

  Future<void> _loadFromLocal() async {
    final maps = await StudentDatabase.getAllStudents();
    _students = maps.map((e) => Student.fromMap(e)).toList();
  }

  // ================= ATTENDANCE =================

  Future<void> _load() async {
    setState(() => _isLoadingAttendance = true);

    final date = DateFormat('yyyy-MM-dd').format(selectedDate);

    final local =
    await AttendanceDatabase.getByDate(date, widget.courseId);

    attendanceMap.clear();

    if (local.isNotEmpty) {
      for (var m in local) {
        final a = Attendance.fromMap(m);
        attendanceMap[a.studentId] = a;
      }
    } else if (isOnline) {
      final remote =
      await AttendanceService().getByDate(date, widget.courseId);

      for (var a in remote) {
        attendanceMap[a.studentId] = a;
        await AttendanceDatabase.upsert(a.toMap());
      }
    }

    // ✅ Ensure every student has attendance
    for (var s in _students) {
      final id = s.stdId;
      if (id == null) continue;

      attendanceMap.putIfAbsent(
        id,
            () => Attendance(
          uniqueId: "${id}_$date",
          studentId: id,
          sCourseId: widget.courseId,
          attendDate: selectedDate,
          date: date,
          status: 'P',
          marks: 0,
        ),
      );
    }

    setState(() => _isLoadingAttendance = false);
  }

  // ================= SAVE =================

  Future<void> _save() async {
    for (var a in attendanceMap.values) {
      a.syncStatus = isOnline ? 1 : 0;

      await AttendanceDatabase.upsert(a.toMap());

      if (isOnline) {
        await AttendanceService().save(widget.courseId, a);
        await AttendanceDatabase.markSynced(a.uniqueId);
      }
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Saved")));
  }

  // ================= DELETE =================

  Future<void> _delete(Attendance a) async {
    await AttendanceDatabase.delete(a.uniqueId);

    if (isOnline) {
      await AttendanceService().delete(widget.courseId, a.uniqueId);
    }

    attendanceMap.remove(a.studentId);
    setState(() {});
  }

  // ================= ACTIONS =================

  void toggle(String id) {
    final a = attendanceMap[id];
    if (a == null) return;

    setState(() => a.status = a.status == 'P' ? 'A' : 'P');
  }

  void changeMarks(String id, int d) {
    final a = attendanceMap[id];
    if (a == null) return;

    setState(() => a.marks = (a.marks + d).clamp(0, 100));
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (d != null) {
      selectedDate = d;
      await _load();
    }
  }

  // ================= LOADING UI =================

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading..."),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
      FloatingActionButton(onPressed: _save, child: const Icon(Icons.save)),
      appBar: AppBar(
        title: const Text("Attendance"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => AttendanceSync.sync(widget.courseId),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              ListTile(
                title: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: pickDate,
              ),

              // ✅ EMPTY STATE
              if (_students.isEmpty)
                const Expanded(
                  child: Center(child: Text("No students found")),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadStudents();
                      await _load();
                    },
                    child: ListView(
                      children: _students.map((s) {
                        final studentId = s.stdId;
                        if (studentId == null) {
                          return const SizedBox();
                        }

                        final a = attendanceMap[studentId] ??
                            Attendance(
                              uniqueId:
                              "${studentId}_${selectedDate.toString()}",
                              studentId: studentId,
                              sCourseId: widget.courseId,
                              attendDate: selectedDate,
                              date: DateFormat('yyyy-MM-dd')
                                  .format(selectedDate),
                              status: 'P',
                              marks: 0,
                            );

                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(s.stdName ?? ""),
                            subtitle: Text("Marks: ${a.marks}"),
                            leading: CircleAvatar(
                              child: Text(a.status),
                              backgroundColor: a.status == 'P'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            onTap: () => toggle(studentId),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () =>
                                      changeMarks(studentId, -1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () =>
                                      changeMarks(studentId, 1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _delete(a),
                                )
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                )
            ],
          ),

          // ✅ LOADER
          if (_isLoadingStudents || _isLoadingAttendance)
            _buildLoadingOverlay(),
        ],
      ),
    );
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
//
// import '../../../../db/attendance/attendance_database.dart';
// import '../../../../db/course/courseDbConfig.dart';
// import '../../../../model/attendance/attendance.dart';
// import '../../../../model/school/student.dart';
// import '../../../../services/attendance/attendance_serevice.dart';
// import '../../../../services/attendance/attendance_sync.dart';
//
// class AttendancePerformanceScreen extends StatefulWidget {
//   final String courseId;
//
//   const AttendancePerformanceScreen({
//     super.key,
//     required this.courseId,
//   });
//
//   @override
//   State<AttendancePerformanceScreen> createState() =>
//       _AttendancePerformanceScreenState();
// }
//
// class _AttendancePerformanceScreenState
//     extends State<AttendancePerformanceScreen> {
//   DateTime selectedDate = DateTime.now();
//   bool isOnline = true;
//
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   List<Student> _students = [];
//   Map<String, Attendance> attendanceMap = {};
//
//   bool _isLoadingStudents = false;
//   bool _isLoadingAttendance = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }
//
//   Future<void> _init() async {
//     final result = await Connectivity().checkConnectivity();
//     isOnline = result != ConnectivityResult.none;
//
//     await _loadStudents();
//     await _load();
//   }
//
//   // ================= STUDENT LOAD =================
//
//   Future<void> _loadStudents() async {
//     setState(() => _isLoadingStudents = true);
//
//     try {
//       if (isOnline) {
//         await _loadFromFirebase();
//       } else {
//         await _loadFromLocal();
//       }
//     } catch (_) {
//       await _loadFromLocal();
//     }
//
//     setState(() => _isLoadingStudents = false);
//   }
//
//   Future<void> _loadFromFirebase() async {
//     final snapshot = await _firestore
//         .collection('courses')
//         .doc(widget.courseId)
//         .collection('students')
//         .orderBy('stdName')
//         .get();
//
//     _students = snapshot.docs
//         .map((doc) => Student.fromMap({
//       ...doc.data(),
//       'uniqueId': doc.id,
//     }))
//         .toList();
//
//     for (var s in _students) {
//       await StudentDatabase.insertStudent(s.toMap());
//     }
//   }
//
//   Future<void> _loadFromLocal() async {
//     final maps = await StudentDatabase.getAllStudents();
//     _students = maps.map((e) => Student.fromMap(e)).toList();
//   }
//
//   // ================= ATTENDANCE LOAD =================
//
//   Future<void> _load() async {
//     setState(() => _isLoadingAttendance = true);
//
//     final date = DateFormat('yyyy-MM-dd').format(selectedDate);
//
//     final local =
//     await AttendanceDatabase.getByDate(date, widget.courseId);
//
//     attendanceMap.clear();
//
//     if (local.isNotEmpty) {
//       for (var m in local) {
//         final a = Attendance.fromMap(m);
//         attendanceMap[a.studentId] = a;
//       }
//     } else if (isOnline) {
//       final remote =
//       await AttendanceService().getByDate(date, widget.courseId);
//
//       for (var a in remote) {
//         attendanceMap[a.studentId] = a;
//         await AttendanceDatabase.upsert(a.toMap());
//       }
//     }
//
//     for (var s in _students) {
//       attendanceMap.putIfAbsent(
//         s.stdId!,
//             () => Attendance(
//           uniqueId: DateTime.now().millisecondsSinceEpoch.toString(),
//           studentId: s.stdId!,
//           sheetId: "",
//           sCourseId: widget.courseId,
//           time: "",
//           exitIn: 0,
//           attendDate: selectedDate,
//           date: date,
//           status: 'P',
//           marks: 0,
//         ),
//       );
//     }
//
//     setState(() => _isLoadingAttendance = false);
//   }
//
//   // ================= SAVE =================
//
//   Future<void> _save() async {
//     for (var a in attendanceMap.values) {
//       a.syncStatus = isOnline ? 1 : 0;
//
//       await AttendanceDatabase.upsert(a.toMap());
//
//       if (isOnline) {
//         await AttendanceService().save(widget.courseId, a);
//         await AttendanceDatabase.markSynced(a.uniqueId);
//       }
//     }
//
//     ScaffoldMessenger.of(context)
//         .showSnackBar(const SnackBar(content: Text("Saved")));
//   }
//
//   // ================= DELETE =================
//
//   Future<void> _delete(Attendance a) async {
//     await AttendanceDatabase.delete(a.uniqueId);
//
//     if (isOnline) {
//       await AttendanceService().delete(widget.courseId, a.uniqueId);
//     }
//
//     attendanceMap.remove(a.studentId);
//     setState(() {});
//   }
//
//   // ================= ACTIONS =================
//
//   void toggle(String id) {
//     final a = attendanceMap[id]!;
//     setState(() => a.status = a.status == 'P' ? 'A' : 'P');
//   }
//
//   void changeMarks(String id, int d) {
//     final a = attendanceMap[id]!;
//     setState(() => a.marks = (a.marks + d).clamp(0, 100));
//   }
//
//   Future<void> pickDate() async {
//     final d = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2023),
//       lastDate: DateTime.now(),
//     );
//
//     if (d != null) {
//       selectedDate = d;
//       await _load();
//     }
//   }
//
//   // ================= LOADER =================
//
//   Widget _buildLoadingOverlay() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black.withOpacity(0.3),
//         child: Center(
//           child: Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: const Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text("Loading...",
//                     style: TextStyle(fontWeight: FontWeight.bold)),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ================= UI =================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton:
//       FloatingActionButton(onPressed: _save, child: const Icon(Icons.save)),
//       appBar: AppBar(
//         title: const Text("Attendance"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.sync),
//             onPressed: () => AttendanceSync.sync(widget.courseId),
//           )
//         ],
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               ListTile(
//                 title: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
//                 trailing: const Icon(Icons.calendar_today),
//                 onTap: pickDate,
//               ),
//               Expanded(
//                 child: RefreshIndicator(
//                   onRefresh: () async {
//                     await _loadStudents();
//                     await _load();
//                   },
//                   child: ListView(
//                     children: _students.map((s) {
//                       final a = attendanceMap[s.stdId]!;
//
//                       return Card(
//                         margin: const EdgeInsets.all(8),
//                         child: ListTile(
//                           title: Text(s.stdName ?? ""),
//                           subtitle: Text("Marks: ${a.marks}"),
//                           leading: CircleAvatar(
//                             child: Text(a.status),
//                             backgroundColor: a.status == 'P'
//                                 ? Colors.green
//                                 : Colors.red,
//                           ),
//                           onTap: () => toggle(s.stdId!),
//                           trailing: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.remove),
//                                 onPressed: () =>
//                                     changeMarks(s.stdId!, -1),
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.add),
//                                 onPressed: () =>
//                                     changeMarks(s.stdId!, 1),
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.delete),
//                                 onPressed: () => _delete(a),
//                               )
//                             ],
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               )
//             ],
//           ),
//
//           if (_isLoadingStudents || _isLoadingAttendance)
//             _buildLoadingOverlay(),
//         ],
//       ),
//     );
//   }
// }


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
//
// import '../../../../db/attendance/attendance_database.dart';
// import '../../../../db/course/courseDbConfig.dart';
// import '../../../../model/attendance/attendance.dart';
// import '../../../../model/school/student.dart';
// import '../../../../services/attendance/attendance_serevice.dart';
// import '../../../../services/attendance/attendance_sync.dart';
//
//
// class AttendancePerformanceScreen extends StatefulWidget {
//   final String courseId;
//
//   const AttendancePerformanceScreen({
//     super.key,
//     required this.courseId,
//   });
//
//   @override
//   State<AttendancePerformanceScreen> createState() =>
//       _AttendancePerformanceScreenState();
// }
//
// class _AttendancePerformanceScreenState
//     extends State<AttendancePerformanceScreen> {
//   DateTime selectedDate = DateTime.now();
//   bool isOnline = true;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   List<Student> _students = [];
//   Map<String, Attendance> attendanceMap = {};
//   bool _isLoading = true;
//
//
//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }
//
//   Future<void> _init() async {
//     final result = await Connectivity().checkConnectivity();
//     isOnline = result != ConnectivityResult.none;
//     await _loadStudents();
//     await _load();
//   }
//
//   // ================= LOAD =================
//
//   Future<void> _loadStudents() async {
//
//     setState(() => _isLoading = true);
//
//     try {
//
//       if (isOnline) {
//         await _loadFromFirebase();
//       } else {
//         await _loadFromLocal();
//       }
//
//     } catch (_) {
//
//       await _loadFromLocal();
//
//     }
//
//     setState(() => _isLoading = false);
//
//   }
//
//   Future<void> _loadFromFirebase() async {
//
//     final snapshot = await _firestore
//         .collection('courses')
//         .doc(widget.courseId)
//         .collection('students')
//         .orderBy('stdName')
//         .get();
//
//     _students = snapshot.docs
//         .map((doc) => Student.fromMap({...doc.data(), 'uniqueId': doc.id}))
//         .toList();
//
//     for (var s in _students) {
//       await StudentDatabase.insertStudent(s.toMap());
//     }
//
//
//   }
//
//   Future<void> _loadFromLocal() async {
//
//     final maps = await StudentDatabase.getAllStudents();
//
//     _students = maps.map((e) => Student.fromMap(e)).toList();
//
//
//   }
//
//   // ================= SYNC =================
//
//   Future<void> _syncWithFirebase() async {
//
//     final unsynced = await StudentDatabase.getUnsyncedStudents();
//
//     for (var map in unsynced) {
//
//       final student = Student.fromMap(map);
//
//       try {
//
//         await _firestore
//             .collection('courses')
//             .doc(widget.courseId)
//             .collection('students')
//             .doc(student.uniqueId)
//             .set(student.toMap());
//
//         await StudentDatabase.updateSyncStatus(student.id!, 1);
//
//       } catch (e) {
//         debugPrint("Sync error $e");
//       }
//     }
//
//     _loadStudents();
//
//   }
//
//
//   Future<void> _load() async {
//     final date = DateFormat('yyyy-MM-dd').format(selectedDate);
//
//     final local =
//     await AttendanceDatabase.getByDate(date, widget.courseId);
//
//     attendanceMap.clear();
//
//     if (local.isNotEmpty) {
//       for (var m in local) {
//         final a = Attendance.fromMap(m);
//         attendanceMap[a.studentId] = a;
//       }
//     } else if (isOnline) {
//       final remote = await AttendanceService()
//           .getByDate(date, widget.courseId);
//
//       for (var a in remote) {
//         attendanceMap[a.studentId] = a;
//         await AttendanceDatabase.upsert(a.toMap());
//       }
//     }
//
//     // fill missing
//     for (var s in _students) {
//       attendanceMap.putIfAbsent(
//         s.stdId!,
//             () => Attendance(
//           uniqueId: DateTime.now().millisecondsSinceEpoch.toString(),
//           studentId: s.stdId!,
//           sheetId: "",
//           sCourseId: widget.courseId,
//           time: "",
//           exitIn: 0,
//           attendDate: selectedDate,
//           date: date,
//           status: 'P',
//           marks: 0,
//         ),
//       );
//     }
//
//     setState(() {});
//   }
//
//   // ================= SAVE =================
//
//   Future<void> _save() async {
//     for (var a in attendanceMap.values) {
//       a.syncStatus = isOnline ? 1 : 0;
//
//       await AttendanceDatabase.upsert(a.toMap());
//
//       if (isOnline) {
//         await AttendanceService().save(widget.courseId, a);
//         await AttendanceDatabase.markSynced(a.uniqueId);
//       }
//     }
//
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text("Saved")));
//   }
//
//   // ================= DELETE =================
//
//   Future<void> _delete(Attendance a) async {
//     await AttendanceDatabase.delete(a.uniqueId);
//
//     if (isOnline) {
//       await AttendanceService().delete(widget.courseId, a.uniqueId);
//     }
//
//     attendanceMap.remove(a.studentId);
//     setState(() {});
//   }
//
//   // ================= UI ACTIONS =================
//
//   void toggle(String id) {
//     final a = attendanceMap[id]!;
//     setState(() => a.status = a.status == 'P' ? 'A' : 'P');
//   }
//
//   void changeMarks(String id, int d) {
//     final a = attendanceMap[id]!;
//     setState(() => a.marks = (a.marks + d).clamp(0, 100));
//   }
//
//   Future<void> pickDate() async {
//     final d = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2023),
//       lastDate: DateTime.now(),
//     );
//
//     if (d != null) {
//       selectedDate = d;
//       await _load();
//     }
//   }
//
//   // ================= UI =================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton:
//       FloatingActionButton(onPressed: _save, child: Icon(Icons.save)),
//       appBar: AppBar(
//         title: Text("Attendance"),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.sync),
//             onPressed: () => AttendanceSync.sync(widget.courseId),
//           )
//         ],
//       ),
//       body: Column(
//         children: [
//           ListTile(
//             title: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
//             trailing: Icon(Icons.calendar_today),
//             onTap: pickDate,
//           ),
//           Expanded(
//             child: ListView(
//               children: _students.map((s) {
//                 final a = attendanceMap[s.stdId]!;
//
//                 return Card(
//                   margin: EdgeInsets.all(8),
//                   child: ListTile(
//                     title: Text(s.stdName ?? ""),
//                     subtitle: Text("Marks: ${a.marks}"),
//                     leading: CircleAvatar(
//                       child: Text(a.status),
//                       backgroundColor:
//                       a.status == 'P' ? Colors.green : Colors.red,
//                     ),
//                     onTap: () => toggle(s.stdId!),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           icon: Icon(Icons.remove),
//                           onPressed: () => changeMarks(s.stdId!, -1),
//                         ),
//                         IconButton(
//                           icon: Icon(Icons.add),
//                           onPressed: () => changeMarks(s.stdId!, 1),
//                         ),
//                         IconButton(
//                           icon: Icon(Icons.delete),
//                           onPressed: () => _delete(a),
//                         )
//                       ],
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }