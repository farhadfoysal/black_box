import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

Future<void> fullAppReset() async {
  try {
    // =========================
    // 1. CLEAR SHARED PREFS
    // =========================
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // =========================
    // 2. DELETE ALL DATABASES
    // =========================
    final dbPath = await getDatabasesPath();
    final dbDir = Directory(dbPath);

    if (await dbDir.exists()) {
      final files = dbDir.listSync();

      for (var file in files) {
        if (file is File) {
          await databaseFactory.deleteDatabase(file.path);
        }
      }
    }

    // =========================
    // 3. CLEAR CACHE DIRECTORY
    // =========================
    final cacheDir = await getTemporaryDirectory();

    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }

    // =========================
    // 4. CLEAR APP DOC DIRECTORY (OPTIONAL ⚠️)
    // =========================
    final appDir = await getApplicationDocumentsDirectory();

    if (await appDir.exists()) {
      await appDir.delete(recursive: true);
    }

    print("🔥 FULL APP RESET COMPLETE");

  } catch (e) {
    print("❌ Reset Error: $e");
  }
}

Future<void> confirmFullReset(BuildContext context) async {
  final confirm = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("⚠️ Full Reset"),
      content: Text("This will delete ALL app data. Continue?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
      ],
    ),
  );

  if (confirm == true) {
    await fullAppReset();
  }
}