import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class DatabaseBackupScreen extends StatefulWidget {
  const DatabaseBackupScreen({super.key});

  @override
  State<DatabaseBackupScreen> createState() => _DatabaseBackupScreenState();
}

class _DatabaseBackupScreenState extends State<DatabaseBackupScreen> {
  bool isLoading = false;

  Future<String> getDatabasePath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    return "${appDocDir.path}/black_box.db"; // Replace with your db name
  }

  Future<String> getDatabasePathSaved() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    return "${appDocDir.path}/blackbox_saved.db"; // Replace with your db name
  }

  Future<void> exportDatabaseFile({required String dbName}) async {
    try {
      final dbDir = await getDatabasesPath();
      final dbPath = path.join(dbDir, dbName);
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception("Database file does not exist: $dbPath");
      }

      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        throw Exception("Storage permission denied");
      }

      final extDir = await getExternalStorageDirectory();
      if (extDir == null) throw Exception("External storage not found");

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = path.join(extDir.path, "backup_${dbName}_$timestamp.db");

      await dbFile.copy(backupPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Exported to: $backupPath")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Export failed: $e")),
      );
    }
  }




  Future<void> exportDatabase() async {
    try {
      // ✅ Get database path dynamically
      final databasesPath = await getDatabasesPath();
      final dbPath = path.join(databasesPath, "black_box.db");
      final dbFile = File(dbPath);

      // ✅ Check if the file exists
      if (!await dbFile.exists()) {
        throw Exception("Database file does not exist at $dbPath");
      }

      // ✅ Ask for storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception("Storage permission not granted");
      }

      // ✅ Get external directory
      final Directory? extDir = await getExternalStorageDirectory();
      if (extDir == null) {
        throw Exception("Unable to access external storage");
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFilePath = path.join(extDir.path, "blackbox_db_backup_$timestamp.db");

      // ✅ Copy the DB file
      await dbFile.copy(backupFilePath);

      print("✅ Exported to: $backupFilePath");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Database exported to ${backupFilePath}")),
      );
    } catch (e) {
      print("❌ Failed to export database: $e");
      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text("❌ Failed to export database: $e")),
      );
    }
  }



  Future<void> exportDatabaseSaved() async {
    try {
      // ✅ Get database path dynamically
      final databasesPath = await getDatabasesPath();
      final dbPath = path.join(databasesPath, "blackbox_saved.db");
      final dbFile = File(dbPath);

      // ✅ Check if the file exists
      if (!await dbFile.exists()) {
        throw Exception("Database file does not exist at $dbPath");
      }

      // ✅ Ask for storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception("Storage permission not granted");
      }

      // ✅ Get external directory
      final Directory? extDir = await getExternalStorageDirectory();
      if (extDir == null) {
        throw Exception("Unable to access external storage");
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFilePath = path.join(extDir.path, "blackbox_db_backup_$timestamp.db");

      // ✅ Copy the DB file
      await dbFile.copy(backupFilePath);

      print("✅ Exported to: $backupFilePath");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Database exported to ${backupFilePath}")),
      );
    } catch (e) {
      print("❌ Failed to export database: $e");
      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text("❌ Failed to export database: $e")),
      );
    }
  }

  Future<void> exportDatabasen1() async {
    try {
      // Safely get the database location
      final dbDir = await getDatabasesPath();
      final dbName = "black_box.db";
      final dbPath = path.join(dbDir, dbName);

      final backupDir = await getExternalStorageDirectory();
      if (backupDir == null) throw Exception("External storage not found");

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = path.join(backupDir.path, "blackbox_db_backup_$timestamp.db");

      final originalDb = File(dbPath);
      final backupFile = File(backupPath);

      if (!await originalDb.exists()) {
        throw Exception("Database file does not exist at $dbPath");
      }

      await backupFile.writeAsBytes(await originalDb.readAsBytes());
      debugPrint("Database exported to: $backupPath");
      Get.snackbar("Success", "Database exported to:\n$backupPath");

    } catch (e) {
      debugPrint("Failed to export database: $e");
      Get.snackbar("Export Failed", e.toString());
    }
  }


  Future<void> exportDatabasen() async {
    try {
      Directory? externalDir = await getExternalStorageDirectory();

      if (externalDir == null) throw Exception("External directory not found");

      String dbName = "black_box.db";
      String dbPath = "/data/user/0/com.edu.black_box/databases/$dbName";
      String backupPath = "${externalDir.path}/blackbox_db_backup_${DateTime.now().millisecondsSinceEpoch}.db";

      File originalDb = File(dbPath);
      File backupFile = File(backupPath);

      if (await originalDb.exists()) {
        await backupFile.writeAsBytes(await originalDb.readAsBytes());
        debugPrint("Database exported to: $backupPath");
        Get.snackbar("Success", "Database exported successfully");
      } else {
        throw Exception("Database file does not exist.");
      }
    } catch (e) {
      debugPrint("Failed to export database: $e");
      Get.snackbar("Export Failed", e.toString());
    }
  }


  Future<void> exportDatabaseNot() async {
    setState(() => isLoading = true);
    try {
      String dbPath = await getDatabasePath();
      String newFileName = "blackbox_db_backup_${DateTime.now().millisecondsSinceEpoch}.db";

      Directory? directory = await getExternalStorageDirectory();
      String newPath = "${directory!.path}/$newFileName";

      File originalFile = File(dbPath);
      File backupFile = await originalFile.copy(newPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Database exported to ${backupFile.path}")),
      );
    } catch (e) {
      print("Failed to export database: $e");
      final dbPath = await getDatabasesPath();
      print("Database path: $dbPath");
      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text("Failed to export database: $e")),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> importDatabaseFile({required String targetDbName}) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    try {
      final dbDir = await getDatabasesPath();
      final targetPath = path.join(dbDir, targetDbName);
      final selectedFile = File(result.files.single.path!);

      await selectedFile.copy(targetPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Database imported successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Import failed: $e")),
      );
    }
  }


  Future<void> importDatabase() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      try {
        String dbPath = await getDatabasePath();
        File selectedFile = File(result.files.single.path!);

        await selectedFile.copy(dbPath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Database imported successfully!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to import database: $e")),
        );
      }
    }
  }

  Future<void> uploadToGoogleDrive() async {
    setState(() => isLoading = true);
    try {
      final dbPath = await getDatabasePath();
      final fileToUpload = File(dbPath);

      final credentials = ServiceAccountCredentials.fromJson(r'''
{
  "private_key_id": "b1f9eff8ba858b7cdc16fa761d63774465bafec0",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCr9t8D9bAj7tGy\nvWQcbhrSOk+ltFkaDovUXtr4LoXCCu3yRx8ixM0e6OLzWXyqzrSE7+sycpGtbE21\nSLPInPS3V8DpbaxvOGoCrCGmePeVIFP/qJg5VhOGyb0Py/0KinWk3JaLiVmAIwJf\nOm+SkkUwJrChttk1bbD/bymICx8lcVAEVr65qdCrb9Ja2hFrxdnAKb7cLNabbg3l\nareXzRutJoGP48ir1qeqyzmjPTW2LFMO5a8rNoWofLspAUR9wijh47nndK486Pju\nMr20qfbBDsItmsBgF42M2MBJDVG4QwYKiXpjS2ZX3cdCY3zLaclAusUalVg0isxO\ngBNxzCn7AgMBAAECggEASNBhoiWYDb8D3/E9wKQGi1nRe9Kfn97k6mm3wjrAvGcw\nVdQzpN88E4h9AJm1pgWcfmWwa04DzTD8vnQoXBvJqxBnSO/9gaKbkMIeBYVXIDfu\nGWTj//MolXw6p8OyQ5JZOhOFU1Q3J4CrcnMl5yQ0U60uQWtREcR+m8oQBeDfsVRV\nvBau5OUaED3J5ybUa2oSZsxdn/ZDIgJGKmA/ECQ1t9kWlyqOTDRkEQTl6/rV4rYV\nYefLdrixto6V9BR8OT+cb2bjuCOqoJ6nAd4vs9+HNhW9UR+L69oMsir3wGrJcgsr\n4tkYXfUYpf/GSMun3jlWhW3HWvgV1XnaJq1PfkTOMQKBgQDaxqZJppl87FWPramv\nR0T/9czqZyy3oM/man80rrwQ1OCMlg5ZXAhLXyMusDHRvbgBS8KqDWMzM62xKQOf\nXe/W/CKjmvJPJguWkB8spm6Yy2OnsVQWVQGAJuQyZt4DbyQxrSTGsxLfBW7/v5nF\nWMO8m42HtDgDR+ZEhNvFBjn+BwKBgQDJOThtlmTlKRoOYRezW/X51LTMOaDCTMPB\nL1Mdppini0DvMtXFmPSt+yqpzLdGsZ+VtyIVt5cPFQeaerNhECPka+6hhDeCyc3M\nC/9w7syngbeLaabMxclZSHALOR5Ltp4/vwrkcXUTz+RTFVJtpavkLSKkXWvYRvXm\nfStvlFy3bQKBgG4S8OuxpRxTlKEb0XpdM3xNYfK2QquJf9EA2EvbdshJM0nI3iNb\nyNiTX5JIGGjdOc19Hs6MudKzN7shVa9Dhj720T7b4Pqtu7rffK/sdUzvWI6xDAvI\nbV7bMomhdCbqLp3H7e8DfoUzqKuI7Yd7p9Anu8gBhwUvkc37ws+Y2GjVAoGAciaN\nxk0862tHpsSZp1wRzCpIblp6wf6+RgdMxVNO4izzJz7VWoUMuO31I+JITkhRWaNM\nKLm/bgTmDVJyFCwN0HUSKHpS61UD9C8SN8SgQJ4ru2CyCRRixs17EkLS1uzAFTWR\nPkrGufiDdEZyPlVvj7+zGT8OAOEwehKj42ZsunkCgYEAkMYH7UZchoVMuTMfRwjl\nF2xSoAM4mKYV3umDgH7ExXDUV7wVjnwwsd/a20U0tBSgFNf3lf1GIpNwi7nlztcA\nLVssqqE96AZ6A794OUgcjyISAjfp4BWrVOlC+43YC5SSepLkHRgfYMrM6GR/h/Mg\n/rV6GPQMuayxYrvwbSkHZf4=\n-----END PRIVATE KEY-----\n",
  "client_email": "blackbox@blackbox-457715.iam.gserviceaccount.com",
  "client_id": "107293831737834359102",
  "type": "service_account",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/blackbox%40blackbox-457715.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''');

      final scopes = [drive.DriveApi.driveFileScope];

      await clientViaServiceAccount(credentials, scopes).then((client) async {
        var driveApi = drive.DriveApi(client);
        var driveFile = drive.File();
        driveFile.name = "blackbox_db_${DateTime.now().millisecondsSinceEpoch}.db";

        await driveApi.files.create(
          driveFile,
          uploadMedia: drive.Media(fileToUpload.openRead(), fileToUpload.lengthSync()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Uploaded to Google Drive")),
        );
      });
    } catch (e) {
      print("Upload failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> uploadToGoogleDriveSaved() async {
    setState(() => isLoading = true);
    try {
      final dbPath = await getDatabasePathSaved();
      final fileToUpload = File(dbPath);

      final credentials = ServiceAccountCredentials.fromJson(r'''
{
  "private_key_id": "b1f9eff8ba858b7cdc16fa761d63774465bafec0",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCr9t8D9bAj7tGy\nvWQcbhrSOk+ltFkaDovUXtr4LoXCCu3yRx8ixM0e6OLzWXyqzrSE7+sycpGtbE21\nSLPInPS3V8DpbaxvOGoCrCGmePeVIFP/qJg5VhOGyb0Py/0KinWk3JaLiVmAIwJf\nOm+SkkUwJrChttk1bbD/bymICx8lcVAEVr65qdCrb9Ja2hFrxdnAKb7cLNabbg3l\nareXzRutJoGP48ir1qeqyzmjPTW2LFMO5a8rNoWofLspAUR9wijh47nndK486Pju\nMr20qfbBDsItmsBgF42M2MBJDVG4QwYKiXpjS2ZX3cdCY3zLaclAusUalVg0isxO\ngBNxzCn7AgMBAAECggEASNBhoiWYDb8D3/E9wKQGi1nRe9Kfn97k6mm3wjrAvGcw\nVdQzpN88E4h9AJm1pgWcfmWwa04DzTD8vnQoXBvJqxBnSO/9gaKbkMIeBYVXIDfu\nGWTj//MolXw6p8OyQ5JZOhOFU1Q3J4CrcnMl5yQ0U60uQWtREcR+m8oQBeDfsVRV\nvBau5OUaED3J5ybUa2oSZsxdn/ZDIgJGKmA/ECQ1t9kWlyqOTDRkEQTl6/rV4rYV\nYefLdrixto6V9BR8OT+cb2bjuCOqoJ6nAd4vs9+HNhW9UR+L69oMsir3wGrJcgsr\n4tkYXfUYpf/GSMun3jlWhW3HWvgV1XnaJq1PfkTOMQKBgQDaxqZJppl87FWPramv\nR0T/9czqZyy3oM/man80rrwQ1OCMlg5ZXAhLXyMusDHRvbgBS8KqDWMzM62xKQOf\nXe/W/CKjmvJPJguWkB8spm6Yy2OnsVQWVQGAJuQyZt4DbyQxrSTGsxLfBW7/v5nF\nWMO8m42HtDgDR+ZEhNvFBjn+BwKBgQDJOThtlmTlKRoOYRezW/X51LTMOaDCTMPB\nL1Mdppini0DvMtXFmPSt+yqpzLdGsZ+VtyIVt5cPFQeaerNhECPka+6hhDeCyc3M\nC/9w7syngbeLaabMxclZSHALOR5Ltp4/vwrkcXUTz+RTFVJtpavkLSKkXWvYRvXm\nfStvlFy3bQKBgG4S8OuxpRxTlKEb0XpdM3xNYfK2QquJf9EA2EvbdshJM0nI3iNb\nyNiTX5JIGGjdOc19Hs6MudKzN7shVa9Dhj720T7b4Pqtu7rffK/sdUzvWI6xDAvI\nbV7bMomhdCbqLp3H7e8DfoUzqKuI7Yd7p9Anu8gBhwUvkc37ws+Y2GjVAoGAciaN\nxk0862tHpsSZp1wRzCpIblp6wf6+RgdMxVNO4izzJz7VWoUMuO31I+JITkhRWaNM\nKLm/bgTmDVJyFCwN0HUSKHpS61UD9C8SN8SgQJ4ru2CyCRRixs17EkLS1uzAFTWR\nPkrGufiDdEZyPlVvj7+zGT8OAOEwehKj42ZsunkCgYEAkMYH7UZchoVMuTMfRwjl\nF2xSoAM4mKYV3umDgH7ExXDUV7wVjnwwsd/a20U0tBSgFNf3lf1GIpNwi7nlztcA\nLVssqqE96AZ6A794OUgcjyISAjfp4BWrVOlC+43YC5SSepLkHRgfYMrM6GR/h/Mg\n/rV6GPQMuayxYrvwbSkHZf4=\n-----END PRIVATE KEY-----\n",
  "client_email": "blackbox@blackbox-457715.iam.gserviceaccount.com",
  "client_id": "107293831737834359102",
  "type": "service_account",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/blackbox%40blackbox-457715.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''');

      final scopes = [drive.DriveApi.driveFileScope];

      await clientViaServiceAccount(credentials, scopes).then((client) async {
        var driveApi = drive.DriveApi(client);
        var driveFile = drive.File();
        driveFile.name = "blackboxSaved_db_${DateTime.now().millisecondsSinceEpoch}.db";

        await driveApi.files.create(
          driveFile,
          uploadMedia: drive.Media(fileToUpload.openRead(), fileToUpload.lengthSync()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Uploaded to Google Drive")),
        );
      });
    } catch (e) {
      print("Upload failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: const Text("Backup & Restore"),
        backgroundColor: Colors.deepPurple.shade400,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storage_rounded,
                  size: 90, color: Colors.deepPurple.shade200),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: exportDatabase,
                icon: const Icon(Icons.save_alt),
                label: const Text("Export Database"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade300,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 10),
              Icon(Icons.storage_rounded,
                  size: 90, color: Colors.deepPurple.shade200),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: exportDatabaseSaved,
                icon: const Icon(Icons.save_alt),
                label: const Text("Export Database Saved"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade300,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: importDatabase,
                icon: const Icon(Icons.drive_folder_upload),
                label: const Text("Import Database"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade300,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: uploadToGoogleDrive,
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Upload to Drive"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF005F73),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: uploadToGoogleDriveSaved,
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Upload to Drive(Saved)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF005F73),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
