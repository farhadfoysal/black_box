import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../model/mess/mess_user.dart';
import '../services/local/sqlite_mess_user_service.dart';
import '../services/online/firebase_mess_user_service.dart';
import '../services/sqlite_realtime_service.dart';

/// Repository to handle all MessUser operations
/// Offline-first with Firebase sync
class MessUserRepository {
  final FirebaseMessUserService _firebase = FirebaseMessUserService();
  final SQLiteMessUserService _sqlite = SQLiteMessUserService();
  final SQLiteRealtimeService _realtime = SQLiteRealtimeService();

  /// -----------------------
  /// 🔹 CREATE USER
  /// -----------------------
  Future<void> insert(MessUser user) async {
    await _sqlite.create(user);
    await _trySync();
  }

  /// -----------------------
  /// 🔹 UPDATE USER
  /// -----------------------
  Future<void> update(MessUser user) async {
    if (user.userId == null) return;
    await _sqlite.update(user.userId!, user);
    await _trySync();
  }

  /// -----------------------
  /// 🔹 DELETE USER
  /// -----------------------
  Future<void> delete(String userId) async {
    await _sqlite.delete(userId);
    await _trySync();
  }

  /// -----------------------
  /// 🔹 GET SINGLE USER
  /// -----------------------
  Future<MessUser?> get(String userId) async {
    final online = await _isOnline();
    if (online) {
      final remote = await _firebase.get(userId);
      if (remote != null) await _sqlite.create(remote);
      return remote;
    }
    return await _sqlite.get(userId);
  }

  /// -----------------------
  /// 🔹 GET ALL USERS
  /// -----------------------
  Future<List<MessUser>> getAll() async {
    final online = await _isOnline();
    if (!online) return await _sqlite.getAll();

    final remoteData = await _firebase.getAll();
    for (final u in remoteData) {
      await _sqlite.create(u);
    }
    return remoteData;
  }

  /// -----------------------
  /// 🔹 WATCH (REAL-TIME STREAM)
  /// -----------------------
  Stream<List<MessUser>> watchAll() async* {
    final online = await _isOnline();
    if (!online) {
      yield* _sqlite.watchAll();
    } else {
      yield* _firebase.watchAll().asyncMap((data) async {
        for (final u in data) await _sqlite.create(u);
        return data;
      });
    }
  }

  /// -----------------------
  /// 🔹 WATCH BY MESS
  /// -----------------------
  Stream<List<MessUser>> watchByMess(String messId) async* {
    final online = await _isOnline();
    if (!online) {
      yield* _sqlite.watchByMess(messId);
    } else {
      yield* _firebase.watchByMess(messId).asyncMap((data) async {
        for (final u in data) await _sqlite.create(u);
        return data;
      });
    }
  }

  /// -----------------------
  /// 🔹 SEARCH / FILTER
  /// -----------------------
  Future<List<MessUser>> search(String query) async {
    final allData = await getAll();
    final lower = query.toLowerCase();
    return allData.where((u) =>
    (u.phone?.toLowerCase().contains(lower) ?? false) ||
        (u.userId?.toLowerCase().contains(lower) ?? false) ||
        (u.phone?.contains(query) ?? false)
    ).toList();
  }

  /// -----------------------
  /// 🔹 SORTING
  /// -----------------------
  Future<List<MessUser>> sortByName({bool ascending = true}) async {
    final allData = await getAll();
    allData.sort((a, b) => ascending
        ? (a.email ?? '').compareTo(b.email ?? '')
        : (b.email ?? '').compareTo(a.email ?? ''));
    return allData;
  }

  // Future<List<MessUser>> sortByBalance({bool ascending = true}) async {
  //   final allData = await getAll();
  //   allData.sort((a, b) => ascending
  //       ? a.balance.compareTo(b.balance)
  //       : b.balance.compareTo(a.balance));
  //   return allData;
  // }

  /// -----------------------
  /// 🔹 PAGINATION
  /// -----------------------
  Future<List<MessUser>> paginate({int limit = 10, int offset = 0}) async {
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
    for (final u in localData) {
      switch (u.syncStatus) {
        case 'pendingCreate':
          await _firebase.create(u);
          break;
        case 'pendingUpdate':
          await _firebase.update(u.userId!, u);
          break;
        case 'pendingDelete':
          await _firebase.delete(u.userId!);
          break;
      }
    }
  }

  /// -----------------------
  /// 🔹 REFRESH FROM SERVER
  /// -----------------------
  Future<void> refreshFromServer() async {
    final online = await _isOnline();
    if (!online) return;

    final remoteData = await _firebase.getAll();
    for (final u in remoteData) await _sqlite.create(u);
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
