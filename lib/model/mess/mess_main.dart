class MessMain {
  int? _id;
  String? _mId;
  String? _messId;
  String? _messName;
  String? _messAddress;
  String? _messPass;
  String? _messAdminId;
  String? _mealUpdateStatus; // 1, 2, 3, 4 - d: 1
  String? _adminPhone;
  DateTime? _startDate;
  String? _sumOfAllTrx; //
  String? _uPerm; // 0,1 - d: 0
  String? _qr;

  MessMain({
    int? id,
    String? mId,
    String? messId,
    String? messName,
    String? messAddress,
    String? messPass,
    String? messAdminId,
    String? mealUpdateStatus,
    String? adminPhone,
    DateTime? startDate,
    String? sumOfAllTrx,
    String? uPerm,
    String? qr,
  })  : _id = id,
        _mId = mId,
        _messId = messId,
        _messName = messName,
        _messAddress = messAddress,
        _messPass = messPass,
        _messAdminId = messAdminId,
        _mealUpdateStatus = mealUpdateStatus,
        _adminPhone = adminPhone,
        _startDate = startDate,
        _sumOfAllTrx = sumOfAllTrx,
        _uPerm = uPerm,
        _qr = qr;

  // Getters
  int? get id => _id;
  String? get mId => _mId;
  String? get messId => _messId;
  String? get messName => _messName;
  String? get messAddress => _messAddress;
  String? get messPass => _messPass;
  String? get messAdminId => _messAdminId;
  String? get mealUpdateStatus => _mealUpdateStatus;
  String? get adminPhone => _adminPhone;
  DateTime? get startDate => _startDate;
  String? get sumOfAllTrx => _sumOfAllTrx;
  String? get uPerm => _uPerm;
  String? get qr => _qr;

  // Setters
  set id(int? id) => _id = id;
  set mId(String? mId) => _mId = mId;
  set messId(String? messId) => _messId = messId;
  set messName(String? messName) => _messName = messName;
  set messAddress(String? messAddress) => _messAddress = messAddress;
  set messPass(String? messPass) => _messPass = messPass;
  set messAdminId(String? messAdminId) => _messAdminId = messAdminId;
  set mealUpdateStatus(String? mealUpdateStatus) => _mealUpdateStatus = mealUpdateStatus;
  set adminPhone(String? adminPhone) => _adminPhone = adminPhone;
  set startDate(DateTime? startDate) => _startDate = startDate;
  set sumOfAllTrx(String? sumOfAllTrx) => _sumOfAllTrx = sumOfAllTrx;
  set uPerm(String? uPerm) => _uPerm = uPerm;
  set qr(String? qr) => _qr = qr;

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'm_id': _mId,
      'mess_id': _messId,
      'mess_name': _messName,
      'mess_address': _messAddress,
      'mess_pass': _messPass,
      'mess_admin_id': _messAdminId,
      'meal_update_status': _mealUpdateStatus,
      'admin_phone': _adminPhone,
      'start_date': _startDate?.toIso8601String(),
      'sum_of_all_trx': _sumOfAllTrx,
      'u_perm': _uPerm,
      'qr': _qr,
    };
  }

  static MessMain fromMap(Map<String, dynamic> map) {
    return MessMain(
      id: map['id'],
      mId: map['m_id'] ?? '',
      messId: map['mess_id'] ?? '',
      messName: map['mess_name'] ?? '',
      messAddress: map['mess_address'] ?? '',
      messPass: map['mess_pass'] ?? '',
      messAdminId: map['mess_admin_id'] ?? '',
      mealUpdateStatus: map['meal_update_status'] ?? '1',
      adminPhone: map['admin_phone'] ?? '',
      startDate: map['start_date'] != null ? DateTime.tryParse(map['start_date']) : null,
      sumOfAllTrx: map['sum_of_all_trx'] ?? '0',
      uPerm: map['u_perm'] ?? '0',
      qr: map['qr'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'm_id': _mId,
      'mess_id': _messId,
      'mess_name': _messName,
      'mess_address': _messAddress,
      'mess_pass': _messPass,
      'mess_admin_id': _messAdminId,
      'meal_update_status': _mealUpdateStatus,
      'admin_phone': _adminPhone,
      'start_date': _startDate?.toIso8601String(),
      'sum_of_all_trx': _sumOfAllTrx,
      'u_perm': _uPerm,
      'qr': _qr,
    };
  }

  factory MessMain.fromJson(Map<String, dynamic> json) {
    return MessMain(
      id: json['id'],
      mId: json['m_id'] ?? '',
      messId: json['mess_id'] ?? '',
      messName: json['mess_name'] ?? '',
      messAddress: json['mess_address'] ?? '',
      messPass: json['mess_pass'] ?? '',
      messAdminId: json['mess_admin_id'] ?? '',
      mealUpdateStatus: json['meal_update_status'] ?? '1',
      adminPhone: json['admin_phone'] ?? '',
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      sumOfAllTrx: json['sum_of_all_trx'] ?? '0',
      uPerm: json['u_perm'] ?? '0',
      qr: json['qr'] ?? '',
    );
  }
}
