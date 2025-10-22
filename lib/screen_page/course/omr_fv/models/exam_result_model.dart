class ExamResult {
  final String id;
  final String studentId;
  final String omrSheetId;
  final String studentName;
  final String examName;
  final List<String> studentAnswers;
  final List<String> correctAnswers;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int unansweredCount;
  final double percentage;
  final DateTime scannedAt;
  final String? scannedImagePath;

  ExamResult({
    required this.id,
    required this.studentId,
    required this.omrSheetId,
    required this.studentName,
    required this.examName,
    required this.studentAnswers,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.unansweredCount,
    required this.percentage,
    required this.scannedAt,
    this.scannedImagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'omrSheetId': omrSheetId,
    'studentName': studentName,
    'examName': examName,
    'studentAnswers': studentAnswers,
    'correctAnswers': correctAnswers,
    'totalQuestions': totalQuestions,
    'correctCount': correctCount,
    'wrongCount': wrongCount,
    'unansweredCount': unansweredCount,
    'percentage': percentage,
    'scannedAt': scannedAt.toIso8601String(),
    'scannedImagePath': scannedImagePath,
  };

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
    id: json['id'],
    studentId: json['studentId'],
    omrSheetId: json['omrSheetId'],
    studentName: json['studentName'],
    examName: json['examName'],
    studentAnswers: List<String>.from(json['studentAnswers']),
    correctAnswers: List<String>.from(json['correctAnswers']),
    totalQuestions: json['totalQuestions'],
    correctCount: json['correctCount'],
    wrongCount: json['wrongCount'],
    unansweredCount: json['unansweredCount'],
    percentage: json['percentage'].toDouble(),
    scannedAt: DateTime.parse(json['scannedAt']),
    scannedImagePath: json['scannedImagePath'],
  );
}