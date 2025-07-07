import 'package:sqflite/sqflite.dart';
import 'package:black_box/db/course/course_db.dart';

class CourseFavoriteDAO {
  final db = CourseDb.instance.database;

  /// Mark a course as favorite
  Future<int> favoriteCourse({
    required String uniqueId,
    required String userId,
    required String courseId,
  }) async {
    final database = await db;
    return await database.insert('favorites', {
      'unique_id': uniqueId,
      'user_id': userId,
      'course_id': courseId,
      'favorited_at': DateTime.now().toIso8601String(),
    });
  }

  /// Unfavorite a course
  Future<int> unfavoriteCourse(String userId, String courseId) async {
    final database = await db;
    return await database.delete(
      'favorites',
      where: 'user_id = ? AND course_id = ?',
      whereArgs: [userId, courseId],
    );
  }

  /// Check if a course is favorited
  Future<bool> isCourseFavorited(String userId, String courseId) async {
    final database = await db;
    final result = await database.query(
      'favorites',
      where: 'user_id = ? AND course_id = ?',
      whereArgs: [userId, courseId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Get all favorite course IDs for a user
  Future<List<String>> getFavoriteCourseIds(String userId) async {
    final database = await db;
    final result = await database.query(
      'favorites',
      columns: ['course_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.map((e) => e['course_id'] as String).toList();
  }

  // Future<List<String>> getFavoriteCourseIds(String userId) async {
  //   final database = await db;
  //   final result = await database.query(
  //     'course_favorites',
  //     columns: ['course_id'],
  //     where: 'user_id = ?',
  //     whereArgs: [userId],
  //   );
  //   return result.map((e) => e['course_id'] as String).toList();
  // }


}
