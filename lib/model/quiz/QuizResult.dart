import 'package:equatable/equatable.dart';
import 'quiz.dart';

/// Model class to represent a student's quiz result.
class QuizResult extends Equatable {
  final String studentId;
  final String phoneNumber;
  final Quiz quiz;
  final int correctCount;
  final int incorrectCount;
  final int uncheckedCount;
  final double percentage;
  final DateTime timestamp;

  /// Constructor for creating a [QuizResult] object.
  ///
  /// [studentId] is the unique identifier for the student.
  /// [phoneNumber] is the student's phone number.
  /// [quiz] contains details about the quiz.
  /// [correctCount] is the number of correct answers.
  /// [incorrectCount] is the number of incorrect answers.
  /// [uncheckedCount] is the number of unanswered questions.
  /// [percentage] is the student's score as a percentage.
  /// [timestamp] is the time the result was recorded.
  const QuizResult({
    required this.studentId,
    required this.phoneNumber,
    required this.quiz,
    required this.correctCount,
    required this.incorrectCount,
    required this.uncheckedCount,
    required this.percentage,
    required this.timestamp,
  });

  /// Converts a [QuizResult] object to a map for database storage or API submission.
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'phoneNumber': phoneNumber,
      'quizId': quiz.qId,
      'quizName': quiz.quizName,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'uncheckedCount': uncheckedCount,
      'percentage': percentage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates a [QuizResult] object from a map (e.g., from database or API response).
  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      studentId: map['studentId'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      quiz: Quiz.fromMap(map), // Assuming the Quiz class has a fromMap method
      correctCount: map['correctCount'] ?? 0,
      incorrectCount: map['incorrectCount'] ?? 0,
      uncheckedCount: map['uncheckedCount'] ?? 0,
      percentage: map['percentage'] ?? 0.0,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  factory QuizResult.fromMapp(Map<String, dynamic> map) {
    return QuizResult(
      studentId: map['studentId'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      quiz: Quiz.fromMap(map), // Assuming the Quiz class has a fromMap method
      correctCount: map['correctCount'] ?? 0,
      incorrectCount: map['incorrectCount'] ?? 0,
      uncheckedCount: map['uncheckedCount'] ?? 0,
      percentage: map['percentage'] ?? 0.0,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  List<Object?> get props => [
    studentId,
    phoneNumber,
    quiz,
    correctCount,
    incorrectCount,
    uncheckedCount,
    percentage,
    timestamp,
  ];

  /// Returns a human-readable string representation of the quiz result.
  @override
  String toString() {
    return 'QuizResult(studentId: $studentId, phoneNumber: $phoneNumber, '
        'quizId: ${quiz.qId}, correctCount: $correctCount, '
        'incorrectCount: $incorrectCount, uncheckedCount: $uncheckedCount, '
        'percentage: $percentage, timestamp: $timestamp)';
  }
}
