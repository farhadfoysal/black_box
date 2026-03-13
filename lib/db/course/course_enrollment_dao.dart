import 'package:firebase_database/firebase_database.dart';
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

  Future<void> insertEnrollment(Map<String, dynamic> data) async {
    final database = await db;

    await database.insert(
      'enrollments',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  Future<void> syncEnrollmentsFromFirebase(String userId) async {
    final database = await db;

    try {
      final enrollRef = FirebaseDatabase.instance.ref("enrollments");

      final snapshot =
      await enrollRef.orderByChild("user_id").equalTo(userId).once();

      if (!snapshot.snapshot.exists) return;

      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;

      for (var entry in data.values) {
        final enroll = Map<String, dynamic>.from(entry);

        final uniqueId = enroll['unique_id'];
        final courseId = enroll['course_id'];
        final status = enroll['status'] ?? 'active';
        final enrolledAt = enroll['enrolled_at'];

        // check if already exists locally
        final existing = await database.query(
          'enrollments',
          where: 'unique_id = ?',
          whereArgs: [uniqueId],
          limit: 1,
        );

        if (existing.isEmpty) {
          await database.insert('enrollments', {
            'unique_id': uniqueId,
            'user_id': userId,
            'course_id': courseId,
            'enrolled_at': enrolledAt,
            'status': status,
          });
        }
      }
    } catch (e) {
      print("Enrollment sync failed: $e");
    }
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
