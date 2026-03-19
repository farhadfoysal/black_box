import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/attendance/attendance.dart';
import '../../model/attendance/monthly_report.dart';


class AttendanceService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference _ref(String courseId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('attendance');
  }

  // CREATE / UPDATE
  Future<void> save(String courseId, Attendance a) async {
    await _ref(courseId).doc(a.uniqueId).set(a.toMap());
  }

  // READ
  Future<List<Attendance>> getByDate(
       String date, String courseId) async {
    final res = await _ref(courseId)
        .where('date', isEqualTo: date)
        .where('sCourseId', isEqualTo: courseId)
        .get();

    return res.docs.map((e) => Attendance.fromMap(e.data() as Map<String, dynamic>)).toList();
  }

  // DELETE
  Future<void> delete(String courseId, String id) async {
    await _ref(courseId).doc(id).delete();
  }

  Future<List<Attendance>> getByMonth(
      String courseId, String month) async {
    final start = "$month-01";
    final end = "$month-31";

    final res = await _ref(courseId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();

    return res.docs
        .map((e) => Attendance.fromMap(e.data() as Map<String, dynamic>))
        .toList();
  }

  Map<String, MonthlyReport> buildStudentReport(
      List<Attendance> list,
      Map<String, String> studentNames) {

    final Map<String, MonthlyReport> report = {};

    for (var a in list) {
      final id = a.studentId;

      if (!report.containsKey(id)) {
        report[id] = MonthlyReport(
          id: id,
          name: studentNames[id] ?? "Unknown",
          totalClasses: 0,
          present: 0,
          absent: 0,
          attendancePercent: 0,
          avgMarks: 0,
        );
      }

      final r = report[id]!;

      r.totalClasses++;
      if (a.status == 'P') {
        r.present++;
      } else {
        r.absent++;
      }

      r.avgMarks += a.marks;
    }

    // finalize
    report.forEach((key, r) {
      if (r.totalClasses > 0) {
        r.attendancePercent =
            (r.present / r.totalClasses) * 100;
        r.avgMarks = r.avgMarks / r.totalClasses;
      }
    });

    return report;
  }

  MonthlyReport buildCourseReport(List<Attendance> list) {
    int total = list.length;
    int present = 0;
    int absent = 0;
    double marks = 0;

    for (var a in list) {
      if (a.status == 'P') present++;
      else absent++;

      marks += a.marks;
    }

    return MonthlyReport(
      id: "course",
      name: "Course Summary",
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