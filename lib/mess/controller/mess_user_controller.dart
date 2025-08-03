import 'package:get/get.dart';

import '../../model/mess/mess_user.dart';
import '../data/providers/mess_repository_provider.dart';
import '../data/repository/mess_user_repository.dart';
import '../services/sync_service.dart';

class MessUserController extends GetxController {
  late final MessUserRepository _repo;
  final SyncService _syncService = SyncService();

  final RxList<MessUser> users = RxList<MessUser>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initRepository();
  }

  Future<void> _initRepository() async {
    _repo = await MessRepositoryProvider.instance.messUserRepository;

    // Load initial data from local SQLite
    await loadUsersFromLocal();

    // Listen to realtime Firebase changes and update UI
    _repo.watchAll().listen((list) {
      users.assignAll(list);
    });
  }

  Future<void> loadUsersFromLocal() async {
    isLoading.value = true;
    final list = await _repo.getAll();
    users.assignAll(list);
    isLoading.value = false;
  }

  Future<void> addUser(MessUser user) async {
    await _repo.insert(user);
    // You can enqueue sync operation here if needed
  }

  Future<void> updateUser(MessUser user) async {
    await _repo.update(user);
    // You can enqueue sync operation here if needed
  }

  Future<void> deleteUser(MessUser user) async {
    if (user.id == null || user.uniqueId == null) return;
    await _repo.delete(user.id!, user.uniqueId!);
    // You can enqueue sync operation here if needed
  }

  /// Sync method: runs the SyncService and then reloads local data
  Future<void> syncPendingOperations() async {
    await _syncService.syncPendingOperations();
    // Refresh local data after sync completes
    await loadUsersFromLocal();
  }
}
