class TutorDate {
  int? _id;
  String? _uniqueId;
  String? _monthId;
  String? _userId;
  String? _day;
  String? _date;
  DateTime? _dayDate;
  int? _attendance;
  int? _minutes;

  // Constructor
  TutorDate({
    int? id,
    String? uniqueId,
    String? monthId,
    String? userId,
    String? day,
    String? date,
    DateTime? dayDate,
    int? attendance,
    int? minutes,
  })  : _id = id,
        _uniqueId = uniqueId,
        _monthId = monthId,
        _userId = userId,
        _day = day,
        _date = date,
        _dayDate = dayDate,
        _attendance = attendance ?? 0,
        _minutes = minutes ?? 0;

  // Getters
  int? get id => _id;
  String? get uniqueId => _uniqueId;
  String? get monthId => _monthId;
  String? get userId => _userId;
  String? get day => _day;
  String? get date => _date;
  DateTime? get dayDate => _dayDate;
  int? get attendance => _attendance;
  int? get minutes => _minutes;

  // Setters
  set id(int? id) => _id = id;
  set uniqueId(String? uniqueId) => _uniqueId = uniqueId;
  set monthId(String? monthId) => _monthId = monthId;
  set userId(String? userId) => _userId = userId;
  set day(String? day) => _day = day;
  set date(String? date) => _date = date;
  set dayDate(DateTime? dayDate) => _dayDate = dayDate;
  set attendance(int? attendance) => _attendance = attendance;
  set minutes(int? minutes) => _minutes = minutes;

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'month_id': _monthId,
      'user_id': _userId,
      'day': _day,
      'date': _date,
      'day_date': _dayDate?.toIso8601String(),
      'attendance': _attendance,
      'minutes': _minutes,
    };
  }

  // Convert from Map
  static TutorDate fromMap(Map<String, dynamic> map) {
    return TutorDate(
      id: map['id'],
      uniqueId: map['unique_id'],
      monthId: map['month_id'],
      userId: map['user_id'],
      day: map['day'],
      date: map['date'],
      dayDate: map['day_date'] != null ? DateTime.parse(map['day_date']) : null,
      attendance: map['attendance'],
      minutes: map['minutes'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'month_id': _monthId,
      'user_id': _userId,
      'day': _day,
      'date': _date,
      'day_date': _dayDate?.toIso8601String(),
      'attendance': _attendance,
      'minutes': _minutes,
    };
  }

  // Convert from JSON
  factory TutorDate.fromJson(Map<String, dynamic> json) {
    return TutorDate(
      id: json['id'],
      uniqueId: json['unique_id'],
      monthId: json['month_id'],
      userId: json['user_id'],
      day: json['day'],
      date: json['date'],
      dayDate: json['day_date'] != null ? DateTime.parse(json['day_date']) : null,
      attendance: json['attendance'],
      minutes: json['minutes'],
    );
  }
}
