import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:sqflite/sqflite.dart';

import '../../../model/mess/payment.dart';
import '../db/database_config.dart';
import '../model/model_extensions.dart';


class PaymentRepository {
  final Database _db;
  final DatabaseReference _fbRef;

  PaymentRepository._(this._db, this._fbRef);

  static Future<PaymentRepository> init() async {
    final db = await DatabaseConfig.initSQLite();
    final fbRef = DatabaseConfig.firebaseRef.child('payment');
    return PaymentRepository._(db, fbRef);
  }

  Future<List<Payment>> getAll() async {
    final maps = await _db.query('payment');
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<Payment?> getById(int id) async {
    final maps = await _db.query('payment', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Payment.fromMap(maps.first);
    return null;
  }

  Future<int> insert(Payment payment) async {
    final newPayment = payment.copyWithSyncStatus(PaymentSync.pendingCreate);
    final id = await _db.insert('payment', newPayment.toMap());

    final json = newPayment.toJson();
    final fbKey = id.toString();
    _fbRef.child(fbKey).set(json);

    return id;
  }

  Future<int> update(Payment payment) async {
    final updatedPayment = payment.copyWithSyncStatus(PaymentSync.pendingUpdate);
    final count = await _db.update(
      'payment',
      updatedPayment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );

    final json = updatedPayment.toJson();
    final fbKey = payment.id.toString();
    _fbRef.child(fbKey).update(json);

    return count;
  }

  // Future<int> delete(int id) async {
  //   final payment = await getById(id);
  //   if (payment == null) return 0;
  //
  //   final deletedPayment = payment.copyWithSyncStatus(PaymentSync.pendingDelete);
  //   await _db.update(
  //     'payment',
  //     deletedPayment.toMap(),
  //     where: 'id = ?',
  //     whereArgs: [id],
  //   );
  //
  //   await _fbRef.child(id.toString()).remove();
  //
  //   return await _db.delete('payment', where: 'id = ?', whereArgs: [id]);
  // }

  Future<int> delete(int id, String uniqueId) async {
    final payment = await getById(id);
    if (payment == null) return 0;

    final deletedPayment = payment.copyWithSyncStatus(PaymentSync.pendingDelete);
    await _db.update(
      'payment',
      deletedPayment.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    await _fbRef.child(uniqueId).remove();

    return await _db.delete('payment', where: 'id = ?', whereArgs: [id]);
  }

  Stream<List<Payment>> watchAll() {
    return _fbRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<String, dynamic> map = Map<String, dynamic>.from(data as Map);
      return map.values
          .map((json) => Payment.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    });
  }

  Future<void> updateSyncStatus(String uniqueId, String newStatus) async {
    final db = await _db;
    await db.update(
      'payment',
      {'sync_status': newStatus, 'last_updated': DateTime.now().toIso8601String()},
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

  Future<void> deleteByUniqueId(String uniqueId) async {
    final db = await _db;
    await db.delete(
      'payment',
      where: 'unique_id = ?',
      whereArgs: [uniqueId],
    );
  }

  Future<void> syncPendingOperations() async {
    final List<Map<String, dynamic>> pendingItems = await _db.query(
      'payment',
      where: 'sync_status != ?',
      whereArgs: [PaymentSync.synced],
    );

    for (final item in pendingItems) {
      final model = Payment.fromMap(item);
      final uniqueId = model.uniqueId ?? model.id.toString();

      try {
        if (model.syncStatus == PaymentSync.pendingCreate) {
          await _fbRef.child(uniqueId).set(model.toJson());
        } else if (model.syncStatus == PaymentSync.pendingUpdate) {
          await _fbRef.child(uniqueId).update(model.toJson());
        } else if (model.syncStatus == PaymentSync.pendingDelete) {
          await _fbRef.child(uniqueId).remove();
          await deleteByUniqueId(uniqueId);
          continue;
        }

        await _db.update(
          'payment',
          {
            'sync_status': PaymentSync.synced,
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
