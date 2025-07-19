import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/transfer_status.dart';
import '../utils/network_utils.dart';
import '../utils/security_utils.dart';
import '../exceptions/p2p_exceptions.dart';

typedef MessageHandler = void Function(Message message);
typedef FileHandler = void Function(TransferStatus transfer);

class LocalServer {
  final MessageHandler onMessageReceived;
  final FileHandler onFileReceived;
  final String deviceId;
  final String? deviceName;
  final bool enableLogging;
  final String? customTempDirectory;

  HttpServer? _server;
  late final Router _router;
  final Uuid _uuid = const Uuid();
  DateTime? _serverStartTime;

  LocalServer({
    required this.onMessageReceived,
    required this.onFileReceived,
    required this.deviceId,
    this.deviceName,
    this.enableLogging = true,
    this.customTempDirectory,
  }) {
    _router = Router()
      ..post('/message', _handleMessage)
      ..post('/file', _handleFileUpload)
      ..get('/status', _handleStatusRequest)
      ..get('/health', _handleHealthCheck);
  }

  Future<void> start(int port) async {
    try {
      final localIp = await NetworkUtils.getLocalIp();
      if (localIp == null) {
        throw P2PServerException('Could not determine local IP address');
      }

      _server = await io.serve(
        _router,
        InternetAddress(localIp),
        port,
        shared: true,
      ).timeout(const Duration(seconds: 10));

      _serverStartTime = DateTime.now();

      if (enableLogging) {
        debugPrint('P2P Server started on http://$localIp:$port');
        debugPrint('Device ID: $deviceId');
      }
    } catch (e, stackTrace) {
      throw P2PServerException(
        'Server start failed: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> stop() async {
    try {
      await _server?.close().timeout(const Duration(seconds: 5));
      _server = null;
      _serverStartTime = null;
    } catch (e, stackTrace) {
      throw P2PServerException(
        'Server stop failed: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  Future<Response> _handleMessage(Request request) async {
    try {
      // Verify authorization
      final authHeader = request.headers['Authorization'];
      if (!SecurityUtils.verifyMessageAuthHeader(
        authHeader,
        expectedDeviceId: deviceId,
      )) {
        return Response.unauthorized('Invalid authorization');
      }

      final messageJson = await request.readAsString();
      final messageData = jsonDecode(messageJson) as Map<String, dynamic>;
      final message = Message.fromJson(messageData);

      // Process the message
      onMessageReceived(message);

      return Response.ok(
        jsonEncode({'status': 'success'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      debugPrint('Message handling error: $e\n$stackTrace');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Message processing failed'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _handleFileUpload(Request request) async {
    String? transferId;
    try {
      // Verify authorization
      final authHeader = request.headers['Authorization'];
      if (!SecurityUtils.verifyMessageAuthHeader(
        authHeader,
        expectedDeviceId: deviceId,
      )) {
        return Response.unauthorized('Invalid authorization');
      }

      transferId = authHeader?.split('|').firstOrNull;
      final contentLength = request.contentLength;
      if (contentLength == null || contentLength <= 0) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid file size'}),
        );
      }

      final contentType = request.headers['content-type'] ?? 'application/octet-stream';
      final fileName = request.headers['x-file-name'] ?? 'file_${_uuid.v4()}';
      final extension = fileName.contains('.') ? '.${fileName.split('.').last}' : '';

      final tempDir = await _getTempDirectory();
      final uniqueFileName = '${_uuid.v4()}$extension';
      final filePath = '${tempDir.path}/$uniqueFileName';
      final file = File(filePath);

      // Create transfer status
      final transfer = TransferStatus(
        id: transferId ?? _uuid.v4(),
        fileName: fileName,
        fileSize: contentLength,
        status: TransferStatusType.inProgress,
        isIncoming: true,
      );
      onFileReceived(transfer);

      // Write the file
      final sink = file.openWrite();
      int receivedBytes = 0;
      const int logInterval = 1024 * 1024; // 1MB
      int nextLog = logInterval;

      await request.read().listen(
            (chunk) {
          receivedBytes += chunk.length;
          sink.add(chunk);

          // Update progress
          final progress = (receivedBytes / contentLength * 100).toInt();
          final updatedTransfer = transfer.copyWith(
            progress: progress.clamp(0, 100),
          );
          onFileReceived(updatedTransfer);

          if (enableLogging && receivedBytes >= nextLog) {
            debugPrint('Received ${receivedBytes ~/ (1024 * 1024)}MB of $fileName');
            nextLog += logInterval;
          }
        },
        onDone: () async {
          await sink.close();
          if (enableLogging) {
            debugPrint('File saved to $filePath');
          }

          // Mark transfer as complete
          final completedTransfer = transfer.copyWith(
            progress: 100,
            status: TransferStatusType.completed,
            endTime: DateTime.now(),
          );
          onFileReceived(completedTransfer);
        },
        onError: (e) {
          sink.close();
          debugPrint('File upload error: $e');

          final failedTransfer = transfer.copyWith(
            status: TransferStatusType.failed,
            endTime: DateTime.now(),
          );
          onFileReceived(failedTransfer);
          throw e;
        },
      ).asFuture();

      return Response.ok(
        jsonEncode({
          'status': 'success',
          'filePath': filePath,
          'fileName': fileName,
          'size': receivedBytes,
        }),
      );
    } catch (e, stackTrace) {
      debugPrint('File upload failed: $e\n$stackTrace');
      return Response.internalServerError(
        body: jsonEncode({'error': 'File upload failed'}),
      );
    }
  }

  Future<Directory> _getTempDirectory() async {
    if (customTempDirectory != null) {
      return Directory(customTempDirectory!).create(recursive: true);
    }
    return getTemporaryDirectory();
  }

  Response _handleStatusRequest(Request request) {
    return Response.ok(
      jsonEncode({
        'status': 'running',
        'deviceId': deviceId,
        'deviceName': deviceName,
        'uptime': _serverStartTime != null
            ? DateTime.now().difference(_serverStartTime!).inSeconds
            : 0,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _handleHealthCheck(Request request) {
    return Response.ok(
      jsonEncode({'status': 'healthy'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}


// import 'dart:io';
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart' as io;
// import 'package:shelf_router/shelf_router.dart';
// import 'package:mime/mime.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:uuid/uuid.dart';
//
// typedef MessageHandler = void Function(String message, String? senderIp);
// typedef FileHandler = void Function(ReceivedFile file);
//
// class ReceivedFile {
//   final File file;
//   final String originalName;
//   final String mimeType;
//   final int size;
//
//   ReceivedFile({
//     required this.file,
//     required this.originalName,
//     required this.mimeType,
//     required this.size,
//   });
//
//   String get path => file.path;
// }
//
// class LocalServer {
//   final MessageHandler onMessageReceived;
//   final FileHandler onFileReceived;
//   final int port;
//   final bool enableLogging;
//   final String? customTempDirectory;
//
//   HttpServer? _server;
//   late final Router _router;
//   final Uuid _uuid = const Uuid();
//   DateTime? _serverStartTime;
//
//   LocalServer({
//     required this.onMessageReceived,
//     required this.onFileReceived,
//     this.port = 8080,
//     this.enableLogging = true,
//     this.customTempDirectory,
//   }) {
//     _router = Router()
//       ..post('/message', _handleMessage)
//       ..post('/file', _handleFileUpload)
//       ..get('/status', _handleStatusRequest)
//       ..get('/info', _handleInfoRequest);
//   }
//
//   Future<void> start() async {
//     try {
//       _server = await io.serve(
//         _router,
//         InternetAddress.anyIPv4,
//         port,
//         shared: true,
//       ).timeout(const Duration(seconds: 10));
//
//       _serverStartTime = DateTime.now();
//
//       if (enableLogging) {
//         debugPrint('Server started on port ${_server?.port}');
//         debugPrint('Local IP: ${await _getLocalIp()}');
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Failed to start server: $e');
//       debugPrint(stackTrace.toString());
//       rethrow;
//     }
//   }
//
//   Future<void> stop() async {
//     try {
//       await _server?.close().timeout(const Duration(seconds: 5));
//       _server = null;
//       _serverStartTime = null;
//       if (enableLogging) {
//         debugPrint('Server stopped');
//       }
//     } catch (e) {
//       debugPrint('Error stopping server: $e');
//       rethrow;
//     }
//   }
//
//   Future<String> _getLocalIp() async {
//     try {
//       for (final interface in await NetworkInterface.list()) {
//         for (final addr in interface.addresses) {
//           if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
//             return addr.address;
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Error getting local IP: $e');
//     }
//     return '0.0.0.0';
//   }
//
//   Future<Directory> _getTempDirectory() async {
//     if (customTempDirectory != null) {
//       return Directory(customTempDirectory!).create(recursive: true);
//     }
//     return getTemporaryDirectory();
//   }
//
//   Future<Response> _handleMessage(Request request) async {
//     String? clientIp;
//
//     try {
//       // Get client IP from headers or connection info
//       clientIp = request.headers['x-forwarded-for'] ??
//           request.headers['x-real-ip'] ??
//           (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)?.remoteAddress.address;
//
//       if (enableLogging) {
//         debugPrint('Message request received from $clientIp');
//       }
//
//       final message = await request.readAsString();
//
//       if (message.isEmpty) {
//         return Response.badRequest(
//           body: jsonEncode({'error': 'Empty message'}),
//           headers: {'Content-Type': 'application/json'},
//         );
//       }
//
//       onMessageReceived(message, clientIp);
//
//       return Response.ok(
//         jsonEncode({'status': 'success', 'message': 'Message processed'}),
//         headers: {'Content-Type': 'application/json'},
//       );
//     } catch (e, stackTrace) {
//       debugPrint('Error handling message from $clientIp: $e');
//       debugPrint(stackTrace.toString());
//       return Response.internalServerError(
//         body: jsonEncode({'error': 'Failed to process message'}),
//         headers: {'Content-Type': 'application/json'},
//       );
//     }
//   }
//
//   Future<Response> _handleFileUpload(Request request) async {
//     String? clientIp;
//
//     try {
//       // Get client IP from headers or connection info
//       clientIp = request.headers['x-forwarded-for'] ??
//           request.headers['x-real-ip'] ??
//           (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)?.remoteAddress.address;
//
//       if (enableLogging) {
//         debugPrint('File upload request received from $clientIp');
//       }
//
//       final contentLength = request.contentLength;
//       if (contentLength == null || contentLength <= 0) {
//         return Response.badRequest(
//           body: jsonEncode({'error': 'Invalid content length'}),
//           headers: {'Content-Type': 'application/json'},
//         );
//       }
//
//       final contentType = request.headers['content-type'] ?? 'application/octet-stream';
//       final originalName = request.headers['x-file-name'] ?? 'file_${_uuid.v4()}';
//       final extension = originalName.contains('.')
//           ? '.${originalName.split('.').last}'
//           : '';
//
//       final tempDir = await _getTempDirectory();
//       final fileName = '${_uuid.v4()}$extension';
//       final filePath = '${tempDir.path}/$fileName';
//       final file = File(filePath);
//
//       // Start writing the file
//       final sink = file.openWrite();
//       int receivedBytes = 0;
//       const int logInterval = 1024 * 1024; // Log every 1MB
//       int nextLog = logInterval;
//
//       await request.read().listen(
//             (List<int> chunk) {
//           receivedBytes += chunk.length;
//           sink.add(chunk);
//
//           if (enableLogging && receivedBytes >= nextLog) {
//             debugPrint('Received ${receivedBytes / (1024 * 1024)} MB of $contentLength bytes');
//             nextLog += logInterval;
//           }
//         },
//         onDone: () async {
//           await sink.close();
//           if (enableLogging) {
//             debugPrint('File saved to $filePath');
//           }
//         },
//         onError: (e) {
//           sink.close();
//           debugPrint('File upload error: $e');
//           throw e;
//         },
//       ).asFuture();
//
//       final receivedFile = ReceivedFile(
//         file: file,
//         originalName: originalName,
//         mimeType: contentType,
//         size: contentLength,
//       );
//
//       onFileReceived(receivedFile);
//
//       return Response.ok(
//         jsonEncode({
//           'status': 'success',
//           'path': filePath,
//           'size': file.lengthSync(),
//           'originalName': originalName,
//         }),
//         headers: {'Content-Type': 'application/json'},
//       );
//     } catch (e, stackTrace) {
//       debugPrint('Error handling file upload from $clientIp: $e');
//       debugPrint(stackTrace.toString());
//       return Response.internalServerError(
//         body: jsonEncode({'error': 'Failed to process file upload'}),
//         headers: {'Content-Type': 'application/json'},
//       );
//     }
//   }
//
//   Response _handleStatusRequest(Request request) {
//     return Response.ok(
//       jsonEncode({
//         'status': 'running',
//         'timestamp': DateTime.now().toIso8601String(),
//         'uptime': _serverStartTime != null
//             ? DateTime.now().difference(_serverStartTime!).inSeconds
//             : 0,
//       }),
//       headers: {'Content-Type': 'application/json'},
//     );
//   }
//
//   Response _handleInfoRequest(Request request) {
//     return Response.ok(
//       jsonEncode({
//         'server': 'Flutter P2P Server',
//         'version': '1.0.0',
//         'endpoints': {
//           'POST /message': 'Send a text message',
//           'POST /file': 'Upload a file',
//           'GET /status': 'Check server status',
//           'GET /info': 'Get server information',
//         },
//       }),
//       headers: {'Content-Type': 'application/json'},
//     );
//   }
// }