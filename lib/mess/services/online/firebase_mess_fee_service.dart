import 'package:black_box/model/mess/mess_fees.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../data/db/database_interfaces.dart';

class FirebaseMessFeeService implements BaseDatabaseService<MessFees> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('mess_fee');

  @override
  Future<String> create(MessFees fee) async {
    final newRef = _dbRef.push();
    await newRef.set(fee.toJson());
    return newRef.key!;
  }

  @override
  Future<void> update(String id, MessFees fee) async {
    await _dbRef.child(id).update(fee.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _dbRef.child(id).remove();
  }

  @override
  Future<MessFees?> get(String id) async {
    final snapshot = await _dbRef.child(id).get();
    return snapshot.exists ? MessFees.fromJson(snapshot.value as Map<String, dynamic>) : null;
  }

  @override
  Future<List<MessFees>> getAll() async {
    final snapshot = await _dbRef.get();
    if (snapshot.exists) {
      return (snapshot.value as Map).values
          .map((e) => MessFees.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Stream<MessFees?> watch(String id) {
    return _dbRef.child(id).onValue.map((event) {
      return event.snapshot.exists
          ? MessFees.fromJson(event.snapshot.value as Map<String, dynamic>)
          : null;
    });
  }

  @override
  Stream<List<MessFees>> watchAll() {
    return _dbRef.onValue.map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => MessFees.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }

  @override
  Stream<List<MessFees>> watchByMess(String messId) {
    return _dbRef
        .orderByChild('mess_id')
        .equalTo(messId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => MessFees.fromJson(e as Map<String, dynamic>))
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
  Stream<List<MessFees>> watchByUser(String uniqueId) {
    return _dbRef
        .orderByChild('unique_id')
        .equalTo(uniqueId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => MessFees.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }
}
