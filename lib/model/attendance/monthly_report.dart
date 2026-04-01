class MonthlyReport {
  String _id;
  String _name;

  int _totalClasses;
  int _present;
  int _absent;
  double _attendancePercent;
  double _avgMarks;

  // ================= CONSTRUCTOR =================

  MonthlyReport({
    required String id,
    required String name,
    int totalClasses = 0,
    int present = 0,
    int absent = 0,
    double attendancePercent = 0,
    double avgMarks = 0,
  })  : _id = id,
        _name = name,
        _totalClasses = totalClasses,
        _present = present,
        _absent = absent,
        _attendancePercent = attendancePercent,
        _avgMarks = avgMarks;

  // ================= GETTERS =================

  String get id => _id;
  String get name => _name;

  int get totalClasses => _totalClasses;
  int get present => _present;
  int get absent => _absent;
  double get attendancePercent => _attendancePercent;
  double get avgMarks => _avgMarks;

  // ================= SETTERS =================

  set id(String value) => _id = value;
  set name(String value) => _name = value;

  set totalClasses(int value) => _totalClasses = value;
  set present(int value) => _present = value;
  set absent(int value) => _absent = value;
  set attendancePercent(double value) => _attendancePercent = value;
  set avgMarks(double value) => _avgMarks = value;

  // ================= MAP =================

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'name': _name,
      'total_classes': _totalClasses,
      'present': _present,
      'absent': _absent,
      'attendance_percent': _attendancePercent,
      'avg_marks': _avgMarks,
    };
  }

  factory MonthlyReport.fromMap(Map<String, dynamic> map) {
    return MonthlyReport(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      totalClasses: map['total_classes'] ?? 0,
      present: map['present'] ?? 0,
      absent: map['absent'] ?? 0,
      attendancePercent:
      (map['attendance_percent'] as num?)?.toDouble() ?? 0.0,
      avgMarks:
      (map['avg_marks'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ================= JSON =================

  Map<String, dynamic> toJson() => toMap();

  factory MonthlyReport.fromJson(Map<String, dynamic> json) =>
      MonthlyReport.fromMap(json);

  // ================= HELPER =================

  void calculate() {
    if (_totalClasses > 0) {
      _attendancePercent = (_present / _totalClasses) * 100;
      _avgMarks = _avgMarks / _totalClasses;
    }
  }
}


// class MonthlyReport {
//   final String id; // studentId OR courseId
//   final String name;
//
//   final int totalClasses;
//   final int present;
//   final int absent;
//   final double attendancePercent;
//   final double avgMarks;
//
//   MonthlyReport({
//     required this.id,
//     required this.name,
//     required this.totalClasses,
//     required this.present,
//     required this.absent,
//     required this.attendancePercent,
//     required this.avgMarks,
//   });
//
//   List<MonthlyReport> mapStudentReports(
//       List<Map<String, dynamic>> data,
//       Map<String, String> studentNames) {
//
//     return data.map((e) {
//       final total = e['total_classes'] ?? 0;
//       final present = e['present'] ?? 0;
//       final absent = e['absent'] ?? 0;
//
//       return MonthlyReport(
//         id: e['student_id'],
//         name: studentNames[e['student_id']] ?? "Unknown",
//         totalClasses: total,
//         present: present,
//         absent: absent,
//         attendancePercent:
//         total == 0 ? 0 : (present / total) * 100,
//         avgMarks: (e['avg_marks'] ?? 0).toDouble(),
//       );
//     }).toList();
//   }
//
// }


// ============================================================
// monthly_report.dart
// ============================================================

// class MonthlyReport {
//   final String id;
//   final String name;
//   int totalClasses;
//   int present;
//   int absent;
//   double attendancePercent;
//   double avgMarks;
//
//   MonthlyReport({
//     required this.id,
//     required this.name,
//     required this.totalClasses,
//     required this.present,
//     required this.absent,
//     required this.attendancePercent,
//     required this.avgMarks,
//   });
// }