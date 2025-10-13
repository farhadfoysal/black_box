import 'dart:async';
import 'package:black_box/mess/data/model/model_extensions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../model/mess/my_meals.dart';
import '../services/local/sqlite_mess_meal_service.dart';
import '../services/online/firebase_mess_meal_service.dart';
import '../services/sqlite_realtime_service.dart';

/// Repository for MyMeals model
/// Fully offline-first with real-time Firebase sync
class MyMealsRepository {
  final FirebaseMyMealsService _firebase = FirebaseMyMealsService();
  final SqliteMessMealService _sqlite = SqliteMessMealService();
  final SQLiteRealtimeService _realtime = SQLiteRealtimeService();

  /// -----------------------
  /// 🔹 CREATE
  /// -----------------------
  Future<void> insert(MyMeals meal) async {
    await _sqlite.create(meal.copyWithSyncStatus(MyMealsSync.pendingCreate));
    await _trySync();
  }

  /// -----------------------
  /// 🔹 UPDATE
  /// -----------------------
  Future<void> update(MyMeals meal) async {
    if (meal.id == null) return;
    await _sqlite.update(meal.uniqueId,meal.copyWithSyncStatus(MyMealsSync.pendingUpdate));
    await _trySync();
  }

  /// -----------------------
  /// 🔹 DELETE
  /// -----------------------
  Future<void> delete(MyMeals meal) async {
    await _sqlite.delete(meal.uniqueId!);
    await _trySync();
  }

  /// -----------------------
  /// 🔹 GET SINGLE ITEM
  /// -----------------------
  Future<MyMeals?> getById(String id) async {
    final online = await _isOnline();
    if (online) {
      final remote = await _firebase.get(id.toString());
      if (remote != null) await _sqlite.create(remote);
      return remote;
    }
    return await _sqlite.get(id.toString());
  }

  /// -----------------------
  /// 🔹 GET ALL ITEMS
  /// -----------------------
  Future<List<MyMeals>> getAll() async {
    final online = await _isOnline();
    if (!online) return await _sqlite.getAll();

    final remoteData = await _firebase.getAll();
    for (final item in remoteData) {
      await _sqlite.create(item);
    }
    return remoteData;
  }

  /// -----------------------
  /// 🔹 WATCH STREAM (REALTIME)
  /// -----------------------
  Stream<List<MyMeals>> watchAll() async* {
    final online = await _isOnline();
    if (!online) {
      yield* _sqlite.watchAll();
    } else {
      yield* _firebase.watchAll().asyncMap((data) async {
        for (final item in data) await _sqlite.create(item);
        return data;
      });
    }
  }

  /// -----------------------
  /// 🔹 FILTER / SEARCH
  /// -----------------------
  Future<List<MyMeals>> search(String query) async {
    final allData = await getAll();
    final lower = query.toLowerCase();
    return allData.where((m) =>
    (m.sumMeal?.toLowerCase().contains(lower) ?? false) ||
        (m.uniqueId?.toLowerCase().contains(lower) ?? false)
    ).toList();
  }

  /// -----------------------
  /// 🔹 SORTING
  /// -----------------------
  Future<List<MyMeals>> sortByName({bool ascending = true}) async {
    final allData = await getAll();
    allData.sort((a, b) => ascending
        ? (a.sumMeal ?? '').compareTo(b.sumMeal ?? '')
        : (b.sumMeal ?? '').compareTo(a.sumMeal ?? ''));
    return allData;
  }

  Future<List<MyMeals>> sortByDate({bool ascending = true}) async {
    final allData = await getAll();
    allData.sort((a, b) => ascending
        ? (a.date ?? '').compareTo(b.date ?? '')
        : (b.date ?? '').compareTo(a.date ?? ''));
    return allData;
  }

  /// -----------------------
  /// 🔹 PAGINATION
  /// -----------------------
  Future<List<MyMeals>> paginate({int limit = 10, int offset = 0}) async {
    final allData = await getAll();
    final end = (offset + limit > allData.length) ? allData.length : offset + limit;
    return allData.sublist(offset, end);
  }

  /// -----------------------
  /// 🔹 SYNC PENDING OPERATIONS
  /// -----------------------
  Future<void> syncPendingOperations() async {
    final online = await _isOnline();
    if (!online) return;

    final localData = await _sqlite.getAll();
    for (final item in localData) {
      switch (item.syncStatus) {
        case MyMealsSync.pendingCreate:
          await _firebase.create(item);
          break;
        case MyMealsSync.pendingUpdate:
          await _firebase.update(item.uniqueId,item);
          break;
        case MyMealsSync.pendingDelete:
          await _firebase.delete(item.uniqueId);
          await _sqlite.delete(item.uniqueId ?? '');
          continue;
      }
      await _sqlite.updateSyncStatus(item.uniqueId ?? '', MyMealsSync.synced);
    }
  }

  /// -----------------------
  /// 🔹 REFRESH FROM SERVER
  /// -----------------------
  Future<void> refreshFromServer() async {
    final online = await _isOnline();
    if (!online) return;

    final remoteData = await _firebase.getAll();
    for (final item in remoteData) await _sqlite.create(item);
  }

  /// -----------------------
  /// 🔹 HELPERS
  /// -----------------------
  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> _trySync() async {
    final online = await _isOnline();
    if (online) await syncPendingOperations();
  }
}
