import 'dart:async';
import 'package:black_box/mess/data/model/model_extensions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../model/mess/account_print.dart';
import '../services/local/sqlite_mess_print_service.dart';
import '../services/online/firebase_mess_print_service.dart';
import '../services/sqlite_realtime_service.dart';

/// Repository for AccountPrint model
/// Fully offline-first with real-time Firebase sync
class AccountPrintRepository {
  final FirebaseAccountPrintService _firebase = FirebaseAccountPrintService();
  final SQLiteAccountPrintService _sqlite = SQLiteAccountPrintService();
  final SQLiteRealtimeService _realtime = SQLiteRealtimeService();

  /// -----------------------
  /// 🔹 CREATE
  /// -----------------------
  Future<void> insert(AccountPrint ap) async {
    await _sqlite.create(ap.copyWithSyncStatus(AccountPrintSync.pendingCreate));
    await _trySync();
  }

  /// -----------------------
  /// 🔹 UPDATE
  /// -----------------------
  Future<void> update(AccountPrint ap) async {
    if (ap.id == null) return;
    await _sqlite.update(ap.id.toString(),ap.copyWithSyncStatus(AccountPrintSync.pendingUpdate));
    await _trySync();
  }

  /// -----------------------
  /// 🔹 DELETE
  /// -----------------------
  Future<void> delete(AccountPrint ap) async {
    await _sqlite.delete(ap.id!.toString());
    await _trySync();
  }

  /// -----------------------
  /// 🔹 GET SINGLE ITEM
  /// -----------------------
  Future<AccountPrint?> getById(int id) async {
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
  Future<List<AccountPrint>> getAll() async {
    final online = await _isOnline();
    if (!online) return await _sqlite.getAll();

    final remoteData = await _firebase.getAll();
    for (final item in remoteData) await _sqlite.create(item);
    return remoteData;
  }

  /// -----------------------
  /// 🔹 WATCH STREAM (REALTIME)
  /// -----------------------
  Stream<List<AccountPrint>> watchAll() async* {
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
  Future<List<AccountPrint>> search(String query) async {
    final allData = await getAll();
    final lower = query.toLowerCase();
    return allData.where((m) =>
    (m.phone?.toLowerCase().contains(lower) ?? false) ||
        (m.uniqueId?.toLowerCase().contains(lower) ?? false)
    ).toList();
  }

  /// -----------------------
  /// 🔹 SORTING
  /// -----------------------
  Future<List<AccountPrint>> sortByDescription({bool ascending = true}) async {
    final allData = await getAll();
    allData.sort((a, b) => ascending
        ? (a.phone ?? '').compareTo(b.phone ?? '')
        : (b.phone ?? '').compareTo(a.phone ?? ''));
    return allData;
  }

  // Future<List<AccountPrint>> sortByDate({bool ascending = true}) async {
  //   final allData = await getAll();
  //   allData.sort((a, b) => ascending
  //       ? (a.date ?? '').compareTo(b.date ?? '')
  //       : (b.date ?? '').compareTo(a.date ?? ''));
  //   return allData;
  // }

  /// -----------------------
  /// 🔹 PAGINATION
  /// -----------------------
  Future<List<AccountPrint>> paginate({int limit = 10, int offset = 0}) async {
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
        case AccountPrintSync.pendingCreate:
          await _firebase.create(item);
          break;
        case AccountPrintSync.pendingUpdate:
          await _firebase.update(item.id.toString(),item);
          break;
        case AccountPrintSync.pendingDelete:
          await _firebase.delete(item.id.toString());
          await _sqlite.deleteByUniqueId(item.uniqueId ?? '');
          continue;
      }
      await _sqlite.updateSyncStatus(item.uniqueId ?? '', AccountPrintSync.synced);
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
