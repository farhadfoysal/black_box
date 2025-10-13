import 'package:black_box/mess/data/db/database_config.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import '../../../model/mess/payment.dart';
import '../../data/db/database_interfaces.dart';
import '../../data/model/model_extensions.dart';

class SQLitePaymentService implements BaseDatabaseService<Payment> {
  final DatabaseConfig _dbHelper = DatabaseConfig.instance;
  final _lock = Lock();

  @override
  Future<String> create(Payment item) async {
    return await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.insert(
        'payment',
        item.toMap()..['sync_status'] = MessUserSync.pendingCreate,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return item.uniqueId;
    });
  }

  @override
  Future<void> update(String id, Payment item) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'payment',
        item.toMap()..['sync_status'] = MessUserSync.pendingUpdate,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'payment',
        {'sync_status': MessUserSync.pendingDelete},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<Payment?> get(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Payment.fromMap(maps.first);
    return null;
  }

  @override
  Future<List<Payment>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('payment');
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  @override
  Stream<Payment?> watch(String id) =>
      Stream.periodic(Duration(seconds: 2)).asyncMap((_) => get(id));

  @override
  Stream<List<Payment>> watchAll() =>
      Stream.periodic(Duration(seconds: 2)).asyncMap((_) => getAll());

  @override
  Future<void> pushPendingOperations() async {
    final db = await _dbHelper.database;

    // Get all pending operations
    final pending = await db.query('payment',
        where: 'sync_status != ?',
        whereArgs: [MessMainSync.synced]);

    // This would be handled by the repositories
    return Future.value();
  }

  @override
  Future<void> pullLatestData() async {
    return Future.value();
  }

  @override
  Stream<List<Payment>> watchByMess(String messId) {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'payment',
        where: 'mess_id = ?',
        whereArgs: [messId],
      );
      return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
    });
  }

  Stream<List<Payment>> watchByUser(String uniqueId) {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'payment',
        where: 'unique_id = ?',
        whereArgs: [uniqueId],
      );
      return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
    });
  }
  /// -----------------------
  /// ✅ UPDATE SYNC STATUS
  /// -----------------------
  Future<void> updateSyncStatus(String uniqueId, String newStatus) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'payment',
        {'sync_status': newStatus},
        where: 'unique_id = ?',
        whereArgs: [uniqueId],
      );
    });
  }
}
