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
import '../../model/tutor/tutor_week_day.dart';
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

  Future<int> insertTutorStudent(TutorStudent student) async {
    final db = await DatabaseHelper().database;

    return await db.insert(
      'tutor_students', // Table name
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertTutorStudentDay(TutorStudent tutorStudent) async {
    final db = await DatabaseHelper().database;

    try {
      return await db.transaction((txn) async {
        // Prepare the TutorStudent data without the 'days' field
        Map<String, dynamic> studentData = {
          'id': tutorStudent.id,
          'unique_id': tutorStudent.uniqueId,
          'user_id': tutorStudent.userId,
          'name': tutorStudent.name,
          'phone': tutorStudent.phone,
          'gaurdian_phone': tutorStudent.gaurdianPhone,
          'phone_pass': tutorStudent.phonePass,
          'dob': tutorStudent.dob,
          'education': tutorStudent.education,
          'address': tutorStudent.address,
          'active_status': tutorStudent.activeStatus,
          'admitted_date': tutorStudent.admittedDate?.toIso8601String(),
          'img': tutorStudent.img,
        };

        // Insert the TutorStudent data into the tutor_students table (inside the transaction)
        int result = await txn.insert(
          'tutor_students',
          studentData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // If TutorStudent has days, insert associated TutorWeekDay records into the tutor_week_days table (inside the transaction)
        if (tutorStudent.days != null && tutorStudent.days!.isNotEmpty) {
          for (var day in tutorStudent.days!) {
            await txn.insert(
              'tutor_week_days',
              day.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        return result;
      });
    } catch (e) {
      print('Error inserting TutorStudent: $e');
      rethrow;
    }
  }


  Future<int> insertTutorStudentDayNot(TutorStudent tutorStudent) async {
    final db = await DatabaseHelper().database;

    try {
      // Prepare the TutorStudent data without the 'days' field
      Map<String, dynamic> studentData = {
        'id': tutorStudent.id,
        'unique_id': tutorStudent.uniqueId,
        'user_id': tutorStudent.userId,
        'name': tutorStudent.name,
        'phone': tutorStudent.phone,
        'gaurdian_phone': tutorStudent.gaurdianPhone,
        'phone_pass': tutorStudent.phonePass,
        'dob': tutorStudent.dob,
        'education': tutorStudent.education,
        'address': tutorStudent.address,
        'active_status': tutorStudent.activeStatus,
        'admitted_date': tutorStudent.admittedDate?.toIso8601String(),
        'img': tutorStudent.img,
      };

      // Insert the TutorStudent data into the tutor_students table (without the 'days' field)
      int result = await db.insert(
        'tutor_students',
        studentData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // If TutorStudent has days, insert associated TutorWeekDay records into the tutor_week_days table
      if (tutorStudent.days != null && tutorStudent.days!.isNotEmpty) {
        // Insert each day asynchronously into the tutor_week_days table
        for (var day in tutorStudent.days!) {
          await db.insert(
            'tutor_week_days',
            day.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      return result;
    } catch (e) {
      print('Error inserting TutorStudent: $e');
      rethrow;
    }
  }

  Future<int> updateTutorStudentDay(TutorStudent tutorStudent) async {
    final db = await DatabaseHelper().database;

    // Prepare TutorStudent data excluding 'days' for the update operation
    Map<String, dynamic> studentData = {
      'unique_id': tutorStudent.uniqueId,
      'user_id': tutorStudent.userId,
      'name': tutorStudent.name,
      'phone': tutorStudent.phone,
      'gaurdian_phone': tutorStudent.gaurdianPhone,
      'phone_pass': tutorStudent.phonePass,
      'dob': tutorStudent.dob,
      'education': tutorStudent.education,
      'address': tutorStudent.address,
      'active_status': tutorStudent.activeStatus,
      'admitted_date': tutorStudent.admittedDate?.toIso8601String(),
      'img': tutorStudent.img,
    };

    try {
      return await db.transaction((txn) async {
        // Update the tutor_students table excluding 'days' field
        int studentUpdateCount = await txn.update(
          'tutor_students',
          studentData,
          where: 'unique_id = ?',
          whereArgs: [tutorStudent.uniqueId],
        );

        // If tutorStudent.days is provided, delete old TutorWeekDay records and re-insert updated ones
        if (tutorStudent.days != null && tutorStudent.days!.isNotEmpty) {
          // Delete the existing TutorWeekDay records for this student
          await txn.delete(
            'tutor_week_days',
            where: 'student_id = ?',
            whereArgs: [tutorStudent.uniqueId],
          );

          // Insert updated TutorWeekDay records
          for (TutorWeekDay day in tutorStudent.days!) {
            await txn.insert(
              'tutor_week_days',
              day.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        return studentUpdateCount;
      });
    } catch (e) {
      print('Error updating TutorStudent: $e');
      rethrow;
    }
  }


  Future<int> updateTutorStudentDayNott(TutorStudent tutorStudent) async {
    final db = await DatabaseHelper().database;

    // Prepare TutorStudent data excluding 'days' for the update operation
    Map<String, dynamic> studentData = {
      'unique_id': tutorStudent.uniqueId,
      'user_id': tutorStudent.userId,
      'name': tutorStudent.name,
      'phone': tutorStudent.phone,
      'gaurdian_phone': tutorStudent.gaurdianPhone,
      'phone_pass': tutorStudent.phonePass,
      'dob': tutorStudent.dob,
      'education': tutorStudent.education,
      'address': tutorStudent.address,
      'active_status': tutorStudent.activeStatus,
      'admitted_date': tutorStudent.admittedDate?.toIso8601String(),
      'img': tutorStudent.img,
    };

    try {
      // Update the tutor_students table excluding 'days' field
      int studentUpdateCount = await db.update(
        'tutor_students',
        studentData,
        where: 'unique_id = ?',
        whereArgs: [tutorStudent.uniqueId],
      );

      // If tutorStudent.days is provided, delete old TutorWeekDay records and re-insert updated ones
      if (tutorStudent.days != null && tutorStudent.days!.isNotEmpty) {
        // Delete the existing TutorWeekDay records for this student
        await db.delete(
          'tutor_week_days',
          where: 'student_id = ?',
          whereArgs: [tutorStudent.uniqueId],
        );

        // Insert updated TutorWeekDay records
        for (TutorWeekDay day in tutorStudent.days!) {
          await db.insert(
            'tutor_week_days',
            day.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      return studentUpdateCount;
    } catch (e) {
      print('Error updating TutorStudent: $e');
      rethrow;
    }
  }


  Future<int> updateTutorStudentDayNot(TutorStudent tutorStudent) async {
    final db = await DatabaseHelper().database;

    // Update the main TutorStudent data
    int r = await db.update(
      'tutor_students',
      tutorStudent.toMap(),
      where: 'unique_id = ?',
      whereArgs: [tutorStudent.uniqueId],
    );

    // First, delete the existing TutorWeekDay records for this student
    r = await db.delete(
      'tutor_week_days',
      where: 'student_id = ?',
      whereArgs: [tutorStudent.uniqueId],
    );

    // Re-insert the updated TutorWeekDay records
    if(tutorStudent.days!=null){
      for (TutorWeekDay day in tutorStudent.days!) {
        await db.insert(
          'tutor_week_days',
          day.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    return r;
  }


  Future<int> deleteTutorStudent(String uniqueId) async {
    final db = await DatabaseHelper().database;

    // Delete associated TutorWeekDay records
    int r = await db.delete(
      'tutor_week_days',
      where: 'student_id = ?',
      whereArgs: [uniqueId],
    );

    // Delete the TutorStudent record
    r = await db.delete(
      'tutor_students',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
    return r;
  }


  Future<TutorStudent?> getTutorStudentDay(String uniqueId) async {
    final db = await DatabaseHelper().database;

    // Query the tutor_students table for the specific student
    final List<Map<String, dynamic>> studentMaps = await db.query(
      'tutor_students',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );

    if (studentMaps.isEmpty) return null;

    // Create the TutorStudent object
    TutorStudent tutorStudent = TutorStudent.fromMap(studentMaps.first);

    // Query the tutor_week_days table for the associated days
    final List<Map<String, dynamic>> daysMaps = await db.query(
      'tutor_week_days',
      where: 'student_id = ?',
      whereArgs: [uniqueId],
    );

    // Map the days to TutorWeekDay objects
    tutorStudent.days = daysMaps.map((dayMap) => TutorWeekDay.fromMap(dayMap)).toList();

    return tutorStudent;
  }

  Future<int> insertTutorStudentDays(TutorStudent tutorStudent) async {
    final db = await DatabaseHelper().database;

    try {
      return await db.transaction((txn) async {
        // Prepare the TutorStudent data without the 'days' field
        Map<String, dynamic> studentData = {
          'id': tutorStudent.id,
          'unique_id': tutorStudent.uniqueId,
          'user_id': tutorStudent.userId,
          'name': tutorStudent.name,
          'phone': tutorStudent.phone,
          'gaurdian_phone': tutorStudent.gaurdianPhone,
          'phone_pass': tutorStudent.phonePass,
          'dob': tutorStudent.dob,
          'education': tutorStudent.education,
          'address': tutorStudent.address,
          'active_status': tutorStudent.activeStatus,
          'admitted_date': tutorStudent.admittedDate?.toIso8601String(),
          'img': tutorStudent.img,
        };

        // Insert the TutorStudent data into the tutor_students table (without the 'days' field)
        int result = await txn.insert(
          'tutor_students',
          studentData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // If TutorStudent has days, insert associated TutorWeekDay records into the tutor_week_days table
        if (tutorStudent.days != null && tutorStudent.days!.isNotEmpty) {
          // Insert each day into the tutor_week_days table as part of the transaction
          for (var day in tutorStudent.days!) {
            await txn.insert(
              'tutor_week_days',
              day.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        return result;
      });
    } catch (e) {
      print('Error inserting TutorStudent: $e');
      rethrow;
    }
  }


  Future<int> insertTutorStudentDaysNott(TutorStudent tutorStudent) async {
    final db = await DatabaseHelper().database;

    try {
      // Prepare the TutorStudent data without the 'days' field
      Map<String, dynamic> studentData = {
        'id': tutorStudent.id,
        'unique_id': tutorStudent.uniqueId,
        'user_id': tutorStudent.userId,
        'name': tutorStudent.name,
        'phone': tutorStudent.phone,
        'gaurdian_phone': tutorStudent.gaurdianPhone,
        'phone_pass': tutorStudent.phonePass,
        'dob': tutorStudent.dob,
        'education': tutorStudent.education,
        'address': tutorStudent.address,
        'active_status': tutorStudent.activeStatus,
        'admitted_date': tutorStudent.admittedDate?.toIso8601String(),
        'img': tutorStudent.img,
      };

      // Insert the TutorStudent data into the tutor_students table (without the 'days' field)
      int result = await db.insert(
        'tutor_students',
        studentData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // If TutorStudent has days, insert associated TutorWeekDay records into the tutor_week_days table
      if (tutorStudent.days != null && tutorStudent.days!.isNotEmpty) {
        // Insert each day asynchronously into the tutor_week_days table
        for (var day in tutorStudent.days!) {
          await db.insert(
            'tutor_week_days',
            day.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      return result;
    } catch (e) {
      print('Error inserting TutorStudent: $e');
      rethrow;
    }
  }


  Future<int> insertTutorStudentDaysNot(TutorStudent tutorStudent) async {
    final db = await DatabaseHelper().database;

    // Insert the main TutorStudent data into the tutor_students table
    int r = await db.insert(
      'tutor_students',
      tutorStudent.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insert associated TutorWeekDay records into the tutor_week_days table if days is not null
    if (tutorStudent.days != null && tutorStudent.days!.isNotEmpty) {
      // Perform the insert operations for all days asynchronously
      for (var day in tutorStudent.days!) {
        await db.insert(
          'tutor_week_days',
          day.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    return r;
  }

  Future<int> updateTutorStudent(TutorStudent student) async {
    final db = await DatabaseHelper().database;

    // Prepare the map with the fields to be updated, excluding 'days'
    Map<String, dynamic> updateData = {
      // 'unique_id': student.uniqueId,
      // 'user_id': student.userId,
      'name': student.name,
      'phone': student.phone,
      'gaurdian_phone': student.gaurdianPhone,
      'phone_pass': student.phonePass,
      'dob': student.dob,
      'education': student.education,
      'address': student.address,
      'active_status': student.activeStatus,
      'admitted_date': student.admittedDate?.toIso8601String(),
      'img': student.img,
      // Exclude 'days' as you don't want to update it
    };

    return await db.update(
      'tutor_students', // Table name
      updateData,
      where: 'unique_id = ?', // Update based on the `id`
      whereArgs: [student.uniqueId],
    );
  }


  Future<int> updateTutorStudentNot(TutorStudent student) async {
    final db = await DatabaseHelper().database;

    return await db.update(
      'tutor_students', // Table name
      student.toMap(),
      where: 'id = ?', // Update based on the `id`
      whereArgs: [student.id],
    );
  }

  Future<int> updateTutorStudentMonth(TutorMonth month) async {
    final db = await DatabaseHelper().database;

    // Prepare the map with all the fields to be updated, excluding 'dates'
    Map<String, dynamic> updateData = {
      // 'unique_id': month.uniqueId,  // Ensure you are updating based on unique_id
      // 'student_id': month.studentId, // Optional, include if you want to update student_id
      // 'user_id': month.userId,       // Optional, include if you want to update user_id
      'month': month.month,          // Include the month field
      'start_date': month.startDate?.toIso8601String(), // Include start_date if needed
      'end_date': month.endDate?.toIso8601String(),     // Include end_date if needed
      'paid_date': month.paidDate?.toIso8601String(),   // Optional, include if you want to update paid_date
      'paid': month.paid,            // Optional, include if you want to update paid amount
      'pay_tk': month.payTk,        // Include pay_tk to be updated
      'paid_tk': month.paidTk,      // Include paid_tk to be updated
      'paid_by': month.paidBy,      // Include paid_by to be updated
    };

    return await db.update(
      'tutor_month', // Table name
      updateData,
      where: 'unique_id = ?', // Update based on the unique_id
      whereArgs: [month.uniqueId],
    );
  }


  Future<int> updateTutorStudentMonthNot(TutorMonth month) async {
    final db = await DatabaseHelper().database;

    return await db.update(
      'tutor_month', // Table name
      month.toMap(),
      where: 'unique_id = ?', // Update based on the `id`
      whereArgs: [month.uniqueId],
    );
  }

  Future<TutorStudent?> getTutorStudent(int id) async {
    final db = await DatabaseHelper().database;

    final List<Map<String, dynamic>> maps = await db.query(
      'tutor_students', // Table name
      where: 'id = ?',  // Filter by `id`
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TutorStudent.fromMap(maps.first);
    } else {
      return null; // Return null if no student is found
    }
  }

  Future<List<TutorStudent>> getTutorStudents() async {
    final db = await DatabaseHelper().database;

    final List<Map<String, dynamic>> maps = await db.query('tutor_students'); // Query all records

    return maps.map((map) => TutorStudent.fromMap(map)).toList();
  }

  Future<List<TutorStudent>> getTutorStudentsDay() async {
    final db = await DatabaseHelper().database;

    // Query all tutor students
    final List<Map<String, dynamic>> maps = await db.query('tutor_students');

    // Loop through each TutorStudent and fetch their associated TutorWeekDay records
    List<TutorStudent> tutorStudents = [];
    for (var map in maps) {
      // Create a TutorStudent object from the main table
      TutorStudent tutorStudent = TutorStudent.fromMap(map);

      // Query the tutor_week_days table for days associated with this tutor student
      final List<Map<String, dynamic>> daysMaps = await db.query(
        'tutor_week_days',
        where: 'student_id = ?',
        whereArgs: [tutorStudent.uniqueId], // Use the uniqueId as the foreign key
      );

      // Map the result to a list of TutorWeekDay objects
      tutorStudent.days = daysMaps.map((dayMap) => TutorWeekDay.fromMap(dayMap)).toList();

      // Add the populated TutorStudent to the list
      tutorStudents.add(tutorStudent);
    }

    return tutorStudents;
  }




  Future<List<TutorMonth>> getTutorStudentMonthsWithDates(String studentId) async {
    Database db = await DatabaseHelper().database;

    try {
      // Step 1: Retrieve all months for the given student ID
      List<Map<String, dynamic>> monthMaps = await db.query(
        'tutor_month',
        where: 'student_id = ?', // Assuming "student_id" is a column in the tutor_month table
        whereArgs: [studentId],
      );

      // Convert the result to a list of TutorMonth objects
      List<TutorMonth> months = monthMaps.map((monthMap) {
        return TutorMonth.fromMap(monthMap); // Ensure TutorMonth has a fromMap method
      }).toList();

      if (months.isNotEmpty) {
        // Extract all unique month IDs to fetch dates in a single query
        List<String?> monthIds = months.map((month) => month.uniqueId).toList();

        // Step 2: Retrieve all associated dates for the retrieved months in a single query
        List<Map<String, dynamic>> dateMaps = await db.query(
          'tutor_date',
          where: 'month_id IN (${List.filled(monthIds.length, '?').join(', ')})',
          whereArgs: monthIds,
        );

        // Organize the dates by month_id using a map
        Map<String, List<TutorDate>> dateGroups = {};
        for (var dateMap in dateMaps) {
          TutorDate date = TutorDate.fromMap(dateMap); // Ensure TutorDate has a fromMap method
          dateGroups.putIfAbsent(date.monthId!, () => []).add(date);
        }

        // Assign the grouped dates to their corresponding months
        for (TutorMonth month in months) {
          month.dates = dateGroups[month.uniqueId] ?? [];
        }
      }

      return months;
    } catch (e) {
      print('Error fetching TutorMonths with dates: $e');
      rethrow;
    }
  }


  // Method to retrieve all months with their associated dates for a student
  Future<List<TutorMonth>> getTutorStudentMonthsWithDatesNot(String studentId) async {
    Database db = await DatabaseHelper().database;

    // Step 1: Retrieve all months for the given student ID
    List<Map<String, dynamic>> monthMaps = await db.query(
      'tutor_month',
      where: 'student_id = ?', // Assuming "student_id" is a column in the tutor_month table
      whereArgs: [studentId],
    );

    // Convert the result to a list of TutorMonth objects
    List<TutorMonth> months = monthMaps.map((monthMap) {
      return TutorMonth.fromMap(monthMap); // Ensure TutorMonth has a fromMap method
    }).toList();

    // Step 2: Retrieve associated dates for each month
    for (TutorMonth month in months) {
      // Query the tutor_date table for the current month's uniqueId
      List<Map<String, dynamic>> dateMaps = await db.query(
        'tutor_date',
        where: 'month_id = ?', // Assuming "month_id" links dates to their month
        whereArgs: [month.uniqueId],
      );

      // Convert the result to a list of TutorDate objects and assign to the month
      month.dates = dateMaps.map((dateMap) {
        return TutorDate.fromMap(dateMap); // Ensure TutorDate has a fromMap method
      }).toList();
    }

    return months;
  }

  Future<int> insertTutorMonth(TutorMonth tutorMonth) async {
    Database db = await DatabaseHelper().database;

    try {
      return await db.transaction((txn) async {
        // Prepare the data without the dates field
        Map<String, dynamic> monthData = {
          'id': tutorMonth.id,
          'unique_id': tutorMonth.uniqueId,
          'student_id': tutorMonth.studentId,
          'user_id': tutorMonth.userId,
          'month': tutorMonth.month,
          'start_date': tutorMonth.startDate?.toIso8601String(),
          'end_date': tutorMonth.endDate?.toIso8601String(),
          'paid_date': tutorMonth.paidDate?.toIso8601String(),
          'paid': tutorMonth.paid,
          'pay_tk': tutorMonth.payTk,
          'paid_tk': tutorMonth.paidTk,
          'paid_by': tutorMonth.paidBy,
        };

        // Insert the TutorMonth data into the tutor_month table (without the 'dates' field)
        int monthInsertId = await txn.insert('tutor_month', monthData);

        if (tutorMonth.dates != null && tutorMonth.dates!.isNotEmpty) {
          // Insert each day into the tutor_date table using the transaction object
          for (var date in tutorMonth.dates!) {
            await txn.insert(
              'tutor_date',
              date.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        return monthInsertId;
      });
    } catch (e) {
      print('Error inserting TutorMonth: $e');
      rethrow;
    }
  }


  Future<int> insertTutorMonthNott(TutorMonth tutorMonth) async {
    Database db = await DatabaseHelper().database;

    try {
      return await db.transaction((txn) async {
        // Prepare the data without the dates field
        Map<String, dynamic> monthData = {
          'id': tutorMonth.id,
          'unique_id': tutorMonth.uniqueId,
          'student_id': tutorMonth.studentId,
          'user_id': tutorMonth.userId,
          'month': tutorMonth.month,
          'start_date': tutorMonth.startDate?.toIso8601String(),
          'end_date': tutorMonth.endDate?.toIso8601String(),
          'paid_date': tutorMonth.paidDate?.toIso8601String(),
          'paid': tutorMonth.paid,
          'pay_tk': tutorMonth.payTk,
          'paid_tk': tutorMonth.paidTk,
          'paid_by': tutorMonth.paidBy,
        };

        // Insert the TutorMonth data into the tutor_month table (without the 'dates' field)
        int monthInsertId = await txn.insert('tutor_month', monthData);

        if (tutorMonth.dates != null && tutorMonth.dates!.isNotEmpty) {
          // Insert each day asynchronously into the tutor_week_days table
          for (var date in tutorMonth.dates!) {
            await db.insert(
              'tutor_date',
              date.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        return monthInsertId;
      });
    } catch (e) {
      print('Error inserting TutorMonth: $e');
      rethrow;
    }
  }


  // Insert TutorMonth and associated TutorDates
  Future<int> insertTutorMonthNot(TutorMonth tutorMonth) async {
    Database db = await DatabaseHelper().database;

    try {
      return await db.transaction((txn) async {
        int monthInsertId = await txn.insert('tutor_month', tutorMonth.toMap());
        for (TutorDate date in tutorMonth.dates!) {
          date.monthId = tutorMonth.uniqueId;
          await txn.insert('tutor_date', date.toMap());
        }
        return monthInsertId;
      });
    } catch (e) {
      print('Error inserting TutorMonth: $e');
      rethrow;
    }


    // Start a transaction to ensure atomicity
    // return await db.transaction((txn) async {
    //   // Insert the TutorMonth into the tutor_month table
    //   int monthInsertId = await txn.insert('tutor_month', tutorMonth.toMap());
    //
    //   // Insert TutorDate records for the inserted TutorMonth
    //   for (TutorDate date in tutorMonth.dates!) {
    //     // Set the monthId in the TutorDate to the uniqueId of the inserted TutorMonth
    //     date.monthId = tutorMonth.uniqueId;
    //     await txn.insert('tutor_date', date.toMap());
    //   }
    //
    //   return monthInsertId;
    // });
  }

  Future<int> updateTutorMonthDates(TutorMonth month) async {
    Database db = await DatabaseHelper().database;

    // Validate if dates are provided, since we need them for further processing
    if (month.dates == null || month.dates!.isEmpty) {
      throw Exception('Cannot update TutorMonth without dates.');
    }

    try {
      return await db.transaction((txn) async {
        // Prepare TutorMonth data excluding 'dates' for the update operation
        Map<String, dynamic> monthData = {
          'unique_id': month.uniqueId,
          'student_id': month.studentId,
          'user_id': month.userId,
          'month': month.month,
          'start_date': month.startDate?.toIso8601String(),
          'end_date': month.endDate?.toIso8601String(),
          'paid_date': month.paidDate?.toIso8601String(),
          'paid': month.paid,
          'pay_tk': month.payTk,
          'paid_tk': month.paidTk,
          'paid_by': month.paidBy,
        };

        // Update the tutor_month table excluding the 'dates' field
        int monthUpdateCount = await txn.update(
          'tutor_month',
          monthData,
          where: 'unique_id = ?',
          whereArgs: [month.uniqueId],
        );

        // Proceed to delete old TutorDate records related to this month
        await txn.delete(
          'tutor_date',
          where: 'month_id = ?',
          whereArgs: [month.uniqueId],
        );

        // Insert updated TutorDate records
        for (TutorDate date in month.dates!) {
          // Set the 'month_id' field in the date to associate it with the correct TutorMonth
          date.monthId = month.uniqueId;  // Ensure 'monthId' is set in each date
          await txn.insert('tutor_date', date.toMap());
        }

        return monthUpdateCount;
      });
    } catch (e) {
      print('Error updating TutorMonth: $e');
      rethrow;
    }
  }


  Future<int> updateTutorMonthDatesNot(TutorMonth month) async {
    Database db = await DatabaseHelper().database;

    if (month.dates == null || month.dates!.isEmpty) {
      throw Exception('Cannot update TutorMonth without dates.');
    }

    try {
      return await db.transaction((txn) async {
        // Update the tutor_month table
        int monthUpdateCount = await txn.update(
          'tutor_month',
          month.toMap(),
          where: 'unique_id = ?',
          whereArgs: [month.uniqueId],
        );

        // Proceed to update dates regardless of whether the month itself was updated
        await txn.delete(
          'tutor_date',
          where: 'month_id = ?',
          whereArgs: [month.uniqueId],
        );

        // Insert updated TutorDates
        for (TutorDate date in month.dates!) {
          await txn.insert('tutor_date', date.toMap());
        }

        return monthUpdateCount;
      });
    } catch (e) {
      print('Error updating TutorMonth: $e');
      rethrow;
    }
  }



  // Future<int> updateTutorMonthDates(TutorMonth month) async {
  //   Database db = await DatabaseHelper().database;
  //
  //   // Start a transaction to ensure atomicity
  //   return await db.transaction((txn) async {
  //     // Update the tutor_month table
  //     int monthUpdateCount = await txn.update(
  //       'tutor_month',
  //       month.toMap(),
  //       where: 'unique_id = ?',
  //       whereArgs: [month.uniqueId],
  //     );
  //
  //     // If the TutorMonth update is successful, update the TutorDates
  //     if (monthUpdateCount > 0) {
  //       // Delete the existing dates before updating
  //       await txn.delete(
  //         'tutor_date',
  //         where: 'month_id = ?',
  //         whereArgs: [month.uniqueId],
  //       );
  //
  //       // Insert updated TutorDates
  //       for (TutorDate date in month.dates!) {
  //         await txn.insert('tutor_date', date.toMap());
  //       }
  //     }
  //
  //     return monthUpdateCount;
  //   });
  // }

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
