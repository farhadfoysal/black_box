import 'package:black_box/db/local/database_helper.dart';
import 'package:black_box/model/mess/mess_main.dart';
import 'package:black_box/model/mess/mess_user.dart';
import 'package:black_box/model/tutor/tutor_month.dart';
import 'package:black_box/model/tutor/tutor_student.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../model/schedule/schedule_item.dart';
import '../../model/school/school.dart';
import '../../model/tutor/tutor_date.dart';
import '../../model/user/admin.dart';
import '../../model/user/u_data.dart';
import '../../model/user/user.dart';

class DatabaseManager {
  Future<int> insertUser(User user) async {
    Database db = await DatabaseHelper().database;
    return await db.insert('User', user.toMap());
  }

  Future<int> insertMessUser(MessUser user) async {
    Database db = await DatabaseHelper().database;
    return await db.insert('MUser', user.toMap());
  }

  Future<int> updateUser(User user) async {
    Database db = await DatabaseHelper().database;
    return await db.update('User', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    Database db = await DatabaseHelper().database;
    return await db.delete('User', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<User>> getUsers() async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('User');
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  Future<User?> getUserById(int id) async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('User', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByPhone(String id) async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('User', where: 'phone = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<MessUser?> getMessUserByPhone(String id) async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('MUser', where: 'phone = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return MessUser.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> checkUserByPhone(String phone, String pass) async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('User', where: '(phone = ? OR email) = ? AND pass = ?', whereArgs: [phone,phone,pass]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> checkUserLogin(String phone, String pass, int type) async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('User', where: '(phone = ? OR email = ?) AND pass = ? AND utype = ?', whereArgs: [phone,phone,pass,type]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertUData(UData uData) async {
    Database db = await DatabaseHelper().database;
    return await db.insert('Udata', uData.toMap());
  }

  Future<int> updateUData(UData uData) async {
    Database db = await DatabaseHelper().database;
    return await db.update('Udata', uData.toMap(), where: 'id = ?', whereArgs: [uData.id]);
  }

  Future<int> deleteUData(int id) async {
    Database db = await DatabaseHelper().database;
    return await db.delete('Udata', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<UData>> getUData() async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('Udata');
    return List.generate(maps.length, (i) {
      return UData.fromMap(maps[i]);
    });
  }

  Future<UData?> getUDataById(int id) async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('Udata', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return UData.fromMap(maps.first);
    }
    return null;
  }

  Future<UData?> getUDataByPhone(String phone) async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('Udata', where: 'phone = ?', whereArgs: [phone]);
    if (maps.isNotEmpty) {
      return UData.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertSchool(School school) async {
    Database db = await DatabaseHelper().database;
    return await db.insert('school', school.toMap());
  }

  Future<int> insertMess(MessMain mess) async {
    Database db = await DatabaseHelper().database;
    return await db.insert('mess', mess.toMap());
  }

  Future<int> insertTutorStudent(TutorStudent tutorStudent) async {
    Database db = await DatabaseHelper().database;
    return await db.insert('tutor_student', tutorStudent.toMap());
  }

  // Insert TutorMonth and associated TutorDates
  Future<int> insertTutorMonth(TutorMonth tutorMonth) async {
    Database db = await DatabaseHelper().database;

    // Start a transaction to ensure atomicity
    return await db.transaction((txn) async {
      // Insert the TutorMonth into the tutor_month table
      int monthInsertId = await txn.insert('tutor_month', tutorMonth.toMap());

      // Insert TutorDate records for the inserted TutorMonth
      for (TutorDate date in tutorMonth.dates!) {
        // Set the monthId in the TutorDate to the uniqueId of the inserted TutorMonth
        date.monthId = tutorMonth.uniqueId;
        await txn.insert('tutor_date', date.toMap());
      }

      return monthInsertId;
    });
  }

  // Method to update TutorMonth dates in SQLite
  Future<int> updateTutorMonthDates(TutorMonth month) async {
    Database db = await DatabaseHelper().database;

    // Start a transaction to ensure atomicity
    return await db.transaction((txn) async {
      // Update the tutor_month table
      int monthUpdateCount = await txn.update(
        'tutor_month',
        month.toMap(),
        where: 'unique_id = ?',
        whereArgs: [month.uniqueId],
      );

      // If the TutorMonth update is successful, update the TutorDates
      if (monthUpdateCount > 0) {
        // Delete the existing dates before updating
        await txn.delete(
          'tutor_date',
          where: 'month_id = ?',
          whereArgs: [month.uniqueId],
        );

        // Insert updated TutorDates
        for (TutorDate date in month.dates!) {
          await txn.insert('tutor_date', date.toMap());
        }
      }

      return monthUpdateCount;
    });
  }

  Future<int> updateSchool(School school) async {
    Database db = await DatabaseHelper().database;
    return await db.update('school', school.toMap(), where: 'id = ?', whereArgs: [school.id]);
  }

  Future<int> deleteSchool(int id) async {
    Database db = await DatabaseHelper().database;
    return await db.delete('school', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<School>> getSchools() async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('school');
    return List.generate(maps.length, (i) {
      return School.fromMap(maps[i]);
    });
  }

  Future<School?> getSchoolById(int id) async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('school', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return School.fromMap(maps.first);
    }
    return null;
  }


  Future<School?> getSchoolBySid(String sid) async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('school', where: 'sid = ?', whereArgs: [sid]);

    if (maps.isNotEmpty) {
      return School.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<School?> getSchoolByPhone(String phone) async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('school', where: 'phone = ?', whereArgs: [phone]);

    if (maps.isNotEmpty) {
      return School.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateSchoolBySid(School school) async {
    Database db = await DatabaseHelper().database;
    return await db.update('school', school.toMap(), where: 'sid = ?', whereArgs: [school.sId]);
  }

  Future<int> deleteSchoolBySid(String sid) async {
    Database db = await DatabaseHelper().database;
    return await db.delete('school', where: 'sid = ?', whereArgs: [sid]);
  }


  // Insert a new school into the database
  Future<int> insertSchooll(School school) async {
    final db = await DatabaseHelper().database;
    return await db!.insert('school', school.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get all schools from the database
  Future<List<School>> getSchoolls() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db!.query('school');
    return List.generate(maps.length, (i) {
      return School.fromMap(maps[i]);
    });
  }

  // Update a school
  Future<int> updateSchooll(School school) async {
    final db = await DatabaseHelper().database;
    return await db!.update(
      'school',
      school.toMap(),
      where: "id = ?",
      whereArgs: [school.id],
    );
  }

  // Delete a school
  Future<void> deleteSchooll(int id) async {
    final db = await DatabaseHelper().database;
    await db!.delete(
      'school',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<int> insertAdmin(Admin admin) async {
    Database db = await DatabaseHelper().database;
    return await db.insert('admin', admin.toMap());
  }

  Future<int> updateAdmin(Admin admin) async {
    Database db = await DatabaseHelper().database;
    return await db.update('admin', admin.toMap(), where: 'id = ?', whereArgs: [admin.id]);
  }

  Future<int> deleteAdmin(int id) async {
    Database db = await DatabaseHelper().database;
    return await db.delete('admin', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Admin>> getAdmins() async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('admin');
    return List.generate(maps.length, (i) {
      return Admin.fromMap(maps[i]);
    });
  }

  Future<Admin?> getAdminById(int id) async {
    Database db = await DatabaseHelper().database;
    List<Map<String, dynamic>> maps = await db.query('admin', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Admin.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getUserUDataSchool() async {
    Database db = await DatabaseHelper().database;
    String sql = '''
      SELECT user.id AS user_id, user.uname, user.email, user.pass,
             u_data.id AS udata_id, u_data.uid, u_data.sid, u_data.fname, u_data.lname, u_data.phone, u_data.address,
             school.id AS school_id, school.eiin, school.semail, school.sname, school.saddress, school.sphone
      FROM user
      INNER JOIN u_data ON user.id = u_data.uid
      INNER JOIN school ON u_data.sid = school.id
    ''';
    List<Map<String, dynamic>> result = await db.rawQuery(sql);
    return result;
  }

  Future<int> insertSchedule(ScheduleItem schedule) async {
    final db = await await DatabaseHelper().database;
    return await db.insert(
      'schedule',
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScheduleItem>> getAllSchedules() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('schedule');

    return List.generate(maps.length, (i) {
      return ScheduleItem.fromMap(maps[i]);
    });
  }

  Future<List<ScheduleItem>> getAllSchedulesByUniqueId(String uniqueId) async {
    final db = await DatabaseHelper().database;

    final List<Map<String, dynamic>> maps = await db.query(
      'schedule',
      where: 'temp_code = ? OR temp_num = ?',
      whereArgs: [uniqueId, uniqueId],
    );

    return List.generate(maps.length, (i) {
      return ScheduleItem.fromMap(maps[i]);
    });
  }

  Future<List<ScheduleItem>> getSchedulesByDayAndTime(String day) async {
    final db = await DatabaseHelper().database;

    // Get the current time in the format "hh:mm a"
    final DateFormat dateFormat = DateFormat("hh:mm a");
    final String currentTime = dateFormat.format(DateTime.now());

    // SQL query to get schedules by day and ordered by time
    String sqlQuery = '''
    SELECT * FROM schedule
    WHERE day = ? OR day = ?
    ORDER BY 
      CASE 
        WHEN start_time >= ? THEN 1 
        ELSE 2 
      END,
      start_time ASC
  ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(
        sqlQuery,
        [day, "Everyday", currentTime]
    );

    return List.generate(maps.length, (i) {
      return ScheduleItem.fromMap(maps[i]);
    });
  }


  Future<List<ScheduleItem>> getSchedulesByDayAndTimeId(String day, String uniqueId) async {
    final db = await DatabaseHelper().database;

    // Get the current time in the format "hh:mm a"
    final DateFormat dateFormat = DateFormat("hh:mm a");
    final String currentTime = dateFormat.format(DateTime.now());

    // SQL query to get schedules by day, time, and tempCode = uniqueId
    String sqlQuery = '''
    SELECT * FROM schedule
    WHERE (day = ? OR day = ?)
      AND temp_code = ?
    ORDER BY 
      CASE 
        WHEN start_time >= ? THEN 1 
        ELSE 2 
      END,
      start_time ASC
  ''';

    // Execute the query with the day, 'Everyday', uniqueId, and current time as arguments
    final List<Map<String, dynamic>> maps = await db.rawQuery(
        sqlQuery,
        [day, "Everyday", uniqueId, currentTime]
    );

    // Convert the result into a list of ScheduleItem objects
    return List.generate(maps.length, (i) {
      return ScheduleItem.fromMap(maps[i]);
    });
  }

  Future<List<ScheduleItem>> getTodaySchedulesById(String uniqueId) async {
    final db = await DatabaseHelper().database;

    final String today = DateFormat('EEEE').format(DateTime.now());

    final DateFormat dateFormat = DateFormat("hh:mm a");
    final String currentTime = dateFormat.format(DateTime.now());

    String sqlQuery = '''
    SELECT * FROM schedule
    WHERE (day = ? OR day = ?)
      AND temp_code = ?
    ORDER BY 
      CASE 
        WHEN start_time >= ? THEN 1 
        ELSE 2 
      END,
      start_time ASC
  ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(
        sqlQuery,
        [today, "Everyday", uniqueId, currentTime]
    );

    // Convert the result into a list of ScheduleItem objects
    return List.generate(maps.length, (i) {
      return ScheduleItem.fromMap(maps[i]);
    });
  }


  Future<void> setSchedulesList(List<ScheduleItem> schedules) async {
    final db = await DatabaseHelper().database;

    // Begin a transaction for bulk insertions
    await db.transaction((txn) async {
      for (var schedule in schedules) {
        await txn.insert(
          'schedule',
          schedule.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }


  Future<void> deleteSchedule(String uniqueId) async {
    final db = await DatabaseHelper().database;
    await db.delete('schedule', where: 'uniqueId = ?', whereArgs: [uniqueId]);
  }

  Future<void> deleteSchedules(String uniqueId) async {
    final db = await DatabaseHelper().database;
    await db.delete(
        'schedule',
        where: 'temp_code = ? AND temp_num = ?',
        whereArgs: [uniqueId, uniqueId]
    );
  }


}
