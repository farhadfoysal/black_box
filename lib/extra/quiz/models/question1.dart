enum QuestionType { mcq, text, image, url, driveLink }

class Question1 {
  final String id;
  final QuestionType type;
  final String questionText;
  final List<String>? options; // For MCQs
  final String? correctAnswer; // For validation
  final String? mediaUrl; // For image/URL/Drive links
  final String quizId;
  final String schoolId;

  Question1({
    required this.id,
    required this.type,
    required this.questionText,
    this.options,
    this.correctAnswer,
    this.mediaUrl,
    required this.quizId,
    required this.schoolId,
  });

  factory Question1.fromJson(Map<String, dynamic> json) {
    return Question1(
      id: json['id'],
      type: QuestionType.values.firstWhere((e) => e.name == json['type']),
      questionText: json['questionText'],
      options: (json['options'] as List?)?.cast<String>(),
      correctAnswer: json['correctAnswer'],
      mediaUrl: json['mediaUrl'],
      quizId: json['quizId'],
      schoolId: json['schoolId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'questionText': questionText,
    'options': options,
    'correctAnswer': correctAnswer,
    'mediaUrl': mediaUrl,
    'quizId': quizId,
    'schoolId': schoolId,
  };
}
