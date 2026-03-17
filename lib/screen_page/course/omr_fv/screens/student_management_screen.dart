import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

import '../../../../db/course/courseDbConfig.dart';
import '../../../../model/school/student.dart';

class StudentManagementScreen extends StatefulWidget {
  final String? schoolId;
  final String? userId;
  final String? userType;

  const StudentManagementScreen({
    super.key,
    this.schoolId,
    this.userId,
    this.userType,
  });

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();

  List<Student> _students = [];
  List<Student> _filteredStudents = [];

  bool _isLoading = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _checkConnectivity();
    await _loadStudents();

    Connectivity().onConnectivityChanged.listen((result) {

      final online = result.first != ConnectivityResult.none;

      setState(() => _isOnline = online);

      if (online) _syncWithFirebase();

    });
  }

  Future<void> _checkConnectivity() async {

    final connectivity = await Connectivity().checkConnectivity();

    setState(() {
      _isOnline = connectivity != ConnectivityResult.none;
    });

  }

  // ================= LOAD =================

  Future<void> _loadStudents() async {

    setState(() => _isLoading = true);

    try {

      if (_isOnline) {
        await _loadFromFirebase();
      } else {
        await _loadFromLocal();
      }

    } catch (_) {

      await _loadFromLocal();

    }

    setState(() => _isLoading = false);

  }

  Future<void> _loadFromFirebase() async {

    final snapshot = await _firestore
        .collection('courses')
        .doc(widget.schoolId)
        .collection('students')
        .orderBy('stdName')
        .get();

    _students = snapshot.docs
        .map((doc) => Student.fromMap({...doc.data(), 'uniqueId': doc.id}))
        .toList();

    for (var s in _students) {
      await StudentDatabase.insertStudent(s.toMap());
    }

    _applyFilter();

  }

  Future<void> _loadFromLocal() async {

    final maps = await StudentDatabase.getAllStudents();

    _students = maps.map((e) => Student.fromMap(e)).toList();

    _applyFilter();

  }

  // ================= SYNC =================

  Future<void> _syncWithFirebase() async {

    final unsynced = await StudentDatabase.getUnsyncedStudents();

    for (var map in unsynced) {

      final student = Student.fromMap(map);

      try {

        await _firestore
            .collection('courses')
            .doc(widget.schoolId)
            .collection('students')
            .doc(student.uniqueId)
            .set(student.toMap());

        await StudentDatabase.updateSyncStatus(student.id!, 1);

      } catch (e) {
        debugPrint("Sync error $e");
      }
    }

    _loadStudents();

  }

  // ================= CRUD =================

  Future<void> _createStudent(Student student) async {

    try {

      student.addDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      student.uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      student.syncStatus = _isOnline ? 1 : 0;

      await StudentDatabase.insertStudent(student.toMap());

      if (_isOnline) {

        await _firestore
            .collection('courses')
            .doc(widget.schoolId)
            .collection('students')
            .doc(student.uniqueId)
            .set(student.toMap());

      }

      _success("Student Added");

      _loadStudents();

    } catch (e) {

      _error(e.toString());

    }
  }

  Future<void> _updateStudent(Student student) async {

    try {

      student.syncStatus = _isOnline ? 1 : 0;

      await StudentDatabase.updateStudentByUniqueId(
          student.uniqueId!, student.toMap());

      if (_isOnline) {

        await _firestore
            .collection('courses')
            .doc(widget.schoolId)
            .collection('students')
            .doc(student.uniqueId)
            .update(student.toMap());

      }

      _success("Student Updated");

      _loadStudents();

    } catch (e) {

      _error(e.toString());

    }

  }

  Future<void> _deleteStudent(Student student) async {

    final confirm = await _confirm("Delete Student", "Delete ${student.stdName}?");

    if (confirm != true) return;

    try {

      if (student.imagePath != null) {

        final file = File(student.imagePath!);

        if (await file.exists()) {
          await file.delete();
        }

      }

      await StudentDatabase.deleteStudentByUniqueId(student.uniqueId!);

      if (_isOnline) {

        await _firestore
            .collection('courses')
            .doc(widget.schoolId)
            .collection('students')
            .doc(student.uniqueId)
            .delete();

      }

      _success("Student Deleted");

      _loadStudents();

    } catch (e) {

      _error(e.toString());

    }

  }

  // ================= FILTER =================

  void _applyFilter() {

    final query = _searchController.text.toLowerCase();

    _filteredStudents = _students.where((s) {

      return (s.stdName ?? '').toLowerCase().contains(query) ||
          (s.studentId ?? '').toLowerCase().contains(query) ||
          (s.major ?? '').toLowerCase().contains(query);

    }).toList();

    setState(() {});

  }

  // ================= UI HELPERS =================

  void _success(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.green, content: Text(msg)),
    );
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(msg)),
    );
  }

  Future<bool?> _confirm(String title, String msg) {

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [

          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false), // ✅ FIX
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true), // ✅ FIX
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          )

        ],
      ),
    );

  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Student Management"),
        backgroundColor: const Color(0xFF2C3E50),
        actions: [

          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _studentDialog(),
          )

        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(

        children: [

          _searchBar(),

          Expanded(
            child: _filteredStudents.isEmpty
                ? _emptyView()
                : _studentList(),
          ),

        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.upload_file),
        label: const Text("Bulk Import"),
        onPressed: _bulkDialog,
      ),

    );

  }

  Widget _searchBar() {

    return Padding(
      padding: const EdgeInsets.all(16),

      child: TextField(

        controller: _searchController,

        onChanged: (_) => _applyFilter(),

        decoration: InputDecoration(
          hintText: "Search students...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
      ),
    );

  }

  Widget _emptyView() {

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          const Icon(Icons.people_outline, size: 80, color: Colors.grey),

          const SizedBox(height: 10),

          const Text("No students found"),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add Student"),
            onPressed: () => _studentDialog(),
          )

        ],
      ),
    );

  }

  Widget _studentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, i) {
        final s = _filteredStudents[i];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 4,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),

              // 🔵 Avatar
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  (s.stdName ?? "S")[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue,
                  ),
                ),
              ),

              // 🧑 Name
              title: Text(
                s.stdName ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              // 📄 Info Section
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        const Icon(Icons.badge, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text("ID: ${s.stdId ?? ''}"),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(Icons.school, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text("Class: ${s.major ?? ''}"),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(s.stdPhone ?? ''),
                      ],
                    ),
                  ],
                ),
              ),

              isThreeLine: true,

              // ⚙️ Menu
              trailing: PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                icon: const Icon(Icons.more_vert),

                onSelected: (v) {
                  if (v == "edit") {
                    _studentDialog(student: s);
                  } else if (v == "delete") {
                    _deleteStudent(s);
                  }
                },

                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: "edit",
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text("Edit"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: "delete",
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text("Delete"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget _studentList() {
  //
  //   return ListView.builder(
  //
  //     padding: const EdgeInsets.all(16),
  //
  //     itemCount: _filteredStudents.length,
  //
  //     itemBuilder: (_, i) {
  //
  //       final s = _filteredStudents[i];
  //
  //       return Card(
  //
  //         child: ListTile(
  //
  //           leading: CircleAvatar(
  //             child: Text((s.stdName ?? "S")[0].toUpperCase()),
  //           ),
  //
  //           title: Text(s.stdName ?? ""),
  //
  //           subtitle: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //
  //               Text("ID: ${s.stdId ?? ''}"),
  //               Text("Class: ${s.major ?? ''}"),
  //               Text("Mobile: ${s.stdPhone ?? ''}"),
  //
  //             ],
  //           ),
  //
  //           isThreeLine: true,
  //
  //           trailing: PopupMenuButton(
  //
  //             onSelected: (v) {
  //
  //               if (v == "edit") {
  //                 _studentDialog(student: s);
  //               }
  //
  //               if (v == "delete") {
  //                 _deleteStudent(s);
  //               }
  //
  //             },
  //
  //             itemBuilder: (_) => const [
  //
  //               PopupMenuItem(value: "edit", child: Text("Edit")),
  //               PopupMenuItem(value: "delete", child: Text("Delete")),
  //
  //             ],
  //
  //           ),
  //
  //         ),
  //       );
  //
  //     },
  //   );
  //
  // }

  // ================= DIALOGS =================

  void _studentDialog({Student? student}) {

    final name = TextEditingController(text: student?.stdName);
    final id = TextEditingController(text: student?.studentId);
    final mobile = TextEditingController(text: student?.stdPhone);
    final cls = TextEditingController(text: student?.major);
    final email = TextEditingController(text: student?.stdEmail);

    final editing = student != null;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(editing ? "Edit Student" : "Add Student"),

        content: SingleChildScrollView(
          child: Column(
            children: [
              _field(name, "Name"),
              _field(id, "Student ID"),
              _field(mobile, "Mobile"),
              _field(cls, "Class"),
              _field(email, "Email"),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // ✅ FIXED
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            child: Text(editing ? "Update" : "Add"),
            onPressed: () async {

              final s = Student(
                id: student?.id,
                uniqueId: student?.uniqueId,
                stdName: name.text,
                studentId: id.text,
                stdPhone: mobile.text,
                major: cls.text,
                stdEmail: email.text,
                addDate: student?.addDate,
              );

              Navigator.pop(dialogContext); // ✅ FIXED

              if (editing) {
                await _updateStudent(s);
              } else {
                await _createStudent(s);
              }
            },
          )
        ],
      ),
    );

  }

  Widget _field(TextEditingController c, String label) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: TextField(
        controller: c,
        decoration: InputDecoration(labelText: label),
      ),
    );

  }

  void _bulkDialog() {

    showDialog(

      context: context,

      builder: (_) => AlertDialog(

        title: const Text("Bulk Import"),

        content: const Text(
            "CSV format:\nName, Student ID, Mobile, Class, Email"),

        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _success("CSV import coming soon");
            },
            child: const Text("Select File"),
          )

        ],

      ),
    );

  }

}








// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:intl/intl.dart';
//
// import '../../../../db/course/courseDbConfig.dart';
// import '../../../../model/school/student.dart';
// import '../../screen/course_students.dart';
//
//
// class StudentManagementScreen extends StatefulWidget {
//   final String? schoolId;
//   final String? userId;
//   final String? userType; // 'admin' or 'teacher'
//
//   const StudentManagementScreen({
//     Key? key,
//     this.schoolId,
//     this.userId,
//     this.userType,
//   }) : super(key: key);
//
//   @override
//   State<StudentManagementScreen> createState() => _StudentManagementScreenState();
// }
//
// class _StudentManagementScreenState extends State<StudentManagementScreen>
//     with SingleTickerProviderStateMixin {
//
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   List<Student> _students = [];
//   List<Student> _filteredStudents = [];
//
//   bool _isLoading = true;
//   bool _isOnline = true;
//
//   String _searchQuery = '';
//
//   final TextEditingController _searchController = TextEditingController();
//   late TabController _tabController;
//
//   final Color _primaryColor = const Color(0xFF667eea);
//   final Color _successColor = const Color(0xFF10b981);
//   final Color _errorColor = const Color(0xFFef4444);
//
//   @override
//   void initState() {
//     super.initState();
//
//     _tabController = TabController(length: 3, vsync: this);
//
//     _checkConnectivity();
//     _loadStudents();
//
//     Connectivity().onConnectivityChanged.listen((results) {
//       final result = results.first;
//
//       setState(() {
//         _isOnline = result != ConnectivityResult.none;
//       });
//
//       if (_isOnline) {
//         _syncWithFirebase();
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _checkConnectivity() async {
//     final connectivity = await Connectivity().checkConnectivity();
//
//     setState(() {
//       _isOnline = connectivity != ConnectivityResult.none;
//     });
//   }
//
//   // ================= LOAD STUDENTS =================
//
//   Future<void> _loadStudents() async {
//     setState(() => _isLoading = true);
//
//     try {
//       if (_isOnline) {
//         await _loadFromFirebase();
//       } else {
//         await _loadFromLocalDatabase();
//       }
//     } catch (e) {
//       await _loadFromLocalDatabase();
//     }
//
//     setState(() => _isLoading = false);
//   }
//
//   Future<void> _loadFromFirebase() async {
//
//     final snapshot = await _firestore
//         .collection('courses')
//         .doc(widget.schoolId)
//         .collection('students')
//         .orderBy('stdName')
//         .get();
//
//     _students = snapshot.docs
//         .map((doc) => Student.fromMap({...doc.data(), 'uniqueId': doc.id}))
//         .toList();
//
//     for (var student in _students) {
//       await StudentDatabase.insertStudent(student.toMap());
//     }
//
//     _applyFilters();
//   }
//
//   Future<void> _loadFromLocalDatabase() async {
//
//     final maps = await StudentDatabase.getAllStudents();
//
//     _students = maps.map((map) => Student.fromMap(map)).toList();
//
//     _applyFilters();
//   }
//
//   // ================= SYNC =================
//
//   Future<void> _syncWithFirebase() async {
//
//     final unsynced = await StudentDatabase.getUnsyncedStudents();
//
//     for (var map in unsynced) {
//
//       final student = Student.fromMap(map);
//
//       try {
//
//         await _firestore
//             .collection('courses')
//             .doc(widget.schoolId)
//             .collection('students')
//             .doc(student.uniqueId)
//             .set(student.toMap());
//
//         await StudentDatabase.updateSyncStatus(student.id!, 1);
//
//       } catch (e) {
//         debugPrint(e.toString());
//       }
//     }
//
//     _loadStudents();
//   }
//
//   // ================= CRUD =================
//
//   Future<void> _addOrUpdateStudent(Student? student) async {
//
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => StudentFormScreen(
//           student: student,
//           schoolId: widget.schoolId ?? '',
//           isOnline: _isOnline,
//         ),
//       ),
//     );
//
//     if (result != null && result is Student) {
//
//       if (student == null) {
//         await _createStudent(result);
//       } else {
//         await _updateStudent(result);
//       }
//     }
//   }
//
//   Future<void> _createStudent(Student student) async {
//
//     try {
//
//       student.addDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
//       student.uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
//       student.syncStatus = _isOnline ? 1 : 0;
//
//       await StudentDatabase.insertStudent(student.toMap());
//
//       if (_isOnline) {
//
//         await _firestore
//             .collection('courses')
//             .doc(widget.schoolId)
//             .collection('students')
//             .doc(student.uniqueId)
//             .set(student.toMap());
//       }
//
//       _showSuccessSnackBar("Student Added");
//
//       _loadStudents();
//
//     } catch (e) {
//       _showErrorSnackBar(e.toString());
//     }
//   }
//
//   Future<void> _updateStudent(Student student) async {
//
//     try {
//
//       student.syncStatus = _isOnline ? 1 : 0;
//
//       await StudentDatabase.updateStudentByUniqueId(
//           student.uniqueId!, student.toMap());
//
//       if (_isOnline) {
//
//         await _firestore
//             .collection('courses')
//             .doc(widget.schoolId)
//             .collection('students')
//             .doc(student.uniqueId)
//             .update(student.toMap());
//       }
//
//       _showSuccessSnackBar("Student Updated");
//
//       _loadStudents();
//
//     } catch (e) {
//       _showErrorSnackBar(e.toString());
//     }
//   }
//
//   Future<void> _deleteStudent(Student student) async {
//
//     final confirm = await _showConfirmDialog(
//         "Delete Student", "Delete ${student.stdName}?");
//
//     if (confirm != true) return;
//
//     try {
//
//       if (student.imagePath != null) {
//
//         final file = File(student.imagePath!);
//
//         if (await file.exists()) {
//           await file.delete();
//         }
//       }
//
//       await StudentDatabase.deleteStudentByUniqueId(student.uniqueId!);
//
//       if (_isOnline) {
//
//         await _firestore
//             .collection('courses')
//             .doc(widget.schoolId)
//             .collection('students')
//             .doc(student.uniqueId)
//             .delete();
//       }
//
//       _showSuccessSnackBar("Student Deleted");
//
//       _loadStudents();
//
//     } catch (e) {
//       _showErrorSnackBar(e.toString());
//     }
//   }
//
//   // ================= FILTER =================
//
//   void _applyFilters() {
//
//     _filteredStudents = _students.where((student) {
//
//       final name = student.stdName?.toLowerCase() ?? '';
//       final id = student.studentId?.toLowerCase() ?? '';
//
//       return name.contains(_searchQuery.toLowerCase()) ||
//           id.contains(_searchQuery.toLowerCase());
//
//     }).toList();
//
//     setState(() {});
//   }
//
//   void _filterStudents(String query) {
//     setState(() {
//       _searchQuery = query;
//
//       _filteredStudents = _students.where((student) {
//         return (student.stdName ?? '')
//             .toLowerCase()
//             .contains(query.toLowerCase()) ||
//             (student.studentId ?? '')
//                 .toLowerCase()
//                 .contains(query.toLowerCase()) ||
//             (student.major ?? '')
//                 .toLowerCase()
//                 .contains(query.toLowerCase());
//       }).toList();
//     });
//   }
//
//   // ============= UI HELPERS =============
//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.check_circle, color: Colors.white),
//             SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: _successColor,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }
//
//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.error, color: Colors.white),
//             SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: _errorColor,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }
//
//   Future<bool?> _showConfirmDialog(String title, String message) {
//     return showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: Text('Cancel', style: TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _errorColor,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//   // ================= UI =================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Student Management'),
//         backgroundColor: const Color(0xFF2C3E50),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: () => _showStudentDialog(),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           _buildSearchBar(),
//           Expanded(
//             child: _filteredStudents.isEmpty
//                 ? _buildEmptyState()
//                 : _buildStudentList(),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () => _showBulkImportDialog(),
//         icon: const Icon(Icons.upload_file),
//         label: const Text('Bulk Import'),
//         backgroundColor: const Color(0xFF3498DB),
//       ),
//     );
//   }
//
//   Widget _buildSearchBar() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       color: Colors.grey.shade100,
//       child: TextField(
//         decoration: InputDecoration(
//           hintText: 'Search students...',
//           prefixIcon: const Icon(Icons.search),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide.none,
//           ),
//           filled: true,
//           fillColor: Colors.white,
//         ),
//         onChanged: _filterStudents,
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(
//             Icons.people_outline,
//             size: 80,
//             color: Colors.grey,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             _searchQuery.isEmpty
//                 ? 'No students added yet'
//                 : 'No students found matching "$_searchQuery"',
//             style: const TextStyle(fontSize: 16, color: Colors.grey),
//           ),
//           if (_searchQuery.isEmpty) ...[
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () => _showStudentDialog(),
//               icon: const Icon(Icons.add),
//               label: const Text('Add First Student'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF2C3E50),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStudentList() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: _filteredStudents.length,
//       itemBuilder: (context, index) {
//         final student = _filteredStudents[index];
//
//         return Card(
//           margin: const EdgeInsets.only(bottom: 12),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundColor: const Color(0xFF3498DB),
//               child: Text(
//                 (student.stdName ?? 'S').substring(0, 1).toUpperCase(),
//                 style: const TextStyle(
//                     color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//             ),
//             title: Text(
//               student.stdName ?? '',
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('ID: ${student.studentId ?? ''}'),
//                 Text('Class: ${student.major ?? ''}'),
//                 Text('Mobile: ${student.stdPhone ?? ''}'),
//               ],
//             ),
//             isThreeLine: true,
//             trailing: PopupMenuButton<String>(
//               onSelected: (value) {
//                 if (value == 'edit') {
//                   _showStudentDialog(student: student);
//                 } else if (value == 'delete') {
//                   _confirmDelete(student);
//                 }
//               },
//               itemBuilder: (context) => const [
//                 PopupMenuItem(value: 'edit', child: Text('Edit')),
//                 PopupMenuItem(value: 'delete', child: Text('Delete')),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   void _showStudentDialog({Student? student}) {
//     final isEditing = student != null;
//
//     final nameController =
//     TextEditingController(text: student?.stdName ?? '');
//     final studentIdController =
//     TextEditingController(text: student?.studentId ?? '');
//     final mobileController =
//     TextEditingController(text: student?.stdPhone ?? '');
//     final classController =
//     TextEditingController(text: student?.major ?? '');
//     final emailController =
//     TextEditingController(text: student?.stdEmail ?? '');
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(isEditing ? 'Edit Student' : 'Add Student'),
//         content: SingleChildScrollView(
//           child: Column(
//             children: [
//               TextField(
//                 controller: nameController,
//                 decoration:
//                 const InputDecoration(labelText: 'Student Name'),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: studentIdController,
//                 decoration:
//                 const InputDecoration(labelText: 'Student ID'),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: mobileController,
//                 decoration:
//                 const InputDecoration(labelText: 'Mobile Number'),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: classController,
//                 decoration: const InputDecoration(labelText: 'Class'),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: emailController,
//                 decoration: const InputDecoration(labelText: 'Email'),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               final newStudent = Student(
//                 id: student?.id,
//                 stdName: nameController.text,
//                 studentId: studentIdController.text,
//                 stdPhone: mobileController.text,
//                 major: classController.text,
//                 stdEmail: emailController.text,
//                 addDate:
//                 student?.addDate ?? DateTime.now().toIso8601String(),
//               );
//
//               // await _databaseService.saveStudent(newStudent);
//
//               await _createStudent(newStudent);
//
//               Navigator.pop(context);
//               _loadStudents();
//
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(isEditing
//                       ? 'Student updated successfully'
//                       : 'Student added successfully'),
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
//   void _showBulkImportDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Bulk Import Students'),
//         content: const Text(
//             'CSV format: Name, Student ID, Mobile, Class, Email'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('CSV import feature coming soon'),
//                 ),
//               );
//             },
//             child: const Text('Select File'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _confirmDelete(Student student) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Student'),
//         content:
//         Text('Are you sure you want to delete ${student.stdName}?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             style:
//             ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             onPressed: () async {
//               if (student.id != null) {
//                 // await _databaseService.deleteStudent(student.id!);
//               }
//
//               Navigator.pop(context);
//               _loadStudents();
//
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Student deleted successfully'),
//                 ),
//               );
//             },
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }
// }








// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/student_model.dart';
// import '../models/course_model.dart';
// import '../services/database_service.dart';
//
// class StudentManagementScreen extends StatefulWidget {
//   final String? schoolId;
//   final String? userId;
//   final String? userType; // 'admin' or 'teacher'
//
//   const StudentManagementScreen({
//     Key? key,
//     this.schoolId,
//     this.userId,
//     this.userType,
//   }) : super(key: key);
//   @override
//   _StudentManagementScreenState createState() => _StudentManagementScreenState();
// }
//
// class _StudentManagementScreenState extends State<StudentManagementScreen> {
//   late DatabaseService _databaseService;
//   List<Student> _students = [];
//   List<Student> _filteredStudents = [];
//   List<Course> _courses = [];
//   String _searchQuery = '';
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
//     await _loadData();
//   }
//
//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);
//
//     final students = await _databaseService.getAllStudents();
//     final courses = await _databaseService.getAllCourses();
//
//     setState(() {
//       _students = students;
//       _filteredStudents = students;
//       _courses = courses;
//       _isLoading = false;
//     });
//   }
//
//   void _filterStudents(String query) {
//     setState(() {
//       _searchQuery = query;
//       _filteredStudents = _students.where((student) {
//         return student.name.toLowerCase().contains(query.toLowerCase()) ||
//             student.studentId.toLowerCase().contains(query.toLowerCase()) ||
//             student.className.toLowerCase().contains(query.toLowerCase());
//       }).toList();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Student Management'),
//         backgroundColor: Color(0xFF2C3E50),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.add),
//             onPressed: () => _showStudentDialog(),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           _buildSearchBar(),
//           _buildStatistics(),
//           Expanded(
//             child: _filteredStudents.isEmpty
//                 ? _buildEmptyState()
//                 : _buildStudentList(),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () => _showBulkImportDialog(),
//         icon: Icon(Icons.upload_file),
//         label: Text('Bulk Import'),
//         backgroundColor: Color(0xFF3498DB),
//       ),
//     );
//   }
//
//   Widget _buildSearchBar() {
//     return Container(
//       padding: EdgeInsets.all(16),
//       color: Colors.grey.shade100,
//       child: TextField(
//         decoration: InputDecoration(
//           hintText: 'Search students...',
//           prefixIcon: Icon(Icons.search),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide.none,
//           ),
//           filled: true,
//           fillColor: Colors.white,
//         ),
//         onChanged: _filterStudents,
//       ),
//     );
//   }
//
//   Widget _buildStatistics() {
//     final courseStats = <String, int>{};
//     for (final student in _students) {
//       final courseName = _courses.firstWhere(
//             (c) => c.id == student.courseId,
//         orElse: () => Course(id: '', name: 'Unknown', code: '', subjects: []),
//       ).name;
//       courseStats[courseName] = (courseStats[courseName] ?? 0) + 1;
//     }
//
//     return Container(
//       height: 130,
//       padding: EdgeInsets.symmetric(horizontal: 10),
//       child: ListView(
//         scrollDirection: Axis.horizontal,
//         children: [
//           _buildStatCard(
//             'Total Students',
//             _students.length.toString(),
//             Icons.people,
//             Color(0xFF2C3E50),
//           ),
//           ...courseStats.entries.map((entry) => _buildStatCard(
//             entry.key,
//             entry.value.toString(),
//             Icons.school,
//             Color(0xFF3498DB),
//           )),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatCard(String label, String value, IconData icon, Color color) {
//     return Container(
//       width: 150,
//       margin: EdgeInsets.only(right: 12, bottom: 16),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: color, size: 24),
//           SizedBox(height: 8),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey[600],
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.people_outline,
//             size: 80,
//             color: Colors.grey,
//           ),
//           SizedBox(height: 16),
//           Text(
//             _searchQuery.isEmpty
//                 ? 'No students added yet'
//                 : 'No students found matching "$_searchQuery"',
//             style: TextStyle(fontSize: 16, color: Colors.grey),
//           ),
//           if (_searchQuery.isEmpty) ...[
//             SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () => _showStudentDialog(),
//               icon: Icon(Icons.add),
//               label: Text('Add First Student'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Color(0xFF2C3E50),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStudentList() {
//     return ListView.builder(
//       padding: EdgeInsets.all(16),
//       itemCount: _filteredStudents.length,
//       itemBuilder: (context, index) {
//         final student = _filteredStudents[index];
//         final course = _courses.firstWhere(
//               (c) => c.id == student.courseId,
//           orElse: () => Course(id: '', name: 'Unknown', code: '', subjects: []),
//         );
//
//         return Card(
//           margin: EdgeInsets.only(bottom: 12),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Color(0xFF3498DB),
//               child: Text(
//                 student.name.substring(0, 1).toUpperCase(),
//                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//             ),
//             title: Text(
//               student.name,
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('ID: ${student.studentId} • ${student.className}'),
//                 Text('Course: ${course.name} • Mobile: ${student.mobileNumber}'),
//               ],
//             ),
//             isThreeLine: true,
//             trailing: PopupMenuButton<String>(
//               onSelected: (value) {
//                 if (value == 'edit') {
//                   _showStudentDialog(student: student);
//                 } else if (value == 'delete') {
//                   _confirmDelete(student);
//                 }
//               },
//               itemBuilder: (context) => [
//                 PopupMenuItem(value: 'edit', child: Text('Edit')),
//                 PopupMenuItem(value: 'delete', child: Text('Delete')),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   void _showStudentDialog({Student? student}) {
//     final isEditing = student != null;
//     final nameController = TextEditingController(text: student?.name ?? '');
//     final studentIdController = TextEditingController(text: student?.studentId ?? '');
//     final mobileController = TextEditingController(text: student?.mobileNumber ?? '');
//     final classController = TextEditingController(text: student?.className ?? '');
//     final emailController = TextEditingController(text: student?.email ?? '');
//     String? selectedCourseId = student?.courseId ?? (_courses.isNotEmpty ? _courses.first.id : null);
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(isEditing ? 'Edit Student' : 'Add New Student'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: nameController,
//                 decoration: InputDecoration(
//                   labelText: 'Student Name',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: studentIdController,
//                 decoration: InputDecoration(
//                   labelText: 'Student ID (10 digits)',
//                   border: OutlineInputBorder(),
//                 ),
//                 keyboardType: TextInputType.number,
//                 maxLength: 10,
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: mobileController,
//                 decoration: InputDecoration(
//                   labelText: 'Mobile Number (11 digits)',
//                   border: OutlineInputBorder(),
//                 ),
//                 keyboardType: TextInputType.phone,
//                 maxLength: 11,
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: classController,
//                 decoration: InputDecoration(
//                   labelText: 'Class/Grade',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: selectedCourseId,
//                 decoration: InputDecoration(
//                   labelText: 'Course',
//                   border: OutlineInputBorder(),
//                 ),
//                 items: _courses.map((course) {
//                   return DropdownMenuItem(
//                     value: course.id,
//                     child: Text(course.name),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   selectedCourseId = value;
//                 },
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: emailController,
//                 decoration: InputDecoration(
//                   labelText: 'Email (Optional)',
//                   border: OutlineInputBorder(),
//                 ),
//                 keyboardType: TextInputType.emailAddress,
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
//                   studentIdController.text.length != 10 ||
//                   mobileController.text.length != 11 ||
//                   classController.text.isEmpty ||
//                   selectedCourseId == null) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Please fill all required fields correctly'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//                 return;
//               }
//
//               final newStudent = Student(
//                 id: student?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
//                 name: nameController.text,
//                 studentId: studentIdController.text,
//                 mobileNumber: mobileController.text,
//                 className: classController.text,
//                 courseId: selectedCourseId!,
//                 email: emailController.text.isEmpty ? null : emailController.text,
//                 enrollmentDate: student?.enrollmentDate ?? DateTime.now(),
//               );
//
//               await _databaseService.saveStudent(newStudent);
//               Navigator.pop(context);
//               _loadData();
//
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(isEditing ? 'Student updated successfully' : 'Student added successfully'),
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
//   void _showBulkImportDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Bulk Import Students'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.upload_file, size: 64, color: Colors.grey),
//             SizedBox(height: 16),
//             Text(
//               'Import students from CSV file',
//               style: TextStyle(fontSize: 16),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'CSV format: Name, Student ID, Mobile, Class, Course ID',
//               style: TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               // TODO: Implement CSV import
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('CSV import feature coming soon'),
//                   backgroundColor: Colors.orange,
//                 ),
//               );
//             },
//             child: Text('Select File'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _confirmDelete(Student student) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Delete Student'),
//         content: Text('Are you sure you want to delete ${student.name}?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               await _databaseService.deleteStudent(student.id);
//
//               Navigator.pop(context);
//               _loadData();
//
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Student deleted successfully'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             },
//             child: Text('Delete'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Color(0xFFE74C3C),
//             ),
//           ),
//
//           // ElevatedButton(
//           //     onPressed: () async {
//           //       _students.removeWhere((s) => s.id == student.id);
//           //       await _databaseService.saveStudentList(_students); // custom helper below
//           //
//           //       Navigator.pop(context);
//           //       _loadData();
//           //
//           //       ScaffoldMessenger.of(context).showSnackBar(
//           //         SnackBar(
//           //           content: Text('Student deleted successfully'),
//           //           backgroundColor: Colors.green,
//           //         ),
//           //       );
//           //     },
//           //     ...
//           // ),
//
//
//           // ElevatedButton(
//           //   onPressed: () async {
//           //     // Remove student from list
//           //     _students.removeWhere((s) => s.id == student.id);
//           //     // await _databaseService.setString(
//           //     //   'students',
//           //     //   _students.map((s) => s.toJson()).toList().toString(),
//           //     // );
//           //
//           //     Navigator.pop(context);
//           //     _loadData();
//           //
//           //     ScaffoldMessenger.of(context).showSnackBar(
//           //       SnackBar(
//           //         content: Text('Student deleted successfully'),
//           //         backgroundColor: Colors.green,
//           //       ),
//           //     );
//           //   },
//           //   child: Text('Delete'),
//           //   style: ElevatedButton.styleFrom(
//           //     backgroundColor: Color(0xFFE74C3C),
//           //   ),
//           // ),
//
//         ],
//       ),
//     );
//   }
// }
//
//
//
//
