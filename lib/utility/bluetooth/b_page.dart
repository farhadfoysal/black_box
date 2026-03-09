import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class HC05BluetoothControllerA extends StatelessWidget {
  const HC05BluetoothControllerA({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HC-05 Bluetooth Controller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HC05BluetoothControllerPagee(),
    );
  }
}

class HC05BluetoothControllerPagee extends StatefulWidget {
  const HC05BluetoothControllerPagee({super.key});

  @override
  State<HC05BluetoothControllerPagee> createState() => _HC05BluetoothControllerPageState();
}

class _HC05BluetoothControllerPageState extends State<HC05BluetoothControllerPagee> {
  // Bluetooth State Variables
  BluetoothConnection? _connection;
  BluetoothDevice? _selectedDevice;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isScanning = false;
  bool _isDiscoverable = false;
  bool _isReceiving = false;
  bool _autoScroll = true;
  bool _showHex = false;

  // Data Management
  final List<BluetoothDevice> _pairedDevices = [];
  final List<BluetoothDiscoveryResult> _discoveryResults = [];
  final List<Map<String, dynamic>> _messageLog = [];

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _pinController = TextEditingController(text: '1234');
  final ScrollController _logScrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  // Stream Subscriptions
  StreamSubscription<BluetoothDiscoveryResult>? _scanSubscription;
  StreamSubscription<Uint8List>? _dataSubscription;

  // Statistics
  int _bytesSent = 0;
  int _bytesReceived = 0;
  int _messagesSent = 0;
  int _messagesReceived = 0;
  DateTime? _connectionStartTime;

  // Settings
  String _lineEnding = '\n';
  final List<String> _lineEndings = ['None', '\n', '\r', '\r\n'];

  // LED States
  Map<String, bool> _ledStates = {
    'red': false,
    'green': false,
    'yellow': false,
    'white': false,
  };

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  @override
  void dispose() {
    _disconnect();
    _scanSubscription?.cancel();
    _dataSubscription?.cancel();
    _inputController.dispose();
    _pinController.dispose();
    _logScrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  // ===================== BLUETOOTH METHODS =====================

  Future<void> _initializeBluetooth() async {
    try {
      await _requestPermissions();

      // Check if Bluetooth is enabled
      final bool isEnabled =
          (await FlutterBluetoothSerial.instance.isEnabled) == true;

      if (!isEnabled) {
        final bool enabled =
            (await FlutterBluetoothSerial.instance.requestEnable()) == true;

        if (!enabled) {
          _addLog('❌ Bluetooth is not enabled', type: 'error');
          return;
        }
      }

      // Make device discoverable for 300 seconds
      final int? discoverableSeconds =
      await FlutterBluetoothSerial.instance.requestDiscoverable(300);

      setState(() {
        _isDiscoverable =
            discoverableSeconds != null && discoverableSeconds > 0;
      });

      if (_isDiscoverable) {
        _addLog(
          '✅ Device discoverable for $discoverableSeconds seconds',
          type: 'success',
        );
      } else {
        _addLog('❌ Discoverable request denied', type: 'error');
      }

      // Load paired devices
      final List<BluetoothDevice> bondedDevices =
      await FlutterBluetoothSerial.instance.getBondedDevices();

      setState(() {
        _pairedDevices
          ..clear()
          ..addAll(bondedDevices);
      });

      _addLog('✅ Bluetooth initialized', type: 'success');
      _addLog(
        'Found ${bondedDevices.length} paired device(s)',
        type: 'info',
      );
    } catch (e) {
      _addLog('❌ Initialization error: $e', type: 'error');
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      _addLog('⚠️ Some permissions are not granted', type: 'warning');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'This app needs Bluetooth and location permissions to function properly. '
                'Please grant all permissions in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _discoveryResults.clear();
    });

    _addLog('🔍 Scanning for Bluetooth devices...', type: 'info');

    try {
      _scanSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
        setState(() {
          int index = _discoveryResults.indexWhere(
                (element) => element.device.address == result.device.address,
          );

          if (index >= 0) {
            _discoveryResults[index] = result;
          } else {
            _discoveryResults.add(result);
          }
        });

        _addLog('Found: ${result.device.name ?? "Unknown"} (${result.device.address})', type: 'info');
      });

      // Auto-stop after 15 seconds
      Future.delayed(const Duration(seconds: 15), () {
        if (_isScanning) {
          _stopScan();
        }
      });

    } catch (e) {
      _addLog('❌ Scan error: $e', type: 'error');
      setState(() => _isScanning = false);
    }
  }

  void _stopScan() {
    FlutterBluetoothSerial.instance.cancelDiscovery();
    _scanSubscription?.cancel();
    setState(() => _isScanning = false);
    _addLog('✅ Scan completed. Found ${_discoveryResults.length} device(s)', type: 'success');
  }

  Future<void> _showPairingDialog(BluetoothDevice device) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bluetooth, color: Colors.blue),
            const SizedBox(width: 10),
            Text('Pair with ${device.name ?? "Device"}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter PIN for ${device.name ?? "Unknown Device"}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'PIN Code',
                hintText: '1234',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Common Bluetooth PINs'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('HC-05: 1234'),
                            Text('HC-06: 1234 or 0000'),
                            Text('Most modules: 1234'),
                            SizedBox(height: 10),
                            Text('Note: Some modules might not require PIN'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pairDevice(device);
            },
            child: const Text('Pair'),
          ),
        ],
      ),
    );
  }

  Future<void> _pairDevice(BluetoothDevice device) async {
    _addLog('🤝 Pairing with ${device.name ?? "Unknown"}...', type: 'info');

    try {
      bool bonded = false;

      if (device.isBonded) {
        bonded = true;
      } else {
        bonded = await FlutterBluetoothSerial.instance.bondDeviceAtAddress(
          device.address,
          pin: _pinController.text,
        ) ?? false;
      }

      if (bonded) {
        _addLog('✅ Successfully paired with ${device.name ?? "Device"}', type: 'success');
        setState(() {
          _selectedDevice = device;
          if (!_pairedDevices.contains(device)) {
            _pairedDevices.add(device);
          }
        });
        _connectToDevice();
      } else {
        _addLog('❌ Pairing failed. Check PIN (usually 1234 or 0000)', type: 'error');
      }
    } catch (e) {
      _addLog('❌ Pairing error: $e', type: 'error');
    }
  }

  Future<void> _connectToDevice() async {
    if (_selectedDevice == null) return;

    setState(() {
      _isConnecting = true;
    });

    _addLog('🔗 Connecting to ${_selectedDevice!.name ?? "Device"}...', type: 'info');

    try {
      _connection = await BluetoothConnection.toAddress(_selectedDevice!.address);

      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _connectionStartTime = DateTime.now();
      });

      _addLog('✅ Connected to ${_selectedDevice!.name ?? "Device"}', type: 'success');
      _startListening();

      // Send initial handshake after a small delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _sendData('?'); // Request status
      });

    } catch (e) {
      setState(() => _isConnecting = false);
      _addLog('❌ Connection failed: $e', type: 'error');
    }
  }

  void _startListening() {
    if (_connection == null) return;

    _dataSubscription?.cancel();
    _dataSubscription = _connection!.input!.listen(_handleIncomingData, onDone: _onDisconnected);
  }

  void _handleIncomingData(Uint8List data) {
    if (data.isEmpty) return;

    setState(() {
      _isReceiving = true;
      _bytesReceived += data.length;
      _messagesReceived++;
    });

    String receivedString;
    if (_showHex) {
      // Display as hexadecimal
      receivedString = data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');
    } else {
      // Display as ASCII/UTF-8
      try {
        receivedString = utf8.decode(data);
      } catch (e) {
        receivedString = String.fromCharCodes(data);
      }
    }

    _addLog('📥 $receivedString', type: 'received');

    // Parse status updates from Arduino
    _parseArduinoResponse(receivedString);

    // Reset receiving flag after delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isReceiving = false);
      }
    });
  }

  void _parseArduinoResponse(String response) {
    // Parse LED states from Arduino status messages
    if (response.contains('RED:')) {
      setState(() {
        _ledStates['red'] = response.contains('ON');
      });
    }
    if (response.contains('GREEN:')) {
      setState(() {
        _ledStates['green'] = response.contains('ON');
      });
    }
    if (response.contains('YELLOW:')) {
      setState(() {
        _ledStates['yellow'] = response.contains('ON');
      });
    }
    if (response.contains('WHITE:')) {
      setState(() {
        _ledStates['white'] = response.contains('ON');
      });
    }
  }

  void _onDisconnected() {
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
        _connectionStartTime = null;
      });
    }
    _addLog('⚠️ Disconnected from device', type: 'warning');
  }

  Future<void> _sendData(String data) async {
    if (!_isConnected || _connection == null) {
      _addLog('⚠️ Not connected to device', type: 'warning');
      return;
    }

    try {
      // Add line ending if needed
      String dataToSend = data;
      if (_lineEnding != 'None' && !data.endsWith(_lineEnding)) {
        dataToSend += _lineEnding;
      }

      final bytes = Uint8List.fromList(utf8.encode(dataToSend));

      // Debug: Print what we're sending
      _addLog('Sending: "$dataToSend" (${bytes.length} bytes)', type: 'debug');

      _connection!.output.add(bytes);
      await _connection!.output.allSent;

      setState(() {
        _bytesSent += bytes.length;
        _messagesSent++;
      });

      _addLog('📤 $data', type: 'sent');

      // Update LED states locally
      _updateLocalLedStates(data);

    } catch (e) {
      _addLog('❌ Send error: $e', type: 'error');
      _disconnect();
    }
  }

  void _updateLocalLedStates(String command) {
    command = command.trim();
    switch (command) {
      case '1':
        setState(() {
          _ledStates['red'] = true;
          _ledStates['green'] = true;
          _ledStates['yellow'] = true;
          _ledStates['white'] = true;
        });
        break;
      case '0':
        setState(() {
          _ledStates['red'] = false;
          _ledStates['green'] = false;
          _ledStates['yellow'] = false;
          _ledStates['white'] = false;
        });
        break;
      case 'R':
        setState(() => _ledStates['red'] = true);
        break;
      case 'r':
        setState(() => _ledStates['red'] = false);
        break;
      case 'G':
        setState(() => _ledStates['green'] = true);
        break;
      case 'g':
        setState(() => _ledStates['green'] = false);
        break;
      case 'Y':
        setState(() => _ledStates['yellow'] = true);
        break;
      case 'y':
        setState(() => _ledStates['yellow'] = false);
        break;
      case 'W':
        setState(() => _ledStates['white'] = true);
        break;
      case 'w':
        setState(() => _ledStates['white'] = false);
        break;
    }
  }

  void _disconnect() {
    _dataSubscription?.cancel();
    if (_connection != null) {
      _connection!.close();
      _connection = null;
    }

    setState(() {
      _isConnected = false;
      _isConnecting = false;
      _connectionStartTime = null;
    });

    _addLog('🔌 Disconnected from device', type: 'info');
  }

  void _addLog(String message, {String type = 'info'}) {
    final timestamp = DateTime.now();
    final timeStr = DateFormat('HH:mm:ss.SSS').format(timestamp);

    setState(() {
      _messageLog.insert(0, {
        'time': timeStr,
        'message': message,
        'type': type,
        'timestamp': timestamp,
      });

      if (_messageLog.length > 200) {
        _messageLog.removeLast();
      }
    });

    if (_autoScroll && _logScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _logScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _clearLogs() {
    setState(() {
      _messageLog.clear();
    });
    _addLog('🧹 Logs cleared', type: 'info');
  }

  void _resetStatistics() {
    setState(() {
      _bytesSent = 0;
      _bytesReceived = 0;
      _messagesSent = 0;
      _messagesReceived = 0;
    });
    _addLog('📊 Statistics reset', type: 'info');
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // ===================== UI WIDGETS =====================

  Widget _buildDeviceTile(BluetoothDevice device, {bool isBonded = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          isBonded ? Icons.bluetooth_connected : Icons.bluetooth,
          color: isBonded ? Colors.green : Colors.blue,
        ),
        title: Text(
          device.name ?? 'Unknown Device',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          device.address,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: _selectedDevice?.address == device.address && _isConnected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : ElevatedButton(
          onPressed: () {
            setState(() => _selectedDevice = device);
            if (isBonded) {
              _connectToDevice();
            } else {
              _showPairingDialog(device);
            }
          },
          child: const Text('Connect'),
        ),
      ),
    );
  }

  Widget _buildDiscoveryTile(BluetoothDiscoveryResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.grey[50],
      child: ListTile(
        leading: const Icon(Icons.bluetooth_searching, color: Colors.orange),
        title: Text(
          result.device.name ?? 'Unknown Device',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.device.address, style: const TextStyle(fontSize: 12)),
            if (result.rssi != null)
              Text(
                'Signal: ${result.rssi} dBm',
                style: TextStyle(
                  fontSize: 11,
                  color: _getSignalColor(result.rssi!),
                ),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            setState(() => _selectedDevice = result.device);
            _showPairingDialog(result.device);
          },
          child: const Text('Pair'),
        ),
      ),
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -70) return Colors.orange;
    return Colors.red;
  }

  Widget _buildLEDControlButton(String label, String command, Color color, String ledName) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _ledStates[ledName] == true ? color : Colors.grey[200],
            foregroundColor: _ledStates[ledName] == true ? Colors.white : color,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () => _sendData(command),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _ledStates[ledName] == true ? Icons.lightbulb : Icons.lightbulb_outline,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Sent', '${_bytesSent} B', Icons.upload),
                _buildStatItem('Received', '${_bytesReceived} B', Icons.download),
                _buildStatItem('Messages', '$_messagesSent/$_messagesReceived', Icons.message),
              ],
            ),
            if (_connectionStartTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Connected for: ${_formatDuration(DateTime.now().difference(_connectionStartTime!))}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLEDStatusIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LED Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLEDStatusItem('RED', _ledStates['red'] ?? false, Colors.red),
                _buildLEDStatusItem('GREEN', _ledStates['green'] ?? false, Colors.green),
                _buildLEDStatusItem('YELLOW', _ledStates['yellow'] ?? false, Colors.amber),
                _buildLEDStatusItem('WHITE', _ledStates['white'] ?? false, Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLEDStatusItem(String label, bool isOn, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOn ? color : Colors.grey[300],
            border: Border.all(color: color.withOpacity(0.5), width: 2),
          ),
          child: Center(
            child: Icon(
              isOn ? Icons.lightbulb : Icons.lightbulb_outline,
              color: isOn ? Colors.white : color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(isOn ? 'ON' : 'OFF', style: TextStyle(
          fontSize: 10,
          color: isOn ? color : Colors.grey,
          fontWeight: FontWeight.bold,
        )),
      ],
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Settings'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  SwitchListTile(
                    title: const Text('Auto-scroll Logs'),
                    value: _autoScroll,
                    onChanged: (value) => setState(() {
                      _autoScroll = value;
                    }),
                  ),
                  SwitchListTile(
                    title: const Text('Show Hex Values'),
                    value: _showHex,
                    onChanged: (value) => setState(() {
                      _showHex = value;
                    }),
                  ),
                  ListTile(
                    title: const Text('Line Ending'),
                    subtitle: Text('Current: ${_lineEnding == '\n' ? '\\n' : _lineEnding == '\r' ? '\\r' : _lineEnding}'),
                    trailing: DropdownButton<String>(
                      value: _lineEnding,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _lineEnding = value;
                          });
                        }
                      },
                      items: _lineEndings.map((ending) {
                        return DropdownMenuItem(
                          value: ending,
                          child: Text(ending == 'None' ? 'None' : ending == '\n' ? '\\n' : ending),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Reset Statistics'),
                    leading: const Icon(Icons.restart_alt),
                    onTap: () {
                      _resetStatistics();
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Clear All Logs'),
                    leading: const Icon(Icons.delete_forever),
                    onTap: () {
                      _clearLogs();
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  const ListTile(
                    title: Text('About'),
                    subtitle: Text(
                      'HC-05 Bluetooth Controller v1.0\n'
                          'Supports HC-05, HC-06 modules\n'
                          '4-LED Control System',
                    ),
                    leading: Icon(Icons.info),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HC-05 4-LED Controller'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
          ),
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _sendData('?'),
              tooltip: 'Refresh Status',
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isConnected
                                    ? Icons.bluetooth_connected
                                    : _isConnecting
                                    ? Icons.bluetooth_searching
                                    : Icons.bluetooth_disabled,
                                color: _isConnected
                                    ? Colors.green
                                    : _isConnecting
                                    ? Colors.orange
                                    : Colors.red,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isConnected
                                          ? 'Connected'
                                          : _isConnecting
                                          ? 'Connecting...'
                                          : 'Disconnected',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _isConnected
                                            ? Colors.green
                                            : _isConnecting
                                            ? Colors.orange
                                            : Colors.red,
                                      ),
                                    ),
                                    Text(
                                      _selectedDevice?.name ?? 'No device selected',
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _selectedDevice?.address ?? '',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isConnecting) const CircularProgressIndicator(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: Icon(_isScanning ? Icons.stop : Icons.search),
                                  label: Text(_isScanning ? 'Stop Scan' : 'Scan Devices'),
                                  onPressed: _isScanning ? _stopScan : _startScan,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isConnected ? Colors.red : Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _isConnected ? _disconnect : _connectToDevice,
                                  child: Text(
                                    _isConnected ? 'Disconnect' : 'Connect',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // LED Status Indicator
                  _buildLEDStatusIndicator(),
                  const SizedBox(height: 16),

                  // LED Control Grid
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LED Controls',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          // On/Off/Toggle Row
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.power_settings_new),
                                  label: const Text('ALL ON'),
                                  onPressed: () => _sendData('1'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.power_off),
                                  label: const Text('ALL OFF'),
                                  onPressed: () => _sendData('0'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.swap_horiz),
                                  label: const Text('TOGGLE'),
                                  onPressed: () => _sendData('T'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Individual LED Controls
                          Row(
                            children: [
                              _buildLEDControlButton('RED ON', 'R', Colors.red, 'red'),
                              _buildLEDControlButton('RED OFF', 'r', Colors.red, 'red'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildLEDControlButton('GREEN ON', 'G', Colors.green, 'green'),
                              _buildLEDControlButton('GREEN OFF', 'g', Colors.green, 'green'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildLEDControlButton('YELLOW ON', 'Y', Colors.amber, 'yellow'),
                              _buildLEDControlButton('YELLOW OFF', 'y', Colors.amber, 'yellow'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildLEDControlButton('WHITE ON', 'W', Colors.grey, 'white'),
                              _buildLEDControlButton('WHITE OFF', 'w', Colors.grey, 'white'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // System Commands
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: () => _sendData('?'),
                                child: const Text('STATUS'),
                              ),
                              ElevatedButton(
                                onPressed: () => _sendData('TEST'),
                                child: const Text('TEST'),
                              ),
                              ElevatedButton(
                                onPressed: () => _sendData('PING'),
                                child: const Text('PING'),
                              ),
                              ElevatedButton(
                                onPressed: () => _sendData('HELP'),
                                child: const Text('HELP'),
                              ),
                              ElevatedButton(
                                onPressed: () => _sendData('RESET'),
                                child: const Text('RESET'),
                              ),
                              ElevatedButton(
                                onPressed: () => _sendData('BLINK'),
                                child: const Text('BLINK'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Device List
                  if (_pairedDevices.isNotEmpty || _discoveryResults.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Available Devices',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                if (_isScanning)
                                  const CircularProgressIndicator(),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: ListView(
                                children: [
                                  if (_pairedDevices.isNotEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Paired Devices',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ..._pairedDevices.map((device) => _buildDeviceTile(device, isBonded: true)),
                                  if (_discoveryResults.isNotEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Discovered Devices',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ..._discoveryResults.map(_buildDiscoveryTile),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Custom Input
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Custom Command',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _inputController,
                                  focusNode: _inputFocusNode,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Enter command (e.g., R, r, 1, 0, TEST)',
                                    hintText: 'Type command and press Send',
                                  ),
                                  onSubmitted: (value) {
                                    if (value.isNotEmpty) {
                                      _sendData(value);
                                      _inputController.clear();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  if (_inputController.text.isNotEmpty) {
                                    _sendData(_inputController.text);
                                    _inputController.clear();
                                  }
                                },
                                child: const Text('Send'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Statistics
                  _buildStatisticsCard(),
                  const SizedBox(height: 16),

                  // Serial Monitor
                  SizedBox(
                    height: 300,
                    child: Card(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Serial Monitor',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text('${_messageLog.length} entries'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.autorenew),
                                      onPressed: _resetStatistics,
                                      tooltip: 'Reset Statistics',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 0),
                          Expanded(
                            child: _messageLog.isEmpty
                                ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.monitor, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No data received yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    'Connect to device to see serial data',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                                : ListView.builder(
                              controller: _logScrollController,
                              reverse: true,
                              itemCount: _messageLog.length,
                              itemBuilder: (context, index) {
                                final log = _messageLog[index];
                                Color bgColor = Colors.white;
                                Color textColor = Colors.black;

                                switch (log['type']) {
                                  case 'sent':
                                    bgColor = Colors.blue[50]!;
                                    textColor = Colors.blue[900]!;
                                    break;
                                  case 'received':
                                    bgColor = Colors.green[50]!;
                                    textColor = Colors.green[900]!;
                                    break;
                                  case 'error':
                                    bgColor = Colors.red[50]!;
                                    textColor = Colors.red[900]!;
                                    break;
                                  case 'warning':
                                    bgColor = Colors.orange[50]!;
                                    textColor = Colors.orange[900]!;
                                    break;
                                  case 'success':
                                    bgColor = Colors.green[50]!;
                                    textColor = Colors.green[900]!;
                                    break;
                                  case 'debug':
                                    bgColor = Colors.grey[50]!;
                                    textColor = Colors.grey[700]!;
                                    break;
                                }

                                return Container(
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    border: Border(
                                      bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          log['time'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                            fontFamily: 'Monospace',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: SelectableText(
                                          log['message'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textColor,
                                            fontFamily: 'Monospace',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _isConnected
          ? FloatingActionButton.extended(
        onPressed: () {
          _inputFocusNode.requestFocus();
        },
        icon: const Icon(Icons.keyboard),
        label: const Text('Send Command'),
        backgroundColor: Colors.blue,
      )
          : null,
    );
  }
}