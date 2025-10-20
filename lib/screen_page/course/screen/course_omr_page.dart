import 'dart:io';
import 'package:black_box/screen_page/course/screen/tag_generator_page.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'omr_scanner_page.dart';

class CourseOmrPage extends StatefulWidget {
  const CourseOmrPage({Key? key}) : super(key: key);


  @override
  _CourseOmrPageState createState() => _CourseOmrPageState();
}


class _CourseOmrPageState extends State<CourseOmrPage> {
  @override
  void initState() {
    super.initState();
    requestPermissions();
  }


  Future<void> requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OMR Tag — Coaching Center')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate OMR Tag'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TagGeneratorPage()),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan OMR Tag'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScannerPage()),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'How it works:\n- Tag generator prints a PNG containing: QR (studentId+phone) + bubble grid for answers.\n- Scanner detects QR (anchor), then captures an image and samples bubble locations (relative to QR).\n- Fill detection is done by sampling average darkness in each bubble region.\n',
            )
          ],
        ),
      ),
    );
  }
}