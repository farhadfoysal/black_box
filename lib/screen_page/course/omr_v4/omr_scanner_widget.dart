import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'omr_scanner_service.dart';

class OMRScannerWidget extends StatefulWidget {
  @override
  _OMRScannerWidgetState createState() => _OMRScannerWidgetState();
}

class _OMRScannerWidgetState extends State<OMRScannerWidget> {
  final OMRScannerService _scannerService = OMRScannerService();
  bool _isProcessing = false;
  OMRResult? _lastResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    await _scannerService.loadModel();
  }

  Future<void> _pickAndProcessImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      try {
        OMRResult result = await _scannerService.processImage(File(image.path));
        setState(() {
          _lastResult = result;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Error processing image: $e';
        });
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('বাংলা OMR স্ক্যানার'),
        backgroundColor: Color(0xFF1E324B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              color: Color(0xFF1E324B),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'BANGLA QUIZ OMR SCANNER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'AI-Powered Detection System',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Scan Button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickAndProcessImage,
              icon: Icon(Icons.camera_alt),
              label: Text('OMR শীট স্ক্যান করুন'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Color(0xFFFF4500),
              ),
            ),

            SizedBox(height: 20),

            // Processing Indicator
            if (_isProcessing) ...[
              LinearProgressIndicator(),
              SizedBox(height: 10),
              Text(
                'প্রসেসিং...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
            ],

            // Error Message
            if (_errorMessage != null) ...[
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Results
            if (_lastResult != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'স্ক্যান ফলাফল:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E324B),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Set Number
                      _buildResultRow('সেট নম্বর:', _lastResult!.setNumber.toString()),

                      // Student ID
                      _buildResultRow(
                          'ছাত্র/ছাত্রী আইডি:',
                          _lastResult!.studentId.join()
                      ),

                      // Mobile Number
                      _buildResultRow(
                          'মোবাইল নম্বর:',
                          _lastResult!.mobileNumber.join()
                      ),

                      SizedBox(height: 16),

                      // Answers
                      Text(
                        'উত্তরসমূহ:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E324B),
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _lastResult!.answers.asMap().entries.map((entry) {
                          return Chip(
                            label: Text('Q${entry.key + 1}: ${entry.value}'),
                            backgroundColor: Color(0xFF1E324B),
                            labelStyle: TextStyle(color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Instructions
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Card(
                  color: Color(0xFFFFF8F0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'নির্দেশনা: HB পেন্সিল ব্যবহার করুন • বাবল সম্পূর্ণ ভরাট করুন • ভুল হলে পরিষ্কার করে মুছুন',
                      style: TextStyle(
                        color: Color(0xFFFF4500),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
}