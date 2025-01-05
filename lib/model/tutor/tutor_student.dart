import 'package:black_box/model/tutor/tutor_week_day.dart';

class TutorStudent {
  int? _id;
  String? _uniqueId;
  String? _userId;
  String? _name;
  String? _phone;
  String? _gaurdianPhone;
  String? _phonePass;
  String? _dob;
  String? _education;
  String? _address;
  int? _activeStatus;
  DateTime? _admittedDate;
  String? _img;
  List<TutorWeekDay>? _days;

  // Constructor
  TutorStudent({
    int? id,
    String? uniqueId,
    String? userId,
    String? name,
    String? phone,
    String? gaurdianPhone,
    String? phonePass,
    String? dob,
    String? education,
    String? address,
    int? activeStatus,
    DateTime? admittedDate,
    String? img,
    List<TutorWeekDay>? days,
  })  : _id = id,
        _uniqueId = uniqueId,
        _userId = userId,
        _name = name,
        _phone = phone,
        _gaurdianPhone = gaurdianPhone,
        _phonePass = phonePass,
        _dob = dob,
        _education = education,
        _address = address,
        _activeStatus = activeStatus,
        _admittedDate = admittedDate,
        _img = img,
        _days = days;

  // Getters
  int? get id => _id;
  String? get uniqueId => _uniqueId;
  String? get userId => _userId;
  String? get name => _name;
  String? get phone => _phone;
  String? get gaurdianPhone => _gaurdianPhone;
  String? get phonePass => _phonePass;
  String? get dob => _dob;
  String? get education => _education;
  String? get address => _address;
  int? get activeStatus => _activeStatus;
  DateTime? get admittedDate => _admittedDate;
  String? get img => _img;
  List<TutorWeekDay>? get days => _days;

  // Setters
  set id(int? id) => _id = id;
  set uniqueId(String? uniqueId) => _uniqueId = uniqueId;
  set userId(String? userId) => _userId = userId;
  set name(String? name) => _name = name;
  set phone(String? phone) => _phone = phone;
  set gaurdianPhone(String? gaurdianPhone) => _gaurdianPhone = gaurdianPhone;
  set phonePass(String? phonePass) => _phonePass = phonePass;
  set dob(String? dob) => _dob = dob;
  set education(String? education) => _education = education;
  set address(String? address) => _address = address;
  set activeStatus(int? activeStatus) => _activeStatus = activeStatus;
  set admittedDate(DateTime? admittedDate) => _admittedDate = admittedDate;
  set img(String? img) => _img = img;
  set days(List<TutorWeekDay>? days) => _days = days;

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'user_id': _userId,
      'name': _name,
      'phone': _phone,
      'gaurdian_phone': _gaurdianPhone,
      'phone_pass': _phonePass,
      'dob': _dob,
      'education': _education,
      'address': _address,
      'active_status': _activeStatus,
      'admitted_date': _admittedDate?.toIso8601String(),
      'img': _img,
      'days': _days?.map((day) => day.toMap()).toList(),
    };
  }

  // Convert from Map
  static TutorStudent fromMap(Map<String, dynamic> map) {
    return TutorStudent(
      id: map['id'],
      uniqueId: map['unique_id'],
      userId: map['user_id'],
      name: map['name'],
      phone: map['phone'],
      gaurdianPhone: map['gaurdian_phone'],
      phonePass: map['phone_pass'],
      dob: map['dob'],
      education: map['education'],
      address: map['address'],
      activeStatus: map['active_status'],
      admittedDate: map['admitted_date'] != null ? DateTime.parse(map['admitted_date']) : null,
      img: map['img'],
      days: (map['days'] as List?)?.map((day) => TutorWeekDay.fromMap(day)).toList(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'user_id': _userId,
      'name': _name,
      'phone': _phone,
      'gaurdian_phone': _gaurdianPhone,
      'phone_pass': _phonePass,
      'dob': _dob,
      'education': _education,
      'address': _address,
      'active_status': _activeStatus,
      'admitted_date': _admittedDate?.toIso8601String(),
      'img': _img,
      'days': _days?.map((day) => day.toJson()).toList(),
    };
  }

  // Convert from JSON
  factory TutorStudent.fromJson(Map<String, dynamic> json) {
    return TutorStudent(
      id: json['id'],
      uniqueId: json['unique_id'],
      userId: json['user_id'],
      name: json['name'],
      phone: json['phone'],
      gaurdianPhone: json['gaurdian_phone'],
      phonePass: json['phone_pass'],
      dob: json['dob'],
      education: json['education'],
      address: json['address'],
      activeStatus: json['active_status'],
      admittedDate: json['admitted_date'] != null ? DateTime.parse(json['admitted_date']) : null,
      img: json['img'],
      days: (json['days'] as List?)?.map((day) => TutorWeekDay.fromJson(day)).toList(),
    );
  }
}
