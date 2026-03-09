import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class HC05BluetoothControllerApp extends StatelessWidget {
  const HC05BluetoothControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HC-05 Bluetooth Controller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HC05BluetoothControllerPage(),
    );
  }
}

class HC05BluetoothControllerPage extends StatefulWidget {
  const HC05BluetoothControllerPage({super.key});

  @override
  State<HC05BluetoothControllerPage> createState() => _HC05BluetoothControllerPageState();
}

class _HC05BluetoothControllerPageState extends State<HC05BluetoothControllerPage> {
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


  /// Request necessary permissions
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

  /// Start scanning for Bluetooth devices
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

  /// Stop scanning
  void _stopScan() {
    FlutterBluetoothSerial.instance.cancelDiscovery();
    _scanSubscription?.cancel();
    setState(() => _isScanning = false);
    _addLog('✅ Scan completed. Found ${_discoveryResults.length} device(s)', type: 'success');
  }

  /// Show PIN dialog for pairing with HC-05/HC-06
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

  /// Pair with a Bluetooth device
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

  /// Connect to a Bluetooth device
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

      // Send initial handshake
      _sendData('HELLO');

    } catch (e) {
      setState(() => _isConnecting = false);
      _addLog('❌ Connection failed: $e', type: 'error');
    }
  }

  /// Start listening for incoming data
  void _startListening() {
    if (_connection == null) return;

    _dataSubscription?.cancel();
    _dataSubscription = _connection!.input!.listen(_handleIncomingData, onDone: _onDisconnected);
  }

  /// Handle incoming data with proper buffering
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

    // Reset receiving flag after delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isReceiving = false);
      }
    });
  }

  /// Handle disconnection
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

  /// Send data to connected device
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
      _connection!.output.add(bytes);
      await _connection!.output.allSent;

      setState(() {
        _bytesSent += bytes.length;
        _messagesSent++;
      });

      _addLog('📤 $data', type: 'sent');
    } catch (e) {
      _addLog('❌ Send error: $e', type: 'error');
      _disconnect();
    }
  }

  /// Disconnect from device
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

  /// Add log entry with timestamp
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

      // Keep only last 200 logs
      if (_messageLog.length > 200) {
        _messageLog.removeLast();
      }
    });

    // Auto-scroll to top
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

  /// Clear all logs
  void _clearLogs() {
    setState(() {
      _messageLog.clear();
    });
    _addLog('🧹 Logs cleared', type: 'info');
  }

  /// Reset statistics
  void _resetStatistics() {
    setState(() {
      _bytesSent = 0;
      _bytesReceived = 0;
      _messagesSent = 0;
      _messagesReceived = 0;
    });
    _addLog('📊 Statistics reset', type: 'info');
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // ===================== UI WIDGETS =====================

  /// Build device list tile
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

  /// Build discovery result tile
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

  /// Build control button
  Widget _buildControlButton(String label, String command, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () => _sendData(command),
      child: Text(label),
    );
  }

  /// Build statistics card
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

  /// Show settings dialog
  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              SwitchListTile(
                title: const Text('Auto-scroll Logs'),
                value: _autoScroll,
                onChanged: (value) => setState(() => _autoScroll = value),
              ),
              SwitchListTile(
                title: const Text('Show Hex Values'),
                value: _showHex,
                onChanged: (value) => setState(() => _showHex = value),
              ),
              ListTile(
                title: const Text('Line Ending'),
                subtitle: Text('Current: $_lineEnding'),
                trailing: DropdownButton<String>(
                  value: _lineEnding,
                  onChanged: (value) {
                    setState(() => _lineEnding = value!);
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
                      'Works with Arduino/ESP32/ESP8266',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HC-05 Bluetooth Controller'),
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

                  // Quick Controls
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Controls',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // For 4-LED system
                              _buildControlButton('ALL ON', '1', Colors.green),
                              _buildControlButton('ALL OFF', '0', Colors.red),
                              _buildControlButton('TOGGLE', 'T', Colors.blue),
                              _buildControlButton('RED ON', 'R', Colors.red),
                              _buildControlButton('RED OFF', 'r', Colors.red.shade300),
                              _buildControlButton('GREEN ON', 'G', Colors.green),
                              _buildControlButton('GREEN OFF', 'g', Colors.green.shade300),
                              _buildControlButton('YELLOW ON', 'Y', Colors.orange),
                              _buildControlButton('YELLOW OFF', 'y', Colors.orange.shade300),
                              _buildControlButton('WHITE ON', 'W', Colors.grey),
                              _buildControlButton('WHITE OFF', 'w', Colors.grey.shade300),
                              _buildControlButton('STATUS', '?', Colors.teal),
                              _buildControlButton('TEST', 'TEST', Colors.purple),
                              _buildControlButton('PING', 'PING', Colors.amber),
                              _buildControlButton('HELLO', 'HELLO', Colors.blue),
                            ],
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
                            'Custom Data Transmission',
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
                                    labelText: 'Enter command or data',
                                    hintText: 'e.g., 123, ABC, command',
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
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              OutlinedButton(
                                onPressed: () => _sendData('123'),
                                child: const Text('123'),
                              ),
                              OutlinedButton(
                                onPressed: () => _sendData('ABC'),
                                child: const Text('ABC'),
                              ),
                              OutlinedButton(
                                onPressed: () => _sendData('HELLO'),
                                child: const Text('HELLO'),
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
        label: const Text('Send Data'),
        backgroundColor: Colors.blue,
      )
          : null,
    );
  }
}


// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:intl/intl.dart';
//
// class HC05BluetoothControllerPage extends StatefulWidget {
//   const HC05BluetoothControllerPage({super.key});
//
//   @override
//   State<HC05BluetoothControllerPage> createState() =>
//       _HC05BluetoothControllerPageState();
// }
//
// class _HC05BluetoothControllerPageState
//     extends State<HC05BluetoothControllerPage> {
//   BluetoothConnection? _connection;
//   BluetoothDevice? _selectedDevice;
//
//   bool _isConnected = false;
//   bool _isConnecting = false;
//   bool _isScanning = false;
//   bool _isReceiving = false;
//
//   final List<BluetoothDevice> _pairedDevices = [];
//   final List<BluetoothDiscoveryResult> _discoveryResults = [];
//   final List<Map<String, dynamic>> _logs = [];
//
//   final TextEditingController _inputController = TextEditingController();
//   final TextEditingController _pinController =
//   TextEditingController(text: '1234');
//
//   final ScrollController _logScrollController = ScrollController();
//   final FocusNode _inputFocus = FocusNode();
//
//   StreamSubscription<BluetoothDiscoveryResult>? _scanSub;
//   StreamSubscription<Uint8List>? _dataSub;
//
//   int _bytesSent = 0;
//   int _bytesReceived = 0;
//   int _sent = 0;
//   int _received = 0;
//
//   DateTime? _connectedAt;
//
//   bool _autoScroll = true;
//   bool _showHex = false;
//   String _lineEnding = '\n';
//
//   @override
//   void initState() {
//     super.initState();
//     _initBluetooth();
//   }
//
//   @override
//   void dispose() {
//     _disconnect();
//     _scanSub?.cancel();
//     _dataSub?.cancel();
//     _inputController.dispose();
//     _pinController.dispose();
//     _logScrollController.dispose();
//     _inputFocus.dispose();
//     super.dispose();
//   }
//
//   // ------------------ INIT ------------------
//
//   Future<void> _initBluetooth() async {
//     await _requestPermissions();
//
//     final enabled =
//         await FlutterBluetoothSerial.instance.isEnabled ?? false;
//
//     if (!enabled) {
//       final ok = await FlutterBluetoothSerial.instance.requestEnable();
//       if (ok != true) {
//         _log('Bluetooth not enabled', 'error');
//         return;
//       }
//     }
//
//     final bonded =
//     await FlutterBluetoothSerial.instance.getBondedDevices();
//
//     setState(() {
//       _pairedDevices.clear();
//       _pairedDevices.addAll(bonded);
//     });
//
//     _log('Bluetooth ready (${bonded.length} paired)', 'success');
//   }
//
//   Future<void> _requestPermissions() async {
//     await [
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//       Permission.locationWhenInUse,
//     ].request();
//   }
//
//   // ------------------ SCAN ------------------
//
//   Future<void> _startScan() async {
//     if (_isScanning) return;
//
//     setState(() {
//       _isScanning = true;
//       _discoveryResults.clear();
//     });
//
//     _log('Scanning devices...', 'info');
//
//     _scanSub =
//         FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
//           final index = _discoveryResults
//               .indexWhere((e) => e.device.address == r.device.address);
//
//           setState(() {
//             if (index >= 0) {
//               _discoveryResults[index] = r;
//             } else {
//               _discoveryResults.add(r);
//             }
//           });
//         });
//
//     Future.delayed(const Duration(seconds: 12), _stopScan);
//   }
//
//   void _stopScan() {
//     FlutterBluetoothSerial.instance.cancelDiscovery();
//     _scanSub?.cancel();
//     setState(() => _isScanning = false);
//     _log('Scan stopped', 'success');
//   }
//
//   // ------------------ PAIR & CONNECT ------------------
//
//   Future<void> _pairAndConnect(BluetoothDevice device) async {
//     bool bonded = device.isBonded;
//
//     if (!bonded) {
//       bonded = await FlutterBluetoothSerial.instance.bondDeviceAtAddress(
//         device.address,
//         pin: _pinController.text,
//       ) ??
//           false;
//     }
//
//     if (!bonded) {
//       _log('Pairing failed', 'error');
//       return;
//     }
//
//     _connect(device);
//   }
//
//   Future<void> _connect(BluetoothDevice device) async {
//     if (_isConnecting) return;
//
//     setState(() => _isConnecting = true);
//     _log('Connecting to ${device.name}', 'info');
//
//     try {
//       _connection =
//       await BluetoothConnection.toAddress(device.address);
//
//       _connectedAt = DateTime.now();
//       _selectedDevice = device;
//
//       setState(() {
//         _isConnected = true;
//         _isConnecting = false;
//       });
//
//       _log('Connected', 'success');
//       _listen();
//       _send('HELLO');
//     } catch (e) {
//       setState(() => _isConnecting = false);
//       _log('Connection failed: $e', 'error');
//     }
//   }
//
//   void _disconnect() {
//     _dataSub?.cancel();
//     _connection?.close();
//
//     setState(() {
//       _isConnected = false;
//       _connection = null;
//       _connectedAt = null;
//     });
//
//     _log('Disconnected', 'info');
//   }
//
//   // ------------------ DATA ------------------
//
//   void _listen() {
//     _dataSub = _connection!.input!.listen((data) {
//       _bytesReceived += data.length;
//       _received++;
//
//       final msg = _showHex
//           ? data.map((e) => e.toRadixString(16)).join(' ')
//           : String.fromCharCodes(data);
//
//       _log('RX: $msg', 'received');
//     });
//   }
//
//   Future<void> _send(String msg) async {
//     if (!_isConnected) return;
//
//     final full =
//     _lineEnding == 'None' ? msg : msg + _lineEnding;
//
//     final bytes = Uint8List.fromList(utf8.encode(full));
//     _connection!.output.add(bytes);
//     await _connection!.output.allSent;
//
//     _bytesSent += bytes.length;
//     _sent++;
//
//     _log('TX: $msg', 'sent');
//   }
//
//   // ------------------ LOG ------------------
//
//   void _log(String msg, String type) {
//     final time = DateFormat('HH:mm:ss').format(DateTime.now());
//
//     setState(() {
//       _logs.insert(0, {
//         'time': time,
//         'msg': msg,
//         'type': type,
//       });
//
//       if (_logs.length > 200) _logs.removeLast();
//     });
//
//     if (_autoScroll && _logScrollController.hasClients) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _logScrollController.jumpTo(0);
//       });
//     }
//   }
//
//   // ------------------ UI ------------------
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('HC-05 Bluetooth Controller'),
//         actions: [
//           IconButton(
//               icon: const Icon(Icons.delete),
//               onPressed: () => setState(() => _logs.clear()))
//         ],
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(12),
//         children: [
//           _statusCard(),
//           _deviceList(),
//           _controls(),
//           _serialMonitor(),
//         ],
//       ),
//       floatingActionButton: _isConnected
//           ? FloatingActionButton(
//         onPressed: () => _inputFocus.requestFocus(),
//         child: const Icon(Icons.keyboard),
//       )
//           : null,
//     );
//   }
//
//   Widget _statusCard() => Card(
//     child: ListTile(
//       leading: Icon(
//         _isConnected
//             ? Icons.bluetooth_connected
//             : Icons.bluetooth_disabled,
//         color: _isConnected ? Colors.green : Colors.red,
//       ),
//       title: Text(_isConnected ? 'Connected' : 'Disconnected'),
//       subtitle: Text(_selectedDevice?.name ?? 'No device'),
//       trailing: _isConnecting
//           ? const CircularProgressIndicator()
//           : ElevatedButton(
//         onPressed:
//         _isConnected ? _disconnect : _startScan,
//         child:
//         Text(_isConnected ? 'DISCONNECT' : 'SCAN'),
//       ),
//     ),
//   );
//
//   Widget _deviceList() => Card(
//     child: Column(
//       children: [
//         const ListTile(title: Text('Devices')),
//         ..._pairedDevices.map((d) => ListTile(
//           title: Text(d.name ?? 'Unknown'),
//           subtitle: Text(d.address),
//           trailing: ElevatedButton(
//             onPressed: () => _connect(d),
//             child: const Text('Connect'),
//           ),
//         )),
//         ..._discoveryResults.map((r) => ListTile(
//           title: Text(r.device.name ?? 'Unknown'),
//           subtitle: Text(r.device.address),
//           trailing: ElevatedButton(
//             onPressed: () => _pairAndConnect(r.device),
//             child: const Text('Pair'),
//           ),
//         )),
//       ],
//     ),
//   );
//
//   Widget _controls() => Card(
//     child: Wrap(
//       spacing: 8,
//       children: [
//         _btn('ON', '1'),
//         _btn('OFF', '0'),
//         _btn('RED', 'R'),
//         _btn('GREEN', 'G'),
//         _btn('STATUS', '?'),
//       ],
//     ),
//   );
//
//   Widget _btn(String t, String c) =>
//       ElevatedButton(onPressed: () => _send(c), child: Text(t));
//
//   Widget _serialMonitor() => Card(
//     child: SizedBox(
//       height: 300,
//       child: ListView.builder(
//         reverse: true,
//         controller: _logScrollController,
//         itemCount: _logs.length,
//         itemBuilder: (_, i) => ListTile(
//           dense: true,
//           title: Text(_logs[i]['msg']),
//           leading: Text(_logs[i]['time']),
//         ),
//       ),
//     ),
//   );
// }
