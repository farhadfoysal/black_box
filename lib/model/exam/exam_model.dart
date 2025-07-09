
import 'package:black_box/model/exam/question_model.dart';

class ExamModel {
  int? id; // SQLite local id
  final String uniqueId; // Unique Exam Instance ID
  String examId;   // Firebase Template Exam ID
  final String title;
  final String description;
  final String createdAt;
  final int durationMinutes;
  final int status; // 0 = inactive, 1 = active
  final String examType; // stored as String now: 'written', 'quiz', etc.
  final String subjectId;
  final String? courseId;
  final String? userId;
  final String? mediaUrl;
  final String? mediaType;
  final List<QuestionModel>? questions;

  ExamModel({
    this.id,
    required this.uniqueId,
    required this.examId,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.durationMinutes,
    required this.status,
    required this.examType,
    required this.subjectId,
    this.courseId,
    this.userId,
    this.mediaUrl,
    this.mediaType,
    this.questions,
  });

  /// Map for SQLite
  Map<String, dynamic> toMap() => {
    'id': id,
    'unique_id': uniqueId,
    'exam_id': examId,
    'title': title,
    'description': description,
    'created_at': createdAt,
    'duration_minutes': durationMinutes,
    'status': status,
    'exam_type': examType,
    'subject_id': subjectId,
    'course_id': courseId,
    'user_id': userId,
    'media_url': mediaUrl,
    'media_type': mediaType,
  };

  /// From SQLite Map
  factory ExamModel.fromMap(Map<String, dynamic> map) => ExamModel(
    id: map['id'],
    uniqueId: map['unique_id'],
    examId: map['exam_id'],
    title: map['title'],
    description: map['description'],
    createdAt: map['created_at'],
    durationMinutes: map['duration_minutes'],
    status: map['status'],
    examType: map['exam_type'] ?? 'quiz',
    subjectId: map['subject_id'],
    courseId: map['course_id'],
    userId: map['user_id'],
    mediaUrl: map['media_url'],
    mediaType: map['media_type'],
  );

  /// JSON for Firebase / Web API
  Map<String, dynamic> toJson() => toMap();

  /// From JSON (Firebase)
  factory ExamModel.fromJson(Map<String, dynamic> json) =>
      ExamModel.fromMap(json);
}


class ExamTypes {
  static const String written = 'written';
  static const String quiz = 'quiz';
  static const String image = 'image';
  static const String edpuzzle = 'edpuzzle';

  static const List<String> values = [written, quiz, image, edpuzzle];

  static String validate(String value) {
    return values.contains(value) ? value : quiz;
  }
}


// import 'package:black_box/db/exam/question_model.dart';
//
// class ExamModel {
//   int? id; // SQLite local id
//   final String uniqueId; // Unique Exam Instance ID (could be for attempt/submission)
//   final String examId; // Firebase Template Exam ID
//   final String title;
//   final String description;
//   final String createdAt;
//   final int durationMinutes;
//   final int status; // 0 = inactive, 1 = active
//   final ExamType type;
//   final String subjectId;
//   final String? courseId; // New: course association
//   final String? userId;   // New: who attempted (if applicable)
//
//   // Optional media content
//   final String? mediaUrl;
//   final String? mediaType;
//
//   // Optional quiz data if applicable
//   final List<QuestionModel>? questions;
//
//   ExamModel({
//     this.id,
//     required this.uniqueId,
//     required this.examId,
//     required this.title,
//     required this.description,
//     required this.createdAt,
//     required this.durationMinutes,
//     required this.status,
//     required this.type,
//     required this.subjectId,
//     this.courseId,
//     this.userId,
//     this.mediaUrl,
//     this.mediaType,
//     this.questions,
//   });
//
//   Map<String, dynamic> toMap() => {
//     'id': id,
//     'unique_id': uniqueId,
//     'exam_id': examId,
//     'title': title,
//     'description': description,
//     'created_at': createdAt,
//     'duration_minutes': durationMinutes,
//     'status': status,
//     'type': type.name,
//     'subject_id': subjectId,
//     'course_id': courseId,
//     'user_id': userId,
//     'media_url': mediaUrl,
//     'media_type': mediaType,
//     'questions': questions != null
//         ? questions!.map((q) => q.toJson()).toList()
//         : null,
//   };
//
//   factory ExamModel.fromMap(Map<String, dynamic> map) => ExamModel(
//     id: map['id'],
//     uniqueId: map['unique_id'],
//     examId: map['exam_id'],
//     title: map['title'],
//     description: map['description'],
//     createdAt: map['created_at'],
//     durationMinutes: map['duration_minutes'],
//     status: map['status'],
//     type: ExamTypeExtension.fromString(map['type']),
//     subjectId: map['subject_id'],
//     courseId: map['course_id'],
//     userId: map['user_id'],
//     mediaUrl: map['media_url'],
//     mediaType: map['media_type'],
//     questions: map['questions'] != null
//         ? (map['questions'] as List)
//         .map((q) => QuestionModel.fromJson(Map<String, dynamic>.from(q)))
//         .toList()
//         : null,
//   );
//
//   Map<String, dynamic> toJson() => toMap();
//
//   factory ExamModel.fromJson(Map<String, dynamic> json) =>
//       ExamModel.fromMap(json);
// }
// enum ExamType {
//   written,    // Written input
//   quiz,       // MCQ-based
//   image,      // Image upload
//   edpuzzle,   // Video with embedded questions
// }
//
// extension ExamTypeExtension on ExamType {
//   static ExamType fromString(String value) {
//     return ExamType.values.firstWhere(
//           (e) => e.name == value,
//       orElse: () => ExamType.quiz,
//     );
//   }
// }