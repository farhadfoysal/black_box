import 'package:flutter/material.dart';

import '../../../model/mess/others_fee.dart';
import '../../data/providers/mess_repository_provider.dart';
import '../../data/repository/mess_others_fee_repository.dart';

class OthersFeeController extends ChangeNotifier {
  final List<OthersFee> _items = [];
  List<OthersFee> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late final OthersFeeRepository _repo;

  OthersFeeController() {
    _init();
  }

  Future<void> _init() async {
    _repo = await MessRepositoryProvider.instance.othersFeeRepository;
    await loadItems();
    _repo.watchAll().listen((data) {
      _items..clear()..addAll(data);
      notifyListeners();
    });
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    final local = await _repo.getAll();
    _items..clear()..addAll(local);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> add(OthersFee item) async => await _repo.insert(item);
  Future<void> update(OthersFee item) async => await _repo.update(item);
  Future<void> delete(OthersFee item) async {
    if (item.id != null && item.uniqueId != null) {
      await _repo.delete(item.id!, item.uniqueId!);
    }
  }

  Future<void> sync() async {
    await _repo.syncPendingOperations();
    await loadItems();
  }
}
