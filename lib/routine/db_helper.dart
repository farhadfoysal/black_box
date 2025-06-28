import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "routine.db";
  static const _databaseVersion = 1;

  static const table = "routine";

  static const columnId = "id";
  static const columnCourseCode = "course_code";
  static const columnDay = "day";
  static const columnRoom = "room";
  static const columnTime = "time";
  static const columnInstructor = "instructor";

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnCourseCode TEXT NOT NULL,
            $columnDay TEXT NOT NULL,
            $columnRoom TEXT NOT NULL,
            $columnTime TEXT NOT NULL,
            $columnInstructor TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertRoutine(Map<String, dynamic> routine) async {
    final db = await database;
    await db.insert(table, routine);
  }

  Future<List<Map<String, dynamic>>> getRoutineByCourse(String courseCode) async {
    final db = await database;
    return await db.query(table, where: '$columnCourseCode = ?', whereArgs: [courseCode]);
  }

  Future<List<Map<String, dynamic>>> getAllRoutines() async {
    final db = await database;
    return await db.query(table);
  }
}
