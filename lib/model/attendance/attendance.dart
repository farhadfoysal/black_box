class Attendance {
  int? _id;
  String _uniqueId;
  String _userId;
  String _sheetId;
  String _sId;
  String _time;
  int _exitIn; // '1', '0', '3', or '2'
  DateTime _attendDate;
  String _date;
  String _status; // 'p present', 'a absent', 'e exit', or 'i in'

  // Constructor
  Attendance({
    int? id,
    required String uniqueId,
    required String userId,
    required String sheetId,
    required String sId,
    required String time,
    required int exitIn,
    required DateTime attendDate,
    required String date,
    required String status,
  })  : _id = id,
        _uniqueId = uniqueId,
        _userId = userId,
        _sheetId = sheetId,
        _sId = sId,
        _time = time,
        _exitIn = exitIn,
        _attendDate = attendDate,
        _date = date,
        _status = status;

  // Getters
  int? get id => _id;
  String get uniqueId => _uniqueId;
  String get userId => _userId;
  String get sheetId => _sheetId;
  String get sId => _sId;
  String get time => _time;
  int get exitIn => _exitIn;
  DateTime get attendDate => _attendDate;
  String get date => _date;
  String get status => _status;

  // Setters
  set id(int? id) => _id = id;
  set uniqueId(String uniqueId) => _uniqueId = uniqueId;
  set userId(String userId) => _userId = userId;
  set sheetId(String sheetId) => _sheetId = sheetId;
  set messId(String sId) => _sId = _sId;
  set time(String time) => _time = time;
  set exitIn(int exitIn) => _exitIn = exitIn;
  set attendDate(DateTime attendDate) => _attendDate = attendDate;
  set date(String date) => _date = date;
  set status(String status) => _status = status;

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'user_id': _userId,
      'sheet_id': _sheetId,
      'sId': _sId,
      'time': _time,
      'exit_in': _exitIn,
      'attend_date': _attendDate.toIso8601String(),
      'date': _date,
      'status': _status,
    };
  }

  // Convert from Map
  static Attendance fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      uniqueId: map['unique_id'] ?? '',
      userId: map['user_id'] ?? '',
      sheetId: map['sheet_id'] ?? '',
      sId: map['_sId'] ?? '',
      time: map['time'] ?? '',
      exitIn: map['exit_in'] ?? 0,
      attendDate: DateTime.parse(map['attend_date'] ?? ''),
      date: map['date'] ?? '',
      status: map['status'] ?? '',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'user_id': _userId,
      'sheet_id': _sheetId,
      'sId': _sId,
      'time': _time,
      'exit_in': _exitIn,
      'attend_date': _attendDate.toIso8601String(),
      'date': _date,
      'status': _status,
    };
  }

  // Convert from JSON
  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      uniqueId: json['unique_id'] ?? '',
      userId: json['user_id'] ?? '',
      sheetId: json['sheet_id'] ?? '',
      sId: json['_sId'] ?? '',
      time: json['time'] ?? '',
      exitIn: json['exit_in'] ?? 0,
      attendDate: DateTime.parse(json['attend_date'] ?? ''),
      date: json['date'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
