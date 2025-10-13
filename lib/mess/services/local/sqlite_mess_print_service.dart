import 'dart:async';
import 'package:black_box/mess/data/db/database_config.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import '../../../model/mess/account_print.dart';
import '../../data/db/database_interfaces.dart';
import '../../data/model/model_extensions.dart';

class SQLiteAccountPrintService implements BaseDatabaseService<AccountPrint> {
  final DatabaseConfig _dbHelper = DatabaseConfig.instance;
  final _lock = Lock();

  @override
  Future<String> create(AccountPrint item) async {
    return await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.insert(
        'account_print',
        item.toMap()..['sync_status'] = AccountPrintSync.pendingCreate,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return item.uniqueId ?? '';
    });
  }

  @override
  Future<void> update(String id, AccountPrint item) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'account_print',
        item.toMap()..['sync_status'] = AccountPrintSync.pendingUpdate,
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
        'account_print',
        {'sync_status': AccountPrintSync.pendingDelete},
        where: 'unique_id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> deleteByUniqueId(String id) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.delete(
        'account_print',
        where: 'unique_id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<AccountPrint?> get(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account_print',
      where: 'unique_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return AccountPrint.fromMap(maps.first);
    return null;
  }

  Future<AccountPrint?> getById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account_print',
      where: 'unique_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return AccountPrint.fromMap(maps.first);
    return null;
  }

  @override
  Future<List<AccountPrint>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('account_print');
    return List.generate(maps.length, (i) => AccountPrint.fromMap(maps[i]));
  }

  @override
  Stream<AccountPrint?> watch(String id) =>
      Stream.periodic(const Duration(seconds: 2)).asyncMap((_) => get(id));

  @override
  Stream<List<AccountPrint>> watchAll() =>
      Stream.periodic(const Duration(seconds: 2)).asyncMap((_) => getAll());

  @override
  Future<void> pushPendingOperations() async {
    // intentionally left blank; repository handles sync logic
    return Future.value();
  }

  @override
  Future<void> pullLatestData() async {
    // intentionally left blank; repository handles remote fetch
    return Future.value();
  }

  @override
  Stream<List<AccountPrint>> watchByMess(String messId) {
    return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'account_print',
        where: 'mess_id = ?',
        whereArgs: [messId],
      );
      return List.generate(maps.length, (i) => AccountPrint.fromMap(maps[i]));
    });
  }

  Stream<List<AccountPrint>> watchByUser(String uniqueId) {
    return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'account_print',
        where: 'unique_id = ?',
        whereArgs: [uniqueId],
      );
      return List.generate(maps.length, (i) => AccountPrint.fromMap(maps[i]));
    });
  }

  /// -----------------------
  /// ✅ UPDATE SYNC STATUS
  /// -----------------------
  Future<void> updateSyncStatus(String uniqueId, String newStatus) async {
    await _lock.synchronized(() async {
      final db = await _dbHelper.database;
      await db.update(
        'account_print',
        {'sync_status': newStatus},
        where: 'unique_id = ?',
        whereArgs: [uniqueId],
      );
    });
  }
}



// import 'package:black_box/mess/data/db/database_config.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:synchronized/synchronized.dart';
//
// import '../../../model/mess/account_print.dart';
// import '../../data/db/database_interfaces.dart';
// import '../../data/model/model_extensions.dart';
//
// class SQLiteAccountPrintService implements BaseDatabaseService<AccountPrint> {
//   final DatabaseConfig _dbHelper = DatabaseConfig.instance;
//   final _lock = Lock();
//
//   @override
//   Future<String> create(AccountPrint item) async {
//     return await _lock.synchronized(() async {
//       final db = await _dbHelper.database;
//       await db.insert(
//         'account_print',
//         item.toMap()..['sync_status'] = MessUserSync.pendingCreate,
//         conflictAlgorithm: ConflictAlgorithm.replace,
//       );
//       return item.uniqueId;
//     });
//   }
//
//   @override
//   Future<void> update(String id, AccountPrint item) async {
//     await _lock.synchronized(() async {
//       final db = await _dbHelper.database;
//       await db.update(
//         'account_print',
//         item.toMap()..['sync_status'] = MessUserSync.pendingUpdate,
//         where: 'unique_id = ?',
//         whereArgs: [id],
//       );
//     });
//   }
//
//   @override
//   Future<void> delete(String id) async {
//     await _lock.synchronized(() async {
//       final db = await _dbHelper.database;
//       await db.update(
//         'account_print',
//         {'sync_status': MessUserSync.pendingDelete},
//         where: 'unique_id = ?',
//         whereArgs: [id],
//       );
//     });
//   }
//
//   Future<void> deleteByUniqueId(String id) async {
//     await _lock.synchronized(() async {
//       final db = await _dbHelper.database;
//       await db.update(
//         'account_print',
//         {'sync_status': MessUserSync.pendingDelete},
//         where: 'unique_id = ?',
//         whereArgs: [id],
//       );
//     });
//   }
//
//   @override
//   Future<AccountPrint?> get(String id) async {
//     final db = await _dbHelper.database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'account_print',
//       where: 'unique_id = ?',
//       whereArgs: [id],
//     );
//     if (maps.isNotEmpty) return AccountPrint.fromMap(maps.first);
//     return null;
//   }
//
//
//   Future<AccountPrint?> getById(String id) async {
//     final db = await _dbHelper.database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'account_print',
//       where: 'unique_id = ?',
//       whereArgs: [id],
//     );
//     if (maps.isNotEmpty) return AccountPrint.fromMap(maps.first);
//     return null;
//   }
//
//   @override
//   Future<List<AccountPrint>> getAll() async {
//     final db = await _dbHelper.database;
//     final List<Map<String, dynamic>> maps = await db.query('account_print');
//     return List.generate(maps.length, (i) => AccountPrint.fromMap(maps[i]));
//   }
//
//   @override
//   Stream<AccountPrint?> watch(String id) =>
//       Stream.periodic(Duration(seconds: 2)).asyncMap((_) => get(id));
//
//   @override
//   Stream<List<AccountPrint>> watchAll() =>
//       Stream.periodic(Duration(seconds: 2)).asyncMap((_) => getAll());
//
//   @override
//   Future<void> pushPendingOperations() async {
//     final db = await _dbHelper.database;
//
//     // Get all pending operations
//     final pending = await db.query('account_print',
//         where: 'sync_status != ?',
//         whereArgs: [MessMainSync.synced]);
//
//     // This would be handled by the repositories
//     return Future.value();
//   }
//
//   @override
//   Future<void> pullLatestData() async {
//     return Future.value();
//   }
//
//   @override
//   Stream<List<AccountPrint>> watchByMess(String messId) {
//     return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
//       final db = await _dbHelper.database;
//       final List<Map<String, dynamic>> maps = await db.query(
//         'account_print',
//         where: 'mess_id = ?',
//         whereArgs: [messId],
//       );
//       return List.generate(maps.length, (i) => AccountPrint.fromMap(maps[i]));
//     });
//   }
//
//   Stream<List<AccountPrint>> watchByUser(String uniqueId) {
//     return Stream.periodic(Duration(seconds: 2)).asyncMap((_) async {
//       final db = await _dbHelper.database;
//       final List<Map<String, dynamic>> maps = await db.query(
//         'account_print',
//         where: 'unique_id = ?',
//         whereArgs: [uniqueId],
//       );
//       return List.generate(maps.length, (i) => AccountPrint.fromMap(maps[i]));
//     });
//   }
// }
