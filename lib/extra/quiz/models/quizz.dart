import 'questionn.dart';

class Quizz {
  final String quizId;
  final String title;
  final int times;
  final String schoolId;
  final List<Questionn> questions;

  Quizz({
    required this.quizId,
    required this.title,
    required this.times,
    required this.schoolId,
    required this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'title': title,
      'times': times,
      'schoolId': schoolId,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  factory Quizz.fromMap(Map<String, dynamic> map) {
    return Quizz(
      quizId: map['quizId'],
      title: map['title'],
      times: map['times'],
      schoolId: map['schoolId'],
      questions: List<Questionn>.from(map['questions']?.map((x) => Questionn.fromMap(x))),
    );
  }
}
