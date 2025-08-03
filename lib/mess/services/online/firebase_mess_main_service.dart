import 'package:firebase_database/firebase_database.dart';

import '../../../model/mess/mess_main.dart';
import '../../data/db/database_interfaces.dart';

class FirebaseMessMainService implements BaseDatabaseService<MessMain> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('mess_main');

  @override
  Future<String> create(MessMain mess) async {
    final newRef = _dbRef.push();
    await newRef.set(mess.toJson());
    return newRef.key!;
  }

  @override
  Future<void> update(String id, MessMain mess) async {
    await _dbRef.child(id).update(mess.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _dbRef.child(id).remove();
  }

  @override
  Future<MessMain?> get(String id) async {
    final snapshot = await _dbRef.child(id).get();
    return snapshot.exists ? MessMain.fromJson(snapshot.value as Map<String, dynamic>) : null;
  }

  @override
  Future<List<MessMain>> getAll() async {
    final snapshot = await _dbRef.get();
    if (snapshot.exists) {
      return (snapshot.value as Map).values
          .map((e) => MessMain.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Stream<MessMain?> watch(String id) {
    return _dbRef.child(id).onValue.map((event) {
      return event.snapshot.exists
          ? MessMain.fromJson(event.snapshot.value as Map<String, dynamic>)
          : null;
    });
  }

  @override
  Stream<List<MessMain>> watchAll() {
    return _dbRef.onValue.map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => MessMain.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }

  @override
  Stream<List<MessMain>> watchByMess(String messId) {
    return _dbRef
        .orderByChild('mess_id')
        .equalTo(messId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => MessMain.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }

  @override
  Future<void> pushPendingOperations() async {
    // Not needed for Firebase service
    return Future.value();
  }

  @override
  Future<void> pullLatestData() async {
    // Not needed for Firebase service
    return Future.value();
  }

  @override
  Stream<List<MessMain>> watchByUser(String uniqueId) {
    return _dbRef
        .orderByChild('unique_id')
        .equalTo(uniqueId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => MessMain.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }
}