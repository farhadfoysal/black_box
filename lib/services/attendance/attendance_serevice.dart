import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/attendance/attendance.dart';


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