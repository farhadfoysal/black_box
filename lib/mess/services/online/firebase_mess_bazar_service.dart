import 'package:firebase_database/firebase_database.dart';
import '../../../model/mess/bazar_list.dart';
import '../../data/db/database_interfaces.dart';

class FirebaseBazarListService implements BaseDatabaseService<BazarList> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('bazar_list');

  @override
  Future<String> create(BazarList bazar) async {
    final newRef = _dbRef.push();
    await newRef.set(bazar.toJson());
    return newRef.key!;
  }

  @override
  Future<void> update(String id, BazarList bazar) async {
    await _dbRef.child(id).update(bazar.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _dbRef.child(id).remove();
  }

  @override
  Future<BazarList?> get(String id) async {
    final snapshot = await _dbRef.child(id).get();
    return snapshot.exists ? BazarList.fromJson(snapshot.value as Map<String, dynamic>) : null;
  }

  @override
  Future<List<BazarList>> getAll() async {
    final snapshot = await _dbRef.get();
    if (snapshot.exists) {
      return (snapshot.value as Map).values
          .map((e) => BazarList.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Stream<BazarList?> watch(String id) {
    return _dbRef.child(id).onValue.map((event) {
      return event.snapshot.exists
          ? BazarList.fromJson(event.snapshot.value as Map<String, dynamic>)
          : null;
    });
  }

  @override
  Stream<List<BazarList>> watchAll() {
    return _dbRef.onValue.map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => BazarList.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }

  @override
  Stream<List<BazarList>> watchByMess(String messId) {
    return _dbRef
        .orderByChild('mess_id')
        .equalTo(messId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => BazarList.fromJson(e as Map<String, dynamic>))
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
  Stream<List<BazarList>> watchByUser(String uniqueId) {
    return _dbRef
        .orderByChild('unique_id')
        .equalTo(uniqueId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => BazarList.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }
}
