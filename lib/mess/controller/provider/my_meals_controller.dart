import 'package:flutter/material.dart';

import '../../../model/mess/my_meals.dart';
import '../../data/providers/mess_repository_provider.dart';
import '../../data/repository/mess_meal_repository.dart';

class MyMealsController extends ChangeNotifier {
  final List<MyMeals> _meals = [];
  List<MyMeals> get meals => _meals;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late final MyMealsRepository _repo;

  MyMealsController() {
    _init();
  }

  Future<void> _init() async {
    _repo = await MessRepositoryProvider.instance.myMealsRepository;
    await loadItems();
    _repo.watchAll().listen((data) {
      _meals..clear()..addAll(data);
      notifyListeners();
    });
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    final local = await _repo.getAll();
    _meals..clear()..addAll(local);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> add(MyMeals item) async => await _repo.insert(item);
  Future<void> update(MyMeals item) async => await _repo.update(item);
  Future<void> delete(MyMeals item) async {
    if (item.id != null && item.uniqueId != null) {
      await _repo.delete(item.id!, item.uniqueId!);
    }
  }

  Future<void> sync() async {
    await _repo.syncPendingOperations();
    await loadItems();
  }
}
