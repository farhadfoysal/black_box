import 'package:flutter/material.dart';

import '../../../model/mess/account_print.dart';
import '../../data/providers/mess_repository_provider.dart';
import '../../data/repository/mess_print_repository.dart';
import '../../services/sync_service.dart';

class AccountPrintController extends ChangeNotifier {
  final List<AccountPrint> _items = [];
  List<AccountPrint> get items => _items;
  final SyncService _syncService = SyncService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late final AccountPrintRepository _repo;

  AccountPrintController() {
    _init();
  }

  Future<void> _init() async {
    _repo = await MessRepositoryProvider.instance.accountPrintRepository;
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

  Future<void> add(AccountPrint item) async => await _repo.insert(item);
  Future<void> update(AccountPrint item) async => await _repo.update(item);
  Future<void> delete(AccountPrint item) async {
    if (item.id != null && item.uniqueId != null) {
      await _repo.delete(item.id!, item.uniqueId!);
    }
  }

  Future<void> sync() async {
    await _repo.syncPendingOperations();
    await loadItems();
  }
}
