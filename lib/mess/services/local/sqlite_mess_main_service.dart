import 'package:black_box/mess/data/db/database_config.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import '../../../model/mess/mess_main.dart';
import '../../data/db/database_interfaces.dart';
import '../../data/model/model_extensions.dart';

class SQLiteMessMainService implements BaseDatabaseService<MessMain> {
  final DatabaseConfig _dbHelper = DatabaseConfig.instance;
  final _lock = Lock();

  @override
  Future<String> create(MessMain mess) async {
    return await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.insert(
        'mess_main',
        mess.toMap()..['sync_status'] = MessMainSync.pendingCreate,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return mess.messId!;
    });
  }

  @override
  Future<void> update(String id, MessMain mess) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'mess_main',
        mess.toMap()..['sync_status'] = MessMainSync.pendingUpdate,
        where: 'mess_id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      // Mark as pending delete instead of actually deleting
      await db.update(
        'mess_main',
        {'sync_status': MessMainSync.pendingDelete},
        where: 'mess_id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<MessMain?> get(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mess_main',
      where: 'mess_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return MessMain.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<MessMain>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('mess_main');
    return List.generate(maps.length, (i) => MessMain.fromMap(maps[i]));
  }

  @override
  Stream<MessMain?> watch(String id) {
    // SQLite doesn't support native streams, so we use periodic polling
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) => get(id));
  }

  @override
  Stream<List<MessMain>> watchAll() {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) => getAll());
  }

  @override
  Stream<List<MessMain>> watchByMess(String messId) {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'mess_main',
        where: 'mess_id = ?',
        whereArgs: [messId],
      );
      return List.generate(maps.length, (i) => MessMain.fromMap(maps[i]));
    });
  }

  @override
  Future<void> pushPendingOperations() async {
    final db = await _dbHelper.database;

    // Get all pending operations
    final pending = await db.query('mess_main',
        where: 'sync_status != ?',
        whereArgs: [MessMainSync.synced]);

    // This would be handled by the repository
    return Future.value();
  }

  @override
  Future<void> pullLatestData() async {
    // This would be handled by the repository
    return Future.value();
  }

  @override
  Stream<List<MessMain>> watchByUser(String uniqueId) {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'mess_main',
        where: 'unique_id = ?',
        whereArgs: [uniqueId],
      );
      return List.generate(maps.length, (i) => MessMain.fromMap(maps[i]));
    });
  }
}