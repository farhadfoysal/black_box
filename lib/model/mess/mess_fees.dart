class MessFees {
  int? _id;
  String _messId;
  String _feeType;
  String _amount;
  String _adminId;
  DateTime _date;
  String _status;

  MessFees({
    int? id,
    required String messId,
    required String feeType,
    required String amount,
    required String adminId,
    required DateTime date,
    required String status,
  })  : _id = id,
        _messId = messId,
        _feeType = feeType,
        _amount = amount,
        _adminId = adminId,
        _date = date,
        _status = status;

  // Getters
  int? get id => _id;
  String get messId => _messId;
  String get feeType => _feeType;
  String get amount => _amount;
  String get adminId => _adminId;
  DateTime get date => _date;
  String get status => _status;

  // Setters
  set id(int? id) => _id = id;
  set messId(String messId) => _messId = messId;
  set feeType(String feeType) => _feeType = feeType;
  set amount(String amount) => _amount = amount;
  set adminId(String adminId) => _adminId = adminId;
  set date(DateTime date) => _date = date;
  set status(String status) => _status = status;

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'mess_id': _messId,
      'fee_type': _feeType,
      'amount': _amount,
      'admin_id': _adminId,
      'date': _date.toIso8601String(),
      'status': _status,
    };
  }

  static MessFees fromMap(Map<String, dynamic> map) {
    return MessFees(
      id: map['id'],
      messId: map['mess_id'] ?? '',
      feeType: map['fee_type'] ?? '',
      amount: map['amount'] ?? '0',
      adminId: map['admin_id'] ?? '',
      date: DateTime.parse(map['date']),
      status: map['status'] ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'mess_id': _messId,
      'fee_type': _feeType,
      'amount': _amount,
      'admin_id': _adminId,
      'date': _date.toIso8601String(),
      'status': _status,
    };
  }

  factory MessFees.fromJson(Map<String, dynamic> json) {
    return MessFees(
      id: json['id'],
      messId: json['mess_id'] ?? '',
      feeType: json['fee_type'] ?? '',
      amount: json['amount'] ?? '0',
      adminId: json['admin_id'] ?? '',
      date: DateTime.parse(json['date']),
      status: json['status'] ?? '1',
    );
  }
}
