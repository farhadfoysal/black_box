import 'package:black_box/mess/data/db/database_config.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import '../../../model/mess/bazar_list.dart';
import '../../data/db/database_interfaces.dart';
import '../../data/model/model_extensions.dart';

class SQLiteBazarListService implements BaseDatabaseService<BazarList> {
  final DatabaseConfig _dbHelper = DatabaseConfig.instance;
  final _lock = Lock();

  @override
  Future<String> create(BazarList item) async {
    return await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.insert(
        'bazar_list',
        item.toMap()..['sync_status'] = MessUserSync.pendingCreate,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return item.listId;
    });
  }

  @override
  Future<void> update(String id, BazarList item) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'bazar_list',
        item.toMap()..['sync_status'] = MessUserSync.pendingUpdate,
        where: 'list_id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'bazar_list',
        {'sync_status': MessUserSync.pendingDelete},
        where: 'list_id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<BazarList?> get(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bazar_list',
      where: 'list_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return BazarList.fromMap(maps.first);
    return null;
  }

  @override
  Future<List<BazarList>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('bazar_list');
    return List.generate(maps.length, (i) => BazarList.fromMap(maps[i]));
  }

  @override
  Stream<BazarList?> watch(String id) =>
      Stream.periodic(Duration(seconds: 2)).asyncMap((_) => get(id));

  @override
  Stream<List<BazarList>> watchAll() =>
      Stream.periodic(Duration(seconds: 2)).asyncMap((_) => getAll());

  @override
  Future<void> pushPendingOperations() async {
    final db = await _dbHelper.database;

    // Get all pending operations
    final pending = await db.query('bazar_list',
        where: 'sync_status != ?',
        whereArgs: [MessMainSync.synced]);

    // This would be handled by the repositories
    return Future.value();
  }

  @override
  Future<void> pullLatestData() async {
    // Logic for pulling data from remote source
    return Future.value();
  }

  @override
  Stream<List<BazarList>> watchByMess(String messId) {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'bazar_list',
        where: 'mess_id = ?',
        whereArgs: [messId],
      );
      return List.generate(maps.length, (i) => BazarList.fromMap(maps[i]));
    });
  }

  @override
  Stream<List<BazarList>> watchByUser(String uniqueId) {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'bazar_list',
        where: 'unique_id = ?',
        whereArgs: [uniqueId],
      );
      return List.generate(maps.length, (i) => BazarList.fromMap(maps[i]));
    });
  }

  /// -----------------------
  /// ✅ UPDATE SYNC STATUS
  /// -----------------------
  Future<void> updateSyncStatus(String uniqueId, String newStatus) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'bazar_list',
        {'sync_status': newStatus},
        where: 'unique_id = ?',
        whereArgs: [uniqueId],
      );
    });
  }

}
