import 'package:firebase_database/firebase_database.dart';
import '../../../model/mess/others_fee.dart';
import '../../data/db/database_interfaces.dart';

class FirebaseOthersFeeService implements BaseDatabaseService<OthersFee> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('others_fee');

  @override
  Future<String> create(OthersFee fee) async {
    final newRef = _dbRef.push();
    await newRef.set(fee.toJson());
    return newRef.key!;
  }

  @override
  Future<void> update(String id, OthersFee fee) async {
    await _dbRef.child(id).update(fee.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _dbRef.child(id).remove();
  }

  @override
  Future<OthersFee?> get(String id) async {
    final snapshot = await _dbRef.child(id).get();
    return snapshot.exists ? OthersFee.fromJson(snapshot.value as Map<String, dynamic>) : null;
  }

  @override
  Future<List<OthersFee>> getAll() async {
    final snapshot = await _dbRef.get();
    if (snapshot.exists) {
      return (snapshot.value as Map).values
          .map((e) => OthersFee.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Stream<OthersFee?> watch(String id) {
    return _dbRef.child(id).onValue.map((event) {
      return event.snapshot.exists
          ? OthersFee.fromJson(event.snapshot.value as Map<String, dynamic>)
          : null;
    });
  }

  @override
  Stream<List<OthersFee>> watchAll() {
    return _dbRef.onValue.map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => OthersFee.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }

  @override
  Stream<List<OthersFee>> watchByMess(String messId) {
    return _dbRef
        .orderByChild('mess_id')
        .equalTo(messId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => OthersFee.fromJson(e as Map<String, dynamic>))
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
  Stream<List<OthersFee>> watchByUser(String uniqueId) {
    return _dbRef
        .orderByChild('unique_id')
        .equalTo(uniqueId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => OthersFee.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }
}
