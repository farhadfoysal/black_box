import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/peer_device.dart';
import '../models/transfer_status.dart';
import 'local_server.dart';
import '../utils/network_utils.dart';
import '../utils/security_utils.dart';
import '../exceptions/p2p_exceptions.dart';

class ConnectionManager with ChangeNotifier {
  static const int _serverPort = 8080;
  static int get serverPort => _serverPort;
  static const int _discoveryTimeout = 2000;
  static const int _connectionTimeout = 5000;

  LocalServer? _localServer;
  final List<PeerDevice> _availableDevices = [];
  final List<TransferStatus> _activeTransfers = [];
  final List<Message> _messages = [];
  PeerDevice? _connectedDevice;
  bool _isServerRunning = false;
  bool _isDiscovering = false;
  String? _localDeviceId;
  Timer? _discoveryTimer;
  Timer? _connectionMonitor;
  final Uuid _uuid = const Uuid();

  // Public getters
  List<PeerDevice> get availableDevices => List.unmodifiable(_availableDevices);
  List<TransferStatus> get activeTransfers => List.unmodifiable(_activeTransfers);
  List<Message> get messages => List.unmodifiable(_messages);
  bool get isServerRunning => _isServerRunning;
  bool get isDiscovering => _isDiscovering;
  PeerDevice? get connectedDevice => _connectedDevice;
  String? get localDeviceId => _localDeviceId;

  ConnectionManager() {
    _localDeviceId = _uuid.v4();
    _init();
  }

  // Add to ConnectionManager
  Timer? _keepaliveTimer;

  void _startKeepalive() {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_connectedDevice == null) return;

      try {
        await http.get(
          Uri.parse('http://${_connectedDevice!.ipAddress}:$_serverPort/health'),
        ).timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Keepalive failed: $e');
        disconnect();
      }
    });
  }

// Call _startKeepalive() when connecting
// Call _keepaliveTimer?.cancel() when disconnecting

  Future<void> _init() async {
    await NetworkUtils.ensureNetworkPermissions();
  }

  Future<void> startServer({String? deviceName}) async {
    try {
      if (_isServerRunning) return;

      _localServer = LocalServer(
        onMessageReceived: _handleIncomingMessage,
        onFileReceived: _handleIncomingFile,
        deviceId: _localDeviceId!,
        deviceName: deviceName,
      );

      await _localServer!.start(_serverPort);
      _isServerRunning = true;

      _startDiscoveryTimer();
      notifyListeners();
    } catch (e, stackTrace) {
      throw P2PServerException(
        'Failed to start server: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> stopServer() async {
    try {
      await _localServer?.stop();
      _discoveryTimer?.cancel();
      _connectionMonitor?.cancel();
      _isServerRunning = false;
      notifyListeners();
    } catch (e, stackTrace) {
      throw P2PServerException(
        'Failed to stop server: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  void _startDiscoveryTimer() {
    _discoveryTimer?.cancel();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_isDiscovering) {
        discoverDevices();
      }
    });
  }

  Future<void> discoverDevices() async {
    if (_isDiscovering) return;

    _isDiscovering = true;
    notifyListeners();

    try {
      final devices = await NetworkUtils.scanLocalNetwork(
        port: _serverPort,
        timeout: _discoveryTimeout,
      );

      _availableDevices.clear();
      _availableDevices.addAll(devices);
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Discovery error: $e\n$stackTrace');
    } finally {
      _isDiscovering = false;
      notifyListeners();
    }
  }

  Future<void> connectToDevice(PeerDevice device) async {
    try {
      // Verify connection before proceeding
      final isReachable = await NetworkUtils.testConnection(
        device.ipAddress,
        _serverPort,
        timeout: const Duration(seconds: 2),
      );

      if (!isReachable) {
        throw P2PConnectionException('Device not reachable');
      }

      _connectedDevice = device;
      notifyListeners();

      _startConnectionMonitoring();

      // Send handshake message
      await sendMessage('Connection established', isSystemMessage: true);
    } catch (e, stackTrace) {
      _connectedDevice = null;
      notifyListeners();
      throw P2PConnectionException(
        'Failed to connect: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  void _startConnectionMonitoring() {
    _connectionMonitor?.cancel();
    _connectionMonitor = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnectionHealth();
    });
  }

  Future<void> _checkConnectionHealth() async {
    if (_connectedDevice == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://${_connectedDevice!.ipAddress}:$_serverPort/health'),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode != 200) {
        throw Exception('Health check failed');
      }
    } catch (e) {
      debugPrint('Connection health check failed: $e');
      disconnect();
    }
  }

  Future<void> disconnect() async {
    _connectionMonitor?.cancel();
    _connectedDevice = null;
    notifyListeners();
  }

  Future<void> sendMessage(
      String text, {
        bool isSystemMessage = false,
        String? filePath,
        String? fileName,
        int? fileSize,
      }) async {
    if (_connectedDevice == null && !isSystemMessage) {
      throw P2PConnectionException('No device connected');
    }

    final message = Message(
      text: text,
      senderId: _localDeviceId!,
      receiverId: _connectedDevice?.id,
      isSent: true,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
    );

    // Add to local messages immediately
    _messages.add(message);
    notifyListeners();

    if (isSystemMessage) return;

    try {
      final client = http.Client();
      try {
        final response = await client.post(
          Uri.parse('http://${_connectedDevice!.ipAddress}:$_serverPort/message'),
          body: jsonEncode(message.toJson()),
          headers: {
            'Content-Type': 'application/json',
            'Connection': 'close',
            'X-Sender-Id': _localDeviceId!,
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['status'] == 'received') {
            message.status = MessageStatus.delivered;
          } else {
            message.status = MessageStatus.failed;
          }
        } else {
          message.status = MessageStatus.failed;
        }
        notifyListeners();
      } finally {
        client.close();
      }
    } catch (e, stackTrace) {
      message.status = MessageStatus.failed;
      notifyListeners();
      debugPrint('Message send error: $e\n$stackTrace');
    }
  }

  Future<void> sendFile(File file) async {
    if (_connectedDevice == null) {
      throw P2PConnectionException('No device connected');
    }

    final fileName = file.path.split('/').last;
    final fileSize = await file.length();
    final transferId = _uuid.v4();

    final transfer = TransferStatus(
      id: transferId,
      fileName: fileName,
      fileSize: fileSize,
      status: TransferStatusType.inProgress,
    );

    _activeTransfers.add(transfer);
    notifyListeners();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://${_connectedDevice!.ipAddress}:$_serverPort/file'),
      );

      request.headers['X-Sender-Id'] = _localDeviceId!;
      request.headers['X-Transfer-Id'] = transferId;

      final fileStream = file.openRead();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileSize,
        filename: fileName,
      );

      int bytesSent = 0;
      multipartFile.finalize().listen(
            (chunk) {
          bytesSent += chunk.length;
          final progress = (bytesSent / fileSize * 100).toInt();
          final updatedTransfer = transfer.copyWith(progress: progress);
          _updateTransfer(updatedTransfer);
        },
        onDone: () {
          final completedTransfer = transfer.copyWith(
            progress: 100,
            status: TransferStatusType.completed,
            endTime: DateTime.now(),
          );
          _updateTransfer(completedTransfer);
        },
        onError: (e) {
          final failedTransfer = transfer.copyWith(
            status: TransferStatusType.failed,
            endTime: DateTime.now(),
          );
          _updateTransfer(failedTransfer);
          throw e;
        },
      );

      request.files.add(multipartFile);
      final response = await request.send()
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('File transfer failed: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('File transfer error: $e\n$stackTrace');
      final failedTransfer = transfer.copyWith(
        status: TransferStatusType.failed,
        endTime: DateTime.now(),
      );
      _updateTransfer(failedTransfer);
      rethrow;
    }
  }

  void _updateTransfer(TransferStatus updatedTransfer) {
    final index = _activeTransfers.indexWhere((t) => t.id == updatedTransfer.id);
    if (index != -1) {
      _activeTransfers[index] = updatedTransfer;
      notifyListeners();
    }
  }

  // void _handleIncomingMessage(Message message) {
  //   // Prevent duplicate messages
  //   if (!_messages.any((m) => m.id == message.id)) {
  //     message.isSent = false; // Mark as received message
  //     _messages.add(message);
  //     notifyListeners();
  //
  //     // Send delivery confirmation
  //     if (message.senderId != _localDeviceId) {
  //       _sendDeliveryConfirmation(message);
  //     }
  //   }
  // }

  Future<void> _sendDeliveryConfirmation(Message message) async {
    try {
      final client = http.Client();
      try {
        await client.post(
          Uri.parse('http://${message.senderId}:$_serverPort/confirm'),
          body: jsonEncode({
            'messageId': message.id,
            'status': 'delivered',
            'timestamp': DateTime.now().toIso8601String(),
          }),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 2));
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Failed to send delivery confirmation: $e');
    }
  }

  void _handleIncomingFile(TransferStatus transfer) {
    if (!_activeTransfers.any((t) => t.id == transfer.id)) {
      transfer.isIncoming = true;
      _activeTransfers.add(transfer);
      notifyListeners();

      sendMessage(
        'Received file: ${transfer.fileName}',
        isSystemMessage: true,
        filePath: transfer.fileName,
        fileSize: transfer.fileSize,
      );
    }
  }

  void _handleIncomingMessage(Message message) {
    // Ensure message isn't duplicated and comes from another device
    if (!_messages.any((m) => m.id == message.id) && message.senderId != _localDeviceId) {
      // Mark as received message (not sent by this device)
      message.isSent = false;

      // Add to messages list
      _messages.add(message);

      // Notify listeners to update UI
      notifyListeners();

      debugPrint('Received message from ${message.senderId}: ${message.text}');

      // Send delivery confirmation
      _sendDeliveryConfirmation(message);
    }
  }

  // // In ConnectionManager
  // void _handleIncomingMessage(Message message) {
  //   // Ensure message isn't duplicated
  //   if (!_messages.any((m) => m.id == message.id)) {
  //     _messages.add(message);
  //     notifyListeners();
  //     debugPrint('New message received: ${message.text}');
  //   } else {
  //     debugPrint('Duplicate message ignored: ${message.id}');
  //   }
  // }

  @override
  void dispose() {
    _discoveryTimer?.cancel();
    _connectionMonitor?.cancel();
    _localServer?.stop();
    super.dispose();
  }

  // Debug utilities
  void debugPrintMessages() {
    debugPrint('=== Current Messages ===');
    for (final msg in _messages) {
      debugPrint('${msg.isSent ? "Sent" : "Received"}: ${msg.text}');
      debugPrint('Status: ${msg.status}');
      debugPrint('Timestamp: ${msg.timestamp}');
      debugPrint('---');
    }
  }

  void debugPrintConnections() {
    debugPrint('=== Connection Status ===');
    debugPrint('Server running: $_isServerRunning');
    debugPrint('Connected device: ${_connectedDevice?.name ?? "None"}');
    debugPrint('Local device ID: $_localDeviceId');
  }

  void debugConnectionStatus() {
    debugPrint('''
  Connection Status:
  - Server Running: $_isServerRunning
  - Connected Device: ${_connectedDevice?.name ?? 'None'}
  - Local IP: ${NetworkUtils.getLocalIp()}
  - Messages: ${_messages.length} total
  ''');
  }

  void debugLastMessage() {
    if (_messages.isEmpty) {
      debugPrint('No messages sent/received');
      return;
    }

    final last = _messages.last;
    debugPrint('''
  Last Message:
  - Text: ${last.text}
  - Status: ${last.status}
  - Sent: ${last.isSent}
  - Timestamp: ${last.timestamp}
  - Sender: ${last.senderId}
  - Receiver: ${last.receiverId}
  ''');
  }

}


// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:uuid/uuid.dart';
// import '../models/message.dart';
// import '../models/peer_device.dart';
// import '../models/transfer_status.dart';
// import 'local_server.dart';
// import '../utils/network_utils.dart';
// import '../utils/security_utils.dart';
// import '../exceptions/p2p_exceptions.dart';
//
// class ConnectionManager with ChangeNotifier {
//   static const int _serverPort = 8080;
//   static const int _discoveryTimeout = 2000; // ms
//   static const int _connectionTimeout = 5000; // ms
//
//   LocalServer? _localServer;
//   final List<PeerDevice> _availableDevices = [];
//   final List<TransferStatus> _activeTransfers = [];
//   final List<Message> _messages = [];
//   PeerDevice? _connectedDevice;
//   bool _isServerRunning = false;
//   bool _isDiscovering = false;
//   String? _localDeviceId;
//   Timer? _discoveryTimer;
//   Timer? _connectionMonitor;
//   final Uuid _uuid = const Uuid();
//
//   // Public getters
//   List<PeerDevice> get availableDevices => List.unmodifiable(_availableDevices);
//   List<TransferStatus> get activeTransfers => List.unmodifiable(_activeTransfers);
//   List<Message> get messages => List.unmodifiable(_messages);
//   bool get isServerRunning => _isServerRunning;
//   bool get isDiscovering => _isDiscovering;
//   PeerDevice? get connectedDevice => _connectedDevice;
//   String? get localDeviceId => _localDeviceId;
//
//   ConnectionManager() {
//     _localDeviceId = _uuid.v4();
//     _init();
//   }
//
//   Future<void> _init() async {
//     await NetworkUtils.ensureNetworkPermissions();
//   }
//
//   Future<void> startServer({String? deviceName}) async {
//     try {
//       if (_isServerRunning) return;
//
//       _localServer = LocalServer(
//         onMessageReceived: _handleIncomingMessage,
//         onFileReceived: _handleIncomingFile,
//         deviceId: _localDeviceId!,
//         deviceName: deviceName,
//       );
//
//       await _localServer!.start(_serverPort);
//       _isServerRunning = true;
//
//       // Start periodic discovery
//       _startDiscoveryTimer();
//
//       notifyListeners();
//     } catch (e, stackTrace) {
//       throw P2PServerException(
//         'Failed to start server: ${e.toString()}',
//         stackTrace: stackTrace,
//       );
//     }
//   }
//
//   Future<void> stopServer() async {
//     try {
//       await _localServer?.stop();
//       _discoveryTimer?.cancel();
//       _connectionMonitor?.cancel();
//       _isServerRunning = false;
//       notifyListeners();
//     } catch (e, stackTrace) {
//       throw P2PServerException(
//         'Failed to stop server: ${e.toString()}',
//         stackTrace: stackTrace,
//       );
//     }
//   }
//
//   void _startDiscoveryTimer() {
//     _discoveryTimer?.cancel();
//     _discoveryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
//       discoverDevices();
//     });
//   }
//
//   Future<void> discoverDevices() async {
//     if (_isDiscovering) return;
//
//     _isDiscovering = true;
//     notifyListeners();
//
//     try {
//       final devices = await NetworkUtils.scanLocalNetwork(
//         port: _serverPort,
//         timeout: _discoveryTimeout,
//       );
//
//       _availableDevices.clear();
//       _availableDevices.addAll(devices);
//       notifyListeners();
//     } catch (e, stackTrace) {
//       throw P2PDiscoveryException(
//         'Device discovery failed: ${e.toString()}',
//         stackTrace: stackTrace,
//       );
//     } finally {
//       _isDiscovering = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> connectToDevice(PeerDevice device) async {
//     try {
//       _connectedDevice = device;
//       notifyListeners();
//
//       // Start connection monitoring
//       _connectionMonitor?.cancel();
//       _connectionMonitor = Timer.periodic(const Duration(seconds: 5), (_) {
//         _checkConnectionHealth();
//       });
//
//       // Send a hello message to establish connection
//       await sendMessage('Connection established', isSystemMessage: true);
//     } catch (e, stackTrace) {
//       _connectedDevice = null;
//       notifyListeners();
//       throw P2PConnectionException(
//         'Failed to connect to device: ${e.toString()}',
//         stackTrace: stackTrace,
//       );
//     }
//   }
//
//   Future<void> disconnect() async {
//     _connectionMonitor?.cancel();
//     _connectedDevice = null;
//     notifyListeners();
//   }
//
//   Future<void> _checkConnectionHealth() async {
//     if (_connectedDevice == null) return;
//
//     try {
//       final response = await http.get(
//         Uri.parse('http://${_connectedDevice!.ipAddress}:$_serverPort/health'),
//         headers: {'Connection': 'close'},
//       ).timeout(const Duration(seconds: 2));
//
//       if (response.statusCode != 200) {
//         disconnect();
//       }
//     } catch (_) {
//       disconnect();
//     }
//   }
//
//   Future<void> sendMessage(String text, {bool isSystemMessage = false}) async {
//     if (_connectedDevice == null && !isSystemMessage) {
//       throw P2PConnectionException('No device connected');
//     }
//
//     final message = Message(
//       text: text,
//       senderId: _localDeviceId!,
//       receiverId: _connectedDevice?.id,
//       isSent: true,
//     );
//
//     // Add to local messages immediately
//     _messages.add(message);
//     notifyListeners();
//
//     if (isSystemMessage) return;
//
//     try {
//       final client = http.Client();
//       try {
//         final response = await client.post(
//           Uri.parse('http://${_connectedDevice!.ipAddress}:$_serverPort/message'),
//           body: jsonEncode(message.toJson()),
//           headers: {
//             'Content-Type': 'application/json',
//             'Connection': 'close',
//           },
//         ).timeout(const Duration(seconds: 5));
//
//         if (response.statusCode == 200) {
//           message.status = MessageStatus.delivered;
//         } else {
//           message.status = MessageStatus.failed;
//           debugPrint('Message failed with status: ${response.statusCode}');
//         }
//         notifyListeners();
//       } finally {
//         client.close();
//       }
//     } catch (e, stackTrace) {
//       message.status = MessageStatus.failed;
//       notifyListeners();
//       debugPrint('Message send error: $e\n$stackTrace');
//     }
//   }
//
//   // Future<void> sendMessage(
//   //     String text, {
//   //       bool isSystemMessage = false,
//   //       String? filePath,
//   //       String? fileName,
//   //       int? fileSize,
//   //     }) async {
//   //   if (_connectedDevice == null && !isSystemMessage) {
//   //     throw P2PConnectionException('No device connected');
//   //   }
//   //
//   //   final message = Message(
//   //     text: text,
//   //     senderId: _localDeviceId!,
//   //     receiverId: _connectedDevice?.id,
//   //     isSent: true,
//   //     filePath: filePath,
//   //     fileName: fileName,
//   //     fileSize: fileSize,
//   //   );
//   //
//   //   _messages.add(message);
//   //   notifyListeners();
//   //
//   //   try {
//   //     if (!isSystemMessage) {
//   //       await _sendMessageToDevice(message);
//   //     }
//   //   } catch (e, stackTrace) {
//   //     message.status = MessageStatus.failed;
//   //     notifyListeners();
//   //     throw P2PMessageException(
//   //       'Failed to send message: ${e.toString()}',
//   //       stackTrace: stackTrace,
//   //     );
//   //   }
//   // }
//
//   Future<void> _sendMessageToDevice(Message message) async {
//     final client = http.Client();
//     try {
//       final response = await client.post(
//         Uri.parse('http://${_connectedDevice!.ipAddress}:$_serverPort/message'),
//         body: jsonEncode(message.toJson()),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': SecurityUtils.generateMessageAuthHeader(
//             message.id,
//             _localDeviceId!,
//           ),
//         },
//       ).timeout(const Duration(milliseconds: _connectionTimeout));
//
//       if (response.statusCode == 200) {
//         message.status = MessageStatus.delivered;
//       } else {
//         message.status = MessageStatus.failed;
//       }
//       notifyListeners();
//     } finally {
//       client.close();
//     }
//   }
//
//   Future<void> sendFile(File file) async {
//     if (_connectedDevice == null) {
//       throw P2PConnectionException('No device connected');
//     }
//
//     final fileName = file.path.split('/').last;
//     final fileSize = await file.length();
//     final transferId = _uuid.v4();
//
//     final transfer = TransferStatus(
//       fileName: fileName,
//       fileSize: fileSize,
//       status: TransferStatusType.inProgress,
//     );
//
//     _activeTransfers.add(transfer);
//     notifyListeners();
//
//     try {
//       final request = http.MultipartRequest(
//         'POST',
//         Uri.parse('http://${_connectedDevice!.ipAddress}:$_serverPort/file'),
//       );
//
//       request.headers['Authorization'] = SecurityUtils.generateMessageAuthHeader(
//         transferId,
//         _localDeviceId!,
//       );
//
//       final fileStream = file.openRead();
//       final multipartFile = http.MultipartFile(
//         'file',
//         fileStream,
//         fileSize,
//         filename: fileName,
//       );
//
//       int bytesSent = 0;
//       multipartFile.finalize().listen(
//             (chunk) {
//           bytesSent += chunk.length;
//           final progress = (bytesSent / fileSize * 100).toInt();
//           final updatedTransfer = transfer.copyWith(
//             progress: progress.clamp(0, 100),
//           );
//           _updateTransfer(updatedTransfer);
//         },
//         onDone: () {
//           final completedTransfer = transfer.copyWith(
//             progress: 100,
//             status: TransferStatusType.completed,
//             endTime: DateTime.now(),
//           );
//           _updateTransfer(completedTransfer);
//         },
//         onError: (e) {
//           final failedTransfer = transfer.copyWith(
//             status: TransferStatusType.failed,
//             endTime: DateTime.now(),
//           );
//           _updateTransfer(failedTransfer);
//           throw e;
//         },
//       );
//
//       request.files.add(multipartFile);
//       final response = await request.send()
//           .timeout(const Duration(milliseconds: _connectionTimeout));
//
//       if (response.statusCode != 200) {
//         throw Exception('File transfer failed with status ${response.statusCode}');
//       }
//     } catch (e, stackTrace) {
//       final failedTransfer = transfer.copyWith(
//         status: TransferStatusType.failed,
//         endTime: DateTime.now(),
//       );
//       _updateTransfer(failedTransfer);
//       throw P2PFileTransferException(
//         'File transfer failed: ${e.toString()}',
//         stackTrace: stackTrace,
//       );
//     }
//   }
//
//   void _updateTransfer(TransferStatus updatedTransfer) {
//     final index = _activeTransfers.indexWhere((t) => t.id == updatedTransfer.id);
//     if (index != -1) {
//       _activeTransfers[index] = updatedTransfer;
//       notifyListeners();
//     }
//   }
//
//   void _handleIncomingMessage(Message message) {
//     _messages.add(message);
//     notifyListeners();
//   }
//
//   void _handleIncomingFile(TransferStatus transfer) {
//     _activeTransfers.add(transfer);
//     notifyListeners();
//
//     // Create a message for the received file
//     sendMessage(
//       'Received file: ${transfer.fileName}',
//       isSystemMessage: true,
//       filePath: transfer.fileName,
//       fileSize: transfer.fileSize,
//     );
//   }
//
//   @override
//   void dispose() {
//     _discoveryTimer?.cancel();
//     _connectionMonitor?.cancel();
//     _localServer?.stop();
//     super.dispose();
//   }
// }