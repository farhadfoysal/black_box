import 'dart:async';
import 'package:black_box/mess/data/model/model_extensions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../model/mess/bazar_list.dart';
import '../services/local/sqlite_mess_bazar_service.dart';
import '../services/online/firebase_mess_bazar_service.dart';
import '../services/sqlite_realtime_service.dart';

/// Repository to manage Bazar List
/// Fully offline-first with real-time Firebase sync
class BazarListRepository {
  final FirebaseBazarListService _firebase = FirebaseBazarListService();
  final SQLiteBazarListService _sqlite = SQLiteBazarListService();
  final SQLiteRealtimeService _realtime = SQLiteRealtimeService();

  /// -----------------------
  /// 🔹 CREATE
  /// -----------------------
  Future<void> insert(BazarList item) async {
    await _sqlite.create(item.copyWithSyncStatus(BazarListSync.pendingCreate));
    await _trySync();
  }

  /// -----------------------
  /// 🔹 UPDATE
  /// -----------------------
  Future<void> update(BazarList item) async {
    if (item.id == null) return;
    await _sqlite.update(item.listId,item.copyWithSyncStatus(BazarListSync.pendingUpdate));
    await _trySync();
  }

  /// -----------------------
  /// 🔹 DELETE
  /// -----------------------
  Future<void> delete(BazarList item) async {
    await _sqlite.delete(item.listId!);
    await _trySync();
  }

  /// -----------------------
  /// 🔹 GET SINGLE ITEM
  /// -----------------------
  Future<BazarList?> getById(String listId) async {
    final online = await _isOnline();
    if (online) {
      final remote = await _firebase.get(listId);
      if (remote != null) await _sqlite.create(remote);
      return remote;
    }
    return await _sqlite.get(listId);
  }

  /// -----------------------
  /// 🔹 GET ALL ITEMS
  /// -----------------------
  Future<List<BazarList>> getAll() async {
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
  Stream<List<BazarList>> watchAll() async* {
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
  Future<List<BazarList>> search(String query) async {
    final allData = await getAll();
    final lower = query.toLowerCase();
    return allData.where((b) =>
    (b.listDetails?.toLowerCase().contains(lower) ?? false) ||
        (b.listId?.toLowerCase().contains(lower) ?? false)
    ).toList();
  }

  /// -----------------------
  /// 🔹 SORTING
  /// -----------------------
  Future<List<BazarList>> sortByName({bool ascending = true}) async {
    final allData = await getAll();
    allData.sort((a, b) => ascending
        ? (a.listDetails ?? '').compareTo(b.listDetails ?? '')
        : (b.listDetails ?? '').compareTo(a.listDetails ?? ''));
    return allData;
  }

  Future<List<BazarList>> sortByDate({bool ascending = true}) async {
    final allData = await getAll();
    allData.sort((a, b) => ascending
        ? (a.dateTime ?? '').compareTo(b.dateTime ?? '')
        : (b.dateTime ?? '').compareTo(a.dateTime ?? ''));
    return allData;
  }

  /// -----------------------
  /// 🔹 PAGINATION
  /// -----------------------
  Future<List<BazarList>> paginate({int limit = 10, int offset = 0}) async {
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
        case BazarListSync.pendingCreate:
          await _firebase.create(item);
          break;
        case BazarListSync.pendingUpdate:
          await _firebase.update(item.listId,item);
          break;
        case BazarListSync.pendingDelete:
          await _firebase.delete(item.listId);
          await _sqlite.delete(item.listId ?? '');
          continue;
      }
      await _sqlite.updateSyncStatus(item.uniqueId ?? '', BazarListSync.synced);
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
