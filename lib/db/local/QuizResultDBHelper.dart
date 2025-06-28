import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../model/quiz/QResult.dart';
import '../../model/quiz/QuizResult.dart';
import '../../quiz/QuizResult.dart';

class Quizresultdbhelper {
  static const String databaseName = 'quiz_results.db';
  static const String tableName = 'quiz_results';

  // Open SQLite database
  Future<Database> _openDatabase() async {
    final String path = join(await getDatabasesPath(), databaseName);
    return openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  // Create the table
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId TEXT,
        phoneNumber TEXT,
        quizId TEXT,
        quizName TEXT,
        correctCount INTEGER,
        incorrectCount INTEGER,
        uncheckedCount INTEGER,
        percentage REAL,
        timestamp TEXT
      )
    ''');
  }

  static Future<void> saveQuizResultToSQLite(QuizResult quizResult) async {
    try {
      // Get a reference to the SQLite database
      final db = await Quizresultdbhelper()._openDatabase();

      // Convert the quiz result to a map
      final quizResultMap = quizResult.toMap();

      // Insert the result into the SQLite database
      await db.insert(
        tableName, // Using the table name defined above
        quizResultMap,
        conflictAlgorithm: ConflictAlgorithm.ignore, // In case of conflicts, replace the existing entry
      );
    } catch (e) {
      print('Error saving quiz result to SQLite: $e');
      throw e; // Rethrow the error if needed
    }
  }
  // Save the quiz result to SQLite
  // Future<void> saveQuizResultToSQLite(QuizResult quizResult) async {
  //   final db = await _openDatabase();
  //   await db.insert(tableName, {
  //     'studentId': quizResult.studentId,
  //     'phoneNumber': quizResult.phoneNumber,
  //     'quizId': quizResult.quiz.qId,
  //     'quizName': quizResult.quiz.quizName,
  //     'correctCount': quizResult.correctCount,
  //     'incorrectCount': quizResult.incorrectCount,
  //     'uncheckedCount': quizResult.uncheckedCount,
  //     'percentage': quizResult.percentage,
  //     'timestamp': DateTime.now().toString(),
  //   });
  // }

  Future<bool> hasUserPerformedQuiz(String studentId, String phoneNumber, String quizId) async {
    final db = await _openDatabase();

    // Query to check if a record exists with matching studentId, phoneNumber, and quizId
    final result = await db.query(
      tableName,
      where: 'studentId = ? AND phoneNumber = ? AND quizId = ?',
      whereArgs: [studentId, phoneNumber, quizId],
    );

    // If result is empty, user hasn't performed the quiz yet
    return result.isNotEmpty;
  }

  Future<QResult?> getQuizResult(String studentId, String phoneNumber, String quizId) async {
    final db = await _openDatabase();

    // Query to get the quiz result based on studentId, phoneNumber, and quizId
    final result = await db.query(
      tableName,
      where: 'studentId = ? AND phoneNumber = ? AND quizId = ?',
      whereArgs: [studentId, phoneNumber, quizId],
    );

    // If result is found, convert the first row to a QuizResult object
    if (result.isNotEmpty) {
      // Assuming your QuizResult class has a fromMap method to convert data to an object
      return QResult.fromMap(result.first);
    } else {
      return null; // Return null if no result is found
    }
  }

  Future<List<QResult>> getResultsByQuizId(String quizId) async {
    final db = await _openDatabase();

    // Query the database to get all results for the given quizId
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'quizId = ?',
      whereArgs: [quizId],
    );

    // Convert the results into a list of QResult objects
    return List.generate(maps.length, (i) {
      return QResult.fromMap(maps[i]);
    });
  }


  // Fetch all quiz results from SQLite
  Future<List<Map<String, dynamic>>> getQuizResults() async {
    final db = await _openDatabase();
    return db.query(tableName);
  }
}
