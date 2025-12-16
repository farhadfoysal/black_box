// courseDbConfig.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE students ADD COLUMN imagePath TEXT');
          await db.execute('ALTER TABLE students ADD COLUMN imageSyncStatus INTEGER DEFAULT 0');
        }
      },
    );
  }

  // Student CRUD operations
  static Future<int> insertStudent(Map<String, dynamic> student) async {
    final db = await database;
    return await db.insert('students', student,
        conflictAlgorithm: ConflictAlgorithm.replace);
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
    return await db.update('students', student,
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteStudent(int id) async {
    final db = await database;
    return await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> updateSyncStatus(int id, int status) async {
    final db = await database;
    return await db.update('students', {'syncStatus': status},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> updateImageSyncStatus(int id, int status) async {
    final db = await database;
    return await db.update('students', {'imageSyncStatus': status},
        where: 'id = ?', whereArgs: [id]);
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
  static Future<String> saveImageLocally(File imageFile, String studentId) async {
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