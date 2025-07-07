import 'package:sqflite/sqflite.dart';
import 'package:black_box/db/course/course_db.dart';

class CourseEnrollmentDAO {
  final db = CourseDb.instance.database;

  /// Enroll a user in a course
  Future<int> enrollCourse({
    required String uniqueId,
    required String userId,
    required String courseId,
    String status = 'active',
  }) async {
    final database = await db;
    return await database.insert('enrollments', {
      'unique_id': uniqueId,
      'user_id': userId,
      'course_id': courseId,
      'enrolled_at': DateTime.now().toIso8601String(),
      'status': status,
    });
  }

  /// Disenroll (remove enrollment)
  Future<int> disenrollCourse(String userId, String courseId) async {
    final database = await db;
    return await database.delete(
      'enrollments',
      where: 'user_id = ? AND course_id = ?',
      whereArgs: [userId, courseId],
    );
  }

  /// Check if a course is enrolled
  Future<bool> isCourseEnrolled(String userId, String courseId) async {
    final database = await db;
    final result = await database.query(
      'enrollments',
      where: 'user_id = ? AND course_id = ? AND status = ?',
      whereArgs: [userId, courseId, 'active'],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Get all enrolled course IDs for a user (only active enrollments)
  Future<List<String>> getEnrolledCourseIds(String userId) async {
    final database = await db;
    final result = await database.query(
      'enrollments',
      columns: ['course_id'],
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'active'],
    );
    return result.map((e) => e['course_id'] as String).toList();
  }

  // Future<List<String>> getEnrolledCourseIds(String userId) async {
  //   final database = await db;
  //   final result = await database.query(
  //     'course_enrollments',
  //     columns: ['course_id'],
  //     where: 'user_id = ?',
  //     whereArgs: [userId],
  //   );
  //   return result.map((e) => e['course_id'].toString()).toList();
  // }


// Future<List<String>> getEnrolledCourseIds(String userId) async {
  //   final database = await db;
  //   final result = await database.query(
  //     'course_enrollments',
  //     columns: ['course_id'],
  //     where: 'user_id = ?',
  //     whereArgs: [userId],
  //   );
  //   return result.map((e) => e['course_id'] as String).toList();
  // }


}
