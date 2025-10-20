import 'package:flutter/material.dart';
import 'export_manager.dart';
import 'omr_database_manager.dart';

class ResultsPage extends StatefulWidget {
  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<Exam> _exams = [];
  Exam? _selectedExam;
  List<OMRResult> _results = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'score';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      _exams = await DatabaseManager.getExams();
      if (_exams.isNotEmpty) {
        _selectedExam = _exams.first;
        _loadResults();
      }
      setState(() {});
    } catch (e) {
      _showError('Failed to load exams: $e');
    }
  }

  Future<void> _loadResults() async {
    if (_selectedExam == null) return;

    setState(() => _isLoading = true);
    try {
      _results = await DatabaseManager.getExamResults(_selectedExam!.id!);
      _sortResults();
    } catch (e) {
      _showError('Failed to load results: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sortResults() {
    _results.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'studentId':
          comparison = a.studentId.compareTo(b.studentId);
          break;
        case 'setNumber':
          comparison = a.setNumber.compareTo(b.setNumber);
          break;
        case 'confidence':
          comparison = a.confidence.compareTo(b.confidence);
          break;
        case 'score':
        default:
          comparison = a.score.compareTo(b.score);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  List<OMRResult> get _filteredResults {
    if (_searchQuery.isEmpty) return _results;
    return _results.where((result) =>
    result.studentId.contains(_searchQuery) ||
        (result.mobileNumber ?? '').contains(_searchQuery) ||
        result.setNumber.toString().contains(_searchQuery)).toList();
  }

  Future<void> _exportToPDF() async {
    if (_selectedExam == null) return;

    try {
      final file = await ExportManager.generatePDFReport(_selectedExam!, _filteredResults);
      await ExportManager.shareFile(file, '${_selectedExam!.name} Results');
      _showSuccess('PDF exported successfully!');
    } catch (e) {
      _showError('Failed to export PDF: $e');
    }
  }

  Future<void> _exportToCSV() async {
    if (_selectedExam == null) return;

    try {
      final file = await ExportManager.exportToCSV(_selectedExam!, _filteredResults);
      await ExportManager.shareFile(file, '${_selectedExam!.name} Results');
      _showSuccess('CSV exported successfully!');
    } catch (e) {
      _showError('Failed to export CSV: $e');
    }
  }

  void _showResultDetails(OMRResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Result Details - ${result.studentId}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Student ID', result.studentId),
              _buildDetailRow('Set Number', result.setNumber.toString()),
              _buildDetailRow('Mobile', result.mobileNumber ?? 'N/A'),
              _buildDetailRow('Score', '${result.score.toStringAsFixed(2)}%'),
              _buildDetailRow('Confidence', '${(result.confidence * 100).toStringAsFixed(1)}%'),
              _buildDetailRow('Scanned At',
                  '${result.scannedAt.day}/${result.scannedAt.month}/${result.scannedAt.year} '
                      '${result.scannedAt.hour}:${result.scannedAt.minute.toString().padLeft(2, '0')}'),
              SizedBox(height: 16),
              Text('Answer Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: result.answers.asMap().entries.map((e) {
                  final isCorrect = e.key < _selectedExam!.correctAnswers.length &&
                      String.fromCharCode(e.value) == _selectedExam!.correctAnswers[e.key];
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green[50] : Colors.red[50],
                      border: Border.all(color: isCorrect ? Colors.green : Colors.red),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Q${e.key + 1}:${String.fromCharCode(e.value)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isCorrect ? Colors.green[800] : Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text('$label:', style: TextStyle(fontWeight: FontWeight.bold))),
          Text(value),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with controls
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exam Results & Analytics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<Exam>(
                            value: _selectedExam,
                            isExpanded: true,
                            items: _exams.map((exam) {
                              return DropdownMenuItem(
                                value: exam,
                                child: Text('${exam.name} (${exam.totalQuestions} questions)'),
                              );
                            }).toList(),
                            onChanged: (exam) {
                              setState(() => _selectedExam = exam);
                              _loadResults();
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Search by ID, Mobile, or Set',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) => setState(() => _searchQuery = value),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Sort by:'),
                        SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _sortBy,
                          items: [
                            DropdownMenuItem(value: 'score', child: Text('Score')),
                            DropdownMenuItem(value: 'studentId', child: Text('Student ID')),
                            DropdownMenuItem(value: 'setNumber', child: Text('Set Number')),
                            DropdownMenuItem(value: 'confidence', child: Text('Confidence')),
                          ],
                          onChanged: (value) {
                            setState(() => _sortBy = value!);
                            _sortResults();
                            setState(() {});
                          },
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                          onPressed: () {
                            setState(() => _sortAscending = !_sortAscending);
                            _sortResults();
                          },
                        ),
                        Spacer(),
                        ElevatedButton.icon(
                          onPressed: _exportToPDF,
                          icon: Icon(Icons.picture_as_pdf),
                          label: Text('Export PDF'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _exportToCSV,
                          icon: Icon(Icons.table_chart),
                          label: Text('Export CSV'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Statistics
            if (_results.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Total Students', _results.length.toString(), Icons.people),
                      _buildStatCard('Average Score',
                          '${(_results.map((r) => r.score).reduce((a, b) => a + b) / _results.length).toStringAsFixed(1)}%',
                          Icons.assessment),
                      _buildStatCard('Highest Score',
                          '${_results.map((r) => r.score).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}%',
                          Icons.emoji_events),
                      _buildStatCard('Pass Rate',
                          '${((_results.where((r) => r.score >= 60).length / _results.length) * 100).toStringAsFixed(1)}%',
                          Icons.check_circle),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Results table
            Expanded(
              child: Card(
                elevation: 4,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _filteredResults.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        _results.isEmpty ? 'No results available' : 'No results match your search',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      if (_results.isEmpty)
                        Text(
                          'Scan some OMR sheets to see results here',
                          style: TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                )
                    : Column(
                  children: [
                    // Table header
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: ListTile(
                        leading: SizedBox(width: 40, child: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
                        title: Row(
                          children: [
                            Expanded(child: Text('Student ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(child: Text('Set', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(child: Text('Confidence', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                        trailing: SizedBox(width: 60, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ),
                    ),

                    // Results list
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredResults.length,
                        itemBuilder: (context, index) {
                          final result = _filteredResults[index];
                          final rank = _results.indexOf(result) + 1;
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                              color: index.isEven ? Colors.white : Colors.grey[50],
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                alignment: Alignment.center,
                                child: CircleAvatar(
                                  backgroundColor: _getRankColor(rank),
                                  radius: 12,
                                  child: Text(
                                    rank.toString(),
                                    style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(result.studentId)),
                                  Expanded(child: Text('Set ${result.setNumber}')),
                                  Expanded(
                                    child: Text(
                                      '${result.score.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: result.score >= 60 ? Colors.green :
                                        result.score >= 40 ? Colors.orange : Colors.red,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${(result.confidence * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: result.confidence > 0.8 ? Colors.green :
                                        result.confidence > 0.6 ? Colors.orange : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.visibility, size: 20),
                                    onPressed: () => _showResultDetails(result),
                                    tooltip: 'View Details',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.blue),
        SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank <= 3) return Colors.orange;
    if (rank <= 10) return Colors.blue;
    return Colors.grey;
  }
}