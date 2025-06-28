import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../model/quiz/quiz.dart';

class QuizDBHelper {
  static Database? _db;

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'quiz.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE quizzes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            q_id TEXT,
            quiz_name TEXT,
            quiz_description TEXT,
            created_at TEXT,
            minutes INTEGER,
            status INTEGER,
            type INTEGER,
            subject TEXT
          )
        ''');
      },
    );
  }

  static Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  /// Insert a Quiz
  static Future<void> insertQuiz(Quiz quiz) async {
    final db = await database;
    await db.insert(
      'quizzes',
      quiz.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch all Quizzes
  static Future<List<Quiz>> getQuizzes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('quizzes', orderBy: 'created_at DESC');
    return maps.map((e) => Quiz.fromMap(e)).toList();
  }

  /// Delete a Quiz by id
  static Future<void> deleteQuiz(int id) async {
    final db = await database;
    await db.delete(
      'quizzes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteQuizByUId(String id) async {
    final db = await database;
    await db.delete(
      'quizzes',
      where: 'q_id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all quizzes (optional helper)
  static Future<void> deleteAllQuizzes() async {
    final db = await database;
    await db.delete('quizzes');
  }

  /// Get a quiz by its q_id
  static Future<Quiz?> getQuizByQId(String qId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quizzes',
      where: 'q_id = ?',
      whereArgs: [qId],
    );

    if (maps.isNotEmpty) {
      return Quiz.fromMap(maps.first);
    } else {
      return null;
    }
  }

  /// Check if a quiz exists by its q_id
  static Future<bool> checkQuizById(String qId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'quizzes',
      where: 'q_id = ?',
      whereArgs: [qId],
      limit: 1,
    );
    return result.isNotEmpty;
  }



}
