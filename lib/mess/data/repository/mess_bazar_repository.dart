import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:sqflite/sqflite.dart';

import '../../../model/mess/bazar_list.dart';
import '../db/database_config.dart';
import '../model/model_extensions.dart';


class BazarListRepository {
  final Database _db;
  final DatabaseReference _fbRef;

  BazarListRepository._(this._db, this._fbRef);

  static Future<BazarListRepository> init() async {
    final db = await DatabaseConfig.initSQLite();
    final fbRef = DatabaseConfig.firebaseRef.child('bazar_list');
    return BazarListRepository._(db, fbRef);
  }

  Future<List<BazarList>> getAll() async {
    final maps = await _db.query('bazar_list');
    return maps.map((map) => BazarList.fromMap(map)).toList();
  }

  Future<BazarList?> getById(int id) async {
    final maps = await _db.query('bazar_list', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return BazarList.fromMap(maps.first);
    return null;
  }

  Future<int> insert(BazarList item) async {
    final newItem = item.copyWithSyncStatus(BazarListSync.pendingCreate);
    final id = await _db.insert('bazar_list', newItem.toMap());

    final json = newItem.toJson();
    final fbKey = json['list_id'] ?? id.toString();
    _fbRef.child(fbKey).set(json);

    return id;
  }

  Future<int> update(BazarList item) async {
    final updatedItem = item.copyWithSyncStatus(BazarListSync.pendingUpdate);
    final count = await _db.update(
      'bazar_list',
      updatedItem.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );

    final json = updatedItem.toJson();
    final fbKey = json['list_id'] ?? item.id.toString();
    _fbRef.child(fbKey).update(json);

    return count;
  }

  Future<int> delete(int id, String listId) async {
    final item = await getById(id);
    if (item == null) return 0;

    final deletedItem = item.copyWithSyncStatus(BazarListSync.pendingDelete);
    await _db.update(
      'bazar_list',
      deletedItem.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    await _fbRef.child(listId).remove();

    return await _db.delete('bazar_list', where: 'id = ?', whereArgs: [id]);
  }

  Stream<List<BazarList>> watchAll() {
    return _fbRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<String, dynamic> map = Map<String, dynamic>.from(data as Map);
      return map.values
          .map((json) => BazarList.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    });
  }

  Future<void> updateSyncStatus(String uniqueId, String newStatus) async {
    final db = await _db;
    await db.update(
      'bazar_list',
      {'sync_status': newStatus, 'last_updated': DateTime.now().toIso8601String()},
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

  Future<void> deleteByUniqueId(String uniqueId) async {
    final db = await _db;
    await db.delete(
      'bazar_list',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

}
