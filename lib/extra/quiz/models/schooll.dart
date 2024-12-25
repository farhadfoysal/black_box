class Schooll {
  final String name;
  final String schoolId;

  Schooll({
    required this.name,
    required this.schoolId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'schoolId': schoolId,
    };
  }

  factory Schooll.fromMap(Map<String, dynamic> map) {
    return Schooll(
      name: map['name'],
      schoolId: map['schoolId'],
    );
  }
}
