import 'package:get/get.dart';

import '../../model/mess/others_fee.dart';
import '../data/providers/mess_repository_provider.dart';
import '../data/repository/mess_others_fee_repository.dart';
import '../services/sync_service.dart';

class OthersFeeController extends GetxController {
  late final OthersFeeRepository _repo;
  final SyncService _syncService = SyncService();

  final RxList<OthersFee> othersFees = RxList<OthersFee>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initRepository();
  }

  Future<void> _initRepository() async {
    _repo = await MessRepositoryProvider.instance.othersFeeRepository;

    await loadOthersFeesFromLocal();

    _repo.watchAll().listen((list) {
      othersFees.assignAll(list);
    });
  }

  Future<void> loadOthersFeesFromLocal() async {
    isLoading.value = true;
    final list = await _repo.getAll();
    othersFees.assignAll(list);
    isLoading.value = false;
  }

  Future<void> addOthersFee(OthersFee item) async {
    await _repo.insert(item);
  }

  Future<void> updateOthersFee(OthersFee item) async {
    await _repo.update(item);
  }

  Future<void> deleteOthersFee(OthersFee item) async {
    if (item.id == null || item.uniqueId == null) return;
    await _repo.delete(item.id!, item.uniqueId!);
  }

  Future<void> syncPendingOperations() async {
    await _syncService.syncPendingOperations();
    await loadOthersFeesFromLocal();
  }
}
