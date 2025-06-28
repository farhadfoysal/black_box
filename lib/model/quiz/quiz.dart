class Quiz {
  int? id; // Local SQLite id (optional)
  String qId; // Unique Quiz ID (Firebase)
  final String quizName;
  final String quizDescription;
  final String createdAt;
  final int minutes;
  final int status; // 0 or 1
  final int type; //1 2 3
  final String subject; // 0 or 1

  Quiz({
    this.id,
    required this.qId,
    required this.quizName,
    required this.quizDescription,
    required this.createdAt,
    required this.minutes,
    required this.status,
    required this.type,
    required this.subject,
  });

  // For saving into SQLite Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'q_id': qId,
      'quiz_name': quizName,
      'quiz_description': quizDescription,
      'created_at': createdAt,
      'minutes': minutes,
      'status': status,
      'type': type,
      'subject': subject,
    };
  }

  // For reading from SQLite
  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'],
      qId: map['q_id'],
      quizName: map['quiz_name'],
      quizDescription: map['quiz_description'],
      createdAt: map['created_at'],
      minutes: map['minutes'],
      status: map['status'],
      type: map['type'],
      subject: map['subject'],
    );
  }

  // For sending to Firebase
  Map<String, dynamic> toJson() {
    return {
      'q_id': qId,
      'quiz_name': quizName,
      'quiz_description': quizDescription,
      'created_at': createdAt,
      'minutes': minutes,
      'status': status,
      'type': type,
      'subject': subject,
    };
  }

  // For receiving from Firebase
  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: null, // Firebase won't store local id
      qId: json['q_id'] ?? '',
      quizName: json['quiz_name'] ?? '',
      quizDescription: json['quiz_description'] ?? '',
      createdAt: json['created_at'] ?? '',
      minutes: json['minutes'] ?? 0,
      status: json['status'] ?? 0,
      type: json['type'] ?? 1,
      subject: json['subject'] ?? "all",
    );
  }
}
