import 'package:flutter/material.dart';

import '../../../model/mess/mess_main.dart';
import '../../data/providers/mess_repository_provider.dart';
import '../../data/repository/mess_repository.dart';

class MessMainController extends ChangeNotifier {
  final List<MessMain> _items = [];
  List<MessMain> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late final MessMainRepository _repo;

  MessMainController() {
    _init();
  }

  Future<void> _init() async {
    _repo = await MessRepositoryProvider.instance.messMainRepository;
    await loadItems();
    _repo.watchAll().listen((data) {
      _items
        ..clear()
        ..addAll(data);
      notifyListeners();
    });
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    final local = await _repo.getAll();
    _items
      ..clear()
      ..addAll(local);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(MessMain item) async {
    await _repo.insert(item);
  }

  Future<void> updateItem(MessMain item) async {
    await _repo.update(item);
  }

  Future<void> deleteItem(MessMain item) async {
    if (item.id != null && item.messId != null) {
      await _repo.delete(item.id!, item.messId!);
    }
  }

  Future<void> sync() async {
    await _repo.syncPendingOperations();
    await loadItems();
  }
}
