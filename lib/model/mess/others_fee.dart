import '../../mess/data/model/model_extensions.dart';

class OthersFee {
  int? _id;
  String _uniqueId;
  String _messId;
  String _feeType;
  String _amount;
  String _adminId;
  String _date;
  String _status;
  String? _syncStatus;

  OthersFee({
    int? id,
    required String uniqueId,
    required String messId,
    String feeType = '',
    String amount = '0',
    String adminId = '',
    required String date,
    String status = '1',
    String? syncStatus,
  })  : _id = id,
        _uniqueId = uniqueId,
        _messId = messId,
        _feeType = feeType,
        _amount = amount,
        _adminId = adminId,
        _date = date,
        _status = status,
        _syncStatus = syncStatus;

  // Getters
  int? get id => _id;
  String get uniqueId => _uniqueId;
  String get messId => _messId;
  String get feeType => _feeType;
  String get amount => _amount;
  String get adminId => _adminId;
  String get date => _date;
  String get status => _status;

  String? get syncStatus => _syncStatus;
  set syncStatus(String? value) => _syncStatus = value;

  // Setters
  set id(int? id) => _id = id;
  set uniqueId(String uniqueId) => _uniqueId = uniqueId;
  set messId(String messId) => _messId = messId;
  set feeType(String feeType) => _feeType = feeType;
  set amount(String amount) => _amount = amount;
  set adminId(String adminId) => _adminId = adminId;
  set date(String date) => _date = date;
  set status(String status) => _status = status;

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'mess_id': _messId,
      'fee_type': _feeType,
      'amount': _amount,
      'admin_id': _adminId,
      'date': _date,
      'status': _status,
      'sync_status': _syncStatus,
    };
  }

  static OthersFee fromMap(Map<String, dynamic> map) {
    return OthersFee(
      id: map['id'],
      uniqueId: map['unique_id'] ?? '',
      messId: map['mess_id'] ?? '',
      feeType: map['fee_type'] ?? '',
      amount: map['amount'] ?? '0',
      adminId: map['admin_id'] ?? '',
      date: (map['date']),
      status: map['status'] ?? '1',
      syncStatus: map['sync_status'] ?? OthersFeeSync.synced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'mess_id': _messId,
      'fee_type': _feeType,
      'amount': _amount,
      'admin_id': _adminId,
      'date': _date,
      'status': _status,
      'sync_status': _syncStatus,
    };
  }

  factory OthersFee.fromJson(Map<String, dynamic> json) {
    return OthersFee(
      id: json['id'],
      uniqueId: json['unique_id'] ?? '',
      messId: json['mess_id'] ?? '',
      feeType: json['fee_type'] ?? '',
      amount: json['amount'] ?? '0',
      adminId: json['admin_id'] ?? '',
      date: (json['date']),
      status: json['status'] ?? '1',
      syncStatus: json['sync_status'] ?? OthersFeeSync.synced,
    );
  }
}
