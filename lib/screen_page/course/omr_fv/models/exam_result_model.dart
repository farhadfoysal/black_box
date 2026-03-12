import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class ExamResult {
  final String id;
  final String studentId;
  final String schoolId;
  final String omrSheetId;
  final String studentName;
  final String examName;
  final List<String> studentAnswers;
  final List<String> correctAnswers;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int unansweredCount;
  final double percentage;
  final DateTime scannedAt;
  final String? scannedImagePath;

  ExamResult({
    required this.id,
    required this.studentId,
    required this.schoolId,
    required this.omrSheetId,
    required this.studentName,
    required this.examName,
    required this.studentAnswers,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.unansweredCount,
    required this.percentage,
    required this.scannedAt,
    this.scannedImagePath,
  });

  // ================= JSON (Firebase/API) =================

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'schoolId': schoolId,
    'omrSheetId': omrSheetId,
    'studentName': studentName,
    'examName': examName,
    'studentAnswers': studentAnswers,
    'correctAnswers': correctAnswers,
    'totalQuestions': totalQuestions,
    'correctCount': correctCount,
    'wrongCount': wrongCount,
    'unansweredCount': unansweredCount,
    'percentage': percentage,
    'scannedAt': scannedAt.toIso8601String(),
    'scannedImagePath': scannedImagePath,
  };

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
    id: json['id'],
    studentId: json['studentId'],
    schoolId: json['schoolId'],
    omrSheetId: json['omrSheetId'],
    studentName: json['studentName'],
    examName: json['examName'],
    studentAnswers: List<String>.from(json['studentAnswers']),
    correctAnswers: List<String>.from(json['correctAnswers']),
    totalQuestions: json['totalQuestions'],
    correctCount: json['correctCount'],
    wrongCount: json['wrongCount'],
    unansweredCount: json['unansweredCount'],
    percentage: json['percentage'].toDouble(),
    scannedAt: DateTime.parse(json['scannedAt']),
    scannedImagePath: json['scannedImagePath'],
  );

  // ================= SQLite (Map) =================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'schoolId': schoolId,
      'omrSheetId': omrSheetId,
      'studentName': studentName,
      'examName': examName,
      'studentAnswers': jsonEncode(studentAnswers),
      'correctAnswers': jsonEncode(correctAnswers),
      'totalQuestions': totalQuestions,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'unansweredCount': unansweredCount,
      'percentage': percentage,
      'scannedAt': scannedAt.toIso8601String(),
      'scannedImagePath': scannedImagePath,
    };
  }

  factory ExamResult.fromMap(Map<String, dynamic> map) {

    DateTime parsedDate;

    final scannedAtValue = map['scannedAt'];

    if (scannedAtValue is String) {
      parsedDate = DateTime.parse(scannedAtValue);
    } else if (scannedAtValue is Timestamp) {
      parsedDate = scannedAtValue.toDate();
    } else {
      parsedDate = DateTime.now();
    }

    return ExamResult(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      schoolId: map['schoolId'] ?? '',
      omrSheetId: map['omrSheetId'] ?? '',
      studentName: map['studentName'] ?? '',
      examName: map['examName'] ?? '',

      studentAnswers: map['studentAnswers'] == null
          ? []
          : (map['studentAnswers'] is String
          ? List<String>.from(jsonDecode(map['studentAnswers']))
          : List<String>.from(map['studentAnswers'])),

      correctAnswers: map['correctAnswers'] == null
          ? []
          : (map['correctAnswers'] is String
          ? List<String>.from(jsonDecode(map['correctAnswers']))
          : List<String>.from(map['correctAnswers'])),

      totalQuestions: map['totalQuestions'] ?? 0,
      correctCount: map['correctCount'] ?? 0,
      wrongCount: map['wrongCount'] ?? 0,
      unansweredCount: map['unansweredCount'] ?? 0,

      percentage: (map['percentage'] ?? 0).toDouble(),

      scannedAt: parsedDate,

      scannedImagePath: map['scannedImagePath'],
    );
  }

  // factory ExamResult.fromMap(Map<String, dynamic> map) {
  //
  //   DateTime parsedDate;
  //
  //   if (map['scannedAt'] is String) {
  //     parsedDate = DateTime.parse(map['scannedAt']);
  //   } else if (map['scannedAt'] is Timestamp) {
  //     parsedDate = map['scannedAt'].toDate();
  //   } else {
  //     parsedDate = DateTime.now();
  //   }
  //
  //   return ExamResult(
  //     id: map['id'],
  //     studentId: map['studentId'],
  //     schoolId: map['schoolId'],
  //     omrSheetId: map['omrSheetId'],
  //     studentName: map['studentName'],
  //     examName: map['examName'],
  //     studentAnswers: List<String>.from(jsonDecode(map['studentAnswers'])),
  //     correctAnswers: List<String>.from(jsonDecode(map['correctAnswers'])),
  //     totalQuestions: map['totalQuestions'],
  //     correctCount: map['correctCount'],
  //     wrongCount: map['wrongCount'],
  //     unansweredCount: map['unansweredCount'],
  //     percentage: (map['percentage'] as num).toDouble(),
  //     scannedAt: parsedDate,
  //     scannedImagePath: map['scannedImagePath'],
  //   );
  // }

  // factory ExamResult.fromMap(Map<String, dynamic> map) {
  //
  //   DateTime parsedDate;
  //
  //   if (map['scannedAt'] is String) {
  //     parsedDate = DateTime.parse(map['scannedAt']);
  //   } else if (map['scannedAt'] is Timestamp) {
  //     parsedDate = map['scannedAt'].toDate();
  //   } else {
  //     parsedDate = DateTime.now();
  //   }
  //
  //   return ExamResult(
  //     id: map['id'],
  //     studentId: map['studentId'],
  //     omrSheetId: map['omrSheetId'],
  //     studentName: map['studentName'],
  //     examName: map['examName'],
  //     studentAnswers: List<String>.from(jsonDecode(map['studentAnswers'])),
  //     correctAnswers: List<String>.from(jsonDecode(map['correctAnswers'])),
  //     totalQuestions: map['totalQuestions'],
  //     correctCount: map['correctCount'],
  //     wrongCount: map['wrongCount'],
  //     unansweredCount: map['unansweredCount'],
  //     percentage: (map['percentage'] as num).toDouble(),
  //     scannedAt: parsedDate,
  //     scannedImagePath: map['scannedImagePath'],
  //   );
  // }

}