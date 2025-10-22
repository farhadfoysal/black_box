import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/exam_result_model.dart';
import '../models/omr_sheet_model.dart';
import '../services/database_service.dart';
import '../widgets/result_card_widget.dart';

class ResultsScreen extends StatefulWidget {
  final OMRSheet? omrSheetFilter;
  final List<ExamResult>? initialResults;

  ResultsScreen({this.omrSheetFilter, this.initialResults});

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late DatabaseService _databaseService;
  List<ExamResult> _allResults = [];
  List<ExamResult> _filteredResults = [];
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _isLoading = true;

  // Statistics
  double _averageScore = 0;
  int _totalScanned = 0;
  int _passedCount = 0;
  int _failedCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    _databaseService = DatabaseService(prefs);

    if (widget.initialResults != null) {
      setState(() {
        _allResults = widget.initialResults!;
        _filteredResults = widget.initialResults!;
        _calculateStatistics();
        _isLoading = false;
      });
    } else {
      await _loadResults();
    }
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);

    final results = await _databaseService.getAllResults();
    setState(() {
      _allResults = results;
      _filteredResults = results;
      _calculateStatistics();
      _isLoading = false;
    });
  }

  void _calculateStatistics() {
    if (_filteredResults.isEmpty) {
      _averageScore = 0;
      _totalScanned = 0;
      _passedCount = 0;
      _failedCount = 0;
      return;
    }

    _totalScanned = _filteredResults.length;
    _averageScore =
        _filteredResults.fold(0.0, (sum, result) => sum + result.percentage) /
        _totalScanned;
    _passedCount = _filteredResults.where((r) => r.percentage >= 60).length;
    _failedCount = _totalScanned - _passedCount;
  }

  void _filterResults(String query) {
    setState(() {
      _searchQuery = query;
      _filteredResults = _allResults.where((result) {
        return result.studentName.toLowerCase().contains(query.toLowerCase()) ||
            result.examName.toLowerCase().contains(query.toLowerCase()) ||
            result.studentId.toLowerCase().contains(query.toLowerCase());
      }).toList();
      _sortResults();
      _calculateStatistics();
    });
  }

  void _sortResults() {
    switch (_sortBy) {
      case 'date':
        _filteredResults.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
        break;
      case 'score':
        _filteredResults.sort((a, b) => b.percentage.compareTo(a.percentage));
        break;
      case 'name':
        _filteredResults.sort((a, b) => a.studentName.compareTo(b.studentName));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.omrSheetFilter != null
              ? 'Results - ${widget.omrSheetFilter!.examName}'
              : 'All Results',
        ),
        backgroundColor: Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortResults();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'date', child: Text('Sort by Date')),
              PopupMenuItem(value: 'score', child: Text('Sort by Score')),
              PopupMenuItem(value: 'name', child: Text('Sort by Name')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                _buildStatisticsSection(),
                Expanded(
                  child: _filteredResults.isEmpty
                      ? _buildEmptyState()
                      : _buildResultsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search results...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: _filterResults,
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Average Score',
                  '${_averageScore.toStringAsFixed(1)}%',
                  Icons.analytics,
                  Color(0xFF3498DB),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Scanned',
                  _totalScanned.toString(),
                  Icons.qr_code_scanner,
                  Color(0xFF9B59B6),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Passed',
                  _passedCount.toString(),
                  Icons.check_circle,
                  Color(0xFF2ECC71),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Failed',
                  _failedCount.toString(),
                  Icons.cancel,
                  Color(0xFFE74C3C),
                ),
              ),
            ],
          ),
          if (_filteredResults.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildScoreDistributionChart(),
          ],
        ],
      ),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDistributionChart() {
    final distribution = _calculateScoreDistribution();

    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    distribution.values
                        .reduce((a, b) => a > b ? a : b)
                        .toDouble() +
                    2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = [
                          '0-20',
                          '21-40',
                          '41-60',
                          '61-80',
                          '81-100',
                        ];
                        return Text(
                          labels[value.toInt()],
                          style: TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: distribution.entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: _getBarColor(entry.key),
                        width: 30,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<int, int> _calculateScoreDistribution() {
    final distribution = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0};

    for (final result in _filteredResults) {
      if (result.percentage <= 20) {
        distribution[0] = distribution[0]! + 1;
      } else if (result.percentage <= 40) {
        distribution[1] = distribution[1]! + 1;
      } else if (result.percentage <= 60) {
        distribution[2] = distribution[2]! + 1;
      } else if (result.percentage <= 80) {
        distribution[3] = distribution[3]! + 1;
      } else {
        distribution[4] = distribution[4]! + 1;
      }
    }

    return distribution;
  }

  Color _getBarColor(int index) {
    final colors = [
      Color(0xFFE74C3C),
      Color(0xFFE67E22),
      Color(0xFFF39C12),
      Color(0xFF3498DB),
      Color(0xFF2ECC71),
    ];
    return colors[index];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No results available yet'
                : 'No results found matching "$_searchQuery"',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        final result = _filteredResults[index];
        return ResultCardWidget(
          result: result,
          onTap: () => _showResultDetails(result),
        );
      },
    );
  }

  void _showResultDetails(ExamResult result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(24),
          constraints: BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Result Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              _buildDetailRow('Student', result.studentName),
              _buildDetailRow('Student ID', result.studentId),
              _buildDetailRow('Exam', result.examName),
              _buildDetailRow('Date', _formatDateTime(result.scannedAt)),
              Divider(),
              _buildDetailRow(
                'Total Questions',
                result.totalQuestions.toString(),
              ),
              _buildDetailRow(
                'Correct',
                result.correctCount.toString(),
                Colors.green,
              ),
              _buildDetailRow(
                'Wrong',
                result.wrongCount.toString(),
                Colors.red,
              ),
              _buildDetailRow(
                'Unanswered',
                result.unansweredCount.toString(),
                Colors.orange,
              ),
              Divider(),
              Center(
                child: Column(
                  children: [
                    Text(
                      '${result.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: result.percentage >= 60
                            ? Color(0xFF2ECC71)
                            : Color(0xFFE74C3C),
                      ),
                    ),
                    Text(
                      result.percentage >= 60 ? 'PASSED' : 'FAILED',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: result.percentage >= 60
                            ? Color(0xFF2ECC71)
                            : Color(0xFFE74C3C),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _exportResult(result),
                    child: Text('Export'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _exportResult(ExamResult result) {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export functionality coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
