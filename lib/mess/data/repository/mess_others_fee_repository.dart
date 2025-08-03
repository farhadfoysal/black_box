import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:sqflite/sqflite.dart';

import '../../../model/mess/others_fee.dart';
import '../db/database_config.dart';
import '../model/model_extensions.dart';



class OthersFeeRepository {
  final Database _db;
  final DatabaseReference _fbRef;

  OthersFeeRepository._(this._db, this._fbRef);

  static Future<OthersFeeRepository> init() async {
    final db = await DatabaseConfig.initSQLite();
    final fbRef = DatabaseConfig.firebaseRef.child('others_fee');
    return OthersFeeRepository._(db, fbRef);
  }

  Future<List<OthersFee>> getAll() async {
    final maps = await _db.query('others_fee');
    return maps.map((map) => OthersFee.fromMap(map)).toList();
  }

  Future<OthersFee?> getById(int id) async {
    final maps = await _db.query('others_fee', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return OthersFee.fromMap(maps.first);
    return null;
  }

  Future<int> insert(OthersFee fee) async {
    final newFee = fee.copyWithSyncStatus(OthersFeeSync.pendingCreate);
    final id = await _db.insert('others_fee', newFee.toMap());

    final json = newFee.toJson();
    final fbKey = id.toString();
    _fbRef.child(fbKey).set(json);

    return id;
  }

  Future<int> update(OthersFee fee) async {
    final updatedFee = fee.copyWithSyncStatus(OthersFeeSync.pendingUpdate);
    final count = await _db.update(
      'others_fee',
      updatedFee.toMap(),
      where: 'id = ?',
      whereArgs: [fee.id],
    );

    final json = updatedFee.toJson();
    final fbKey = fee.id.toString();
    _fbRef.child(fbKey).update(json);

    return count;
  }

  // Future<int> delete(int id) async {
  //   final fee = await getById(id);
  //   if (fee == null) return 0;
  //
  //   final deletedFee = fee.copyWithSyncStatus(OthersFeeSync.pendingDelete);
  //   await _db.update(
  //     'others_fee',
  //     deletedFee.toMap(),
  //     where: 'id = ?',
  //     whereArgs: [id],
  //   );
  //
  //   await _fbRef.child(id.toString()).remove();
  //
  //   return await _db.delete('others_fee', where: 'id = ?', whereArgs: [id]);
  // }

  Future<int> delete(int id, String uniqueId) async {
    final fee = await getById(id);
    if (fee == null) return 0;

    final deletedFee = fee.copyWithSyncStatus(OthersFeeSync.pendingDelete);
    await _db.update(
      'others_fee',
      deletedFee.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    await _fbRef.child(uniqueId).remove();

    return await _db.delete('others_fee', where: 'id = ?', whereArgs: [id]);
  }

  Stream<List<OthersFee>> watchAll() {
    return _fbRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<String, dynamic> map = Map<String, dynamic>.from(data as Map);
      return map.values
          .map((json) => OthersFee.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    });
  }

  Future<void> updateSyncStatus(String uniqueId, String newStatus) async {
    final db = await _db;
    await db.update(
      'others_fee',
      {'sync_status': newStatus, 'last_updated': DateTime.now().toIso8601String()},
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

  Future<void> deleteByUniqueId(String uniqueId) async {
    final db = await _db;
    await db.delete(
      'others_fee',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

}
