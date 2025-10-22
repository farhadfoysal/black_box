class Student {
  final String id;
  final String name;
  final String studentId;
  final String mobileNumber;
  final String className;
  final String courseId;
  final String? email;
  final DateTime enrollmentDate;

  Student({
    required this.id,
    required this.name,
    required this.studentId,
    required this.mobileNumber,
    required this.className,
    required this.courseId,
    this.email,
    required this.enrollmentDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'studentId': studentId,
    'mobileNumber': mobileNumber,
    'className': className,
    'courseId': courseId,
    'email': email,
    'enrollmentDate': enrollmentDate.toIso8601String(),
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'],
    name: json['name'],
    studentId: json['studentId'],
    mobileNumber: json['mobileNumber'],
    className: json['className'],
    courseId: json['courseId'],
    email: json['email'],
    enrollmentDate: DateTime.parse(json['enrollmentDate']),
  );
}