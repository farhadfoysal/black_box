import 'package:crypto/crypto.dart';
import 'dart:convert';

class SecurityUtils {
  static const String _secretKey = 'your-secure-key'; // In production, use secure storage

  static String generateMessageAuthHeader(String messageId, String deviceId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = sha256.convert(utf8.encode('$messageId|$deviceId|$timestamp|$_secretKey'));
    return '$messageId|$deviceId|$timestamp|${hash.toString()}';
  }

  static bool verifyMessageAuthHeader(String? header, {required String expectedDeviceId}) {
    if (header == null) return false;

    final parts = header.split('|');
    if (parts.length != 4) return false;

    final [messageId, deviceId, timestampStr, receivedHash] = parts;
    if (deviceId != expectedDeviceId) return false;

    final timestamp = int.tryParse(timestampStr) ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - timestamp > 30000) {
      return false; // Expired after 30 seconds
    }

    final expectedHash = sha256.convert(
      utf8.encode('$messageId|$deviceId|$timestampStr|$_secretKey'),
    ).toString();

    return receivedHash == expectedHash;
  }
}