import 'dart:async';
import 'package:black_box/mess/data/model/model_extensions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../model/mess/others_fee.dart';
import '../services/local/sqlite_mess_other_service.dart';
import '../services/online/firebase_mess_other_service.dart';
import '../services/sqlite_realtime_service.dart';

/// Repository for OthersFee model
/// Fully offline-first with real-time Firebase sync
class OthersFeeRepository {
  final FirebaseOthersFeeService _firebase = FirebaseOthersFeeService();
  final SQLiteOthersFeeService _sqlite = SQLiteOthersFeeService();
  final SQLiteRealtimeService _realtime = SQLiteRealtimeService();

  /// -----------------------
  /// 🔹 CREATE
  /// -----------------------
  Future<void> insert(OthersFee fee) async {
    await _sqlite.create(fee.copyWithSyncStatus(OthersFeeSync.pendingCreate));
    await _trySync();
  }

  /// -----------------------
  /// 🔹 UPDATE
  /// -----------------------
  Future<void> update(OthersFee fee) async {
    if (fee.id == null) return;
    await _sqlite.update(fee.id.toString(),fee.copyWithSyncStatus(OthersFeeSync.pendingUpdate));
    await _trySync();
  }

  /// -----------------------
  /// 🔹 DELETE
  /// -----------------------
  Future<void> delete(OthersFee fee) async {
    await _sqlite.delete(fee.id!.toString());
    await _trySync();
  }

  /// -----------------------
  /// 🔹 GET SINGLE ITEM
  /// -----------------------
  Future<OthersFee?> getById(int id) async {
    final online = await _isOnline();
    if (online) {
      final remote = await _firebase.getById(id.toString());
      if (remote != null) await _sqlite.create(remote);
      return remote;
    }
    return await _sqlite.getById(id.toString());
  }

  /// -----------------------
  /// 🔹 GET ALL ITEMS
  /// -----------------------
  Future<List<OthersFee>> getAll() async {
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
  Stream<List<OthersFee>> watchAll() async* {
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
  Future<List<OthersFee>> search(String query) async {
    final allData = await getAll();
    final lower = query.toLowerCase();
    return allData.where((m) =>
    (m.feeType?.toLowerCase().contains(lower) ?? false) ||
        (m.uniqueId?.toLowerCase().contains(lower) ?? false)
    ).toList();
  }

  /// -----------------------
  /// 🔹 SORTING
  /// -----------------------
  Future<List<OthersFee>> sortByName({bool ascending = true}) async {
    final allData = await getAll();
    allData.sort((a, b) => ascending
        ? (a.feeType ?? '').compareTo(b.feeType ?? '')
        : (b.feeType ?? '').compareTo(a.feeType ?? ''));
    return allData;
  }

  Future<List<OthersFee>> sortByDate({bool ascending = true}) async {
    final allData = await getAll();
    allData.sort((a, b) => ascending
        ? (a.date ?? '').compareTo(b.date ?? '')
        : (b.date ?? '').compareTo(a.date ?? ''));
    return allData;
  }

  /// -----------------------
  /// 🔹 PAGINATION
  /// -----------------------
  Future<List<OthersFee>> paginate({int limit = 10, int offset = 0}) async {
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
        case OthersFeeSync.pendingCreate:
          await _firebase.create(item);
          break;
        case OthersFeeSync.pendingUpdate:
          await _firebase.update(item.id.toString(),item);
          break;
        case OthersFeeSync.pendingDelete:
          await _firebase.delete(item.uniqueId.toString());
          await _sqlite.delete(item.id.toString());
          continue;
      }
      await _sqlite.updateSyncStatus(item.uniqueId ?? '', OthersFeeSync.synced);
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
