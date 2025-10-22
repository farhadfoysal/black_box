class OMRExamConfig {
  final String examName;
  final int numberOfQuestions;
  final int setNumber;
  final String studentId;
  final String mobileNumber;
  final DateTime examDate;
  final List<String> correctAnswers;
  final String studentName;
  final String className;
  final String subjectCode;
  final String registrationNumber;
  final String subjectName;
  final String department;
  final String roomNumber;
  final String branch;

  OMRExamConfig({
    required this.examName,
    required this.numberOfQuestions,
    required this.setNumber,
    required this.studentId,
    required this.mobileNumber,
    required this.examDate,
    required this.correctAnswers,
    this.studentName = '',
    this.className = '',
    this.subjectCode = '',
    this.registrationNumber = '',
    this.subjectName = '',
    this.department = '',
    this.roomNumber = '',
    this.branch = '',
  });
}

class OMRResponse {
  final int setNumber;
  final String studentId;
  final String mobileNumber;
  final List<int> answers;
  final double score;
  final int correctAnswers;
  final int totalQuestions;
  final DateTime submissionTime;

  OMRResponse({
    required this.setNumber,
    required this.studentId,
    required this.mobileNumber,
    required this.answers,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.submissionTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'studentId': studentId,
      'mobileNumber': mobileNumber,
      'answers': answers,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'submissionTime': submissionTime.toIso8601String(),
    };
  }
}