import 'dart:convert';

class Favorite {
  int? id;
  String? uniqueId; // UUID for favorite record
  String userId;    // User who favorited
  String courseId;  // Course favorited
  DateTime favoritedAt;

  Favorite({
    this.id,
    this.uniqueId,
    required this.userId,
    required this.courseId,
    DateTime? favoritedAt,
  }) : favoritedAt = favoritedAt ?? DateTime.now();

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
    id: json['id'],
    uniqueId: json['unique_id'],
    userId: json['user_id'],
    courseId: json['course_id'],
    favoritedAt: DateTime.parse(json['favorited_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'unique_id': uniqueId,
    'user_id': userId,
    'course_id': courseId,
    'favorited_at': favoritedAt.toIso8601String(),
  };

  factory Favorite.fromMap(Map<String, dynamic> map) => Favorite(
    id: map['id'],
    uniqueId: map['unique_id'],
    userId: map['user_id'],
    courseId: map['course_id'],
    favoritedAt: DateTime.parse(map['favorited_at']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'unique_id': uniqueId,
    'user_id': userId,
    'course_id': courseId,
    'favorited_at': favoritedAt.toIso8601String(),
  };
}
