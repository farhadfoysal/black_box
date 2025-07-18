import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../app_permission.dart';
import 'connection_data.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({Key? key}) : super(key: key);

  @override
  _ClientScreenState createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  ConnectionData? _connectionData;
  bool _isConnected = false;
  final List<String> _availableFiles = [];
  final Dio _dio = Dio();
  bool _isScanning = false;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _connectToHotspot(ConnectionData data) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hasPermissions = await AppPermissions.checkAllPermissions();
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }

      // Simulate hotspot connection
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _connectionData = data;
        _isConnected = true;
        _isLoading = false;
      });

      await _fetchAvailableFiles();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchAvailableFiles() async {
    if (_connectionData == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _availableFiles.clear();
        _availableFiles.addAll([
          'document.pdf',
          'image.jpg',
          'presentation.pptx',
          'spreadsheet.xlsx',
        ]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _downloadFile(String filename) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception('Could not access downloads directory');

      final savePath = '${dir.path}/$filename';

      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File saved to $savePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShareIt - Client'),
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.wifi, color: Colors.green),
              onPressed: () {
                setState(() {
                  _isConnected = false;
                  _connectionData = null;
                  _availableFiles.clear();
                });
              },
            ),
        ],
      ),
      body: _isScanning
          ? Stack(
        children: [
          MobileScanner(
            onDetect: (barcodeCapture) {
              final barcode = barcodeCapture.barcodes.first;
              if (barcode.rawValue != null) {
                final data = ConnectionData.fromEncodedString(barcode.rawValue!);
                if (data != null) {
                  _connectToHotspot(data);
                }
                _stopScanning();
              }
            },
          ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Scan QR Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _stopScanning,
                child: const Text('Cancel Scan'),
              ),
            ),
          ),
        ],
      )
          : _isConnected
          ? Column(
        children: [
          ListTile(
            title: Text('Connected to ${_connectionData!.ssid}'),
            subtitle: Text('Server IP: ${_connectionData!.serverIp}'),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: _availableFiles.isEmpty
                ? const Center(child: Text('No files available'))
                : ListView.builder(
              itemCount: _availableFiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(_availableFiles[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: _isLoading
                        ? null
                        : () => _downloadFile(_availableFiles[index]),
                  ),
                );
              },
            ),
          ),
        ],
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Scan QR code to connect to a ShareIt server'),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _startScanning,
              child: const Text('Scan QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}
