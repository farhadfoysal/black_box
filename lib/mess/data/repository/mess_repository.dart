import 'dart:convert';

import 'package:black_box/mess/data/model/model_extensions.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sqflite/sqflite.dart';

import '../../../model/mess/mess_main.dart';
import '../db/database_config.dart';

class MessMainRepository {
  final Database _db;
  final DatabaseReference _fbRef;

  MessMainRepository._(this._db, this._fbRef);

  static Future<MessMainRepository> init() async {
    final db = await DatabaseConfig.initSQLite();
    final fbRef = DatabaseConfig.firebaseRef.child('mess_main');
    return MessMainRepository._(db, fbRef);
  }

  Future<List<MessMain>> getAll() async {
    final maps = await _db.query('mess_main');
    return maps.map((map) => MessMain.fromMap(map)).toList();
  }

  Future<MessMain?> getById(int id) async {
    final maps = await _db.query('mess_main', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return MessMain.fromMap(maps.first);
    return null;
  }

  /// Get the latest MessMain (offline-first)
  Future<MessMain?> getLatestMessMain({bool fetchOnlineIfEmpty = true}) async {
    // 1️⃣ Try SQLite first
    final maps = await _db.query(
      'mess_main',
      orderBy: 'last_updated DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return MessMain.fromMap(maps.first);
    }

    // 2️⃣ If SQLite empty & allowed, fetch from Firebase
    if (fetchOnlineIfEmpty) {
      final snapshot = await _fbRef.orderByChild('last_updated').limitToLast(1).once();
      if (snapshot.snapshot.value != null) {
        final Map<String, dynamic> map =
        Map<String, dynamic>.from((snapshot.snapshot.value as Map).values.first);

        // Save to SQLite for offline use
        final mess = MessMain.fromJson(map);
        await _db.insert(
          'mess_main',
          mess.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        return mess;
      }
    }

    return null;
  }

  /// Get the latest MessMain from SQLite (offline-first)
  Future<MessMain?> getLatestMessMainFromLocal() async {
    final maps = await _db.query(
      'mess_main',
      orderBy: 'last_updated DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return MessMain.fromMap(maps.first);
    }
    return null;
  }

  /// Optionally: fetch latest from Firebase if needed
  Future<MessMain?> getLatestFromFirebase() async {
    final snapshot = await _fbRef.orderByChild('last_updated').limitToLast(1).once();
    if (snapshot.snapshot.value != null) {
      final Map<String, dynamic> map =
      Map<String, dynamic>.from((snapshot.snapshot.value as Map).values.first);
      return MessMain.fromJson(map);
    }
    return null;
  }

  Future<int> insert(MessMain messMain) async {
    // Insert locally with sync_status = pending_create
    final newObj = messMain.copyWithSyncStatus(MessMainSync.pendingCreate);
    final id = await _db.insert('mess_main', newObj.toMap());

    // Insert in Firebase asynchronously (optional: can do via sync service)
    final json = newObj.toJson();
    final fbKey = json['mess_id'] ?? id.toString();
    _fbRef.child(fbKey).set(json);

    return id;
  }

  Future<int> update(MessMain messMain) async {
    final updatedObj = messMain.copyWithSyncStatus(MessMainSync.pendingUpdate);
    final count = await _db.update(
      'mess_main',
      updatedObj.toMap(),
      where: 'id = ?',
      whereArgs: [messMain.id],
    );

    // Update in Firebase async
    final json = updatedObj.toJson();
    final fbKey = json['mess_id'] ?? messMain.id.toString();
    _fbRef.child(fbKey).update(json);

    return count;
  }

  Future<int> delete(int id, String messId) async {
    // Mark sync_status pending_delete before deletion (optional)
    final messMain = await getById(id);
    if (messMain == null) return 0;

    final deletedObj = messMain.copyWithSyncStatus(MessMainSync.pendingDelete);
    await _db.update(
      'mess_main',
      deletedObj.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    // Delete from Firebase async
    await _fbRef.child(messId).remove();

    // Finally delete locally
    return await _db.delete('mess_main', where: 'id = ?', whereArgs: [id]);
  }

  /// Real-time Firebase stream watcher for all MessMain objects
  Stream<List<MessMain>> watchAll() {
    return _fbRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<String, dynamic> map = Map<String, dynamic>.from(data as Map);
      final list = map.values
          .map((json) => MessMain.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      return list;
    });
  }

  // Example in MessMainRepository:

  Future<void> updateSyncStatus(String uniqueId, String newStatus) async {
    final db = await _db;
    await db.update(
      'mess_main',
      {'sync_status': newStatus, 'last_updated': DateTime.now().toIso8601String()},
      where: 'mess_id = ?',
      whereArgs: [uniqueId],
    );
  }

  Future<void> deleteByUniqueId(String uniqueId) async {
    final db = await _db;
    await db.delete(
      'mess_main',
      where: 'mess_id = ?',
      whereArgs: [uniqueId],
    );
  }

  Future<void> syncPendingOperations() async {
    final List<Map<String, dynamic>> pendingItems = await _db.query(
      'mess_main',
      where: 'sync_status != ?',
      whereArgs: [MessMainSync.synced],
    );

    for (final item in pendingItems) {
      final mm = MessMain.fromMap(item);
      final uniqueId = mm.messId ?? mm.id.toString();

      try {
        if (mm.syncStatus == MessMainSync.pendingCreate) {
          await _fbRef.child(uniqueId).set(mm.toJson());
        } else if (mm.syncStatus == MessMainSync.pendingUpdate) {
          await _fbRef.child(uniqueId).update(mm.toJson());
        } else if (mm.syncStatus == MessMainSync.pendingDelete) {
          await _fbRef.child(uniqueId).remove();
          await deleteByUniqueId(uniqueId);
          continue;
        }

        await _db.update(
          'mess_main',
          {
            'sync_status': MessMainSync.synced,
            'last_updated': DateTime.now().toIso8601String(),
          },
          where: 'unique_id = ?',
          whereArgs: [uniqueId],
        );
      } catch (e) {
        print('Sync failed for item $uniqueId: $e');
      }
    }
  }

}


// final messMainRepo = await MessMainRepository.init();
//
// final allMess = await messMainRepo.getAll();
//
// final newMess = MessMain(...);
// final newId = await messMainRepo.insert(newMess);
//
// final updatedMess = newMess.copyWithSyncStatus('pending_update');
// await messMainRepo.update(updatedMess);
//
// await messMainRepo.delete(newId, newMess.messId!);
//
// messMainRepo.watchAll().listen((list) {
// print('Realtime mess list changed: $list');
// });
