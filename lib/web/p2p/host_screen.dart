import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../app_permission.dart';
import '../service/hotspot_manager.dart';
import '../service/qr_service.dart';
import 'file_transfer_server.dart';
import 'connection_data.dart';

class ServerScreen extends StatefulWidget {
  const ServerScreen({Key? key}) : super(key: key);

  @override
  _ServerScreenState createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _ssid;
  late String _password;
  bool _isHotspotActive = false;
  String? _serverIp;
  late FileTransferServer _fileServer;
  final List<String> _sharedFiles = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _requiresManualSetup = false;

  @override
  void initState() {
    super.initState();
    _ssid = 'AndroidShare_${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}';
    _password = 'Share${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}';
    _initServer();
  }

  Future<void> _initServer() async {
    final dir = await getApplicationDocumentsDirectory();
    _fileServer = FileTransferServer(
      sharedDirectory: '${dir.path}/shared_files',
      encryptionKey: 'secure_encryption_key_32_chars',
    );
  }

  Future<void> _toggleHotspot() async {
    if (_isHotspotActive) {
      await _stopHotspot();
    } else {
      await _startHotspot();
    }
  }

  Future<void> _startHotspot() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _requiresManualSetup = false;
    });

    try {
      final hasPermissions = await AppPermissions.checkAllPermissions();
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }

      // Check Android version
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt ?? 0;
        _requiresManualSetup = sdkInt >= 26;
      }

      if (_requiresManualSetup) {
        // Show instructions for manual setup
        await _showManualHotspotSetupDialog();
        // Use the new enableHotspot() method instead of createHotspot()
        final success = await HotspotManager.enableHotspot();
        if (!success) {
          throw Exception('Failed to enable hotspot');
        }
      } else {
        // For older Android versions
        final success = await HotspotManager.createHotspot(
          ssid: _ssid,
          password: _password,
        );
        if (!success) {
          throw Exception('Failed to create hotspot');
        }
      }

      _serverIp = await HotspotManager.getHotspotIP();
      await _fileServer.start();

      setState(() {
        _isHotspotActive = true;
        _isLoading = false;
      });

      if (!_requiresManualSetup) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hotspot created successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _showManualHotspotSetupDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Manual Hotspot Setup Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('On your Android version, please:'),
            const SizedBox(height: 16),
            const Text('1. Go to Settings > Network & Internet > Hotspot & tethering'),
            const Text('2. Configure WiFi hotspot with these settings:'),
            const SizedBox(height: 8),
            Text('SSID: $_ssid', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Password: $_password', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('3. Enable the hotspot'),
            const SizedBox(height: 16),
            const Text('4. Return to this app'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I\'ve configured it'),
          ),
        ],
      ),
    );
  }

  Future<void> _stopHotspot() async {
    setState(() { _isLoading = true; });

    try {
      await HotspotManager.stopHotspot();
      await _fileServer.stop();

      setState(() {
        _isHotspotActive = false;
        _serverIp = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _shareFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _sharedFiles.addAll(result.files.map((file) => file.path!).where((path) => path != null).toList());
        });

        for (final file in result.files) {
          if (file.path != null) {
            final sourceFile = File(file.path!);
            final destination = File('${_fileServer.sharedDirectory}/${file.name}');
            await sourceFile.copy(destination.path);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing files: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShareIt - Server'),
        actions: [
          IconButton(
            icon: Icon(_isHotspotActive ? Icons.wifi_off : Icons.wifi),
            onPressed: _isLoading ? null : _toggleHotspot,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _ssid,
                decoration: const InputDecoration(labelText: 'SSID'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                onSaved: (value) => _ssid = value!,
              ),
              TextFormField(
                initialValue: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                onSaved: (value) => _password = value!,
              ),
              const SizedBox(height: 20),

              if (_isLoading) const CircularProgressIndicator(),

              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),

              if (_requiresManualSetup && !_isHotspotActive)
                const Text(
                  'Please configure hotspot manually as shown in instructions',
                  style: TextStyle(color: Colors.orange),
                ),

              if (_isHotspotActive && _serverIp != null) ...[
                const Text('Hotspot Active', style: TextStyle(color: Colors.green)),
                Text('SSID: $_ssid'),
                Text('Password: $_password'),
                Text('Server IP: $_serverIp'),
                const SizedBox(height: 20),

                QRService.generateQRCode(
                  ConnectionData(
                    ssid: _ssid,
                    password: _password,
                    serverIp: _serverIp!,
                  ).toEncodedString(),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _shareFiles,
                  child: const Text('Share Files'),
                ),

                Expanded(
                  child: _sharedFiles.isEmpty
                      ? const Center(child: Text('No files shared yet'))
                      : ListView.builder(
                    itemCount: _sharedFiles.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(_sharedFiles[index].split('/').last),
                        subtitle: Text(_sharedFiles[index]),
                      );
                    },
                  ),
                ),
              ] else ...[
                const Spacer(),
                ElevatedButton(
                  onPressed: _isLoading ? null : _startHotspot,
                  child: const Text('Create Hotspot'),
                ),
                const Spacer(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_isHotspotActive) {
      _stopHotspot();
    }
    super.dispose();
  }
}