import 'package:black_box/black_box_app.dart';
import 'package:black_box/utility/controller/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'controller/connectivity_controller.dart';
import 'db/local/deletion_sync_manager.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await DeletionSyncManager().init();

  // Get.put(ConnectivityController());
  Get.put(ThemeController());
  runApp(const BlackBoxApp());
  // runApp(MaterialApp(
  //   home: BlackBoxApp(),
  // ));
}

// Future<void> deleteNoteLocallyAndSync({
//   required String noteId,
//   required String uniqueId,
// }) async {
//   final db = await openDatabase('app_database.db');
//   await db.delete('NOTE', where: 'id = ?', whereArgs: [noteId]);
//
//   await DeletionSyncManager().markForDeletion(
//     entityId: noteId,
//     uniqueId: uniqueId,
//     entityName: 'NOTE',
//   );
// }
