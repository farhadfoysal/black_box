import '../../mess/data/model/model_extensions.dart';

class Payment {
  int? _id;
  String _uniqueId;
  String _adminId;
  String _messId;
  String _phone;
  String _dateM;
  String _trxId;
  String _amount;
  String _clearTrx;
  int _print;
  String _time;
  String? _syncStatus;

  Payment({
    int? id,
    required String uniqueId,
    required String adminId,
    required String messId,
    String phone = '',
    required String dateM,
    String trxId = '',
    String amount = '0',
    String clearTrx = '1',
    int printing = 0,
    String? time,
    String? syncStatus,
  })  : _id = id,
        _uniqueId = uniqueId,
        _adminId = adminId,
        _messId = messId,
        _phone = phone,
        _dateM = dateM,
        _trxId = trxId,
        _amount = amount,
        _clearTrx = clearTrx,
        _print = printing,
        _time = time ?? '',
        _syncStatus = syncStatus;

  // Getters
  int? get id => _id;
  String get uniqueId => _uniqueId;
  String get adminId => _adminId;
  String get messId => _messId;
  String get phone => _phone;
  String get dateM => _dateM;
  String get trxId => _trxId;
  String get amount => _amount;
  String get clearTrx => _clearTrx;
  int get printing => _print;
  String get time => _time;

  String? get syncStatus => _syncStatus;
  set syncStatus(String? value) => _syncStatus = value;

  // Setters
  set id(int? id) => _id = id;
  set uniqueId(String uniqueId) => _uniqueId = uniqueId;
  set adminId(String adminId) => _adminId = adminId;
  set messId(String messId) => _messId = messId;
  set phone(String phone) => _phone = phone;
  set dateM(String dateM) => _dateM = dateM;
  set trxId(String trxId) => _trxId = trxId;
  set amount(String amount) => _amount = amount;
  set clearTrx(String clearTrx) => _clearTrx = clearTrx;
  set printing(int print) => _print = print;
  set time(String time) => _time = time;

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'admin_id': _adminId,
      'mess_id': _messId,
      'phone': _phone,
      'date_m': _dateM,
      'trx_id': _trxId,
      'amount': _amount,
      'clear_trx': _clearTrx,
      'print': _print,
      'time': _time,
      'sync_status': _syncStatus,
    };
  }

  static Payment fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      uniqueId: map['unique_id'] ?? '',
      adminId: map['admin_id'] ?? '',
      messId: map['mess_id'] ?? '',
      phone: map['phone'] ?? '',
      dateM: (map['date_m']),
      trxId: map['trx_id'] ?? '',
      amount: map['amount'] ?? '0',
      clearTrx: map['clear_trx'] ?? '1',
      printing: map['print'] ?? 0,
      time: (map['time']),
      syncStatus: map['sync_status'] ?? PaymentSync.synced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'admin_id': _adminId,
      'mess_id': _messId,
      'phone': _phone,
      'date_m': _dateM,
      'trx_id': _trxId,
      'amount': _amount,
      'clear_trx': _clearTrx,
      'print': _print,
      'time': _time,
      'sync_status': _syncStatus,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      uniqueId: json['unique_id'] ?? '',
      adminId: json['admin_id'] ?? '',
      messId: json['mess_id'] ?? '',
      phone: json['phone'] ?? '',
      dateM: (json['date_m']),
      trxId: json['trx_id'] ?? '',
      amount: json['amount'] ?? '0',
      clearTrx: json['clear_trx'] ?? '1',
      printing: json['print'] ?? 0,
      time: (json['time']),
      syncStatus: json['sync_status'] ?? PaymentSync.synced,
    );
  }
}
