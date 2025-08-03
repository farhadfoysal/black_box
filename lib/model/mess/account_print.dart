import '../../mess/data/model/model_extensions.dart';

class AccountPrint {
  int? _id;
  String _uniqueId;
  String _userName;
  String _phone;
  String _messMonthEx;
  String _myExpense;
  String _mealExpense;
  String _myMonthMeal;
  String _payOrReceive;
  String _trxClearId;
  String? _syncStatus;

  AccountPrint({
    int? id,
    required String uniqueId,
    required String userName,
    required String phone,
    required String messMonthEx,
    required String myExpense,
    required String mealExpense,
    required String myMonthMeal,
    required String payOrReceive,
    required String trxClearId,
    String? syncStatus,
  })  : _id = id,
        _uniqueId = uniqueId,
        _userName = userName,
        _phone = phone,
        _messMonthEx = messMonthEx,
        _myExpense = myExpense,
        _mealExpense = mealExpense,
        _myMonthMeal = myMonthMeal,
        _payOrReceive = payOrReceive,
        _trxClearId = trxClearId,
        _syncStatus = syncStatus;

  // Getters
  int? get id => _id;
  String get uniqueId => _uniqueId;
  String get userName => _userName;
  String get phone => _phone;
  String get messMonthEx => _messMonthEx;
  String get myExpense => _myExpense;
  String get mealExpense => _mealExpense;
  String get myMonthMeal => _myMonthMeal;
  String get payOrReceive => _payOrReceive;
  String get trxClearId => _trxClearId;

  String? get syncStatus => _syncStatus;
  set syncStatus(String? value) => _syncStatus = value;

  // Setters
  set id(int? id) => _id = id;
  set uniqueId(String uniqueId) => _uniqueId = uniqueId;
  set userName(String userName) => _userName = userName;
  set phone(String phone) => _phone = phone;
  set messMonthEx(String messMonthEx) => _messMonthEx = messMonthEx;
  set myExpense(String myExpense) => _myExpense = myExpense;
  set mealExpense(String mealExpense) => _mealExpense = mealExpense;
  set myMonthMeal(String myMonthMeal) => _myMonthMeal = myMonthMeal;
  set payOrReceive(String payOrReceive) => _payOrReceive = payOrReceive;
  set trxClearId(String trxClearId) => _trxClearId = trxClearId;

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'user_name': _userName,
      'phone': _phone,
      'mess_month_ex': _messMonthEx,
      'my_expense': _myExpense,
      'meal_expense': _mealExpense,
      'my_month_meal': _myMonthMeal,
      'pay_or_recieve': _payOrReceive,
      'trx_clear_id': _trxClearId,
      'sync_status': _syncStatus,
    };
  }

  static AccountPrint fromMap(Map<String, dynamic> map) {
    return AccountPrint(
      id: map['id'],
      uniqueId: map['unique_id'] ?? '',
      userName: map['user_name'] ?? '',
      phone: map['phone'] ?? '',
      messMonthEx: map['mess_month_ex'] ?? '',
      myExpense: map['my_expense'] ?? '',
      mealExpense: map['meal_expense'] ?? '',
      myMonthMeal: map['my_month_meal'] ?? '',
      payOrReceive: map['pay_or_recieve'] ?? '',
      trxClearId: map['trx_clear_id'] ?? '0',
      syncStatus: map['sync_status'] ?? AccountPrintSync.synced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'user_name': _userName,
      'phone': _phone,
      'mess_month_ex': _messMonthEx,
      'my_expense': _myExpense,
      'meal_expense': _mealExpense,
      'my_month_meal': _myMonthMeal,
      'pay_or_recieve': _payOrReceive,
      'trx_clear_id': _trxClearId,
      'sync_status': _syncStatus,
    };
  }

  factory AccountPrint.fromJson(Map<String, dynamic> json) {
    return AccountPrint(
      id: json['id'],
      uniqueId: json['unique_id'] ?? '',
      userName: json['user_name'] ?? '',
      phone: json['phone'] ?? '',
      messMonthEx: json['mess_month_ex'] ?? '',
      myExpense: json['my_expense'] ?? '',
      mealExpense: json['meal_expense'] ?? '',
      myMonthMeal: json['my_month_meal'] ?? '',
      payOrReceive: json['pay_or_recieve'] ?? '',
      trxClearId: json['trx_clear_id'] ?? '0',
      syncStatus: json['sync_status'] ?? AccountPrintSync.synced,
    );
  }
}
