import 'package:get/get.dart';

import '../../model/mess/payment.dart';
import '../data/providers/mess_repository_provider.dart';
import '../data/repository/mess_payment_repository.dart';
import '../services/sync_service.dart';

class PaymentController extends GetxController {
  late final PaymentRepository _repo;
  final SyncService _syncService = SyncService();

  final RxList<Payment> payments = RxList<Payment>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initRepository();
  }

  Future<void> _initRepository() async {
    _repo = await MessRepositoryProvider.instance.paymentRepository;

    await loadPaymentsFromLocal();

    _repo.watchAll().listen((list) {
      payments.assignAll(list);
    });
  }

  Future<void> loadPaymentsFromLocal() async {
    isLoading.value = true;
    final list = await _repo.getAll();
    payments.assignAll(list);
    isLoading.value = false;
  }

  Future<void> addPayment(Payment item) async {
    await _repo.insert(item);
  }

  Future<void> updatePayment(Payment item) async {
    await _repo.update(item);
  }

  Future<void> deletePayment(Payment item) async {
    if (item.id == null || item.uniqueId == null) return;
    await _repo.delete(item.id!, item.uniqueId!);
  }

  Future<void> syncPendingOperations() async {
    await _syncService.syncPendingOperations();
    await loadPaymentsFromLocal();
  }
}
