import 'package:get/get.dart';

import '../../model/mess/account_print.dart';
import '../data/providers/mess_repository_provider.dart';
import '../data/repository/mess_print_repository.dart';
import '../services/sync_service.dart';

class AccountPrintController extends GetxController {
  late final AccountPrintRepository _repo;
  final SyncService _syncService = SyncService();

  final RxList<AccountPrint> accountPrints = RxList<AccountPrint>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initRepository();
  }

  Future<void> _initRepository() async {
    _repo = await MessRepositoryProvider.instance.accountPrintRepository;

    await loadAccountPrintsFromLocal();

    _repo.watchAll().listen((list) {
      accountPrints.assignAll(list);
    });
  }

  Future<void> loadAccountPrintsFromLocal() async {
    isLoading.value = true;
    final list = await _repo.getAll();
    accountPrints.assignAll(list);
    isLoading.value = false;
  }

  Future<void> addAccountPrint(AccountPrint item) async {
    await _repo.insert(item);
  }

  Future<void> updateAccountPrint(AccountPrint item) async {
    await _repo.update(item);
  }

  Future<void> deleteAccountPrint(AccountPrint item) async {
    if (item.id == null || item.uniqueId == null) return;
    await _repo.delete(item.id!, item.uniqueId!);
  }

  Future<void> syncPendingOperations() async {
    await _syncService.syncPendingOperations();
    await loadAccountPrintsFromLocal();
  }
}
