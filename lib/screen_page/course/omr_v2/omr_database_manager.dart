import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseManager {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'omr_system.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exams(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        total_questions INTEGER NOT NULL,
        correct_answers TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT UNIQUE NOT NULL,
        name TEXT,
        mobile TEXT,
        class_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,
        student_id TEXT NOT NULL,
        set_number INTEGER NOT NULL,
        mobile_number TEXT,
        answers TEXT NOT NULL,
        score REAL NOT NULL,
        scanned_at TEXT NOT NULL,
        confidence REAL NOT NULL,
        FOREIGN KEY (exam_id) REFERENCES exams (id),
        FOREIGN KEY (student_id) REFERENCES students (student_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE batch_scans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,
        scan_data TEXT NOT NULL,
        processed_count INTEGER NOT NULL,
        total_count INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (exam_id) REFERENCES exams (id)
      )
    ''');
  }

  // Exam CRUD operations
  static Future<int> insertExam(Exam exam) async {
    final db = await database;
    return await db.insert('exams', exam.toMap());
  }

  static Future<List<Exam>> getExams() async {
    final db = await database;
    final maps = await db.query('exams', orderBy: 'created_at DESC');
    return maps.map((map) => Exam.fromMap(map)).toList();
  }

  // Student CRUD operations
  static Future<int> insertStudent(Student student) async {
    final db = await database;
    return await db.insert('students', student.toMap());
  }

  static Future<Student?> getStudent(String studentId) async {
    final db = await database;
    final maps = await db.query(
      'students',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    return maps.isNotEmpty ? Student.fromMap(maps.first) : null;
  }

  // Results operations
  static Future<int> insertResult(OMRResult result) async {
    final db = await database;
    return await db.insert('results', result.toMap());
  }

  // Add to DatabaseManager class

  // static Future<List<OMRResult>> getExamResults(int examId) async {
  //   final db = await database;
  //   final maps = await db.query(
  //     'results',
  //     where: 'exam_id = ?',
  //     whereArgs: [examId],
  //     orderBy: 'score DESC',
  //   );
  //   return maps.map((map) => OMRResult.fromMap(map)).toList();
  // }
  //
  // static Future<int> createBatchScan(BatchScan batch) async {
  //   final db = await database;
  //   return await db.insert('batch_scans', batch.toMap());
  // }
  //
  // static Future<void> updateBatchScan(BatchScan batch) async {
  //   final db = await database;
  //   await db.update(
  //     'batch_scans',
  //     batch.toMap(),
  //     where: 'id = ?',
  //     whereArgs: [batch.id],
  //   );
  // }

  static Future<List<OMRResult>> getExamResults(int examId) async {
    final db = await database;
    final maps = await db.query(
      'results',
      where: 'exam_id = ?',
      whereArgs: [examId],
      orderBy: 'score DESC',
    );
    return maps.map((map) => OMRResult.fromMap(map)).toList();
  }

  // Batch processing
  static Future<int> createBatchScan(BatchScan batch) async {
    final db = await database;
    return await db.insert('batch_scans', batch.toMap());
  }

  static Future<void> updateBatchScan(BatchScan batch) async {
    final db = await database;
    await db.update(
      'batch_scans',
      batch.toMap(),
      where: 'id = ?',
      whereArgs: [batch.id],
    );
  }
}

class Exam {
  final int? id;
  final String name;
  final DateTime date;
  final int totalQuestions;
  final List<String> correctAnswers;
  final DateTime createdAt;

  Exam({
    this.id,
    required this.name,
    required this.date,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers.join(','),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'],
      name: map['name'],
      date: DateTime.parse(map['date']),
      totalQuestions: map['total_questions'],
      correctAnswers: (map['correct_answers'] as String).split(','),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class Student {
  final int? id;
  final String studentId;
  final String? name;
  final String? mobile;
  final String? className;
  final DateTime createdAt;

  Student({
    this.id,
    required this.studentId,
    this.name,
    this.mobile,
    this.className,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'name': name,
      'mobile': mobile,
      'class_name': className,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      studentId: map['student_id'],
      name: map['name'],
      mobile: map['mobile'],
      className: map['class_name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class OMRResult {
  final int? id;
  final int examId;
  final String studentId;
  final int setNumber;
  final String? mobileNumber;
  final List<int> answers;
  final double score;
  final DateTime scannedAt;
  final double confidence;

  OMRResult({
    this.id,
    required this.examId,
    required this.studentId,
    required this.setNumber,
    this.mobileNumber,
    required this.answers,
    required this.score,
    required this.scannedAt,
    required this.confidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam_id': examId,
      'student_id': studentId,
      'set_number': setNumber,
      'mobile_number': mobileNumber,
      'answers': answers.map((a) => String.fromCharCode(a)).join(''),
      'score': score,
      'scanned_at': scannedAt.toIso8601String(),
      'confidence': confidence,
    };
  }

  factory OMRResult.fromMap(Map<String, dynamic> map) {
    return OMRResult(
      id: map['id'],
      examId: map['exam_id'],
      studentId: map['student_id'],
      setNumber: map['set_number'],
      mobileNumber: map['mobile_number'],
      answers: (map['answers'] as String).codeUnits.toList(),
      score: map['score'],
      scannedAt: DateTime.parse(map['scanned_at']),
      confidence: map['confidence'],
    );
  }
}

class BatchScan {
  int? id;
  int examId;
  List<String> scanData; // List of image paths
  int processedCount;
  int totalCount;
  String status; // 'processing', 'completed', 'failed'
  DateTime createdAt;

  BatchScan({
    this.id,
    required this.examId,
    required this.scanData,
    required this.processedCount,
    required this.totalCount,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam_id': examId,
      'scan_data': scanData.join('||'),
      'processed_count': processedCount,
      'total_count': totalCount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BatchScan.fromMap(Map<String, dynamic> map) {
    return BatchScan(
      id: map['id'],
      examId: map['exam_id'],
      scanData: (map['scan_data'] as String).split('||'),
      processedCount: map['processed_count'],
      totalCount: map['total_count'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}