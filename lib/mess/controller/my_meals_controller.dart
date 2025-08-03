import 'package:get/get.dart';

import '../../model/mess/my_meals.dart';
import '../data/providers/mess_repository_provider.dart';
import '../data/repository/mess_meal_repository.dart';
import '../services/sync_service.dart';

class MyMealsController extends GetxController {
  late final MyMealsRepository _repo;
  final SyncService _syncService = SyncService();

  final RxList<MyMeals> meals = RxList<MyMeals>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initRepository();
  }

  Future<void> _initRepository() async {
    _repo = await MessRepositoryProvider.instance.myMealsRepository;

    await loadMealsFromLocal();

    _repo.watchAll().listen((list) {
      meals.assignAll(list);
    });
  }

  Future<void> loadMealsFromLocal() async {
    isLoading.value = true;
    final list = await _repo.getAll();
    meals.assignAll(list);
    isLoading.value = false;
  }

  Future<void> addMeal(MyMeals item) async {
    await _repo.insert(item);
  }

  Future<void> updateMeal(MyMeals item) async {
    await _repo.update(item);
  }

  Future<void> deleteMeal(MyMeals item) async {
    if (item.id == null || item.uniqueId == null) return;
    await _repo.delete(item.id!, item.uniqueId!);
  }

  Future<void> syncPendingOperations() async {
    await _syncService.syncPendingOperations();
    await loadMealsFromLocal();
  }
}
