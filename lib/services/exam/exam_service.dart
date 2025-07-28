import 'package:flutter/material.dart';
import '../../model/exam/exam_model.dart';
import '../../model/exam/question_model.dart';

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
          createdAt: DateTime.now().toIso8601String(),
          durationMinutes: 120,
          status: 1,
          examType: 'quiz',
          subjectId: 'math',
          questions: [
            QuestionModel(
              qId: 'q1',
              quizId: 'math101',
              questionTitle: 'What is 5 + 7?',
              questionAnswers: ['10', '11', '12', '13'],
              correctAnswer: '12',
              explanation: '5 + 7 = 12',
              source: 'Class Notes',
              type: 'mcq',
              url: '',
            ),
            QuestionModel(
              qId: 'q2',
              quizId: 'math101',
              questionTitle: 'Solve: 2x = 8. What is x?',
              questionAnswers: [],
              correctAnswer: null,
              explanation: 'Divide both sides by 2',
              source: 'Chapter 2',
              type: 'text',
              url: '',
            ),
            QuestionModel(
              qId: 'q3',
              quizId: 'math101',
              questionTitle: 'Upload a graph of a quadratic equation.',
              questionAnswers: [],
              correctAnswer: null,
              explanation: '',
              source: 'Graphing Practice',
              type: 'image',
              url: '',
            ),
            QuestionModel(
              qId: 'q4',
              quizId: 'math101',
              questionTitle: 'Watch and answer: Introduction to Algebra',
              questionAnswers: [],
              correctAnswer: null,
              explanation: '',
              source: 'YouTube Lesson',
              type: 'video',
              url: 'https://youtu.be/HXHphpDJ9T0?si=HQWku725Gc5xRRTY',
            ),
          ],
        ),
        ExamModel(
          uniqueId: '2',
          examId: 'physics101',
          title: 'Physics Midterm',
          description: 'Mechanics and Thermodynamics',
          createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          durationMinutes: 90,
          status: 1,
          examType: 'written',
          subjectId: 'physics',
          questions: [
            QuestionModel(
              qId: 'q1',
              quizId: 'physics101',
              questionTitle: 'State Newton’s Second Law of Motion.',
              questionAnswers: [],
              correctAnswer: null,
              explanation: '',
              source: 'Lecture 3',
              type: 'text',
              url: '',
            ),
            QuestionModel(
              qId: 'q2',
              quizId: 'physics101',
              questionTitle: 'Upload a diagram of the Carnot engine.',
              questionAnswers: [],
              correctAnswer: null,
              explanation: '',
              source: 'Thermodynamics Book',
              type: 'image',
              url: '',
            ),
            QuestionModel(
              qId: 'q3',
              quizId: 'physics101',
              questionTitle: 'What is the acceleration due to gravity on Earth?',
              questionAnswers: ['9.8 m/s²', '8.9 m/s²', '10 m/s²', '9.2 m/s²'],
              correctAnswer: '9.8 m/s²',
              explanation: 'Standard value at sea level',
              source: 'Physics Textbook',
              type: 'mcq',
              url: '',
            ),
            QuestionModel(
              qId: 'q4',
              quizId: 'physics101',
              questionTitle: 'Watch and explain: Laws of Thermodynamics',
              questionAnswers: [],
              correctAnswer: null,
              explanation: '',
              source: 'YouTube Reference',
              type: 'video',
              url: 'https://www.youtube.com/watch?v=G3rnyjWZkXo',
            ),
          ],
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



  Future<List<ExamModel>> getUserExams() async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      ExamModel(
        uniqueId: '1',
        examId: 'math101',
        title: 'Mathematics Final Exam',
        description: 'Covers all topics from semester 1',
        createdAt: DateTime.now().toIso8601String(),
        durationMinutes: 120,
        status: 1,
        examType: 'quiz',
        subjectId: 'math',
        questions: [
          QuestionModel(
            qId: 'q1',
            quizId: 'math101',
            questionTitle: 'What is 5 + 7?',
            questionAnswers: ['10', '11', '12', '13'],
            correctAnswer: '12',
            explanation: '5 + 7 = 12',
            source: 'Class Notes',
            type: 'mcq',
            url: '',
          ),
          QuestionModel(
            qId: 'q2',
            quizId: 'math101',
            questionTitle: 'Solve: 2x = 8. What is x?',
            questionAnswers: [],
            correctAnswer: null,
            explanation: 'Divide both sides by 2',
            source: 'Chapter 2',
            type: 'text',
            url: '',
          ),
          QuestionModel(
            qId: 'q3',
            quizId: 'math101',
            questionTitle: 'Upload a graph of a quadratic equation.',
            questionAnswers: [],
            correctAnswer: null,
            explanation: '',
            source: 'Graphing Practice',
            type: 'image',
            url: '',
          ),
          QuestionModel(
            qId: 'q4',
            quizId: 'math101',
            questionTitle: 'Watch and answer: Introduction to Algebra',
            questionAnswers: [],
            correctAnswer: null,
            explanation: '',
            source: 'YouTube Lesson',
            type: 'video',
            url: 'https://youtu.be/HXHphpDJ9T0?si=HQWku725Gc5xRRTY',
          ),
        ],
      ),
      ExamModel(
        uniqueId: '2',
        examId: 'physics101',
        title: 'Physics Midterm',
        description: 'Mechanics and Thermodynamics',
        createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        durationMinutes: 90,
        status: 1,
        examType: 'written',
        subjectId: 'physics',
        questions: [
          QuestionModel(
            qId: 'q1',
            quizId: 'physics101',
            questionTitle: 'State Newton’s Second Law of Motion.',
            questionAnswers: [],
            correctAnswer: null,
            explanation: '',
            source: 'Lecture 3',
            type: 'text',
            url: '',
          ),
          QuestionModel(
            qId: 'q2',
            quizId: 'physics101',
            questionTitle: 'Upload a diagram of the Carnot engine.',
            questionAnswers: [],
            correctAnswer: null,
            explanation: '',
            source: 'Thermodynamics Book',
            type: 'image',
            url: '',
          ),
          QuestionModel(
            qId: 'q3',
            quizId: 'physics101',
            questionTitle: 'What is the acceleration due to gravity on Earth?',
            questionAnswers: ['9.8 m/s²', '8.9 m/s²', '10 m/s²', '9.2 m/s²'],
            correctAnswer: '9.8 m/s²',
            explanation: 'Standard value at sea level',
            source: 'Physics Textbook',
            type: 'mcq',
            url: '',
          ),
          QuestionModel(
            qId: 'q4',
            quizId: 'physics101',
            questionTitle: 'Watch and explain: Laws of Thermodynamics',
            questionAnswers: [],
            correctAnswer: null,
            explanation: '',
            source: 'YouTube Reference',
            type: 'video',
            url: 'https://youtu.be/HXHphpDJ9T0?si=HQWku725Gc5xRRTY',
          ),
        ],
      ),
    ];
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
