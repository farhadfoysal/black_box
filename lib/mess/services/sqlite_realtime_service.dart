import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../data/db/database_config.dart';

class SQLiteRealtimeService {
  static final SQLiteRealtimeService _instance = SQLiteRealtimeService._internal();
  factory SQLiteRealtimeService() => _instance;

  late Database _db;
  final Map<String, List<VoidCallback>> _tableListeners = {};
  final Map<String, List<VoidCallback>> _itemListeners = {};

  SQLiteRealtimeService._internal();

  Future<void> initialize() async {
    _db = await DatabaseConfig.initSQLite();
  }

  void addTableListener(String table, VoidCallback callback) {
    _tableListeners[table] ??= [];
    _tableListeners[table]!.add(callback);
  }

  void addItemListener(String table, String id, VoidCallback callback) {
    final key = '$table/$id';
    _itemListeners[key] ??= [];
    _itemListeners[key]!.add(callback);
  }

  void removeTableListener(String table, VoidCallback callback) {
    _tableListeners[table]?.remove(callback);
  }

  void removeItemListener(String table, String id, VoidCallback callback) {
    final key = '$table/$id';
    _itemListeners[key]?.remove(callback);
  }

  void _notifyTable(String table) {
    _tableListeners[table]?.forEach((cb) => cb());
  }

  void _notifyItem(String table, String id) {
    _itemListeners['$table/$id']?.forEach((cb) => cb());
  }

  Future<void> insertOrUpdate(String table, String id, Map<String, dynamic> data,
      {bool fromSync = false}) async {
    await _db.insert(
      table,
      {
        'id': id,
        'data': jsonEncode(data),
        'last_updated': DateTime.now().millisecondsSinceEpoch,
        if (!fromSync) 'sync_status': 'pending'
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _notifyTable(table);
    _notifyItem(table, id);

    if (!fromSync) {
      await _db.insert('pending_operations', {
        'operation_type': 'upsert',
        'table_name': table,
        'item_id': id,
        'item_data': jsonEncode(data),
        'created_at': DateTime.now().millisecondsSinceEpoch
      });
    }
  }

  Future<void> delete(String table, String id, {bool fromSync = false}) async {
    await _db.delete(table, where: 'id = ?', whereArgs: [id]);

    _notifyTable(table);
    _notifyItem(table, id);

    if (!fromSync) {
      await _db.insert('pending_operations', {
        'operation_type': 'delete',
        'table_name': table,
        'item_id': id,
        'created_at': DateTime.now().millisecondsSinceEpoch
      });
    }
  }

  Stream<List<Map<String, dynamic>>> watchTable(String table) {
    final controller = StreamController<List<Map<String, dynamic>>>();

    // Initial data
    _db.query(table).then((List<Map<String, dynamic>> rows) {
      controller.add(rows.map((row) => jsonDecode(row['data'] as String) as Map<String, dynamic>).toList());
    });

    // Periodic polling (every 2 seconds)
    final timer = Timer.periodic(Duration(seconds: 2), (_) async {
      final rows = await _db.query(table) as List<Map<String, dynamic>>;
      controller.add(rows.map((row) => jsonDecode(row['data'] as String) as Map<String, dynamic>).toList());
    });

    // Listen for changes
    VoidCallback? listener;
    listener = () {
      _db.query(table).then((List<Map<String, dynamic>> rows) {
        controller.add(rows.map((row) => jsonDecode(row['data'] as String) as Map<String, dynamic>).toList());
      });
    };
    addTableListener(table, listener);

    controller.onCancel = () {
      timer.cancel();
      if (listener != null) {
        removeTableListener(table, listener);
      }
    };

    return controller.stream;
  }

  Stream<Map<String, dynamic>?> watchItem(String table, String id) {
    final controller = StreamController<Map<String, dynamic>?>();

    // Initial data
    _db.query(table, where: 'id = ?', whereArgs: [id]).then((List<Map<String, dynamic>> rows) {
      controller.add(rows.isEmpty ? null : jsonDecode(rows.first['data'] as String) as Map<String, dynamic>);
    });

    // Periodic polling (every 2 seconds)
    final timer = Timer.periodic(Duration(seconds: 2), (_) async {
      final rows = await _db.query(table, where: 'id = ?', whereArgs: [id]) as List<Map<String, dynamic>>;
      controller.add(rows.isEmpty ? null : jsonDecode(rows.first['data'] as String) as Map<String, dynamic>);
    });

    // Listen for changes
    VoidCallback? listener;
    listener = () {
      _db.query(table, where: 'id = ?', whereArgs: [id]).then((List<Map<String, dynamic>> rows) {
        controller.add(rows.isEmpty ? null : jsonDecode(rows.first['data'] as String) as Map<String, dynamic>);
      });
    };
    addItemListener(table, id, listener);

    controller.onCancel = () {
      timer.cancel();
      if (listener != null) {
        removeItemListener(table, id, listener);
      }
    };

    return controller.stream;
  }
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    return await _db.query('pending_operations');
  }

  Future<void> clearPendingOperation(int id) async {
    await _db.delete('pending_operations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _db.close();
  }
}