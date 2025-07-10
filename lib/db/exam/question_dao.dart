import 'package:sqflite/sqflite.dart';
import '../../model/exam/question_model.dart';
import 'app_database.dart';

class QuestionDAO {
  /// Insert a new question
  Future<int> insertQuestion(QuestionModel question) async {
    final db = await AppDatabase().database;
    return await db.insert('questions', question.toMap());
  }

  /// Fetch all questions
  Future<List<QuestionModel>> getAllQuestions() async {
    final db = await AppDatabase().database;
    final result = await db.query('questions');
    return result.map((q) => QuestionModel.fromMap(q)).toList();
  }

  /// Fetch questions by quizId
  Future<List<QuestionModel>> getQuestionsByQuizId(String quizId) async {
    final db = await AppDatabase().database;
    final result = await db.query(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );
    return result.map((q) => QuestionModel.fromMap(q)).toList();
  }

  /// Fetch questions by examId
  Future<List<QuestionModel>> getQuestionsByExamId(String examId) async {
    final db = await AppDatabase().database;
    final result = await db.query(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [examId],
    );
    return result.map((q) => QuestionModel.fromMap(q)).toList();
  }

  /// Fetch single question by local id
  Future<QuestionModel?> getQuestionById(int id) async {
    final db = await AppDatabase().database;
    final result = await db.query(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return QuestionModel.fromMap(result.first);
    }
    return null;
  }

  /// Update a question
  Future<int> updateQuestion(QuestionModel question) async {
    final db = await AppDatabase().database;
    return await db.update(
      'questions',
      question.toMap(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  /// Delete a question by id
  Future<int> deleteQuestion(int id) async {
    final db = await AppDatabase().database;
    return await db.delete(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a question by uniqueId
  Future<int> deleteQuestionByUniqueId(String id) async {
    final db = await AppDatabase().database;
    return await db.delete(
      'questions',
      where: 'q_id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all questions by quizId
  Future<int> deleteQuestionsByQuizId(String quizId) async {
    final db = await AppDatabase().database;
    return await db.delete(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );
  }

  /// Delete all questions by examId
  Future<int> deleteQuestionsByExamId(String examId) async {
    final db = await AppDatabase().database;
    return await db.delete(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [examId],
    );
  }
}




// import 'package:sqflite/sqflite.dart';
// import '../../model/exam/question_model.dart';
// import 'app_database.dart';
//
// class QuestionDAO {
//   Future<int> insertQuestion(QuestionModel question) async {
//     final db = await AppDatabase().database;
//     return await db.insert('questions', question.toMap());
//   }
//
//   Future<List<QuestionModel>> getQuestionsByQuizId(String quizId) async {
//     final db = await AppDatabase().database;
//     final result = await db.query('questions', where: 'quiz_id = ?', whereArgs: [quizId]);
//     return result.map((q) => QuestionModel.fromMap(q)).toList();
//   }
//
//   Future<int> deleteQuestion(int id) async {
//     final db = await AppDatabase().database;
//     return await db.delete('questions', where: 'id = ?', whereArgs: [id]);
//   }
// }
