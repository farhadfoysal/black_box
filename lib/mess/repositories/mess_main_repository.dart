import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../model/mess/mess_main.dart';
import '../services/local/sqlite_mess_main_service.dart';
import '../services/online/firebase_mess_main_service.dart';
import '../services/sqlite_realtime_service.dart';


/// Repository for MessMain model
/// Handles both online (Firebase) and offline (SQLite) data sources
/// with full synchronization and watcher support.
class MessMainRepository {
  final FirebaseMessMainService _firebase = FirebaseMessMainService();
  final SQLiteMessMainService _sqlite = SQLiteMessMainService();
  final SQLiteRealtimeService _realtime = SQLiteRealtimeService();

  /// -----------------------
  /// 🔹 CREATE / INSERT
  /// -----------------------
  Future<void> insert(MessMain mess) async {
    await _sqlite.create(mess);
    await _trySync();
  }

  /// -----------------------
  /// 🔹 UPDATE
  /// -----------------------
  Future<void> update(MessMain mess) async {
    if (mess.messId == null) return;
    await _sqlite.update(mess.messId!, mess);
    await _trySync();
  }

  /// -----------------------
  /// 🔹 DELETE
  /// -----------------------
  Future<void> delete(String id, String messId) async {
    await _sqlite.delete(messId);
    await _trySync();
  }

  /// -----------------------
  /// 🔹 GET SINGLE ITEM
  /// -----------------------
  Future<MessMain?> get(String messId) async {
    final isOnline = await _isOnline();
    if (isOnline) {
      final remote = await _firebase.get(messId);
      if (remote != null) await _sqlite.create(remote);
      return remote;
    }
    return await _sqlite.get(messId);
  }

  /// -----------------------
  /// 🔹 GET ALL ITEMS
  /// -----------------------
  Future<List<MessMain>> getAll() async {
    final isOnline = await _isOnline();
    if (!isOnline) return await _sqlite.getAll();

    final remoteData = await _firebase.getAll();
    for (final mess in remoteData) {
      await _sqlite.create(mess);
    }
    return remoteData;
  }

  /// -----------------------
  /// 🔹 WATCH (REALTIME STREAM)
  /// -----------------------
  Stream<List<MessMain>> watchAll() async* {
    final isOnline = await _isOnline();
    if (!isOnline) {
      yield* _sqlite.watchAll();
    } else {
      yield* _firebase.watchAll().asyncMap((data) async {
        for (final item in data) {
          await _sqlite.create(item);
        }
        return data;
      });
    }
  }

  /// -----------------------
  /// 🔹 WATCH BY MESS ID
  /// -----------------------
  Stream<List<MessMain>> watchByMess(String messId) async* {
    final isOnline = await _isOnline();
    if (!isOnline) {
      yield* _sqlite.watchByMess(messId);
    } else {
      yield* _firebase.watchByMess(messId).asyncMap((data) async {
        for (final item in data) {
          await _sqlite.create(item);
        }
        return data;
      });
    }
  }

  /// -----------------------
  /// 🔹 WATCH BY USER ID
  /// -----------------------
  Stream<List<MessMain>> watchByUser(String userId) async* {
    final isOnline = await _isOnline();
    if (!isOnline) {
      yield* _sqlite.watchByUser(userId);
    } else {
      yield* _firebase.watchByUser(userId).asyncMap((data) async {
        for (final item in data) {
          await _sqlite.create(item);
        }
        return data;
      });
    }
  }

  /// -----------------------
  /// 🔹 FILTER / SEARCH
  /// -----------------------
  Future<List<MessMain>> search(String query) async {
    final allData = await getAll();
    return allData
        .where((m) =>
    (m.messName ?? '').toLowerCase().contains(query.toLowerCase()) ||
        (m.messId ?? '').contains(query))
        .toList();
  }

  /// -----------------------
  /// 🔹 SORTING
  /// -----------------------
  Future<List<MessMain>> sortByName({bool ascending = true}) async {
    final allData = await getAll();
    allData.sort((a, b) => ascending
        ? (a.messName ?? '').compareTo(b.messName ?? '')
        : (b.messName ?? '').compareTo(a.messName ?? ''));
    return allData;
  }

  Future<List<MessMain>> sortByDate({bool ascending = true}) async {
    final allData = await getAll();
    allData.sort((a, b) => ascending
        ? (a.startDate ?? '').compareTo(b.startDate ?? '')
        : (b.startDate ?? '').compareTo(a.startDate ?? ''));
    return allData;
  }

  /// -----------------------
  /// 🔹 PAGINATION
  /// -----------------------
  Future<List<MessMain>> paginate({int limit = 10, int offset = 0}) async {
    final allData = await getAll();
    final end = (offset + limit > allData.length)
        ? allData.length
        : offset + limit;
    return allData.sublist(offset, end);
  }

  /// -----------------------
  /// 🔹 SYNC OPERATIONS
  /// -----------------------
  Future<void> syncPendingOperations() async {
    final isOnline = await _isOnline();
    if (!isOnline) return;

    final localData = await _sqlite.getAll();
    for (final item in localData) {
      switch (item.syncStatus) {
        case 'pendingCreate':
          await _firebase.create(item);
          break;
        case 'pendingUpdate':
          await _firebase.update(item.messId!, item);
          break;
        case 'pendingDelete':
          await _firebase.delete(item.messId!);
          break;
      }
    }
  }

  /// -----------------------
  /// 🔹 REFRESH FROM REMOTE
  /// -----------------------
  Future<void> refreshFromServer() async {
    final isOnline = await _isOnline();
    if (!isOnline) return;

    final remoteData = await _firebase.getAll();
    for (final mess in remoteData) {
      await _sqlite.create(mess);
    }
  }

  /// -----------------------
  /// 🔹 HELPERS
  /// -----------------------
  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> _trySync() async {
    final isOnline = await _isOnline();
    if (isOnline) {
      await syncPendingOperations();
    }
  }
}



// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import '../../model/mess/mess_main.dart';
// import '../services/local/sqlite_mess_main_service.dart';
// import '../services/online/firebase_mess_main_service.dart';
// import '../services/sqlite_realtime_service.dart';
//
// class MessMainRepository {
//   final FirebaseMessMainService _firebase = FirebaseMessMainService();
//   final SQLiteMessMainService _sqlite = SQLiteMessMainService();
//   final SQLiteRealtimeService _realtime = SQLiteRealtimeService();
//
//   /// Get all mess data with offline-first sync logic
//   Future<List<MessMain>> getAll() async {
//     final connectivity = await Connectivity().checkConnectivity();
//     if (connectivity == ConnectivityResult.none) {
//       // Offline → Return from SQLite
//       return await _sqlite.getAll();
//     } else {
//       // Online → Fetch from Firebase, then cache locally
//       final remoteData = await _firebase.getAll();
//       for (final mess in remoteData) {
//         await _sqlite.create(mess);
//       }
//       return remoteData;
//     }
//   }
//
//   /// Stream watcher for real-time updates
//   Stream<List<MessMain>> watchAll() async* {
//     final connectivity = await Connectivity().checkConnectivity();
//
//     if (connectivity == ConnectivityResult.none) {
//       // Offline mode
//       yield* _sqlite.watchAll();
//     } else {
//       // Online mode → listen Firebase + update local
//       yield* _firebase.watchAll().asyncMap((remoteData) async {
//         for (final mess in remoteData) {
//           await _sqlite.create(mess);
//         }
//         return remoteData;
//       });
//     }
//   }
//
//   /// Get single mess data
//   Future<MessMain?> get(String id) async {
//     final connectivity = await Connectivity().checkConnectivity();
//     if (connectivity == ConnectivityResult.none) {
//       return await _sqlite.get(id);
//     } else {
//       final mess = await _firebase.get(id);
//       if (mess != null) await _sqlite.create(mess);
//       return mess;
//     }
//   }
//
//   /// Sync local pending changes → Firebase
//   Future<void> syncPending() async {
//     final connectivity = await Connectivity().checkConnectivity();
//     if (connectivity == ConnectivityResult.none) return;
//
//     final db = await _sqlite.getAll();
//     for (final m in db) {
//       if (m.syncStatus == 'pendingCreate') {
//         await _firebase.create(m);
//       } else if (m.syncStatus == 'pendingUpdate') {
//         await _firebase.update(m.messId!, m);
//       } else if (m.syncStatus == 'pendingDelete') {
//         await _firebase.delete(m.messId!);
//       }
//     }
//   }
// }
