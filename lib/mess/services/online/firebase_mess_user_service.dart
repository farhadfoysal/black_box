import 'package:firebase_database/firebase_database.dart';
import '../../../model/mess/mess_user.dart';
import '../../data/db/database_interfaces.dart';

class FirebaseMessUserService implements BaseDatabaseService<MessUser> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('mess_user');

  @override
  Future<String> create(MessUser user) async {
    final newRef = _dbRef.push();
    await newRef.set(user.toJson());
    return newRef.key!;
  }

  @override
  Future<void> update(String id, MessUser user) async {
    await _dbRef.child(id).update(user.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _dbRef.child(id).remove();
  }

  @override
  Future<MessUser?> get(String id) async {
    final snapshot = await _dbRef.child(id).get();
    return snapshot.exists ? MessUser.fromJson(snapshot.value as Map<String, dynamic>) : null;
  }

  @override
  Future<List<MessUser>> getAll() async {
    final snapshot = await _dbRef.get();
    if (snapshot.exists) {
      return (snapshot.value as Map).values
          .map((e) => MessUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Stream<MessUser?> watch(String id) {
    return _dbRef.child(id).onValue.map((event) {
      return event.snapshot.exists
          ? MessUser.fromJson(event.snapshot.value as Map<String, dynamic>)
          : null;
    });
  }

  @override
  Stream<List<MessUser>> watchAll() {
    return _dbRef.onValue.map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => MessUser.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }

  @override
  Stream<List<MessUser>> watchByMess(String messId) {
    return _dbRef
        .orderByChild('mess_id')
        .equalTo(messId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => MessUser.fromJson(e as Map<String, dynamic>))
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
  Stream<List<MessUser>> watchByUser(String uniqueId) {
    return _dbRef
        .orderByChild('unique_id')
        .equalTo(uniqueId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => MessUser.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }
}
