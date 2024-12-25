class Questionn {
  final String questionText;
  final List<String> options;
  final String correctAnswer;

  Questionn({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }

  factory Questionn.fromMap(Map<String, dynamic> map) {
    return Questionn(
      questionText: map['questionText'],
      options: List<String>.from(map['options']),
      correctAnswer: map['correctAnswer'],
    );
  }
}
