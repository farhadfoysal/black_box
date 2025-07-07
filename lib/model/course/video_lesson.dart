import 'dart:convert';

class VideoLesson {
  int? id;
  String? uniqueId;   // UUID
  String courseId;    // FK: course this video belongs to
  String title;
  String description;
  String videoUrl;
  int durationSeconds;  // Video length in seconds
  int position;        // order in course
  DateTime createdAt;

  VideoLesson({
    this.id,
    this.uniqueId,
    required this.courseId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.durationSeconds,
    this.position = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory VideoLesson.fromJson(Map<String, dynamic> json) => VideoLesson(
    id: json['id'],
    uniqueId: json['unique_id'],
    courseId: json['course_id'],
    title: json['title'],
    description: json['description'],
    videoUrl: json['video_url'],
    durationSeconds: json['duration_seconds'],
    position: json['position'] ?? 0,
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'unique_id': uniqueId,
    'course_id': courseId,
    'title': title,
    'description': description,
    'video_url': videoUrl,
    'duration_seconds': durationSeconds,
    'position': position,
    'created_at': createdAt.toIso8601String(),
  };

  factory VideoLesson.fromMap(Map<String, dynamic> map) => VideoLesson(
    id: map['id'],
    uniqueId: map['unique_id'],
    courseId: map['course_id'],
    title: map['title'],
    description: map['description'],
    videoUrl: map['video_url'],
    durationSeconds: map['duration_seconds'],
    position: map['position'] ?? 0,
    createdAt: DateTime.parse(map['created_at']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'unique_id': uniqueId,
    'course_id': courseId,
    'title': title,
    'description': description,
    'video_url': videoUrl,
    'duration_seconds': durationSeconds,
    'position': position,
    'created_at': createdAt.toIso8601String(),
  };
}
