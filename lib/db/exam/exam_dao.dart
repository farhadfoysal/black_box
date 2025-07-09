import 'package:sqflite/sqflite.dart';
import '../../model/exam/exam_model.dart';
import 'app_database.dart';

class ExamDAO {
  /// Insert a new Exam
  Future<int> insertExam(ExamModel exam) async {
    final db = await AppDatabase().database;
    return await db.insert('exams', exam.toMap());
  }

  /// Fetch all Exams
  Future<List<ExamModel>> getAllExams() async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> result = await db.query('exams');
    return result.map((e) => ExamModel.fromMap(e)).toList();
  }

  /// Fetch exams by courseId
  Future<List<ExamModel>> getExamsByCourseId(String courseId) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> result = await db.query(
      'exams',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
    return result.map((e) => ExamModel.fromMap(e)).toList();
  }

  /// Fetch exams by userId
  Future<List<ExamModel>> getExamsByUserId(String userId) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> result = await db.query(
      'exams',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.map((e) => ExamModel.fromMap(e)).toList();
  }

  /// Fetch exams by ExamType (as string)
  Future<List<ExamModel>> getExamsByType(String type) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> result = await db.query(
      'exams',
      where: 'type = ?',
      whereArgs: [type],
    );
    return result.map((e) => ExamModel.fromMap(e)).toList();
  }

  /// Delete exam by exam id (SQLite local id)
  Future<int> deleteExam(int id) async {
    final db = await AppDatabase().database;
    return await db.delete('exams', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete exams by courseId
  Future<int> deleteExamsByCourseId(String courseId) async {
    final db = await AppDatabase().database;
    return await db.delete(
      'exams',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
  }

  /// Update an existing Exam
  Future<int> updateExam(ExamModel exam) async {
    final db = await AppDatabase().database;
    return await db.update(
      'exams',
      exam.toMap(),
      where: 'id = ?',
      whereArgs: [exam.id],
    );
  }
}
