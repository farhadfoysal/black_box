import 'package:firebase_database/firebase_database.dart';
import '../../../model/mess/account_print.dart';
import '../../data/db/database_interfaces.dart';

class FirebaseAccountPrintService implements BaseDatabaseService<AccountPrint> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('account_print');

  @override
  Future<String> create(AccountPrint accountPrint) async {
    final newRef = _dbRef.push();
    await newRef.set(accountPrint.toJson());
    return newRef.key!;
  }

  @override
  Future<void> update(String id, AccountPrint accountPrint) async {
    await _dbRef.child(id).update(accountPrint.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _dbRef.child(id).remove();
  }

  @override
  Future<AccountPrint?> get(String id) async {
    final snapshot = await _dbRef.child(id).get();
    return snapshot.exists ? AccountPrint.fromJson(snapshot.value as Map<String, dynamic>) : null;
  }

  Future<AccountPrint?> getById(String id) async {
    final snapshot = await _dbRef.child(id).get();
    return snapshot.exists ? AccountPrint.fromJson(snapshot.value as Map<String, dynamic>) : null;
  }

  @override
  Future<List<AccountPrint>> getAll() async {
    final snapshot = await _dbRef.get();
    if (snapshot.exists) {
      return (snapshot.value as Map).values
          .map((e) => AccountPrint.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Stream<AccountPrint?> watch(String id) {
    return _dbRef.child(id).onValue.map((event) {
      return event.snapshot.exists
          ? AccountPrint.fromJson(event.snapshot.value as Map<String, dynamic>)
          : null;
    });
  }

  @override
  Stream<List<AccountPrint>> watchAll() {
    return _dbRef.onValue.map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => AccountPrint.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }

  @override
  Stream<List<AccountPrint>> watchByMess(String messId) {
    return _dbRef
        .orderByChild('mess_id')
        .equalTo(messId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => AccountPrint.fromJson(e as Map<String, dynamic>))
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
  Stream<List<AccountPrint>> watchByUser(String uniqueId) {
    return _dbRef
        .orderByChild('unique_id')
        .equalTo(uniqueId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return (event.snapshot.value as Map).values
            .map((e) => AccountPrint.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }



}
