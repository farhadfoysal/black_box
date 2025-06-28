import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/user/user.dart';
import '../model/mess/mess_main.dart';
import '../model/mess/mess_user.dart';
import '../model/school/school.dart';
import '../model/school/teacher.dart';
import '../preference/logout.dart';

class DatabaseBackup extends StatefulWidget {
  const DatabaseBackup({Key? key}) : super(key: key);

  @override
  State<DatabaseBackup> createState() => _DatabaseBackupScreenState();
}

class _DatabaseBackupScreenState extends State<DatabaseBackup> {

  late StreamSubscription _streamSubscription;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool isConnected = false;

  internetConnection()=> _streamSubscription = Connectivity().onConnectivityChanged.listen((result) async {
    isConnected = await InternetConnectionChecker.instance.hasConnection;
    if(!isConnected){
      showConnectivitySnackBar(isConnected);
    }else{
      showConnectivitySnackBar(isConnected);
    }
  });

  // final _auth = FirebaseAuth.instance;
  final _databaseRef = FirebaseDatabase.instance.ref();

  final messName = TextEditingController();
  final messPhone = TextEditingController();
  final messAddress = TextEditingController();
  final messCode = TextEditingController();
  final messPassword = TextEditingController();

  bool isJoining = false; // Toggle between create and join forms
  String _userName = 'Farhad Foysal';
  String? userName;
  String? userPhone;
  String? userEmail;
  User? _user, _user_data;
  MessUser? messUser, _mess_user_data;
  MessMain? messMain;
  String? sid;
  String? messId;
  School? school;
  Teacher? teacher;
  File? _selectedImage;
  bool _showSaveButton = false;
  late TabController _tabController;
  int _currentIndex1 = 0;
  int _currentIndex2 = 0;
  DateTime selectedDate = DateTime.now();
  String? selectedMonthYear;


  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initializeData();
    internetConnection();
  }

  Future<void> _loadUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUserData = prefs.getString('user_logged_in');

    if (savedUserData != null) {
      Map<String, dynamic> userData = jsonDecode(savedUserData);
      setState(() {
        _userName = userData['uname'] ?? 'Tasnim';
      });
    }
  }

  Future<void> _loadUserData() async {
    Logout logout = Logout();
    User? user = await logout.getUserDetails(key: 'user_data');

    Map<String, dynamic>? userMap = await logout.getUser(key: 'user_logged_in');
    Map<String, dynamic>? schoolMap =
    await logout.getSchool(key: 'school_data');

    if (userMap != null) {
      User user_data = User.fromMap(userMap);
      setState(() {
        _user_data = user_data;
        _user = user_data;
      });
    } else {
      print("User map is null");
    }

    if (schoolMap != null) {
      School schoolData = School.fromMap(schoolMap);
      setState(() {
        _user = user;
        school = schoolData;
        sid = school?.sId;
        print(schoolData.sId);
      });
    } else {
      print("School data is null");
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('user_logged_in');
    String? imagePath = prefs.getString('profile_picture-${_user?.uniqueid!}');

    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      setState(() {
        userName = userData['uname'];
        userPhone = userData['phone'];
        userEmail = userData['email'];
        if (imagePath != null) {
          _selectedImage = File(imagePath);
        }
      });
    }
  }

  Future<void> _initializeData() async {
    // First load user data
    await _loadUserData();
    // await _loadMessUserData();


  }

  void showConnectivitySnackBar(bool isOnline) {
    final message = isOnline ? "Internet Connected" : "Internet Not Connected";
    final color = isOnline ? Colors.green : Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }



  String selectedDb = 'black_box.db';
  final List<String> dbOptions = ['black_box.db', 'blackbox_saved.db'];

  Future<void> exportDatabaseFile(String dbName) async {
    try {
      final dbDir = await getDatabasesPath();
      final dbPath = path.join(dbDir, dbName);
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) throw Exception("Database file not found.");

      final permission = await Permission.storage.request();
      if (!permission.isGranted) throw Exception("Permission denied.");

      final extDir = await getExternalStorageDirectory();
      if (extDir == null) throw Exception("External storage not available.");

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

  Future<void> importDatabase(String targetDbName) async {
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

  Future<void> uploadToDrive() async {
    try {
      final credentials = await rootBundle.loadString('assets/credentials.json');
      final credentialsJson = json.decode(credentials);

      final clientId = ClientId(credentialsJson['client_id'], credentialsJson['client_secret']);
      final serviceAccountCredentials = ServiceAccountCredentials.fromJson(credentials);

      final authClient = await clientViaServiceAccount(
        serviceAccountCredentials,
        [drive.DriveApi.driveFileScope],
      );

      final driveApi = drive.DriveApi(authClient);

      final dbPath = path.join(await getDatabasesPath(), selectedDb);
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) throw Exception("Database not found.");

      final media = drive.Media(dbFile.openRead(), await dbFile.length());
      final driveFile = drive.File()
        ..name = "${selectedDb}_${DateTime.now().millisecondsSinceEpoch}.db"
        ..parents = ["1lvKdKsBXJQUuxTeMn06oWsL2v4rzceVd"];
      // https://drive.google.com/drive/folders/15SMvnjyjhkPv7htmXaNQQQSo052J1X5D?usp=sharing

      final uploadedFile =  await driveApi.files.create(driveFile, uploadMedia: media);

      await driveApi.permissions.create(
        drive.Permission()
          ..type = "user"
          ..role = "writer" // or "reader"
          ..emailAddress = "${_user?.email ?? 'farhad.foysal.main@gmail.com'}", // 🔁 Replace with your Gmail
        uploadedFile.id!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Uploaded to Google Drive!")),
      );
      showDriveLinkDialog(context, uploadedFile.id!);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Upload failed: $e")),
      );
    }
  }

  Future<void> uploadAllDbsToDrive() async {
    try {
      final credentials = await rootBundle.loadString('assets/credentials.json');
      final credentialsJson = json.decode(credentials);

      final serviceAccountCredentials = ServiceAccountCredentials.fromJson(credentials);
      final authClient = await clientViaServiceAccount(
        serviceAccountCredentials,
        [drive.DriveApi.driveFileScope],
      );
      final driveApi = drive.DriveApi(authClient);

      final dbDirPath = await getDatabasesPath();
      final dbDir = Directory(dbDirPath);
      final dbFiles = dbDir
          .listSync()
          .where((f) => f is File && f.path.endsWith(".db"))
          .cast<File>()
          .toList();

      if (dbFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No database files found.")),
        );
        return;
      }

      for (final dbFile in dbFiles) {
        final fileName = path.basename(dbFile.path);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final driveFile = drive.File()
          ..name = "${fileName}_$timestamp"
          ..parents = ["1lvKdKsBXJQUuxTeMn06oWsL2v4rzceVd"];
        // https://drive.google.com/drive/folders/15SMvnjyjhkPv7htmXaNQQQSo052J1X5D?usp=sharing
        final media = drive.Media(dbFile.openRead(), await dbFile.length());
        // https://drive.google.com/drive/folders/1lvKdKsBXJQUuxTeMn06oWsL2v4rzceVd?usp=sharing
        final uploadedFile = await driveApi.files.create(driveFile, uploadMedia: media);

        await driveApi.permissions.create(
          drive.Permission()
            ..type = "user"
            ..role = "writer" // or "reader"
            ..emailAddress = "${_user?.email ?? 'farhad.foysal.main@gmail.com'}", // 🔁 Replace with your Gmail
          uploadedFile.id!,
        );
        print("File uploaded: https://drive.google.com/file/d/${uploadedFile.id}/view");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Uploaded: $fileName")),
        );
        showDriveLinkDialog(context, uploadedFile.id!);

      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Upload failed: $e")),
      );
    }
  }

  void showDriveLinkDialog(BuildContext context, String fileId) {
    final fileUrl = "https://drive.google.com/file/d/$fileId/view";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Uploaded to Drive"),
          content: Text(fileUrl),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: fileUrl));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("🔗 Link copied to clipboard!")),
                );
              },
              child: const Text("Copy Link"),
            ),
            TextButton(
              onPressed: () async {
                final uri = Uri.parse(fileUrl);
                if (await canLaunchUrl(uri)) {
                  final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
                  if (!launched) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("❌ Failed to launch URL.")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("❌ Could not open link")),
                  );
                }
              },
              child: const Text("Open in Browser"),
            )

            // TextButton(
            //   onPressed: () async {
            //     final uri = Uri.parse(fileUrl);
            //     if (await canLaunchUrl(uri)) {
            //       await launchUrl(uri, mode: LaunchMode.externalApplication);
            //     } else {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(content: Text("❌ Could not open link")),
            //       );
            //     }
            //   },
            //   child: const Text("Open in Browser"),
            // ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Database Backup & Restore"),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Database", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedDb,
              items: dbOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => selectedDb = val!),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => exportDatabaseFile(selectedDb),
              icon: const Icon(Icons.upload_file),
              label: const Text("Export to Local Storage"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => importDatabase(selectedDb),
              icon: const Icon(Icons.file_download),
              label: const Text("Import from File"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: uploadToDrive,
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Upload to Google Drive"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: uploadAllDbsToDrive,
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Upload All DBs to Google Drive"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Note: Make sure you have granted file access permissions before using these features.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          ],
        ),
      ),
    );
  }
}
