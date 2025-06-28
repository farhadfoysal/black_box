
import 'package:sqflite/sqflite.dart';

import '../../model/schedule/class_routine.dart';
import 'db_helper.dart';

class DBManager {
  static Future<int> insertRoutineWithDuplicate(ClassRoutine routine) async {
    final db = await DBHelper.initDB();
    return await db.insert(
      'class_routine',
      routine.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<int> insertRoutine(ClassRoutine routine) async {
    final db = await DBHelper.initDB();

    // Check if a similar routine already exists
    final existing = await db.query(
      'class_routine',
      where: 'day = ? AND start_time = ? AND end_time = ? AND course_code = ? AND section = ? AND shift = ?',
      whereArgs: [
        routine.day,
        routine.startTime,
        routine.endTime,
        routine.courseCode,
        routine.section,
        routine.shift,
      ],
    );

    if (existing.isNotEmpty) {
      // Duplicate found, do not insert
      print('Duplicate routine found, skipping insert.');
      return -1; // You can return -1 or any custom error code
    }

    // Insert only if no duplicate
    return await db.insert(
      'class_routine',
      routine.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }


  static Future<List<ClassRoutine>> getAllRoutines() async {
    final db = await DBHelper.initDB();
    final List<Map<String, dynamic>> maps = await db.query('class_routine');
    return List.generate(maps.length, (i) => ClassRoutine.fromMap(maps[i]));
  }

  static Future<int> deleteAll() async {
    final db = await DBHelper.initDB();
    return await db.delete('class_routine');
  }

  static Future<int> deleteRoutineById(String uniqueId) async {
    final db = await DBHelper.initDB();
    return await db.delete(
      'class_routine',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }


}

