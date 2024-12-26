class UserAnswer1 {
  final String userId;
  final String questionId;
  final String quizId;
  final String answer;

  UserAnswer1({
    required this.userId,
    required this.questionId,
    required this.quizId,
    required this.answer,
  });

  factory UserAnswer1.fromJson(Map<String, dynamic> json) {
    return UserAnswer1(
      userId: json['userId'],
      questionId: json['questionId'],
      quizId: json['quizId'],
      answer: json['answer'],
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'questionId': questionId,
    'quizId': quizId,
    'answer': answer,
  };
}
