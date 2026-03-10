import 'dart:convert';

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
  String? syncKey;
  String? key;
  int? syncStatus;
  String? uniqueId;
  String? uId;
  String? sId;

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
    this.syncKey,
    this.syncStatus,
    this.key,
    this.sId,
    this.uId,
    this.uniqueId,
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
    'syncKey': syncKey,
    'syncStatus': syncStatus,
    'key': key,
    'sId': sId,
    'uId': uId,
    'uniqueId': uniqueId,
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
    syncKey: json['syncKey'],
    syncStatus: json['syncStatus'],
    key: json['key'],
    sId: json['sId'],
    uId: json['uId'],
    uniqueId: json['uniqueId'],
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examName': examName,
      'courseId': courseId,
      'subjectName': subjectName,
      'setNumber': setNumber,
      'numberOfQuestions': numberOfQuestions,
      'correctAnswers': jsonEncode(correctAnswers),
      'createdAt': createdAt.toIso8601String(),
      'examDate': examDate.toIso8601String(),
      'description': description,
      'isActive': isActive ? 1 : 0,
      'syncKey': syncKey,
      'syncStatus': syncStatus,
      'key': key,
      'sId': sId,
      'uId': uId,
      'uniqueId': uniqueId,
    };
  }

  factory OMRSheet.fromMap(Map<String, dynamic> map) {
    return OMRSheet(
      id: map['id'],
      examName: map['examName'],
      courseId: map['courseId'],
      subjectName: map['subjectName'],
      setNumber: map['setNumber'],
      numberOfQuestions: map['numberOfQuestions'],
      correctAnswers: List<String>.from(jsonDecode(map['correctAnswers'])),
      createdAt: DateTime.parse(map['createdAt']),
      examDate: DateTime.parse(map['examDate']),
      description: map['description'],
      isActive: map['isActive'] == 1,
      syncKey: map['syncKey'],
      syncStatus: map['syncStatus'],
      key: map['key'],
      sId: map['sId'],
      uId: map['uId'],
      uniqueId: map['uniqueId'],
    );
  }

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
    String? syncKey,
    String? key,
    int? syncStatus,
    String? uniqueId,
    String? uId,
    String? sId,
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
      syncKey: syncKey ?? this.syncKey,
      key: key ?? this.key,
      syncStatus: syncStatus ?? this.syncStatus,
      sId: sId ?? this.sId,
      uId: uId ?? this.uId,
      uniqueId: uniqueId ?? this.uniqueId,
    );
  }
}