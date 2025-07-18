import 'dart:io';
import 'dart:convert';
import 'dart:typed_data'; // ✅ Proper import for Uint8List
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart';


class FileTransferServer {
  late HttpServer _server;
  final int port;
  final String sharedDirectory;
  final String? encryptionKey;

  late final Encrypter _encrypter;
  late final IV _iv;

  FileTransferServer({
    this.port = 8080,
    required this.sharedDirectory,
    this.encryptionKey,
  }) {
    if (encryptionKey != null) {
      final key = Key.fromUtf8(encryptionKey!);
      _encrypter = Encrypter(AES(key));
      _iv = IV.fromLength(16);
    }
  }

  Future<void> start() async {
    final directory = Directory(sharedDirectory);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print('Server running on ${_server.address}:${_server.port}');

    await for (HttpRequest request in _server) {
      try {
        if (request.method == 'GET') {
          await _handleGetRequest(request);
        } else if (request.method == 'POST') {
          await _handlePostRequest(request);
        } else if (request.method == 'OPTIONS') {
          await _handleOptionsRequest(request);
        } else {
          request.response.statusCode = HttpStatus.methodNotAllowed;
          request.response.write('Method not allowed');
          await request.response.close();
        }
      } catch (e) {
        print('Error handling request: $e');
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Internal server error');
        await request.response.close();
      }
    }
  }

  Future<void> _handleOptionsRequest(HttpRequest request) async {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
    request.response.statusCode = HttpStatus.ok;
    await request.response.close();
  }

  Future<void> _handleGetRequest(HttpRequest request) async {
    final filePath = request.uri.pathSegments.join('/');
    final file = File('$sharedDirectory/$filePath');

    if (await file.exists()) {
      request.response.headers.contentType = ContentType.binary;

      if (encryptionKey != null) {
        final fileBytes = await file.readAsBytes();
        final encrypted = _encrypter.encryptBytes(fileBytes, iv: _iv);
        await request.response.addStream(Stream.value(encrypted.bytes));
      } else {
        await request.response.addStream(file.openRead());
      }
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('File not found');
    }

    await request.response.close();
  }

  Future<void> _handlePostRequest(HttpRequest request) async {
    final filePath = request.uri.pathSegments.join('/');
    final file = File('$sharedDirectory/$filePath');
    await file.create(recursive: true);

    final List<int> bytes = [];
    await request.listen((data) {
      bytes.addAll(data);
    }).asFuture();

    if (encryptionKey != null) {
      final encrypted = Encrypted(Uint8List.fromList(bytes));
      final decrypted = _encrypter.decryptBytes(encrypted, iv: _iv);
      await file.writeAsBytes(decrypted);
    } else {
      await file.writeAsBytes(bytes);
    }

    request.response.statusCode = HttpStatus.ok;
    request.response.write('File uploaded successfully');
    await request.response.close();
  }

  Future<void> stop() async {
    await _server.close();
    print('Server stopped');
  }
}