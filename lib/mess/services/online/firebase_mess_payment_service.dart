import 'package:firebase_database/firebase_database.dart';
import '../../../model/mess/payment.dart';
import '../../data/db/database_interfaces.dart';

class FirebasePaymentService implements BaseDatabaseService<Payment> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('payment');

  @override
  Future<String> create(Payment payment) async {
    final newRef = _dbRef.push();
    await newRef.set(payment.toJson());
    return newRef.key!;
  }

  @override
  Future<void> update(String id, Payment payment) async {
    await _dbRef.child(id).update(payment.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _dbRef.child(id).remove();
  }

  @override
  Future<Payment?> get(String id) async {
    final snapshot = await _dbRef.child(id).get();
    return snapshot.exists ? Payment.fromJson(snapshot.value as Map<String, dynamic>) : null;
  }

  @override
  Future<List<Payment>> getAll() async {
    final snapshot = await _dbRef.get();
    if (snapshot.exists) {
      return (snapshot.value as Map).values
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Stream<Payment?> watch(String id) {
    return _dbRef.child(id).onValue.map((event) {
      return event.snapshot.exists
          ? Payment.fromJson(event.snapshot.value as Map<String, dynamic>)
          : null;
    });
  }

  @override
  Stream<List<Payment>> watchAll() {
    return _dbRef.onValue.map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => Payment.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }

  @override
  Stream<List<Payment>> watchByMess(String messId) {
    return _dbRef
        .orderByChild('mess_id')
        .equalTo(messId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => Payment.fromJson(e as Map<String, dynamic>))
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
  Stream<List<Payment>> watchByUser(String uniqueId) {
    return _dbRef
        .orderByChild('unique_id')
        .equalTo(uniqueId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => Payment.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }
}
