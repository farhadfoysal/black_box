import 'package:black_box/screen_page/course/omr_v2/results_page.dart';
import 'package:flutter/material.dart';
import '../screen/omr_scanner_page.dart';
import 'batch_processing_page.dart';
import 'exam_management_page.dart';
import 'omr_database_manager.dart';
import 'export_manager.dart';
import 'batch_processor.dart';


class OMRDashboard extends StatefulWidget {
  @override
  _OMRDashboardState createState() => _OMRDashboardState();
}

class _OMRDashboardState extends State<OMRDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    ExamManagementPage(),
    ScannerPage(),
    BatchProcessingPage(),
    ResultsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Professional OMR System'),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Exams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Scanner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections),
            label: 'Batch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Results',
          ),
        ],
      ),
    );
  }
}

// class ExamManagementPage extends StatefulWidget {
//   @override
//   _ExamManagementPageState createState() => _ExamManagementPageState();
// }
//
// class _ExamManagementPageState extends State<ExamManagementPage> {
//   // Implementation for exam management
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(child: Text('Exam Management')),
//     );
//   }
// }
//
// class ScannerPage extends StatefulWidget {
//   @override
//   _ScannerPageState createState() => _ScannerPageState();
// }
//
// class _ScannerPageState extends State<ScannerPage> {
//   // Enhanced scanner implementation
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(child: Text('Enhanced Scanner')),
//     );
//   }
// }
//
// class BatchProcessingPage extends StatefulWidget {
//   @override
//   _BatchProcessingPageState createState() => _BatchProcessingPageState();
// }
//
// class _BatchProcessingPageState extends State<BatchProcessingPage> {
//   // Batch processing implementation
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(child: Text('Batch Processing')),
//     );
//   }
// }
//
// class ResultsPage extends StatefulWidget {
//   @override
//   _ResultsPageState createState() => _ResultsPageState();
// }
//
// class _ResultsPageState extends State<ResultsPage> {
//   // Results and export implementation
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(child: Text('Results & Export')),
//     );
//   }
// }