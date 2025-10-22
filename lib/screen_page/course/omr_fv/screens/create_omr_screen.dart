import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/omr_sheet_model.dart';
import '../models/course_model.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';
import '../utils/omr_generator_fv.dart';
import '../utils/blank_omr_generator.dart';
import '../widgets/blank_omr_preview_widget.dart';
import '../widgets/omr_preview_widget.dart';

class CreateOMRScreen extends StatefulWidget {
  final OMRSheet? editingSheet;

  CreateOMRScreen({this.editingSheet});

  @override
  _CreateOMRScreenState createState() => _CreateOMRScreenState();
}

class _CreateOMRScreenState extends State<CreateOMRScreen> {
  final _formKey = GlobalKey<FormState>();
  late DatabaseService _databaseService;

  // Form controllers
  final _examNameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();

  // Form values
  Course? _selectedCourse;
  int _numberOfQuestions = 40;
  int _setNumber = 1;
  DateTime _examDate = DateTime.now();
  List<String> _correctAnswers = [];
  List<Course> _courses = [];
  bool _isLoading = false;

  // Generation options
  bool _generateBlankOMR = false;
  bool _generateForAllStudents = false;
  List<Student> _selectedStudents = [];
  List<Student> _allStudents = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    final prefs = await SharedPreferences.getInstance();
    _databaseService = DatabaseService(prefs);

    await _loadCourses();
    await _loadStudents();

    if (widget.editingSheet != null) {
      _populateFormWithExistingData();
    } else {
      _correctAnswers = List.generate(_numberOfQuestions, (index) => 'A');
    }
  }

  Future<void> _loadCourses() async {
    final courses = await _databaseService.getAllCourses();
    setState(() {
      _courses = courses;
      if (_courses.isNotEmpty && _selectedCourse == null) {
        _selectedCourse = _courses.first;
      }
    });
  }

  Future<void> _loadStudents() async {
    final students = await _databaseService.getAllStudents();
    setState(() {
      _allStudents = students;
    });
  }

  void _populateFormWithExistingData() {
    final sheet = widget.editingSheet!;
    _examNameController.text = sheet.examName;
    _subjectController.text = sheet.subjectName;
    _descriptionController.text = sheet.description ?? '';
    _numberOfQuestions = sheet.numberOfQuestions;
    _setNumber = sheet.setNumber;
    _examDate = sheet.examDate;
    _correctAnswers = List.from(sheet.correctAnswers);

    _selectedCourse = _courses.firstWhere(
          (course) => course.id == sheet.courseId,
      orElse: () => _courses.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editingSheet != null ? 'Edit OMR Sheet' : 'Create OMR Sheet',
        ),
        backgroundColor: Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.preview),
            onPressed: _previewOMR,
            tooltip: 'Preview OMR',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              SizedBox(height: 24),
              _buildExamConfigSection(),
              SizedBox(height: 24),
              _buildAnswerKeySection(),
              SizedBox(height: 24),
              _buildGenerationOptionsSection(),
              SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _examNameController,
              decoration: InputDecoration(
                labelText: 'Exam Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter exam name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<Course>(
              value: _selectedCourse,
              decoration: InputDecoration(
                labelText: 'Course',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              items: _courses.map((course) {
                return DropdownMenuItem(
                  value: course,
                  child: Text(course.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCourse = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a course';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subject),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter subject name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamConfigSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exam Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Number of Questions'),
                      SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _numberOfQuestions,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [10, 20, 30, 40, 50, 60, 70, 80, 90, 100].map((
                            num,
                            ) {
                          return DropdownMenuItem(
                            value: num,
                            child: Text(num.toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _numberOfQuestions = value!;
                            _correctAnswers = List.generate(
                              value,
                                  (index) => index < _correctAnswers.length
                                  ? _correctAnswers[index]
                                  : 'A',
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Set Number'),
                      SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _setNumber,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [1, 2, 3, 4].map((num) {
                          return DropdownMenuItem(
                            value: num,
                            child: Text('Set $num'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _setNumber = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _examDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _examDate = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Exam Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_examDate.day}/${_examDate.month}/${_examDate.year}',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerKeySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Answer Key',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.auto_fix_high),
                  label: Text('Quick Fill'),
                  onPressed: _showQuickFillDialog,
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GridView.builder(
                padding: EdgeInsets.all(5),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _numberOfQuestions,
                itemBuilder: (context, index) {
                  return _buildAnswerSelector(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerSelector(int questionIndex) {
    final options = ['A', 'B', 'C', 'D'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Q${questionIndex + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: options.map((option) {
              final isSelected = _correctAnswers[questionIndex] == option;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _correctAnswers[questionIndex] = option;
                  });
                },
                child: Container(
                  width: 20,
                  height: 20,
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF2C3E50) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Color(0xFF2C3E50) : Colors.grey,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showQuickFillDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String pattern = 'A';
        return AlertDialog(
          title: Text('Quick Fill Answers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select a pattern to fill all answers:'),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: ['A', 'B', 'C', 'D', 'Random'].map((option) {
                  return ChoiceChip(
                    label: Text(option),
                    selected: pattern == option,
                    onSelected: (selected) {
                      if (selected) {
                        pattern = option;
                        Navigator.pop(context);
                        _applyQuickFill(option);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyQuickFill(String pattern) {
    setState(() {
      if (pattern == 'Random') {
        final options = ['A', 'B', 'C', 'D'];
        _correctAnswers = List.generate(
          _numberOfQuestions,
              (index) => options[DateTime.now().millisecondsSinceEpoch % 4],
        );
      } else {
        _correctAnswers = List.filled(_numberOfQuestions, pattern);
      }
    });
  }


  Widget _buildGenerationOptionsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generation Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 16),

            // Blank OMR option
            SwitchListTile(
              title: Text('Generate Blank OMR Sheet'),
              subtitle: Text('Create OMR without student information for manual filling'),
              value: _generateBlankOMR,
              onChanged: (value) {
                setState(() {
                  _generateBlankOMR = value;
                  if (value) {
                    _generateForAllStudents = false;
                    _selectedStudents.clear();
                  }
                });
              },
              activeColor: Color(0xFF2ECC71),
            ),

            if (_generateBlankOMR) ...[
              SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: InputDecoration(
                  labelText: 'Custom Instructions (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                  hintText: 'Enter any special instructions for students',
                ),
                maxLines: 2,
              ),
            ],

            Divider(height: 32),

            // Personalized OMR option
            SwitchListTile(
              title: Text('Generate for all students in course'),
              subtitle: Text('Create personalized OMR sheets for each student'),
              value: _generateForAllStudents,
              onChanged: _generateBlankOMR ? null : (value) {
                setState(() {
                  _generateForAllStudents = value;
                  if (value) {
                    _selectedStudents = _allStudents
                        .where((s) => s.courseId == _selectedCourse?.id)
                        .toList();
                  } else {
                    _selectedStudents.clear();
                  }
                });
              },
            ),

            if (_generateForAllStudents && !_generateBlankOMR) ...[
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected Students (${_selectedStudents.length})',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextButton(
                    onPressed: _showStudentSelectionDialog,
                    child: Text('Select Students'),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedStudents.isEmpty
                    ? Center(
                  child: Text(
                    'No students selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: _selectedStudents.length,
                  itemBuilder: (context, index) {
                    final student = _selectedStudents[index];
                    return ListTile(
                      dense: true,
                      title: Text(student.name),
                      subtitle: Text('ID: ${student.studentId}'),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedStudents.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStudentSelectionDialog() {
    final courseStudents = _allStudents
        .where((s) => s.courseId == _selectedCourse?.id)
        .toList();

    if (courseStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No students found for selected course'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final tempSelected = List<Student>.from(_selectedStudents);

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Select Students'),
            content: Container(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  CheckboxListTile(
                    title: Text('Select All'),
                    value: tempSelected.length == courseStudents.length,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          tempSelected.clear();
                          tempSelected.addAll(courseStudents);
                        } else {
                          tempSelected.clear();
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
                        final isSelected = tempSelected.any((s) => s.id == student.id);

                        return CheckboxListTile(
                          title: Text(student.name),
                          subtitle: Text('ID: ${student.studentId}'),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                tempSelected.add(student);
                              } else {
                                tempSelected.removeWhere((s) => s.id == student.id);
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
                onPressed: () {
                  this.setState(() {
                    _selectedStudents = tempSelected;
                  });
                  Navigator.pop(context);
                },
                child: Text('Apply (${tempSelected.length})'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleSaveAndGenerate,
            icon: _isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Icon(_generateBlankOMR ? Icons.picture_as_pdf : Icons.save),
            label: Text(_getActionButtonText()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2C3E50),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  String _getActionButtonText() {
    if (_generateBlankOMR) {
      return 'Generate Blank OMR';
    } else if (widget.editingSheet != null) {
      return 'Update';
    } else {
      return 'Create';
    }
  }

  Future<void> _handleSaveAndGenerate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_generateBlankOMR) {
        // Generate blank OMR sheet
        await _generateBlankOMRSheet();
      } else {
        // Save OMR sheet configuration
        await _saveOMRSheet();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateBlankOMRSheet() async {
    final config = BlankOMRConfig(
      examName: _examNameController.text,
      subjectName: _subjectController.text,
      numberOfQuestions: _numberOfQuestions,
      setNumber: _setNumber,
      examDate: _examDate,
      instructions: _instructionsController.text.isEmpty ? null : _instructionsController.text,
    );

    try {
      final file = await BlankOMRGenerator.generateBlankOMRSheet(config);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Blank OMR Sheet generated successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Print',
            textColor: Colors.white,
            onPressed: () async {
              final bytes = await file.readAsBytes();
              await BlankOMRGenerator.printBlankOMRSheet(bytes);
            },
          ),
        ),
      );

      // Also save the OMR configuration for future reference
      final sheet = OMRSheet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        examName: _examNameController.text,
        courseId: _selectedCourse!.id,
        subjectName: _subjectController.text,
        setNumber: _setNumber,
        numberOfQuestions: _numberOfQuestions,
        correctAnswers: _correctAnswers,
        createdAt: DateTime.now(),
        examDate: _examDate,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      );

      await _databaseService.saveOMRSheet(sheet);
      Navigator.pop(context, true);
    } catch (e) {
      throw e;
    }
  }

  Future<void> _saveOMRSheet() async {
    final sheet = OMRSheet(
      id: widget.editingSheet?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      examName: _examNameController.text,
      courseId: _selectedCourse!.id,
      subjectName: _subjectController.text,
      setNumber: _setNumber,
      numberOfQuestions: _numberOfQuestions,
      correctAnswers: _correctAnswers,
      createdAt: widget.editingSheet?.createdAt ?? DateTime.now(),
      examDate: _examDate,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
    );

    await _databaseService.saveOMRSheet(sheet);

    if (_generateForAllStudents && _selectedStudents.isNotEmpty) {
      await _generateOMRsForStudents(sheet);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.editingSheet != null
              ? 'OMR Sheet updated successfully'
              : 'OMR Sheet created successfully',
        ),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }

  Future<void> _generateOMRsForStudents(OMRSheet sheet) async {
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
              LinearProgressIndicator(
                value: value / _selectedStudents.length,
              ),
              SizedBox(height: 16),
              Text('$value / ${_selectedStudents.length} completed'),
            ],
          ),
        ),
      ),
    );

    try {
      for (int i = 0; i < _selectedStudents.length; i++) {
        final student = _selectedStudents[i];
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
    } catch (e) {
      Navigator.pop(context);
      throw e;
    }
  }

  void _previewOMR() {
    if (!_formKey.currentState!.validate()) return;

    if (_generateBlankOMR) {
      // Preview blank OMR
      final config = BlankOMRConfig(
        examName: _examNameController.text,
        subjectName: _subjectController.text,
        numberOfQuestions: _numberOfQuestions,
        setNumber: _setNumber,
        examDate: _examDate,
        instructions: _instructionsController.text.isEmpty ? null : _instructionsController.text,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlankOMRPreviewWidget(config: config),
        ),
      );
    } else {
      // Preview personalized OMR
      final config = OMRExamConfig(
        examName: _examNameController.text,
        numberOfQuestions: _numberOfQuestions,
        setNumber: _setNumber,
        studentId: '0000000000',
        mobileNumber: '00000000000',
        examDate: _examDate,
        correctAnswers: _correctAnswers,
        studentName: 'Preview Student',
        className: _selectedCourse?.name ?? 'Course',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OMRPreviewWidget(config: config),
        ),
      );
    }
  }

  @override
  void dispose() {
    _examNameController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}







// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/omr_sheet_model.dart';
// import '../models/course_model.dart';
// import '../models/student_model.dart';
// import '../services/database_service.dart';
// import '../utils/omr_generator_fv.dart';
// import '../widgets/omr_preview_widget.dart';
//
// class CreateOMRScreen extends StatefulWidget {
//   final OMRSheet? editingSheet;
//
//   CreateOMRScreen({this.editingSheet});
//
//   @override
//   _CreateOMRScreenState createState() => _CreateOMRScreenState();
// }
//
// class _CreateOMRScreenState extends State<CreateOMRScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late DatabaseService _databaseService;
//
//   // Form controllers
//   final _examNameController = TextEditingController();
//   final _subjectController = TextEditingController();
//   final _descriptionController = TextEditingController();
//
//   // Form values
//   Course? _selectedCourse;
//   int _numberOfQuestions = 40;
//   int _setNumber = 1;
//   DateTime _examDate = DateTime.now();
//   List<String> _correctAnswers = [];
//   List<Course> _courses = [];
//   bool _isLoading = false;
//
//   // For batch generation
//   bool _generateForAllStudents = false;
//   List<Student> _selectedStudents = [];
//   List<Student> _allStudents = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeForm();
//   }
//
//   Future<void> _initializeForm() async {
//     final prefs = await SharedPreferences.getInstance();
//     _databaseService = DatabaseService(prefs);
//
//     await _loadCourses();
//     await _loadStudents();
//
//     if (widget.editingSheet != null) {
//       _populateFormWithExistingData();
//     } else {
//       _correctAnswers = List.generate(_numberOfQuestions, (index) => 'A');
//     }
//   }
//
//   Future<void> _loadCourses() async {
//     final courses = await _databaseService.getAllCourses();
//     setState(() {
//       _courses = courses;
//     });
//   }
//
//   Future<void> _loadStudents() async {
//     final students = await _databaseService.getAllStudents();
//     setState(() {
//       _allStudents = students;
//     });
//   }
//
//   void _populateFormWithExistingData() {
//     final sheet = widget.editingSheet!;
//     _examNameController.text = sheet.examName;
//     _subjectController.text = sheet.subjectName;
//     _descriptionController.text = sheet.description ?? '';
//     _numberOfQuestions = sheet.numberOfQuestions;
//     _setNumber = sheet.setNumber;
//     _examDate = sheet.examDate;
//     _correctAnswers = List.from(sheet.correctAnswers);
//
//     // Find and set the course
//     _selectedCourse = _courses.firstWhere(
//       (course) => course.id == sheet.courseId,
//       orElse: () => _courses.first,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.editingSheet != null ? 'Edit OMR Sheet' : 'Create OMR Sheet',
//         ),
//         backgroundColor: Color(0xFF2C3E50),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(icon: Icon(Icons.preview), onPressed: _previewOMR),
//         ],
//       ),
//       body: Form(
//         key: _formKey,
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildBasicInfoSection(),
//               SizedBox(height: 24),
//               _buildExamConfigSection(),
//               SizedBox(height: 24),
//               _buildAnswerKeySection(),
//               SizedBox(height: 24),
//               _buildGenerationOptionsSection(),
//               SizedBox(height: 32),
//               _buildActionButtons(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBasicInfoSection() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Basic Information',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF2C3E50),
//               ),
//             ),
//             SizedBox(height: 16),
//             TextFormField(
//               controller: _examNameController,
//               decoration: InputDecoration(
//                 labelText: 'Exam Name',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.assignment),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter exam name';
//                 }
//                 return null;
//               },
//             ),
//             SizedBox(height: 16),
//             DropdownButtonFormField<Course>(
//               value: _selectedCourse,
//               decoration: InputDecoration(
//                 labelText: 'Course',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.school),
//               ),
//               items: _courses.map((course) {
//                 return DropdownMenuItem(
//                   value: course,
//                   child: Text(course.name),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 setState(() {
//                   _selectedCourse = value;
//                 });
//               },
//               validator: (value) {
//                 if (value == null) {
//                   return 'Please select a course';
//                 }
//                 return null;
//               },
//             ),
//             SizedBox(height: 16),
//             TextFormField(
//               controller: _subjectController,
//               decoration: InputDecoration(
//                 labelText: 'Subject',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.subject),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter subject name';
//                 }
//                 return null;
//               },
//             ),
//             SizedBox(height: 16),
//             TextFormField(
//               controller: _descriptionController,
//               decoration: InputDecoration(
//                 labelText: 'Description (Optional)',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.description),
//               ),
//               maxLines: 2,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildExamConfigSection() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Exam Configuration',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF2C3E50),
//               ),
//             ),
//             SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Number of Questions'),
//                       SizedBox(height: 8),
//                       DropdownButtonFormField<int>(
//                         value: _numberOfQuestions,
//                         decoration: InputDecoration(
//                           border: OutlineInputBorder(),
//                           contentPadding: EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 8,
//                           ),
//                         ),
//                         items: [10, 20, 30, 40, 50, 60, 70, 80, 90, 100].map((
//                           num,
//                         ) {
//                           return DropdownMenuItem(
//                             value: num,
//                             child: Text(num.toString()),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           setState(() {
//                             _numberOfQuestions = value!;
//                             _correctAnswers = List.generate(
//                               value,
//                               (index) => index < _correctAnswers.length
//                                   ? _correctAnswers[index]
//                                   : 'A',
//                             );
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Set Number'),
//                       SizedBox(height: 8),
//                       DropdownButtonFormField<int>(
//                         value: _setNumber,
//                         decoration: InputDecoration(
//                           border: OutlineInputBorder(),
//                           contentPadding: EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 8,
//                           ),
//                         ),
//                         items: [1, 2, 3, 4].map((num) {
//                           return DropdownMenuItem(
//                             value: num,
//                             child: Text('Set $num'),
//                           );
//                         }).toList(),
//                         onChanged: (value) {
//                           setState(() {
//                             _setNumber = value!;
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             InkWell(
//               onTap: () async {
//                 final picked = await showDatePicker(
//                   context: context,
//                   initialDate: _examDate,
//                   firstDate: DateTime.now(),
//                   lastDate: DateTime.now().add(Duration(days: 365)),
//                 );
//                 if (picked != null) {
//                   setState(() {
//                     _examDate = picked;
//                   });
//                 }
//               },
//               child: InputDecorator(
//                 decoration: InputDecoration(
//                   labelText: 'Exam Date',
//                   border: OutlineInputBorder(),
//                   prefixIcon: Icon(Icons.calendar_today),
//                 ),
//                 child: Text(
//                   '${_examDate.day}/${_examDate.month}/${_examDate.year}',
//                   style: TextStyle(fontSize: 16),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAnswerKeySection() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(8),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Answer Key',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF2C3E50),
//                   ),
//                 ),
//                 TextButton.icon(
//                   icon: Icon(Icons.auto_fix_high),
//                   label: Text('Quick Fill'),
//                   onPressed: _showQuickFillDialog,
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             Container(
//               height: 300,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: GridView.builder(
//                 padding: EdgeInsets.all(5),
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 3,
//                   childAspectRatio: 1.5,
//                   crossAxisSpacing: 8,
//                   mainAxisSpacing: 8,
//                 ),
//                 itemCount: _numberOfQuestions,
//                 itemBuilder: (context, index) {
//                   return _buildAnswerSelector(index);
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAnswerSelector(int questionIndex) {
//     final options = ['A', 'B', 'C', 'D'];
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             'Q${questionIndex + 1}',
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF2C3E50),
//             ),
//           ),
//           SizedBox(height: 4),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: options.map((option) {
//               final isSelected = _correctAnswers[questionIndex] == option;
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _correctAnswers[questionIndex] = option;
//                   });
//                 },
//                 child: Container(
//                   width: 20,
//                   height: 20,
//                   margin: EdgeInsets.symmetric(horizontal: 2),
//                   decoration: BoxDecoration(
//                     color: isSelected ? Color(0xFF2C3E50) : Colors.white,
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: isSelected ? Color(0xFF2C3E50) : Colors.grey,
//                     ),
//                   ),
//                   child: Center(
//                     child: Text(
//                       option,
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: isSelected ? Colors.white : Colors.grey,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGenerationOptionsSection() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Generation Options',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF2C3E50),
//               ),
//             ),
//             SizedBox(height: 16),
//             SwitchListTile(
//               title: Text('Generate for all students in course'),
//               subtitle: Text('Create personalized OMR sheets for each student'),
//               value: _generateForAllStudents,
//               onChanged: (value) {
//                 setState(() {
//                   _generateForAllStudents = value;
//                   if (value) {
//                     _selectedStudents = _allStudents
//                         .where((s) => s.courseId == _selectedCourse?.id)
//                         .toList();
//                   } else {
//                     _selectedStudents.clear();
//                   }
//                 });
//               },
//             ),
//             if (_generateForAllStudents) ...[
//               SizedBox(height: 16),
//               Text(
//                 'Selected Students (${_selectedStudents.length})',
//                 style: TextStyle(fontWeight: FontWeight.w500),
//               ),
//               SizedBox(height: 8),
//               Container(
//                 height: 150,
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey.shade300),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: ListView.builder(
//                   padding: EdgeInsets.all(8),
//                   itemCount: _selectedStudents.length,
//                   itemBuilder: (context, index) {
//                     final student = _selectedStudents[index];
//                     return CheckboxListTile(
//                       title: Text(student.name),
//                       subtitle: Text('ID: ${student.studentId}'),
//                       value: true,
//                       onChanged: (value) {
//                         setState(() {
//                           if (value == false) {
//                             _selectedStudents.removeAt(index);
//                           }
//                         });
//                       },
//                       dense: true,
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         Expanded(
//           child: OutlinedButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//             style: OutlinedButton.styleFrom(
//               padding: EdgeInsets.symmetric(vertical: 16),
//             ),
//           ),
//         ),
//         SizedBox(width: 16),
//         Expanded(
//           child: ElevatedButton(
//             onPressed: _isLoading ? null : _saveOMRSheet,
//             child: _isLoading
//                 ? SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                 : Text(widget.editingSheet != null ? 'Update' : 'Create'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Color(0xFF2C3E50),
//               padding: EdgeInsets.symmetric(vertical: 16),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   void _showQuickFillDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         String pattern = 'A';
//         return AlertDialog(
//           title: Text('Quick Fill Answers'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Select a pattern to fill all answers:'),
//               SizedBox(height: 16),
//               Wrap(
//                 spacing: 8,
//                 children: ['A', 'B', 'C', 'D', 'Random'].map((option) {
//                   return ChoiceChip(
//                     label: Text(option),
//                     selected: pattern == option,
//                     onSelected: (selected) {
//                       if (selected) {
//                         pattern = option;
//                         Navigator.pop(context);
//                         _applyQuickFill(option);
//                       }
//                     },
//                   );
//                 }).toList(),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   void _applyQuickFill(String pattern) {
//     setState(() {
//       if (pattern == 'Random') {
//         final options = ['A', 'B', 'C', 'D'];
//         _correctAnswers = List.generate(
//           _numberOfQuestions,
//           (index) => options[DateTime.now().millisecondsSinceEpoch % 4],
//         );
//       } else {
//         _correctAnswers = List.filled(_numberOfQuestions, pattern);
//       }
//     });
//   }
//
//   void _previewOMR() {
//     if (!_formKey.currentState!.validate()) return;
//
//     final config = OMRExamConfig(
//       examName: _examNameController.text,
//       numberOfQuestions: _numberOfQuestions,
//       setNumber: _setNumber,
//       studentId: '0000000000',
//       mobileNumber: '00000000000',
//       examDate: _examDate,
//       correctAnswers: _correctAnswers,
//       studentName: 'Preview Student',
//       className: _selectedCourse?.name ?? 'Course',
//     );
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => OMRPreviewWidget(config: config)),
//     );
//   }
//
//   Future<void> _saveOMRSheet() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       final sheet = OMRSheet(
//         id:
//             widget.editingSheet?.id ??
//             DateTime.now().millisecondsSinceEpoch.toString(),
//         examName: _examNameController.text,
//         courseId: _selectedCourse!.id,
//         subjectName: _subjectController.text,
//         setNumber: _setNumber,
//         numberOfQuestions: _numberOfQuestions,
//         correctAnswers: _correctAnswers,
//         createdAt: widget.editingSheet?.createdAt ?? DateTime.now(),
//         examDate: _examDate,
//         description: _descriptionController.text.isEmpty
//             ? null
//             : _descriptionController.text,
//       );
//
//       await _databaseService.saveOMRSheet(sheet);
//
//       if (_generateForAllStudents && _selectedStudents.isNotEmpty) {
//         await _generateOMRsForStudents(sheet);
//       }
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             widget.editingSheet != null
//                 ? 'OMR Sheet updated successfully'
//                 : 'OMR Sheet created successfully',
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//
//       Navigator.pop(context, true);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _generateOMRsForStudents(OMRSheet sheet) async {
//     for (final student in _selectedStudents) {
//       final config = OMRExamConfig(
//         examName: sheet.examName,
//         numberOfQuestions: sheet.numberOfQuestions,
//         setNumber: sheet.setNumber,
//         studentId: student.studentId,
//         mobileNumber: student.mobileNumber,
//         examDate: sheet.examDate,
//         correctAnswers: sheet.correctAnswers,
//         studentName: student.name,
//         className: student.className,
//       );
//
//       await ProfessionalOMRGenerator.generateOMRSheet(config);
//     }
//   }
//
//   @override
//   void dispose() {
//     _examNameController.dispose();
//     _subjectController.dispose();
//     _descriptionController.dispose();
//     super.dispose();
//   }
// }




