class OMRExamConfig {
  final String examName;
  final int numberOfQuestions;
  final int setNumber;
  final String studentId;
  final String mobileNumber;
  final DateTime examDate;
  final List<String> correctAnswers; // For answer key generation

  OMRExamConfig({
    required this.examName,
    required this.numberOfQuestions,
    required this.setNumber,
    required this.studentId,
    required this.mobileNumber,
    required this.examDate,
    required this.correctAnswers,
  });
}

class OMRResponse {
  final int setNumber;
  final String studentId;
  final String mobileNumber;
  final List<int> answers;
  final double score;

  OMRResponse({
    required this.setNumber,
    required this.studentId,
    required this.mobileNumber,
    required this.answers,
    required this.score,
  });
}