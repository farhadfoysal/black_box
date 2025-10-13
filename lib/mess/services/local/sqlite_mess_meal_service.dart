import 'package:black_box/mess/data/db/database_config.dart';
import 'package:black_box/model/mess/my_meals.dart'; // Ensure this contains MyMeals model
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import '../../data/db/database_interfaces.dart';
import '../../data/model/model_extensions.dart';

class SqliteMessMealService implements BaseDatabaseService<MyMeals> {
  final DatabaseConfig _dbHelper = DatabaseConfig.instance;
  final _lock = Lock();

  @override
  Future<String> create(MyMeals meal) async {
    return await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.insert(
        'meal',
        meal.toMap()
          ..['sync_status'] = MessUserSync.pendingCreate,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return meal.uniqueId;
    });
  }

  @override
  Future<void> update(String id, MyMeals meal) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'meal',
        meal.toMap()
          ..['sync_status'] = MessUserSync.pendingUpdate,
        where: 'unique_id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'meal',
        {'sync_status': MessUserSync.pendingDelete},
        where: 'unique_id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<MyMeals?> get(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'meal',
      where: 'unique_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return MyMeals.fromMap(maps.first);
    return null;
  }

  @override
  Future<List<MyMeals>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('meal');
    return List.generate(maps.length, (i) => MyMeals.fromMap(maps[i]));
  }

  @override
  Stream<MyMeals?> watch(String id) =>
      Stream.periodic(Duration(seconds: 2)).asyncMap((_) => get(id));

  @override
  Stream<List<MyMeals>> watchAll() =>
      Stream.periodic(Duration(seconds: 2)).asyncMap((_) => getAll());

  @override
  @override
  Stream<List<MyMeals>> watchByMess(String messId) {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'my_meals',
        where: 'mess_id = ?',
        whereArgs: [messId],
      );
      return List.generate(maps.length, (i) => MyMeals.fromMap(maps[i]));
    });
  }


  @override
  Future<void> pushPendingOperations() async {
    final db = await _dbHelper.database;

    // Get all pending operations
    final pending = await db.query('my_meals',
        where: 'sync_status != ?',
        whereArgs: [MessMainSync.synced]);

    // This would be handled by the repositories
    return Future.value();
  }

  @override
  Future<void> pullLatestData() async {
    // TODO: Implement pulling fresh data logic
    return Future.value();
  }

  @override
  Stream<List<MyMeals>> watchByUser(String uniqueId) {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'my_meals',
        where: 'unique_id = ?',
        whereArgs: [uniqueId],
      );
      return List.generate(maps.length, (i) => MyMeals.fromMap(maps[i]));
    });
  }

  /// -----------------------
  /// ✅ UPDATE SYNC STATUS
  /// -----------------------
  Future<void> updateSyncStatus(String uniqueId, String newStatus) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'my_meals',
        {'sync_status': newStatus},
        where: 'unique_id = ?',
        whereArgs: [uniqueId],
      );
    });
  }

}
