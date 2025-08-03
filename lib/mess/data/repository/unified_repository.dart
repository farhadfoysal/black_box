import 'package:rxdart/rxdart.dart';

import '../../services/firebase_sync_service.dart';
import '../../services/sqlite_realtime_service.dart';

class UnifiedRepository {
  final FirebaseSyncService _firebaseSync;
  final SQLiteRealtimeService _localDb;

  UnifiedRepository(this._firebaseSync, this._localDb);

  // ==== MessMain ====

  Stream<List<Map<String, dynamic>>> watchAllMessMains() {
    return _localDb.watchTable('mess_main');
  }

  Stream<Map<String, dynamic>?> watchMessMain(String id) {
    return _localDb.watchItem('mess_main', id);
  }

  Future<void> addMessMain(Map<String, dynamic> data) async {
    await _firebaseSync.addMessMain(data);
  }

  Future<void> updateMessMain(String id, Map<String, dynamic> data) async {
    await _firebaseSync.updateMessMain(id, data);
  }

  Future<void> deleteMessMain(String id) async {
    await _firebaseSync.deleteMessMain(id);
  }

  // ==== MessUser ====

  Stream<List<Map<String, dynamic>>> watchMessUsersByMess(String messId) {
    return _localDb.watchTable('mess_user').map(
          (users) => users.where((u) => u['mess_id'] == messId).toList(),
    );
  }

  Stream<Map<String, dynamic>?> watchMessUser(String id) {
    return _localDb.watchItem('mess_user', id);
  }

  Future<void> addMessUser(Map<String, dynamic> data) async {
    await _firebaseSync.addMessUser(data);
  }

  Future<void> updateMessUser(String id, Map<String, dynamic> data) async {
    await _firebaseSync.updateMessUser(id, data);
  }

  Future<void> deleteMessUser(String id) async {
    await _firebaseSync.deleteMessUser(id);
  }

  // ==== BazarList ====

  Stream<List<Map<String, dynamic>>> watchBazarListsByMess(String messId) {
    return _localDb.watchTable('bazar_list').map(
          (lists) => lists.where((l) => l['mess_id'] == messId).toList(),
    );
  }

  Stream<Map<String, dynamic>?> watchBazarList(String id) {
    return _localDb.watchItem('bazar_list', id);
  }

  Future<void> addBazarList(Map<String, dynamic> data) async {
    await _firebaseSync.addBazarList(data);
  }

  Future<void> updateBazarList(String id, Map<String, dynamic> data) async {
    await _firebaseSync.updateBazarList(id, data);
  }

  Future<void> deleteBazarList(String id) async {
    await _firebaseSync.deleteBazarList(id);
  }

  // ==== MessFee ====

  Stream<List<Map<String, dynamic>>> watchMessFeesByMess(String messId) {
    return _localDb.watchTable('mess_fees').map(
          (fees) => fees.where((f) => f['mess_id'] == messId).toList(),
    );
  }

  Stream<Map<String, dynamic>?> watchMessFee(String id) {
    return _localDb.watchItem('mess_fees', id);
  }

  Future<void> addMessFee(Map<String, dynamic> data) async {
    await _firebaseSync.addMessFees(data);
  }

  Future<void> updateMessFee(String id, Map<String, dynamic> data) async {
    await _firebaseSync.updateMessFees(id, data);
  }

  Future<void> deleteMessFee(String id) async {
    await _firebaseSync.deleteMessFees(id);
  }

  // ==== AccountPrint ====

  Stream<List<Map<String, dynamic>>> watchAccountPrintsByUser(String uniqueId) {
    return _localDb.watchTable('account_print').map(
          (prints) => prints.where((p) => p['unique_id'] == uniqueId).toList(),
    );
  }

  Stream<Map<String, dynamic>?> watchAccountPrint(String id) {
    return _localDb.watchItem('account_print', id);
  }

  Future<void> addAccountPrint(Map<String, dynamic> data) async {
    await _firebaseSync.addAccountPrint(data);
  }

  Future<void> updateAccountPrint(String id, Map<String, dynamic> data) async {
    await _firebaseSync.updateAccountPrint(id, data);
  }

  Future<void> deleteAccountPrint(String id) async {
    await _firebaseSync.deleteAccountPrint(id);
  }

  // ==== OthersFee ====

  Stream<List<Map<String, dynamic>>> watchOthersFeesByMess(String messId) {
    return _localDb.watchTable('others_fee').map(
          (fees) => fees.where((f) => f['mess_id'] == messId).toList(),
    );
  }

  Stream<Map<String, dynamic>?> watchOthersFee(String id) {
    return _localDb.watchItem('others_fee', id);
  }

  Future<void> addOthersFee(Map<String, dynamic> data) async {
    await _firebaseSync.addOthersFee(data);
  }

  Future<void> updateOthersFee(String id, Map<String, dynamic> data) async {
    await _firebaseSync.updateOthersFee(id, data);
  }

  Future<void> deleteOthersFee(String id) async {
    await _firebaseSync.deleteOthersFee(id);
  }

  // ==== Payment ====

  Stream<List<Map<String, dynamic>>> watchPaymentsByUser(String uniqueId) {
    return _localDb.watchTable('payment').map(
          (payments) => payments.where((p) => p['unique_id'] == uniqueId).toList(),
    );
  }

  Stream<Map<String, dynamic>?> watchPayment(String id) {
    return _localDb.watchItem('payment', id);
  }

  Future<void> addPayment(Map<String, dynamic> data) async {
    await _firebaseSync.addPayment(data);
  }

  Future<void> updatePayment(String id, Map<String, dynamic> data) async {
    await _firebaseSync.updatePayment(id, data);
  }

  Future<void> deletePayment(String id) async {
    await _firebaseSync.deletePayment(id);
  }

  Stream<List<Map<String, dynamic>>> watchMyMealsByMess(String messId) {
    return _localDb.watchTable('my_meals').map(
          (meals) => meals.where((m) => m['mess_id'] == messId).toList(),
    );
  }

  Stream<Map<String, dynamic>?> watchMyMeal(String id) {
    return _localDb.watchItem('my_meals', id);
  }

  Future<void> addMyMeal(Map<String, dynamic> data) async {
    await _firebaseSync.addMyMeals(data);
  }

  Future<void> updateMyMeal(String id, Map<String, dynamic> data) async {
    await _firebaseSync.updateMyMeals(id, data);
  }

  Future<void> deleteMyMeal(String id) async {
    await _firebaseSync.deleteMyMeals(id);
  }

  // ==== Combined Streams Examples ====

  /// Watch mess with users combined
  Stream<Map<String, dynamic>> watchMessWithUsers(String messId) {
    return Rx.combineLatest2<Map<String, dynamic>?, List<Map<String, dynamic>>, Map<String, dynamic>>(
      watchMessMain(messId),
      watchMessUsersByMess(messId),
          (mess, users) {
        return {
          if (mess != null) ...mess,
          'users': users,
        };
      },
    ).where((data) => data.isNotEmpty);
  }


  /// Watch mess with bazar lists combined
  Stream<Map<String, dynamic>> watchMessWithBazarLists(String messId) {
    return Rx.combineLatest2<Map<String, dynamic>?, List<Map<String, dynamic>>, Map<String, dynamic>>(
      watchMessMain(messId),
      watchBazarListsByMess(messId),
          (mess, bazarLists) {
        return {
          if (mess != null) ...mess,
          'bazar_lists': bazarLists,
        };
      },
    ).where((data) => data.isNotEmpty);
  }
}
