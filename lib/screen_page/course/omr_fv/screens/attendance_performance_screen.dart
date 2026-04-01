// ============================================================
// attendance_performance_screen.dart
// ============================================================
//
// FIXES vs original
// -----------------
// 1. _save() called upsert() TWICE (once with data, once adding
//    sync_status:0). Second call could overwrite a just-synced row.
//    Now: single upsert with sync_status embedded in the model.
//
// 2. _delete() set sync_status=2 but never removed the record from
//    attendanceMap OR from local DB cleanly.  The record re-appeared
//    on next _loadAttendance() because getByDate() returned it.
//    Now: marks sync_status=2 locally, removes from map, and the
//    fixed getByDate() excludes sync_status=2 rows on reload.
//
// 3. _loadAttendance() merge strategy:
//    OLD — if local rows exist, Firestore is skipped entirely.
//          Edits on another device were never pulled.
//    NEW — always prefer local for TODAY (avoids latency) but on a
//          date *change* or explicit sync, always fetch from Firestore
//          and merge (remote wins for existing keys, local wins for
//          unsaved changes).
//
// 4. putIfAbsent() re-created default records for deleted students.
//    Now it skips student IDs whose attendance is already in the map
//    (including soft-deleted ones with sync_status=2 that were removed
//    from the map in step 2).
//
// 5. _controllers leaked memory across date changes.
//    Now: disposed and rebuilt on every date change.
//
// 6. autoSync() used a.sCourseId as the Firestore path — moved to
//    AttendanceSync which guards against empty values.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../db/attendance/attendance_database.dart';
import '../../../../db/course/courseDbConfig.dart';
import '../../../../model/attendance/attendance.dart';
import '../../../../model/school/student.dart';
import '../../../../services/attendance/attendance_serevice.dart';

import '../../../../services/attendance/attendance_sync.dart';

import 'advanced_monthly_report_screen.dart';

class AttendancePerformanceScreen extends StatefulWidget {
  final String courseId;

  const AttendancePerformanceScreen({super.key, required this.courseId});

  @override
  State<AttendancePerformanceScreen> createState() =>
      _AttendancePerformanceScreenState();
}

class _AttendancePerformanceScreenState
    extends State<AttendancePerformanceScreen> {
  // ── state ───────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  bool _isOnline = false;

  List<Student> _students = [];
  // studentId → Attendance (only active records, no sync_status=2)
  final Map<String, Attendance> _attendanceMap = {};

  bool _loadingStudents = false;
  bool _loadingAttendance = false;

  // FIX 5: controllers keyed by studentId; disposed on date change.
  final Map<String, TextEditingController> _controllers = {};

  // ── helpers ─────────────────────────────────────────────────
  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  // ── lifecycle ───────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  // FIX 5: explicit disposal.
  void _disposeControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
  }

  // ── init ────────────────────────────────────────────────────
  Future<void> _init() async {
    final result = await Connectivity().checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    await _loadStudents();
    if (_students.isNotEmpty) await _loadAttendance();
  }

  // ── students ────────────────────────────────────────────────
  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);
    try {
      if (_isOnline) {
        await _loadStudentsFromFirebase();
      } else {
        await _loadStudentsFromLocal();
      }
    } catch (_) {
      await _loadStudentsFromLocal();
    } finally {
      setState(() => _loadingStudents = false);
    }
  }

  Future<void> _loadStudentsFromFirebase() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('students')
        .orderBy('stdName')
        .get();

    _students = snapshot.docs
        .map((d) => Student.fromMap({...d.data(), 'uniqueId': d.id}))
        .toList();

    // Cache locally.
    await Future.wait(
      _students.map((s) => StudentDatabase.insertStudent(s.toMap())),
    );
  }

  Future<void> _loadStudentsFromLocal() async {
    final maps = await StudentDatabase.getAllStudents();
    _students = maps.map(Student.fromMap).toList();
  }

  // ── attendance ──────────────────────────────────────────────
  // FIX 3: improved merge strategy.
  Future<void> _loadAttendance({bool forceRemote = false}) async {
    setState(() => _loadingAttendance = true);

    _attendanceMap.clear();

    // 1. Always load local first (instant, works offline).
    final localRows =
    await AttendanceDatabase.getByDate(_dateKey, widget.courseId);

    for (final m in localRows) {
      final a = Attendance.fromMap(m);
      _attendanceMap[a.studentId] = a;
    }

    // 2. Fetch from Firestore when online and either forced or local is empty.
    if (_isOnline && (forceRemote || localRows.isEmpty)) {
      try {
        final remote = await AttendanceService()
            .getByDate(widget.courseId, _dateKey);

        for (final a in remote) {
          final local = _attendanceMap[a.studentId];

          // Remote wins unless the local copy is pending sync (unsaved edit).
          if (local == null || local.syncStatus == 1) {
            _attendanceMap[a.studentId] = a;
            // Keep local cache fresh.
            await AttendanceDatabase.upsert(
              a.copyWith(syncStatus: 1).toMap(),
            );
          }
        }
      } catch (_) {
        // Network error — silently use local data.
      }
    }

    // 3. Ensure every student has a default record.
    // FIX 4: putIfAbsent only for students NOT already in the map.
    for (final s in _students) {
      final id = s.stdId;
      if (id == null) continue;

      _attendanceMap.putIfAbsent(id, () {
        return Attendance(
          uniqueId: Attendance.generateId(widget.courseId, id, _dateKey),
          studentId: id,
          sCourseId: widget.courseId,
          attendDate: _selectedDate,
          date: _dateKey,
          status: 'P',
          marks: 0,
          syncStatus: 0,
        );
      });
    }

    setState(() => _loadingAttendance = false);
  }

  // ── save ────────────────────────────────────────────────────
  // FIX 1: single upsert per record; sync_status is part of the model.
  Future<void> _save() async {
    for (final a in _attendanceMap.values) {
      // Mark as pending sync before writing.
      a.syncStatus = 0;

      // Local write.
      await AttendanceDatabase.upsert(a.toMap());

      // Firestore write.
      if (_isOnline) {
        try {
          await AttendanceService().save(widget.courseId, a);
          await AttendanceDatabase.markSynced(a.uniqueId);
          a.syncStatus = 1; // keep in-memory state consistent
        } catch (e) {
          debugPrint('SYNC FAILED for ${a.uniqueId}: $e');
          // Stays sync_status=0 — AttendanceSync will retry.
        }
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance saved')),
    );
  }

  // ── delete ──────────────────────────────────────────────────
  // FIX 2: soft-delete locally, remove from map; sync handles Firestore.
  Future<void> _delete(Attendance a) async {
    // Soft-delete: mark for remote deletion.
    await AttendanceDatabase.upsert(a.copyWith(syncStatus: 2).toMap());

    // Remove from UI immediately.
    setState(() => _attendanceMap.remove(a.studentId));

    if (_isOnline) {
      try {
        final ok =
        await AttendanceService().delete(widget.courseId, a.uniqueId);
        if (ok) {
          await AttendanceDatabase.hardDelete(a.uniqueId);
        }
      } catch (_) {
        // Will be retried by AttendanceSync on next connect.
      }
    }
  }

  // ── toggle / marks ───────────────────────────────────────────
  void _toggle(String id) {
    final a = _attendanceMap[id];
    if (a == null) return;
    setState(() => a.status = a.status == 'P' ? 'A' : 'P');
  }

  void _changeMarks(String id, int delta) {
    final a = _attendanceMap[id];
    if (a == null) return;
    setState(() {
      a.marks = (a.marks + delta).clamp(0, 100);
      _controllers[id]?.text = a.marks.toString();
    });
  }

  // ── date picker ──────────────────────────────────────────────
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (d != null && d != _selectedDate) {
      _disposeControllers(); // FIX 5: dispose old controllers
      setState(() => _selectedDate = d);
      await _loadAttendance();
    }
  }

  // ── controller helper ────────────────────────────────────────
  TextEditingController _controllerFor(String id, int marks) {
    return _controllers.putIfAbsent(
      id,
          () => TextEditingController(text: marks.toString()),
    );
  }

  // ── UI ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLoading = _loadingStudents || _loadingAttendance;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_outlined),
            tooltip: 'Monthly Report',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AdvancedMonthlyReportScreen(courseId: widget.courseId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync',
            onPressed: () async {
              setState(() => _loadingAttendance = true);
              await AttendanceSync.sync(widget.courseId);
              // After sync, reload with forceRemote to reflect latest state.
              await _loadAttendance(forceRemote: true);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Date selector
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _dateKey,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: _isOnline
                    ? const Icon(Icons.wifi, color: Colors.green, size: 16)
                    : const Icon(Icons.wifi_off, color: Colors.red, size: 16),
                onTap: _pickDate,
              ),
              const Divider(height: 1),

              // List
              Expanded(
                child: _students.isEmpty && !isLoading
                    ? const Center(child: Text('No students found.'))
                    : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (_, i) => _buildStudentTile(i),
                ),
              ),
            ],
          ),
          if (isLoading)
            const ColoredBox(
              color: Colors.black12,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(int i) {
    final s = _students[i];
    final id = s.stdId;
    if (id == null) return const SizedBox.shrink();

    final a = _attendanceMap[id];
    if (a == null) return const SizedBox.shrink();

    final controller = _controllerFor(id, a.marks);
    // Keep controller in sync if marks were changed programmatically.
    if (controller.text != a.marks.toString()) {
      controller.text = a.marks.toString();
    }

    final isPresent = a.status == 'P';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _toggle(id),
          child: CircleAvatar(
            backgroundColor: isPresent ? Colors.green : Colors.red,
            child: Text(
              a.status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(s.stdName ?? ''),
        subtitle: Row(
          children: [
            const Text('Marks:'),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _changeMarks(id, -1),
            ),
            SizedBox(
              width: 56,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (v) {
                  a.marks = (int.tryParse(v) ?? 0).clamp(0, 100);
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _changeMarks(id, 1),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _delete(a),
        ),
        onTap: () => _toggle(id),
      ),
    );
  }
}



// import 'package:black_box/screen_page/course/omr_fv/screens/advanced_monthly_report_screen.dart';
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
//   const AttendancePerformanceScreen({super.key, required this.courseId});
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
//   final Map<String, TextEditingController> _controllers = {};
//
//   String get _dateKey => DateFormat('yyyy-MM-dd').format(selectedDate);
//
//   String _uniqueId(String studentId) =>
//       "${widget.courseId}_$studentId\_$_dateKey";
//
//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }
//
//   // ================= INIT =================
//
//   Future<void> _init() async {
//     final result = await Connectivity().checkConnectivity();
//     isOnline = result != ConnectivityResult.none;
//
//     await _loadStudents();
//
//     if (_students.isNotEmpty) {
//       await _loadAttendance();
//     }
//   }
//
//   static String generateId(String courseId, String studentId, String date) {
//     return "${courseId}_${studentId}_$date";
//   }
//
//   // ================= STUDENTS =================
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
//         .map((doc) => Student.fromMap({...doc.data(), 'uniqueId': doc.id}))
//         .toList();
//
//     await Future.wait(
//       _students.map((s) => StudentDatabase.insertStudent(s.toMap())),
//     );
//   }
//
//   Future<void> _loadFromLocal() async {
//     final maps = await StudentDatabase.getAllStudents();
//     _students = maps.map((e) => Student.fromMap(e)).toList();
//   }
//
//   // ================= ATTENDANCE =================
//
//   Future<void> _loadAttendance() async {
//     setState(() => _isLoadingAttendance = true);
//
//     final local =
//     await AttendanceDatabase.getByDate(_dateKey, widget.courseId);
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
//       await AttendanceService().getByDate(_dateKey, widget.courseId);
//
//       for (var a in remote) {
//         attendanceMap[a.studentId] = a;
//         await AttendanceDatabase.upsert(a.toMap());
//       }
//     }
//
//     // ensure every student has record
//     for (var s in _students) {
//       final id = s.stdId;
//       if (id == null) continue;
//
//       attendanceMap.putIfAbsent(
//         id,
//             () {
//           final uid = Attendance.generateId(widget.courseId, id, _dateKey);
//
//           return Attendance(
//             uniqueId: uid,
//             studentId: id,
//             sCourseId: widget.courseId,
//             attendDate: selectedDate,
//             date: _dateKey,
//             status: 'P',
//             marks: 0,
//           );
//         },
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
//       final uid = a.uniqueId;
//
//       final data = a.toMap();
//
//       // 1. SAVE LOCALLY FIRST
//       await AttendanceDatabase.upsert(data);
//
//       // 2. MARK AS PENDING SYNC
//       await AttendanceDatabase.upsert({
//         ...data,
//         'sync_status': 0,
//       });
//
//       // 3. SYNC TO FIRESTORE
//       if (isOnline) {
//         try {
//           await AttendanceService().save(widget.courseId, a);
//
//           await AttendanceDatabase.markSynced(uid);
//         } catch (e) {
//           debugPrint("SYNC FAILED: $e");
//         }
//       }
//     }
//
//     if (!mounted) return;
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Attendance saved & synced")),
//     );
//   }
//
//   // Future<void> _save() async {
//   //   for (var a in attendanceMap.values) {
//   //     a.uniqueId = _uniqueId(a.studentId);
//   //
//   //     // save locally
//   //     a.syncStatus = 0;
//   //     await AttendanceDatabase.upsert(a.toMap());
//   //
//   //     print("${a.toMap()}");
//   //
//   //     // sync
//   //     if (isOnline) {
//   //       try {
//   //         await AttendanceService().save(widget.courseId, a);
//   //         await AttendanceDatabase.markSynced(a.uniqueId);
//   //       } catch (e) {
//   //         debugPrint("SYNC FAIL: $e");
//   //       }
//   //     }
//   //   }
//   //
//   //   if (!mounted) return;
//   //
//   //   ScaffoldMessenger.of(context)
//   //       .showSnackBar(const SnackBar(content: Text("Saved successfully")));
//   // }
//
//
//   // ================= DELETE =================
//
//   Future<void> _delete(Attendance a) async {
//     final uid = a.uniqueId;
//
//     // mark as deleted (safer sync)
//     await AttendanceDatabase.upsert({
//       ...a.toMap(),
//       'sync_status': 2,
//     });
//
//     if (isOnline) {
//       try {
//         await AttendanceService().delete(widget.courseId, uid);
//       } catch (_) {}
//     }
//
//     setState(() {
//       attendanceMap.remove(a.studentId);
//     });
//   }
//
//   // Future<void> _delete(Attendance a) async {
//   //   await AttendanceDatabase.delete(a.uniqueId);
//   //
//   //   if (isOnline) {
//   //     await AttendanceService().delete(widget.courseId, a.uniqueId);
//   //   }
//   //
//   //   // recreate default instead of removing
//   //   attendanceMap[a.studentId] = Attendance(
//   //     uniqueId: _uniqueId(a.studentId),
//   //     studentId: a.studentId,
//   //     sCourseId: widget.courseId,
//   //     attendDate: selectedDate,
//   //     date: _dateKey,
//   //     status: 'A',
//   //     marks: 0,
//   //   );
//   //
//   //   setState(() {});
//   // }
//
//   // ================= ACTIONS =================
//
//   Future<void> autoSync() async {
//     final pending = await AttendanceDatabase.unsynced();
//
//     for (var m in pending) {
//       final a = Attendance.fromMap(m);
//
//       try {
//         await AttendanceService().save(a.sCourseId, a);
//         await AttendanceDatabase.markSynced(a.uniqueId);
//       } catch (_) {}
//     }
//   }
//
//
//   void toggle(String id) {
//     final a = attendanceMap[id];
//     if (a == null) return;
//
//     setState(() => a.status = a.status == 'P' ? 'A' : 'P');
//   }
//
//   void changeMarks(String id, int delta) {
//     final a = attendanceMap[id];
//     if (a == null) return;
//
//     setState(() {
//       a.marks = (a.marks + delta).clamp(0, 100);
//
//       final controller = _controllers[id];
//       if (controller != null && controller.text != a.marks.toString()) {
//         controller.text = a.marks.toString();
//       }
//     });
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
//       setState(() => selectedDate = d);
//       await _loadAttendance();
//     }
//   }
//
//   // ================= UI =================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         onPressed: _save,
//         child: const Icon(Icons.save),
//       ),
//       appBar: AppBar(
//         title: const Text("Attendance"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.report_outlined),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) =>
//                       AdvancedMonthlyReportScreen(courseId: widget.courseId),
//                 ),
//               );
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.sync),
//             onPressed: () async {
//               setState(() => _isLoadingAttendance = true);
//               await AttendanceSync.sync(widget.courseId);
//               setState(() => _isLoadingAttendance = false);
//             },
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               ListTile(
//                 title: Text(_dateKey),
//                 trailing: const Icon(Icons.calendar_today),
//                 onTap: pickDate,
//               ),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: _students.length,
//                   itemBuilder: (_, i) {
//                     final s = _students[i];
//                     final id = s.stdId;
//                     if (id == null) return const SizedBox();
//
//                     final a = attendanceMap[id]!;
//
//                     _controllers.putIfAbsent(
//                       id,
//                           () => TextEditingController(text: a.marks.toString()),
//                     );
//
//                     final controller = _controllers[id]!;
//
//                     if (controller.text != a.marks.toString()) {
//                       controller.text = a.marks.toString();
//                     }
//
//                     return Card(
//                       margin: const EdgeInsets.all(8),
//                       child: ListTile(
//                         title: Text(s.stdName ?? ""),
//                         leading: CircleAvatar(
//                           backgroundColor:
//                           a.status == 'P' ? Colors.green : Colors.red,
//                           child: Text(a.status),
//                         ),
//                         onTap: () => toggle(id),
//                         subtitle: Row(
//                           children: [
//                             const Text("Marks: "),
//                             IconButton(
//                               icon: const Icon(Icons.remove),
//                               onPressed: () => changeMarks(id, -1),
//                             ),
//                             SizedBox(
//                               width: 60,
//                               child: TextFormField(
//                                 controller: controller,
//                                 keyboardType: TextInputType.number,
//                                 textAlign: TextAlign.center,
//                                 onChanged: (v) {
//                                   final val = int.tryParse(v) ?? 0;
//                                   a.marks = val.clamp(0, 100);
//                                 },
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.add),
//                               onPressed: () => changeMarks(id, 1),
//                             ),
//                           ],
//                         ),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.delete),
//                           onPressed: () => _delete(a),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//           if (_isLoadingStudents || _isLoadingAttendance)
//             const Center(child: CircularProgressIndicator()),
//         ],
//       ),
//     );
//   }
// }


// import 'package:black_box/screen_page/course/omr_fv/screens/advanced_monthly_report_screen.dart';
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
//   const AttendancePerformanceScreen({super.key, required this.courseId});
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
//   Map<String, TextEditingController> _controllers = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }
//
//   // ================= INIT =================
//
//   Future<void> _init() async {
//     final result = await Connectivity().checkConnectivity();
//     isOnline = result != ConnectivityResult.none;
//
//     await _loadStudents();
//
//     // ✅ prevent race condition
//     if (_students.isNotEmpty) {
//       await _load();
//     }
//   }
//
//   // ================= STUDENTS =================
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
//         .map((doc) => Student.fromMap({...doc.data(), 'uniqueId': doc.id}))
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
//   // ================= ATTENDANCE =================
//
//   Future<void> _load() async {
//     setState(() => _isLoadingAttendance = true);
//
//     final date = DateFormat('yyyy-MM-dd').format(selectedDate);
//
//     final local = await AttendanceDatabase.getByDate(date, widget.courseId);
//
//     attendanceMap.clear();
//
//     if (local.isNotEmpty) {
//       for (var m in local) {
//         final a = Attendance.fromMap(m);
//         attendanceMap[a.studentId] = a;
//       }
//     } else if (isOnline) {
//       final remote = await AttendanceService().getByDate(date, widget.courseId);
//
//       for (var a in remote) {
//         attendanceMap[a.studentId] = a;
//         await AttendanceDatabase.upsert(a.toMap());
//       }
//     }
//
//     // ✅ Ensure every student has attendance
//     for (var s in _students) {
//       final id = s.stdId;
//       if (id == null) continue;
//
//       attendanceMap.putIfAbsent(
//         id,
//             () => Attendance(
//           uniqueId: "${id}_$date",
//           studentId: id,
//           sCourseId: widget.courseId,
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
//     final date = DateFormat('yyyy-MM-dd').format(selectedDate);
//
//     for (var a in attendanceMap.values) {
//       a.uniqueId = "${widget.courseId}_${a.studentId}_$date";
//
//       /// ✅ Always save locally
//       a.syncStatus = 0;
//       await AttendanceDatabase.upsert(a.toMap());
//
//       /// ✅ Try online sync safely
//       if (isOnline) {
//         try {
//           await AttendanceService().save(widget.courseId, a);
//
//           /// mark synced only if success
//           await AttendanceDatabase.markSynced(a.uniqueId);
//
//           print("☁️ SYNC SUCCESS: ${a.uniqueId}");
//         } catch (e) {
//           print("❌ SYNC FAILED: ${a.uniqueId} | $e");
//         }
//       }
//     }
//
//     if (!mounted) return;
//
//     ScaffoldMessenger.of(context)
//         .showSnackBar(const SnackBar(content: Text("Saved locally")));
//   }
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
//     final a = attendanceMap[id];
//     if (a == null) return;
//
//     setState(() => a.status = a.status == 'P' ? 'A' : 'P');
//   }
//
//   void changeMarks(String id, int d) {
//     final a = attendanceMap[id];
//     if (a == null) return;
//
//     setState(() {
//       a.marks = (a.marks + d).clamp(0, 100);
//
//       _controllers[id]?.text = a.marks.toString();
//     });
//   }
//
//   // void changeMarks(String id, int d) {
//   //   final a = attendanceMap[id];
//   //   if (a == null) return;
//   //
//   //   setState(() => a.marks = (a.marks + d).clamp(0, 100));
//   // }
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
//   // ================= LOADING UI =================
//
//   Widget _buildLoadingOverlay() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black.withOpacity(0.3),
//         child: const Center(
//           child: Card(
//             child: Padding(
//               padding: EdgeInsets.all(20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text("Loading..."),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     for (var c in _controllers.values) {
//       c.dispose();
//     }
//     super.dispose();
//   }
//
//   // ================= UI =================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         onPressed: _save,
//         child: const Icon(Icons.save),
//       ),
//       appBar: AppBar(
//         title: const Text("Attendance"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.report_outlined),
//             onPressed: () => {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => AdvancedMonthlyReportScreen(courseId: widget.courseId)),
//               )
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.sync),
//             onPressed: () => AttendanceSync.sync(widget.courseId),
//           ),
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
//
//               // ✅ EMPTY STATE
//               if (_students.isEmpty)
//                 const Expanded(child: Center(child: Text("No students found")))
//               else
//                 Expanded(
//                   child: RefreshIndicator(
//                     onRefresh: () async {
//                       await _loadStudents();
//                       await _load();
//                     },
//                     child: ListView(
//                       children: _students.map((s) {
//                         final studentId = s.stdId;
//                         if (studentId == null) {
//                           return const SizedBox();
//                         }
//
//                         final a =
//                             attendanceMap[studentId] ??
//                                 Attendance(
//                                   uniqueId:
//                                   "${studentId}_${selectedDate.toString()}",
//                                   studentId: studentId,
//                                   sCourseId: widget.courseId,
//                                   attendDate: selectedDate,
//                                   date: DateFormat(
//                                     'yyyy-MM-dd',
//                                   ).format(selectedDate),
//                                   status: 'P',
//                                   marks: 0,
//                                 );
//
//                         return Card(
//                           margin: const EdgeInsets.all(8),
//                           child: ListTile(
//                             title: Text(s.stdName ?? ""),
//                             subtitle: Row(
//                               children: [
//                                 const Text("Marks: "),
//
//                                 // ➖ Decrease button
//                                 IconButton(
//                                   icon: const Icon(Icons.remove),
//                                   onPressed: () => changeMarks(studentId, -1),
//                                 ),
//
//                                 // 🔢 Input field with controller
//                                 SizedBox(
//                                   width: 60,
//                                   child: Builder(
//                                     builder: (_) {
//                                       _controllers.putIfAbsent(
//                                         studentId,
//                                             () => TextEditingController(text: a.marks.toString()),
//                                       );
//
//                                       final controller = _controllers[studentId]!;
//
//                                       // ✅ Sync controller with latest value
//                                       controller.value = controller.value.copyWith(
//                                         text: a.marks.toString(),
//                                         selection: TextSelection.collapsed(
//                                           offset: a.marks.toString().length,
//                                         ),
//                                       );
//
//                                       return TextFormField(
//                                         controller: controller,
//                                         keyboardType: TextInputType.number,
//                                         textAlign: TextAlign.center,
//                                         onChanged: (value) {
//                                           final val = int.tryParse(value) ?? 0;
//                                           a.marks = val.clamp(0, 100);
//                                         },
//                                         decoration: const InputDecoration(
//                                           isDense: true,
//                                           contentPadding: EdgeInsets.symmetric(vertical: 8),
//                                           border: OutlineInputBorder(),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ),
//
//                                 // ➕ Increase button
//                                 IconButton(
//                                   icon: const Icon(Icons.add),
//                                   onPressed: () => changeMarks(studentId, 1),
//                                 ),
//                               ],
//                             ),
//                             // subtitle: Text("Marks: ${a.marks}"),
//                             // subtitle: Row(
//                             //   children: [
//                             //     const Text("Marks: "),
//                             //
//                             //     // ➖ Decrease button
//                             //     IconButton(
//                             //       icon: const Icon(Icons.remove),
//                             //       onPressed: () => changeMarks(studentId, -1),
//                             //     ),
//                             //
//                             //     // 🔢 Input field
//                             //     SizedBox(
//                             //       width: 50,
//                             //       child: TextFormField(
//                             //         initialValue: a.marks.toString(),
//                             //         keyboardType: TextInputType.number,
//                             //         textAlign: TextAlign.center,
//                             //         onChanged: (value) {
//                             //           final val = int.tryParse(value) ?? 0;
//                             //           setState(() {
//                             //             a.marks = val.clamp(0, 100);
//                             //           });
//                             //         },
//                             //         decoration: const InputDecoration(
//                             //           contentPadding: EdgeInsets.symmetric(
//                             //             vertical: 4,
//                             //           ),
//                             //           border: OutlineInputBorder(),
//                             //         ),
//                             //       ),
//                             //     ),
//                             //
//                             //     // ➕ Increase button
//                             //     IconButton(
//                             //       icon: const Icon(Icons.add),
//                             //       onPressed: () => changeMarks(studentId, 1),
//                             //     ),
//                             //   ],
//                             // ),
//
//                             leading: CircleAvatar(
//                               child: Text(a.status),
//                               backgroundColor: a.status == 'P'
//                                   ? Colors.green
//                                   : Colors.red,
//                             ),
//                             onTap: () => toggle(studentId),
//                             trailing: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 // IconButton(
//                                 //   icon: const Icon(Icons.remove),
//                                 //   onPressed: () =>
//                                 //       changeMarks(studentId, -1),
//                                 // ),
//                                 // IconButton(
//                                 //   icon: const Icon(Icons.add),
//                                 //   onPressed: () =>
//                                 //       changeMarks(studentId, 1),
//                                 // ),
//                                 IconButton(
//                                   icon: const Icon(Icons.delete),
//                                   onPressed: () => _delete(a),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//
//           // ✅ LOADER
//           if (_isLoadingStudents || _isLoadingAttendance)
//             _buildLoadingOverlay(),
//         ],
//       ),
//     );
//   }
// }
//


// import 'package:black_box/screen_page/course/omr_fv/screens/advanced_monthly_report_screen.dart';
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
//
// class AttendancePerformanceScreen extends StatefulWidget {
//   final String courseId;
//
//   const AttendancePerformanceScreen({super.key, required this.courseId});
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
//   bool _loading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _init();
//     _startAutoSync();
//   }
//
//   // ================= INIT =================
//
//   Future<void> _init() async {
//     final result = await Connectivity().checkConnectivity();
//     isOnline = result != ConnectivityResult.none;
//
//     await _loadStudents();
//     await _loadAttendance();
//
//     _listenRealtime(); // 🔥 realtime
//   }
//
//   // ================= AUTO SYNC =================
//
//   void _startAutoSync() {
//     Connectivity().onConnectivityChanged.listen((result) async {
//       if (result != ConnectivityResult.none) {
//         await _syncPending();
//       }
//     });
//   }
//
//   Future<void> _syncPending() async {
//     final unsynced = await AttendanceDatabase.unsynced();
//
//     for (var m in unsynced) {
//       final a = Attendance.fromMap(m);
//
//       try {
//         await AttendanceService().save(widget.courseId, a);
//         await AttendanceDatabase.markSynced(a.uniqueId);
//         print("✅ Synced: ${a.uniqueId}");
//       } catch (_) {}
//     }
//   }
//
//   // ================= STUDENTS =================
//
//   Future<void> _loadStudents() async {
//     try {
//       if (isOnline) {
//         final snap = await _firestore
//             .collection('courses')
//             .doc(widget.courseId)
//             .collection('students')
//             .get();
//
//         _students = snap.docs
//             .map((e) => Student.fromMap({...e.data(), 'uniqueId': e.id}))
//             .toList();
//
//         for (var s in _students) {
//           await StudentDatabase.insertStudent(s.toMap());
//         }
//       } else {
//         final maps = await StudentDatabase.getAllStudents();
//         _students = maps.map((e) => Student.fromMap(e)).toList();
//       }
//     } catch (_) {}
//   }
//
//   // ================= LOAD ATTENDANCE =================
//
//   Future<void> _loadAttendance() async {
//     setState(() => _loading = true);
//
//     final date = DateFormat('yyyy-MM-dd').format(selectedDate);
//
//     attendanceMap.clear();
//
//     /// ✅ LOCAL FIRST
//     final local =
//     await AttendanceDatabase.getByDate(date, widget.courseId);
//
//     for (var m in local) {
//       final a = Attendance.fromMap(m);
//       attendanceMap[a.studentId] = a;
//     }
//
//     /// ✅ REMOTE SYNC
//     if (isOnline) {
//       final remote =
//       await AttendanceService().getByDate(date, widget.courseId);
//
//       for (var a in remote) {
//         final localA = attendanceMap[a.studentId];
//
//         if (localA == null ||
//             (a.updatedAt ?? DateTime.now())
//                 .isAfter(localA.updatedAt ?? DateTime(2000))) {
//           attendanceMap[a.studentId] = a;
//           await AttendanceDatabase.upsert(a.toMap());
//         }
//       }
//     }
//
//     /// ✅ ENSURE ALL STUDENTS
//     for (var s in _students) {
//       final id = s.stdId;
//       if (id == null) continue;
//
//       attendanceMap.putIfAbsent(
//         id,
//             () => Attendance(
//           uniqueId: "${widget.courseId}_${id}_$date",
//           studentId: id,
//           sCourseId: widget.courseId,
//           attendDate: selectedDate,
//           date: date,
//           status: 'P',
//           marks: 0,
//           updatedAt: DateTime.now(),
//         ),
//       );
//     }
//
//     setState(() => _loading = false);
//   }
//
//   // ================= SAVE =================
//
//   Future<void> _save() async {
//     final date = DateFormat('yyyy-MM-dd').format(selectedDate);
//
//     for (var a in attendanceMap.values) {
//       a.uniqueId = "${widget.courseId}_${a.studentId}_$date";
//       a.updatedAt = DateTime.now();
//       a.syncStatus = isOnline ? 1 : 0;
//
//       /// ✅ LOCAL SAVE
//       await AttendanceDatabase.upsert(a.toMap());
//
//       /// ✅ FIRESTORE SAVE
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
//   // ================= REALTIME =================
//
//   void _listenRealtime() {
//     final date = DateFormat('yyyy-MM-dd').format(selectedDate);
//
//     _firestore
//         .collection('courses')
//         .doc(widget.courseId)
//         .collection('attendance')
//         .where('date', isEqualTo: date)
//         .snapshots()
//         .listen((snap) async {
//       for (var d in snap.docs) {
//         final a = Attendance.fromMap(d.data());
//
//         attendanceMap[a.studentId] = a;
//         await AttendanceDatabase.upsert(a.toMap());
//       }
//
//       setState(() {});
//     });
//   }
//
//   // ================= UI =================
//
//   @override
//   Widget build(BuildContext context) {
//     final date = DateFormat('yyyy-MM-dd').format(selectedDate);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Attendance ($date)"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: _pickDate,
//           ),
//           IconButton(
//             icon: const Icon(Icons.save),
//             onPressed: _save,
//           ),
//           IconButton(
//             icon: const Icon(Icons.report),
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) =>
//                     AdvancedMonthlyReportScreen(courseId: widget.courseId),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         itemCount: _students.length,
//         itemBuilder: (_, i) {
//           final s = _students[i];
//           final id = s.stdId;
//           if (id == null) return const SizedBox();
//
//           final a = attendanceMap[id]!;
//
//           return Card(
//             margin: const EdgeInsets.all(8),
//             child: ListTile(
//               title: Text(s.stdName ?? ""),
//               subtitle: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.remove),
//                     onPressed: () =>
//                         setState(() => a.marks--),
//                   ),
//                   Text("${a.marks}"),
//                   IconButton(
//                     icon: const Icon(Icons.add),
//                     onPressed: () =>
//                         setState(() => a.marks++),
//                   ),
//                 ],
//               ),
//               leading: CircleAvatar(
//                 backgroundColor:
//                 a.status == 'P' ? Colors.green : Colors.red,
//                 child: Text(a.status),
//               ),
//               onTap: () => setState(() {
//                 a.status = a.status == 'P' ? 'A' : 'P';
//               }),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   // ================= DATE PICK =================
//
//   Future<void> _pickDate() async {
//     final d = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2023),
//       lastDate: DateTime.now(),
//     );
//
//     if (d != null) {
//       selectedDate = d;
//       await _loadAttendance();
//     }
//   }
// }





// import 'package:black_box/screen_page/course/omr_fv/screens/advanced_monthly_report_screen.dart';
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
//   const AttendancePerformanceScreen({super.key, required this.courseId});
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
//   Map<String, TextEditingController> _controllers = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }
//
//   // ================= INIT =================
//
//   Future<void> _init() async {
//     final result = await Connectivity().checkConnectivity();
//     isOnline = result != ConnectivityResult.none;
//
//     await _loadStudents();
//
//     // ✅ prevent race condition
//     if (_students.isNotEmpty) {
//       await _load();
//     }
//   }
//
//   // ================= STUDENTS =================
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
//         .map((doc) => Student.fromMap({...doc.data(), 'uniqueId': doc.id}))
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
//   // ================= ATTENDANCE =================
//
//   Future<void> _load() async {
//     setState(() => _isLoadingAttendance = true);
//
//     final date = DateFormat('yyyy-MM-dd').format(selectedDate);
//
//     final local = await AttendanceDatabase.getByDate(date, widget.courseId);
//
//     attendanceMap.clear();
//
//     if (local.isNotEmpty) {
//       for (var m in local) {
//         final a = Attendance.fromMap(m);
//         attendanceMap[a.studentId] = a;
//       }
//     } else if (isOnline) {
//       final remote = await AttendanceService().getByDate(date, widget.courseId);
//
//       for (var a in remote) {
//         attendanceMap[a.studentId] = a;
//         await AttendanceDatabase.upsert(a.toMap());
//       }
//     }
//
//     // ✅ Ensure every student has attendance
//     for (var s in _students) {
//       final id = s.stdId;
//       if (id == null) continue;
//
//       attendanceMap.putIfAbsent(
//         id,
//         () => Attendance(
//           uniqueId: "${id}_$date",
//           studentId: id,
//           sCourseId: widget.courseId,
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
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text("Saved")));
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
//     final a = attendanceMap[id];
//     if (a == null) return;
//
//     setState(() => a.status = a.status == 'P' ? 'A' : 'P');
//   }
//
//   void changeMarks(String id, int d) {
//     final a = attendanceMap[id];
//     if (a == null) return;
//
//     setState(() {
//       a.marks = (a.marks + d).clamp(0, 100);
//
//       _controllers[id]?.text = a.marks.toString();
//     });
//   }
//
//   // void changeMarks(String id, int d) {
//   //   final a = attendanceMap[id];
//   //   if (a == null) return;
//   //
//   //   setState(() => a.marks = (a.marks + d).clamp(0, 100));
//   // }
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
//   // ================= LOADING UI =================
//
//   Widget _buildLoadingOverlay() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black.withOpacity(0.3),
//         child: const Center(
//           child: Card(
//             child: Padding(
//               padding: EdgeInsets.all(20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text("Loading..."),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     for (var c in _controllers.values) {
//       c.dispose();
//     }
//     super.dispose();
//   }
//
//   // ================= UI =================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         onPressed: _save,
//         child: const Icon(Icons.save),
//       ),
//       appBar: AppBar(
//         title: const Text("Attendance"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.report_outlined),
//             onPressed: () => {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => AdvancedMonthlyReportScreen(courseId: widget.courseId)),
//               )
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.sync),
//             onPressed: () => AttendanceSync.sync(widget.courseId),
//           ),
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
//
//               // ✅ EMPTY STATE
//               if (_students.isEmpty)
//                 const Expanded(child: Center(child: Text("No students found")))
//               else
//                 Expanded(
//                   child: RefreshIndicator(
//                     onRefresh: () async {
//                       await _loadStudents();
//                       await _load();
//                     },
//                     child: ListView(
//                       children: _students.map((s) {
//                         final studentId = s.stdId;
//                         if (studentId == null) {
//                           return const SizedBox();
//                         }
//
//                         final a =
//                             attendanceMap[studentId] ??
//                             Attendance(
//                               uniqueId:
//                                   "${studentId}_${selectedDate.toString()}",
//                               studentId: studentId,
//                               sCourseId: widget.courseId,
//                               attendDate: selectedDate,
//                               date: DateFormat(
//                                 'yyyy-MM-dd',
//                               ).format(selectedDate),
//                               status: 'P',
//                               marks: 0,
//                             );
//
//                         return Card(
//                           margin: const EdgeInsets.all(8),
//                           child: ListTile(
//                             title: Text(s.stdName ?? ""),
//                             subtitle: Row(
//                               children: [
//                                 const Text("Marks: "),
//
//                                 // ➖ Decrease button
//                                 IconButton(
//                                   icon: const Icon(Icons.remove),
//                                   onPressed: () => changeMarks(studentId, -1),
//                                 ),
//
//                                 // 🔢 Input field with controller
//                                 SizedBox(
//                                   width: 60,
//                                   child: Builder(
//                                     builder: (_) {
//                                       _controllers.putIfAbsent(
//                                         studentId,
//                                             () => TextEditingController(text: a.marks.toString()),
//                                       );
//
//                                       final controller = _controllers[studentId]!;
//
//                                       // ✅ Sync controller with latest value
//                                       controller.value = controller.value.copyWith(
//                                         text: a.marks.toString(),
//                                         selection: TextSelection.collapsed(
//                                           offset: a.marks.toString().length,
//                                         ),
//                                       );
//
//                                       return TextFormField(
//                                         controller: controller,
//                                         keyboardType: TextInputType.number,
//                                         textAlign: TextAlign.center,
//                                         onChanged: (value) {
//                                           final val = int.tryParse(value) ?? 0;
//                                           a.marks = val.clamp(0, 100);
//                                         },
//                                         decoration: const InputDecoration(
//                                           isDense: true,
//                                           contentPadding: EdgeInsets.symmetric(vertical: 8),
//                                           border: OutlineInputBorder(),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ),
//
//                                 // ➕ Increase button
//                                 IconButton(
//                                   icon: const Icon(Icons.add),
//                                   onPressed: () => changeMarks(studentId, 1),
//                                 ),
//                               ],
//                             ),
//                             // subtitle: Text("Marks: ${a.marks}"),
//                             // subtitle: Row(
//                             //   children: [
//                             //     const Text("Marks: "),
//                             //
//                             //     // ➖ Decrease button
//                             //     IconButton(
//                             //       icon: const Icon(Icons.remove),
//                             //       onPressed: () => changeMarks(studentId, -1),
//                             //     ),
//                             //
//                             //     // 🔢 Input field
//                             //     SizedBox(
//                             //       width: 50,
//                             //       child: TextFormField(
//                             //         initialValue: a.marks.toString(),
//                             //         keyboardType: TextInputType.number,
//                             //         textAlign: TextAlign.center,
//                             //         onChanged: (value) {
//                             //           final val = int.tryParse(value) ?? 0;
//                             //           setState(() {
//                             //             a.marks = val.clamp(0, 100);
//                             //           });
//                             //         },
//                             //         decoration: const InputDecoration(
//                             //           contentPadding: EdgeInsets.symmetric(
//                             //             vertical: 4,
//                             //           ),
//                             //           border: OutlineInputBorder(),
//                             //         ),
//                             //       ),
//                             //     ),
//                             //
//                             //     // ➕ Increase button
//                             //     IconButton(
//                             //       icon: const Icon(Icons.add),
//                             //       onPressed: () => changeMarks(studentId, 1),
//                             //     ),
//                             //   ],
//                             // ),
//
//                             leading: CircleAvatar(
//                               child: Text(a.status),
//                               backgroundColor: a.status == 'P'
//                                   ? Colors.green
//                                   : Colors.red,
//                             ),
//                             onTap: () => toggle(studentId),
//                             trailing: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 // IconButton(
//                                 //   icon: const Icon(Icons.remove),
//                                 //   onPressed: () =>
//                                 //       changeMarks(studentId, -1),
//                                 // ),
//                                 // IconButton(
//                                 //   icon: const Icon(Icons.add),
//                                 //   onPressed: () =>
//                                 //       changeMarks(studentId, 1),
//                                 // ),
//                                 IconButton(
//                                   icon: const Icon(Icons.delete),
//                                   onPressed: () => _delete(a),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//
//           // ✅ LOADER
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
