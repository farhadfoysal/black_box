import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:uuid/uuid.dart';

class ConnectionData {
  final String ssid;
  final String password;
  final String serverIp;
  final int port;
  late final String? sessionId;
  late final String? encryptionKey;

  ConnectionData({
    required this.ssid,
    required this.password,
    required this.serverIp,
    this.port = 8080,
    this.sessionId,
    this.encryptionKey,
  }) {
    sessionId ??= const Uuid().v4();
    encryptionKey ??= _generateEncryptionKey();
  }

  String _generateEncryptionKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  factory ConnectionData.fromJson(Map<String, dynamic> json) {
    return ConnectionData(
      ssid: json['ssid'],
      password: json['password'],
      serverIp: json['serverIp'],
      port: json['port'] ?? 8080,
      sessionId: json['sessionId'],
      encryptionKey: json['encryptionKey'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'password': password,
      'serverIp': serverIp,
      'port': port,
      'sessionId': sessionId,
      'encryptionKey': encryptionKey,
    };
  }

  String toEncodedString() {
    return Uri.encodeComponent(jsonEncode(toJson()));
  }

  static ConnectionData? fromEncodedString(String encoded) {
    try {
      final decoded = Uri.decodeComponent(encoded);
      return ConnectionData.fromJson(jsonDecode(decoded));
    } catch (e) {
      return null;
    }
  }
}