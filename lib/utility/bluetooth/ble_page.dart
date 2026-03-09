import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ScrollableBluetoothController extends StatefulWidget {
  const ScrollableBluetoothController({super.key});

  @override
  State<ScrollableBluetoothController> createState() => _ScrollableBluetoothControllerState();
}
// enum BleStatus {
//   unknown,
//   unsupported,
//   unauthorized,
//   poweredOff,
//   locationServicesDisabled,
//   ready,
// }

class _ScrollableBluetoothControllerState extends State<ScrollableBluetoothController> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _dataSubscription;

  List<DiscoveredDevice> _foundDevices = [];
  List<BluetoothDevice> _bondedDevices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isReceiving = false;
  bool _showHex = false;
  bool _autoScroll = true;

  QualifiedCharacteristic? _txCharacteristic;
  QualifiedCharacteristic? _rxCharacteristic;
  String _connectionStatus = 'Disconnected';
  String _receivedData = '';

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final List<Map<String, dynamic>> _messageLog = [];
  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();

  // Statistics
  int _bytesSent = 0;
  int _bytesReceived = 0;
  int _messagesSent = 0;
  int _messagesReceived = 0;
  DateTime? _connectionStartTime;

  // Common BLE Service UUIDs for HC-05/HC-06
  static final Uuid serviceUuid = Uuid.parse("0000ffe0-0000-1000-8000-00805f9b34fb");
  static final Uuid txCharacteristicUuid = Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb");
  static final Uuid rxCharacteristicUuid = Uuid.parse("0000ffe2-0000-1000-8000-00805f9b34fb");

  // Bluetooth states
  BluetoothState? _bluetoothState;
  StreamSubscription<BluetoothState>? _bluetoothStateSubscription;
  StreamSubscription<BleStatus>? _bleStatusSubscription;
  BleStatus _bleStatus = BleStatus.unknown;
  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
    _pinController.text = '1234'; // Default HC-05 PIN
    _startListeningToBluetoothState();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    _bluetoothStateSubscription?.cancel();
    _bleStatusSubscription?.cancel();
    _refreshController.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    _pinController.dispose();
    _disconnect();
    super.dispose();
  }

  /// Initialize Bluetooth and check permissions
  Future<void> _initializeBluetooth() async {
    try {
      await _requestPermissions();
      await _checkBluetoothState();
      await _loadBondedDevices();
      _addLog('✅ Bluetooth initialized', type: 'success');
    } catch (e) {
      _addLog('❌ Initialization error: $e', type: 'error');
    }
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    // Request Bluetooth permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();

    // Check if all required permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      _addLog('⚠️ Some permissions are not granted', type: 'warning');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'This app requires Bluetooth and location permissions to function properly. '
                'Please grant all permissions in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  /// Check Bluetooth state
  /// Check Bluetooth state
  Future<void> _checkBluetoothState() async {
    _bleStatus = await _ble.status;
    _updateConnectionStatus();
  }


  /// Start listening to Bluetooth state changes
  void _startListeningToBluetoothState() {
    _bleStatusSubscription = _ble.statusStream.listen((status) {
      setState(() {
        _bleStatus = status;
      });
      _updateConnectionStatus();
    });
  }




  /// Update connection status based on Bluetooth state
  void _updateConnectionStatus() {
    switch (_bleStatus) {
      case BleStatus.ready:
        _connectionStatus = _isConnected ? 'Connected' : 'Ready';
        break;
      case BleStatus.unknown:
        _connectionStatus = 'Unknown';
        break;
      case BleStatus.unsupported:
        _connectionStatus = 'Bluetooth not supported';
        break;
      case BleStatus.unauthorized:
        _connectionStatus = 'Bluetooth not authorized';
        break;
      case BleStatus.poweredOff:
        _connectionStatus = 'Bluetooth is off';
        break;
      case BleStatus.locationServicesDisabled:
        _connectionStatus = 'Location services disabled';
        break;
    }
  }


  /// Load bonded (paired) devices
  Future<void> _loadBondedDevices() async {
    try {
      // Note: flutter_reactive_ble doesn't directly provide bonded devices
      // We'll rely on scanning for devices
      _addLog('Loading paired devices...', type: 'info');
    } catch (e) {
      _addLog('Error loading bonded devices: $e', type: 'error');
    }
  }

  /// Start scanning for Bluetooth devices
  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _foundDevices.clear();
    });

    _addLog('🔍 Scanning for Bluetooth devices...', type: 'info');

    try {
      _scanSubscription = _ble.scanForDevices(
        withServices: [],
        scanMode: ScanMode.lowLatency,
      ).listen((device) {
        if (!_foundDevices.any((d) => d.id == device.id)) {
          setState(() {
            _foundDevices.add(device);
          });
          _addLog('Found: ${device.name ?? "Unknown"} (${device.id})', type: 'info');
        }
      }, onError: (error) {
        _addLog('Scan error: $error', type: 'error');
      });

      // Auto-stop after 15 seconds
      Future.delayed(const Duration(seconds: 15), () {
        if (_isScanning) {
          _stopScan();
        }
      });

    } catch (e) {
      _addLog('Scan error: $e', type: 'error');
      setState(() => _isScanning = false);
    }
  }

  /// Stop scanning
  void _stopScan() {
    _scanSubscription?.cancel();
    setState(() => _isScanning = false);
    _addLog('Scan completed. Found ${_foundDevices.length} device(s)', type: 'info');
  }

  /// Show PIN dialog for pairing
  Future<void> _showPairingDialog(DiscoveredDevice device) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pair Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pair with ${device.name ?? "Unknown Device"}?'),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'PIN (1234 for HC-05/06)',
                hintText: '1234',
                border: OutlineInputBorder(),
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
              _connectToDevice(device);
            },
            child: const Text('Pair & Connect'),
          ),
        ],
      ),
    );
  }

  /// Connect to a Bluetooth device
  Future<void> _connectToDevice(DiscoveredDevice device) async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });

    _addLog('🔗 Connecting to ${device.name ?? "Unknown"}...', type: 'info');

    try {
      _connectionSubscription = _ble.connectToDevice(
        id: device.id,
        connectionTimeout: const Duration(seconds: 15),
      ).listen((connectionState) {
        _updateConnectionState(connectionState);

        if (connectionState.connectionState == DeviceConnectionState.connected) {
          _discoverServices(device.id);
        }
      }, onError: (error) {
        _addLog('Connection error: $error', type: 'error');
        setState(() {
          _isConnecting = false;
          _connectionStatus = 'Connection failed';
        });
      });
    } catch (e) {
      _addLog('Error: $e', type: 'error');
      setState(() {
        _isConnecting = false;
        _connectionStatus = 'Connection error';
      });
    }
  }

  /// Update connection state
  void _updateConnectionState(ConnectionStateUpdate state) {
    setState(() {
      _connectionStatus = state.connectionState.toString().split('.').last;
      _isConnected = state.connectionState == DeviceConnectionState.connected;
      _isConnecting = state.connectionState == DeviceConnectionState.connecting;
    });

    _addLog('Connection state: $_connectionStatus', type: 'info');

    if (state.connectionState == DeviceConnectionState.connected) {
      _connectionStartTime = DateTime.now();
    } else if (state.connectionState == DeviceConnectionState.disconnected) {
      _connectionStartTime = null;
      _cleanupConnection();
    }
  }

  /// Discover services and characteristics
  Future<void> _discoverServices(String deviceId) async {
    try {
      final services = await _ble.discoverServices(deviceId);

      for (final service in services) {
        // Try multiple service UUIDs for compatibility
        if (service.serviceId == serviceUuid ||
            service.serviceId.toString().toLowerCase().contains("ffe0")) {

          for (final characteristic in service.characteristics) {
            // TX characteristic (for sending data)
            if (characteristic.characteristicId == txCharacteristicUuid ||
                characteristic.characteristicId.toString().toLowerCase().contains("ffe1")) {

              _txCharacteristic = QualifiedCharacteristic(
                serviceId: service.serviceId,
                characteristicId: characteristic.characteristicId,
                deviceId: deviceId,
              );
              _addLog('✅ TX characteristic found', type: 'success');
            }

            // RX characteristic (for receiving data)
            if (characteristic.characteristicId == rxCharacteristicUuid ||
                characteristic.characteristicId.toString().toLowerCase().contains("ffe2")) {

              _rxCharacteristic = QualifiedCharacteristic(
                serviceId: service.serviceId,
                characteristicId: characteristic.characteristicId,
                deviceId: deviceId,
              );
              _addLog('✅ RX characteristic found', type: 'success');

              // Subscribe to RX characteristic
              _subscribeToData();
            }
          }

        }
      }

      if (_txCharacteristic != null) {
        _addLog('✅ Connected and ready to send data!', type: 'success');
        // Send initial handshake
        _sendData('HELLO');
      } else {
        _addLog('⚠️ No TX characteristic found', type: 'warning');
      }

    } catch (e) {
      _addLog('Service discovery error: $e', type: 'error');
    }
  }

  /// Subscribe to incoming data
  void _subscribeToData() {
    if (_rxCharacteristic == null) return;

    _dataSubscription?.cancel();
    _dataSubscription = _ble.subscribeToCharacteristic(_rxCharacteristic!).listen(
          (data) {
        _handleIncomingData(data);
      },
      onError: (error) {
        _addLog('Data subscription error: $error', type: 'error');
      },
    );
  }

  /// Handle incoming data
  void _handleIncomingData(List<int> data) {
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
        receivedString = data.map((byte) => String.fromCharCode(byte)).join();
      }
    }

    _addLog('📥 $receivedString', type: 'received');
    setState(() {
      _receivedData = receivedString;
    });

    // Reset receiving flag after delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isReceiving = false);
      }
    });
  }

  /// Send data to connected device
  Future<void> _sendData(String data) async {
    if (!_isConnected || _txCharacteristic == null) {
      _addLog('⚠️ Not connected to device', type: 'warning');
      return;
    }

    try {
      // Add newline character for Arduino Serial.readString()
      String dataToSend = data.endsWith('\n') ? data : '$data\n';
      final bytes = Uint8List.fromList(utf8.encode(dataToSend));

      await _ble.writeCharacteristicWithResponse(_txCharacteristic!, value: bytes);

      setState(() {
        _bytesSent += bytes.length;
        _messagesSent++;
      });

      _addLog('📤 $data', type: 'sent');
    } catch (e) {
      _addLog('Send error: $e', type: 'error');
      _cleanupConnection();
    }
  }

  /// Cleanup connection resources
  void _cleanupConnection() {
    _dataSubscription?.cancel();
    _txCharacteristic = null;
    _rxCharacteristic = null;
    setState(() {
      _isReceiving = false;
    });
  }

  /// Disconnect from device
  void _disconnect() {
    _connectionSubscription?.cancel();
    _cleanupConnection();
    setState(() {
      _isConnected = false;
      _isConnecting = false;
      _connectionStatus = 'Disconnected';
    });
    _addLog('🔌 Disconnected manually', type: 'info');
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
    if (_autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
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

  /// Build device list tile
  Widget _buildDeviceTile(DiscoveredDevice device) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.bluetooth,
          color: _isConnected && _foundDevices.isNotEmpty &&
              _foundDevices.first.id == device.id ? Colors.green : Colors.blue,
        ),
        title: Text(
          device.name ?? 'Unknown Device',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.id,
              style: const TextStyle(fontSize: 12),
            ),
            if (device.rssi != null)
              Text(
                'RSSI: ${device.rssi} dBm',
                style: TextStyle(
                  fontSize: 11,
                  color: _getSignalColor(device.rssi!),
                ),
              ),
          ],
        ),
        trailing: _isConnected && _foundDevices.isNotEmpty &&
            _foundDevices.first.id == device.id
            ? const Icon(Icons.check_circle, color: Colors.green)
            : ElevatedButton(
          onPressed: () => _connectToDevice(device),
          child: const Text('Connect'),
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
            const SizedBox(height: 12),
            if (_connectionStartTime != null)
              Text(
                'Uptime: ${_formatDuration(DateTime.now().difference(_connectionStartTime!))}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  /// Handle pull to refresh
  Future<void> _handleRefresh() async {
    _stopScan();
    await _startScan();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scrollable Bluetooth Controller'),
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
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _handleRefresh,
        enablePullDown: true,
        enablePullUp: false,
        header: const ClassicHeader(
          refreshingText: 'Scanning...',
          completeText: 'Scan complete',
          idleText: 'Pull down to scan',
          releaseText: 'Release to scan',
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                            size: 40,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _connectionStatus,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _isConnected ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _bluetoothState?.toString().split('.').last ?? 'Unknown',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          if (_isConnecting)
                            const CircularProgressIndicator(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(_isScanning ? Icons.stop : Icons.search),
                              label: Text(_isScanning ? 'Stop Scan' : 'Scan Devices'),
                              onPressed: _isScanning ? _stopScan : _startScan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isConnected ? Colors.red : Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isConnected ? _disconnect : null,
                              child: const Text('Disconnect'),
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
              if (_foundDevices.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Devices',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._foundDevices.map(_buildDeviceTile),
                    const SizedBox(height: 16),
                  ],
                ),

              // Quick Controls
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Controls',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildControlButton('LED ON', '1', Colors.green),
                          _buildControlButton('LED OFF', '0', Colors.red),
                          _buildControlButton('Toggle', 'T', Colors.blue),
                          _buildControlButton('Sensor', 'S', Colors.orange),
                          _buildControlButton('Forward', 'F', Colors.purple),
                          _buildControlButton('Reverse', 'R', Colors.purple),
                          _buildControlButton('Stop', 'X', Colors.grey),
                          _buildControlButton('Status', '?', Colors.teal),
                          _buildControlButton('Test', 'TEST', Colors.blue),
                          _buildControlButton('Ping', 'PING', Colors.amber),
                          _buildControlButton('Clear', 'CLR', Colors.red),
                          _buildControlButton('Help', 'HELP', Colors.green),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Custom Data Transmission',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Enter command or data',
                                hintText: 'e.g., 123, LED_ON, SET_MOTOR 255',
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(_showHex ? Icons.code : Icons.text_fields),
                                      onPressed: () {
                                        setState(() => _showHex = !_showHex);
                                      },
                                      tooltip: 'Toggle Hex/Text',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.send),
                                      onPressed: () {
                                        if (_inputController.text.isNotEmpty) {
                                          _sendData(_inputController.text);
                                          _inputController.clear();
                                        }
                                      },
                                      tooltip: 'Send Data',
                                    ),
                                  ],
                                ),
                              ),
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  _sendData(value);
                                  _inputController.clear();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                            onPressed: () => _sendData('123'),
                            child: const Text('Send 123'),
                          ),
                          OutlinedButton(
                            onPressed: () => _sendData('ABC'),
                            child: const Text('Send ABC'),
                          ),
                          OutlinedButton(
                            onPressed: () => _sendData('HELLO'),
                            child: const Text('Send HELLO'),
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
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Serial Monitor',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    Container(
                      height: 300,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                        controller: _scrollController,
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
                              vertical: 8,
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
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Last received: ${_receivedData.isNotEmpty ? _receivedData.substring(0, _receivedData.length < 30 ? _receivedData.length : 30) : "None"}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SwitchListTile(
                            dense: true,
                            title: const Text('Auto-scroll'),
                            value: _autoScroll,
                            onChanged: (value) => setState(() => _autoScroll = value),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: _isConnected
          ? FloatingActionButton.extended(
        onPressed: () {
          if (_inputController.text.isNotEmpty) {
            _sendData(_inputController.text);
            _inputController.clear();
          }
        },
        icon: const Icon(Icons.send),
        label: const Text('Send Data'),
        backgroundColor: Colors.blue,
      )
          : null,
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
                title: const Text('Show Hex Values'),
                value: _showHex,
                onChanged: (value) => setState(() => _showHex = value),
              ),
              SwitchListTile(
                title: const Text('Auto-scroll Logs'),
                value: _autoScroll,
                onChanged: (value) => setState(() => _autoScroll = value),
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
                  'Bluetooth Controller v1.0\n'
                      'Compatible with HC-05/HC-06 modules\n'
                      'Supports Arduino/ESP32/ESP8266',
                ),
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
}