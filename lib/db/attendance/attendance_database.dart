import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AttendanceDatabase {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'attendance.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE attendance(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          unique_id TEXT UNIQUE,
          student_id TEXT,
          sCourseId TEXT,
          date TEXT,
          attend_date TEXT,
          status TEXT,
          marks INTEGER,
          sync_status INTEGER
        )
        ''');
      },
    );
  }

  // CREATE / UPDATE
  static Future<void> upsert(Map<String, dynamic> data) async {
    final database = await db;
    await database.insert(
      'attendance',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ
  static Future<List<Map<String, dynamic>>> getByDate(
      String date, String courseId) async {
    final database = await db;
    return await database.query(
      'attendance',
      where: 'date=? AND sCourseId=?',
      whereArgs: [date, courseId],
    );
  }

  // DELETE
  static Future<void> delete(String uniqueId) async {
    final database = await db;
    await database.delete(
      'attendance',
      where: 'unique_id=?',
      whereArgs: [uniqueId],
    );
  }

  // UNSYNCED
  static Future<List<Map<String, dynamic>>> unsynced() async {
    final database = await db;
    return await database.query(
      'attendance',
      where: 'sync_status=0',
    );
  }

  static Future<void> markSynced(String id) async {
    final database = await db;
    await database.update(
      'attendance',
      {'sync_status': 1},
      where: 'unique_id=?',
      whereArgs: [id],
    );
  }
}





// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
//
// class AttendanceDatabase {
//   static Database? _db;
//
//   static Future<Database> get database async {
//     if (_db != null) return _db!;
//
//     _db = await _initDb();
//     return _db!;
//   }
//
//   static Future<Database> _initDb() async {
//     final path = join(await getDatabasesPath(), 'attendance.db');
//
//     return openDatabase(
//       path,
//       version: 1,
//       onCreate: (db, version) async {
//         await db.execute('''
//         CREATE TABLE attendance(
//           id INTEGER PRIMARY KEY AUTOINCREMENT,
//           unique_id TEXT,
//           student_id TEXT,
//           sheet_id TEXT,
//           sCourseId TEXT,
//           time TEXT,
//           exit_in INTEGER,
//           attend_date TEXT,
//           date TEXT,
//           status TEXT,
//           marks INTEGER,
//           sync_status INTEGER,
//           sync_key TEXT
//         )
//         ''');
//       },
//     );
//   }
//
//   // INSERT / UPDATE
//   static Future<void> insertOrUpdate(Map<String, dynamic> data) async {
//     final db = await database;
//
//     await db.insert(
//       'attendance',
//       data,
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   }
//
//   // GET BY DATE + COURSE
//   static Future<List<Map<String, dynamic>>> getByDate(
//       String date, String courseId) async {
//     final db = await database;
//
//     return db.query(
//       'attendance',
//       where: 'date=? AND sCourseId=?',
//       whereArgs: [date, courseId],
//     );
//   }
//
//   // UNSYNCED DATA
//   static Future<List<Map<String, dynamic>>> getUnsynced() async {
//     final db = await database;
//
//     return db.query(
//       'attendance',
//       where: 'sync_status=0',
//     );
//   }
//
//   static Future<void> updateSyncStatus(String uniqueId) async {
//     final db = await database;
//
//     await db.update(
//       'attendance',
//       {'sync_status': 1},
//       where: 'unique_id=?',
//       whereArgs: [uniqueId],
//     );
//   }
// }