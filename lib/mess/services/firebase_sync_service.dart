import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/db/database_config.dart';
import 'sqlite_realtime_service.dart';

class FirebaseSyncService {
  final SQLiteRealtimeService _localDb;
  final DatabaseReference _firebaseRef;
  final Connectivity _connectivity;

  FirebaseSyncService()
      : _localDb = SQLiteRealtimeService(),
        _firebaseRef = DatabaseConfig.firebaseRef,
        _connectivity = Connectivity();

  Future<void> initialize() async {
    await _localDb.initialize();
    await _setupFirebaseListeners();
    _setupConnectivityListener();
    await _syncPendingOperations();
  }

  Future<void> _setupFirebaseListeners() async {
    void addListenersForTable(String tableName) {
      final ref = _firebaseRef.child(tableName);

      ref.onChildAdded.listen((event) async {
        await _localDb.insertOrUpdate(
          tableName,
          event.snapshot.key!,
          Map<String, dynamic>.from(event.snapshot.value as Map),
          fromSync: true,
        );
      });

      ref.onChildChanged.listen((event) async {
        await _localDb.insertOrUpdate(
          tableName,
          event.snapshot.key!,
          Map<String, dynamic>.from(event.snapshot.value as Map),
          fromSync: true,
        );
      });

      ref.onChildRemoved.listen((event) async {
        await _localDb.delete(tableName, event.snapshot.key!, fromSync: true);
      });
    }

    // Add listeners for all your tables/models:
    addListenersForTable('mess_main');
    addListenersForTable('mess_user');
    addListenersForTable('bazar_list');
    addListenersForTable('my_meals');
    addListenersForTable('account_print');
    addListenersForTable('mess_fees');
    addListenersForTable('others_fee');
    addListenersForTable('payment');
    // pending_operations usually not synced
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await _syncPendingOperations();
      }
    });
  }

  Future<void> _syncPendingOperations() async {
    final pendingOps = await _localDb.getPendingOperations();

    for (final op in pendingOps) {
      try {
        switch (op['operation_type']) {
          case 'upsert':
            await _firebaseRef
                .child('${op['table_name']}/${op['item_id']}')
                .set(jsonDecode(op['item_data']));
            break;
          case 'delete':
            await _firebaseRef
                .child('${op['table_name']}/${op['item_id']}')
                .remove();
            break;
          default:
            print('Unknown operation_type: ${op['operation_type']}');
        }
        await _localDb.clearPendingOperation(op['id']);
      } catch (e) {
        print('Sync error on ${op['table_name']}/${op['item_id']}: $e');
      }
    }
  }

  // Generic method to add or update data in both Firebase and local DB
  Future<void> addOrUpdate(
      String tableName, Map<String, dynamic> data, String? id) async {
    final key = id ?? _firebaseRef.child(tableName).push().key!;
    final connected =
        await _connectivity.checkConnectivity() != ConnectivityResult.none;

    if (connected) {
      await _firebaseRef.child('$tableName/$key').set(data);
    }
    await _localDb.insertOrUpdate(tableName, key, data);
  }

  // Generic update method: just calls addOrUpdate with existing id
  Future<void> update(
      String tableName, String id, Map<String, dynamic> data) async {
    final connected =
        await _connectivity.checkConnectivity() != ConnectivityResult.none;

    if (connected) {
      await _firebaseRef.child('$tableName/$id').update(data);
    }
    await _localDb.insertOrUpdate(tableName, id, data);
  }

  // Generic delete method: delete from Firebase and local DB
  Future<void> delete(String tableName, String id) async {
    final connected =
        await _connectivity.checkConnectivity() != ConnectivityResult.none;

    if (connected) {
      await _firebaseRef.child('$tableName/$id').remove();
    }
    await _localDb.delete(tableName, id);
  }

  // Convenience wrappers per model (optional)

  Future<void> addMessMain(Map<String, dynamic> data, {String? id}) =>
      addOrUpdate('mess_main', data, id);

  Future<void> updateMessMain(String id, Map<String, dynamic> data) =>
      update('mess_main', id, data);

  Future<void> deleteMessMain(String id) => delete('mess_main', id);

  Future<void> addMessUser(Map<String, dynamic> data, {String? id}) =>
      addOrUpdate('mess_user', data, id);

  Future<void> updateMessUser(String id, Map<String, dynamic> data) =>
      update('mess_user', id, data);

  Future<void> deleteMessUser(String id) => delete('mess_user', id);

  Future<void> addBazarList(Map<String, dynamic> data, {String? id}) =>
      addOrUpdate('bazar_list', data, id);

  Future<void> updateBazarList(String id, Map<String, dynamic> data) =>
      update('bazar_list', id, data);

  Future<void> deleteBazarList(String id) => delete('bazar_list', id);

  Future<void> addMyMeals(Map<String, dynamic> data, {String? id}) =>
      addOrUpdate('my_meals', data, id);

  Future<void> updateMyMeals(String id, Map<String, dynamic> data) =>
      update('my_meals', id, data);

  Future<void> deleteMyMeals(String id) => delete('my_meals', id);

  Future<void> addAccountPrint(Map<String, dynamic> data, {String? id}) =>
      addOrUpdate('account_print', data, id);

  Future<void> updateAccountPrint(String id, Map<String, dynamic> data) =>
      update('account_print', id, data);

  Future<void> deleteAccountPrint(String id) => delete('account_print', id);

  Future<void> addMessFees(Map<String, dynamic> data, {String? id}) =>
      addOrUpdate('mess_fees', data, id);

  Future<void> updateMessFees(String id, Map<String, dynamic> data) =>
      update('mess_fees', id, data);

  Future<void> deleteMessFees(String id) => delete('mess_fees', id);

  Future<void> addOthersFee(Map<String, dynamic> data, {String? id}) =>
      addOrUpdate('others_fee', data, id);

  Future<void> updateOthersFee(String id, Map<String, dynamic> data) =>
      update('others_fee', id, data);

  Future<void> deleteOthersFee(String id) => delete('others_fee', id);

  Future<void> addPayment(Map<String, dynamic> data, {String? id}) =>
      addOrUpdate('payment', data, id);

  Future<void> updatePayment(String id, Map<String, dynamic> data) =>
      update('payment', id, data);

  Future<void> deletePayment(String id) => delete('payment', id);

  // ==== MyMeals ====




}



// import 'dart:convert';
//
// import 'package:firebase_database/firebase_database.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
//
// import '../data/db/database_config.dart';
// import 'sqlite_realtime_service.dart';
//
// class FirebaseSyncService {
//   final SQLiteRealtimeService _localDb;
//   final DatabaseReference _firebaseRef;
//   final Connectivity _connectivity;
//
//   FirebaseSyncService()
//       : _localDb = SQLiteRealtimeService(),
//         _firebaseRef = DatabaseConfig.firebaseRef,
//         _connectivity = Connectivity();
//
//   Future<void> initialize() async {
//     await _localDb.initialize();
//     await _setupFirebaseListeners();
//     _setupConnectivityListener();
//     await _syncPendingOperations();
//   }
//
//   Future<void> _setupFirebaseListeners() async {
//     // Helper to add listeners on a given table path
//     void addListenersForTable(String tableName) {
//       final ref = _firebaseRef.child(tableName);
//
//       ref.onChildAdded.listen((event) async {
//         await _localDb.insertOrUpdate(
//           tableName,
//           event.snapshot.key!,
//           Map<String, dynamic>.from(event.snapshot.value as Map),
//           fromSync: true,
//         );
//       });
//
//       ref.onChildChanged.listen((event) async {
//         await _localDb.insertOrUpdate(
//           tableName,
//           event.snapshot.key!,
//           Map<String, dynamic>.from(event.snapshot.value as Map),
//           fromSync: true,
//         );
//       });
//
//       ref.onChildRemoved.listen((event) async {
//         await _localDb.delete(tableName, event.snapshot.key!, fromSync: true);
//       });
//     }
//
//     // Add listeners for all your tables/models:
//     addListenersForTable('mess_main');
//     addListenersForTable('mess_user');
//     addListenersForTable('bazar_list');
//     addListenersForTable('my_meals');
//     addListenersForTable('account_print');
//     addListenersForTable('mess_fees');
//     addListenersForTable('others_fee');
//     addListenersForTable('payment');
//     addListenersForTable('pending_operations'); // Usually you don't sync this, but added for completeness
//   }
//
//   void _setupConnectivityListener() {
//     _connectivity.onConnectivityChanged.listen((result) async {
//       if (result != ConnectivityResult.none) {
//         await _syncPendingOperations();
//       }
//     });
//   }
//
//   Future<void> _syncPendingOperations() async {
//     final pendingOps = await _localDb.getPendingOperations();
//
//     for (final op in pendingOps) {
//       try {
//         switch (op['operation_type']) {
//           case 'upsert':
//             await _firebaseRef
//                 .child('${op['table_name']}/${op['item_id']}')
//                 .set(jsonDecode(op['item_data']));
//             break;
//           case 'delete':
//             await _firebaseRef
//                 .child('${op['table_name']}/${op['item_id']}')
//                 .remove();
//             break;
//           default:
//             print('Unknown operation_type: ${op['operation_type']}');
//         }
//         await _localDb.clearPendingOperation(op['id']);
//       } catch (e) {
//         print('Sync error on ${op['table_name']}/${op['item_id']}: $e');
//       }
//     }
//   }
//
//   // Generic method to add or update data in both Firebase and local DB
//   Future<void> addOrUpdate(
//       String tableName, Map<String, dynamic> data, String? id) async {
//     final key = id ?? _firebaseRef.child(tableName).push().key!;
//     final connected = await _connectivity.checkConnectivity() != ConnectivityResult.none;
//
//     if (connected) {
//       await _firebaseRef.child('$tableName/$key').set(data);
//     }
//     await _localDb.insertOrUpdate(tableName, key, data);
//   }
//
//   // Generic method to delete data from both Firebase and local DB
//   Future<void> delete(String tableName, String id) async {
//     final connected = await _connectivity.checkConnectivity() != ConnectivityResult.none;
//
//     if (connected) {
//       await _firebaseRef.child('$tableName/$id').remove();
//     }
//     await _localDb.delete(tableName, id);
//   }
//
//   // You can add convenience methods if you want, e.g.:
//   Future<void> addMessMain(Map<String, dynamic> data, {String? id}) =>
//       addOrUpdate('mess_main', data, id);
//
//   Future<void> addMessUser(Map<String, dynamic> data, {String? id}) =>
//       addOrUpdate('mess_user', data, id);
//
//   Future<void> addBazarList(Map<String, dynamic> data, {String? id}) =>
//       addOrUpdate('bazar_list', data, id);
//
//   Future<void> addMyMeals(Map<String, dynamic> data, {String? id}) =>
//       addOrUpdate('my_meals', data, id);
//
//   Future<void> addAccountPrint(Map<String, dynamic> data, {String? id}) =>
//       addOrUpdate('account_print', data, id);
//
//   Future<void> addMessFees(Map<String, dynamic> data, {String? id}) =>
//       addOrUpdate('mess_fees', data, id);
//
//   Future<void> addOthersFee(Map<String, dynamic> data, {String? id}) =>
//       addOrUpdate('others_fee', data, id);
//
//   Future<void> addPayment(Map<String, dynamic> data, {String? id}) =>
//       addOrUpdate('payment', data, id);
// }



// import 'dart:convert';
//
// import 'package:firebase_database/firebase_database.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import '../data/db/database_config.dart';
// import 'sqlite_realtime_service.dart';
//
// class FirebaseSyncService {
//   final SQLiteRealtimeService _localDb;
//   final DatabaseReference _firebaseRef;
//   final Connectivity _connectivity;
//
//   FirebaseSyncService()
//       : _localDb = SQLiteRealtimeService(),
//         _firebaseRef = DatabaseConfig.firebaseRef,
//         _connectivity = Connectivity();
//
//   Future<void> initialize() async {
//     await _localDb.initialize();
//     await _setupFirebaseListeners();
//     _setupConnectivityListener();
//     await _syncPendingOperations();
//   }
//
//   Future<void> _setupFirebaseListeners() async {
//     // MessMain listeners
//     _firebaseRef.child('mess_main').onChildAdded.listen((event) async {
//       await _localDb.insertOrUpdate(
//           'mess_main',
//           event.snapshot.key!,
//           event.snapshot.value as Map<String, dynamic>,
//           fromSync: true
//       );
//     });
//
//     _firebaseRef.child('mess_main').onChildChanged.listen((event) async {
//       await _localDb.insertOrUpdate(
//           'mess_main',
//           event.snapshot.key!,
//           event.snapshot.value as Map<String, dynamic>,
//           fromSync: true
//       );
//     });
//
//     _firebaseRef.child('mess_main').onChildRemoved.listen((event) async {
//       await _localDb.delete('mess_main', event.snapshot.key!, fromSync: true);
//     });
//
//     // Similar listeners for other models...
//   }
//
//   void _setupConnectivityListener() {
//     _connectivity.onConnectivityChanged.listen((result) async {
//       if (result != ConnectivityResult.none) {
//         await _syncPendingOperations();
//       }
//     });
//   }
//
//   Future<void> _syncPendingOperations() async {
//     final pendingOps = await _localDb.getPendingOperations();
//
//     for (final op in pendingOps) {
//       try {
//         switch (op['operation_type']) {
//           case 'upsert':
//             await _firebaseRef
//                 .child('${op['table_name']}/${op['item_id']}')
//                 .set(jsonDecode(op['item_data']));
//             break;
//           case 'delete':
//             await _firebaseRef
//                 .child('${op['table_name']}/${op['item_id']}')
//                 .remove();
//             break;
//         }
//         await _localDb.clearPendingOperation(op['id']);
//       } catch (e) {
//         print('Sync error: $e');
//       }
//     }
//   }
//
//   Future<void> addMessMain(Map<String, dynamic> data) async {
//     final id = _firebaseRef.child('mess_main').push().key!;
//     if ((await _connectivity.checkConnectivity()) != ConnectivityResult.none) {
//       await _firebaseRef.child('mess_main/$id').set(data);
//     }
//     await _localDb.insertOrUpdate('mess_main', id, data);
//   }
//
// // Similar methods for other models...
// }