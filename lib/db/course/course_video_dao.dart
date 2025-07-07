import 'package:sqflite/sqflite.dart';
import 'package:black_box/db/course/course_db.dart';

class CourseVideoDAO {
  final db = CourseDb.instance.database;

  /// Add a video to a course
  Future<int> addVideo({
    required String uniqueId,
    required String courseId,
    required String title,
    String? description,
    required String videoUrl,
    required int durationSeconds,
    int position = 0,
  }) async {
    final database = await db;
    return await database.insert('video_courses', {
      'unique_id': uniqueId,
      'course_id': courseId,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'duration_seconds': durationSeconds,
      'position': position,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get videos for a course ordered by position ascending
  Future<List<Map<String, dynamic>>> getVideosByCourseId(String courseId) async {
    final database = await db;
    final result = await database.query(
      'video_courses',
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'position ASC',
    );
    return result;
  }

  /// Delete a video by unique ID
  Future<int> deleteVideo(String uniqueId) async {
    final database = await db;
    return await database.delete(
      'video_courses',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }
}
