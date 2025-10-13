import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../model/mess/mess_main.dart';
import '../data/model/model_extensions.dart';
import '../data/providers/mess_repository_provider.dart';
import '../data/repository/mess_repository.dart';
import '../services/sync_service.dart';

class MessMainController extends GetxController {
  late final MessMainRepository _repo;

  // Reactive list for UI updates
  final RxList<MessMain> messMainList = RxList<MessMain>();

  // Loading state
  final RxBool isLoading = false.obs;

  // Sync service instance (singleton or injected)
  final SyncService _syncService = SyncService();

  @override
  void onInit() {
    super.onInit();
    _initRepository();
  }

  Future<void> _initRepository() async {
    _repo = await MessRepositoryProvider.instance.messMainRepository;

    // Load initial data from SQLite
    await loadMessMainFromLocal();

    // Listen to realtime Firebase data changes
    _repo.watchAll().listen((list) {
      messMainList.assignAll(list);
    });

    // Optionally listen to connectivity changes and trigger sync
    Connectivity().onConnectivityChanged.listen((status) {
      if (status != ConnectivityResult.none) {
        syncPendingOperations();
      }
    });
  }

  Future<void> loadMessMainFromLocal() async {
    isLoading.value = true;
    final list = await _repo.getAll();
    messMainList.assignAll(list);
    isLoading.value = false;
  }

  Future<void> addMessMain(MessMain item) async {
    // Insert with pending_create sync status locally
    final newItem = item.copyWithSyncStatus(MessMainSync.pendingCreate);
    await _repo.insert(newItem);

    // Add to pending_operations table
    await _syncService.enqueuePendingOperation(
      tableName: 'mess_main',
      operation: 'create',
      itemId: newItem.messId ?? '',
      itemData: newItem.toJson(),
    );

    // Try syncing immediately if online
    await syncPendingOperations();
  }

  Future<void> updateMessMain(MessMain item) async {
    final updatedItem = item.copyWithSyncStatus(MessMainSync.pendingUpdate);
    await _repo.update(updatedItem);

    await _syncService.enqueuePendingOperation(
      tableName: 'mess_main',
      operation: 'update',
      itemId: updatedItem.messId ?? '',
      itemData: updatedItem.toJson(),
    );

    await syncPendingOperations();
  }

  Future<void> deleteMessMain(MessMain item) async {
    if (item.id == null || item.messId == null) return;

    // Mark for deletion locally
    final deletedItem = item.copyWithSyncStatus(MessMainSync.pendingDelete);
    await _repo.update(deletedItem);

    await _syncService.enqueuePendingOperation(
      tableName: 'mess_main',
      operation: 'delete',
      itemId: deletedItem.messId ?? '',
      itemData: deletedItem.toJson(),
    );

    await syncPendingOperations();
  }

  /// Sync pending operations with Firebase and update local status
  Future<void> syncPendingOperations() async {
    await _syncService.syncPendingOperations();
    // After syncing, refresh local list to reflect latest synced data
    await loadMessMainFromLocal();
  }
}




// import 'package:get/get.dart';
//
// import '../../model/mess/mess_main.dart';
// import '../data/providers/mess_repository_provider.dart';
// import '../data/repositories/mess_repository.dart';
//
// class MessMainController extends GetxController {
//   late final MessMainRepository _repo;
//
//   // Reactive list for UI updates
//   final RxList<MessMain> messMainList = RxList<MessMain>();
//
//   // Loading state
//   final RxBool isLoading = false.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     _initRepository();
//   }
//
//   Future<void> _initRepository() async {
//     _repo = await MessRepositoryProvider.instance.messMainRepository;
//
//     // Load initial data from SQLite
//     await loadMessMainFromLocal();
//
//     // Start listening to realtime Firebase data changes
//     _repo.watchAll().listen((list) {
//       messMainList.assignAll(list);
//     });
//   }
//
//   Future<void> loadMessMainFromLocal() async {
//     isLoading.value = true;
//     final list = await _repo.getAll();
//     messMainList.assignAll(list);
//     isLoading.value = false;
//   }
//
//   Future<void> addMessMain(MessMain item) async {
//     await _repo.insert(item);
//     // You might trigger a sync process here for firebase sync
//   }
//
//   Future<void> updateMessMain(MessMain item) async {
//     await _repo.update(item);
//     // Trigger sync if needed
//   }
//
//   Future<void> deleteMessMain(MessMain item) async {
//     if (item.id == null || item.messId == null) return;
//     await _repo.delete(item.id!, item.messId!);
//     // Trigger sync if needed
//   }
//
//   /// Example sync method that you can expand for offline-first
//   Future<void> syncPendingOperations() async {
//     // Here you would check SQLite for records with pending sync_status
//     // Then send to Firebase and update local sync_status to 'synced'
//     // This method can be called periodically or on connectivity change
//   }
// }
