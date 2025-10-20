import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'batch_processor.dart';
import 'omr_database_manager.dart';

class BatchProcessingPage extends StatefulWidget {
  @override
  _BatchProcessingPageState createState() => _BatchProcessingPageState();
}

class _BatchProcessingPageState extends State<BatchProcessingPage> {
  List<Exam> _exams = [];
  Exam? _selectedExam;
  List<String> _selectedImages = [];
  bool _isProcessing = false;
  double _progress = 0.0;
  BatchResult? _lastBatchResult;
  List<BatchScan> _batchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadExams();
    _loadBatchHistory();
  }

  Future<void> _loadExams() async {
    try {
      _exams = await DatabaseManager.getExams();
      if (_exams.isNotEmpty) {
        _selectedExam = _exams.first;
      }
      setState(() {});
    } catch (e) {
      _showError('Failed to load exams: $e');
    }
  }

  Future<void> _loadBatchHistory() async {
    // Implementation depends on your database structure
    // This would load previous batch processing sessions
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null) {
      setState(() {
        _selectedImages = images.map((image) => image.path).toList();
      });
    }
  }

  Future<void> _processBatch() async {
    if (_selectedExam == null || _selectedImages.isEmpty) {
      _showError('Please select an exam and at least one image');
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
    });

    try {
      // Create batch scan record
      final batch = BatchScan(
        examId: _selectedExam!.id!,
        scanData: _selectedImages,
        processedCount: 0,
        totalCount: _selectedImages.length,
        status: 'processing',
        createdAt: DateTime.now(),
      );

      final batchId = await DatabaseManager.createBatchScan(batch);
      batch.id = batchId;

      // Process images
      _lastBatchResult = await BatchProcessor.processBatch(
        _selectedImages,
        _selectedExam!,
        confidenceThreshold: 0.7,
      );

      // Update batch scan record
      batch.processedCount = _lastBatchResult!.successCount;
      batch.status = 'completed';
      await DatabaseManager.updateBatchScan(batch);

      // Save results
      for (final result in _lastBatchResult!.successfulResults) {
        await DatabaseManager.insertResult(result);
      }

      _showSuccess('Batch processing completed! '
          'Success: ${_lastBatchResult!.successCount}, '
          'Failed: ${_lastBatchResult!.failureCount}');

    } catch (e) {
      _showError('Batch processing failed: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _progress = 1.0;
      });
    }
  }

  void _showResultsDialog() {
    if (_lastBatchResult == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batch Processing Results'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultStat('Total Images', _selectedImages.length.toString()),
              _buildResultStat('Successful', _lastBatchResult!.successCount.toString()),
              _buildResultStat('Failed', _lastBatchResult!.failureCount.toString()),
              _buildResultStat('Success Rate',
                  '${(_lastBatchResult!.successRate * 100).toStringAsFixed(1)}%'),
              SizedBox(height: 16),
              Text('Successful Scans:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._lastBatchResult!.successfulResults.take(5).map((result) =>
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: result.score >= 60 ? Colors.green : Colors.orange,
                      child: Text(result.score.toStringAsFixed(0),
                          style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                    title: Text('ID: ${result.studentId}'),
                    subtitle: Text('Set: ${result.setNumber} • Score: ${result.score.toStringAsFixed(1)}%'),
                    trailing: Text('${(result.confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: result.confidence > 0.8 ? Colors.green :
                          result.confidence > 0.6 ? Colors.orange : Colors.red,
                        )),
                  )),
              if (_lastBatchResult!.successfulResults.length > 5)
                Text('... and ${_lastBatchResult!.successfulResults.length - 5} more'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to results page
            },
            child: Text('View All Results'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStat(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedImages.clear();
      _lastBatchResult = null;
    });
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
            // Header
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch OMR Processing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Process multiple OMR sheets at once by selecting multiple images',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Exam selection and image picker
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Exam', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          DropdownButton<Exam>(
                            value: _selectedExam,
                            isExpanded: true,
                            items: _exams.map((exam) {
                              return DropdownMenuItem(
                                value: exam,
                                child: Text('${exam.name} (${exam.totalQuestions} questions)'),
                              );
                            }).toList(),
                            onChanged: _isProcessing ? null : (exam) => setState(() => _selectedExam = exam),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 16),

                Expanded(
                  flex: 3,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Images', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          if (_selectedImages.isEmpty)
                            Text('No images selected', style: TextStyle(color: Colors.grey))
                          else
                            Text('${_selectedImages.length} images selected',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isProcessing ? null : _pickImages,
                                  icon: Icon(Icons.photo_library),
                                  label: Text('Pick Images'),
                                ),
                              ),
                              if (_selectedImages.isNotEmpty) ...[
                                SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _isProcessing ? null : _clearSelection,
                                  icon: Icon(Icons.clear),
                                  label: Text('Clear'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Processing section
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Process button and progress
                  Expanded(
                    flex: 1,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Processing', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 16),

                            if (_isProcessing) ...[
                              LinearProgressIndicator(value: _progress),
                              SizedBox(height: 8),
                              Text('Processing... ${(_progress * 100).toStringAsFixed(0)}%',
                                  textAlign: TextAlign.center),
                              SizedBox(height: 16),
                            ],

                            ElevatedButton.icon(
                              onPressed: _isProcessing || _selectedImages.isEmpty || _selectedExam == null
                                  ? null
                                  : _processBatch,
                              icon: Icon(Icons.play_arrow),
                              label: Text('Start Processing'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.blue[800],
                              ),
                            ),

                            if (_lastBatchResult != null) ...[
                              SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _showResultsDialog,
                                icon: Icon(Icons.analytics),
                                label: Text('View Results'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // Selected images preview
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Selected Images (${_selectedImages.length})',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 12),
                            if (_selectedImages.isEmpty)
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.photo_library, size: 64, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text('No images selected', style: TextStyle(color: Colors.grey)),
                                      Text('Click "Pick Images" to select OMR sheets',
                                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: GridView.builder(
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 0.7,
                                  ),
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Image.file(
                                            File(_selectedImages[index]),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(child: Icon(Icons.error));
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}