import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageService {
  static Future<Directory> getOMRDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final omrDir = Directory('${appDir.path}/OMR_Sheets');

    if (!await omrDir.exists()) {
      await omrDir.create(recursive: true);
    }

    return omrDir;
  }

  static Future<Directory> getResultsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final resultsDir = Directory('${appDir.path}/OMR_Results');

    if (!await resultsDir.exists()) {
      await resultsDir.create(recursive: true);
    }

    return resultsDir;
  }

  static Future<File> saveOMRImage(File sourceFile, String fileName) async {
    final omrDir = await getOMRDirectory();
    final destinationPath = '${omrDir.path}/$fileName';
    return await sourceFile.copy(destinationPath);
  }

  static Future<void> deleteOMRImage(String fileName) async {
    final omrDir = await getOMRDirectory();
    final file = File('${omrDir.path}/$fileName');

    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<List<File>> getAllOMRImages() async {
    final omrDir = await getOMRDirectory();
    final files = omrDir.listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.png') || file.path.endsWith('.jpg'))
        .toList();

    return files;
  }
}