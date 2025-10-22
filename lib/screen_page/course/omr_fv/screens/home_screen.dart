import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/omr_sheet_model.dart';
import '../models/exam_result_model.dart';
import 'create_omr_screen.dart';
import 'scan_omr_screen.dart';
import 'omr_list_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DatabaseService _databaseService;
  List<OMRSheet> _recentSheets = [];
  List<ExamResult> _recentResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    _databaseService = DatabaseService(prefs);
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final sheets = await _databaseService.getAllOMRSheets();
    final results = await _databaseService.getAllResults();

    setState(() {
      _recentSheets = sheets.take(5).toList();
      _recentResults = results.take(5).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OMR Management System'),
        backgroundColor: Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActions(),
                    SizedBox(height: 24),
                    _buildStatistics(),
                    SizedBox(height: 24),
                    _buildRecentOMRSheets(),
                    SizedBox(height: 24),
                    _buildRecentResults(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle_outline,
                title: 'Create OMR',
                subtitle: 'Design new sheet',
                color: Color(0xFF3498DB),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateOMRScreen()),
                  );
                  _loadData();
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.qr_code_scanner,
                title: 'Scan OMR',
                subtitle: 'Check answers',
                color: Color(0xFF2ECC71),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ScanOMRScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.list_alt,
                title: 'All Sheets',
                subtitle: 'Manage OMRs',
                color: Color(0xFF9B59B6),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OMRListScreen()),
                  );
                  _loadData();
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.assessment,
                title: 'Results',
                subtitle: 'View reports',
                color: Color(0xFFE74C3C),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ResultsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Sheets',
                _recentSheets.length.toString(),
                Icons.description,
                Color(0xFF3498DB),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Scanned',
                _recentResults.length.toString(),
                Icons.check_circle,
                Color(0xFF2ECC71),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Avg Score',
                _calculateAverageScore(),
                Icons.trending_up,
                Color(0xFFE74C3C),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildRecentOMRSheets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent OMR Sheets',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OMRListScreen()),
                );
              },
              child: Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (_recentSheets.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No OMR sheets created yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...(_recentSheets.map((sheet) => _buildOMRSheetTile(sheet))),
      ],
    );
  }

  Widget _buildOMRSheetTile(OMRSheet sheet) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF3498DB).withOpacity(0.1),
          child: Text(
            'S${sheet.setNumber}',
            style: TextStyle(
              color: Color(0xFF3498DB),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(sheet.examName),
        subtitle: Text(
          '${sheet.numberOfQuestions} Questions • ${sheet.subjectName}',
        ),
        trailing: Text(
          _formatDate(sheet.examDate),
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: () {
          // Navigate to sheet details
        },
      ),
    );
  }

  Widget _buildRecentResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Results',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ResultsScreen()),
                );
              },
              child: Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (_recentResults.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No results available yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...(_recentResults.map((result) => _buildResultTile(result))),
      ],
    );
  }

  Widget _buildResultTile(ExamResult result) {
    final color = result.percentage >= 80
        ? Color(0xFF2ECC71)
        : result.percentage >= 60
        ? Color(0xFFF39C12)
        : Color(0xFFE74C3C);

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Text(
            '${result.percentage.toInt()}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(result.studentName),
        subtitle: Text(
          '${result.examName} • ${result.correctCount}/${result.totalQuestions}',
        ),
        trailing: Text(
          _formatDate(result.scannedAt),
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  String _calculateAverageScore() {
    if (_recentResults.isEmpty) return '0%';

    final totalPercentage = _recentResults.fold<double>(
      0,
      (sum, result) => sum + result.percentage,
    );

    return '${(totalPercentage / _recentResults.length).toStringAsFixed(1)}%';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
