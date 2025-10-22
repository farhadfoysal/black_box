import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../models/omr_sheet_model.dart';
import '../models/exam_result_model.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';
import '../services/omr_scanner_service.dart';
import '../widgets/result_card_widget.dart';

class ScanOMRScreen extends StatefulWidget {
  @override
  _ScanOMRScreenState createState() => _ScanOMRScreenState();
}

class _ScanOMRScreenState extends State<ScanOMRScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DatabaseService _databaseService;
  late OMRScannerService _scannerService;

  // Camera scanning
  MobileScannerController? _mobileScannerController;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;

  // Image/File selection
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  // OMR Processing
  List<OMRSheet> _omrSheets = [];
  OMRSheet? _selectedOMRSheet;
  ScanResult? _scanResult;
  Student? _detectedStudent;
  bool _isProcessing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scannerService = OMRScannerService();
    _initializeDatabase();
    _initializeCamera();
  }

  Future<void> _initializeDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    _databaseService = DatabaseService(prefs);
    await _loadOMRSheets();
  }

  Future<void> _loadOMRSheets() async {
    setState(() => _isLoading = true);

    final sheets = await _databaseService.getAllOMRSheets();
    setState(() {
      _omrSheets = sheets;
      if (sheets.isNotEmpty) {
        _selectedOMRSheet = sheets.first;
      }
      _isLoading = false;
    });
  }

  void _initializeCamera() {
    _mobileScannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan OMR Sheet'),
        backgroundColor: Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.camera_alt), text: 'Camera'),
            Tab(icon: Icon(Icons.image), text: 'Gallery'),
            Tab(icon: Icon(Icons.picture_as_pdf), text: 'PDF'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildOMRSheetSelector(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCameraTab(),
                      _buildGalleryTab(),
                      _buildPDFTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOMRSheetSelector() {
    if (_omrSheets.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        color: Colors.orange.shade100,
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade800),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No OMR sheets available. Please create one first.',
                style: TextStyle(color: Colors.orange.shade800),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select OMR Template',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<OMRSheet>(
            value: _selectedOMRSheet,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _omrSheets.map((sheet) {
              return DropdownMenuItem(
                value: sheet,
                child: Text('${sheet.examName} - Set ${sheet.setNumber}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedOMRSheet = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCameraTab() {
    return Stack(
      children: [
        MobileScanner(
          controller: _mobileScannerController!,
          onDetect: (capture) {
            // Handle barcode detection if needed
          },
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              IconButton(
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _isFlashOn = !_isFlashOn;
                    _mobileScannerController?.toggleTorch();
                  });
                },
              ),
              SizedBox(height: 16),
              IconButton(
                icon: Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _isFrontCamera = !_isFrontCamera;
                    _mobileScannerController?.switchCamera();
                  });
                },
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _captureImage,
              icon: Icon(Icons.camera),
              label: Text('Capture'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2C3E50),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryTab() {
    return Center(
      child: _selectedImage != null
          ? Column(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_selectedImage!, fit: BoxFit.contain),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: Icon(Icons.image),
                        label: Text('Change Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _processSelectedImage,
                        icon: _isProcessing
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(Icons.check_circle),
                        label: Text(
                          _isProcessing ? 'Processing...' : 'Process',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2ECC71),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_scanResult != null) _buildScanResults(),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined, size: 100, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No image selected',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: Icon(Icons.photo_library),
                  label: Text('Select from Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3498DB),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPDFTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 100, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Upload PDF with OMR sheets',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Process multiple OMR sheets at once',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickPDF,
            icon: Icon(Icons.upload_file),
            label: Text('Select PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE74C3C),
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResults() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan Results',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          if (_detectedStudent != null) ...[
            Text('Student: ${_detectedStudent!.name}'),
            Text('ID: ${_detectedStudent!.studentId}'),
          ] else ...[
            Text('Student ID: ${_scanResult!.studentId ?? "Not detected"}'),
          ],
          Text(
            'Confidence: ${(_scanResult!.confidence * 100).toStringAsFixed(1)}%',
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _scanResult = null;
                    _selectedImage = null;
                  });
                },
                icon: Icon(Icons.cancel),
                label: Text('Cancel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              ),
              ElevatedButton.icon(
                onPressed: _saveResult,
                icon: Icon(Icons.save),
                label: Text('Save Result'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2ECC71),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _captureImage() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _tabController.animateTo(1); // Switch to gallery tab
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _scanResult = null;
        _detectedStudent = null;
      });
    }
  }

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        await _processPDF(file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processPDF(File pdfFile) async {
    // TODO: Implement PDF to image conversion and batch processing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF processing will be implemented soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _processSelectedImage() async {
    if (_selectedImage == null || _selectedOMRSheet == null) return;

    setState(() => _isProcessing = true);

    try {
      _scanResult = await _scannerService.scanOMRSheet(
        _selectedImage!,
        _selectedOMRSheet!,
      );

      if (_scanResult!.studentId != null) {
        _detectedStudent = await _databaseService.getStudentById(
          _scanResult!.studentId!,
        );
      }

      if (_scanResult!.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan Error: ${_scanResult!.errorMessage}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveResult() async {
    if (_scanResult == null || _selectedOMRSheet == null) return;

    try {
      // Calculate results
      int correctCount = 0;
      int wrongCount = 0;
      int unansweredCount = 0;

      for (int i = 0; i < _scanResult!.detectedAnswers.length; i++) {
        final studentAnswer = _scanResult!.detectedAnswers[i];
        final correctAnswer = i < _selectedOMRSheet!.correctAnswers.length
            ? _selectedOMRSheet!.correctAnswers[i]
            : '';

        if (studentAnswer.isEmpty) {
          unansweredCount++;
        } else if (studentAnswer == correctAnswer) {
          correctCount++;
        } else {
          wrongCount++;
        }
      }

      final percentage = (_scanResult!.detectedAnswers.length > 0)
          ? (correctCount / _scanResult!.detectedAnswers.length) * 100
          : 0.0;

      final result = ExamResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: _scanResult!.studentId ?? 'Unknown',
        omrSheetId: _selectedOMRSheet!.id,
        studentName: _detectedStudent?.name ?? 'Unknown Student',
        examName: _selectedOMRSheet!.examName,
        studentAnswers: _scanResult!.detectedAnswers,
        correctAnswers: _selectedOMRSheet!.correctAnswers,
        totalQuestions: _selectedOMRSheet!.numberOfQuestions,
        correctCount: correctCount,
        wrongCount: wrongCount,
        unansweredCount: unansweredCount,
        percentage: percentage,
        scannedAt: DateTime.now(),
        scannedImagePath: _selectedImage?.path,
      );

      await _databaseService.saveResult(result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Result saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Show result dialog
      _showResultDialog(result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving result: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showResultDialog(ExamResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scan Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${result.studentName}'),
            Text('Score: ${result.correctCount}/${result.totalQuestions}'),
            Text('Percentage: ${result.percentage.toStringAsFixed(1)}%'),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: result.percentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                result.percentage >= 80
                    ? Color(0xFF2ECC71)
                    : result.percentage >= 60
                    ? Color(0xFFF39C12)
                    : Color(0xFFE74C3C),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _scanResult = null;
                _selectedImage = null;
                _detectedStudent = null;
              });
            },
            child: Text('Scan Another'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mobileScannerController?.dispose();
    _scannerService.dispose();
    super.dispose();
  }
}
