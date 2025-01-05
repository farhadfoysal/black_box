import 'package:black_box/model/tutor/tutor_date.dart';

class TutorMonth {
  int? _id;
  String? _uniqueId;
  String? _studentId;
  String? _userId;
  String? _month;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _paidDate;
  int? _paid;
  String? _payTk;
  String? _paidTk;
  String? _paidBy;
  List<TutorDate>? _dates;

  // Constructor
  TutorMonth({
    int? id,
    String? uniqueId,
    String? studentId,
    String? userId,
    String? month,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? paidDate,
    int? paid,
    String? payTk,
    String? paidTk,
    String? paidBy,
    List<TutorDate>? dates,
  })  : _id = id,
        _uniqueId = uniqueId,
        _studentId = studentId,
        _userId = userId,
        _month = month,
        _startDate = startDate,
        _endDate = endDate,
        _paidDate = paidDate,
        _paid = paid,
        _payTk = payTk,
        _paidTk = paidTk,
        _paidBy = paidBy,
        _dates = dates ?? [];

  // Getters
  int? get id => _id;
  String? get uniqueId => _uniqueId;
  String? get studentId => _studentId;
  String? get userId => _userId;
  String? get month => _month;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  DateTime? get paidDate => _paidDate;
  int? get paid => _paid;
  String? get payTk => _payTk;
  String? get paidTk => _paidTk;
  String? get paidBy => _paidBy;
  List<TutorDate>? get dates => _dates;

  // Setters
  set id(int? id) => _id = id;
  set uniqueId(String? uniqueId) => _uniqueId = uniqueId;
  set studentId(String? studentId) => _studentId = studentId;
  set userId(String? userId) => _userId = userId;
  set month(String? month) => _month = month;
  set startDate(DateTime? startDate) => _startDate = startDate;
  set endDate(DateTime? endDate) => _endDate = endDate;
  set paidDate(DateTime? paidDate) => _paidDate = paidDate;
  set paid(int? paid) => _paid = paid;
  set payTk(String? payTk) => _payTk = payTk;
  set paidTk(String? paidTk) => _paidTk = paidTk;
  set paidBy(String? paidBy) => _paidBy = paidBy;
  set dates(List<TutorDate>? dates) => _dates = dates ?? [];

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'student_id': _studentId,
      'user_id': _userId,
      'month': _month,
      'start_date': _startDate?.toIso8601String(),
      'end_date': _endDate?.toIso8601String(),
      'paid_date': _paidDate?.toIso8601String(),
      'paid': _paid,
      'pay_tk': _payTk,
      'paid_tk': _paidTk,
      'paid_by': _paidBy,
      'dates': _dates?.map((date) => date.toMap()).toList(),
    };
  }

  // Convert from Map
  static TutorMonth fromMap(Map<String, dynamic> map) {
    return TutorMonth(
      id: map['id'],
      uniqueId: map['unique_id'],
      studentId: map['student_id'],
      userId: map['user_id'],
      month: map['month'],
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : null,
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      paidDate: map['paid_date'] != null ? DateTime.parse(map['paid_date']) : null,
      paid: map['paid'],
      payTk: map['pay_tk'],
      paidTk: map['paid_tk'],
      paidBy: map['paid_by'],
      dates: (map['dates'] as List<dynamic>?)
          ?.map((dateMap) => TutorDate.fromMap(dateMap))
          .toList(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'student_id': _studentId,
      'user_id': _userId,
      'month': _month,
      'start_date': _startDate?.toIso8601String(),
      'end_date': _endDate?.toIso8601String(),
      'paid_date': _paidDate?.toIso8601String(),
      'paid': _paid,
      'pay_tk': _payTk,
      'paid_tk': _paidTk,
      'paid_by': _paidBy,
      'dates': _dates?.map((date) => date.toJson()).toList(),
    };
  }

  // Convert from JSON
  factory TutorMonth.fromJson(Map<String, dynamic> json) {
    return TutorMonth(
      id: json['id'],
      uniqueId: json['unique_id'],
      studentId: json['student_id'],
      userId: json['user_id'],
      month: json['month'],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      paidDate: json['paid_date'] != null ? DateTime.parse(json['paid_date']) : null,
      paid: json['paid'],
      payTk: json['pay_tk'],
      paidTk: json['paid_tk'],
      paidBy: json['paid_by'],
      dates: (json['dates'] as List<dynamic>?)
          ?.map((dateJson) => TutorDate.fromJson(dateJson))
          .toList(),
    );
  }
}
