import 'package:sqflite/sqflite.dart';
import '../../model/course/course_model.dart';
import 'course_db.dart';
import '../../model/course/course_model_db_mapper.dart'; // <— make sure this is imported

class CourseDAO {
  final db = CourseDb.instance.database;

  Future<int> insertCourse(CourseModel course) async {
    final database = await db;
    return await database.insert('courses', course.toMap());
  }

  Future<List<CourseModel>> getAllCourses() async {
    final database = await db;
    final result = await database.query('courses');
    return result.map((json) => CourseModelDbMapper.fromMap(json)).toList();
  }

  Future<int> updateCourse(CourseModel course) async {
    final database = await db;
    return await database.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<int> deleteCourse(int id) async {
    final database = await db;
    return await database.delete(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// ✅ Fetch all courses created by a specific user
  Future<List<CourseModel>> getCoursesByUserId(String userId) async {
    final database = await db;
    final result = await database.query(
      'courses',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.map((json) => CourseModelDbMapper.fromMap(json)).toList();
  }

  /// ✅ Fetch a single course by its unique_id
  Future<CourseModel?> getCourseByUniqueId(String uniqueId) async {
    final database = await db;
    final result = await database.query(
      'courses',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return CourseModelDbMapper.fromMap(result.first);
    } else {
      return null;
    }
  }
}


// import 'package:sqflite/sqflite.dart';
// import '../../model/course/course_model.dart';
// import 'course_db.dart';
//
//
// class CourseDAO {
//   final db = CourseDb.instance.database;
//
//   Future<int> insertCourse(CourseModel course) async {
//     final database = await db;
//     return await database.insert('courses', course.toJson());
//   }
//
//   Future<List<CourseModel>> getAllCourses() async {
//     final database = await db;
//     final result = await database.query('courses');
//     return result.map((json) => CourseModel.fromJson(json)).toList();
//   }
//
//   Future<int> updateCourse(CourseModel course) async {
//     final database = await db;
//     return await database.update(
//       'courses',
//       course.toJson(),
//       where: 'id = ?',
//       whereArgs: [course.id],
//     );
//   }
//
//   Future<int> deleteCourse(int id) async {
//     final database = await db;
//     return await database.delete(
//       'courses',
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//   }
// }
