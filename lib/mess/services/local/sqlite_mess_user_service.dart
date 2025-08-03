import 'package:black_box/mess/data/db/database_config.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import '../../../model/mess/mess_user.dart';
import '../../data/db/database_interfaces.dart';
import '../../data/model/model_extensions.dart';

class SQLiteMessUserService implements BaseDatabaseService<MessUser> {
  final DatabaseConfig _dbHelper = DatabaseConfig.instance;
  final _lock = Lock();

  @override
  Future<String> create(MessUser user) async {
    return await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.insert(
        'mess_user',
        user.toMap()..['sync_status'] = MessUserSync.pendingCreate,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return user.uniqueId!;
    });
  }

  @override
  Future<void> update(String id, MessUser user) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'mess_user',
        user.toMap()..['sync_status'] = MessUserSync.pendingUpdate,
        where: 'unique_id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      // Mark as pending delete instead of actual deletion
      await db.update(
        'mess_user',
        {'sync_status': MessUserSync.pendingDelete},
        where: 'unique_id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<MessUser?> get(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mess_user',
      where: 'unique_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return MessUser.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<MessUser>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('mess_user');
    return List.generate(maps.length, (i) => MessUser.fromMap(maps[i]));
  }

  @override
  Stream<MessUser?> watch(String id) =>
      Stream.periodic(Duration(seconds: 2)).asyncMap((_) => get(id));

  @override
  Stream<List<MessUser>> watchAll() =>
      Stream.periodic(Duration(seconds: 2)).asyncMap((_) => getAll());


  @override
  Stream<List<MessUser>> watchByMess(String messId) {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'mess_user',
        where: 'mess_id = ?',
        whereArgs: [messId],
      );
      return List.generate(maps.length, (i) => MessUser.fromMap(maps[i]));
    });
  }

  @override
  Future<void> pushPendingOperations() async {
    final db = await _dbHelper.database;

    final pending = await db.query(
      'mess_user',
      where: 'sync_status != ?',
      whereArgs: [MessUserSync.synced],
    );

    // Your sync logic with Firebase or remote DB here.

    return Future.value();
  }

  @override
  Future<void> pullLatestData() async {
    // Fetch latest data from remote DB and update local DB accordingly.

    return Future.value();
  }

  @override
  Stream<List<MessUser>> watchByUser(String uniqueId) {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'mess_user',
        where: 'unique_id = ?',
        whereArgs: [uniqueId],
      );
      return List.generate(maps.length, (i) => MessUser.fromMap(maps[i]));
    });
  }
}
