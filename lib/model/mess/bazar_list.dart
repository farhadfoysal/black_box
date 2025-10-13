import '../../mess/data/model/model_extensions.dart';

class BazarList {
  int? _id;
  String _listId;
  String _uniqueId;
  String _messId;
  String _phone;
  String _listDetails;
  String _amount;
  String _dateTime;
  String _adminNotify;
  String? _syncStatus;

  BazarList({
    int? id,
    required String listId,
    required String uniqueId,
    required String messId,
    required String phone,
    required String listDetails,
    required String amount,
    required String dateTime,
    required String adminNotify,
    String? syncStatus,
  })  : _id = id,
        _listId = listId,
        _uniqueId = uniqueId,
        _messId = messId,
        _phone = phone,
        _listDetails = listDetails,
        _amount = amount,
        _dateTime = dateTime,
        _adminNotify = adminNotify,
        _syncStatus = syncStatus;

  // Getters
  int? get id => _id;
  String get listId => _listId;
  String get uniqueId => _uniqueId;
  String get messId => _messId;
  String get phone => _phone;
  String get listDetails => _listDetails;
  String get amount => _amount;
  String get dateTime => _dateTime;
  String get adminNotify => _adminNotify;

  String? get syncStatus => _syncStatus;
  set syncStatus(String? value) => _syncStatus = value;

  // Setters
  set id(int? id) => _id = id;
  set listId(String listId) => _listId = listId;
  set uniqueId(String uniqueId) => _uniqueId = uniqueId;
  set messId(String messId) => _messId = messId;
  set phone(String phone) => _phone = phone;
  set listDetails(String listDetails) => _listDetails = listDetails;
  set amount(String amount) => _amount = amount;
  set dateTime(String dateTime) => _dateTime = dateTime;
  set adminNotify(String adminNotify) => _adminNotify = adminNotify;

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'list_id': _listId,
      'unique_id': _uniqueId,
      'mess_id': _messId,
      'phone': _phone,
      'list_details': _listDetails,
      'amount': _amount,
      'date_time': _dateTime,
      'admin_notify': _adminNotify,
      'sync_status': _syncStatus,
    };
  }

  static BazarList fromMap(Map<String, dynamic> map) {
    return BazarList(
      id: map['id'],
      listId: map['list_id'] ?? '',
      uniqueId: map['unique_id'] ?? '',
      messId: map['mess_id'] ?? '',
      phone: map['phone'] ?? '0',
      listDetails: map['list_details'] ?? '',
      amount: map['amount'] ?? '0',
      dateTime: (map['date_time']),
      adminNotify: map['admin_notify'] ?? '0',
      syncStatus: map['sync_status'] ?? BazarListSync.synced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'list_id': _listId,
      'unique_id': _uniqueId,
      'mess_id': _messId,
      'phone': _phone,
      'list_details': _listDetails,
      'amount': _amount,
      'date_time': _dateTime,
      'admin_notify': _adminNotify,
      'sync_status': _syncStatus,
    };
  }

  factory BazarList.fromJson(Map<String, dynamic> json) {
    return BazarList(
      id: json['id'],
      listId: json['list_id'] ?? '',
      uniqueId: json['unique_id'] ?? '',
      messId: json['mess_id'] ?? '',
      phone: json['phone'] ?? '0',
      listDetails: json['list_details'] ?? '',
      amount: json['amount'] ?? '0',
      dateTime: (json['date_time']),
      adminNotify: json['admin_notify'] ?? '0',
      syncStatus: json['sync_status'] ?? BazarListSync.synced,
    );
  }
}
