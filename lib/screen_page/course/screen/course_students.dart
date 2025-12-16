// students_list.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../db/course/courseDbConfig.dart';
import '../../../model/school/student.dart';

class StudentsListScreen extends StatefulWidget {
  final String schoolId;
  final String userId;
  final String userType; // 'admin' or 'teacher'

  const StudentsListScreen({
    Key? key,
    required this.schoolId,
    required this.userId,
    required this.userType,
  }) : super(key: key);

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen>
    with SingleTickerProviderStateMixin {
  // Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  bool _isOnline = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Colors
  final Color _primaryColor = const Color(0xFF667eea);
  final Color _secondaryColor = const Color(0xFF764ba2);
  final Color _accentColor = const Color(0xFFf093fb);
  final Color _successColor = const Color(0xFF10b981);
  final Color _warningColor = const Color(0xFFf59e0b);
  final Color _errorColor = const Color(0xFFef4444);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkConnectivity();
    _loadStudents();

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Pick the first result as the current connectivity status
      final result = results.first;
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      if (_isOnline) {
        _syncWithFirebase();
      }
    });

  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  // ============= DATA LOADING =============
  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      if (_isOnline) {
        await _loadFromFirebase();
      } else {
        await _loadFromLocalDatabase();
      }
    } catch (e) {
      print('Error loading students: $e');
      _showErrorSnackBar('Error loading students: $e');
      await _loadFromLocalDatabase();
    } finally {
      setState(() => _isLoading = false);
    }
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

    // Save to local database
    for (var student in _students) {
      await StudentDatabase.insertStudent(student.toMap());
    }

    _applyFilters();
  }

  Future<void> _loadFromLocalDatabase() async {
    final List<Map<String, dynamic>> maps =
    await StudentDatabase.getAllStudents();

    _students = maps.map((map) => Student.fromMap(map)).toList();
    _applyFilters();
  }

  Future<void> _syncWithFirebase() async {
    if (!_isOnline) return;

    // Get all unsynced students
    final List<Map<String, dynamic>> unsyncedMaps =
    await StudentDatabase.getUnsyncedStudents();

    for (var map in unsyncedMaps) {
      final student = Student.fromMap(map);
      try {
        // Upload to Firebase
        final docRef = _firestore
            .collection('courses')
            .doc(widget.schoolId)
            .collection('students')
            .doc(student.uniqueId);

        // If there's a local image that needs syncing
        if (student.imagePath != null && student.imageSyncStatus == 0) {
          final imageBytes = await ImageHandler.getImageBytes(student.imagePath!);
          if (imageBytes != null) {
            final base64Image = await ImageHandler.convertImageToBase64(student.imagePath!);
            if (base64Image != null) {
              final updatedStudent = student.toMap();
              updatedStudent['stdImg'] = base64Image;
              await docRef.set(updatedStudent);

              // Update sync status for image
              await StudentDatabase.updateImageSyncStatus(student.id!, 1);
            }
          }
        } else {
          await docRef.set(student.toMap());
        }

        // Update sync status
        await StudentDatabase.updateSyncStatus(student.id!, 1);
      } catch (e) {
        print('Error syncing student ${student.stdName}: $e');
      }
    }

    _loadStudents();
  }

  // ============= FILTERING & SEARCHING =============
  void _applyFilters() {
    setState(() {
      _filteredStudents = _students.where((student) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            student.stdName!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            student.stdId!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            student.stdPhone!.contains(_searchQuery);

        // Tab filter
        final matchesTab = _selectedFilter == 'All' ||
            (_selectedFilter == 'Active' && student.aStatus == 1) ||
            (_selectedFilter == 'Inactive' && student.aStatus == 0);

        return matchesSearch && matchesTab;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  // ============= CRUD OPERATIONS =============
  Future<void> _addOrUpdateStudent(Student? student) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentFormScreen(
          student: student,
          schoolId: widget.schoolId,
          isOnline: _isOnline,
        ),
      ),
    );

    if (result != null && result is Student) {
      if (student == null) {
        await _createStudent(result);
      } else {
        await _updateStudent(result);
      }
    }
  }

  Future<void> _createStudent(Student student) async {
    try {
      student.addDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      student.uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      student.syncStatus = _isOnline ? 1 : 0;

      // Save to local database
      await StudentDatabase.insertStudent(student.toMap());

      // Save to Firebase if online
      if (_isOnline) {
        await _firestore
            .collection('courses')
            .doc(widget.schoolId)
            .collection('students')
            .doc(student.uniqueId)
            .set(student.toMap());
      }

      _showSuccessSnackBar('Student added successfully');
      _loadStudents();
    } catch (e) {
      _showErrorSnackBar('Error adding student: $e');
    }
  }

  Future<void> _updateStudent(Student student) async {
    try {
      student.syncStatus = _isOnline ? 1 : 0;

      // Update local database
      await StudentDatabase.updateStudent(student.id!, student.toMap());

      // Update Firebase if online
      if (_isOnline) {
        await _firestore
            .collection('courses')
            .doc(widget.schoolId)
            .collection('students')
            .doc(student.uniqueId)
            .update(student.toMap());
      }

      _showSuccessSnackBar('Student updated successfully');
      _loadStudents();
    } catch (e) {
      _showErrorSnackBar('Error updating student: $e');
    }
  }

  Future<void> _deleteStudent(Student student) async {
    final confirmed = await _showConfirmDialog(
      'Delete Student',
      'Are you sure you want to delete ${student.stdName}?',
    );

    if (confirmed != true) return;

    try {
      // Delete local image if exists
      if (student.imagePath != null) {
        final imageFile = File(student.imagePath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      // Delete from local database
      await StudentDatabase.deleteStudent(student.id!);

      // Delete from Firebase if online
      if (_isOnline) {
        await _firestore
            .collection('courses')
            .doc(widget.schoolId)
            .collection('students')
            .doc(student.uniqueId)
            .delete();
      }

      _showSuccessSnackBar('Student deleted successfully');
      _loadStudents();
    } catch (e) {
      _showErrorSnackBar('Error deleting student: $e');
    }
  }

  // ============= UI HELPERS =============
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentImage(Student student) {
    if (student.stdImg != null && student.stdImg!.startsWith('http')) {
      // Network image
      return CachedNetworkImage(
        imageUrl: student.stdImg!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildAvatarFallback(student),
        errorWidget: (context, url, error) => _buildAvatarFallback(student),
      );
    } else if (student.imagePath != null) {
      // Local image
      return Image.file(
        File(student.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(student),
      );
    } else {
      // Fallback
      return _buildAvatarFallback(student);
    }
  }

  Widget _buildAvatarFallback(Student student) {
    return Center(
      child: Text(
        student.stdName != null && student.stdName!.isNotEmpty
            ? student.stdName![0].toUpperCase()
            : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============= UI BUILD =============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryColor.withOpacity(0.1),
              _secondaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildTabBar(),
              _buildConnectionStatus(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingIndicator()
                    : _filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : _buildStudentsList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _secondaryColor],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Students Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_filteredStudents.length} Students',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.sync, color: Colors.white),
                onPressed: _isOnline ? _syncWithFirebase : null,
                tooltip: 'Sync with server',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search by name, ID, or phone...',
            prefixIcon: Icon(Icons.search, color: _primaryColor),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _secondaryColor],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
        onTap: (index) {
          setState(() {
            _selectedFilter = ['All', 'Active', 'Inactive'][index];
            _applyFilters();
          });
        },
        tabs: [
          Tab(text: 'All (${_students.length})'),
          Tab(
              text:
              'Active (${_students.where((s) => s.aStatus == 1).length})'),
          Tab(
              text:
              'Inactive (${_students.where((s) => s.aStatus == 0).length})'),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    if (_isOnline) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _warningColor),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: _warningColor),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Working offline. Changes will sync when connected.',
              style: TextStyle(color: _warningColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(_primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Loading students...',
            style: TextStyle(color: Colors.grey),
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
          Icon(Icons.school_outlined, size: 100, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'No students found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to add your first student',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return RefreshIndicator(
      onRefresh: _loadStudents,
      color: _primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredStudents.length,
        itemBuilder: (context, index) {
          final student = _filteredStudents[index];
          return _buildStudentCard(student);
        },
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStudentDetails(student),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Hero(
                  tag: 'student_${student.id}',
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [_primaryColor, _secondaryColor],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildStudentImage(student),
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.stdName ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.badge, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            student.stdId ?? 'N/A',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            student.stdPhone ?? 'N/A',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusChip(student),
                          if (student.syncStatus == 0) ...[
                            SizedBox(width: 8),
                            _buildSyncChip(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _addOrUpdateStudent(student);
                        break;
                      case 'delete':
                        _deleteStudent(student);
                        break;
                      case 'view':
                        _showStudentDetails(student);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: _primaryColor),
                          SizedBox(width: 12),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: _successColor),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: _errorColor),
                          SizedBox(width: 12),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Student student) {
    final isActive = student.aStatus == 1;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? _successColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? _successColor : Colors.grey,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? _successColor : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: isActive ? _successColor : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _warningColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync, size: 12, color: _warningColor),
          SizedBox(width: 4),
          Text(
            'Pending',
            style: TextStyle(
              color: _warningColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _addOrUpdateStudent(null),
      backgroundColor: _primaryColor,
      icon: Icon(Icons.add),
      label: Text('Add Student'),
      elevation: 8,
    );
  }

  void _showStudentDetails(Student student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StudentDetailsSheet(
        student: student,
        primaryColor: _primaryColor,
        secondaryColor: _secondaryColor,
        onEdit: () {
          Navigator.pop(context);
          _addOrUpdateStudent(student);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteStudent(student);
        },
      ),
    );
  }
}

// ============= STUDENT DETAILS SHEET =============
class StudentDetailsSheet extends StatelessWidget {
  final Student student;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StudentDetailsSheet({
    Key? key,
    required this.student,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  Widget _buildStudentImage() {
    if (student.stdImg != null && student.stdImg!.startsWith('http')) {
      // Network image
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: student.stdImg!,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
          placeholder: (context, url) => Container(
            width: 100,
            height: 100,
            color: Colors.grey[200],
            child: Icon(Icons.person, size: 40, color: Colors.grey),
          ),
          errorWidget: (context, url, error) => Container(
            width: 100,
            height: 100,
            color: Colors.grey[200],
            child: Icon(Icons.error, size: 40, color: Colors.grey),
          ),
        ),
      );
    } else if (student.imagePath != null) {
      // Local image
      return ClipOval(
        child: Image.file(
          File(student.imagePath!),
          fit: BoxFit.cover,
          width: 100,
          height: 100,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 100,
            height: 100,
            color: Colors.grey[200],
            child: Icon(Icons.person, size: 40, color: Colors.grey),
          ),
        ),
      );
    } else {
      // Fallback
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Icon(Icons.person, size: 40, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: _buildStudentImage(),
                    ),
                    SizedBox(height: 16),
                    Text(
                      student.stdName ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      student.stdId ?? 'N/A',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(20),
                  children: [
                    _buildDetailSection('Personal Information', [
                      _buildDetailItem(Icons.person, 'Full Name',
                          student.stdName ?? 'N/A'),
                      _buildDetailItem(
                          Icons.wc, 'Gender', student.gender ?? 'N/A'),
                      _buildDetailItem(Icons.cake, 'Date of Birth',
                          student.dob ?? 'N/A'),
                      _buildDetailItem(Icons.email, 'Email',
                          student.stdEmail ?? 'N/A'),
                      _buildDetailItem(
                          Icons.phone, 'Phone', student.stdPhone ?? 'N/A'),
                      _buildDetailItem(Icons.home, 'Address',
                          student.address ?? 'N/A'),
                    ]),
                    SizedBox(height: 20),
                    _buildDetailSection('Academic Information', [
                      _buildDetailItem(
                          Icons.school, 'Major', student.major ?? 'N/A'),
                      _buildDetailItem(Icons.calendar_today, 'Admission Date',
                          student.addDate ?? 'N/A'),
                    ]),
                    SizedBox(height: 20),
                    _buildDetailSection('Guardian Information', [
                      _buildDetailItem(Icons.man, 'Father Name',
                          student.fatherName ?? 'N/A'),
                      _buildDetailItem(Icons.woman, 'Mother Name',
                          student.motherName ?? 'N/A'),
                      _buildDetailItem(Icons.phone, 'Guardian Phone',
                          student.gPhone ?? 'N/A'),
                      _buildDetailItem(Icons.email, 'Guardian Email',
                          student.gEmail ?? 'N/A'),
                    ]),
                    SizedBox(height: 80),
                  ],
                ),
              ),

              // Action Buttons
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: Icon(Icons.delete),
                        label: Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: Icon(Icons.edit),
                        label: Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============= STUDENT FORM SCREEN =============
class StudentFormScreen extends StatefulWidget {
  final Student? student;
  final String schoolId;
  final bool isOnline;

  const StudentFormScreen({
    Key? key,
    this.student,
    required this.schoolId,
    required this.isOnline,
  }) : super(key: key);

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Student _student;
  File? _imageFile;
  bool _isLoading = false;
  final Color _primaryColor = const Color(0xFF667eea);
  final Color _secondaryColor = const Color(0xFF764ba2);

  @override
  void initState() {
    super.initState();
    _student = widget.student ?? Student();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      // Save image locally if picked
      if (_imageFile != null) {
        final studentId = _student.stdId ?? DateTime.now().millisecondsSinceEpoch.toString();
        final imagePath = await ImageHandler.saveImageLocally(_imageFile!, studentId);
        _student.imagePath = imagePath;
        _student.imageSyncStatus = widget.isOnline ? 1 : 0;

        // Convert to base64 for Firebase if online
        if (widget.isOnline) {
          final base64Image = await ImageHandler.convertImageToBase64(imagePath);
          if (base64Image != null) {
            _student.stdImg = base64Image;
          }
        }
      }

      Navigator.pop(context, _student);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving student: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImageWidget() {
    if (_imageFile != null) {
      return ClipOval(
        child: Image.file(
          _imageFile!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        ),
      );
    } else if (_student.stdImg != null && _student.stdImg!.isNotEmpty) {
      if (_student.stdImg!.startsWith('http')) {
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: _student.stdImg!,
            fit: BoxFit.cover,
            width: 120,
            height: 120,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.person, size: 40, color: Colors.grey),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.error, size: 40, color: Colors.grey),
            ),
          ),
        );
      } else {
        // Base64 image from Firebase
        return Container(
          color: Colors.grey[200],
          child: Icon(Icons.person, size: 40, color: Colors.grey),
        );
      }
    } else if (_student.imagePath != null) {
      return ClipOval(
        child: Image.file(
          File(_student.imagePath!),
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[200],
            child: Icon(Icons.person, size: 40, color: Colors.grey),
          ),
        ),
      );
    } else {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Icon(Icons.camera_alt, color: Colors.white, size: 40),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryColor.withOpacity(0.1),
              _secondaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.all(20),
                    children: [
                      _buildImagePicker(),
                      SizedBox(height: 24),
                      _buildSection('Personal Information', [
                        _buildTextField(
                          label: 'Full Name *',
                          icon: Icons.person,
                          initialValue: _student.stdName,
                          onSaved: (value) => _student.stdName = value,
                          validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                        ),
                        _buildTextField(
                          label: 'Student ID *',
                          icon: Icons.badge,
                          initialValue: _student.stdId,
                          onSaved: (value) => _student.stdId = value,
                          validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                        ),
                        _buildDropdown(
                          label: 'Gender *',
                          icon: Icons.wc,
                          value: _student.gender,
                          items: ['Male', 'Female', 'Other'],
                          onChanged: (value) => _student.gender = value,
                        ),
                        _buildTextField(
                          label: 'Date of Birth',
                          icon: Icons.cake,
                          initialValue: _student.dob,
                          onSaved: (value) => _student.dob = value,
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _student.dob =
                                    DateFormat('yyyy-MM-dd').format(date);
                              });
                            }
                          },
                        ),
                        _buildTextField(
                          label: 'Email',
                          icon: Icons.email,
                          initialValue: _student.stdEmail,
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (value) => _student.stdEmail = value,
                        ),
                        _buildTextField(
                          label: 'Phone *',
                          icon: Icons.phone,
                          initialValue: _student.stdPhone,
                          keyboardType: TextInputType.phone,
                          onSaved: (value) => _student.stdPhone = value,
                          validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
                        ),
                        _buildTextField(
                          label: 'Address',
                          icon: Icons.home,
                          initialValue: _student.address,
                          maxLines: 3,
                          onSaved: (value) => _student.address = value,
                        ),
                      ]),
                      SizedBox(height: 24),
                      _buildSection('Academic Information', [
                        _buildTextField(
                          label: 'Major/Class',
                          icon: Icons.school,
                          initialValue: _student.major,
                          onSaved: (value) => _student.major = value,
                        ),
                        _buildDropdown(
                          label: 'Status',
                          icon: Icons.check_circle,
                          value: _student.aStatus == 1 ? 'Active' : 'Inactive',
                          items: ['Active', 'Inactive'],
                          onChanged: (value) =>
                          _student.aStatus = value == 'Active' ? 1 : 0,
                        ),
                      ]),
                      SizedBox(height: 24),
                      _buildSection('Guardian Information', [
                        _buildTextField(
                          label: 'Father Name',
                          icon: Icons.man,
                          initialValue: _student.fatherName,
                          onSaved: (value) => _student.fatherName = value,
                        ),
                        _buildTextField(
                          label: 'Mother Name',
                          icon: Icons.woman,
                          initialValue: _student.motherName,
                          onSaved: (value) => _student.motherName = value,
                        ),
                        _buildTextField(
                          label: 'Guardian Phone',
                          icon: Icons.phone,
                          initialValue: _student.gPhone,
                          keyboardType: TextInputType.phone,
                          onSaved: (value) => _student.gPhone = value,
                        ),
                        _buildTextField(
                          label: 'Guardian Email',
                          icon: Icons.email,
                          initialValue: _student.gEmail,
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (value) => _student.gEmail = value,
                        ),
                      ]),
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _secondaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.student == null ? 'Add Student' : 'Edit Student',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [_primaryColor, _secondaryColor],
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipOval(
                  child: Container(
                    color: Colors.white.withOpacity(0.1),
                    child: _buildImageWidget(),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: _primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    String? initialValue,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primaryColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
        ),
        onSaved: onSaved,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primaryColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveStudent,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: _isLoading
              ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
              : Text(
            widget.student == null ? 'Add Student' : 'Update Student',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}