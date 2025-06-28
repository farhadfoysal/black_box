import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../model/quiz/question.dart';

class QuestionDBHelper {
  static Database? _db;

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'question.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE questions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            q_id TEXT,
            quiz_id TEXT,
            question_title TEXT,
            question_answers TEXT,
            explanation TEXT,
            source TEXT,
            type TEXT,
            url TEXT
          )
        ''');
      },
    );
  }

  static Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  // Insert a Question
  static Future<void> insertQuestion(Question question, String quizId) async {
    final db = await database;
    await db.insert(
      'questions',
      {
        'q_id': question.qId,
        'quiz_id': quizId,
        'question_title': question.questionTitle,
        'question_answers': jsonEncode(question.questionAnswers), // Save List as JSON string
        'explanation': question.explanation,
        'source': question.source,
        'type': question.type,
        'url': question.url,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get Questions by Quiz ID
  static Future<List<Question>> getQuestionsByQuizId(String quizId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );

    return maps.map((map) => Question(
      id: map['id'],
      qId: map['q_id'],
      quizId: map['quiz_id'],
      questionTitle: map['question_title'],
      questionAnswers: List<String>.from(jsonDecode(map['question_answers'] ?? '[]')),
      explanation: map['explanation'],
      source: map['source'],
      type: map['type'],
      url: map['url'],
    )).toList();
  }

  // Delete a specific Question
  static Future<void> deleteQuestion(int id) async {
    final db = await database;
    await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteQuestionByUId(String id) async {
    final db = await database;
    await db.delete('questions', where: 'q_id = ?', whereArgs: [id]);
  }

  // Delete all Questions for a Quiz
  static Future<void> deleteQuestionsByQuizId(String quizId) async {
    final db = await database;
    await db.delete('questions', where: 'quiz_id = ?', whereArgs: [quizId]);
  }

  /// Insert a Question into SQLite
  static Future<void> insertQuestionn(Question question) async {
    final db = await database;
    await db.insert(
      'questions',
      question.toMap(),  // directly use the model's toMap()
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch all Questions for a specific Quiz ID
  static Future<List<Question>> getQuestionsByQuizIdd(String quizId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );

    return maps.map((map) => Question.fromMap(map)).toList();
  }

  /// Delete a specific Question by local ID
  static Future<void> deleteQuestionn(int id) async {
    final db = await database;
    await db.delete(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all Questions belonging to a specific Quiz
  static Future<void> deleteQuestionsByQuizIdd(String quizId) async {
    final db = await database;
    await db.delete(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );
  }

}
