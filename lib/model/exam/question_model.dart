import 'dart:convert';

class QuestionModel {
  int? id;                 // Local SQLite ID (auto-increment or null)
  String? qId;             // Unique Firebase Question ID
  final String quizId;     // ID of the Quiz it belongs to
  final String questionTitle;
  final List<String> questionAnswers;
  final String? correctAnswer;
  final String explanation;
  final String source;
  final String type;       // e.g., 'mcq', 'text', 'image', 'video'
  final String url;        // Optional image/video/audio URL if applicable

  QuestionModel({
    this.id,
    this.qId,
    required this.quizId,
    required this.questionTitle,
    required this.questionAnswers,
    required this.correctAnswer,
    required this.explanation,
    required this.source,
    required this.type,
    required this.url,
  });

  /// Returns a shuffled copy of the answer choices
  List<String> getShuffledAnswers() {
    final shuffledAnswers = List<String>.from(questionAnswers);
    shuffledAnswers.shuffle();
    return shuffledAnswers;
  }

  /// Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'q_id': qId,
      'quiz_id': quizId,
      'question_title': questionTitle,
      'question_answers': jsonEncode(questionAnswers),
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'source': source,
      'type': type,
      'url': url,
    };
  }

  /// Create from Map (for SQLite)
  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'],
      qId: map['q_id'],
      quizId: map['quiz_id'],
      questionTitle: map['question_title'],
      questionAnswers: List<String>.from(jsonDecode(map['question_answers'] ?? '[]')),
      correctAnswer: map['correct_answer'],
      explanation: map['explanation'],
      source: map['source'],
      type: map['type'],
      url: map['url'],
    );
  }

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'q_id': qId,
      'quiz_id': quizId,
      'question_title': questionTitle,
      'question_answers': questionAnswers,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'source': source,
      'type': type,
      'url': url,
    };
  }

  /// Create from Firebase JSON
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: null,
      qId: json['q_id'],
      quizId: json['quiz_id'],
      questionTitle: json['question_title'],
      questionAnswers: List<String>.from(json['question_answers'] ?? []),
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'],
      source: json['source'],
      type: json['type'],
      url: json['url'],
    );
  }
}
