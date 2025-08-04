import 'package:flutter/material.dart';

import '../../../model/mess/bazar_list.dart';
import '../../data/providers/mess_repository_provider.dart';
import '../../data/repository/mess_bazar_repository.dart';

class BazarListController extends ChangeNotifier {
  final List<BazarList> _items = [];
  List<BazarList> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late final BazarListRepository _repo;

  BazarListController() {
    _init();
  }

  Future<void> _init() async {
    _repo = await MessRepositoryProvider.instance.bazarListRepository;
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

  Future<void> add(BazarList item) async => await _repo.insert(item);
  Future<void> update(BazarList item) async => await _repo.update(item);
  Future<void> delete(BazarList item) async {
    if (item.id != null && item.uniqueId != null) {
      await _repo.delete(item.id!, item.uniqueId!);
    }
  }

  Future<void> sync() async {
    await _repo.syncPendingOperations();
    await loadItems();
  }
}
