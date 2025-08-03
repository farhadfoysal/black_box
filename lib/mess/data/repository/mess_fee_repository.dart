import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:sqflite/sqflite.dart';

import '../../../model/mess/mess_fees.dart';
import '../db/database_config.dart';
import '../model/model_extensions.dart';


class MessFeesRepository {
  final Database _db;
  final DatabaseReference _fbRef;

  MessFeesRepository._(this._db, this._fbRef);

  static Future<MessFeesRepository> init() async {
    final db = await DatabaseConfig.initSQLite();
    final fbRef = DatabaseConfig.firebaseRef.child('mess_fees');
    return MessFeesRepository._(db, fbRef);
  }

  Future<List<MessFees>> getAll() async {
    final maps = await _db.query('mess_fees');
    return maps.map((map) => MessFees.fromMap(map)).toList();
  }

  Future<MessFees?> getById(int id) async {
    final maps = await _db.query('mess_fees', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return MessFees.fromMap(maps.first);
    return null;
  }

  Future<int> insert(MessFees fee) async {
    final newFee = fee.copyWithSyncStatus(MessFeesSync.pendingCreate);
    final id = await _db.insert('mess_fees', newFee.toMap());

    final json = newFee.toJson();
    final fbKey = id.toString();
    _fbRef.child(fbKey).set(json);

    return id;
  }

  Future<int> update(MessFees fee) async {
    final updatedFee = fee.copyWithSyncStatus(MessFeesSync.pendingUpdate);
    final count = await _db.update(
      'mess_fees',
      updatedFee.toMap(),
      where: 'id = ?',
      whereArgs: [fee.id],
    );

    final json = updatedFee.toJson();
    final fbKey = fee.id.toString();
    _fbRef.child(fbKey).update(json);

    return count;
  }

  Future<int> delete(int id) async {
    final fee = await getById(id);
    if (fee == null) return 0;

    final deletedFee = fee.copyWithSyncStatus(MessFeesSync.pendingDelete);
    await _db.update(
      'mess_fees',
      deletedFee.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    await _fbRef.child(id.toString()).remove();

    return await _db.delete('mess_fees', where: 'id = ?', whereArgs: [id]);
  }

  Stream<List<MessFees>> watchAll() {
    return _fbRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<String, dynamic> map = Map<String, dynamic>.from(data as Map);
      return map.values
          .map((json) => MessFees.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    });
  }

  Future<void> updateSyncStatus(String uniqueId, String newStatus) async {
    final db = await _db;
    await db.update(
      'mess_fees',
      {'sync_status': newStatus, 'last_updated': DateTime.now().toIso8601String()},
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

  Future<void> deleteByUniqueId(String uniqueId) async {
    final db = await _db;
    await db.delete(
      'mess_fees',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

}
