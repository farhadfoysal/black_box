import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';

class ClientPage extends StatefulWidget {
  @override
  _ClientPageState createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '8080');
  List<String> _availableFiles = [];
  bool _isConnected = false;
  bool _isScanning = false;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;

  Future<void> _connectToServer() async {
    try {
      final ip = _ipController.text;
      final port = int.parse(_portController.text);

      final response = await http.get(Uri.parse('http://$ip:$port/files'));
      if (response.statusCode == 200) {
        setState(() {
          _availableFiles = response.body.split('\n');
          _isConnected = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
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

      final request = http.Request('GET', Uri.parse('http://$ip:$port/download/$filename'));
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
      appBar: AppBar(title: Text('File Share Client')),
      body: Column(
        children: [
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
          if (_isDownloading)
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          if (_isConnected) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Available Files:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _connectToServer,
                child: ListView.builder(
                  itemCount: _availableFiles.length,
                  itemBuilder: (ctx, i) => ListTile(
                    leading: Icon(Icons.insert_drive_file),
                    title: Text(_availableFiles[i]),
                    trailing: IconButton(
                      icon: Icon(Icons.download),
                      onPressed: () => _downloadFile(_availableFiles[i]),
                    ),
                  ),
                ),
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