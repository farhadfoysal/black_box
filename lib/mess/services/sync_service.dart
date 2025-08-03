import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/db/database_config.dart';
import '../data/model/model_extensions.dart';
import '../data/providers/mess_repository_provider.dart';

class SyncService {
  final DatabaseConfig _dbConfig = DatabaseConfig.instance;

  /// Run this method periodically or when connectivity is restored
  Future<void> syncPendingOperations() async {
    // Check if device is online
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('No internet, skipping sync');
      return;
    }

    final db = await _dbConfig.database;

    // Fetch all pending operations sorted by created_at ascending
    final List<Map<String, dynamic>> pendingOps = await db.query(
      'pending_operations',
      orderBy: 'created_at ASC',
    );

    if (pendingOps.isEmpty) {
      print('No pending operations to sync');
      return;
    }

    print('Syncing ${pendingOps.length} pending operations...');

    for (var op in pendingOps) {
      final int opId = op['id'];
      final String tableName = op['table_name'];
      final String operation = op['operation']; // create, update, delete
      final String itemId = op['item_id'];
      final String itemDataJson = op['item_data'];

      try {
        final itemData = jsonDecode(itemDataJson);

        // Apply sync depending on table and operation
        switch (tableName) {
          case 'mess_main':
            await _syncMessMain(opId, operation, itemId, itemData);
            break;
          case 'mess_user':
            await _syncMessUser(opId, operation, itemId, itemData);
            break;
          case 'bazar_list':
            await _syncBazarList(opId, operation, itemId, itemData);
            break;
          case 'my_meals':
            await _syncMyMeals(opId, operation, itemId, itemData);
            break;
          case 'account_print':
            await _syncAccountPrint(opId, operation, itemId, itemData);
            break;
          case 'mess_fees':
            await _syncMessFees(opId, operation, itemId, itemData);
            break;
          case 'others_fee':
            await _syncOthersFee(opId, operation, itemId, itemData);
            break;
          case 'payment':
            await _syncPayment(opId, operation, itemId, itemData);
            break;
          default:
            print('Unknown table $tableName, skipping');
        }
      } catch (e) {
        print('Error syncing operation id $opId: $e');
      }
    }

    print('Sync completed');
  }

  Future<void> enqueuePendingOperation({
    required String tableName,
    required String operation, // 'create', 'update', 'delete'
    required String itemId,
    required Map<String, dynamic> itemData,
  }) async {
    final db = await DatabaseConfig.instance.database;
    await db.insert('pending_operations', {
      'table_name': tableName,
      'operation': operation,
      'item_id': itemId,
      'item_data': jsonEncode(itemData),
      'created_at': DateTime.now().toIso8601String(),
    });
  }


  // Below are example sync handlers per table & operation.
  // These need your repository methods to push data to Firebase
  // and update local SQLite sync status accordingly.

  Future<void> _syncMessMain(int opId, String operation, String itemId, Map<String, dynamic> data) async {
    final repo = await MessRepositoryProvider.instance.messMainRepository;
    final firebaseRef = DatabaseConfig.firebaseRef.child('mess_main').child(itemId);

    if (operation == 'create' || operation == 'update') {
      // Push to Firebase
      await firebaseRef.set(data);
      // Update local sync_status to 'synced'
      await repo.updateSyncStatus(itemId, MessMainSync.synced);
    } else if (operation == 'delete') {
      await firebaseRef.remove();
      await repo.deleteByUniqueId(itemId);
    }

    await _removePendingOperation(opId);
  }

  Future<void> _syncMessUser(int opId, String operation, String itemId, Map<String, dynamic> data) async {
    final repo = await MessRepositoryProvider.instance.messUserRepository;
    final firebaseRef = DatabaseConfig.firebaseRef.child('mess_user').child(itemId);

    if (operation == 'create' || operation == 'update') {
      await firebaseRef.set(data);
      await repo.updateSyncStatus(itemId, MessUserSync.synced);
    } else if (operation == 'delete') {
      await firebaseRef.remove();
      await repo.deleteByUniqueId(itemId);
    }

    await _removePendingOperation(opId);
  }

  Future<void> _syncBazarList(int opId, String operation, String itemId, Map<String, dynamic> data) async {
    final repo = await MessRepositoryProvider.instance.bazarListRepository;
    final firebaseRef = DatabaseConfig.firebaseRef.child('bazar_list').child(itemId);

    if (operation == 'create' || operation == 'update') {
      await firebaseRef.set(data);
      await repo.updateSyncStatus(itemId, BazarListSync.synced);
    } else if (operation == 'delete') {
      await firebaseRef.remove();
      await repo.deleteByUniqueId(itemId);
    }

    await _removePendingOperation(opId);
  }

  Future<void> _syncMyMeals(int opId, String operation, String itemId, Map<String, dynamic> data) async {
    final repo = await MessRepositoryProvider.instance.myMealsRepository;
    final firebaseRef = DatabaseConfig.firebaseRef.child('my_meals').child(itemId);

    if (operation == 'create' || operation == 'update') {
      await firebaseRef.set(data);
      await repo.updateSyncStatus(itemId, MyMealsSync.synced);
    } else if (operation == 'delete') {
      await firebaseRef.remove();
      await repo.deleteByUniqueId(itemId);
    }

    await _removePendingOperation(opId);
  }

  Future<void> _syncAccountPrint(int opId, String operation, String itemId, Map<String, dynamic> data) async {
    final repo = await MessRepositoryProvider.instance.accountPrintRepository;
    final firebaseRef = DatabaseConfig.firebaseRef.child('account_print').child(itemId);

    if (operation == 'create' || operation == 'update') {
      await firebaseRef.set(data);
      await repo.updateSyncStatus(itemId, AccountPrintSync.synced);
    } else if (operation == 'delete') {
      await firebaseRef.remove();
      await repo.deleteByUniqueId(itemId);
    }

    await _removePendingOperation(opId);
  }

  Future<void> _syncMessFees(int opId, String operation, String itemId, Map<String, dynamic> data) async {
    final repo = await MessRepositoryProvider.instance.messFeesRepository;
    final firebaseRef = DatabaseConfig.firebaseRef.child('mess_fees').child(itemId);

    if (operation == 'create' || operation == 'update') {
      await firebaseRef.set(data);
      await repo.updateSyncStatus(itemId, MessFeesSync.synced);
    } else if (operation == 'delete') {
      await firebaseRef.remove();
      await repo.deleteByUniqueId(itemId);
    }

    await _removePendingOperation(opId);
  }

  Future<void> _syncOthersFee(int opId, String operation, String itemId, Map<String, dynamic> data) async {
    final repo = await MessRepositoryProvider.instance.othersFeeRepository;
    final firebaseRef = DatabaseConfig.firebaseRef.child('others_fee').child(itemId);

    if (operation == 'create' || operation == 'update') {
      await firebaseRef.set(data);
      await repo.updateSyncStatus(itemId, OthersFeeSync.synced);
    } else if (operation == 'delete') {
      await firebaseRef.remove();
      await repo.deleteByUniqueId(itemId);
    }

    await _removePendingOperation(opId);
  }

  Future<void> _syncPayment(int opId, String operation, String itemId, Map<String, dynamic> data) async {
    final repo = await MessRepositoryProvider.instance.paymentRepository;
    final firebaseRef = DatabaseConfig.firebaseRef.child('payment').child(itemId);

    if (operation == 'create' || operation == 'update') {
      await firebaseRef.set(data);
      await repo.updateSyncStatus(itemId, PaymentSync.synced);
    } else if (operation == 'delete') {
      await firebaseRef.remove();
      await repo.deleteByUniqueId(itemId);
    }

    await _removePendingOperation(opId);
  }

  // Helper to remove pending operation after success
  Future<void> _removePendingOperation(int id) async {
    final db = await _dbConfig.database;
    await db.delete(
      'pending_operations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
