import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;

  static Database? _database;
  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'exam_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Create all tables here
    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unique_id TEXT,
        exam_id TEXT,
        title TEXT,
        description TEXT,
        created_at TEXT,
        duration_minutes INTEGER,
        status INTEGER,
        exam_type TEXT,
        subject_id TEXT,
        course_id TEXT,
        user_id TEXT,
        media_url TEXT,
        media_type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        q_id TEXT,
        quiz_id TEXT,
        question_title TEXT,
        question_answers TEXT,
        correct_answer TEXT,
        explanation TEXT,
        source TEXT,
        type TEXT,
        url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT,
        phone_number TEXT,
        quiz_id TEXT,
        quiz_name TEXT,
        correct_count INTEGER,
        incorrect_count INTEGER,
        unchecked_count INTEGER,
        percentage REAL,
        timestamp TEXT
      )
    ''');
    
  }
}
