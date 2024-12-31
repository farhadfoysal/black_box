class MessUser {
  int? _id;
  String _uniqueId;
  String _userId;
  String _userName;
  String _phone;
  String _email;
  String _userType;
  String _phonePass;
  String _password;
  String _dob;
  String _education;
  String _address;
  String _messId;
  String _activeStatus;
  DateTime _bazarStart;
  DateTime _bazarEnd;
  String _qr;
  String _img;

  MessUser({
    int? id,
    required String uniqueId,
    required String userId,
    String userName = '',
    required String phone,
    String email = '',
    String userType = 'u',
    required String phonePass,
    required String password,
    String dob = '',
    String education = '',
    String address = '',
    String messId = '',
    String activeStatus = '0',
    required DateTime bazarStart,
    required DateTime bazarEnd,
    String qr = '',
    String img = '',
  })  : _id = id,
        _uniqueId = uniqueId,
        _userId = userId,
        _userName = userName,
        _phone = phone,
        _email = email,
        _userType = userType,
        _phonePass = phonePass,
        _password = password,
        _dob = dob,
        _education = education,
        _address = address,
        _messId = messId,
        _activeStatus = activeStatus,
        _bazarStart = bazarStart,
        _bazarEnd = bazarEnd,
        _qr = qr,
        _img = img;

  // Getters
  int? get id => _id;
  String get uniqueId => _uniqueId;
  String get userId => _userId;
  String get userName => _userName;
  String get phone => _phone;
  String get email => _email;
  String get userType => _userType;
  String get phonePass => _phonePass;
  String get password => _password;
  String get dob => _dob;
  String get education => _education;
  String get address => _address;
  String get messId => _messId;
  String get activeStatus => _activeStatus;
  DateTime get bazarStart => _bazarStart;
  DateTime get bazarEnd => _bazarEnd;
  String get qr => _qr;
  String get img => _img;

  // Setters
  set id(int? id) => _id = id;
  set uniqueId(String uniqueId) => _uniqueId = uniqueId;
  set userId(String userId) => _userId = userId;
  set userName(String userName) => _userName = userName;
  set phone(String phone) => _phone = phone;
  set email(String email) => _email = email;
  set userType(String userType) => _userType = userType;
  set phonePass(String phonePass) => _phonePass = phonePass;
  set password(String password) => _password = password;
  set dob(String dob) => _dob = dob;
  set education(String education) => _education = education;
  set address(String address) => _address = address;
  set messId(String messId) => _messId = messId;
  set activeStatus(String activeStatus) => _activeStatus = activeStatus;
  set bazarStart(DateTime bazarStart) => _bazarStart = bazarStart;
  set bazarEnd(DateTime bazarEnd) => _bazarEnd = bazarEnd;
  set qr(String qr) => _qr = qr;
  set img(String img) => _img = img;

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'user_id': _userId,
      'user_name': _userName,
      'phone': _phone,
      'email': _email,
      'user_type': _userType,
      'phone_pass': _phonePass,
      'password': _password,
      'dob': _dob,
      'education': _education,
      'address': _address,
      'mess_id': _messId,
      'active_status': _activeStatus,
      'bazar_start': _bazarStart.toIso8601String(),
      'bazar_end': _bazarEnd.toIso8601String(),
      'qr': _qr,
      'img': _img,
    };
  }

  static MessUser fromMap(Map<String, dynamic> map) {
    return MessUser(
      id: map['id'],
      uniqueId: map['unique_id'] ?? '',
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      userType: map['user_type'] ?? 'u',
      phonePass: map['phone_pass'] ?? '',
      password: map['password'] ?? '',
      dob: map['dob'] ?? '',
      education: map['education'] ?? '',
      address: map['address'] ?? '',
      messId: map['mess_id'] ?? '',
      activeStatus: map['active_status'] ?? '0',
      bazarStart: DateTime.parse(map['bazar_start']),
      bazarEnd: DateTime.parse(map['bazar_end']),
      qr: map['qr'] ?? '',
      img: map['img'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'user_id': _userId,
      'user_name': _userName,
      'phone': _phone,
      'email': _email,
      'user_type': _userType,
      'phone_pass': _phonePass,
      'password': _password,
      'dob': _dob,
      'education': _education,
      'address': _address,
      'mess_id': _messId,
      'active_status': _activeStatus,
      'bazar_start': _bazarStart.toIso8601String(),
      'bazar_end': _bazarEnd.toIso8601String(),
      'qr': _qr,
      'img': _img,
    };
  }

  factory MessUser.fromJson(Map<String, dynamic> json) {
    return MessUser(
      id: json['id'],
      uniqueId: json['unique_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? 'u',
      phonePass: json['phone_pass'] ?? '',
      password: json['password'] ?? '',
      dob: json['dob'] ?? '',
      education: json['education'] ?? '',
      address: json['address'] ?? '',
      messId: json['mess_id'] ?? '',
      activeStatus: json['active_status'] ?? '0',
      bazarStart: DateTime.parse(json['bazar_start']),
      bazarEnd: DateTime.parse(json['bazar_end']),
      qr: json['qr'] ?? '',
      img: json['img'] ?? '',
    );
  }
}