class Course {
  final String id;
  final String name;
  final String code;
  final String? description;
  final List<String> subjects;

  Course({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.subjects,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'description': description,
    'subjects': subjects,
  };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'],
    name: json['name'],
    code: json['code'],
    description: json['description'],
    subjects: List<String>.from(json['subjects']),
  );
}