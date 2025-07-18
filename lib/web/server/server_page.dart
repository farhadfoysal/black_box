import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'file_transfer.dart';

class ServerPage extends StatefulWidget {
  @override
  _ServerPageState createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> with SingleTickerProviderStateMixin {
  late FileTransferServer _fileServer;
  String? _serverIp;
  bool _isServerRunning = false;
  bool _hasStoragePermission = false;
  bool _isScanning = false;

  // Categorized file lists
  final List<FileSystemEntity> _photos = [];
  final List<FileSystemEntity> _videos = [];
  final List<FileSystemEntity> _documents = [];
  final List<FileSystemEntity> _otherFiles = [];

  // Tab controller
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Track which categories have been loaded
  final Map<String, bool> _loadedCategories = {
    'photos': false,
    'videos': false,
    'documents': false,
    'others': false,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _initServer();
    _checkPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      _loadFilesForCurrentTab();
    }
  }

  Future<void> _loadFilesForCurrentTab() async {
    if (!_isServerRunning || !_hasStoragePermission) return;

    String category;
    switch (_currentTabIndex) {
      case 0:
        category = 'photos';
        break;
      case 1:
        category = 'videos';
        break;
      case 2:
        category = 'documents';
        break;
      case 3:
        category = 'others';
        break;
      default:
        return;
    }

    // Only load if not already loaded
    if (!_loadedCategories[category]!) {
      await _scanAvailableFiles(category);
    }
  }

  Future<void> _checkPermissions() async {
    var storageStatus = await Permission.storage.status;
    var manageExternalStatus = await Permission.manageExternalStorage.status;

    if (!storageStatus.isGranted) {
      storageStatus = await Permission.storage.request();
    }
    if (!manageExternalStatus.isGranted) {
      manageExternalStatus = await Permission.manageExternalStorage.request();
    }

    setState(() {
      _hasStoragePermission = storageStatus.isGranted && manageExternalStatus.isGranted;
    });
  }

  Future<void> _initServer() async {
    _fileServer = FileTransferServer();
  }

  Future<void> _toggleServer() async {
    if (_isServerRunning) {
      await _stopServer();
    } else {
      await _startServer();
    }
  }

  Future<void> _startServer() async {
    try {
      if (!_hasStoragePermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permissions are required to share files')),
        );
        return;
      }

      await _fileServer.start();
      _serverIp = await _getLocalIpAddress();

      setState(() {
        _isServerRunning = true;
      });

      // Load initial tab (Photos)
      await _loadFilesForCurrentTab();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server running at $_serverIp:${_fileServer.port}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start server: $e')),
      );
    }
  }

  Future<void> _stopServer() async {
    await _fileServer.stop();
    setState(() {
      _isServerRunning = false;
      _serverIp = null;
    });
  }

  Future<String?> _getLocalIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting IP: $e');
    }
    return null;
  }

  Future<void> _scanAvailableFiles(String category) async {
    if (!_hasStoragePermission) return;

    setState(() {
      _isScanning = true;
    });

    try {
      final List<Directory> targetDirs = [];
      final externalStorage = await getExternalStorageDirectory();

      if (externalStorage != null) {
        final parentDir = externalStorage.parent.parent.parent;
        targetDirs.addAll([
          Directory('${parentDir.path}/DCIM'),
          Directory('${parentDir.path}/DCIM/Camera'),
          Directory('${parentDir.path}/Pictures'),
          Directory('${parentDir.path}/Download'),
          Directory('${parentDir.path}/Downloads'),
        ]);
      }

      targetDirs.addAll([
        Directory('/storage/emulated/0/DCIM'),
        Directory('/storage/emulated/0/DCIM/Camera'),
        Directory('/storage/emulated/0/Pictures'),
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/Downloads'),
      ]);

      // Clear only the current category
      switch (category) {
        case 'photos':
          _photos.clear();
          break;
        case 'videos':
          _videos.clear();
          break;
        case 'documents':
          _documents.clear();
          break;
        case 'others':
          _otherFiles.clear();
          break;
      }

      for (var dir in targetDirs) {
        if (await dir.exists()) {
          try {
            await _scanAndCategorizeDirectory(dir, category);
          } catch (e) {
            print('Error scanning ${dir.path}: $e');
          }
        }
      }

      // Sort the current category
      switch (category) {
        case 'photos':
          _photos.sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));
          break;
        case 'videos':
          _videos.sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));
          break;
        case 'documents':
          _documents.sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));
          break;
        case 'others':
          _otherFiles.sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));
          break;
      }

      // Mark category as loaded
      _loadedCategories[category] = true;

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning files: $e')),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _scanAndCategorizeDirectory(Directory dir, String category) async {
    try {
      final entities = await dir.list().toList();
      for (var entity in entities) {
        if (entity is File) {
          _categorizeFile(entity, category);
        } else if (entity is Directory) {
          await _scanAndCategorizeDirectory(entity, category);
        }
      }
    } catch (e) {
      print('Error scanning ${dir.path}: $e');
    }
  }

  void _categorizeFile(File file, String category) {
    final ext = path.extension(file.path).toLowerCase();
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.flv', '.wmv'];
    final docExtensions = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'];

    if (category == 'photos' && imageExtensions.contains(ext)) {
      _photos.add(file);
    } else if (category == 'videos' && videoExtensions.contains(ext)) {
      _videos.add(file);
    } else if (category == 'documents' && docExtensions.contains(ext)) {
      _documents.add(file);
    } else if (category == 'others' &&
        !imageExtensions.contains(ext) &&
        !videoExtensions.contains(ext) &&
        !docExtensions.contains(ext)) {
      _otherFiles.add(file);
    }
  }

  Widget _buildFileList(List<FileSystemEntity> files) {
    if (_isScanning) {
      return Center(child: CircularProgressIndicator());
    }

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No files found',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: BouncingScrollPhysics(),
      itemCount: files.length,
      itemBuilder: (ctx, i) {
        final file = files[i];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: _getFileIcon(file),
            title: Text(path.basename(file.path)),
            subtitle: Text(file.path),
            trailing: IconButton(
              icon: Icon(Icons.share),
              onPressed: () => _shareFile(file),
            ),
          ),
        );
      },
    );
  }

  Widget _getFileIcon(FileSystemEntity file) {
    if (file is Directory) return Icon(Icons.folder);

    final ext = path.extension(file.path).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif'].contains(ext)) {
      return Icon(Icons.image, color: Colors.blue);
    } else if (['.mp4', '.mov', '.avi'].contains(ext)) {
      return Icon(Icons.video_file, color: Colors.red);
    } else if (['.pdf'].contains(ext)) {
      return Icon(Icons.picture_as_pdf, color: Colors.orange);
    } else if (['.doc', '.docx'].contains(ext)) {
      return Icon(Icons.description, color: Colors.blue);
    }
    return Icon(Icons.insert_drive_file, color: Colors.grey);
  }


  Future<void> _shareFile(FileSystemEntity file) async {
    try {
      // Check if the file exists
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File not found: ${path.basename(file.path)}')),
        );
        return;
      }

      final fileName = path.basename(file.path);

      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing to share $fileName...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Prepare the file for sharing
      final files = [XFile(file.path)];

      // Share the file
      await Share.shareXFiles(
        files,
        text: 'Check out this file: $fileName',
        subject: 'File shared via File Share App',
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share file: ${e.toString()}')),
      );
    }
  }

  String get _connectionString => 'http://$_serverIp:${_fileServer.port}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Share Server'),
        actions: [
          if (_isServerRunning && _serverIp != null)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => _scanAvailableFiles(
                  ['photos', 'videos', 'documents', 'others'][_currentTabIndex]),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.photo), text: 'Photos'),
            Tab(icon: Icon(Icons.video_library), text: 'Videos'),
            Tab(icon: Icon(Icons.description), text: 'Documents'),
            Tab(icon: Icon(Icons.insert_drive_file), text: 'Others'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Server Status'),
              subtitle: Text(_isServerRunning ? 'Running on $_serverIp' : 'Stopped'),
              value: _isServerRunning,
              onChanged: (_) => _toggleServer(),
              secondary: Icon(_isServerRunning ? Icons.cloud : Icons.cloud_off),
            ),
            if (_isServerRunning && _serverIp != null) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text('Server Information', style: Theme.of(context).textTheme.headlineLarge),
                            SizedBox(height: 10),
                            Text('IP: $_serverIp', style: TextStyle(fontSize: 16)),
                            Text('Port: ${_fileServer.port}', style: TextStyle(fontSize: 16)),
                            SizedBox(height: 16),
                            QrImageView(
                              data: _connectionString,
                              version: QrVersions.auto,
                              size: 180.0,
                              backgroundColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(),
            ],
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFileList(_photos),
                  _buildFileList(_videos),
                  _buildFileList(_documents),
                  _buildFileList(_otherFiles),
                ],
              ),
            ),
            if (!_hasStoragePermission)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _checkPermissions,
                  child: Text('Grant Permissions'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:path/path.dart' as path;
// import 'file_transfer.dart';
//
// class ServerPage extends StatefulWidget {
//   @override
//   _ServerPageState createState() => _ServerPageState();
// }
//
// class _ServerPageState extends State<ServerPage> {
//   late FileTransferServer _fileServer;
//   String? _serverIp;
//   bool _isServerRunning = false;
//   bool _hasStoragePermission = false;
//   bool _isScanning = false;
//
//   // Categorized file lists
//   final List<FileSystemEntity> _photos = [];
//   final List<FileSystemEntity> _videos = [];
//   final List<FileSystemEntity> _documents = [];
//   final List<FileSystemEntity> _otherFiles = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _initServer();
//     _checkPermissions();
//   }
//
//   Future<void> _checkPermissions() async {
//     var storageStatus = await Permission.storage.status;
//     var manageExternalStatus = await Permission.manageExternalStorage.status;
//
//     if (!storageStatus.isGranted) {
//       storageStatus = await Permission.storage.request();
//     }
//     if (!manageExternalStatus.isGranted) {
//       manageExternalStatus = await Permission.manageExternalStorage.request();
//     }
//
//     setState(() {
//       _hasStoragePermission = storageStatus.isGranted && manageExternalStatus.isGranted;
//     });
//   }
//
//   Future<void> _initServer() async {
//     _fileServer = FileTransferServer();
//   }
//
//   Future<void> _toggleServer() async {
//     if (_isServerRunning) {
//       await _stopServer();
//     } else {
//       await _startServer();
//     }
//   }
//
//   Future<void> _startServer() async {
//     try {
//       if (!_hasStoragePermission) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Storage permissions are required to share files')),
//         );
//         return;
//       }
//
//       await _fileServer.start();
//       _serverIp = await _getLocalIpAddress();
//
//       setState(() {
//         _isServerRunning = true;
//       });
//
//       await _scanAvailableFiles();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Server running at $_serverIp:${_fileServer.port}')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to start server: $e')),
//       );
//     }
//   }
//
//   Future<void> _stopServer() async {
//     await _fileServer.stop();
//     setState(() {
//       _isServerRunning = false;
//       _serverIp = null;
//     });
//   }
//
//   Future<String?> _getLocalIpAddress() async {
//     try {
//       for (var interface in await NetworkInterface.list()) {
//         for (var addr in interface.addresses) {
//           if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
//             return addr.address;
//           }
//         }
//       }
//     } catch (e) {
//       print('Error getting IP: $e');
//     }
//     return null;
//   }
//
//   Future<void> _scanAvailableFiles() async {
//     if (!_hasStoragePermission) return;
//
//     setState(() {
//       _isScanning = true;
//       _photos.clear();
//       _videos.clear();
//       _documents.clear();
//       _otherFiles.clear();
//     });
//
//     try {
//       final List<Directory> targetDirs = [];
//       final externalStorage = await getExternalStorageDirectory();
//
//       if (externalStorage != null) {
//         final parentDir = externalStorage.parent.parent.parent;
//         targetDirs.addAll([
//           Directory('${parentDir.path}/DCIM'),
//           Directory('${parentDir.path}/DCIM/Camera'),
//           Directory('${parentDir.path}/Pictures'),
//           Directory('${parentDir.path}/Download'),
//           Directory('${parentDir.path}/Downloads'),
//         ]);
//       }
//
//       targetDirs.addAll([
//         Directory('/storage/emulated/0/DCIM'),
//         Directory('/storage/emulated/0/DCIM/Camera'),
//         Directory('/storage/emulated/0/Pictures'),
//         Directory('/storage/emulated/0/Download'),
//         Directory('/storage/emulated/0/Downloads'),
//       ]);
//
//       for (var dir in targetDirs) {
//         if (await dir.exists()) {
//           try {
//             await _scanAndCategorizeDirectory(dir);
//           } catch (e) {
//             print('Error scanning ${dir.path}: $e');
//           }
//         }
//       }
//
//       _sortFilesByCategory();
//
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error scanning files: $e')),
//       );
//     } finally {
//       setState(() {
//         _isScanning = false;
//       });
//     }
//   }
//
//   Future<void> _scanAndCategorizeDirectory(Directory dir) async {
//     try {
//       final entities = await dir.list().toList();
//       for (var entity in entities) {
//         if (entity is File) {
//           _categorizeFile(entity);
//         } else if (entity is Directory) {
//           await _scanAndCategorizeDirectory(entity);
//         }
//       }
//     } catch (e) {
//       print('Error scanning ${dir.path}: $e');
//     }
//   }
//
//   void _categorizeFile(File file) {
//     final ext = path.extension(file.path).toLowerCase();
//     final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
//     final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.flv', '.wmv'];
//     final docExtensions = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'];
//
//     if (imageExtensions.contains(ext)) {
//       _photos.add(file);
//     } else if (videoExtensions.contains(ext)) {
//       _videos.add(file);
//     } else if (docExtensions.contains(ext)) {
//       _documents.add(file);
//     } else {
//       _otherFiles.add(file);
//     }
//   }
//
//   void _sortFilesByCategory() {
//     _photos.sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));
//     _videos.sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));
//     _documents.sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));
//     _otherFiles.sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));
//   }
//
//   Widget _buildCategorySection(String title, List<FileSystemEntity> files, IconData icon) {
//     if (files.isEmpty) return SizedBox.shrink();
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             children: [
//               Icon(icon, color: Colors.blue),
//               SizedBox(width: 8),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//               SizedBox(width: 8),
//               Chip(
//                 label: Text('${files.length}'),
//                 backgroundColor: Colors.blue.withOpacity(0.2),
//               ),
//             ],
//           ),
//         ),
//         ListView.builder(
//           shrinkWrap: true,
//           physics: NeverScrollableScrollPhysics(),
//           itemCount: files.length,
//           itemBuilder: (ctx, i) {
//             final file = files[i];
//             return Card(
//               margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               child: ListTile(
//                 leading: _getFileIcon(file),
//                 title: Text(path.basename(file.path)),
//                 subtitle: Text(file.path),
//                 trailing: IconButton(
//                   icon: Icon(Icons.share),
//                   onPressed: () => _shareFile(file),
//                 ),
//               ),
//             );
//           },
//         ),
//         Divider(),
//       ],
//     );
//   }
//
//   Widget _getFileIcon(FileSystemEntity file) {
//     if (file is Directory) return Icon(Icons.folder);
//
//     final ext = path.extension(file.path).toLowerCase();
//     if (['.jpg', '.jpeg', '.png', '.gif'].contains(ext)) {
//       return Icon(Icons.image);
//     } else if (['.mp4', '.mov', '.avi'].contains(ext)) {
//       return Icon(Icons.video_file);
//     } else if (['.pdf'].contains(ext)) {
//       return Icon(Icons.picture_as_pdf);
//     } else if (['.doc', '.docx'].contains(ext)) {
//       return Icon(Icons.description);
//     }
//     return Icon(Icons.insert_drive_file);
//   }
//
//   void _shareFile(FileSystemEntity file) {
//     // Implement file sharing logic here
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Sharing ${path.basename(file.path)}')),
//     );
//   }
//
//   String get _connectionString => 'http://$_serverIp:${_fileServer.port}';
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('File Share Server'),
//         actions: [
//           if (_isServerRunning && _serverIp != null)
//             IconButton(
//               icon: Icon(Icons.refresh),
//               onPressed: _scanAvailableFiles,
//             ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             SwitchListTile(
//               title: Text('Server Status'),
//               subtitle: Text(_isServerRunning ? 'Running on $_serverIp' : 'Stopped'),
//               value: _isServerRunning,
//               onChanged: (_) => _toggleServer(),
//               secondary: Icon(_isServerRunning ? Icons.cloud : Icons.cloud_off),
//             ),
//             if (_isServerRunning && _serverIp != null) ...[
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     Card(
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           children: [
//                             Text('Server Information', style: Theme.of(context).textTheme.headlineLarge),
//                             SizedBox(height: 10),
//                             Text('IP: $_serverIp', style: TextStyle(fontSize: 16)),
//                             Text('Port: ${_fileServer.port}', style: TextStyle(fontSize: 16)),
//                             SizedBox(height: 16),
//                             QrImageView(
//                               data: _connectionString,
//                               version: QrVersions.auto,
//                               size: 180.0,
//                               backgroundColor: Colors.white,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Divider(),
//             ],
//             if (_isScanning)
//               Center(child: CircularProgressIndicator())
//             else if (_photos.isNotEmpty || _videos.isNotEmpty || _documents.isNotEmpty || _otherFiles.isNotEmpty) ...[
//               _buildCategorySection('Photos', _photos, Icons.photo),
//               _buildCategorySection('Videos', _videos, Icons.video_library),
//               _buildCategorySection('Documents', _documents, Icons.description),
//               _buildCategorySection('Other Files', _otherFiles, Icons.insert_drive_file),
//             ] else
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     Icon(Icons.folder_open, size: 64, color: Colors.grey),
//                     SizedBox(height: 16),
//                     Text(
//                       'No files found or permission not granted',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                     if (!_hasStoragePermission)
//                       ElevatedButton(
//                         onPressed: _checkPermissions,
//                         child: Text('Grant Permissions'),
//                       ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:path/path.dart' as path;
//
// import 'file_transfer.dart';
//
// class ServerPage extends StatefulWidget {
//   @override
//   _ServerPageState createState() => _ServerPageState();
// }
//
// class _ServerPageState extends State<ServerPage> {
//   late FileTransferServer _fileServer;
//   String? _serverIp;
//   bool _isServerRunning = false;
//   final List<FileSystemEntity> _availableFiles = [];
//   bool _hasStoragePermission = false;
//   bool _isScanning = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initServer();
//     _checkPermissions();
//   }
//
//   Future<void> _checkPermissions() async {
//     // Request both storage and manage external storage permissions
//     var storageStatus = await Permission.storage.status;
//     var manageExternalStatus = await Permission.manageExternalStorage.status;
//
//     if (!storageStatus.isGranted) {
//       storageStatus = await Permission.storage.request();
//     }
//     if (!manageExternalStatus.isGranted) {
//       manageExternalStatus = await Permission.manageExternalStorage.request();
//     }
//
//     setState(() {
//       _hasStoragePermission = storageStatus.isGranted && manageExternalStatus.isGranted;
//     });
//   }
//
//   Future<void> _initServer() async {
//     _fileServer = FileTransferServer();
//   }
//
//   Future<void> _toggleServer() async {
//     if (_isServerRunning) {
//       await _stopServer();
//     } else {
//       await _startServer();
//     }
//   }
//
//   Future<void> _startServer() async {
//     try {
//       if (!_hasStoragePermission) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Storage permissions are required to share files')),
//         );
//         return;
//       }
//
//       await _fileServer.start();
//       _serverIp = await _getLocalIpAddress();
//
//       setState(() {
//         _isServerRunning = true;
//       });
//
//       await _scanAvailableFiles();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Server running at $_serverIp:${_fileServer.port}')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to start server: $e')),
//       );
//     }
//   }
//
//   Future<void> _stopServer() async {
//     await _fileServer.stop();
//     setState(() {
//       _isServerRunning = false;
//       _serverIp = null;
//     });
//   }
//
//   Future<String?> _getLocalIpAddress() async {
//     try {
//       for (var interface in await NetworkInterface.list()) {
//         for (var addr in interface.addresses) {
//           if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
//             return addr.address;
//           }
//         }
//       }
//     } catch (e) {
//       print('Error getting IP: $e');
//     }
//     return null;
//   }
//
//   Future<void> _scanAvailableFiles() async {
//     if (!_hasStoragePermission) return;
//
//     setState(() {
//       _isScanning = true;
//       _availableFiles.clear();
//     });
//
//     try {
//       // Get common directories
//       final List<Directory> roots = [];
//
//       // Internal storage
//       final appDir = await getApplicationDocumentsDirectory();
//       roots.add(Directory(appDir.parent.parent.parent.path));
//
//       // External storage (SD card)
//       final externalDirs = await getExternalStorageDirectories();
//       if (externalDirs != null && externalDirs.isNotEmpty) {
//         for (var dir in externalDirs) {
//           roots.add(Directory(dir.parent.parent.parent.path));
//         }
//       }
//
//       // Add standard directories
//       roots.addAll([
//         Directory('/storage/emulated/0'), // Main storage
//         Directory('/storage'), // All storage devices
//         Directory('/sdcard'), // Common symlink to storage
//       ]);
//
//       // Scan each root directory
//       for (var root in roots) {
//         if (await root.exists()) {
//           try {
//             await _scanDirectory(root, _availableFiles, maxDepth: 2);
//           } catch (e) {
//             print('Error scanning ${root.path}: $e');
//           }
//         }
//       }
//
//       // Sort files by name
//       _availableFiles.sort((a, b) => path.basename(a.path).toLowerCase().compareTo(path.basename(b.path).toLowerCase()));
//
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error scanning files: $e')),
//       );
//     } finally {
//       setState(() {
//         _isScanning = false;
//       });
//     }
//   }
//
//   Future<void> _scanDirectory(Directory dir, List<FileSystemEntity> files, {int maxDepth = 2, int currentDepth = 0}) async {
//     if (currentDepth > maxDepth) return;
//
//     try {
//       final entities = await dir.list().toList();
//       for (var entity in entities) {
//         if (entity is File) {
//           files.add(entity);
//         } else if (entity is Directory) {
//           await _scanDirectory(entity, files, maxDepth: maxDepth, currentDepth: currentDepth + 1);
//         }
//       }
//     } catch (e) {
//       print('Error scanning ${dir.path}: $e');
//     }
//   }
//
//   String get _connectionString => 'http://$_serverIp:${_fileServer.port}';
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('File Share Server'),
//         actions: [
//           if (_isServerRunning && _serverIp != null)
//             IconButton(
//               icon: Icon(Icons.refresh),
//               onPressed: _scanAvailableFiles,
//             ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             SwitchListTile(
//               title: Text('Server Status'),
//               subtitle: Text(_isServerRunning ? 'Running on $_serverIp' : 'Stopped'),
//               value: _isServerRunning,
//               onChanged: (_) => _toggleServer(),
//               secondary: Icon(_isServerRunning ? Icons.cloud : Icons.cloud_off),
//             ),
//             if (_isServerRunning && _serverIp != null) ...[
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     Card(
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           children: [
//                             Text('Server Information', style: Theme.of(context).textTheme.headlineLarge),
//                             SizedBox(height: 10),
//                             Text('IP: $_serverIp', style: TextStyle(fontSize: 16)),
//                             Text('Port: ${_fileServer.port}', style: TextStyle(fontSize: 16)),
//                             SizedBox(height: 16),
//                             QrImageView(
//                               data: _connectionString,
//                               version: QrVersions.auto,
//                               size: 180.0,
//                               backgroundColor: Colors.white,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Divider(),
//             ],
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Text('Available Files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             ),
//             if (_isScanning)
//               Center(child: CircularProgressIndicator())
//             else if (_availableFiles.isNotEmpty)
//               ListView.builder(
//                 shrinkWrap: true,
//                 physics: NeverScrollableScrollPhysics(),
//                 itemCount: _availableFiles.length,
//                 itemBuilder: (ctx, i) {
//                   final entity = _availableFiles[i];
//                   final isFile = entity is File;
//                   return Card(
//                     margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     child: ListTile(
//                       leading: Icon(isFile ? Icons.insert_drive_file : Icons.folder),
//                       title: Text(path.basename(entity.path)),
//                       subtitle: Text(entity.path),
//                       trailing: isFile
//                           ? IconButton(
//                         icon: Icon(Icons.share),
//                         onPressed: () {
//                           // Implement file sharing
//                         },
//                       )
//                           : null,
//                       onTap: () {
//                         if (entity is Directory) {
//                           // Implement directory navigation
//                         }
//                       },
//                     ),
//                   );
//                 },
//               )
//             else
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     Icon(Icons.folder_open, size: 64, color: Colors.grey),
//                     SizedBox(height: 16),
//                     Text(
//                       'No files found or permission not granted',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                     if (!_hasStoragePermission)
//                       ElevatedButton(
//                         onPressed: _checkPermissions,
//                         child: Text('Grant Permissions'),
//                       ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// import 'file_transfer.dart';
//
// class ServerPage extends StatefulWidget {
//   @override
//   _ServerPageState createState() => _ServerPageState();
// }
//
// class _ServerPageState extends State<ServerPage> {
//   late FileTransferServer _fileServer;
//   String? _serverIp;
//   bool _isServerRunning = false;
//   final List<String> _availableFiles = [];
//   bool _hasStoragePermission = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initServer();
//     _checkPermissions();
//   }
//
//   Future<void> _checkPermissions() async {
//     var status = await Permission.storage.status;
//     if (!status.isGranted) {
//       status = await Permission.storage.request();
//     }
//     setState(() {
//       _hasStoragePermission = status.isGranted;
//     });
//   }
//
//   Future<void> _initServer() async {
//     _fileServer = FileTransferServer();
//   }
//
//   Future<void> _toggleServer() async {
//     if (_isServerRunning) {
//       await _stopServer();
//     } else {
//       await _startServer();
//     }
//   }
//
//   Future<void> _startServer() async {
//     try {
//       if (!_hasStoragePermission) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Storage permission is required to share files')),
//         );
//         return;
//       }
//
//       await _fileServer.start();
//       _serverIp = await _getLocalIpAddress();
//
//       setState(() {
//         _isServerRunning = true;
//       });
//
//       // Scan for available files
//       await _scanAvailableFiles();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Server running at $_serverIp:${_fileServer.port}')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to start server: $e')),
//       );
//     }
//   }
//
//   Future<void> _stopServer() async {
//     await _fileServer.stop();
//     setState(() {
//       _isServerRunning = false;
//       _serverIp = null;
//     });
//   }
//
//   Future<String?> _getLocalIpAddress() async {
//     try {
//       for (var interface in await NetworkInterface.list()) {
//         for (var addr in interface.addresses) {
//           if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
//             return addr.address;
//           }
//         }
//       }
//     } catch (e) {
//       print('Error getting IP: $e');
//     }
//     return null;
//   }
//
//   Future<void> _scanAvailableFiles() async {
//     if (!_hasStoragePermission) return;
//
//     // Get root directories
//     final List<Directory> roots = [];
//
//     // Add internal storage
//     final appDir = await getApplicationDocumentsDirectory();
//     roots.add(Directory(appDir.parent.parent.parent.path));
//
//     // Add external storage if available
//     try {
//       final externalDirs = await getExternalStorageDirectories();
//       if (externalDirs != null && externalDirs.isNotEmpty) {
//         for (var dir in externalDirs) {
//           roots.add(Directory(dir.parent.parent.parent.path));
//         }
//       }
//     } catch (e) {
//       print('Error getting external storage: $e');
//     }
//
//     // Scan files recursively (with depth limit for performance)
//     final List<String> files = [];
//     for (var root in roots) {
//       try {
//         await _scanDirectory(root, files, maxDepth: 3);
//       } catch (e) {
//         print('Error scanning directory ${root.path}: $e');
//       }
//     }
//
//     setState(() {
//       _availableFiles.clear();
//       _availableFiles.addAll(files);
//     });
//   }
//
//   Future<void> _scanDirectory(Directory dir, List<String> files, {int maxDepth = 3, int currentDepth = 0}) async {
//     if (currentDepth > maxDepth) return;
//
//     try {
//       await for (var entity in dir.list(recursive: false)) {
//         if (entity is File) {
//           files.add(entity.path);
//         } else if (entity is Directory) {
//           await _scanDirectory(entity, files, maxDepth: maxDepth, currentDepth: currentDepth + 1);
//         }
//       }
//     } catch (e) {
//       print('Error scanning ${dir.path}: $e');
//     }
//   }
//
//   String get _connectionString => 'http://$_serverIp:${_fileServer.port}';
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('File Share Server')),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             SwitchListTile(
//               title: Text('Server Status'),
//               value: _isServerRunning,
//               onChanged: (_) => _toggleServer(),
//             ),
//             if (_isServerRunning && _serverIp != null) ...[
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     Text('Server IP: $_serverIp', style: TextStyle(fontSize: 16)),
//                     Text('Port: ${_fileServer.port}', style: TextStyle(fontSize: 16)),
//                     SizedBox(height: 16),
//                     Container(
//                       padding: EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: QrImageView(
//                         data: _connectionString,
//                         version: QrVersions.auto,
//                         size: 180.0,
//                         backgroundColor: Colors.white,
//                       ),
//                     ),
//                     SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: _scanAvailableFiles,
//                       child: Text('Refresh Files'),
//                     ),
//                   ],
//                 ),
//               ),
//               Divider(),
//             ],
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Text('Available Files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             ),
//             if (_availableFiles.isNotEmpty)
//               ConstrainedBox(
//                 constraints: BoxConstraints(maxHeight: 300),
//                 child: ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: _availableFiles.length,
//                   itemBuilder: (ctx, i) => ListTile(
//                     leading: Icon(Icons.insert_drive_file),
//                     title: Text(_availableFiles[i].split('/').last),
//                     subtitle: Text(_availableFiles[i]),
//                   ),
//                 ),
//               )
//             else
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text('No files found or permission not granted'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:qr_flutter/qr_flutter.dart';
//
// import 'file_transfer.dart';
//
// class ServerPage extends StatefulWidget {
//   @override
//   _ServerPageState createState() => _ServerPageState();
// }
//
// class _ServerPageState extends State<ServerPage> {
//   late FileTransferServer _fileServer;
//   String? _serverIp;
//   bool _isServerRunning = false;
//   final List<String> _sharedFiles = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _initServer();
//   }
//
//   Future<void> _initServer() async {
//     final dir = await getApplicationDocumentsDirectory();
//     _fileServer = FileTransferServer(
//       sharedDirectory: '${dir.path}/shared_files',
//     );
//   }
//
//   Future<void> _toggleServer() async {
//     if (_isServerRunning) {
//       await _stopServer();
//     } else {
//       await _startServer();
//     }
//   }
//
//   Future<void> _startServer() async {
//     try {
//       await _fileServer.start();
//       _serverIp = await _getLocalIpAddress();
//
//       setState(() {
//         _isServerRunning = true;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Server running at $_serverIp:${_fileServer.port}')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to start server: $e')),
//       );
//     }
//   }
//
//   Future<void> _stopServer() async {
//     await _fileServer.stop();
//     setState(() {
//       _isServerRunning = false;
//       _serverIp = null;
//     });
//   }
//
//   Future<String?> _getLocalIpAddress() async {
//     try {
//       for (var interface in await NetworkInterface.list()) {
//         for (var addr in interface.addresses) {
//           if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
//             return addr.address;
//           }
//         }
//       }
//     } catch (e) {
//       print('Error getting IP: $e');
//     }
//     return null;
//   }
//
//   Future<void> _shareFiles() async {
//     final result = await FilePicker.platform.pickFiles(allowMultiple: true);
//     if (result == null) return;
//
//     final sharedDir = Directory(_fileServer.sharedDirectory);
//     for (final file in result.files) {
//       if (file.path != null) {
//         await File(file.path!).copy('${sharedDir.path}/${file.name}');
//       }
//     }
//
//     setState(() {
//       _sharedFiles.addAll(result.files.map((f) => f.path!).whereType<String>());
//     });
//   }
//
//   String get _connectionString => 'http://$_serverIp:${_fileServer.port}';
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('File Share Server')),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             SwitchListTile(
//               title: Text('Server Status'),
//               value: _isServerRunning,
//               onChanged: (_) => _toggleServer(),
//             ),
//             if (_isServerRunning && _serverIp != null) ...[
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     Text('Server IP: $_serverIp', style: TextStyle(fontSize: 16)),
//                     Text('Port: ${_fileServer.port}', style: TextStyle(fontSize: 16)),
//                     SizedBox(height: 16),
//                     Container(
//                       padding: EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: QrImageView(
//                         data: _connectionString,
//                         version: QrVersions.auto,
//                         size: 180.0,
//                         backgroundColor: Colors.white,
//                       ),
//                     ),
//                     SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: _shareFiles,
//                       child: Text('Share Files'),
//                     ),
//                   ],
//                 ),
//               ),
//               Divider(),
//             ],
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Text('Shared Files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             ),
//             if (_sharedFiles.isNotEmpty)
//               ConstrainedBox(
//                 constraints: BoxConstraints(maxHeight: 300),
//                 child: ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: _sharedFiles.length,
//                   itemBuilder: (ctx, i) => ListTile(
//                     leading: Icon(Icons.insert_drive_file),
//                     title: Text(_sharedFiles[i].split('/').last),
//                     subtitle: Text(_sharedFiles[i]),
//                   ),
//                 ),
//               )
//             else
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text('No files shared yet'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
//
// import 'file_transfer.dart';
//
// class ServerPage extends StatefulWidget {
//   @override
//   _ServerPageState createState() => _ServerPageState();
// }
//
// class _ServerPageState extends State<ServerPage> {
//   late FileTransferServer _fileServer;
//   String? _serverIp;
//   bool _isServerRunning = false;
//   final List<String> _sharedFiles = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _initServer();
//   }
//
//   Future<void> _initServer() async {
//     final dir = await getApplicationDocumentsDirectory();
//     _fileServer = FileTransferServer(
//       sharedDirectory: '${dir.path}/shared_files',
//     );
//   }
//
//   Future<void> _toggleServer() async {
//     if (_isServerRunning) {
//       await _stopServer();
//     } else {
//       await _startServer();
//     }
//   }
//
//   Future<void> _startServer() async {
//     try {
//       await _fileServer.start();
//       _serverIp = await _getLocalIpAddress();
//
//       setState(() {
//         _isServerRunning = true;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Server running at $_serverIp')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to start server: $e')),
//       );
//     }
//   }
//
//   Future<void> _stopServer() async {
//     await _fileServer.stop();
//     setState(() {
//       _isServerRunning = false;
//       _serverIp = null;
//     });
//   }
//
//   Future<String?> _getLocalIpAddress() async {
//     try {
//       for (var interface in await NetworkInterface.list()) {
//         for (var addr in interface.addresses) {
//           if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
//             return addr.address;
//           }
//         }
//       }
//     } catch (e) {
//       print('Error getting IP: $e');
//     }
//     return null;
//   }
//
//   Future<void> _shareFiles() async {
//     final result = await FilePicker.platform.pickFiles(allowMultiple: true);
//     if (result == null) return;
//
//     setState(() {
//       _sharedFiles.addAll(result.files.map((f) => f.path!).whereType<String>());
//     });
//
//     final sharedDir = Directory(_fileServer.sharedDirectory);
//     for (final file in result.files) {
//       if (file.path != null) {
//         await File(file.path!).copy('${sharedDir.path}/${file.name}');
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('File Share Server')),
//       body: Column(
//         children: [
//           SwitchListTile(
//             title: Text('Server Status'),
//             value: _isServerRunning,
//             onChanged: (_) => _toggleServer(),
//           ),
//           if (_serverIp != null) ...[
//             Text('Server IP: $_serverIp'),
//             Text('Port: ${_fileServer.port}'),
//             ElevatedButton(
//               onPressed: _shareFiles,
//               child: Text('Share Files'),
//             ),
//           ],
//           Expanded(
//             child: ListView.builder(
//               itemCount: _sharedFiles.length,
//               itemBuilder: (ctx, i) => ListTile(
//                 title: Text(_sharedFiles[i].split('/').last),
//                 subtitle: Text(_sharedFiles[i]),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }