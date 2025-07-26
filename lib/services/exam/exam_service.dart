import 'package:flutter/material.dart';
import '../../model/exam/exam_model.dart';

class ExamService with ChangeNotifier {
  final List<ExamModel> _exams = [];
  bool isLoading = false;
  String? error;

  List<ExamModel> get exams => List.unmodifiable(_exams);

  /// Load sample or local exams (simulate fetching from DB/remote)
  Future<void> loadExams() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 1)); // simulate delay

      _exams.clear();
      _exams.addAll([
        ExamModel(
          uniqueId: '1',
          examId: 'math101',
          title: 'Mathematics Final Exam',
          description: 'Covers all topics from semester 1',
          createdAt: DateTime.now().toString(),
          durationMinutes: 120,
          status: 1,
          examType: 'quiz',
          subjectId: 'math',
        ),
        ExamModel(
          uniqueId: '2',
          examId: 'physics101',
          title: 'Physics Midterm',
          description: 'Mechanics and Thermodynamics',
          createdAt: DateTime.now().subtract(const Duration(days: 2)).toString(),
          durationMinutes: 90,
          status: 1,
          examType: 'written',
          subjectId: 'physics',
        ),
      ]);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Return all exams (used by ExamListPage)
  Future<List<ExamModel>> getAllExams() async {
    return exams;
  }

  /// Create a new exam
  Future<void> createNewExam(String examType) async {
    final newExam = ExamModel(
      uniqueId: DateTime.now().millisecondsSinceEpoch.toString(),
      examId: 'newExam${_exams.length + 1}',
      title: 'New $examType Exam',
      description: 'Description of $examType',
      createdAt: DateTime.now().toString(),
      durationMinutes: 60,
      status: 1,
      examType: examType,
      subjectId: 'unknown',
    );
    _exams.add(newExam);
    notifyListeners();
  }

  /// Update exam by replacing it with new model
  Future<void> updateExam(String examId, ExamModel updatedExam) async {
    final index = _exams.indexWhere((e) => e.uniqueId == examId);
    if (index != -1) {
      _exams[index] = updatedExam;
      notifyListeners();
    }
  }

  /// Delete exam by uniqueId
  Future<void> deleteExam(String examId) async {
    _exams.removeWhere((e) => e.uniqueId == examId);
    notifyListeners();
  }

  /// Toggle active/inactive status (0 or 1)
  Future<void> updateExamStatus(String examId, int status) async {
    final index = _exams.indexWhere((e) => e.uniqueId == examId);
    if (index != -1) {
      _exams[index] = _exams[index].copyWith(status: status);
      notifyListeners();
    }
  }

  /// Duplicate an existing exam
  Future<void> duplicateExam(String examId) async {
    final exam = _exams.firstWhere((e) => e.uniqueId == examId);
    final duplicated = exam.copyWith(
      uniqueId: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${exam.title} (Copy)',
      createdAt: DateTime.now().toString(),
    );
    _exams.add(duplicated);
    notifyListeners();
  }
}
