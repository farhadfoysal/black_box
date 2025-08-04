import 'package:flutter/material.dart';

import '../../../model/mess/payment.dart';
import '../../data/providers/mess_repository_provider.dart';
import '../../data/repository/mess_payment_repository.dart';

class PaymentController extends ChangeNotifier {
  final List<Payment> _payments = [];
  List<Payment> get payments => _payments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late final PaymentRepository _repo;

  PaymentController() {
    _init();
  }

  Future<void> _init() async {
    _repo = await MessRepositoryProvider.instance.paymentRepository;
    await loadItems();
    _repo.watchAll().listen((data) {
      _payments..clear()..addAll(data);
      notifyListeners();
    });
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    final local = await _repo.getAll();
    _payments..clear()..addAll(local);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> add(Payment item) async => await _repo.insert(item);
  Future<void> update(Payment item) async => await _repo.update(item);
  Future<void> delete(Payment item) async {
    if (item.id != null && item.uniqueId != null) {
      await _repo.delete(item.id!, item.uniqueId!);
    }
  }

  Future<void> sync() async {
    await _repo.syncPendingOperations();
    await loadItems();
  }
}
