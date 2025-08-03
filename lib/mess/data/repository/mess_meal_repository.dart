import 'dart:convert';

import 'package:black_box/mess/data/model/model_extensions.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sqflite/sqflite.dart';

import '../../../model/mess/my_meals.dart';
import '../db/database_config.dart';

class MyMealsRepository {
  final Database _db;
  final DatabaseReference _fbRef;

  MyMealsRepository._(this._db, this._fbRef);

  static Future<MyMealsRepository> init() async {
    final db = await DatabaseConfig.initSQLite();
    final fbRef = DatabaseConfig.firebaseRef.child('my_meals');
    return MyMealsRepository._(db, fbRef);
  }

  Future<List<MyMeals>> getAll() async {
    final maps = await _db.query('my_meals');
    return maps.map((map) => MyMeals.fromMap(map)).toList();
  }

  Future<MyMeals?> getById(int id) async {
    final maps = await _db.query('my_meals', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return MyMeals.fromMap(maps.first);
    return null;
  }

  Future<int> insert(MyMeals meal) async {
    final newMeal = meal.copyWithSyncStatus(MyMealsSync.pendingCreate);
    final id = await _db.insert('my_meals', newMeal.toMap());

    final json = newMeal.toJson();
    final fbKey = json['unique_id'] ?? id.toString();
    _fbRef.child(fbKey).set(json);

    return id;
  }

  Future<int> update(MyMeals meal) async {
    final updatedMeal = meal.copyWithSyncStatus(MyMealsSync.pendingUpdate);
    final count = await _db.update(
      'my_meals',
      updatedMeal.toMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );

    final json = updatedMeal.toJson();
    final fbKey = json['unique_id'] ?? meal.id.toString();
    _fbRef.child(fbKey).update(json);

    return count;
  }

  Future<int> delete(int id, String uniqueId) async {
    final meal = await getById(id);
    if (meal == null) return 0;

    final deletedMeal = meal.copyWithSyncStatus(MyMealsSync.pendingDelete);
    await _db.update(
      'my_meals',
      deletedMeal.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    await _fbRef.child(uniqueId).remove();

    return await _db.delete('my_meals', where: 'id = ?', whereArgs: [id]);
  }

  Stream<List<MyMeals>> watchAll() {
    return _fbRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<String, dynamic> map = Map<String, dynamic>.from(data as Map);
      return map.values
          .map((json) => MyMeals.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    });
  }

  Future<void> updateSyncStatus(String uniqueId, String newStatus) async {
    final db = await _db;
    await db.update(
      'my_meals',
      {'sync_status': newStatus, 'last_updated': DateTime.now().toIso8601String()},
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

  Future<void> deleteByUniqueId(String uniqueId) async {
    final db = await _db;
    await db.delete(
      'my_meals',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

}
