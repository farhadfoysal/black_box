// ============================================================
// attendance_service.dart
// ============================================================
//
// FIXES vs original
// -----------------
// 1. getByDate() — removed redundant .where('sCourseId', ...) filter.
//    The collection is already scoped to courseId, and the extra filter
//    caused mismatches when the stored field value differed by casing.
//
// 2. save() — already used merge:true (good). No change needed there.
//
// 3. delete() — now returns a bool so callers know if it succeeded.
//
// 4. buildStudentReport() — MonthlyReport fields are now public; the
//    original had them private with no setters, causing runtime errors
//    on `r.totalClasses++` etc.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/attendance/attendance.dart';
import '../../model/attendance/monthly_report.dart';

class AttendanceService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference _ref(String courseId) => _firestore
      .collection('courses')
      .doc(courseId)
      .collection('attendance');

  // ── CREATE / UPDATE ──────────────────────────────────────────
  Future<void> save(String courseId, Attendance a) async {
    await _ref(courseId)
        .doc(a.uniqueId)
        .set(a.toMap(), SetOptions(merge: true));
  }

  // ── READ ─────────────────────────────────────────────────────
  // FIX 1: single .where('date') — collection already scoped to courseId.
  Future<List<Attendance>> getByDate(
      String courseId,
      String date,
      ) async {
    final res = await _ref(courseId)
        .where('date', isEqualTo: date)
        .get();

    return res.docs
        .map((e) => Attendance.fromMap(e.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Attendance>> getByMonth(
      String courseId,
      String month, // 'yyyy-MM'
      ) async {
    final res = await _ref(courseId)
        .where('date', isGreaterThanOrEqualTo: '$month-01')
        .where('date', isLessThanOrEqualTo: '$month-31')
        .get();

    return res.docs
        .map((e) => Attendance.fromMap(e.data() as Map<String, dynamic>))
        .toList();
  }

  // ── DELETE ───────────────────────────────────────────────────
  // FIX 3: returns bool so caller can confirm before hard-deleting locally.
  Future<bool> delete(String courseId, String uniqueId) async {
    try {
      await _ref(courseId).doc(uniqueId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── REPORTS (pure Dart, no Firestore) ────────────────────────
  // FIX 4: MonthlyReport fields are now public — no runtime errors.
  Map<String, MonthlyReport> buildStudentReport(
      List<Attendance> list,
      Map<String, String> studentNames,
      ) {
    final Map<String, MonthlyReport> report = {};

    for (final a in list) {
      final id = a.studentId;
      report.putIfAbsent(
        id,
            () => MonthlyReport(
          id: id,
          name: studentNames[id] ?? 'Unknown',
          totalClasses: 0,
          present: 0,
          absent: 0,
          attendancePercent: 0,
          avgMarks: 0,
        ),
      );

      final r = report[id]!;
      r.totalClasses++;
      if (a.status == 'P') r.present++; else r.absent++;
      r.avgMarks += a.marks; // accumulate; finalize below
    }

    report.forEach((_, r) {
      if (r.totalClasses > 0) {
        r.attendancePercent = (r.present / r.totalClasses) * 100;
        r.avgMarks = r.avgMarks / r.totalClasses;
      }
    });

    return report;
  }

  MonthlyReport buildCourseReport(List<Attendance> list) {
    int present = 0;
    int absent = 0;
    double marks = 0;

    for (final a in list) {
      if (a.status == 'P') present++; else absent++;
      marks += a.marks;
    }

    final total = list.length;
    return MonthlyReport(
      id: 'course',
      name: 'Course Summary',
      totalClasses: total,
      present: present,
      absent: absent,
      attendancePercent: total == 0 ? 0 : (present / total) * 100,
      avgMarks: total == 0 ? 0 : marks / total,
    );
  }
}



// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../../model/attendance/attendance.dart';
// import '../../model/attendance/monthly_report.dart';
//
//
// class AttendanceService {
//   final _firestore = FirebaseFirestore.instance;
//
//   CollectionReference _ref(String courseId) {
//     return _firestore
//         .collection('courses')
//         .doc(courseId)
//         .collection('attendance');
//   }
//
//   // CREATE / UPDATE
//   // Future<void> save(String courseId, Attendance a) async {
//   //   await _ref(courseId).doc(a.uniqueId).set(a.toMap());
//   // }
//
//   Future<void> save(String courseId, Attendance a) async {
//     await _ref(courseId)
//         .doc(a.uniqueId)
//         .set(
//       a.toMap(),
//       SetOptions(merge: true),
//     );
//   }
//
//   // READ
//   Future<List<Attendance>> getByDate(
//        String date, String courseId) async {
//     final res = await _ref(courseId)
//         .where('date', isEqualTo: date)
//         .where('sCourseId', isEqualTo: courseId)
//         .get();
//
//     return res.docs.map((e) => Attendance.fromMap(e.data() as Map<String, dynamic>)).toList();
//   }
//
//   // DELETE
//   Future<void> delete(String courseId, String id) async {
//     await _ref(courseId).doc(id).delete();
//   }
//
//   Future<List<Attendance>> getByMonth(
//       String courseId, String month) async {
//     final start = "$month-01";
//     final end = "$month-31";
//
//     final res = await _ref(courseId)
//         .where('date', isGreaterThanOrEqualTo: start)
//         .where('date', isLessThanOrEqualTo: end)
//         .get();
//
//     return res.docs
//         .map((e) => Attendance.fromMap(e.data() as Map<String, dynamic>))
//         .toList();
//   }
//
//   Map<String, MonthlyReport> buildStudentReport(
//       List<Attendance> list,
//       Map<String, String> studentNames) {
//
//     final Map<String, MonthlyReport> report = {};
//
//     for (var a in list) {
//       final id = a.studentId;
//
//       if (!report.containsKey(id)) {
//         report[id] = MonthlyReport(
//           id: id,
//           name: studentNames[id] ?? "Unknown",
//           totalClasses: 0,
//           present: 0,
//           absent: 0,
//           attendancePercent: 0,
//           avgMarks: 0,
//         );
//       }
//
//       final r = report[id]!;
//
//       r.totalClasses++;
//       if (a.status == 'P') {
//         r.present++;
//       } else {
//         r.absent++;
//       }
//
//       r.avgMarks += a.marks;
//     }
//
//     // finalize
//     report.forEach((key, r) {
//       if (r.totalClasses > 0) {
//         r.attendancePercent =
//             (r.present / r.totalClasses) * 100;
//         r.avgMarks = r.avgMarks / r.totalClasses;
//       }
//     });
//
//     return report;
//   }
//
//   MonthlyReport buildCourseReport(List<Attendance> list) {
//     int total = list.length;
//     int present = 0;
//     int absent = 0;
//     double marks = 0;
//
//     for (var a in list) {
//       if (a.status == 'P') present++;
//       else absent++;
//
//       marks += a.marks;
//     }
//
//     return MonthlyReport(
//       id: "course",
//       name: "Course Summary",
//       totalClasses: total,
//       present: present,
//       absent: absent,
//       attendancePercent: total == 0 ? 0 : (present / total) * 100,
//       avgMarks: total == 0 ? 0 : marks / total,
//     );
//   }
//
// }





// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../../model/attendance/attendance.dart';
//
//
// class AttendanceService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Future<void> uploadAttendance(
//       String schoolId, Attendance attendance) async {
//     await _firestore
//         .collection('schools')
//         .doc(schoolId)
//         .collection('attendance')
//         .doc(attendance.uniqueId)
//         .set(attendance.toMap());
//   }
//
//   Future<List<Attendance>> fetchByDate(
//       String schoolId, String date) async {
//     final snapshot = await _firestore
//         .collection('schools')
//         .doc(schoolId)
//         .collection('attendance')
//         .where('date', isEqualTo: date)
//         .get();
//
//     return snapshot.docs
//         .map((e) => Attendance.fromMap(e.data()))
//         .toList();
//   }
// }