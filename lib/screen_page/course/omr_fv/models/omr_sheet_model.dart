import 'package:flutter/foundation.dart';

class OMRSheet {
  final String id;
  final String examName;
  final String courseId;
  final String subjectName;
  final int setNumber;
  final int numberOfQuestions;
  final List<String> correctAnswers;
  final DateTime createdAt;
  final DateTime examDate;
  final String? description;
  final bool isActive;

  OMRSheet({
    required this.id,
    required this.examName,
    required this.courseId,
    required this.subjectName,
    required this.setNumber,
    required this.numberOfQuestions,
    required this.correctAnswers,
    required this.createdAt,
    required this.examDate,
    this.description,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'examName': examName,
    'courseId': courseId,
    'subjectName': subjectName,
    'setNumber': setNumber,
    'numberOfQuestions': numberOfQuestions,
    'correctAnswers': correctAnswers,
    'createdAt': createdAt.toIso8601String(),
    'examDate': examDate.toIso8601String(),
    'description': description,
    'isActive': isActive,
  };

  factory OMRSheet.fromJson(Map<String, dynamic> json) => OMRSheet(
    id: json['id'],
    examName: json['examName'],
    courseId: json['courseId'],
    subjectName: json['subjectName'],
    setNumber: json['setNumber'],
    numberOfQuestions: json['numberOfQuestions'],
    correctAnswers: List<String>.from(json['correctAnswers']),
    createdAt: DateTime.parse(json['createdAt']),
    examDate: DateTime.parse(json['examDate']),
    description: json['description'],
    isActive: json['isActive'] ?? true,
  );

  OMRSheet copyWith({
    String? examName,
    String? courseId,
    String? subjectName,
    int? setNumber,
    int? numberOfQuestions,
    List<String>? correctAnswers,
    DateTime? examDate,
    String? description,
    bool? isActive,
  }) {
    return OMRSheet(
      id: id,
      examName: examName ?? this.examName,
      courseId: courseId ?? this.courseId,
      subjectName: subjectName ?? this.subjectName,
      setNumber: setNumber ?? this.setNumber,
      numberOfQuestions: numberOfQuestions ?? this.numberOfQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      createdAt: createdAt,
      examDate: examDate ?? this.examDate,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}