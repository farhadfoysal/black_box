class Payment {
  int? _id;
  String _uniqueId;
  String _adminId;
  String _messId;
  String _phone;
  DateTime _dateM;
  String _trxId;
  String _amount;
  String _clearTrx;
  int _print;
  DateTime _time;

  Payment({
    int? id,
    required String uniqueId,
    required String adminId,
    required String messId,
    String phone = '',
    required DateTime dateM,
    String trxId = '',
    String amount = '0',
    String clearTrx = '1',
    int print = 0,
    DateTime? time,
  })  : _id = id,
        _uniqueId = uniqueId,
        _adminId = adminId,
        _messId = messId,
        _phone = phone,
        _dateM = dateM,
        _trxId = trxId,
        _amount = amount,
        _clearTrx = clearTrx,
        _print = print,
        _time = time ?? DateTime.now();

  // Getters
  int? get id => _id;
  String get uniqueId => _uniqueId;
  String get adminId => _adminId;
  String get messId => _messId;
  String get phone => _phone;
  DateTime get dateM => _dateM;
  String get trxId => _trxId;
  String get amount => _amount;
  String get clearTrx => _clearTrx;
  int get print => _print;
  DateTime get time => _time;

  // Setters
  set id(int? id) => _id = id;
  set uniqueId(String uniqueId) => _uniqueId = uniqueId;
  set adminId(String adminId) => _adminId = adminId;
  set messId(String messId) => _messId = messId;
  set phone(String phone) => _phone = phone;
  set dateM(DateTime dateM) => _dateM = dateM;
  set trxId(String trxId) => _trxId = trxId;
  set amount(String amount) => _amount = amount;
  set clearTrx(String clearTrx) => _clearTrx = clearTrx;
  set print(int print) => _print = print;
  set time(DateTime time) => _time = time;

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'admin_id': _adminId,
      'mess_id': _messId,
      'phone': _phone,
      'date_m': _dateM.toIso8601String(),
      'trx_id': _trxId,
      'amount': _amount,
      'clear_trx': _clearTrx,
      'print': _print,
      'time': _time.toIso8601String(),
    };
  }

  static Payment fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      uniqueId: map['unique_id'] ?? '',
      adminId: map['admin_id'] ?? '',
      messId: map['mess_id'] ?? '',
      phone: map['phone'] ?? '',
      dateM: DateTime.parse(map['date_m']),
      trxId: map['trx_id'] ?? '',
      amount: map['amount'] ?? '0',
      clearTrx: map['clear_trx'] ?? '1',
      print: map['print'] ?? 0,
      time: DateTime.parse(map['time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'admin_id': _adminId,
      'mess_id': _messId,
      'phone': _phone,
      'date_m': _dateM.toIso8601String(),
      'trx_id': _trxId,
      'amount': _amount,
      'clear_trx': _clearTrx,
      'print': _print,
      'time': _time.toIso8601String(),
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      uniqueId: json['unique_id'] ?? '',
      adminId: json['admin_id'] ?? '',
      messId: json['mess_id'] ?? '',
      phone: json['phone'] ?? '',
      dateM: DateTime.parse(json['date_m']),
      trxId: json['trx_id'] ?? '',
      amount: json['amount'] ?? '0',
      clearTrx: json['clear_trx'] ?? '1',
      print: json['print'] ?? 0,
      time: DateTime.parse(json['time']),
    );
  }
}
