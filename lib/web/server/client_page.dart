import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class ClientPage extends StatefulWidget {
  @override
  _ClientPageState createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController =
      TextEditingController(text: '8080');
  bool _isConnected = false;
  bool _isScanning = false;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;

  // Tab controller
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Categorized file lists
  final List<String> _photos = [];
  final List<String> _videos = [];
  final List<String> _documents = [];
  final List<String> _otherFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
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
    }
  }

  Future<void> _connectToServer() async {
    try {
      final ip = _ipController.text;
      final port = int.parse(_portController.text);

      // Load all categories when connecting
      await Future.wait([
        _loadFilesForCategory('photos', ip, port),
        _loadFilesForCategory('videos', ip, port),
        _loadFilesForCategory('documents', ip, port),
        _loadFilesForCategory('others', ip, port),
      ]);

      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }

  Future<void> _loadFilesForCategory(
      String category, String ip, int port) async {
    try {
      final response =
          await http.get(Uri.parse('http://$ip:$port/files/$category'));
      if (response.statusCode == 200) {
        setState(() {
          switch (category) {
            case 'photos':
              _photos.clear();
              _photos
                  .addAll(response.body.split('\n').where((f) => f.isNotEmpty));
              break;
            case 'videos':
              _videos.clear();
              _videos
                  .addAll(response.body.split('\n').where((f) => f.isNotEmpty));
              break;
            case 'documents':
              _documents.clear();
              _documents
                  .addAll(response.body.split('\n').where((f) => f.isNotEmpty));
              break;
            case 'others':
              _otherFiles.clear();
              _otherFiles
                  .addAll(response.body.split('\n').where((f) => f.isNotEmpty));
              break;
          }
        });
      }
    } catch (e) {
      print('Error loading $category: $e');
    }
  }

  Future<void> _downloadFile(String filename) async {
    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      final ip = _ipController.text;
      final port = int.parse(_portController.text);

      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/downloads/$filename';
      await Directory('${dir.path}/downloads').create(recursive: true);

      final request = http.Request(
          'GET',
          Uri.parse(
              'http://$ip:$port/download/${Uri.encodeComponent(filename)}'));
      final response = await http.Client().send(request);

      final file = File(savePath);
      final sink = file.openWrite();
      int received = 0;
      final total = response.contentLength ?? 0;

      response.stream.listen(
        (List<int> chunk) {
          received += chunk.length;
          setState(() {
            _downloadProgress = received / total;
          });
          sink.add(chunk);
        },
        onDone: () async {
          await sink.close();
          setState(() {
            _isDownloading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to $savePath')),
          );
        },
        onError: (e) {
          setState(() {
            _isDownloading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed: $e')),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  void _startScanner() {
    setState(() {
      _isScanning = true;
    });
  }

  void _handleScannedData(String? data) {
    if (data == null || !data.startsWith('http://')) return;

    setState(() {
      _isScanning = false;
    });

    try {
      final uri = Uri.parse(data);
      _ipController.text = uri.host;
      _portController.text = uri.port.toString();
      _connectToServer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid QR code: $e')),
      );
    }
  }

  Widget _buildFileList(List<String> files) {
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No files available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadFilesForCategory(
        ['photos', 'videos', 'documents', 'others'][_currentTabIndex],
        _ipController.text,
        int.parse(_portController.text),
      ),
      child: ListView.builder(
        itemCount: files.length,
        itemBuilder: (ctx, i) {
          final file = files[i];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: _getFileIcon(file),
              title: Text(path.basename(file)),
              subtitle: Text(file),
              trailing: IconButton(
                icon: Icon(Icons.download),
                onPressed: () => _downloadFile(file),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getFileIcon(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.flv', '.wmv'];
    final docExtensions = [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt'
    ];

    if (imageExtensions.contains(ext)) {
      return Icon(Icons.image, color: Colors.blue);
    } else if (videoExtensions.contains(ext)) {
      return Icon(Icons.video_file, color: Colors.red);
    } else if (docExtensions.contains(ext)) {
      return Icon(Icons.description, color: Colors.green);
    }
    return Icon(Icons.insert_drive_file, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Scan Server QR Code'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => setState(() => _isScanning = false),
          ),
        ),
        body: Stack(
          children: [
            MobileScanner(
              fit: BoxFit.cover,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  _handleScannedData(barcode.rawValue);
                }
              },
            ),
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('File Share Client'),
        bottom: _isConnected
            ? TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                      icon: Icon(
                          Icons.photo)), // Added missing closing parenthesis
                  Tab(icon: Icon(Icons.video_library)),
                  Tab(icon: Icon(Icons.description)),
                  Tab(icon: Icon(Icons.insert_drive_file)),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          if (!_isConnected) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(labelText: 'Server IP'),
                  ),
                  TextField(
                    controller: _portController,
                    decoration: InputDecoration(labelText: 'Port'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _connectToServer,
                          child: Text('Connect'),
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _startScanner,
                        child: Icon(Icons.qr_code_scanner),
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (_isDownloading)
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          if (_isConnected) ...[
            Expanded(
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
          ],
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:http/http.dart' as http;
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'dart:io';
//
// class ClientPage extends StatefulWidget {
//   @override
//   _ClientPageState createState() => _ClientPageState();
// }
//
// class _ClientPageState extends State<ClientPage> {
//   final TextEditingController _ipController = TextEditingController();
//   final TextEditingController _portController = TextEditingController(text: '8080');
//   List<String> _availableFiles = [];
//   bool _isConnected = false;
//   bool _isScanning = false;
//   double _downloadProgress = 0.0;
//   bool _isDownloading = false;
//
//   Future<void> _connectToServer() async {
//     try {
//       final ip = _ipController.text;
//       final port = int.parse(_portController.text);
//
//       final response = await http.get(Uri.parse('http://$ip:$port/files'));
//       if (response.statusCode == 200) {
//         setState(() {
//           _availableFiles = response.body.split('\n');
//           _isConnected = true;
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Connection failed: $e')),
//       );
//     }
//   }
//
//   Future<void> _downloadFile(String filename) async {
//     try {
//       setState(() {
//         _isDownloading = true;
//         _downloadProgress = 0.0;
//       });
//
//       final ip = _ipController.text;
//       final port = int.parse(_portController.text);
//
//       final dir = await getApplicationDocumentsDirectory();
//       final savePath = '${dir.path}/downloads/$filename';
//       await Directory('${dir.path}/downloads').create(recursive: true);
//
//       final request = http.Request('GET', Uri.parse('http://$ip:$port/download/$filename'));
//       final response = await http.Client().send(request);
//
//       final file = File(savePath);
//       final sink = file.openWrite();
//       int received = 0;
//       final total = response.contentLength ?? 0;
//
//       response.stream.listen(
//             (List<int> chunk) {
//           received += chunk.length;
//           setState(() {
//             _downloadProgress = received / total;
//           });
//           sink.add(chunk);
//         },
//         onDone: () async {
//           await sink.close();
//           setState(() {
//             _isDownloading = false;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Saved to $savePath')),
//           );
//         },
//         onError: (e) {
//           setState(() {
//             _isDownloading = false;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Download failed: $e')),
//           );
//         },
//       );
//     } catch (e) {
//       setState(() {
//         _isDownloading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Download failed: $e')),
//       );
//     }
//   }
//
//   void _startScanner() {
//     setState(() {
//       _isScanning = true;
//     });
//   }
//
//   void _handleScannedData(String? data) {
//     if (data == null || !data.startsWith('http://')) return;
//
//     setState(() {
//       _isScanning = false;
//     });
//
//     try {
//       final uri = Uri.parse(data);
//       _ipController.text = uri.host;
//       _portController.text = uri.port.toString();
//       _connectToServer();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Invalid QR code: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isScanning) {
//       return Scaffold(
//         appBar: AppBar(
//           title: Text('Scan Server QR Code'),
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back),
//             onPressed: () => setState(() => _isScanning = false),
//           ),
//         ),
//         body: Stack(
//           children: [
//             MobileScanner(
//               fit: BoxFit.cover,
//               onDetect: (capture) {
//                 final List<Barcode> barcodes = capture.barcodes;
//                 for (final barcode in barcodes) {
//                   _handleScannedData(barcode.rawValue);
//                 }
//               },
//             ),
//             Center(
//               child: Container(
//                 width: 250,
//                 height: 250,
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.white, width: 2),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(title: Text('File Share Client')),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: _ipController,
//                   decoration: InputDecoration(labelText: 'Server IP'),
//                 ),
//                 TextField(
//                   controller: _portController,
//                   decoration: InputDecoration(labelText: 'Port'),
//                   keyboardType: TextInputType.number,
//                 ),
//                 SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: _connectToServer,
//                         child: Text('Connect'),
//                       ),
//                     ),
//                     SizedBox(width: 16),
//                     ElevatedButton(
//                       onPressed: _startScanner,
//                       child: Icon(Icons.qr_code_scanner),
//                       style: ElevatedButton.styleFrom(
//                         shape: CircleBorder(),
//                         padding: EdgeInsets.all(16),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           if (_isDownloading)
//             LinearProgressIndicator(
//               value: _downloadProgress,
//               backgroundColor: Colors.grey[200],
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
//             ),
//           if (_isConnected) ...[
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Text(
//                 'Available Files:',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//               ),
//             ),
//             Expanded(
//               child: RefreshIndicator(
//                 onRefresh: _connectToServer,
//                 child: ListView.builder(
//                   itemCount: _availableFiles.length,
//                   itemBuilder: (ctx, i) => ListTile(
//                     leading: Icon(Icons.insert_drive_file),
//                     title: Text(_availableFiles[i]),
//                     trailing: IconButton(
//                       icon: Icon(Icons.download),
//                       onPressed: () => _downloadFile(_availableFiles[i]),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:http/http.dart' as http;
// import 'dart:io';
//
// class ClientPage extends StatefulWidget {
//   @override
//   _ClientPageState createState() => _ClientPageState();
// }
//
// class _ClientPageState extends State<ClientPage> {
//   final TextEditingController _ipController = TextEditingController();
//   final TextEditingController _portController = TextEditingController(text: '8080');
//   List<String> _availableFiles = [];
//   bool _isConnected = false;
//
//   Future<void> _connectToServer() async {
//     try {
//       final ip = _ipController.text;
//       final port = int.parse(_portController.text);
//
//       final response = await http.get(Uri.parse('http://$ip:$port/files'));
//       if (response.statusCode == 200) {
//         setState(() {
//           _availableFiles = response.body.split('\n');
//           _isConnected = true;
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Connection failed: $e')),
//       );
//     }
//   }
//
//   Future<void> _downloadFile(String filename) async {
//     try {
//       final ip = _ipController.text;
//       final port = int.parse(_portController.text);
//
//       final dir = await getApplicationDocumentsDirectory();
//       final savePath = '${dir.path}/downloads/$filename';
//       await Directory('${dir.path}/downloads').create(recursive: true);
//
//       final response = await http.get(
//         Uri.parse('http://$ip:$port/download/$filename'),
//       );
//
//       await File(savePath).writeAsBytes(response.bodyBytes);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Saved to $savePath')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Download failed: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('File Share Client')),
//       body: Column(
//         children: [
//           TextField(
//             controller: _ipController,
//             decoration: InputDecoration(labelText: 'Server IP'),
//           ),
//           TextField(
//             controller: _portController,
//             decoration: InputDecoration(labelText: 'Port'),
//             keyboardType: TextInputType.number,
//           ),
//           ElevatedButton(
//             onPressed: _connectToServer,
//             child: Text('Connect'),
//           ),
//           if (_isConnected) ...[
//             Text('Available Files:', style: TextStyle(fontWeight: FontWeight.bold)),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _availableFiles.length,
//                 itemBuilder: (ctx, i) => ListTile(
//                   title: Text(_availableFiles[i]),
//                   trailing: IconButton(
//                     icon: Icon(Icons.download),
//                     onPressed: () => _downloadFile(_availableFiles[i]),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }
