import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class CourseDb {
  static final CourseDb instance = CourseDb._init();
  static Database? _database;

  CourseDb._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('black_box.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// ✅ Create the `courses` table with full schema matching CourseModel
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unique_id TEXT,
        user_id TEXT,
        course_name TEXT,
        course_image TEXT,
        category TEXT,
        description TEXT,
        total_video INTEGER,
        total_times TEXT,
        total_rating REAL,
        fee REAL,
        tracking_number TEXT,
        discount REAL,
        level TEXT,
        count_students INTEGER,
        created_at TEXT,
        status TEXT
      )
    ''');
  }

  /// ✅ Close database safely
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}



// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';
//
// class CourseDb {
//   static final CourseDb instance = CourseDb._init();
//   static Database? _database;
//
//   CourseDb._init();
//
//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDB('black_box.db');
//     return _database!;
//   }
//
//   Future<Database> _initDB(String filePath) async {
//     final dbPath = await getDatabasesPath();
//     final path = join(dbPath, filePath);
//
//     return await openDatabase(
//       path,
//       version: 1,
//       onCreate: _createDB,
//     );
//   }
//
//   /// Create the `courses` table with full schema matching CourseModel
//   Future _createDB(Database db, int version) async {
//     await db.execute('''
//       CREATE TABLE courses (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         unique_id TEXT,
//         user_id TEXT,
//         course_name TEXT,
//         course_image TEXT,
//         category TEXT,
//         description TEXT,
//         total_video INTEGER,
//         total_times TEXT,
//         total_rating REAL,
//         level TEXT,
//         count_students INTEGER,
//         created_at TEXT,
//         status TEXT
//       )
//     ''');
//   }
//
//   /// Close database safely
//   Future close() async {
//     final db = await instance.database;
//     db.close();
//   }
// }
