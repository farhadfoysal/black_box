import 'package:black_box/mess/data/db/database_config.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import '../../../model/mess/mess_fees.dart';
import '../../data/db/database_interfaces.dart';
import '../../data/model/model_extensions.dart';

class SQLiteMessFeesService implements BaseDatabaseService<MessFees> {
  final DatabaseConfig _dbHelper = DatabaseConfig.instance;
  final _lock = Lock();

  @override
  Future<String> create(MessFees item) async {
    return await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.insert(
        'mess_fees',
        item.toMap()..['sync_status'] = MessUserSync.pendingCreate,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return item.messId;
    });
  }

  @override
  Future<void> update(String id, MessFees item) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'mess_fees',
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
        'mess_fees',
        {'sync_status': MessUserSync.pendingDelete},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<MessFees?> get(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mess_fees',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return MessFees.fromMap(maps.first);
    return null;
  }

  @override
  Future<List<MessFees>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('mess_fees');
    return List.generate(maps.length, (i) => MessFees.fromMap(maps[i]));
  }

  @override
  Stream<MessFees?> watch(String id) =>
      Stream.periodic(Duration(seconds: 2)).asyncMap((_) => get(id));

  @override
  Stream<List<MessFees>> watchAll() =>
      Stream.periodic(Duration(seconds: 2)).asyncMap((_) => getAll());

  @override
  Future<void> pushPendingOperations() async {
    final db = await _dbHelper.database;

    // Get all pending operations
    final pending = await db.query('mess_fee',
        where: 'sync_status != ?',
        whereArgs: [MessMainSync.synced]);

    // This would be handled by the repository
    return Future.value();
  }

  @override
  Future<void> pullLatestData() async {
    // Pull data logic
    return Future.value();
  }

  @override
  Stream<List<MessFees>> watchByMess(String messId) {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'mess_fee',
        where: 'mess_id = ?',
        whereArgs: [messId],
      );
      return List.generate(maps.length, (i) => MessFees.fromMap(maps[i]));
    });
  }

  @override
  Stream<List<MessFees>> watchByUser(String uniqueId) {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'mess_fee',
        where: 'unique_id = ?',
        whereArgs: [uniqueId],
      );
      return List.generate(maps.length, (i) => MessFees.fromMap(maps[i]));
    });
  }
}
