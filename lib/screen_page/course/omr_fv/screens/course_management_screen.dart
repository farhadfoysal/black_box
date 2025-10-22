import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';
import '../services/database_service.dart';

class CourseManagementScreen extends StatefulWidget {
  @override
  _CourseManagementScreenState createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  late DatabaseService _databaseService;
  List<Course> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    _databaseService = DatabaseService(prefs);
    await _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);

    final courses = await _databaseService.getAllCourses();
    setState(() {
      _courses = courses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Course Management'),
        backgroundColor: Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showCourseDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _courses.isEmpty
          ? _buildEmptyState()
          : _buildCourseList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No courses available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCourseDialog(),
            icon: Icon(Icons.add),
            label: Text('Add First Course'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        return _buildCourseCard(course);
      },
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF3498DB),
          child: Text(
            course.code,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          course.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          '${course.subjects.length} subjects',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFF3498DB)),
              onPressed: () => _showCourseDialog(course: course),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Color(0xFFE74C3C)),
              onPressed: () => _confirmDelete(course),
            ),
          ],
        ),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.description != null && course.description!.isNotEmpty) ...[
                  Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(course.description!),
                  SizedBox(height: 12),
                ],
                Text(
                  'Subjects:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: course.subjects.map((subject) {
                    return Chip(
                      label: Text(subject),
                      backgroundColor: Color(0xFF3498DB).withOpacity(0.1),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCourseDialog({Course? course}) {
    final isEditing = course != null;
    final nameController = TextEditingController(text: course?.name ?? '');
    final codeController = TextEditingController(text: course?.code ?? '');
    final descriptionController = TextEditingController(text: course?.description ?? '');
    final subjectsController = TextEditingController(
      text: course?.subjects.join(', ') ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Course' : 'Add New Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'Course Code',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              TextField(
                controller: subjectsController,
                decoration: InputDecoration(
                  labelText: 'Subjects (comma separated)',
                  border: OutlineInputBorder(),
                  helperText: 'e.g., Physics, Chemistry, Biology',
                ),
                maxLines: 2,
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
              if (nameController.text.isEmpty || codeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please fill all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final subjects = subjectsController.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();

              if (subjects.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please add at least one subject'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newCourse = Course(
                id: course?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                code: codeController.text.toUpperCase(),
                description: descriptionController.text.isEmpty ? null : descriptionController.text,
                subjects: subjects,
              );

              await _databaseService.saveCourse(newCourse);
              Navigator.pop(context);
              _loadCourses();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEditing ? 'Course updated successfully' : 'Course added successfully'),
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

  void _confirmDelete(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Course'),
        content: Text('Are you sure you want to delete "${course.name}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Check if any students are enrolled in this course
              final students = await _databaseService.getAllStudents();
              final enrolledStudents = students.where((s) => s.courseId == course.id).toList();

              if (enrolledStudents.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cannot delete course with enrolled students'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Delete the course
              final courses = await _databaseService.getAllCourses();
              courses.removeWhere((c) => c.id == course.id);

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                'courses',
                courses.map((c) => c.toJson()).toList().toString(),
              );

              Navigator.pop(context);
              _loadCourses();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Course deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE74C3C),
            ),
          ),
        ],
      ),
    );
  }
}





// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/course_model.dart';
// import '../services/database_service.dart';
//
// class CourseManagementScreen extends StatefulWidget {
//   @override
//   _CourseManagementScreenState createState() => _CourseManagementScreenState();
// }
//
// class _CourseManagementScreenState extends State<CourseManagementScreen> {
//   late DatabaseService _databaseService;
//   List<Course> _courses = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeDatabase();
//   }
//
//   Future<void> _initializeDatabase() async {
//     final prefs = await SharedPreferences.getInstance();
//     _databaseService = DatabaseService(prefs);
//     await _loadCourses();
//   }
//
//   Future<void> _loadCourses() async {
//     setState(() => _isLoading = true);
//
//     final courses = await _databaseService.getAllCourses();
//     setState(() {
//       _courses = courses;
//       _isLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Course Management'),
//         backgroundColor: Color(0xFF2C3E50),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.add),
//             onPressed: () => _showCourseDialog(),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : _courses.isEmpty
//           ? _buildEmptyState()
//           : _buildCourseList(),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.school_outlined,
//             size: 80,
//             color: Colors.grey,
//           ),
//           SizedBox(height: 16),
//           Text(
//             'No courses available',
//             style: TextStyle(fontSize: 16, color: Colors.grey),
//           ),
//           SizedBox(height: 24),
//           ElevatedButton.icon(
//             onPressed: () => _showCourseDialog(),
//             icon: Icon(Icons.add),
//             label: Text('Add First Course'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Color(0xFF2C3E50),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCourseList() {
//     return ListView.builder(
//       padding: EdgeInsets.all(16),
//       itemCount: _courses.length,
//       itemBuilder: (context, index) {
//         final course = _courses[index];
//         return _buildCourseCard(course);
//       },
//     );
//   }
//
//   Widget _buildCourseCard(Course course) {
//     return Card(
//       margin: EdgeInsets.only(bottom: 12),
//       child: ExpansionTile(
//         leading: CircleAvatar(
//           backgroundColor: Color(0xFF3498DB).withOpacity(0.1),
//           child: Text(
//             course.code,
//             style: TextStyle(
//               color: Color(0xFF3498DB),
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ),
//         title: Text(
//           course.name,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         subtitle: Text('${course.subjects.length} subjects'),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(
//               icon: Icon(Icons.edit, color: Color(0xFF3498DB)),
//               onPressed: () => _showCourseDialog(course: course),
//             ),
//             IconButton(
//               icon: Icon(Icons.delete, color: Color(0xFFE74C3C)),
//               onPressed: () => _confirmDelete(course),
//             ),
//           ],
//         ),
//         children: [
//           Padding(
//             padding: EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (course.description != null && course.description!.isNotEmpty) ...[
//                   Text(
//                     'Description:',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 4),
//                   Text(course.description!),
//                   SizedBox(height: 12),
//                 ],
//                 Text(
//                   'Subjects:',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 8),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: course.subjects.map((subject) {
//                     return Chip(
//                       label: Text(subject),
//                       backgroundColor: Color(0xFF2C3E50).withOpacity(0.1),
//                     );
//                   }).toList(),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showCourseDialog({Course? course}) {
//     final isEditing = course != null;
//     final nameController = TextEditingController(text: course?.name ?? '');
//     final codeController = TextEditingController(text: course?.code ?? '');
//     final descriptionController = TextEditingController(text: course?.description ?? '');
//     final subjectsController = TextEditingController(
//       text: course?.subjects.join(', ') ?? '',
//     );
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(isEditing ? 'Edit Course' : 'Add New Course'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: nameController,
//                 decoration: InputDecoration(
//                   labelText: 'Course Name',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: codeController,
//                 decoration: InputDecoration(
//                   labelText: 'Course Code',
//                   border: OutlineInputBorder(),
//                 ),
//                 textCapitalization: TextCapitalization.characters,
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: descriptionController,
//                 decoration: InputDecoration(
//                   labelText: 'Description (Optional)',
//                   border: OutlineInputBorder(),
//                 ),
//                 maxLines: 2,
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: subjectsController,
//                 decoration: InputDecoration(
//                   labelText: 'Subjects (comma separated)',
//                   border: OutlineInputBorder(),
//                   helperText: 'e.g., Physics, Chemistry, Biology',
//                 ),
//                 maxLines: 2,
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (nameController.text.isEmpty ||
//                   codeController.text.isEmpty ||
//                   subjectsController.text.isEmpty) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Please fill all required fields'),
//                     backgroundColor: Colors.orange,
//                   ),
//                 );
//                 return;
//               }
//
//               final subjects = subjectsController.text
//                   .split(',')
//                   .map((s) => s.trim())
//                   .where((s) => s.isNotEmpty)
//                   .toList();
//
//               final newCourse = Course(
//                 id: course?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
//                 name: nameController.text,
//                 code: codeController.text.toUpperCase(),
//                 description: descriptionController.text.isEmpty ? null : descriptionController.text,
//                 subjects: subjects,
//               );
//
//               await _databaseService.saveCourse(newCourse);
//               Navigator.pop(context);
//               _loadCourses();
//
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(isEditing ? 'Course updated successfully' : 'Course added successfully'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             },
//             child: Text(isEditing ? 'Update' : 'Add'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _confirmDelete(Course course) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Delete Course'),
//         content: Text('Are you sure you want to delete "${course.name}"?\n\nThis action cannot be undone.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               // Note: In a real app, you'd need to implement delete in DatabaseService
//               // For now, we'll just remove from the list
//               setState(() {
//                 _courses.removeWhere((c) => c.id == course.id);
//               });
//
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Course deleted successfully'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             },
//             child: Text('Delete'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Color(0xFFE74C3C),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }