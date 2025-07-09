import 'package:sqflite/sqflite.dart';
import '../../model/exam/quiz_result_model.dart';
import 'app_database.dart';

class QuizResultDAO {
  /// Insert a new quiz result
  Future<int> insertResult(QuizResultModel result) async {
    final db = await AppDatabase().database;
    return await db.insert('quiz_results', result.toMap());
  }

  /// Fetch all results
  Future<List<QuizResultModel>> getAllResults() async {
    final db = await AppDatabase().database;
    final result = await db.query('quiz_results');
    return result.map((r) => QuizResultModel.fromMap(r)).toList();
  }

  /// Fetch results by student ID
  Future<List<QuizResultModel>> getResultsByStudent(String studentId) async {
    final db = await AppDatabase().database;
    final result = await db.query(
      'quiz_results',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    return result.map((r) => QuizResultModel.fromMap(r)).toList();
  }

  /// Fetch results by quiz ID
  Future<List<QuizResultModel>> getResultsByQuizId(String quizId) async {
    final db = await AppDatabase().database;
    final result = await db.query(
      'quiz_results',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );
    return result.map((r) => QuizResultModel.fromMap(r)).toList();
  }

  /// Fetch single result by local id
  Future<QuizResultModel?> getResultById(int id) async {
    final db = await AppDatabase().database;
    final result = await db.query(
      'quiz_results',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return QuizResultModel.fromMap(result.first);
    }
    return null;
  }

  /// Update a quiz result
  Future<int> updateResult(QuizResultModel result) async {
    final db = await AppDatabase().database;
    return await db.update(
      'quiz_results',
      result.toMap(),
      where: 'id = ?',
      whereArgs: [result.id],
    );
  }

  /// Delete a result by local id
  Future<int> deleteResult(int id) async {
    final db = await AppDatabase().database;
    return await db.delete(
      'quiz_results',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all results by quiz id
  Future<int> deleteResultsByQuizId(String quizId) async {
    final db = await AppDatabase().database;
    return await db.delete(
      'quiz_results',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );
  }

  /// Delete all results by student id
  Future<int> deleteResultsByStudentId(String studentId) async {
    final db = await AppDatabase().database;
    return await db.delete(
      'quiz_results',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
  }
}



// import 'package:sqflite/sqflite.dart';
// import '../../model/exam/quiz_result_model.dart';
// import 'app_database.dart';
//
// class QuizResultDAO {
//   Future<int> insertResult(QuizResultModel result) async {
//     final db = await AppDatabase().database;
//     return await db.insert('quiz_results', result.toMap());
//   }
//
//   Future<List<QuizResultModel>> getResultsByStudent(String studentId) async {
//     final db = await AppDatabase().database;
//     final result = await db.query('quiz_results', where: 'student_id = ?', whereArgs: [studentId]);
//     return result.map((r) => QuizResultModel.fromMap(r)).toList();
//   }
//
//   Future<int> deleteResult(int id) async {
//     final db = await AppDatabase().database;
//     return await db.delete('quiz_results', where: 'id = ?', whereArgs: [id]);
//   }
// }
