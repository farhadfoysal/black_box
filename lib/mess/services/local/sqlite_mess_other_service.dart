import 'package:black_box/mess/data/db/database_config.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import '../../../model/mess/others_fee.dart';
import '../../data/db/database_interfaces.dart';
import '../../data/model/model_extensions.dart';

class SQLiteOthersFeeService implements BaseDatabaseService<OthersFee> {
  final DatabaseConfig _dbHelper = DatabaseConfig.instance;
  final _lock = Lock();

  @override
  Future<String> create(OthersFee item) async {
    return await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.insert(
        'others_fee',
        item.toMap()..['sync_status'] = MessUserSync.pendingCreate,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return item.uniqueId;
    });
  }

  @override
  Future<void> update(String id, OthersFee item) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'others_fee',
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
        'others_fee',
        {'sync_status': MessUserSync.pendingDelete},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<OthersFee?> get(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'others_fee',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return OthersFee.fromMap(maps.first);
    return null;
  }

  Future<OthersFee?> getById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'others_fee',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return OthersFee.fromMap(maps.first);
    return null;
  }

  @override
  Future<List<OthersFee>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('others_fee');
    return List.generate(maps.length, (i) => OthersFee.fromMap(maps[i]));
  }

  @override
  Stream<OthersFee?> watch(String id) =>
      Stream.periodic(Duration(seconds: 2)).asyncMap((_) => get(id));

  @override
  Stream<List<OthersFee>> watchAll() =>
      Stream.periodic(Duration(seconds: 2)).asyncMap((_) => getAll());

  @override
  Future<void> pushPendingOperations() async {
    final db = await _dbHelper.database;

    // Get all pending operations
    final pending = await db.query('others_fee',
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
  Stream<List<OthersFee>> watchByMess(String messId) {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'others_fee',
        where: 'mess_id = ?',
        whereArgs: [messId],
      );
      return List.generate(maps.length, (i) => OthersFee.fromMap(maps[i]));
    });
  }

  Stream<List<OthersFee>> watchByUser(String uniqueId) {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'others_fee',
        where: 'unique_id = ?',
        whereArgs: [uniqueId],
      );
      return List.generate(maps.length, (i) => OthersFee.fromMap(maps[i]));
    });
  }

  /// -----------------------
  /// ✅ UPDATE SYNC STATUS
  /// -----------------------
  Future<void> updateSyncStatus(String uniqueId, String newStatus) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'others_fee',
        {'sync_status': newStatus},
        where: 'unique_id = ?',
        whereArgs: [uniqueId],
      );
    });
  }

}
