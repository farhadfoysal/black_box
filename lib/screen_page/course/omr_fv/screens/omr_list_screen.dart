import 'package:black_box/screen_page/course/omr_fv/screens/results_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/omr_sheet_model.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';
import '../utils/omr_generator_fv.dart';
import 'create_omr_screen.dart';

class OMRListScreen extends StatefulWidget {
  @override
  _OMRListScreenState createState() => _OMRListScreenState();
}

class _OMRListScreenState extends State<OMRListScreen> {
  late DatabaseService _databaseService;
  List<OMRSheet> _omrSheets = [];
  List<OMRSheet> _filteredSheets = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
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
      _filteredSheets = sheets;
      _isLoading = false;
    });
  }

  void _filterSheets(String query) {
    setState(() {
      _searchQuery = query;
      _filteredSheets = _omrSheets.where((sheet) {
        return sheet.examName.toLowerCase().contains(query.toLowerCase()) ||
            sheet.subjectName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OMR Sheets'),
        backgroundColor: Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateOMRScreen()),
              );
              if (result == true) {
                _loadOMRSheets();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredSheets.isEmpty
                ? _buildEmptyState()
                : _buildOMRList(),
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
          hintText: 'Search OMR sheets...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: _filterSheets,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No OMR sheets created yet'
                : 'No sheets found matching "$_searchQuery"',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (_searchQuery.isEmpty) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateOMRScreen()),
                );
                if (result == true) {
                  _loadOMRSheets();
                }
              },
              icon: Icon(Icons.add),
              label: Text('Create First OMR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2C3E50),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOMRList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredSheets.length,
      itemBuilder: (context, index) {
        final sheet = _filteredSheets[index];
        return _buildOMRCard(sheet);
      },
    );
  }

  Widget _buildOMRCard(OMRSheet sheet) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showSheetOptions(sheet),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sheet.examName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Set ${sheet.setNumber}',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: Color(0xFF3498DB),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.subject, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    sheet.subjectName,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.quiz, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '${sheet.numberOfQuestions} Questions',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Exam: ${_formatDate(sheet.examDate)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Created: ${_formatDate(sheet.createdAt)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (sheet.description != null &&
                  sheet.description!.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  sheet.description!,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _generateOMR(sheet),
                    icon: Icon(Icons.download, size: 16),
                    label: Text('Generate'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF2ECC71),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _editSheet(sheet),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF3498DB),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(sheet),
                    icon: Icon(Icons.delete, size: 16),
                    label: Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFFE74C3C),
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


  void _showSheetOptions(OMRSheet sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows full height if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 10,
            right: 10,
            top: 10,
            // prevent bottom overflow when keyboard appears
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download, color: Color(0xFF2ECC71)),
                title: const Text('Generate OMR Sheet'),
                subtitle: const Text('Create printable OMR for this template'),
                onTap: () {
                  Navigator.pop(context);
                  _generateOMR(sheet);
                },
              ),
              ListTile(
                leading: const Icon(Icons.group, color: Color(0xFF9B59B6)),
                title: const Text('Generate for Multiple Students'),
                subtitle: const Text('Create OMRs for selected students'),
                onTap: () {
                  Navigator.pop(context);
                  _showStudentSelectionDialog(sheet);
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility, color: Color(0xFF3498DB)),
                title: const Text('View Answer Key'),
                subtitle: const Text('See correct answers for this sheet'),
                onTap: () {
                  Navigator.pop(context);
                  _showAnswerKey(sheet);
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics, color: Color(0xFFF39C12)),
                title: const Text('View Results'),
                subtitle: const Text('See all scanned results for this sheet'),
                onTap: () {
                  Navigator.pop(context);
                  _viewResults(sheet);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF3498DB)),
                title: const Text('Edit Sheet'),
                onTap: () {
                  Navigator.pop(context);
                  _editSheet(sheet);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
                title: const Text('Delete Sheet'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(sheet);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }



  // void _showSheetOptions(OMRSheet sheet) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context) => Container(
  //       padding: EdgeInsets.all(10),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           ListTile(
  //             leading: Icon(Icons.download, color: Color(0xFF2ECC71)),
  //             title: Text('Generate OMR Sheet'),
  //             subtitle: Text('Create printable OMR for this template'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _generateOMR(sheet);
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.group, color: Color(0xFF9B59B6)),
  //             title: Text('Generate for Multiple Students'),
  //             subtitle: Text('Create OMRs for selected students'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _showStudentSelectionDialog(sheet);
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.visibility, color: Color(0xFF3498DB)),
  //             title: Text('View Answer Key'),
  //             subtitle: Text('See correct answers for this sheet'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _showAnswerKey(sheet);
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.analytics, color: Color(0xFFF39C12)),
  //             title: Text('View Results'),
  //             subtitle: Text('See all scanned results for this sheet'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _viewResults(sheet);
  //             },
  //           ),
  //           Divider(),
  //           ListTile(
  //             leading: Icon(Icons.edit, color: Color(0xFF3498DB)),
  //             title: Text('Edit Sheet'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _editSheet(sheet);
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.delete, color: Color(0xFFE74C3C)),
  //             title: Text('Delete Sheet'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _confirmDelete(sheet);
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Future<void> _generateOMR(OMRSheet sheet) async {
    final config = OMRExamConfig(
      examName: sheet.examName,
      numberOfQuestions: sheet.numberOfQuestions,
      setNumber: sheet.setNumber,
      studentId: '0000000000',
      mobileNumber: '00000000000',
      examDate: sheet.examDate,
      correctAnswers: sheet.correctAnswers,
      studentName: '',
      className: '',
    );

    try {
      final file = await ProfessionalOMRGenerator.generateOMRSheet(config);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OMR Sheet generated successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () {
              // Open file
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating OMR: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStudentSelectionDialog(OMRSheet sheet) async {
    final students = await _databaseService.getAllStudents();
    final courseStudents = students
        .where((s) => s.courseId == sheet.courseId)
        .toList();

    if (courseStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No students found for this course'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedStudents = <Student>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Select Students'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                CheckboxListTile(
                  title: Text('Select All'),
                  value: selectedStudents.length == courseStudents.length,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedStudents.clear();
                        selectedStudents.addAll(courseStudents);
                      } else {
                        selectedStudents.clear();
                      }
                    });
                  },
                ),
                Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: courseStudents.length,
                    itemBuilder: (context, index) {
                      final student = courseStudents[index];
                      return CheckboxListTile(
                        title: Text(student.name),
                        subtitle: Text('ID: ${student.studentId}'),
                        value: selectedStudents.contains(student),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedStudents.add(student);
                            } else {
                              selectedStudents.remove(student);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedStudents.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      _generateForStudents(sheet, selectedStudents);
                    },
              child: Text('Generate (${selectedStudents.length})'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateForStudents(
    OMRSheet sheet,
    List<Student> students,
  ) async {
    final progress = ValueNotifier<int>(0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder<int>(
        valueListenable: progress,
        builder: (context, value, child) => AlertDialog(
          title: Text('Generating OMR Sheets'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: value / students.length),
              SizedBox(height: 16),
              Text('$value / ${students.length} completed'),
            ],
          ),
        ),
      ),
    );

    try {
      for (int i = 0; i < students.length; i++) {
        final student = students[i];
        final config = OMRExamConfig(
          examName: sheet.examName,
          numberOfQuestions: sheet.numberOfQuestions,
          setNumber: sheet.setNumber,
          studentId: student.studentId,
          mobileNumber: student.mobileNumber,
          examDate: sheet.examDate,
          correctAnswers: sheet.correctAnswers,
          studentName: student.name,
          className: student.className,
        );

        await ProfessionalOMRGenerator.generateOMRSheet(config);
        progress.value = i + 1;
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Generated ${students.length} OMR sheets successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating OMRs: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAnswerKey(OMRSheet sheet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Answer Key - ${sheet.examName}'),
        content: Container(
          width: double.maxFinite,
          height: 440,
          child: Column(
            children: [
              Text(
                'Set ${sheet.setNumber} - ${sheet.numberOfQuestions} Questions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: sheet.numberOfQuestions,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF2C3E50),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Q${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            sheet.correctAnswers[index],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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

  void _viewResults(OMRSheet sheet) async {
    final results = await _databaseService.getResultsByOMRSheet(sheet.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ResultsScreen(omrSheetFilter: sheet, initialResults: results),
      ),
    );
  }

  void _editSheet(OMRSheet sheet) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateOMRScreen(editingSheet: sheet)),
    );

    if (result == true) {
      _loadOMRSheets();
    }
  }

  void _confirmDelete(OMRSheet sheet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete OMR Sheet'),
        content: Text(
          'Are you sure you want to delete "${sheet.examName}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSheet(sheet);
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE74C3C)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSheet(OMRSheet sheet) async {
    try {
      await _databaseService.deleteOMRSheet(sheet.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OMR Sheet deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadOMRSheets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting sheet: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
