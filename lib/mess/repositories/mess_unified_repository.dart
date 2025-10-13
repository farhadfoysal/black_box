// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:rxdart/rxdart.dart';
//
// import '../services/firebase_sync_service.dart';
// import '../services/sqlite_realtime_service.dart';
//
//
// class UnifiedRepository {
//   final FirebaseSyncService _firebaseSync;
//   final SQLiteRealtimeService _localDb;
//
//   UnifiedRepository(this._firebaseSync, this._localDb);
//
//   // =============================
//   // Generic Helpers
//   // =============================
//
//   Future<bool> _isOnline() async {
//     final result = await Connectivity().checkConnectivity();
//     return result != ConnectivityResult.none;
//   }
//
//   Future<void> _trySync() async {
//     if (await _isOnline()) {
//       await syncPendingOperations();
//     }
//   }
//
//   Future<void> addItem(String table, Map<String, dynamic> data) async {
//     final newData = {...data, 'sync_status': 'pendingCreate', 'last_updated': DateTime.now().toIso8601String()};
//     await _localDb.insert(table, newData);
//     await _trySync();
//   }
//
//   Future<void> updateItem(String table, String id, Map<String, dynamic> data) async {
//     final updatedData = {...data, 'sync_status': 'pendingUpdate', 'last_updated': DateTime.now().toIso8601String()};
//     await _localDb.update(table, id, updatedData);
//     await _trySync();
//   }
//
//   Future<void> deleteItem(String table, String id, String uniqueId) async {
//     await _localDb.update(table, id, {'sync_status': 'pendingDelete', 'last_updated': DateTime.now().toIso8601String()});
//     await _trySync();
//   }
//
//   Stream<List<Map<String, dynamic>>> watchTable(String table) {
//     return _localDb.watchTable(table);
//   }
//
//   Stream<Map<String, dynamic>?> watchItem(String table, String id) {
//     return _localDb.watchItem(table, id);
//   }
//
//   Stream<Map<String, dynamic>> combineWithChildren(
//       Stream<Map<String, dynamic>?> mainStream,
//       Stream<List<Map<String, dynamic>>> childStream,
//       String childKey,
//       ) {
//     return Rx.combineLatest2(mainStream, childStream, (main, children) {
//       return {
//         if (main != null) ...main,
//         childKey: children,
//       };
//     }).where((data) => data.isNotEmpty);
//   }
//
//   // =============================
//   // Sync Pending Operations
//   // =============================
//
//   Future<void> syncPendingOperations() async {
//     final pendingItems = await _localDb.getPendingOperations(); // returns List<Map> of items with sync_status != 'synced'
//
//     for (final item in pendingItems) {
//       final table = item['table'] as String;
//       final uniqueId = item['unique_id'] ?? item['id'].toString();
//
//       try {
//         switch (item['sync_status']) {
//           case 'pendingCreate':
//             await _firebaseSync.addGeneric(table, item);
//             break;
//           case 'pendingUpdate':
//             await _firebaseSync.updateGeneric(table, uniqueId, item);
//             break;
//           case 'pendingDelete':
//             await _firebaseSync.deleteGeneric(table, uniqueId);
//             await _localDb.deleteByUniqueId(table, uniqueId);
//             continue; // Skip setting synced
//         }
//
//         // Mark synced
//         await _localDb.updateSyncStatus(table, uniqueId, 'synced');
//       } catch (e) {
//         print('Sync failed for $table $uniqueId: $e');
//       }
//     }
//   }
//
//   // =============================
//   // Table-Specific Convenience Methods
//   // =============================
//
//   // MessMain
//   Stream<List<Map<String, dynamic>>> watchAllMessMains() => watchTable('mess_main');
//   Stream<Map<String, dynamic>?> watchMessMain(String id) => watchItem('mess_main', id);
//   Future<void> addMessMain(Map<String, dynamic> data) => addItem('mess_main', data);
//   Future<void> updateMessMain(String id, Map<String, dynamic> data) => updateItem('mess_main', id, data);
//   Future<void> deleteMessMain(String id, String uniqueId) => deleteItem('mess_main', id, uniqueId);
//
//   // MessUser
//   Stream<List<Map<String, dynamic>>> watchMessUsersByMess(String messId) =>
//       watchTable('mess_user').map((users) => users.where((u) => u['mess_id'] == messId).toList());
//   Stream<Map<String, dynamic>?> watchMessUser(String id) => watchItem('mess_user', id);
//   Future<void> addMessUser(Map<String, dynamic> data) => addItem('mess_user', data);
//   Future<void> updateMessUser(String id, Map<String, dynamic> data) => updateItem('mess_user', id, data);
//   Future<void> deleteMessUser(String id, String uniqueId) => deleteItem('mess_user', id, uniqueId);
//
//   // BazarList
//   Stream<List<Map<String, dynamic>>> watchBazarListsByMess(String messId) =>
//       watchTable('bazar_list').map((lists) => lists.where((l) => l['mess_id'] == messId).toList());
//   Stream<Map<String, dynamic>?> watchBazarList(String id) => watchItem('bazar_list', id);
//   Future<void> addBazarList(Map<String, dynamic> data) => addItem('bazar_list', data);
//   Future<void> updateBazarList(String id, Map<String, dynamic> data) => updateItem('bazar_list', id, data);
//   Future<void> deleteBazarList(String id, String uniqueId) => deleteItem('bazar_list', id, uniqueId);
//
//   // MessFees
//   Stream<List<Map<String, dynamic>>> watchMessFeesByMess(String messId) =>
//       watchTable('mess_fees').map((fees) => fees.where((f) => f['mess_id'] == messId).toList());
//   Stream<Map<String, dynamic>?> watchMessFee(String id) => watchItem('mess_fees', id);
//   Future<void> addMessFee(Map<String, dynamic> data) => addItem('mess_fees', data);
//   Future<void> updateMessFee(String id, Map<String, dynamic> data) => updateItem('mess_fees', id, data);
//   Future<void> deleteMessFee(String id, String uniqueId) => deleteItem('mess_fees', id, uniqueId);
//
//   // AccountPrint
//   Stream<List<Map<String, dynamic>>> watchAccountPrintsByUser(String uniqueId) =>
//       watchTable('account_print').map((prints) => prints.where((p) => p['unique_id'] == uniqueId).toList());
//   Stream<Map<String, dynamic>?> watchAccountPrint(String id) => watchItem('account_print', id);
//   Future<void> addAccountPrint(Map<String, dynamic> data) => addItem('account_print', data);
//   Future<void> updateAccountPrint(String id, Map<String, dynamic> data) => updateItem('account_print', id, data);
//   Future<void> deleteAccountPrint(String id, String uniqueId) => deleteItem('account_print', id, uniqueId);
//
//   // OthersFee
//   Stream<List<Map<String, dynamic>>> watchOthersFeesByMess(String messId) =>
//       watchTable('others_fee').map((fees) => fees.where((f) => f['mess_id'] == messId).toList());
//   Stream<Map<String, dynamic>?> watchOthersFee(String id) => watchItem('others_fee', id);
//   Future<void> addOthersFee(Map<String, dynamic> data) => addItem('others_fee', data);
//   Future<void> updateOthersFee(String id, Map<String, dynamic> data) => updateItem('others_fee', id, data);
//   Future<void> deleteOthersFee(String id, String uniqueId) => deleteItem('others_fee', id, uniqueId);
//
//   // Payment
//   Stream<List<Map<String, dynamic>>> watchPaymentsByUser(String uniqueId) =>
//       watchTable('payment').map((payments) => payments.where((p) => p['unique_id'] == uniqueId).toList());
//   Stream<Map<String, dynamic>?> watchPayment(String id) => watchItem('payment', id);
//   Future<void> addPayment(Map<String, dynamic> data) => addItem('payment', data);
//   Future<void> updatePayment(String id, Map<String, dynamic> data) => updateItem('payment', id, data);
//   Future<void> deletePayment(String id, String uniqueId) => deleteItem('payment', id, uniqueId);
//
//   // MyMeals
//   Stream<List<Map<String, dynamic>>> watchMyMealsByMess(String messId) =>
//       watchTable('my_meals').map((meals) => meals.where((m) => m['mess_id'] == messId).toList());
//   Stream<Map<String, dynamic>?> watchMyMeal(String id) => watchItem('my_meals', id);
//   Future<void> addMyMeal(Map<String, dynamic> data) => addItem('my_meals', data);
//   Future<void> updateMyMeal(String id, Map<String, dynamic> data) => updateItem('my_meals', id, data);
//   Future<void> deleteMyMeal(String id, String uniqueId) => deleteItem('my_meals', id, uniqueId);
//
//   // =============================
//   // Example Combined Streams
//   // =============================
//   Stream<Map<String, dynamic>> watchMessWithUsers(String messId) =>
//       combineWithChildren(watchMessMain(messId), watchMessUsersByMess(messId), 'users');
//
//   Stream<Map<String, dynamic>> watchMessWithBazarLists(String messId) =>
//       combineWithChildren(watchMessMain(messId), watchBazarListsByMess(messId), 'bazar_lists');
// }
