import 'package:flutter/material.dart';

import '../../../model/mess/mess_user.dart';
import '../../data/providers/mess_repository_provider.dart';
import '../../data/repository/mess_user_repository.dart';

class MessUserController extends ChangeNotifier {
  final List<MessUser> _users = [];
  List<MessUser> get users => _users;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late final MessUserRepository _repo;

  MessUserController() {
    _init();
  }

  Future<void> _init() async {
    _repo = await MessRepositoryProvider.instance.messUserRepository;
    await loadUsers();

    _repo.watchAll().listen((data) {
      _users
        ..clear()
        ..addAll(data);
      notifyListeners();
    });
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    final local = await _repo.getAll();
    _users
      ..clear()
      ..addAll(local);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addUser(MessUser user) async {
    await _repo.insert(user);
  }

  Future<void> updateUser(MessUser user) async {
    await _repo.update(user);
  }

  Future<void> deleteUser(MessUser user) async {
    if (user.id != null && user.uniqueId != null) {
      await _repo.delete(user.id!, user.uniqueId!);
    }
  }

  Future<void> sync() async {
    await _repo.syncPendingOperations();
    await loadUsers();
  }
}