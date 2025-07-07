import 'dart:convert';

class Enrollment {
  int? id; // For local SQLite PK, nullable for new entries
  String? uniqueId; // Unique enrollment id (UUID)
  String userId; // FK: user who enrolled
  String courseId; // FK: course enrolled into
  DateTime enrolledAt;
  String status; // e.g., "active", "completed", "cancelled"

  Enrollment({
    this.id,
    this.uniqueId,
    required this.userId,
    required this.courseId,
    required this.enrolledAt,
    this.status = 'active',
  });

  // JSON serialization for Supabase & API
  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
    id: json['id'],
    uniqueId: json['unique_id'],
    userId: json['user_id'],
    courseId: json['course_id'],
    enrolledAt: DateTime.parse(json['enrolled_at']),
    status: json['status'] ?? 'active',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'unique_id': uniqueId,
    'user_id': userId,
    'course_id': courseId,
    'enrolled_at': enrolledAt.toIso8601String(),
    'status': status,
  };

  // SQLite mapping
  factory Enrollment.fromMap(Map<String, dynamic> map) => Enrollment(
    id: map['id'],
    uniqueId: map['unique_id'],
    userId: map['user_id'],
    courseId: map['course_id'],
    enrolledAt: DateTime.parse(map['enrolled_at']),
    status: map['status'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'unique_id': uniqueId,
    'user_id': userId,
    'course_id': courseId,
    'enrolled_at': enrolledAt.toIso8601String(),
    'status': status,
  };
}
