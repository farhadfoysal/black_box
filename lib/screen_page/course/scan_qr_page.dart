import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrPage extends StatelessWidget {
  const ScanQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String code = barcode.rawValue ?? "---";
            Navigator.pop(context); // close scanner
            // handle enrollment by code
            _enrollCourseById(context, code);
            break;
          }
        },
      ),
    );
  }

  void _enrollCourseById(BuildContext context, String uniqueId) {
    // Call the original _enrollCourseById from your stateful class
    Navigator.pop(context); // return to previous page
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Found ID: $uniqueId")));
    // or trigger your enrollment logic here.
  }
}
