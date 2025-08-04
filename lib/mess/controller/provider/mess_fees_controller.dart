import 'package:flutter/material.dart';

import '../../../model/mess/mess_fees.dart';
import '../../data/providers/mess_repository_provider.dart';
import '../../data/repository/mess_fee_repository.dart';

class MessFeesController extends ChangeNotifier {
  final List<MessFees> _fees = [];
  List<MessFees> get fees => _fees;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late final MessFeesRepository _repo;

  MessFeesController() {
    _init();
  }

  Future<void> _init() async {
    _repo = await MessRepositoryProvider.instance.messFeesRepository;
    await loadItems();
    _repo.watchAll().listen((data) {
      _fees..clear()..addAll(data);
      notifyListeners();
    });
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    final local = await _repo.getAll();
    _fees..clear()..addAll(local);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> add(MessFees item) async => await _repo.insert(item);
  Future<void> update(MessFees item) async => await _repo.update(item);
  Future<void> delete(MessFees item) async {
    if (item.id != null && item.messId!= null) {
      await _repo.delete(item.id!);
      // await _repo.delete(item.id!, item.messId!);
    }
  }

  Future<void> sync() async {
    await _repo.syncPendingOperations();
    await loadItems();
  }
}
