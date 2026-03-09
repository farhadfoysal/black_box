
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';



class BluetoothControllerPage extends StatefulWidget {
  const BluetoothControllerPage({super.key});

  @override
  State<BluetoothControllerPage> createState() => _BluetoothControllerPageState();
}

class _BluetoothControllerPageState extends State<BluetoothControllerPage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;

  List<DiscoveredDevice> _foundDevices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  QualifiedCharacteristic? _txCharacteristic;
  QualifiedCharacteristic? _rxCharacteristic;
  String _connectionStatus = 'Disconnected';
  String _receivedData = '';

  final TextEditingController _inputController = TextEditingController();
  final List<String> _messageLog = [];
  final ScrollController _scrollController = ScrollController();

  // Common BLE Service UUIDs
  static final Uuid serviceUuid = Uuid.parse("0000ffe0-0000-1000-8000-00805f9b34fb");
  static final Uuid txCharacteristicUuid = Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb");
  static final Uuid rxCharacteristicUuid = Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb");

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _disconnect();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    // Request Bluetooth permissions
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.location.request();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _foundDevices.clear();
    });

    _addLog("🔍 Scanning for Bluetooth devices...");

    _scanSubscription = _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (!_foundDevices.any((d) => d.id == device.id)) {
        setState(() {
          _foundDevices.add(device);
        });
        _addLog("Found: ${device.name} (${device.id})");
      }
    }, onError: (error) {
      _addLog("Scan error: $error");
    });

    // Stop scan after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      _stopScan();
    });
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    setState(() => _isScanning = false);
    _addLog("Scan completed. Found ${_foundDevices.length} devices");
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });

    _addLog("Connecting to ${device.name}...");

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
        _addLog("Connection error: $error");
        setState(() {
          _isConnecting = false;
          _connectionStatus = 'Connection failed';
        });
      });
    } catch (e) {
      _addLog("Error: $e");
      setState(() {
        _isConnecting = false;
        _connectionStatus = 'Connection error';
      });
    }
  }

  void _updateConnectionState(ConnectionStateUpdate state) {
    setState(() {
      _connectionStatus = state.connectionState.toString().split('.').last;
      _isConnected = state.connectionState == DeviceConnectionState.connected;
      _isConnecting = state.connectionState == DeviceConnectionState.connecting;
    });

    _addLog("Connection state: $_connectionStatus");
  }

  Future<void> _discoverServices(String deviceId) async {
    try {
      final services = await _ble.discoverServices(deviceId);

      for (final service in services) {
        if (service.serviceId == serviceUuid) {
          for (final characteristic in service.characteristics) {
            if (characteristic.characteristicId == txCharacteristicUuid) {
              _txCharacteristic = QualifiedCharacteristic(
                serviceId: service.serviceId,
                characteristicId: characteristic.characteristicId,
                deviceId: deviceId,
              );
            }
            if (characteristic.characteristicId == rxCharacteristicUuid) {
              _rxCharacteristic = QualifiedCharacteristic(
                serviceId: service.serviceId,
                characteristicId: characteristic.characteristicId,
                deviceId: deviceId,
              );

              // Subscribe to RX characteristic for incoming data
              _ble.subscribeToCharacteristic(_rxCharacteristic!).listen((data) {
                final received = utf8.decode(data);
                _addLog("📥 Received: $received");
                setState(() {
                  _receivedData = received;
                });
              });
            }
          }
        }
      }

      if (_txCharacteristic != null) {
        _addLog("✅ Connected and ready to send data!");
      }
    } catch (e) {
      _addLog("Service discovery error: $e");
    }
  }

  Future<void> _sendData(String data) async {
    if (!_isConnected || _txCharacteristic == null) {
      _addLog("Not connected to device");
      return;
    }

    try {
      final bytes = Uint8List.fromList(utf8.encode(data + '\n'));
      await _ble.writeCharacteristicWithResponse(_txCharacteristic!, value: bytes);
      _addLog("📤 Sent: $data");
    } catch (e) {
      _addLog("Send error: $e");
    }
  }

  void _disconnect() {
    _connectionSubscription?.cancel();
    _txCharacteristic = null;
    _rxCharacteristic = null;
    setState(() {
      _isConnected = false;
      _isConnecting = false;
      _connectionStatus = 'Disconnected';
    });
    _addLog("Disconnected from device");
  }

  void _addLog(String message) {
    final timestamp = DateTime.now();
    final time = '${timestamp.hour}:${timestamp.minute}:${timestamp.second}';

    setState(() {
      _messageLog.insert(0, '[$time] $message');
    });

    // Auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _messageLog.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Controller'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
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
              child: IntrinsicHeight(
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
                                      : Icons.bluetooth_disabled,
                                  color: _isConnected ? Colors.green : Colors.red,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _connectionStatus,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color:
                                          _isConnected ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      Text(
                                        _isConnected
                                            ? 'Ready to send data'
                                            : 'Not connected',
                                        style: const TextStyle(fontSize: 12),
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
                                      backgroundColor:
                                      _isConnected ? Colors.red : Colors.blue,
                                    ),
                                    onPressed: _isConnected ? _disconnect : null,
                                    child: const Text(
                                      'Disconnect',
                                      style: TextStyle(color: Colors.white),
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
                    if (_foundDevices.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Available Devices',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 150,
                                child: ListView.builder(
                                  itemCount: _foundDevices.length,
                                  itemBuilder: (context, index) {
                                    final device = _foundDevices[index];
                                    return ListTile(
                                      leading: const Icon(Icons.bluetooth),
                                      title: Text(device.name),
                                      subtitle: Text(device.id),
                                      trailing: ElevatedButton(
                                        onPressed: () => _connectToDevice(device),
                                        child: const Text('Connect'),
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

                    // Control Buttons
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Controls',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _sendData('1'),
                                  child: const Text('LED ON (1)'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _sendData('0'),
                                  child: const Text('LED OFF (0)'),
                                ),
                                ElevatedButton(
                                  onPressed: () => _sendData('T'),
                                  child: const Text('Toggle (T)'),
                                ),
                                ElevatedButton(
                                  onPressed: () => _sendData('S'),
                                  child: const Text('Sensor (S)'),
                                ),
                                ElevatedButton(
                                  onPressed: () => _sendData('?'),
                                  child: const Text('Status (?)'),
                                ),
                                ElevatedButton(
                                  onPressed: () => _sendData('TEST'),
                                  child: const Text('Test'),
                                ),
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
                              'Custom Data',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _inputController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Enter data to send',
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Message Log
                    SizedBox(
                      height: 300, // fixed height or adjust as needed
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
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Chip(
                                    label: Text('${_messageLog.length} messages'),
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
                                    Icon(Icons.monitor,
                                        size: 60, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('No messages yet'),
                                    Text(
                                        'Connect and send data to see logs'),
                                  ],
                                ),
                              )
                                  : ListView.builder(
                                controller: _scrollController,
                                reverse: true,
                                itemCount: _messageLog.length,
                                itemBuilder: (context, index) {
                                  final message = _messageLog[index];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      border: const Border(
                                        bottom: BorderSide(
                                            color: Colors.grey, width: 0.5),
                                      ),
                                      color: message.contains('📤')
                                          ? Colors.blue[50]
                                          : message.contains('📥')
                                          ? Colors.green[50]
                                          : Colors.white,
                                    ),
                                    child: Text(
                                      message,
                                      style: const TextStyle(
                                        fontFamily: 'Monospace',
                                        fontSize: 12,
                                      ),
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
            ),
          );
        },
      ),
    );
  }


// @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Bluetooth Controller'),
  //       actions: [
  //         IconButton(
  //           icon: const Icon(Icons.delete),
  //           onPressed: _clearLogs,
  //           tooltip: 'Clear logs',
  //         ),
  //       ],
  //     ),
  //     body: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.stretch,
  //         children: [
  //           // Status Card
  //           Card(
  //             child: Padding(
  //               padding: const EdgeInsets.all(12),
  //               child: Column(
  //                 children: [
  //                   Row(
  //                     children: [
  //                       Icon(
  //                         _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
  //                         color: _isConnected ? Colors.green : Colors.red,
  //                         size: 32,
  //                       ),
  //                       const SizedBox(width: 12),
  //                       Expanded(
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             Text(
  //                               _connectionStatus,
  //                               style: TextStyle(
  //                                 fontWeight: FontWeight.bold,
  //                                 fontSize: 16,
  //                                 color: _isConnected ? Colors.green : Colors.red,
  //                               ),
  //                             ),
  //                             Text(
  //                               _isConnected ? 'Ready to send data' : 'Not connected',
  //                               style: const TextStyle(fontSize: 12),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                       if (_isConnecting)
  //                         const CircularProgressIndicator(),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 12),
  //                   Row(
  //                     children: [
  //                       Expanded(
  //                         child: ElevatedButton.icon(
  //                           icon: Icon(_isScanning ? Icons.stop : Icons.search),
  //                           label: Text(_isScanning ? 'Stop Scan' : 'Scan Devices'),
  //                           onPressed: _isScanning ? _stopScan : _startScan,
  //                         ),
  //                       ),
  //                       const SizedBox(width: 8),
  //                       Expanded(
  //                         child: ElevatedButton(
  //                           style: ElevatedButton.styleFrom(
  //                             backgroundColor: _isConnected ? Colors.red : Colors.blue,
  //                           ),
  //                           onPressed: _isConnected ? _disconnect : null,
  //                           child: const Text(
  //                             'Disconnect',
  //                             style: TextStyle(color: Colors.white),
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //
  //           const SizedBox(height: 16),
  //
  //           // Device List
  //           if (_foundDevices.isNotEmpty)
  //             Card(
  //               child: Padding(
  //                 padding: const EdgeInsets.all(12),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     const Text(
  //                       'Available Devices',
  //                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  //                     ),
  //                     const SizedBox(height: 8),
  //                     SizedBox(
  //                       height: 150,
  //                       child: ListView.builder(
  //                         itemCount: _foundDevices.length,
  //                         itemBuilder: (context, index) {
  //                           final device = _foundDevices[index];
  //                           return ListTile(
  //                             leading: const Icon(Icons.bluetooth),
  //                             title: Text(device.name),
  //                             subtitle: Text(device.id),
  //                             trailing: ElevatedButton(
  //                               onPressed: () => _connectToDevice(device),
  //                               child: const Text('Connect'),
  //                             ),
  //                           );
  //                         },
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //
  //           const SizedBox(height: 16),
  //
  //           // Control Buttons
  //           Card(
  //             child: Padding(
  //               padding: const EdgeInsets.all(12),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text(
  //                     'Quick Controls',
  //                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  //                   ),
  //                   const SizedBox(height: 12),
  //                   Wrap(
  //                     spacing: 8,
  //                     runSpacing: 8,
  //                     children: [
  //                       ElevatedButton(
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: Colors.green,
  //                           foregroundColor: Colors.white,
  //                         ),
  //                         onPressed: () => _sendData('1'),
  //                         child: const Text('LED ON (1)'),
  //                       ),
  //                       ElevatedButton(
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: Colors.red,
  //                           foregroundColor: Colors.white,
  //                         ),
  //                         onPressed: () => _sendData('0'),
  //                         child: const Text('LED OFF (0)'),
  //                       ),
  //                       ElevatedButton(
  //                         onPressed: () => _sendData('T'),
  //                         child: const Text('Toggle (T)'),
  //                       ),
  //                       ElevatedButton(
  //                         onPressed: () => _sendData('S'),
  //                         child: const Text('Sensor (S)'),
  //                       ),
  //                       ElevatedButton(
  //                         onPressed: () => _sendData('?'),
  //                         child: const Text('Status (?)'),
  //                       ),
  //                       ElevatedButton(
  //                         onPressed: () => _sendData('TEST'),
  //                         child: const Text('Test'),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //
  //           const SizedBox(height: 16),
  //
  //           // Custom Input
  //           Card(
  //             child: Padding(
  //               padding: const EdgeInsets.all(12),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text(
  //                     'Custom Data',
  //                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  //                   ),
  //                   const SizedBox(height: 12),
  //                   Row(
  //                     children: [
  //                       Expanded(
  //                         child: TextField(
  //                           controller: _inputController,
  //                           decoration: const InputDecoration(
  //                             border: OutlineInputBorder(),
  //                             labelText: 'Enter data to send',
  //                             hintText: 'e.g., 123, ABC, command',
  //                           ),
  //                           onSubmitted: (value) {
  //                             if (value.isNotEmpty) {
  //                               _sendData(value);
  //                               _inputController.clear();
  //                             }
  //                           },
  //                         ),
  //                       ),
  //                       const SizedBox(width: 8),
  //                       ElevatedButton(
  //                         onPressed: () {
  //                           if (_inputController.text.isNotEmpty) {
  //                             _sendData(_inputController.text);
  //                             _inputController.clear();
  //                           }
  //                         },
  //                         child: const Text('Send'),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //
  //           const SizedBox(height: 16),
  //
  //           // Message Log
  //           Expanded(
  //             child: Card(
  //               child: Column(
  //                 children: [
  //                   Padding(
  //                     padding: const EdgeInsets.all(12),
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         const Text(
  //                           'Serial Monitor',
  //                           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  //                         ),
  //                         Chip(
  //                           label: Text('${_messageLog.length} messages'),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   const Divider(height: 0),
  //                   Expanded(
  //                     child: _messageLog.isEmpty
  //                         ? const Center(
  //                       child: Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Icon(Icons.monitor, size: 60, color: Colors.grey),
  //                           SizedBox(height: 8),
  //                           Text('No messages yet'),
  //                           Text('Connect and send data to see logs'),
  //                         ],
  //                       ),
  //                     )
  //                         : ListView.builder(
  //                       controller: _scrollController,
  //                       reverse: true,
  //                       itemCount: _messageLog.length,
  //                       itemBuilder: (context, index) {
  //                         final message = _messageLog[index];
  //                         return Container(
  //                           padding: const EdgeInsets.symmetric(
  //                             horizontal: 12,
  //                             vertical: 6,
  //                           ),
  //                           decoration: BoxDecoration(
  //                             border: const Border(
  //                               bottom: BorderSide(color: Colors.grey, width: 0.5),
  //                             ),
  //                             color: message.contains('📤')
  //                                 ? Colors.blue[50]
  //                                 : message.contains('📥')
  //                                 ? Colors.green[50]
  //                                 : Colors.white,
  //                           ),
  //                           child: Text(
  //                             message,
  //                             style: const TextStyle(
  //                               fontFamily: 'Monospace',
  //                               fontSize: 12,
  //                             ),
  //                           ),
  //                         );
  //                       },
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}


// import 'dart:async';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
//
// class BluetoothProjectPage extends StatefulWidget {
//   const BluetoothProjectPage({super.key});
//
//   @override
//   State<BluetoothProjectPage> createState() => _BluetoothProjectPageState();
// }
//
// class _BluetoothProjectPageState extends State<BluetoothProjectPage> {
//   // Bluetooth Variables
//   BluetoothConnection? _connection;
//   BluetoothDevice? _selectedDevice;
//   bool _isConnected = false;
//   bool _isConnecting = false;
//   bool _isScanning = false;
//   bool _isDiscoverable = false;
//   String _bluetoothState = "Unknown";
//   String? _pairingPin;
//
//   // Data Variables
//   final TextEditingController _inputController = TextEditingController();
//   final TextEditingController _pinController = TextEditingController();
//   final List<String> _serialLogs = [];
//   final ScrollController _logScrollController = ScrollController();
//   List<BluetoothDevice> _availableDevices = [];
//   List<BluetoothDevice> _bondedDevices = [];
//
//   // Timer for auto-refresh
//   Timer? _discoveryTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeBluetooth();
//     _pinController.text = "1234"; // Default HC-05 PIN
//   }
//
//   @override
//   void dispose() {
//     _disconnect();
//     _discoveryTimer?.cancel();
//     _inputController.dispose();
//     _pinController.dispose();
//     _logScrollController.dispose();
//     super.dispose();
//   }
//
//   /// Initialize Bluetooth and check state
//   Future<void> _initializeBluetooth() async {
//     try {
//       // Check Bluetooth state
//       BluetoothState state = await FlutterBluetoothSerial.instance.state;
//       _updateBluetoothState(state.toString());
//
//       // Request enable Bluetooth if disabled
//       if (state != BluetoothState.STATE_ON) {
//         bool? enabled = await FlutterBluetoothSerial.instance.requestEnable();
//         if (!enabled!) {
//           _addLog("Bluetooth permission denied");
//         }
//       }
//
//       // Get bonded devices
//       _bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
//       setState(() {});
//
//     } catch (e) {
//       _addLog("Initialization error: $e");
//     }
//   }
//
//   /// Update Bluetooth state
//   void _updateBluetoothState(String state) {
//     setState(() {
//       _bluetoothState = state.replaceAll("BluetoothState.", "");
//     });
//     _addLog("Bluetooth State: $_bluetoothState");
//   }
//
//   /// Start scanning for Bluetooth devices
//   Future<void> _startScan() async {
//     if (_isScanning) return;
//
//     setState(() => _isScanning = true);
//     _availableDevices.clear();
//     _addLog("Scanning for devices...");
//
//     try {
//       // Start discovery
//       FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
//         if (!_availableDevices.any((device) => device.address == result.device.address)) {
//           setState(() {
//             _availableDevices.add(result.device);
//           });
//         }
//       });
//
//       // Stop scanning after 10 seconds
//       await Future.delayed(const Duration(seconds: 10));
//       _stopScan();
//
//     } catch (e) {
//       _addLog("Scan error: $e");
//       setState(() => _isScanning = false);
//     }
//   }
//
//   /// Stop scanning
//   void _stopScan() {
//     FlutterBluetoothSerial.instance.cancelDiscovery();
//     setState(() => _isScanning = false);
//     _addLog("Scan completed. Found ${_availableDevices.length} device(s)");
//   }
//
//   /// Pair with a device (first-time pairing with PIN)
//   Future<void> _pairDevice(BluetoothDevice device) async {
//     if (_pairingPin == null || _pairingPin!.isEmpty) {
//       _showPinDialog(device);
//       return;
//     }
//
//     _addLog("Pairing with ${device.name}...");
//
//     try {
//       bool? bonded = false;
//
//       // Try to pair with PIN (for HC-05/06)
//       if (device.isBonded) {
//         bonded = true;
//       } else {
//         bonded = await FlutterBluetoothSerial.instance
//             .bondDeviceAtAddress(device.address, pin: _pairingPin);
//       }
//
//       if (bonded!) {
//         _addLog("Successfully paired with ${device.name}");
//         _selectedDevice = device;
//         _connectToDevice();
//       } else {
//         _addLog("Pairing failed. Check PIN (usually 1234 or 0000)");
//       }
//     } catch (e) {
//       _addLog("Pairing error: $e");
//     }
//   }
//
//   /// Show PIN input dialog for pairing
//   void _showPinDialog(BluetoothDevice device) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Enter Pairing PIN"),
//         content: TextField(
//           controller: _pinController,
//           keyboardType: TextInputType.number,
//           maxLength: 4,
//           decoration: const InputDecoration(
//             hintText: "1234",
//             labelText: "PIN (usually 1234 or 0000)",
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               setState(() => _pairingPin = _pinController.text);
//               Navigator.pop(context);
//               _pairDevice(device);
//             },
//             child: const Text("Pair"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Connect to selected device
//   Future<void> _connectToDevice() async {
//     if (_selectedDevice == null) return;
//
//     setState(() => _isConnecting = true);
//     _addLog("Connecting to ${_selectedDevice!.name}...");
//
//     try {
//       _connection = await BluetoothConnection.toAddress(_selectedDevice!.address);
//
//       setState(() {
//         _isConnected = true;
//         _isConnecting = false;
//       });
//
//       _addLog("✅ Connected to ${_selectedDevice!.name}");
//       _startListening();
//
//     } catch (e) {
//       setState(() => _isConnecting = false);
//       _addLog("Connection failed: $e");
//     }
//   }
//
//   /// Start listening for incoming data
//   void _startListening() {
//     if (_connection == null) return;
//
//     _connection!.input!.listen((Uint8List data) {
//       String received = String.fromCharCodes(data).trim();
//       if (received.isNotEmpty) {
//         _addLog("📥 RX: $received", isIncoming: true);
//       }
//     }).onDone(() {
//       _onDisconnected();
//     });
//   }
//
//   /// Handle disconnection
//   void _onDisconnected() {
//     if (mounted) {
//       setState(() {
//         _isConnected = false;
//         _isConnecting = false;
//       });
//     }
//     _addLog("⚠️ Disconnected from device");
//   }
//
//   /// Disconnect from device
//   void _disconnect() {
//     if (_connection != null) {
//       _connection!.dispose();
//       _connection = null;
//     }
//     setState(() {
//       _isConnected = false;
//       _isConnecting = false;
//     });
//     _addLog("Disconnected");
//   }
//
//   /// Send data to connected device
//   Future<void> _sendData(String data) async {
//     if (!_isConnected || _connection == null) {
//       _addLog("Not connected");
//       return;
//     }
//
//     try {
//       // Add newline character for Arduino Serial.readString()
//       String dataToSend = data.endsWith('\n') ? data : '$data\n';
//
//       _connection!.output.add(Uint8List.fromList(dataToSend.codeUnits));
//       await _connection!.output.allSent;
//
//       _addLog("📤 TX: ${data.trim()}", isOutgoing: true);
//     } catch (e) {
//       _addLog("Send error: $e");
//       _onDisconnected();
//     }
//   }
//
//   /// Send project-specific commands
//   void _sendCommand(String command, {String? description}) {
//     if (description != null) {
//       _addLog("Command: $description");
//     }
//     _sendData(command);
//   }
//
//   /// Clear serial logs
//   void _clearLogs() {
//     setState(() {
//       _serialLogs.clear();
//     });
//   }
//
//   /// Add log entry with timestamp
//   void _addLog(String message, {bool isIncoming = false, bool isOutgoing = false}) {
//     final timestamp = DateTime.now();
//     final timeStr = "${timestamp.hour.toString().padLeft(2, '0')}:"
//         "${timestamp.minute.toString().padLeft(2, '0')}:"
//         "${timestamp.second.toString().padLeft(2, '0')}";
//
//     String prefix = "";
//     if (isIncoming) prefix = "⬅️ ";
//     if (isOutgoing) prefix = "➡️ ";
//
//     setState(() {
//       _serialLogs.insert(0, "[$timeStr] $prefix$message");
//       if (_serialLogs.length > 100) _serialLogs.removeLast();
//     });
//
//     // Auto-scroll to top
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_logScrollController.hasClients) {
//         _logScrollController.animateTo(
//           0,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }
//
//   /// Show device selection dialog
//   void _showDeviceSelection() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(16),
//         height: MediaQuery.of(context).size.height * 0.7,
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   "Select Device",
//                   style: Theme.of(context).textTheme.titleLarge,
//                 ),
//                 IconButton(
//                   onPressed: _startScan,
//                   icon: Icon(
//                     _isScanning ? Icons.stop : Icons.refresh,
//                     color: _isScanning ? Colors.red : Colors.blue,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             if (_isScanning)
//               const LinearProgressIndicator(),
//             const SizedBox(height: 10),
//             Expanded(
//               child: ListView(
//                 children: [
//                   if (_bondedDevices.isNotEmpty) ...[
//                     const Text("Paired Devices:", style: TextStyle(fontWeight: FontWeight.bold)),
//                     ..._bondedDevices.map((device) => _buildDeviceTile(device, isBonded: true)),
//                     const Divider(),
//                   ],
//                   if (_availableDevices.isNotEmpty) ...[
//                     const Text("Available Devices:", style: TextStyle(fontWeight: FontWeight.bold)),
//                     ..._availableDevices.map((device) => _buildDeviceTile(device, isBonded: false)),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Build device list tile
//   Widget _buildDeviceTile(BluetoothDevice device, {bool isBonded = false}) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       child: ListTile(
//         leading: Icon(
//           isBonded ? Icons.bluetooth_connected : Icons.bluetooth,
//           color: isBonded ? Colors.green : Colors.blue,
//         ),
//         title: Text(device.name ?? "Unknown Device"),
//         subtitle: Text(
//           "${device.address}\n${device.type.toString().replaceAll("BluetoothDeviceType.", "")}",
//           style: const TextStyle(fontSize: 12),
//         ),
//         trailing: _selectedDevice?.address == device.address
//             ? const Icon(Icons.check, color: Colors.green)
//             : null,
//         onTap: () {
//           Navigator.pop(context);
//           _selectedDevice = device;
//           if (isBonded) {
//             _connectToDevice();
//           } else {
//             _pairDevice(device);
//           }
//         },
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Advanced Bluetooth Control"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.delete),
//             onPressed: _clearLogs,
//             tooltip: "Clear Logs",
//           ),
//           IconButton(
//             icon: const Icon(Icons.settings),
//             onPressed: () {
//               // Show settings dialog
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Connection Status Card
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
//                           color: _isConnected ? Colors.green : Colors.red,
//                           size: 30,
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 _isConnected ? "CONNECTED" : "DISCONNECTED",
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: _isConnected ? Colors.green : Colors.red,
//                                 ),
//                               ),
//                               Text(
//                                 _selectedDevice?.name ?? "No device selected",
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               Text(
//                                 "Bluetooth: $_bluetoothState",
//                                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//                               ),
//                             ],
//                           ),
//                         ),
//                         if (_isConnecting)
//                           const CircularProgressIndicator(),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton.icon(
//                             icon: const Icon(Icons.search),
//                             label: const Text("Scan & Select"),
//                             onPressed: _showDeviceSelection,
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: _isConnected ? Colors.red : Colors.blue,
//                             ),
//                             onPressed: _isConnected ? _disconnect : _connectToDevice,
//                             child: Text(
//                               _isConnected ? "Disconnect" : "Connect",
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             // Quick Control Buttons
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Quick Controls",
//                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                     ),
//                     const SizedBox(height: 10),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: [
//                         // Project-specific controls
//                         _buildControlButton("LED ON", "1", Colors.green),
//                         _buildControlButton("LED OFF", "0", Colors.red),
//                         _buildControlButton("Toggle LED", "T", Colors.blue),
//                         _buildControlButton("Read Sensor", "S", Colors.orange),
//                         _buildControlButton("Motor Forward", "F", Colors.purple),
//                         _buildControlButton("Motor Reverse", "R", Colors.purple),
//                         _buildControlButton("Stop", "X", Colors.grey),
//                         _buildControlButton("Status", "?", Colors.teal),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             // Custom Data Input
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Custom Data Transmission",
//                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: _inputController,
//                             decoration: const InputDecoration(
//                               border: OutlineInputBorder(),
//                               hintText: "Enter command or data",
//                               labelText: "Data to Send",
//                             ),
//                             onSubmitted: (value) {
//                               if (value.isNotEmpty) {
//                                 _sendData(value);
//                                 _inputController.clear();
//                               }
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         ElevatedButton(
//                           onPressed: () {
//                             if (_inputController.text.isNotEmpty) {
//                               _sendData(_inputController.text);
//                               _inputController.clear();
//                             }
//                           },
//                           child: const Text("Send"),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         OutlinedButton(
//                           onPressed: () => _sendData("TEST"),
//                           child: const Text("Send TEST"),
//                         ),
//                         OutlinedButton(
//                           onPressed: () => _sendData("HELLO"),
//                           child: const Text("Send HELLO"),
//                         ),
//                         OutlinedButton(
//                           onPressed: () => _sendData("PING"),
//                           child: const Text("Send PING"),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             // Serial Monitor
//             Expanded(
//               child: Card(
//                 child: Column(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           const Text(
//                             "Serial Monitor",
//                             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                           ),
//                           Row(
//                             children: [
//                               Chip(
//                                 label: Text("${_serialLogs.length} entries"),
//                                 backgroundColor: Colors.blue[50],
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.autorenew),
//                                 onPressed: () {
//                                   if (_isConnected) {
//                                     _sendData("STATUS");
//                                   }
//                                 },
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     const Divider(height: 0),
//                     Expanded(
//                       child: _serialLogs.isEmpty
//                           ? const Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.monitor, size: 60, color: Colors.grey),
//                             SizedBox(height: 10),
//                             Text(
//                               "No data received yet",
//                               style: TextStyle(color: Colors.grey),
//                             ),
//                             Text(
//                               "Connect to device to see serial data",
//                               style: TextStyle(color: Colors.grey, fontSize: 12),
//                             ),
//                           ],
//                         ),
//                       )
//                           : ListView.builder(
//                         controller: _logScrollController,
//                         reverse: true,
//                         itemCount: _serialLogs.length,
//                         itemBuilder: (context, index) {
//                           final log = _serialLogs[index];
//                           Color bgColor = Colors.white;
//                           if (log.contains("RX:")) {
//                             bgColor = Colors.green[50]!;
//                           } else if (log.contains("TX:")) {
//                             bgColor = Colors.blue[50]!;
//                           } else if (log.contains("⚠️") || log.contains("error")) {
//                             bgColor = Colors.red[50]!;
//                           }
//
//                           return Container(
//                             decoration: BoxDecoration(
//                               color: bgColor,
//                               border: const Border(
//                                 bottom: BorderSide(color: Colors.grey, width: 0.5),
//                               ),
//                             ),
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 6,
//                             ),
//                             child: SelectableText(
//                               log,
//                               style: const TextStyle(
//                                 fontFamily: 'Monospace',
//                                 fontSize: 12,
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Build a control button
//   Widget _buildControlButton(String label, String command, Color color) {
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//       ),
//       onPressed: () => _sendCommand(command, description: label),
//       child: Text(label),
//     );
//   }
// }



// import 'dart:async';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
//
// class BluetoothAdvancedPage extends StatefulWidget {
//   const BluetoothAdvancedPage({super.key});
//
//   @override
//   State<BluetoothAdvancedPage> createState() => _BluetoothAdvancedPageState();
// }
//
// class _BluetoothAdvancedPageState extends State<BluetoothAdvancedPage> {
//   BluetoothConnection? _connection;
//   BluetoothDevice? _selectedDevice;
//
//   bool _connected = false;
//   bool _isPairing = false;
//
//   final TextEditingController _inputController = TextEditingController();
//   final List<String> _logs = [];
//
//   StreamSubscription<BluetoothDiscoveryResult>? _discoveryStream;
//   List<BluetoothDiscoveryResult> _scanResults = [];
//
//   @override
//   void dispose() {
//     _discoveryStream?.cancel();
//     _connection?.dispose();
//     super.dispose();
//   }
//
//   /* --------------------------------------------------
//      🔍 Scan Unpaired + Paired Devices
//   -------------------------------------------------- */
//   void _startScan() {
//     _scanResults.clear();
//
//     _discoveryStream =
//         FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
//           setState(() {
//             if (!_scanResults.any(
//                     (r) => r.device.address == result.device.address)) {
//               _scanResults.add(result);
//             }
//           });
//         });
//
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Scan Bluetooth Devices"),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: ListView(
//             shrinkWrap: true,
//             children: _scanResults.map((r) {
//               return ListTile(
//                 leading: Icon(
//                   r.device.isBonded ? Icons.lock : Icons.bluetooth,
//                 ),
//                 title: Text(r.device.name ?? "Unknown"),
//                 subtitle: Text(r.device.address),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _selectDevice(r.device);
//                 },
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
//
//   /* --------------------------------------------------
//      🔐 Pair Device (PIN 1234 / 0000)
//   -------------------------------------------------- */
//   Future<void> _selectDevice(BluetoothDevice device) async {
//     _selectedDevice = device;
//
//     if (!device.isBonded) {
//       setState(() => _isPairing = true);
//
//       bool? bonded =
//       await FlutterBluetoothSerial.instance.bondDeviceAtAddress(
//         device.address,
//         pin: "1234",
//       );
//
//       if (bonded == true) {
//         _addLog("Paired with ${device.name}");
//       } else {
//         _addLog("Pairing failed or cancelled");
//       }
//
//     } else {
//       _addLog("Already paired with ${device.name}");
//     }
//   }
//
//   /* --------------------------------------------------
//      🔗 Connect
//   -------------------------------------------------- */
//   Future<void> _connect() async {
//     if (_selectedDevice == null) return;
//
//     try {
//       _connection = await BluetoothConnection.toAddress(
//           _selectedDevice!.address);
//
//       setState(() => _connected = true);
//       _listenIncomingData();
//       _addLog("Connected to ${_selectedDevice!.name}");
//     } catch (e) {
//       _addLog("Connection failed");
//     }
//   }
//
//   /* --------------------------------------------------
//      ❌ Disconnect
//   -------------------------------------------------- */
//   void _disconnect() {
//     _connection?.dispose();
//     setState(() {
//       _connected = false;
//       _connection = null;
//     });
//     _addLog("Disconnected");
//   }
//
//   /* --------------------------------------------------
//      📤 Send Data
//   -------------------------------------------------- */
//   void _send(String data) async {
//     if (!_connected) return;
//
//     _connection!.output.add(Uint8List.fromList("$data\n".codeUnits));
//     await _connection!.output.allSent;
//     _addLog("TX → $data");
//   }
//
//   /* --------------------------------------------------
//      📥 Receive Serial Data
//   -------------------------------------------------- */
//   void _listenIncomingData() {
//     _connection!.input!.listen((Uint8List data) {
//       String msg = String.fromCharCodes(data).trim();
//       _addLog("RX ← $msg");
//     }).onDone(() {
//       setState(() => _connected = false);
//       _addLog("Connection closed");
//     });
//   }
//
//   void _addLog(String msg) {
//     setState(() {
//       _logs.insert(
//         0,
//         "[${TimeOfDay.now().format(context)}] $msg",
//       );
//     });
//   }
//
//   /* --------------------------------------------------
//      🖥 UI
//   -------------------------------------------------- */
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Advanced Arduino / ESP Bluetooth App")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             ListTile(
//               leading: Icon(
//                 _connected
//                     ? Icons.bluetooth_connected
//                     : Icons.bluetooth_disabled,
//                 color: _connected ? Colors.green : Colors.red,
//               ),
//               title: Text(_connected
//                   ? "Connected: ${_selectedDevice?.name}"
//                   : "Not Connected"),
//               subtitle: _isPairing ? const Text("Pairing...") : null,
//             ),
//
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _startScan,
//                     child: const Text("Scan & Pair"),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _connected ? _disconnect : _connect,
//                     child:
//                     Text(_connected ? "Disconnect" : "Connect"),
//                   ),
//                 ),
//               ],
//             ),
//
//             const Divider(),
//
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green),
//                   onPressed: () => _send("1"),
//                   child: const Text("ON (1)"),
//                 ),
//                 ElevatedButton(
//                   style:
//                   ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                   onPressed: () => _send("0"),
//                   child: const Text("OFF (0)"),
//                 ),
//               ],
//             ),
//
//             const Divider(),
//
//             TextField(
//               controller: _inputController,
//               decoration: const InputDecoration(
//                 labelText: "Send Custom Data (123 / ABC)",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: () {
//                 if (_inputController.text.isNotEmpty) {
//                   _send(_inputController.text);
//                   _inputController.clear();
//                 }
//               },
//               child: const Text("Send"),
//             ),
//
//             const Divider(),
//
//             const Text(
//               "Serial Monitor (Live)",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 5),
//
//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration:
//                 BoxDecoration(border: Border.all(color: Colors.grey)),
//                 child: ListView(
//                   reverse: true,
//                   children: _logs.map((e) => Text(e)).toList(),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
