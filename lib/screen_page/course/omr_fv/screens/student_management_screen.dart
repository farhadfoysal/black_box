import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_model.dart';
import '../models/course_model.dart';
import '../services/database_service.dart';

class StudentManagementScreen extends StatefulWidget {
  @override
  _StudentManagementScreenState createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  late DatabaseService _databaseService;
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  List<Course> _courses = [];
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
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final students = await _databaseService.getAllStudents();
    final courses = await _databaseService.getAllCourses();

    setState(() {
      _students = students;
      _filteredStudents = students;
      _courses = courses;
      _isLoading = false;
    });
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      _filteredStudents = _students.where((student) {
        return student.name.toLowerCase().contains(query.toLowerCase()) ||
            student.studentId.toLowerCase().contains(query.toLowerCase()) ||
            student.className.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Management'),
        backgroundColor: Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showStudentDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildSearchBar(),
          _buildStatistics(),
          Expanded(
            child: _filteredStudents.isEmpty
                ? _buildEmptyState()
                : _buildStudentList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBulkImportDialog(),
        icon: Icon(Icons.upload_file),
        label: Text('Bulk Import'),
        backgroundColor: Color(0xFF3498DB),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search students...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: _filterStudents,
      ),
    );
  }

  Widget _buildStatistics() {
    final courseStats = <String, int>{};
    for (final student in _students) {
      final courseName = _courses.firstWhere(
            (c) => c.id == student.courseId,
        orElse: () => Course(id: '', name: 'Unknown', code: '', subjects: []),
      ).name;
      courseStats[courseName] = (courseStats[courseName] ?? 0) + 1;
    }

    return Container(
      height: 130,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard(
            'Total Students',
            _students.length.toString(),
            Icons.people,
            Color(0xFF2C3E50),
          ),
          ...courseStats.entries.map((entry) => _buildStatCard(
            entry.key,
            entry.value.toString(),
            Icons.school,
            Color(0xFF3498DB),
          )),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      margin: EdgeInsets.only(right: 12, bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No students added yet'
                : 'No students found matching "$_searchQuery"',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (_searchQuery.isEmpty) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showStudentDialog(),
              icon: Icon(Icons.add),
              label: Text('Add First Student'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2C3E50),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final course = _courses.firstWhere(
              (c) => c.id == student.courseId,
          orElse: () => Course(id: '', name: 'Unknown', code: '', subjects: []),
        );

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFF3498DB),
              child: Text(
                student.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              student.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${student.studentId} • ${student.className}'),
                Text('Course: ${course.name} • Mobile: ${student.mobileNumber}'),
              ],
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showStudentDialog(student: student);
                } else if (value == 'delete') {
                  _confirmDelete(student);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStudentDialog({Student? student}) {
    final isEditing = student != null;
    final nameController = TextEditingController(text: student?.name ?? '');
    final studentIdController = TextEditingController(text: student?.studentId ?? '');
    final mobileController = TextEditingController(text: student?.mobileNumber ?? '');
    final classController = TextEditingController(text: student?.className ?? '');
    final emailController = TextEditingController(text: student?.email ?? '');
    String? selectedCourseId = student?.courseId ?? (_courses.isNotEmpty ? _courses.first.id : null);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Student' : 'Add New Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: studentIdController,
                decoration: InputDecoration(
                  labelText: 'Student ID (10 digits)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 10,
              ),
              SizedBox(height: 16),
              TextField(
                controller: mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number (11 digits)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 11,
              ),
              SizedBox(height: 16),
              TextField(
                controller: classController,
                decoration: InputDecoration(
                  labelText: 'Class/Grade',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCourseId,
                decoration: InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(),
                ),
                items: _courses.map((course) {
                  return DropdownMenuItem(
                    value: course.id,
                    child: Text(course.name),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCourseId = value;
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
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
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  studentIdController.text.length != 10 ||
                  mobileController.text.length != 11 ||
                  classController.text.isEmpty ||
                  selectedCourseId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please fill all required fields correctly'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newStudent = Student(
                id: student?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                studentId: studentIdController.text,
                mobileNumber: mobileController.text,
                className: classController.text,
                courseId: selectedCourseId!,
                email: emailController.text.isEmpty ? null : emailController.text,
                enrollmentDate: student?.enrollmentDate ?? DateTime.now(),
              );

              await _databaseService.saveStudent(newStudent);
              Navigator.pop(context);
              _loadData();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEditing ? 'Student updated successfully' : 'Student added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showBulkImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Import Students'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Import students from CSV file',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'CSV format: Name, Student ID, Mobile, Class, Course ID',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement CSV import
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('CSV import feature coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: Text('Select File'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _databaseService.deleteStudent(student.id);

              Navigator.pop(context);
              _loadData();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Student deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE74C3C),
            ),
          ),

          // ElevatedButton(
          //     onPressed: () async {
          //       _students.removeWhere((s) => s.id == student.id);
          //       await _databaseService.saveStudentList(_students); // custom helper below
          //
          //       Navigator.pop(context);
          //       _loadData();
          //
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         SnackBar(
          //           content: Text('Student deleted successfully'),
          //           backgroundColor: Colors.green,
          //         ),
          //       );
          //     },
          //     ...
          // ),


          // ElevatedButton(
          //   onPressed: () async {
          //     // Remove student from list
          //     _students.removeWhere((s) => s.id == student.id);
          //     // await _databaseService.setString(
          //     //   'students',
          //     //   _students.map((s) => s.toJson()).toList().toString(),
          //     // );
          //
          //     Navigator.pop(context);
          //     _loadData();
          //
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(
          //         content: Text('Student deleted successfully'),
          //         backgroundColor: Colors.green,
          //       ),
          //     );
          //   },
          //   child: Text('Delete'),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: Color(0xFFE74C3C),
          //   ),
          // ),

        ],
      ),
    );
  }
}




