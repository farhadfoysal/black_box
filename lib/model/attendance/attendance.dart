// ============================================================
// attendance.dart  — clean, immutable-friendly model
// ============================================================

class Attendance {
  int? id;
  String uniqueId;
  String studentId;
  String sCourseId;
  DateTime attendDate;
  String date;
  String status; // 'P' | 'A'
  int marks;
  int syncStatus; // 0=pending  1=synced  2=deleted

  Attendance({
    this.id,
    required this.uniqueId,
    required this.studentId,
    required this.sCourseId,
    required this.attendDate,
    required this.date,
    required this.status,
    this.marks = 0,
    this.syncStatus = 0,
  });

  // ── factory ────────────────────────────────────────────────
  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] as int?,
      uniqueId: (map['unique_id'] as String?) ?? '',
      studentId: (map['student_id'] as String?) ?? '',
      sCourseId: (map['sCourseId'] as String?) ?? '',
      attendDate: map['attend_date'] != null
          ? DateTime.parse(map['attend_date'] as String)
          : DateTime.now(),
      date: (map['date'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'P',
      marks: (map['marks'] as int?) ?? 0,
      syncStatus: (map['sync_status'] as int?) ?? 0,
    );
  }

  // ── serialise ──────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'unique_id': uniqueId,
    'student_id': studentId,
    'sCourseId': sCourseId,
    'attend_date': attendDate.toIso8601String(),
    'date': date,
    'status': status,
    'marks': marks,
    'sync_status': syncStatus,
  };

  // ── helpers ────────────────────────────────────────────────
  static String generateId(
      String courseId, String studentId, String date) =>
      '${courseId}_${studentId}_$date';

  Attendance copyWith({
    int? id,
    String? uniqueId,
    String? studentId,
    String? sCourseId,
    DateTime? attendDate,
    String? date,
    String? status,
    int? marks,
    int? syncStatus,
  }) =>
      Attendance(
        id: id ?? this.id,
        uniqueId: uniqueId ?? this.uniqueId,
        studentId: studentId ?? this.studentId,
        sCourseId: sCourseId ?? this.sCourseId,
        attendDate: attendDate ?? this.attendDate,
        date: date ?? this.date,
        status: status ?? this.status,
        marks: marks ?? this.marks,
        syncStatus: syncStatus ?? this.syncStatus,
      );
}


// class Attendance {
//   int? _id;
//   String _uniqueId;
//   String _studentId;
//   String _sCourseId;
//   DateTime _attendDate;
//   String _date;
//   String _status; // P / A
//   int _marks; // ✅ FIXED
//   int? _syncStatus;
//
//
//   Attendance({
//     int? id,
//     required String uniqueId,
//     required String studentId,
//     required String sCourseId,
//     required DateTime attendDate,
//     required String date,
//     required String status,
//     int marks = 0, // ✅ default
//     int? syncStatus,
//   })  : _id = id,
//         _uniqueId = uniqueId,
//         _studentId = studentId,
//         _sCourseId = sCourseId,
//         _attendDate = attendDate,
//         _date = date,
//         _status = status,
//         _marks = marks,
//         _syncStatus = syncStatus;
//
//   // Getters
//   int? get id => _id;
//   String get uniqueId => _uniqueId;
//   String get studentId => _studentId;
//   String get sCourseId => _sCourseId;
//   DateTime get attendDate => _attendDate;
//   String get date => _date;
//   String get status => _status;
//   int get marks => _marks;
//
//   // Setters
//   set id(int? id) => _id = id;
//   set uniqueId(String v) => _uniqueId = v;
//   set studentId(String v) => _studentId = v;
//   set sCourseId(String v) => _sCourseId = v;
//   set attendDate(DateTime v) => _attendDate = v;
//   set date(String v) => _date = v;
//   set status(String v) => _status = v;
//   set marks(int v) => _marks = v;
//   set syncStatus(int v) => _syncStatus = v;
//
//   // Map
//   Map<String, dynamic> toMap() {
//     return {
//       'id': _id,
//       'unique_id': _uniqueId,
//       'student_id': _studentId,
//       'sCourseId': _sCourseId,
//       'attend_date': _attendDate.toIso8601String(),
//       'date': _date,
//       'status': _status,
//       'marks': _marks, // ✅ added
//       'sync_status': _syncStatus,
//     };
//   }
//
//   // From Map
//   factory Attendance.fromMap(Map<String, dynamic> map) {
//     return Attendance(
//       id: map['id'],
//       uniqueId: map['unique_id'] ?? '',
//       studentId: map['student_id'] ?? '',
//       sCourseId: map['sCourseId'] ?? '',
//       attendDate: map['attend_date'] != null
//           ? DateTime.parse(map['attend_date'])
//           : DateTime.now(),
//       date: map['date'] ?? '',
//       status: map['status'] ?? 'P',
//       marks: map['marks'] ?? 0,
//       syncStatus: map['sync_status'],
//     );
//   }
//
//   static String generateId(String courseId, String studentId, String date) {
//     return "${courseId}_${studentId}_$date";
//   }
//
// }