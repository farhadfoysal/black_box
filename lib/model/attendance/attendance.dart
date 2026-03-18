class Attendance {
  int? _id;
  String _uniqueId;
  String _studentId;
  String _sCourseId;
  DateTime _attendDate;
  String _date;
  String _status; // P / A
  int _marks; // ✅ FIXED
  int? _syncStatus;


  Attendance({
    int? id,
    required String uniqueId,
    required String studentId,
    required String sCourseId,
    required DateTime attendDate,
    required String date,
    required String status,
    int marks = 0, // ✅ default
    int? syncStatus,
  })  : _id = id,
        _uniqueId = uniqueId,
        _studentId = studentId,
        _sCourseId = sCourseId,
        _attendDate = attendDate,
        _date = date,
        _status = status,
        _marks = marks,
        _syncStatus = syncStatus;

  // Getters
  int? get id => _id;
  String get uniqueId => _uniqueId;
  String get studentId => _studentId;
  String get sCourseId => _sCourseId;
  DateTime get attendDate => _attendDate;
  String get date => _date;
  String get status => _status;
  int get marks => _marks;

  // Setters
  set id(int? id) => _id = id;
  set uniqueId(String v) => _uniqueId = v;
  set studentId(String v) => _studentId = v;
  set sCourseId(String v) => _sCourseId = v;
  set attendDate(DateTime v) => _attendDate = v;
  set date(String v) => _date = v;
  set status(String v) => _status = v;
  set marks(int v) => _marks = v;
  set syncStatus(int v) => _syncStatus = v;

  // Map
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'student_id': _studentId,
      'sCourseId': _sCourseId,
      'attend_date': _attendDate.toIso8601String(),
      'date': _date,
      'status': _status,
      'marks': _marks, // ✅ added
      'sync_status': _syncStatus,
    };
  }

  // From Map
  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      uniqueId: map['unique_id'] ?? '',
      studentId: map['student_id'] ?? '',
      sCourseId: map['sCourseId'] ?? '',
      attendDate: map['attend_date'] != null
          ? DateTime.parse(map['attend_date'])
          : DateTime.now(),
      date: map['date'] ?? '',
      status: map['status'] ?? 'P',
      marks: map['marks'] ?? 0,
      syncStatus: map['sync_status'],
    );
  }
}