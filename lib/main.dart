import 'package:black_box/black_box_app.dart';
import 'package:black_box/utility/controller/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'controller/connectivity_controller.dart';
import 'db/local/deletion_sync_manager.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/date_symbol_data_local.dart';

const supabaseUrl = 'https://acbvncxbfitjeduodvqb.supabase.co';
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFjYnZuY3hiZml0amVkdW9kdnFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE3ODM0MjgsImV4cCI6MjA2NzM1OTQyOH0.9p0DtIwlBnvkjhmjEFXcjw2xE-HnlteQ7PsDrZfBkyw";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting();
  await initializeDateFormatting('bn');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await DeletionSyncManager().init();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);


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
