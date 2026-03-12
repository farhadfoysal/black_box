// courseDbConfig.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../../screen_page/course/omr_fv/models/exam_result_model.dart';
import '../../screen_page/course/omr_fv/models/omr_sheet_model.dart';
import '../../screen_page/course/omr_fv/models/scanned_result.dart';

class StudentDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'blackbox_students.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            program INTEGER,
            studentId TEXT UNIQUE,
            uId TEXT,
            sId TEXT,
            stdId TEXT,
            stdName TEXT,
            stdPhone TEXT,
            stdEmail TEXT,
            homePhone TEXT,
            stdReligion TEXT,
            address TEXT,
            dob TEXT,
            nidBirth TEXT,
            country TEXT,
            unionWord TEXT,
            fatherName TEXT,
            motherName TEXT,
            fNid TEXT,
            mNid TEXT,
            gName TEXT,
            gAddress TEXT,
            gPhone TEXT,
            gEmail TEXT,
            stdImg TEXT,
            major TEXT,
            sMajor TEXT,
            stdPass TEXT,
            gender TEXT,
            addDate TEXT,
            aStatus INTEGER,
            syncKey TEXT,
            syncStatus INTEGER DEFAULT 0,
            uniqueId TEXT,
            currSessId TEXT,
            imagePath TEXT,
            imageSyncStatus INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE omr_sheets (
            id TEXT PRIMARY KEY,
            examName TEXT,
            courseId TEXT,
            subjectName TEXT,
            setNumber INTEGER,
            numberOfQuestions INTEGER,
            correctAnswers TEXT,
            createdAt TEXT,
            examDate TEXT,
            description TEXT,
            isActive INTEGER,
            syncKey TEXT,
            key TEXT,
            syncStatus INTEGER DEFAULT 0,
            uniqueId TEXT,
            uId TEXT,
            sId TEXT
          )
          ''');

        await db.execute('''
          CREATE TABLE scanned_results (
            id TEXT PRIMARY KEY,
            studentId TEXT,
            mobileNumber TEXT,
            setNumber INTEGER,
            detectedAnswers TEXT,
            confidence REAL,
            errorMessage TEXT,
            sheetId TEXT,
            syncKey TEXT,
            key TEXT,
            syncStatus INTEGER DEFAULT 0,
            uniqueId TEXT,
            sId TEXT,
            createdAt TEXT
          )
          ''');
        await db.execute('''
          CREATE TABLE exam_results (
            id TEXT PRIMARY KEY,
            studentId TEXT,
            schoolId TEXT,
            omrSheetId TEXT,
            studentName TEXT,
            examName TEXT,
            studentAnswers TEXT,
            correctAnswers TEXT,
            totalQuestions INTEGER,
            correctCount INTEGER,
            wrongCount INTEGER,
            unansweredCount INTEGER,
            percentage REAL,
            scannedAt TEXT,
            scannedImagePath TEXT,
            syncStatus INTEGER DEFAULT 0
          )
          ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE students ADD COLUMN imagePath TEXT');
          await db.execute(
            'ALTER TABLE students ADD COLUMN imageSyncStatus INTEGER DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS omr_sheets (
              id TEXT PRIMARY KEY,
              examName TEXT,
              courseId TEXT,
              subjectName TEXT,
              setNumber INTEGER,
              numberOfQuestions INTEGER,
              correctAnswers TEXT,
              createdAt TEXT,
              examDate TEXT,
              description TEXT,
              isActive INTEGER,
              syncKey TEXT,
              key TEXT,
              syncStatus INTEGER DEFAULT 0,
              uniqueId TEXT,
              uId TEXT,
              sId TEXT
            )
            ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS scanned_results (
              id TEXT PRIMARY KEY,
              studentId TEXT,
              mobileNumber TEXT,
              setNumber INTEGER,
              detectedAnswers TEXT,
              confidence REAL,
              errorMessage TEXT,
              sheetId TEXT,
              syncKey TEXT,
              key TEXT,
              syncStatus INTEGER DEFAULT 0,
              uniqueId TEXT,
              sId TEXT,
              createdAt TEXT
            )
            ''');
                  }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS exam_results (
              id TEXT PRIMARY KEY,
              studentId TEXT,
              schoolId TEXT,
              omrSheetId TEXT,
              studentName TEXT,
              examName TEXT,
              studentAnswers TEXT,
              correctAnswers TEXT,
              totalQuestions INTEGER,
              correctCount INTEGER,
              wrongCount INTEGER,
              unansweredCount INTEGER,
              percentage REAL,
              scannedAt TEXT,
              scannedImagePath TEXT,
              syncStatus INTEGER DEFAULT 0
            )
            ''');
                  }
      },
    );
  }

  // Student CRUD operations
  static Future<int> insertStudent(Map<String, dynamic> student) async {
    final db = await database;
    return await db.insert(
      'students',
      student,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getAllStudents() async {
    final db = await database;
    return await db.query('students', orderBy: 'stdName ASC');
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedStudents() async {
    final db = await database;
    return await db.query('students', where: 'syncStatus = ?', whereArgs: [0]);
  }

  static Future<int> updateStudent(int id, Map<String, dynamic> student) async {
    final db = await database;
    return await db.update(
      'students',
      student,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> updateStudentByUniqueId(
    String id,
    Map<String, dynamic> student,
  ) async {
    final db = await database;
    return await db.update(
      'students',
      student,
      where: 'uniqueId = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteStudent(int id) async {
    final db = await database;
    return await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteStudentByUniqueId(String id) async {
    final db = await database;
    return await db.delete('students', where: 'uniqueId = ?', whereArgs: [id]);
  }

  static Future<int> updateSyncStatus(int id, int status) async {
    final db = await database;
    return await db.update(
      'students',
      {'syncStatus': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> updateImageSyncStatus(int id, int status) async {
    final db = await database;
    return await db.update(
      'students',
      {'imageSyncStatus': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }




  static Future<int> insertOMRSheet(OMRSheet sheet) async {
    final db = await database;

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
    final db = await database;

    final result = await db.query(
      'omr_sheets',
      orderBy: 'createdAt DESC',
    );

    return result.map((map) {
      return OMRSheet(
        id: map['id'] as String,
        examName: map['examName'] as String,
        courseId: map['courseId'] as String,
        subjectName: map['subjectName'] as String,
        setNumber: map['setNumber'] as int,
        numberOfQuestions: map['numberOfQuestions'] as int,
        correctAnswers:
        List<String>.from(jsonDecode(map['correctAnswers'] as String)),
        createdAt: DateTime.parse(map['createdAt'] as String),
        examDate: DateTime.parse(map['examDate'] as String),
        description: map['description'] as String?,
        isActive: (map['isActive'] as int) == 1,
        syncKey: map['syncKey'] as String?,
        key: map['key'] as String?,
        syncStatus: map['syncStatus'] as int?,
        uniqueId: map['uniqueId'] as String?,
        uId: map['uId'] as String?,
        sId: map['sId'] as String?,
      );
    }).toList();
  }

  static Future<List<OMRSheet>> getUnsyncedOMRSheets() async {
    final db = await database;

    final result = await db.query(
      'omr_sheets',
      where: 'syncStatus = ?',
      whereArgs: [0],
    );

    return result.map((map) {
      return OMRSheet.fromJson({
        ...map,
        'correctAnswers': jsonDecode(map['correctAnswers'] as String),
      });
    }).toList();
  }


  static Future<int> updateOMRSheet(String id, OMRSheet sheet) async {
    final db = await database;

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
        'syncKey': sheet.syncKey,
        'key': sheet.key,
        'syncStatus': sheet.syncStatus,
        'uniqueId': sheet.uniqueId,
        'uId': sheet.uId,
        'sId': sheet.sId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  static Future<int> deleteOMRSheet(String id) async {
    final db = await database;

    return await db.delete(
      'omr_sheets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> updateOMRSheetSyncStatus(String id, int status) async {
    final db = await database;

    return await db.update(
      'omr_sheets',
      {'syncStatus': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> updateOMRSyncStatus(String id, int status) async {
    final db = await database;

    return await db.update(
      'omr_sheets',
      {'syncStatus': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  static Future<List<OMRSheet>> getOMRByCourse(String courseId) async {
    final db = await database;

    final result = await db.query(
      'omr_sheets',
      where: 'courseId = ?',
      whereArgs: [courseId],
    );

    return result.map((map) {
      return OMRSheet.fromJson({
        ...map,
        'correctAnswers': jsonDecode(map['correctAnswers'] as String),
      });
    }).toList();
  }


  static Future<int> insertScannedResult(ScannedResult result) async {
    final db = await database;

    return await db.insert(
      'scanned_results',
      {
        'id': result.id,
        'studentId': result.studentId,
        'mobileNumber': result.mobileNumber,
        'setNumber': result.setNumber,
        'detectedAnswers': jsonEncode(result.detectedAnswers),
        'confidence': result.confidence,
        'errorMessage': result.errorMessage,
        'sheetId': result.sheetId,
        'syncKey': result.syncKey,
        'key': result.key,
        'syncStatus': result.syncStatus ?? 0,
        'uniqueId': result.uniqueId,
        'sId': result.sId,
        'createdAt': result.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  static Future<List<ScannedResult>> getAllScannedResults() async {
    final db = await database;

    final result = await db.query(
      'scanned_results',
      orderBy: 'createdAt DESC',
    );

    return result.map((map) {
      return ScannedResult.fromMap({
        ...map,
        'detectedAnswers': jsonDecode(map['detectedAnswers'] as String),
      });
    }).toList();
  }


  static Future<List<ScannedResult>> getResultsBySheet(String sheetId) async {
    final db = await database;

    final result = await db.query(
      'scanned_results',
      where: 'sheetId = ?',
      whereArgs: [sheetId],
    );

    return result.map((map) {
      return ScannedResult.fromMap({
        ...map,
        'detectedAnswers': jsonDecode(map['detectedAnswers'] as String),
      });
    }).toList();
  }


  static Future<List<ScannedResult>> getUnsyncedResults() async {
    final db = await database;

    final result = await db.query(
      'scanned_results',
      where: 'syncStatus = ?',
      whereArgs: [0],
    );

    return result.map((map) {
      return ScannedResult.fromMap({
        ...map,
        'detectedAnswers': jsonDecode(map['detectedAnswers'] as String),
      });
    }).toList();
  }


  static Future<int> updateResultSyncStatus(String id, int status) async {
    final db = await database;

    return await db.update(
      'scanned_results',
      {'syncStatus': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  static Future<int> deleteScannedResult(String id) async {
    final db = await database;

    return await db.delete(
      'scanned_results',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> updateScannedResult(
      String id,
      ScannedResult result,
      ) async {
    final db = await database;

    return await db.update(
      'scanned_results',
      {
        'studentId': result.studentId,
        'mobileNumber': result.mobileNumber,
        'setNumber': result.setNumber,
        'detectedAnswers': jsonEncode(result.detectedAnswers),
        'confidence': result.confidence,
        'errorMessage': result.errorMessage,
        'sheetId': result.sheetId,
        'syncKey': result.syncKey,
        'key': result.key,
        'syncStatus': result.syncStatus,
        'uniqueId': result.uniqueId,
        'sId': result.sId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  static Future<int> insertExamResult(ExamResult result) async {

    final db = await database;

    return await db.insert(
      'exam_results',
      {
        'id': result.id,
        'studentId': result.studentId,
        'schoolId': result.schoolId,
        'omrSheetId': result.omrSheetId,
        'studentName': result.studentName,
        'examName': result.examName,
        'studentAnswers': jsonEncode(result.studentAnswers),
        'correctAnswers': jsonEncode(result.correctAnswers),
        'totalQuestions': result.totalQuestions,
        'correctCount': result.correctCount,
        'wrongCount': result.wrongCount,
        'unansweredCount': result.unansweredCount,
        'percentage': result.percentage,
        'scannedAt': result.scannedAt.toIso8601String(),
        'scannedImagePath': result.scannedImagePath,
        'syncStatus': 0
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  static Future<List<ExamResult>> getAllExamResults() async {

    final db = await database;

    final result = await db.query(
      'exam_results',
      orderBy: 'scannedAt DESC',
    );

    return result.map((map) {

      return ExamResult(
        id: map['id'] as String,
        studentId: map['studentId'] as String,
        schoolId: map['schoolId'] as String,
        omrSheetId: map['omrSheetId'] as String,
        studentName: map['studentName'] as String,
        examName: map['examName'] as String,
        studentAnswers:
        List<String>.from(jsonDecode(map['studentAnswers'] as String)),
        correctAnswers:
        List<String>.from(jsonDecode(map['correctAnswers'] as String)),
        totalQuestions: map['totalQuestions'] as int,
        correctCount: map['correctCount'] as int,
        wrongCount: map['wrongCount'] as int,
        unansweredCount: map['unansweredCount'] as int,
        percentage: map['percentage'] as double,
        scannedAt: DateTime.parse(map['scannedAt'] as String),
        scannedImagePath: map['scannedImagePath'] as String?,
      );

    }).toList();
  }

  static Future<List<ExamResult>> getResultsByStudent(String studentId) async {

    final db = await database;

    final result = await db.query(
      'exam_results',
      where: 'studentId = ?',
      whereArgs: [studentId],
    );

    return result.map((map) {

      return ExamResult(
        id: map['id'] as String,
        studentId: map['studentId'] as String,
        schoolId: map['schoolId'] as String,
        omrSheetId: map['omrSheetId'] as String,
        studentName: map['studentName'] as String,
        examName: map['examName'] as String,
        studentAnswers:
        List<String>.from(jsonDecode(map['studentAnswers'] as String)),
        correctAnswers:
        List<String>.from(jsonDecode(map['correctAnswers'] as String)),
        totalQuestions: map['totalQuestions'] as int,
        correctCount: map['correctCount'] as int,
        wrongCount: map['wrongCount'] as int,
        unansweredCount: map['unansweredCount'] as int,
        percentage: map['percentage'] as double,
        scannedAt: DateTime.parse(map['scannedAt'] as String),
        scannedImagePath: map['scannedImagePath'] as String?,
      );

    }).toList();
  }


  static Future<int> deleteExamResult(String id) async {

    final db = await database;

    return await db.delete(
      'exam_results',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> updateExamResult(
      String id,
      ExamResult result,
      ) async {

    final db = await database;

    return await db.update(
      'exam_results',
      {
        'studentId': result.studentId,
        'schoolId': result.schoolId,
        'omrSheetId': result.omrSheetId,
        'studentName': result.studentName,
        'examName': result.examName,
        'studentAnswers': jsonEncode(result.studentAnswers),
        'correctAnswers': jsonEncode(result.correctAnswers),
        'totalQuestions': result.totalQuestions,
        'correctCount': result.correctCount,
        'wrongCount': result.wrongCount,
        'unansweredCount': result.unansweredCount,
        'percentage': result.percentage,
        'scannedAt': result.scannedAt.toIso8601String(),
        'scannedImagePath': result.scannedImagePath,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<ExamResult>> getUnsyncedExamResults() async {

    final db = await database;

    final result = await db.query(
      'exam_results',
      where: 'syncStatus = ?',
      whereArgs: [0],
    );

    return result.map((map) {

      return ExamResult(
        id: map['id'] as String,
        studentId: map['studentId'] as String,
        schoolId: map['schoolId'] as String,
        omrSheetId: map['omrSheetId'] as String,
        studentName: map['studentName'] as String,
        examName: map['examName'] as String,
        studentAnswers:
        List<String>.from(jsonDecode(map['studentAnswers'] as String)),
        correctAnswers:
        List<String>.from(jsonDecode(map['correctAnswers'] as String)),
        totalQuestions: map['totalQuestions'] as int,
        correctCount: map['correctCount'] as int,
        wrongCount: map['wrongCount'] as int,
        unansweredCount: map['unansweredCount'] as int,
        percentage: map['percentage'] as double,
        scannedAt: DateTime.parse(map['scannedAt'] as String),
        scannedImagePath: map['scannedImagePath'] as String?,
      );

    }).toList();
  }

  static Future<int> updateExamResultSyncStatus(
      String id,
      int status,
      ) async {

    final db = await database;

    return await db.update(
      'exam_results',
      {'syncStatus': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<ExamResult>> getResultsBySchool(String schoolId) async {

    final db = await database;

    final maps = await db.query(
      'exam_results',
      where: 'schoolId = ?',
      whereArgs: [schoolId],
      orderBy: 'scannedAt DESC',
    );

    return maps.map((e) => ExamResult.fromMap(e)).toList();

  }

  // Close database
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

// Image handling utilities
class ImageHandler {
  static Future<String> saveImageLocally(
    File imageFile,
    String studentId,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/student_images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'student_${studentId}_$timestamp.jpg';
      final savedImage = await imageFile.copy('${imagesDir.path}/$fileName');

      return savedImage.path;
    } catch (e) {
      print('Error saving image locally: $e');
      rethrow;
    }
  }

  static Future<String?> convertImageToBase64(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) return null;

      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  static Future<Uint8List?> getImageBytes(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) return null;

      return await imageFile.readAsBytes();
    } catch (e) {
      print('Error reading image bytes: $e');
      return null;
    }
  }
}
