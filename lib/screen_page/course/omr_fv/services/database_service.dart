import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/omr_sheet_model.dart';
import '../models/student_model.dart';
import '../models/exam_result_model.dart';
import '../models/course_model.dart';

class DatabaseService {
  static const String _omrSheetsKey = 'omr_sheets';
  static const String _studentsKey = 'students';
  static const String _resultsKey = 'exam_results';
  static const String _coursesKey = 'courses';

  final SharedPreferences _prefs;

  DatabaseService(this._prefs);

  // OMR Sheet Operations
  Future<List<OMRSheet>> getAllOMRSheets() async {
    final String? data = _prefs.getString(_omrSheetsKey);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((json) => OMRSheet.fromJson(json)).toList();
  }

  Future<OMRSheet?> getOMRSheetById(String id) async {
    final sheets = await getAllOMRSheets();
    try {
      return sheets.firstWhere((sheet) => sheet.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveOMRSheet(OMRSheet sheet) async {
    final sheets = await getAllOMRSheets();
    final index = sheets.indexWhere((s) => s.id == sheet.id);

    if (index != -1) {
      sheets[index] = sheet;
    } else {
      sheets.add(sheet);
    }

    await _prefs.setString(_omrSheetsKey, json.encode(sheets.map((s) => s.toJson()).toList()));
  }

  Future<void> deleteOMRSheet(String id) async {
    final sheets = await getAllOMRSheets();
    sheets.removeWhere((sheet) => sheet.id == id);
    await _prefs.setString(_omrSheetsKey, json.encode(sheets.map((s) => s.toJson()).toList()));
  }

  // Student Operations
  Future<List<Student>> getAllStudents() async {
    final String? data = _prefs.getString(_studentsKey);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((json) => Student.fromJson(json)).toList();
  }

  Future<Student?> getStudentById(String studentId) async {
    final students = await getAllStudents();
    try {
      return students.firstWhere((student) => student.studentId == studentId);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveStudent(Student student) async {
    final students = await getAllStudents();
    final index = students.indexWhere((s) => s.id == student.id);

    if (index != -1) {
      students[index] = student;
    } else {
      students.add(student);
    }

    await _prefs.setString(_studentsKey, json.encode(students.map((s) => s.toJson()).toList()));
  }

  // Exam Result Operations
  Future<List<ExamResult>> getAllResults() async {
    final String? data = _prefs.getString(_resultsKey);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((json) => ExamResult.fromJson(json)).toList();
  }

  Future<List<ExamResult>> getResultsByStudent(String studentId) async {
    final results = await getAllResults();
    return results.where((result) => result.studentId == studentId).toList();
  }

  Future<List<ExamResult>> getResultsByOMRSheet(String omrSheetId) async {
    final results = await getAllResults();
    return results.where((result) => result.omrSheetId == omrSheetId).toList();
  }

  Future<void> saveResult(ExamResult result) async {
    final results = await getAllResults();
    results.add(result);
    await _prefs.setString(_resultsKey, json.encode(results.map((r) => r.toJson()).toList()));
  }

  // Course Operations
  Future<List<Course>> getAllCourses() async {
    final String? data = _prefs.getString(_coursesKey);
    if (data == null) return _getDefaultCourses();

    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((json) => Course.fromJson(json)).toList();
  }

  Future<void> saveCourse(Course course) async {
    final courses = await getAllCourses();
    final index = courses.indexWhere((c) => c.id == course.id);

    if (index != -1) {
      courses[index] = course;
    } else {
      courses.add(course);
    }

    await _prefs.setString(_coursesKey, json.encode(courses.map((c) => c.toJson()).toList()));
  }

  List<Course> _getDefaultCourses() {
    return [
      Course(
        id: '1',
        name: 'Science',
        code: 'SCI',
        subjects: ['Physics', 'Chemistry', 'Biology', 'Mathematics'],
      ),
      Course(
        id: '2',
        name: 'Commerce',
        code: 'COM',
        subjects: ['Accounting', 'Business Studies', 'Economics', 'Mathematics'],
      ),
      Course(
        id: '3',
        name: 'Arts',
        code: 'ART',
        subjects: ['History', 'Geography', 'Political Science', 'Sociology'],
      ),
    ];
  }
}