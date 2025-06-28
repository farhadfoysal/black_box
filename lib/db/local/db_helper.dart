import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'class_routine.db');

    return openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE class_routine(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            unique_id TEXT,
            schedule_id TEXT,
            day TEXT,
            start_time TEXT,
            end_time TEXT,
            major TEXT,
            course_code TEXT,
            teacher TEXT,
            room TEXT,
            section TEXT,
            shift TEXT
          )
        ''');
      },
      version: 1,
    );
  }
}
