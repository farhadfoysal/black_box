// widgets/qr_display.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRDisplay extends StatelessWidget {
  final String ssid;
  final String password;

  const QRDisplay({required this.ssid, required this.password, super.key});

  @override
  Widget build(BuildContext context) {
    final data = "$ssid||$password";
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: 200,
    );
  }
}
