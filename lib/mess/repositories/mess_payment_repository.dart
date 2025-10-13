import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../model/mess/payment.dart';
import '../services/local/sqlite_mess_payment_service.dart';
import '../services/online/firebase_mess_payment_service.dart';
import '../services/sqlite_realtime_service.dart';

/// Repository to handle all Payment operations
/// Offline-first with Firebase sync
class PaymentRepository {
  final FirebasePaymentService _firebase = FirebasePaymentService();
  final SQLitePaymentService _sqlite = SQLitePaymentService();
  final SQLiteRealtimeService _realtime = SQLiteRealtimeService();

  /// -----------------------
  /// 🔹 CREATE PAYMENT
  /// -----------------------
  Future<void> insert(Payment payment) async {
    await _sqlite.create(payment);
    await _trySync();
  }

  /// -----------------------
  /// 🔹 UPDATE PAYMENT
  /// -----------------------
  Future<void> update(Payment payment) async {
    if (payment.uniqueId == null) return;
    await _sqlite.update(payment.uniqueId!, payment);
    await _trySync();
  }

  /// -----------------------
  /// 🔹 DELETE PAYMENT
  /// -----------------------
  Future<void> delete(String paymentId) async {
    await _sqlite.delete(paymentId);
    await _trySync();
  }

  /// -----------------------
  /// 🔹 GET SINGLE PAYMENT
  /// -----------------------
  Future<Payment?> get(String paymentId) async {
    final online = await _isOnline();
    if (online) {
      final remote = await _firebase.get(paymentId);
      if (remote != null) await _sqlite.create(remote);
      return remote;
    }
    return await _sqlite.get(paymentId);
  }

  /// -----------------------
  /// 🔹 GET ALL PAYMENTS
  /// -----------------------
  Future<List<Payment>> getAll() async {
    final online = await _isOnline();
    if (!online) return await _sqlite.getAll();

    final remoteData = await _firebase.getAll();
    for (final p in remoteData) await _sqlite.create(p);
    return remoteData;
  }

  /// -----------------------
  /// 🔹 WATCH REAL-TIME STREAM
  /// -----------------------
  Stream<List<Payment>> watchAll() async* {
    final online = await _isOnline();
    if (!online) {
      yield* _sqlite.watchAll();
    } else {
      yield* _firebase.watchAll().asyncMap((data) async {
        for (final p in data) await _sqlite.create(p);
        return data;
      });
    }
  }

  /// -----------------------
  /// 🔹 WATCH BY USER
  /// -----------------------
  Stream<List<Payment>> watchByUser(String userId) async* {
    final online = await _isOnline();
    if (!online) {
      yield* _sqlite.watchByUser(userId);
    } else {
      yield* _firebase.watchByUser(userId).asyncMap((data) async {
        for (final p in data) await _sqlite.create(p);
        return data;
      });
    }
  }

  /// -----------------------
  /// 🔹 FILTER / SEARCH
  /// -----------------------
  Future<List<Payment>> search(String query) async {
    final allData = await getAll();
    final lower = query.toLowerCase();
    return allData.where((p) =>
    (p.uniqueId?.toLowerCase().contains(lower) ?? false) ||
        (p.phone?.toLowerCase().contains(lower) ?? false) ||
        (p.amount.toString().contains(query))
    ).toList();
  }

  /// -----------------------
  /// 🔹 SORTING
  /// -----------------------
  Future<List<Payment>> sortByAmount({bool ascending = true}) async {
    final allData = await getAll();
    allData.sort((a, b) => ascending
        ? a.amount.compareTo(b.amount)
        : b.amount.compareTo(a.amount));
    return allData;
  }

  Future<List<Payment>> sortByDate({bool ascending = true}) async {
    final allData = await getAll();
    allData.sort((a, b) => ascending
        ? (a.dateM ?? '').compareTo(b.dateM ?? '')
        : (b.dateM ?? '').compareTo(a.dateM ?? ''));
    return allData;
  }

  /// -----------------------
  /// 🔹 PAGINATION
  /// -----------------------
  Future<List<Payment>> paginate({int limit = 10, int offset = 0}) async {
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
    for (final p in localData) {
      switch (p.syncStatus) {
        case 'pendingCreate':
          await _firebase.create(p);
          break;
        case 'pendingUpdate':
          await _firebase.update(p.uniqueId!, p);
          break;
        case 'pendingDelete':
          await _firebase.delete(p.uniqueId!);
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
    for (final p in remoteData) await _sqlite.create(p);
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
