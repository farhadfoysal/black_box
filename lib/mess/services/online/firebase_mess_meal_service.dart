import 'package:firebase_database/firebase_database.dart';
import '../../../model/mess/my_meals.dart';
import '../../data/db/database_interfaces.dart';

class FirebaseMyMealsService implements BaseDatabaseService<MyMeals> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('my_meal');

  @override
  Future<String> create(MyMeals meal) async {
    final newRef = _dbRef.push();
    await newRef.set(meal.toJson());
    return newRef.key!;
  }

  @override
  Future<void> update(String id, MyMeals meal) async {
    await _dbRef.child(id).update(meal.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _dbRef.child(id).remove();
  }

  @override
  Future<MyMeals?> get(String id) async {
    final snapshot = await _dbRef.child(id).get();
    return snapshot.exists ? MyMeals.fromJson(snapshot.value as Map<String, dynamic>) : null;
  }

  @override
  Future<List<MyMeals>> getAll() async {
    final snapshot = await _dbRef.get();
    if (snapshot.exists) {
      return (snapshot.value as Map).values
          .map((e) => MyMeals.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Stream<MyMeals?> watch(String id) {
    return _dbRef.child(id).onValue.map((event) {
      return event.snapshot.exists
          ? MyMeals.fromJson(event.snapshot.value as Map<String, dynamic>)
          : null;
    });
  }

  @override
  Stream<List<MyMeals>> watchAll() {
    return _dbRef.onValue.map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => MyMeals.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }

  @override
  Stream<List<MyMeals>> watchByMess(String messId) {
    return _dbRef
        .orderByChild('mess_id')
        .equalTo(messId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => MyMeals.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }

  @override
  Future<void> pushPendingOperations() async => Future.value();

  @override
  Future<void> pullLatestData() async => Future.value();

  @override
  Stream<List<MyMeals>> watchByUser(String uniqueId) {
    return _dbRef
        .orderByChild('unique_id')
        .equalTo(uniqueId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => MyMeals.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }
}
