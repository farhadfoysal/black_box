import 'dart:convert';

class Question {
  int? id;                 // Local SQLite ID (auto-increment or null)
  String? qId;             // Unique Firebase Question ID
  final String quizId;           // ID of the Quiz it belongs to (Required!)
  final String questionTitle;    // Actual question text
  final List<String> questionAnswers;  // List of possible answers
  final String explanation;      // Explanation of correct answer
  final String source;        // Source or reference
  final String type;        // Source or reference
  final String url;        // Source or reference

  Question({
    this.id,
    this.qId,
    required this.quizId,
    required this.questionTitle,
    required this.questionAnswers,
    required this.explanation,
    required this.source,
    required this.type,
    required this.url,
  });

  /// Shuffle the answer choices randomly
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
      'explanation': explanation,
      'source': source,
      'type': type,
      'url': url,
    };
  }

  /// Create from Map from SQLite
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      qId: map['q_id'],
      quizId: map['quiz_id'],
      questionTitle: map['question_title'],
      questionAnswers: List<String>.from(jsonDecode(map['question_answers'] ?? '[]')),
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
      'explanation': explanation,
      'source': source,
      'type': type,
      'url': url,
    };
  }

  /// Create from Firebase JSON
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: null, // Firebase does not use local ids
      qId: json['q_id'],
      quizId: json['quiz_id'],
      questionTitle: json['question_title'],
      questionAnswers: List<String>.from(json['question_answers'] ?? []),
      explanation: json['explanation'],
      source: json['source'],
      type: json['type'],
      url: json['url'],
    );
  }
}


// class Question {
//   String? q_id;  // Nullable String for question ID
//   int? id;        // Nullable int for a numerical ID
//   final String questionTitle;  // The title or question text
//   final List<String> questionAnswers;  // List of possible answers
//   final String explanation;  // Explanation of the answer
//   final String source;  // Source from where the question came
//
//   // Constructor without 'const' as we have non-final fields (q_id and id)
//   Question({
//     this.q_id,
//     this.id,
//     required this.questionTitle,
//     required this.questionAnswers,
//     required this.explanation,
//     required this.source,
//   });
//
//   // Method to get shuffled answers (randomize answer order)
//   List<String> getShuffledAnswers() {
//     final shuffledAnswers = List.of(questionAnswers);  // Create a copy
//     shuffledAnswers.shuffle();  // Shuffle the answers
//     return shuffledAnswers;  // Return the shuffled list
//   }
// }


// class Question {
//   String? q_id;
//   int? id;
//   final String questionTitle;
//   final List<String> questionAnswers;
//   final String explanation;
//   final String source;
//   const Question(this.questionTitle, this.questionAnswers, this.explanation, this.source);
//   List<String> getShuffledAnswers() {
//     final shuffledAnswers = List.of(questionAnswers);
//     shuffledAnswers.shuffle();
//     return shuffledAnswers;
//   }
// }