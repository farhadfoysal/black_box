class MyMeals {
  int? _id;
  String _uniqueId;
  String _messId;
  DateTime _date;
  DateTime _time;
  String _morning;
  String _launce; // Note: Assuming the SQL column name is intentional (spelling: "launce").
  String _dinner;
  String _mealUpdate;
  String _sumMeal;
  String _mealReset;

  MyMeals({
    int? id,
    required String uniqueId,
    required String messId,
    required DateTime date,
    required DateTime time,
    String morning = '0',
    String launce = '0',
    String dinner = '0',
    required String mealUpdate,
    required String sumMeal,
    required String mealReset,
  })  : _id = id,
        _uniqueId = uniqueId,
        _messId = messId,
        _date = date,
        _time = time,
        _morning = morning,
        _launce = launce,
        _dinner = dinner,
        _mealUpdate = mealUpdate,
        _sumMeal = sumMeal,
        _mealReset = mealReset;

  // Getters
  int? get id => _id;
  String get uniqueId => _uniqueId;
  String get messId => _messId;
  DateTime get date => _date;
  DateTime get time => _time;
  String get morning => _morning;
  String get launce => _launce;
  String get dinner => _dinner;
  String get mealUpdate => _mealUpdate;
  String get sumMeal => _sumMeal;
  String get mealReset => _mealReset;

  // Setters
  set id(int? id) => _id = id;
  set uniqueId(String uniqueId) => _uniqueId = uniqueId;
  set messId(String messId) => _messId = messId;
  set date(DateTime date) => _date = date;
  set time(DateTime time) => _time = time;
  set morning(String morning) => _morning = morning;
  set launce(String launce) => _launce = launce;
  set dinner(String dinner) => _dinner = dinner;
  set mealUpdate(String mealUpdate) => _mealUpdate = mealUpdate;
  set sumMeal(String sumMeal) => _sumMeal = sumMeal;
  set mealReset(String mealReset) => _mealReset = mealReset;

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'mess_id': _messId,
      'date': _date.toIso8601String(),
      'time': _time.toIso8601String(),
      'morning': _morning,
      'launce': _launce,
      'dinner': _dinner,
      'meal_update': _mealUpdate,
      'sum_meal': _sumMeal,
      'meal_reset': _mealReset,
    };
  }

  static MyMeals fromMap(Map<String, dynamic> map) {
    return MyMeals(
      id: map['id'],
      uniqueId: map['unique_id'] ?? '',
      messId: map['mess_id'] ?? '',
      date: DateTime.parse(map['date']),
      time: DateTime.parse(map['time']),
      morning: map['morning'] ?? '0',
      launce: map['launce'] ?? '0',
      dinner: map['dinner'] ?? '0',
      mealUpdate: map['meal_update'] ?? '1',
      sumMeal: map['sum_meal'] ?? '',
      mealReset: map['meal_reset'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'unique_id': _uniqueId,
      'mess_id': _messId,
      'date': _date.toIso8601String(),
      'time': _time.toIso8601String(),
      'morning': _morning,
      'launce': _launce,
      'dinner': _dinner,
      'meal_update': _mealUpdate,
      'sum_meal': _sumMeal,
      'meal_reset': _mealReset,
    };
  }

  factory MyMeals.fromJson(Map<String, dynamic> json) {
    return MyMeals(
      id: json['id'],
      uniqueId: json['unique_id'] ?? '',
      messId: json['mess_id'] ?? '',
      date: DateTime.parse(json['date']),
      time: DateTime.parse(json['time']),
      morning: json['morning'] ?? '0',
      launce: json['launce'] ?? '0',
      dinner: json['dinner'] ?? '0',
      mealUpdate: json['meal_update'] ?? '1',
      sumMeal: json['sum_meal'] ?? '',
      mealReset: json['meal_reset'] ?? '0',
    );
  }
}
