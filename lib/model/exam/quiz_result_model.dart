class QuizResultModel {
  int? id; // Local SQLite auto-increment ID
  final String studentId;
  final String phoneNumber;
  final String quizId;
  final String quizName;
  final int correctCount;
  final int incorrectCount;
  final int uncheckedCount;
  final double percentage;
  final DateTime timestamp;

  QuizResultModel({
    this.id,
    required this.studentId,
    required this.phoneNumber,
    required this.quizId,
    required this.quizName,
    required this.correctCount,
    required this.incorrectCount,
    required this.uncheckedCount,
    required this.percentage,
    required this.timestamp,
  });

  /// Convert to Map for SQLite
  Map<String, dynamic> toMap() => {
    'id': id,
    'student_id': studentId,
    'phone_number': phoneNumber,
    'quiz_id': quizId,
    'quiz_name': quizName,
    'correct_count': correctCount,
    'incorrect_count': incorrectCount,
    'unchecked_count': uncheckedCount,
    'percentage': percentage,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Create from Map (SQLite)
  factory QuizResultModel.fromMap(Map<String, dynamic> map) => QuizResultModel(
    id: map['id'],
    studentId: map['student_id'],
    phoneNumber: map['phone_number'],
    quizId: map['quiz_id'],
    quizName: map['quiz_name'],
    correctCount: map['correct_count'],
    incorrectCount: map['incorrect_count'],
    uncheckedCount: map['unchecked_count'],
    percentage: (map['percentage'] as num).toDouble(),
    timestamp: DateTime.parse(map['timestamp']),
  );

  /// Convert to JSON for Firebase / API
  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'phone_number': phoneNumber,
    'quiz_id': quizId,
    'quiz_name': quizName,
    'correct_count': correctCount,
    'incorrect_count': incorrectCount,
    'unchecked_count': uncheckedCount,
    'percentage': percentage,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Create from JSON (Firebase)
  factory QuizResultModel.fromJson(Map<String, dynamic> json) =>
      QuizResultModel(
        id: null,
        studentId: json['student_id'],
        phoneNumber: json['phone_number'],
        quizId: json['quiz_id'],
        quizName: json['quiz_name'],
        correctCount: json['correct_count'],
        incorrectCount: json['incorrect_count'],
        uncheckedCount: json['unchecked_count'],
        percentage: (json['percentage'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp']),
      );
}
