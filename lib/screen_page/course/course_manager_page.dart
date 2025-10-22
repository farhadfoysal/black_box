import 'package:black_box/model/course/materials_model.dart';
import 'package:black_box/model/course/course_model.dart';
import 'package:black_box/model/course/section_model.dart';
import 'package:black_box/model/course/tools_model.dart';
import 'package:black_box/screen_page/course/detail_course_screen.dart';
import 'package:black_box/screen_page/course/omr_fv/screens/home_screen.dart';
import 'package:black_box/screen_page/course/omr_v3/omr_config_page.dart';
import 'package:black_box/screen_page/course/screen/course_omr_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../model/course/teacher.dart';
import '../../model/school/school.dart';
import '../../model/user/user.dart';
import 'omr_fv/utils/omr_generator_fv.dart';
import 'omr_v1/omr_home_page.dart';
import 'omr_v2/omr_dashboard.dart';
// import 'omr_v3/omr_v4.dart';

class CourseManagerScreen extends StatefulWidget {
  final CourseModel course;
  final User user;
  const CourseManagerScreen(
      {Key? key, required this.course, required this.user})
      : super(key: key);

  @override
  State<CourseManagerScreen> createState() => _CourseManagerScreenState();
}

class _CourseManagerScreenState extends State<CourseManagerScreen> {
  String? userName;
  String? userPhone;
  String? userEmail;
  User? _user, _user_data;
  String? sid;
  School? school;
  Teacher? teacher;
  bool isLoading = false;

  late CourseModel _editedCourse;
  bool _isEditing = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  String? selectedLanguage = 'Bangla';
  List<String> languages = ['English', 'Bangla', 'Math'];

  @override
  void initState() {
    super.initState();

    // print("User Type ${widget.user.utype}");

    _editedCourse = CourseModel.fromJson(widget.course.toJson());
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _editedCourse = CourseModel.fromJson(widget.course.toJson());
      }
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await Future.delayed(const Duration(seconds: 1));

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course updated successfully!')));

        setState(() => _isEditing = false);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving changes: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Course' : 'Course Manager'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SAVE', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              const SizedBox(height: 24),
              _buildSectionHeader('Basic Information'),
              _buildTextField(
                label: 'Course Name',
                initialValue: _editedCourse.courseName ?? '',
                enabled: _isEditing,
                onChanged: (value) => _editedCourse.courseName = value ?? '',
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              _buildTextField(
                label: 'Description',
                initialValue: _editedCourse.description ?? '',
                enabled: _isEditing,
                maxLines: 4,
                onChanged: (value) => _editedCourse.description = value ?? '',
              ),
              _buildDropdownField(
                label: 'Category',
                value: _editedCourse.category,
                items: const ['Programming', 'Design', 'Business', 'Science'],
                enabled: _isEditing,
                onChanged: (value) => _editedCourse.category = value ?? '',
              ),
              _buildDropdownField(
                label: 'Level',
                value: _editedCourse.level,
                items: const ['Beginner', 'Intermediate', 'Advanced'],
                enabled: _isEditing,
                onChanged: (value) => _editedCourse.level = value ?? '',
              ),
              _buildTextField(
                label: 'Total Videos',
                initialValue: _editedCourse.totalVideo?.toString() ?? '0',
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _editedCourse.totalVideo = int.tryParse(value ?? '0') ?? 0,
              ),
              _buildTextField(
                label: 'Total Time',
                initialValue: _editedCourse.totalTime ?? '',
                enabled: _isEditing,
                onChanged: (value) => _editedCourse.totalTime = value ?? '',
              ),
              _buildTextField(
                label: 'Course Fee',
                initialValue: _editedCourse.fee?.toString() ?? '0',
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _editedCourse.fee = double.tryParse(value ?? '0') ?? 0.0,
              ),
              _buildTextField(
                label: 'Discount (%)',
                initialValue: _editedCourse.discount?.toString() ?? '0',
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                onChanged: (value) => _editedCourse.discount =
                    double.tryParse(value ?? '0') ?? 0.0,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Course Content'),
              _buildMaterialsList(),
              if (_isEditing)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _showAddSectionDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Section'),
                  ),
                ),
              const SizedBox(height: 24),
              _buildSectionHeader('Tools & Resources'),
              _buildToolsList(),
              if (_isEditing)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _showAddToolDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Tool'),
                  ),
                ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  childAspectRatio: 0.75,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _buildMenuItem(Icons.bus_alert_outlined, 'Bus',
                        () => _navigateToPage(context, 'bus')),
                    _buildMenuItem(Icons.event_busy, 'Absences',
                        () => _navigateToPage(context, 'absence')),
                    _buildMenuItem(Icons.calculate, 'Calculation',
                        () => _navigateToPage(context, 'calculation')),
                    _buildMenuItem(Icons.qr_code_scanner, 'Scanner',
                        () => _navigateToPage(context, 'scanner')),
                    _buildMenuItem(Icons.schedule, 'Timetable',
                        () => _navigateToPage(context, 'time')),
                    _buildMenuItem(Icons.event_note, 'Schedule',
                        () => _navigateToPage(context, 'schedules'),
                        hasNotification: true, notificationCount: 3),
                    _buildMenuItem(Icons.note, 'Notes',
                        () => _navigateToPage(context, 'notes')),
                    _buildMenuItem(Icons.person_search_outlined, 'Students',
                        () => _navigateToPage(context, 'students')),
                    _buildMenuItem(Icons.people, 'Teachers',
                        () => _navigateToPage(context, 'faculty')),
                    _buildMenuItem(Icons.school_outlined, 'Exams',
                        () => _navigateToPage(context, 'exams')),
                    _buildMenuItem(Icons.punch_clock_outlined, 'Routines',
                        () => _navigateToPage(context, 'routines')),
                    _buildMenuItem(Icons.book, 'Subjects',
                        () => _navigateToPage(context, 'courses')),
                    _buildMenuItem(Icons.room_outlined, 'Rooms',
                        () => _navigateToPage(context, 'rooms')),
                    _buildMenuItem(Icons.segment_outlined, 'Sessions',
                        () => _navigateToPage(context, 'sessions')),
                    _buildMenuItem(Icons.apartment_outlined, 'Departments',
                        () => _navigateToPage(context, 'departments')),
                    _buildMenuItem(Icons.category_outlined, 'Programs',
                        () => _navigateToPage(context, 'programs')),
                    _buildMenuItem(Icons.bar_chart, 'Statistics',
                        () => _navigateToPage(context, 'StatisticsPage')),
                  ],
                ),
              ),

              // Today's Summary Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Setup and Customize Your School",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              ListView(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: [
                  _buildSummaryCard(
                      Icons.schedule,
                      'Timetable',
                      'There is no classes',
                      'You don\'t have classes timetable to attend today.',
                      () => _navigateToPage(context, 'TimetableSummaryPage')),
                  _buildSummaryCard(
                      Icons.book,
                      'Homework',
                      'No homework',
                      'Today you have no scheduled tasks to present.',
                      () => _navigateToPage(context, 'HomeworkPage')),
                  _buildSummaryCard(
                      Icons.school,
                      'Exams',
                      'No exams',
                      'You don\'t have scheduled exams today.',
                      () => _navigateToPage(context, 'ExamsPage')),
                  _buildSummaryCard(Icons.event, 'Events', 'Cse', 'FgF',
                      () => _navigateToPage(context, 'EventsPage')),
                  _buildSummaryCard(
                      Icons.book,
                      'Books',
                      'There are no books',
                      'Today you have no borrowed books to return.',
                      () => _navigateToPage(context, 'BooksPage')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build menu item with navigation
  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {bool hasNotification = false, int notificationCount = 0}) {
    return InkWell(
      onTap: onTap, // This will handle navigation when tapped
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue[50],
                child: Icon(icon, color: Colors.blue, size: 30),
              ),
              SizedBox(height: 8),
              Text(title, style: TextStyle(fontSize: 12)),
            ],
          ),
          if (hasNotification)
            Positioned(
              right: 0,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text(
                  notificationCount.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to build summary card with navigation
  Widget _buildSummaryCard(IconData icon, String title, String subtitle,
      String description, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        child: ListTile(
          onTap: onTap,
          // This will handle navigation when tapped
          leading: CircleAvatar(
            backgroundColor: Colors.blue[50],
            child: Icon(icon, color: Colors.blue),
          ),
          title: Text(title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(subtitle),
              SizedBox(height: 4),
              Text(description,
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          trailing: Icon(Icons.arrow_forward),
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, String pageName) {
    if (pageName == 'programs') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailCourseScreen(course: widget.course)));
    } else if (pageName == 'students') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailCourseScreen(course: widget.course)));
    } else if (pageName == 'departments') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailCourseScreen(course: widget.course)));
    } else if (pageName == 'scanner') {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
          // context, MaterialPageRoute(builder: (context) => OMRDashboard()));
          // context, MaterialPageRoute(builder: (context) => ProfessionalOMRGeneratorExample())); // completed
          // context, MaterialPageRoute(builder: (context) => OMRConfigPage()));
          // context, MaterialPageRoute(builder: (context) => OMRHomePage()));
          // context, MaterialPageRoute(builder: (context) => CourseOmrPage()));
    } else if (pageName == 'rooms') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailCourseScreen(course: widget.course)));
    } else if (pageName == 'courses') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailCourseScreen(course: widget.course)));
    } else if (pageName == 'routines') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailCourseScreen(course: widget.course)));
    } else if (pageName == 'faculty') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailCourseScreen(course: widget.course)));
    } else if (pageName == 'exams') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailCourseScreen(course: widget.course)));
    } else if (pageName == 'bus') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailCourseScreen(course: widget.course)));
    } else if (pageName == 'ExamsPage') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailCourseScreen(course: widget.course)));
    } else {}
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) {
    //     // Placeholder for different pages, replace with actual page widgets
    //     return Scaffold(
    //       appBar: AppBar(title: Text(pageName)),
    //       body: Center(child: Text('This is the $pageName page')),
    //     );
    //   }),
    // );
  }

// The helper methods like _buildImageSection, _buildTextField, etc., should remain unchanged unless specific errors occur.
// If needed, I can help audit and correct each of those too.

// ... (Keep all the existing helper methods until _showAddMaterialDialog)

  void _showAddMaterialDialog(Section section) {
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Material'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Material Name',
                    hintText: 'e.g. Introduction Video'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Material Type',
                ),
                items: const [
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                  DropdownMenuItem(value: 'document', child: Text('Document')),
                  DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                  DropdownMenuItem(value: 'link', child: Text('Link')),
                ],
                onChanged: (value) => typeController.text = value ?? '',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                    labelText: 'URL/Path', hintText: 'Enter resource location'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  typeController.text.isNotEmpty) {
                setState(() {
                  section.materials ??= [];
                  section.materials!.add(Materials(
                    materialName: nameController.text,
                    materialType: typeController.text,
                    url: urlController.text.isNotEmpty
                        ? urlController.text
                        : null,
                    id: section.materials?.length ?? 0, // Temporary ID
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddToolDialog() {
    final nameController = TextEditingController();
    final iconController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Tool'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Tool Name',
                    hintText: 'e.g. Visual Studio Code'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(
                    labelText: 'Icon URL',
                    hintText: 'Enter image URL for icon'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                    labelText: 'Tool URL',
                    hintText: 'Enter tool website/download link'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _editedCourse.tools ??= [];
                  _editedCourse.tools!.add(Tools(
                    toolsName: nameController.text,
                    toolsIcon: iconController.text.isNotEmpty
                        ? iconController.text
                        : null,
                    url: urlController.text.isNotEmpty
                        ? urlController.text
                        : null,
                    id: _editedCourse.tools?.length ?? 0, // Temporary ID
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

// ... (Keep the remaining existing methods)
  Widget _buildImageSection() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
            image: _editedCourse.courseImage != null
                ? DecorationImage(
                    image: NetworkImage(_editedCourse.courseImage!),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Optional: fallback on error
                    },
                  )
                : null,
          ),
          child: _editedCourse.courseImage == null
              ? const Center(
                  child: Icon(Icons.image, size: 60, color: Colors.grey),
                )
              : null,
        ),
        if (_isEditing)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton.small(
              onPressed: _showImagePickerDialog,
              child: const Icon(Icons.edit),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required bool enabled,
    ValueChanged<String?>? onChanged,
    FormFieldValidator<String>? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          enabled: enabled,
        ),
        initialValue: initialValue,
        onChanged: onChanged,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    // Ensure value is valid (i.e., included exactly once in items list)
    String? validatedValue =
        (value != null && items.contains(value)) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        value: validatedValue,
        items: items.toSet().map((String val) {
          return DropdownMenuItem<String>(
            value: val,
            child: Text(val),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildMaterialsList() {
    if (_editedCourse.sections?.isEmpty ?? true) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child:
            Text('No sections added yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: _editedCourse.sections!.map((section) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(section.sectionName ?? 'Untitled Section'),
            subtitle: Text('${section.materials?.length ?? 0} materials'),
            children: [
              if (section.materials?.isNotEmpty ?? false)
                ...section.materials!.map((material) => ListTile(
                      leading: Icon(_getMaterialIcon(material.materialType)),
                      title: Text(material.materialName ?? ''),
                      subtitle: Text(material.materialType ?? ''),
                      trailing: _isEditing
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeMaterial(
                                  section, material as Material),
                            )
                          : null,
                    )),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddMaterialDialog(section),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Material'),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToolsList() {
    if (_editedCourse.tools?.isEmpty ?? true) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No tools added yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _editedCourse.tools!
          .map((tool) => Chip(
                label: Text(tool.toolsName ?? ''),
                avatar: tool.toolsIcon != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(tool.toolsIcon!))
                    : null,
                deleteIcon: _isEditing ? const Icon(Icons.close) : null,
                onDeleted: _isEditing ? () => _removeTool(tool) : null,
              ))
          .toList(),
    );
  }

  IconData _getMaterialIcon(String? type) {
    switch (type) {
      case 'video':
        return Icons.video_library;
      case 'document':
        return Icons.insert_drive_file;
      case 'quiz':
        return Icons.quiz;
      case 'link':
        return Icons.link;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Course Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                // TODO: Implement image picker
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                // TODO: Implement camera
                Navigator.pop(context);
              },
            ),
            if (_editedCourse.courseImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Image',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() => _editedCourse.courseImage = null);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddSectionDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Section'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
              labelText: 'Section Name',
              hintText: 'e.g. Introduction to Programming'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _editedCourse.sections ??= [];
                  _editedCourse.sections!.add(Section(
                    sectionName: controller.text,
                    materials: [],
                    id: 0,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeMaterial(Section section, Material material) {
    setState(() {
      section.materials?.remove(material);
    });
  }

  void _removeTool(Tools tool) {
    setState(() {
      _editedCourse.tools?.remove(tool);
    });
  }
}
