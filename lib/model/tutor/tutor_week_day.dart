class TutorWeekDay {
  int? _id;
  String _uniqueId;
  String _studentId;
  String _userId;
  String _day;
  String _time;
  int _minutes;

  // Constructor
  TutorWeekDay({
    int? id,
    required String uniqueId,
    required String studentId,
    required String userId,
    required String day,
    required String time,
    required int minutes,
  })  : _id = id,
        _uniqueId = uniqueId,
        _studentId = studentId,
        _userId = userId,
        _day = day,
        _time = time,
        _minutes = minutes;

  // Getters
  int? get id => _id;
  String get uniqueId => _uniqueId;
  String get studentId => _studentId;
  String get userId => _userId;
  String get day => _day;
  String get time => _time;
  int get minutes => _minutes;

  // Setters
  set id(int? id) => _id = id;
  set uniqueId(String uniqueId) => _uniqueId = uniqueId;
  set studentId(String studentId) => _studentId = studentId;
  set userId(String userId) => _userId = userId;
  set day(String day) => _day = day;
  set time(String time) => _time = time;
  set minutes(int minutes) => _minutes = minutes;

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'student_id': _studentId,
      'user_id': _userId,
      'day': _day,
      'time': _time,
      'minutes': _minutes,
    };
  }

  // Convert from Map
  static TutorWeekDay fromMap(Map<String, dynamic> map) {
    return TutorWeekDay(
      id: map['id'],
      uniqueId: map['unique_id'] ?? '',
      studentId: map['student_id'] ?? '',
      userId: map['user_id'] ?? '',
      day: map['day'] ?? '',
      time: map['time'] ?? '',
      minutes: map['minutes'] ?? 0,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'student_id': _studentId,
      'user_id': _userId,
      'day': _day,
      'time': _time,
      'minutes': _minutes,
    };
  }

  // Convert from JSON
  factory TutorWeekDay.fromJson(Map<String, dynamic> json) {
    return TutorWeekDay(
      id: json['id'],
      uniqueId: json['unique_id'] ?? '',
      studentId: json['student_id'] ?? '',
      userId: json['user_id'] ?? '',
      day: json['day'] ?? '',
      time: json['time'] ?? '',
      minutes: json['minutes'] ?? 0,
    );
  }
}
