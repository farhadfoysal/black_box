import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:sqflite/sqflite.dart';

import '../../../model/mess/account_print.dart';
import '../db/database_config.dart';
import '../model/model_extensions.dart';


class AccountPrintRepository {
  final Database _db;
  final DatabaseReference _fbRef;

  AccountPrintRepository._(this._db, this._fbRef);

  static Future<AccountPrintRepository> init() async {
    final db = await DatabaseConfig.initSQLite();
    final fbRef = DatabaseConfig.firebaseRef.child('account_print');
    return AccountPrintRepository._(db, fbRef);
  }

  Future<List<AccountPrint>> getAll() async {
    final maps = await _db.query('account_print');
    return maps.map((map) => AccountPrint.fromMap(map)).toList();
  }

  Future<AccountPrint?> getById(int id) async {
    final maps = await _db.query('account_print', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return AccountPrint.fromMap(maps.first);
    return null;
  }

  Future<int> insert(AccountPrint ap) async {
    final newAp = ap.copyWithSyncStatus(AccountPrintSync.pendingCreate);
    final id = await _db.insert('account_print', newAp.toMap());

    final json = newAp.toJson();
    final fbKey = json['unique_id'] ?? id.toString();
    _fbRef.child(fbKey).set(json);

    return id;
  }

  Future<int> update(AccountPrint ap) async {
    final updatedAp = ap.copyWithSyncStatus(AccountPrintSync.pendingUpdate);
    final count = await _db.update(
      'account_print',
      updatedAp.toMap(),
      where: 'id = ?',
      whereArgs: [ap.id],
    );

    final json = updatedAp.toJson();
    final fbKey = json['unique_id'] ?? ap.id.toString();
    _fbRef.child(fbKey).update(json);

    return count;
  }

  Future<int> delete(int id, String uniqueId) async {
    final ap = await getById(id);
    if (ap == null) return 0;

    final deletedAp = ap.copyWithSyncStatus(AccountPrintSync.pendingDelete);
    await _db.update(
      'account_print',
      deletedAp.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    await _fbRef.child(uniqueId).remove();

    return await _db.delete('account_print', where: 'id = ?', whereArgs: [id]);
  }

  Stream<List<AccountPrint>> watchAll() {
    return _fbRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<String, dynamic> map = Map<String, dynamic>.from(data as Map);
      return map.values
          .map((json) => AccountPrint.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    });
  }

  Future<void> updateSyncStatus(String uniqueId, String newStatus) async {
    final db = await _db;
    await db.update(
      'account_print',
      {'sync_status': newStatus, 'last_updated': DateTime.now().toIso8601String()},
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

  Future<void> deleteByUniqueId(String uniqueId) async {
    final db = await _db;
    await db.delete(
      'account_print',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

}
