import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../screen_page/course/omr_fv/models/omr_sheet_model.dart';
import 'courseDbConfig.dart';


class OMRDatabase {

  static Future<int> insertOMRSheet(OMRSheet sheet) async {
    final db = await StudentDatabase.database;

    return await db.insert(
      'omr_sheets',
      {
        'id': sheet.id,
        'examName': sheet.examName,
        'courseId': sheet.courseId,
        'subjectName': sheet.subjectName,
        'setNumber': sheet.setNumber,
        'numberOfQuestions': sheet.numberOfQuestions,
        'correctAnswers': jsonEncode(sheet.correctAnswers),
        'createdAt': sheet.createdAt.toIso8601String(),
        'examDate': sheet.examDate.toIso8601String(),
        'description': sheet.description,
        'isActive': sheet.isActive ? 1 : 0,
        'syncKey': sheet.syncKey,
        'key': sheet.key,
        'syncStatus': sheet.syncStatus ?? 0,
        'uniqueId': sheet.uniqueId,
        'uId': sheet.uId,
        'sId': sheet.sId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<OMRSheet>> getAllOMRSheets() async {
    final db = await StudentDatabase.database;

    final maps = await db.query('omr_sheets', orderBy: 'createdAt DESC');

    return maps.map((map) {
      return OMRSheet(
        id: map['id'] as String,
        examName: map['examName'] as String,
        courseId: map['courseId'] as String,
        subjectName: map['subjectName'] as String,
        setNumber: map['setNumber'] as int,
        numberOfQuestions: map['numberOfQuestions'] as int,
        correctAnswers: List<String>.from(
            jsonDecode(map['correctAnswers'] as String)),
        createdAt: DateTime.parse(map['createdAt'] as String),
        examDate: DateTime.parse(map['examDate'] as String),
        description: map['description'] as String?,
        isActive: (map['isActive'] as int) == 1,
        syncStatus: map['syncStatus'] as int?,
        uniqueId: map['uniqueId'] as String?,
        uId: map['uId'] as String?,
        sId: map['sId'] as String?,
      );
    }).toList();
  }

  static Future<List<OMRSheet>> getUnsyncedOMRSheets() async {
    final db = await StudentDatabase.database;

    final maps = await db.query(
      'omr_sheets',
      where: 'syncStatus = ?',
      whereArgs: [0],
    );

    return maps.map((map) {
      return OMRSheet(
        id: map['id'] as String,
        examName: map['examName'] as String,
        courseId: map['courseId'] as String,
        subjectName: map['subjectName'] as String,
        setNumber: map['setNumber'] as int,
        numberOfQuestions: map['numberOfQuestions'] as int,
        correctAnswers: List<String>.from(
            jsonDecode(map['correctAnswers'] as String)),
        createdAt: DateTime.parse(map['createdAt'] as String),
        examDate: DateTime.parse(map['examDate'] as String),
      );
    }).toList();
  }

  static Future<int> updateOMRSheet(String id, OMRSheet sheet) async {
    final db = await StudentDatabase.database;

    return await db.update(
      'omr_sheets',
      {
        'examName': sheet.examName,
        'courseId': sheet.courseId,
        'subjectName': sheet.subjectName,
        'setNumber': sheet.setNumber,
        'numberOfQuestions': sheet.numberOfQuestions,
        'correctAnswers': jsonEncode(sheet.correctAnswers),
        'examDate': sheet.examDate.toIso8601String(),
        'description': sheet.description,
        'isActive': sheet.isActive ? 1 : 0,
        'syncStatus': sheet.syncStatus,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteOMRSheet(String id) async {
    final db = await StudentDatabase.database;

    return await db.delete(
      'omr_sheets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> updateSyncStatus(String id, int status) async {
    final db = await StudentDatabase.database;

    return await db.update(
      'omr_sheets',
      {'syncStatus': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}