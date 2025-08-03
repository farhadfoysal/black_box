import 'package:get/get.dart';

import '../../model/mess/mess_fees.dart';
import '../data/providers/mess_repository_provider.dart';
import '../data/repository/mess_fee_repository.dart';
import '../services/sync_service.dart';

class MessFeesController extends GetxController {
  late final MessFeesRepository _repo;
  final SyncService _syncService = SyncService();

  final RxList<MessFees> fees = RxList<MessFees>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initRepository();
  }

  Future<void> _initRepository() async {
    _repo = await MessRepositoryProvider.instance.messFeesRepository;

    await loadFeesFromLocal();

    _repo.watchAll().listen((list) {
      fees.assignAll(list);
    });
  }

  Future<void> loadFeesFromLocal() async {
    isLoading.value = true;
    final list = await _repo.getAll();
    fees.assignAll(list);
    isLoading.value = false;
  }

  Future<void> addFee(MessFees item) async {
    await _repo.insert(item);
  }

  Future<void> updateFee(MessFees item) async {
    await _repo.update(item);
  }

  Future<void> deleteFee(MessFees item) async {
    if (item.id == null) return;
    await _repo.delete(item.id!);
  }

  Future<void> syncPendingOperations() async {
    await _syncService.syncPendingOperations();
    await loadFeesFromLocal();
  }
}
