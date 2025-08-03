import 'package:get/get.dart';

import '../../model/mess/bazar_list.dart';
import '../data/providers/mess_repository_provider.dart';
import '../data/repository/mess_bazar_repository.dart';
import '../services/sync_service.dart';

class BazarListController extends GetxController {
  late final BazarListRepository _repo;
  final SyncService _syncService = SyncService();

  final RxList<BazarList> bazarLists = RxList<BazarList>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initRepository();
  }

  Future<void> _initRepository() async {
    _repo = await MessRepositoryProvider.instance.bazarListRepository;

    await loadBazarListsFromLocal();

    _repo.watchAll().listen((list) {
      bazarLists.assignAll(list);
    });
  }

  Future<void> loadBazarListsFromLocal() async {
    isLoading.value = true;
    final list = await _repo.getAll();
    bazarLists.assignAll(list);
    isLoading.value = false;
  }

  Future<void> addBazarList(BazarList item) async {
    await _repo.insert(item);
  }

  Future<void> updateBazarList(BazarList item) async {
    await _repo.update(item);
  }

  Future<void> deleteBazarList(BazarList item) async {
    if (item.id == null || item.uniqueId == null) return;
    await _repo.delete(item.id!, item.uniqueId!);
  }

  Future<void> syncPendingOperations() async {
    await _syncService.syncPendingOperations();
    await loadBazarListsFromLocal();
  }
}
