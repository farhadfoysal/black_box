import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:sqflite/sqflite.dart';

import '../../../model/mess/mess_user.dart';
import '../db/database_config.dart';
import '../model/model_extensions.dart';

class MessUserRepository {
  final Database _db;
  final DatabaseReference _fbRef;

  MessUserRepository._(this._db, this._fbRef);

  static Future<MessUserRepository> init() async {
    final db = await DatabaseConfig.initSQLite();
    final fbRef = DatabaseConfig.firebaseRef.child('mess_user');
    return MessUserRepository._(db, fbRef);
  }

  Future<List<MessUser>> getAll() async {
    final maps = await _db.query('mess_user');
    return maps.map((map) => MessUser.fromMap(map)).toList();
  }

  Future<MessUser?> getById(int id) async {
    final maps = await _db.query('mess_user', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return MessUser.fromMap(maps.first);
    return null;
  }

  Future<int> insert(MessUser user) async {
    final newUser = user.copyWithSyncStatus(MessUserSync.pendingCreate);
    final id = await _db.insert('mess_user', newUser.toMap());

    final json = newUser.toJson();
    final fbKey = json['unique_id'] ?? id.toString();
    _fbRef.child(fbKey).set(json);

    return id;
  }

  Future<int> update(MessUser user) async {
    final updatedUser = user.copyWithSyncStatus(MessUserSync.pendingUpdate);
    final count = await _db.update(
      'mess_user',
      updatedUser.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );

    final json = updatedUser.toJson();
    final fbKey = json['unique_id'] ?? user.id.toString();
    _fbRef.child(fbKey).update(json);

    return count;
  }

  Future<int> delete(int id, String uniqueId) async {
    final user = await getById(id);
    if (user == null) return 0;

    final deletedUser = user.copyWithSyncStatus(MessUserSync.pendingDelete);
    await _db.update(
      'mess_user',
      deletedUser.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    await _fbRef.child(uniqueId).remove();

    return await _db.delete('mess_user', where: 'id = ?', whereArgs: [id]);
  }

  Stream<List<MessUser>> watchAll() {
    return _fbRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<String, dynamic> map = Map<String, dynamic>.from(data as Map);
      return map.values
          .map((json) => MessUser.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    });
  }

  Future<void> updateSyncStatus(String uniqueId, String newStatus) async {
    final db = await _db;
    await db.update(
      'mess_user',
      {'sync_status': newStatus, 'last_updated': DateTime.now().toIso8601String()},
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

  Future<void> deleteByUniqueId(String uniqueId) async {
    final db = await _db;
    await db.delete(
      'mess_user',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

  Future<void> syncPendingOperations() async {
    final List<Map<String, dynamic>> pendingItems = await _db.query(
      'mess_user',
      where: 'sync_status != ?',
      whereArgs: [MessUserSync.synced],
    );

    for (final item in pendingItems) {
      final mu = MessUser.fromMap(item);
      final uniqueId = mu.uniqueId ?? mu.id.toString();

      try {
        if (mu.syncStatus == MessUserSync.pendingCreate) {
          await _fbRef.child(uniqueId).set(mu.toJson());
        } else if (mu.syncStatus == MessUserSync.pendingUpdate) {
          await _fbRef.child(uniqueId).update(mu.toJson());
        } else if (mu.syncStatus == MessUserSync.pendingDelete) {
          await _fbRef.child(uniqueId).remove();
          await deleteByUniqueId(uniqueId);
          continue;
        }

        await _db.update(
          'mess_user',
          {
            'sync_status': MessUserSync.synced,
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




// import 'package:black_box/model/mess/mess_user.dart';
// import 'package:firebase_database/firebase_database.dart';


// class MessUserRepository {
//   final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('mess_users');

//   Future<List<MessUser>> getAllUsers() async {
//     final snapshot = await _dbRef.get();
//     if (snapshot.exists) {
//       final data = Map<String, dynamic>.from(snapshot.value as Map);
//       return data.values.map((e) => MessUser.fromJson(Map<String, dynamic>.from(e))).toList();
//     }
//     return [];
//   }

//   Future<void> addUser(MessUser user) async {
//     await _dbRef.child(user.uniqueId!).set(user.toJson());
//   }

//   Future<void> updateUser(MessUser user) async {
//     await _dbRef.child(user.id).update(user.toJson());
//   }

//   Future<void> deleteUser(String id) async {
//     await _dbRef.child(id).remove();
//   }

//   Future<MessUser?> getUserById(String id) async {
//     final snapshot = await _dbRef.child(id).get();
//     if (snapshot.exists) {
//       return MessUser.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
//     }
//     return null;
//   }

//   Future<List<MessUser>> getUsersByMess(String messId) async {
//     final users = await getAllUsers();
//     return users.where((u) => u.messId == messId).toList();
//   }

//   Stream<List<MessUser>> watchUsersByMess(String messId) {
//     return _dbRef.orderByChild('messId').equalTo(messId).onValue.map((event) {
//       if (event.snapshot.exists) {
//         final data = Map<String, dynamic>.from(event.snapshot.value as Map);
//         return data.values.map((e) => MessUser.fromJson(Map<String, dynamic>.from(e))).toList();
//       }
//       return [];
//     });
//   }
// }
