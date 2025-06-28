import 'package:sqflite/sqflite.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart';

class DeletionSyncManager {
  static final DeletionSyncManager _instance = DeletionSyncManager._internal();
  late Database _db;
  final _firebase = FirebaseDatabase.instance;
  bool _isInitialized = false;

  factory DeletionSyncManager() => _instance;

  DeletionSyncManager._internal();

  Future<void> init() async {
    if (_isInitialized) return;

    final path = join(await getDatabasesPath(), 'blackbox_saved.db');
    _db = await openDatabase(path, version: 1, onCreate: _createDb);
    _isInitialized = true;

    _listenToConnectivity();
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS deletion_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_id TEXT NOT NULL,
        unique_id TEXT NOT NULL,
        entity_name TEXT NOT NULL
      );
    ''');
  }

  Future<void> markForDeletion({
    required String entityId,
    required String uniqueId,
    required String entityName,
  }) async {
    await _db.insert('deletion_log', {
      'entity_id': entityId,
      'unique_id': uniqueId,
      'entity_name': entityName,
    });
  }

  Future<void> _listenToConnectivity() async {
    final initialStatus = await Connectivity().checkConnectivity();
    if (initialStatus != ConnectivityResult.none) {
      _syncPendingDeletions();
    }

    Connectivity().onConnectivityChanged.listen((status) {
      if (status != ConnectivityResult.none) {
        _syncPendingDeletions();
      }
    });
  }

  Future<void> _syncPendingDeletions() async {
    final deletions = await _db.query('deletion_log');
    for (var deletion in deletions) {
      final String entityId = deletion['entity_id'] as String;
      final String uniqueId = deletion['unique_id'] as String;
      final String entityName = deletion['entity_name'] as String;

      try {
        final ref = _firebase.ref('$entityName/$uniqueId');
        await ref.remove();

        // Remove from log on success
        await _db.delete(
          'deletion_log',
          where: 'unique_id = ?',
          whereArgs: [uniqueId],
        );
      } catch (e) {
        print('Error deleting $uniqueId from Firebase: $e');
        // Keep in log to retry later
      }
    }
  }
}