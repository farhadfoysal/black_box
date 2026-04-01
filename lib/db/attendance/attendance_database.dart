// ============================================================
// attendance_database.dart
// ============================================================
//
// FIXES vs original
// -----------------
// 1. upsert()  — was: insert(ignore) + update(unique_id) which silently
//                dropped rows whose unique_id was null / mismatched.
//                now: single INSERT OR REPLACE that relies on the
//                UNIQUE(student_id, date, sCourseId) constraint properly,
//                with unique_id always being the canonical key.
//
// 2. upsert()  — the map coming in may carry 'id' = null which causes
//                SQLite to complain on REPLACE. Strip it if null.
//
// 3. pendingDeletes() — new query that returns sync_status=2 rows so the
//                sync layer can push deletions to Firestore then wipe them.
//
// 4. hardDelete() — physically removes a row after remote deletion confirmed.
//
// 5. getByDate() — filters out sync_status=2 (locally-deleted) rows so they
//                never re-appear in the UI.
// ============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../model/attendance/monthly_report.dart';

class AttendanceDatabase {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  // ── schema ──────────────────────────────────────────────────
  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'attendance.db');

    return openDatabase(
      path,
      version: 3, // bump whenever schema changes
      onCreate: _createSchema,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Safest migration: drop & recreate.
        // Replace with ALTER TABLE statements if you need to preserve data.
        await db.execute('DROP TABLE IF EXISTS attendance');
        await _createSchema(db, newVersion);
      },
    );
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE attendance (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        unique_id   TEXT    NOT NULL,
        student_id  TEXT    NOT NULL,
        sCourseId   TEXT    NOT NULL,
        date        TEXT    NOT NULL,
        attend_date TEXT,
        status      TEXT    NOT NULL DEFAULT 'P',
        marks       INTEGER NOT NULL DEFAULT 0,
        sync_status INTEGER NOT NULL DEFAULT 0,
        UNIQUE(student_id, date, sCourseId)
      )
    ''');
  }

  // ── UPSERT (INSERT OR REPLACE) ───────────────────────────────
  // FIX 1 & 2: single atomic operation; strips null 'id' so SQLite
  //            can auto-assign it on first insert.
  static Future<void> upsert(Map<String, dynamic> data) async {
    final db = await database;

    // Remove null 'id' — REPLACE with id=null is treated as a new row,
    // breaking the UNIQUE constraint deduplication.
    final clean = Map<String, dynamic>.from(data)
      ..removeWhere((k, v) => k == 'id' && v == null);

    await db.insert(
      'attendance',
      clean,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── READ ─────────────────────────────────────────────────────
  // FIX 5: exclude locally-deleted (sync_status=2) rows.
  static Future<List<Map<String, dynamic>>> getByDate(
      String date,
      String courseId,
      ) async {
    final db = await database;
    return db.query(
      'attendance',
      where: 'date = ? AND sCourseId = ? AND sync_status != 2',
      whereArgs: [date, courseId],
    );
  }

  // ── HARD DELETE (after remote confirmation) ───────────────────
  // FIX 4: physically remove a row once Firestore delete succeeded.
  static Future<void> hardDelete(String uniqueId) async {
    final db = await database;
    await db.delete(
      'attendance',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

  // ── SYNC HELPERS ─────────────────────────────────────────────
  /// Records waiting to be pushed to Firestore (created / updated).
  static Future<List<Map<String, dynamic>>> pendingUpserts() async {
    final db = await database;
    return db.query('attendance', where: 'sync_status = 0');
  }

  /// Records marked for deletion that haven't been removed from Firestore yet.
  // FIX 3: was missing — sync layer had no way to process deletions.
  static Future<List<Map<String, dynamic>>> pendingDeletes() async {
    final db = await database;
    return db.query('attendance', where: 'sync_status = 2');
  }

  static Future<void> markSynced(String uniqueId) async {
    final db = await database;
    await db.update(
      'attendance',
      {'sync_status': 1},
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

  // ── CLEAR ────────────────────────────────────────────────────
  static Future<void> clear() async {
    final db = await database;
    await db.delete('attendance');
  }

  // ── REPORTS ──────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> studentMonthlyReport(
      String courseId,
      String month, // 'yyyy-MM'
      ) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        student_id,
        COUNT(*)                                      AS total_classes,
        SUM(CASE WHEN status = 'P' THEN 1 ELSE 0 END) AS present,
        SUM(CASE WHEN status = 'A' THEN 1 ELSE 0 END) AS absent,
        AVG(marks)                                    AS avg_marks
      FROM attendance
      WHERE sCourseId = ?
        AND date LIKE ?
        AND sync_status != 2
      GROUP BY student_id
    ''', [courseId, '$month%']);
  }

  static Future<Map<String, dynamic>> courseMonthlyReport(
      String courseId,
      String month,
      ) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*)                                      AS total_classes,
        SUM(CASE WHEN status = 'P' THEN 1 ELSE 0 END) AS present,
        SUM(CASE WHEN status = 'A' THEN 1 ELSE 0 END) AS absent,
        AVG(marks)                                    AS avg_marks
      FROM attendance
      WHERE sCourseId = ?
        AND date LIKE ?
        AND sync_status != 2
    ''', [courseId, '$month%']);

    return result.first;
  }

  // ── MODEL MAPPING ─────────────────────────────────────────────
  static List<MonthlyReport> mapStudentReports(
      List<Map<String, dynamic>> data,
      Map<String, String> studentNames,
      ) {
    return data.map((e) {
      final total = (e['total_classes'] as int?) ?? 0;
      final present = (e['present'] as int?) ?? 0;
      final absent = (e['absent'] as int?) ?? 0;

      return MonthlyReport(
        id: e['student_id'] as String,
        name: studentNames[e['student_id']] ?? 'Unknown',
        totalClasses: total,
        present: present,
        absent: absent,
        attendancePercent: total == 0 ? 0 : (present / total) * 100,
        avgMarks: ((e['avg_marks'] as num?) ?? 0).toDouble(),
      );
    }).toList();
  }
}




// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
//
// import '../../model/attendance/monthly_report.dart';
//
// class AttendanceDatabase {
//   static Database? _db;
//
//   static Future<Database> get db async {
//     if (_db != null) return _db!;
//     _db = await _init();
//     return _db!;
//   }
//
//   static Future<Database> _init() async {
//     final path = join(await getDatabasesPath(), 'attendance.db');
//
//     return await openDatabase(
//       path,
//       version: 2, // 🔥 version bump required
//       onCreate: (db, version) async {
//         await db.execute('''
//         CREATE TABLE attendance(
//           id INTEGER PRIMARY KEY AUTOINCREMENT,
//           unique_id TEXT,
//           student_id TEXT,
//           sCourseId TEXT,
//           date TEXT,
//           attend_date TEXT,
//           status TEXT,
//           marks INTEGER,
//           sync_status INTEGER DEFAULT 0,
//           UNIQUE(student_id, date, sCourseId)
//         )
//         ''');
//       },
//
//       // 🔥 MIGRATION (IMPORTANT)
//       onUpgrade: (db, oldVersion, newVersion) async {
//         if (oldVersion < 2) {
//           await db.execute('DROP TABLE IF EXISTS attendance');
//
//           await db.execute('''
//           CREATE TABLE attendance(
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             unique_id TEXT,
//             student_id TEXT,
//             sCourseId TEXT,
//             date TEXT,
//             attend_date TEXT,
//             status TEXT,
//             marks INTEGER,
//             sync_status INTEGER DEFAULT 0,
//             UNIQUE(student_id, date, sCourseId)
//           )
//           ''');
//         }
//       },
//     );
//   }
//
//   // ================= UPSERT (FIXED) =================
//
//   // static Future<void> upsert(Map<String, dynamic> data) async {
//   //   final database = await db;
//   //
//   //   await database.insert(
//   //     'attendance',
//   //     data,
//   //     conflictAlgorithm: ConflictAlgorithm.replace, // safe now
//   //   );
//   // }
//
//
//
//   static Future<void> upsert(Map<String, dynamic> data) async {
//     final db = await AttendanceDatabase.db;
//
//     await db.insert(
//       'attendance',
//       data,
//       conflictAlgorithm: ConflictAlgorithm.ignore,
//     );
//
//     await db.update(
//       'attendance',
//       data,
//       where: 'unique_id=?',
//       whereArgs: [data['unique_id']],
//     );
//   }
//
//
//   // ================= READ =================
//
//   static Future<List<Map<String, dynamic>>> getByDate(
//       String date, String courseId) async {
//     final database = await db;
//
//     return await database.query(
//       'attendance',
//       where: 'date=? AND sCourseId=?',
//       whereArgs: [date, courseId],
//     );
//   }
//
//   // ================= DELETE =================
//
//   static Future<void> delete(String uniqueId) async {
//     final database = await db;
//
//     await database.delete(
//       'attendance',
//       where: 'unique_id=?',
//       whereArgs: [uniqueId],
//     );
//   }
//
//   // ================= SYNC =================
//
//   static Future<List<Map<String, dynamic>>> unsynced() async {
//     final database = await db;
//
//     return await database.query(
//       'attendance',
//       where: 'sync_status=0',
//     );
//   }
//
//   static Future<void> markSynced(String id) async {
//     final database = await db;
//
//     await database.update(
//       'attendance',
//       {'sync_status': 1},
//       where: 'unique_id=?',
//       whereArgs: [id],
//     );
//   }
//
//   // ================= CLEAR =================
//
//   static Future<void> clear() async {
//     final database = await db;
//     await database.delete('attendance');
//   }
//
//   // ================= REPORT =================
//
//   static Future<List<Map<String, dynamic>>> studentMonthlyReport(
//       String courseId, String month) async {
//     final database = await db;
//
//     return await database.rawQuery('''
//     SELECT
//       student_id,
//       COUNT(*) as total_classes,
//       SUM(CASE WHEN status='P' THEN 1 ELSE 0 END) as present,
//       SUM(CASE WHEN status='A' THEN 1 ELSE 0 END) as absent,
//       AVG(marks) as avg_marks
//     FROM attendance
//     WHERE sCourseId = ?
//     AND date LIKE ?
//     GROUP BY student_id
//   ''', [courseId, '$month%']);
//   }
//
//   static Future<Map<String, dynamic>> courseMonthlyReport(
//       String courseId, String month) async {
//     final database = await db;
//
//     final result = await database.rawQuery('''
//     SELECT
//       COUNT(*) as total_classes,
//       SUM(CASE WHEN status='P' THEN 1 ELSE 0 END) as present,
//       SUM(CASE WHEN status='A' THEN 1 ELSE 0 END) as absent,
//       AVG(marks) as avg_marks
//     FROM attendance
//     WHERE sCourseId = ?
//     AND date LIKE ?
//   ''', [courseId, '$month%']);
//
//     return result.first;
//   }
//
//   List<MonthlyReport> mapStudentReports(
//       List<Map<String, dynamic>> data,
//       Map<String, String> studentNames,
//       ) {
//     return data.map((e) {
//       final total = e['total_classes'] ?? 0;
//       final present = e['present'] ?? 0;
//       final absent = e['absent'] ?? 0;
//
//       return MonthlyReport(
//         id: e['student_id'],
//         name: studentNames[e['student_id']] ?? "Unknown",
//         totalClasses: total,
//         present: present,
//         absent: absent,
//         attendancePercent:
//         total == 0 ? 0 : (present / total) * 100,
//         avgMarks: (e['avg_marks'] ?? 0).toDouble(),
//       );
//     }).toList();
//   }
// }




// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
//
// import '../../model/attendance/monthly_report.dart';
//
// class AttendanceDatabase {
//   static Database? _db;
//
//   static Future<Database> get db async {
//     if (_db != null) return _db!;
//     _db = await _init();
//     return _db!;
//   }
//
//   static Future<Database> _init() async {
//     final path = join(await getDatabasesPath(), 'attendance.db');
//
//     return await openDatabase(
//       path,
//       version: 1,
//       onCreate: (db, version) async {
//         await db.execute('''
//         CREATE TABLE attendance(
//           id INTEGER PRIMARY KEY AUTOINCREMENT,
//           unique_id TEXT UNIQUE,
//           student_id TEXT,
//           sCourseId TEXT,
//           date TEXT,
//           attend_date TEXT,
//           status TEXT,
//           marks INTEGER,
//           sync_status INTEGER DEFAULT 0
//         )
//         ''');
//       },
//     );
//   }
//
//   // CREATE TABLE attendance(
//   // id INTEGER PRIMARY KEY AUTOINCREMENT,
//   // unique_id TEXT,
//   // student_id TEXT,
//   // sCourseId TEXT,
//   // date TEXT,
//   // attend_date TEXT,
//   // status TEXT,
//   // marks INTEGER,
//   // sync_status INTEGER DEFAULT 0,
//   // UNIQUE(student_id, date, sCourseId)
//   // );
//
//   // CREATE / UPDATE
//   static Future<void> upsert(Map<String, dynamic> data) async {
//     final database = await db;
//     await database.insert(
//       'attendance',
//       data,
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   }
//
//   // READ
//   static Future<List<Map<String, dynamic>>> getByDate(
//       String date, String courseId) async {
//     final database = await db;
//     return await database.query(
//       'attendance',
//       where: 'date=? AND sCourseId=?',
//       whereArgs: [date, courseId],
//     );
//   }
//
//   // DELETE
//   static Future<void> delete(String uniqueId) async {
//     final database = await db;
//     await database.delete(
//       'attendance',
//       where: 'unique_id=?',
//       whereArgs: [uniqueId],
//     );
//   }
//
//   // UNSYNCED
//   static Future<List<Map<String, dynamic>>> unsynced() async {
//     final database = await db;
//     return await database.query(
//       'attendance',
//       where: 'sync_status=0',
//     );
//   }
//
//   static Future<void> markSynced(String id) async {
//     final database = await db;
//     await database.update(
//       'attendance',
//       {'sync_status': 1},
//       where: 'unique_id=?',
//       whereArgs: [id],
//     );
//   }
//
//   Stream<List<Map<String, dynamic>>> watchByDate(
//       String date, String courseId) async* {
//     final database = await db;
//
//     yield await getByDate(date, courseId);
//   }
//
//   static Future<void> clear() async {
//     final database = await db;
//     await database.delete('attendance');
//   }
//
//   static Future<List<Map<String, dynamic>>> studentMonthlyReport(
//       String courseId, String month) async {
//     final database = await db;
//
//     return await database.rawQuery('''
//     SELECT
//       student_id,
//       COUNT(*) as total_classes,
//       SUM(CASE WHEN status='P' THEN 1 ELSE 0 END) as present,
//       SUM(CASE WHEN status='A' THEN 1 ELSE 0 END) as absent,
//       AVG(marks) as avg_marks
//     FROM attendance
//     WHERE sCourseId = ?
//     AND date LIKE ?
//     GROUP BY student_id
//   ''', [courseId, '$month%']);
//   }
//
//   static Future<Map<String, dynamic>> courseMonthlyReport(
//       String courseId, String month) async {
//     final database = await db;
//
//     final result = await database.rawQuery('''
//     SELECT
//       COUNT(*) as total_classes,
//       SUM(CASE WHEN status='P' THEN 1 ELSE 0 END) as present,
//       SUM(CASE WHEN status='A' THEN 1 ELSE 0 END) as absent,
//       AVG(marks) as avg_marks
//     FROM attendance
//     WHERE sCourseId = ?
//     AND date LIKE ?
//   ''', [courseId, '$month%']);
//
//     return result.first;
//   }
//
//   List<MonthlyReport> mapStudentReports(
//       List<Map<String, dynamic>> data,
//       Map<String, String> studentNames) {
//
//     return data.map((e) {
//       final total = e['total_classes'] ?? 0;
//       final present = e['present'] ?? 0;
//       final absent = e['absent'] ?? 0;
//
//       return MonthlyReport(
//         id: e['student_id'],
//         name: studentNames[e['student_id']] ?? "Unknown",
//         totalClasses: total,
//         present: present,
//         absent: absent,
//         attendancePercent:
//         total == 0 ? 0 : (present / total) * 100,
//         avgMarks: (e['avg_marks'] ?? 0).toDouble(),
//       );
//     }).toList();
//   }
//
// }
//




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