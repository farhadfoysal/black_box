import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:black_box/model/exam/exam_model.dart';
import 'package:black_box/model/exam/question_model.dart';
import '../../services/exam/exam_service.dart';
import 'exam_details.dart';

// The main Exam List Page.
class ExamListPage extends StatefulWidget {
  const ExamListPage({Key? key}) : super(key: key);

  @override
  _ExamListPageState createState() => _ExamListPageState();
}

class _ExamListPageState extends State<ExamListPage> {
  late Future<List<ExamModel>> _examsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Listen to search query changes.
    _searchController.addListener(_onSearchChanged);
    // Initialize future by fetching exams.
    _examsFuture = _fetchExams();
    // Optionally trigger a load in your ExamService if needed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExamService>(context, listen: false).loadExams();
    });

  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Called every time the search field updates.
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  // Filters exams based on the search query.
  List<ExamModel> _filterExams(List<ExamModel> exams) {
    if (_searchQuery.isEmpty) return exams;
    return exams.where((exam) {
      return exam.title.toLowerCase().contains(_searchQuery) ||
          exam.description.toLowerCase().contains(_searchQuery) ||
          exam.examType.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  // Display error messages via a Snackbar.
  void _showErrorSnackbar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }

  // Fetch exams from the provider.
  Future<List<ExamModel>> _fetchExams() async {
    try {
      final examService = Provider.of<ExamService>(context, listen: false);
      // return await examService.getAllExams();
      return await examService.getUserExams();
    } catch (e) {
      _showErrorSnackbar('Error loading exams: ${e.toString()}');
      return [];
    }
  }

  // Refresh exams by re-fetching.
  Future<void> _refreshExams() async {
    setState(() {
      _examsFuture = _fetchExams();
    });
  }

  // Navigate to the exam start page.
  void _navigateToExamStart(ExamModel exam) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExamStartPage(exam: exam)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Exams',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3A7BD5), Color(0xFF00D2FF)],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search field.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exams...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          // List of exams loaded with FutureBuilder.
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshExams,
              child: FutureBuilder<List<ExamModel>>(
                future: _examsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No exams available'));
                  }

                  final filteredExams = _filterExams(snapshot.data!);
                  if (filteredExams.isEmpty) {
                    return const Center(
                        child: Text('No matching exams found'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredExams.length,
                    itemBuilder: (context, index) =>
                        _buildExamCard(filteredExams[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateExamDialog,
        backgroundColor: const Color(0xFF3A7BD5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Builds each exam card.
  // Widget _buildExamCard(ExamModel exam) {
  //   return Card(
  //     elevation: 4,
  //     margin: const EdgeInsets.only(bottom: 16),
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: InkWell(
  //       borderRadius: BorderRadius.circular(12),
  //       onTap: () => _showExamDetails(exam),
  //       onLongPress: () => _showExamOptions(exam),
  //       child: Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // Title and status.
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Expanded(
  //                   child: Text(
  //                     exam.title,
  //                     style: const TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.bold,
  //                         color: Color(0xFF2C3E50)),
  //                   ),
  //                 ),
  //                 Container(
  //                   padding: const EdgeInsets.symmetric(
  //                       horizontal: 8, vertical: 4),
  //                   decoration: BoxDecoration(
  //                     color: _getStatusColor(exam.status),
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                   child: Text(
  //                     exam.status == 1 ? 'Active' : 'Inactive',
  //                     style:
  //                     const TextStyle(color: Colors.white, fontSize: 12),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 8),
  //             // Description.
  //             Text(exam.description,
  //                 style:
  //                 TextStyle(fontSize: 14, color: Colors.grey[600])),
  //             const SizedBox(height: 12),
  //             // Type and duration row.
  //             Row(
  //               children: [
  //                 Icon(_getExamTypeIcon(exam.examType),
  //                     size: 16, color: const Color(0xFF3A7BD5)),
  //                 const SizedBox(width: 4),
  //                 Text(_formatExamType(exam.examType),
  //                     style: TextStyle(
  //                         fontSize: 13, color: Colors.grey[700])),
  //                 const Spacer(),
  //                 Icon(Icons.timer_outlined,
  //                     size: 16, color: Colors.grey[600]),
  //                 const SizedBox(width: 4),
  //                 Text('${exam.durationMinutes} min',
  //                     style: TextStyle(
  //                         fontSize: 13, color: Colors.grey[700])),
  //               ],
  //             ),
  //             const SizedBox(height: 12),
  //             // Created date and exam actions.
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Text('Created: ${_formatDate(exam.createdAt)}',
  //                     style: TextStyle(
  //                         fontSize: 12, color: Colors.grey[500])),
  //                 Row(
  //                   children: [
  //                     TextButton(
  //                       onPressed: () => _navigateToExamStart(exam),
  //                       style: TextButton.styleFrom(
  //                         padding: EdgeInsets.zero,
  //                         minimumSize: const Size(50, 30),
  //                         tapTargetSize:
  //                         MaterialTapTargetSize.shrinkWrap,
  //                       ),
  //                       child: const Text('START',
  //                           style: TextStyle(
  //                               color: Color(0xFF3A7BD5),
  //                               fontWeight: FontWeight.bold)),
  //                     ),
  //                     IconButton(
  //                       icon: const Icon(Icons.more_vert, size: 20),
  //                       onPressed: () => _showExamOptions(exam),
  //                       color: Colors.grey[600],
  //                       padding: EdgeInsets.zero,
  //                       constraints: const BoxConstraints(),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildExamCard(ExamModel exam) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showExamDetails(exam),
        onLongPress: () => _showExamOptions(exam),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      exam.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(exam.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      exam.status == 1 ? 'Active' : 'Inactive',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(exam.description, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(_getExamTypeIcon(exam.examType), size: 16, color: const Color(0xFF3A7BD5)),
                  const SizedBox(width: 4),
                  Text(_formatExamType(exam.examType), style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  const Spacer(),
                  Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${exam.durationMinutes} min', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Created: ${_formatDate(exam.createdAt)}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _navigateToExamStart(exam),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('START', style: TextStyle(color: Color(0xFF3A7BD5), fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onPressed: () => _showExamOptions(exam),
                        color: Colors.grey[600],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  // Returns the color for exam status.
  Color _getStatusColor(int status) =>
      status == 1 ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

  // Returns the icon for exam type.
  IconData _getExamTypeIcon(String type) {
    switch (type) {
      case 'written':
        return Icons.edit;
      case 'quiz':
        return Icons.quiz;
      case 'image':
        return Icons.image;
      case 'edpuzzle':
        return Icons.video_library;
      default:
        return Icons.help_outline;
    }
  }

  // Formats exam type to a readable string.
  String _formatExamType(String type) {
    switch (type) {
      case 'written':
        return 'Written Exam';
      case 'quiz':
        return 'Quiz';
      case 'image':
        return 'Image Exam';
      case 'edpuzzle':
        return 'Video Exam';
      default:
        return 'Exam';
    }
  }

  // Formats a date string (expects a valid ISO date).
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Displays bottom sheet options for an exam.
  void _showExamOptions(ExamModel exam) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
              const Icon(Icons.edit, color: Color(0xFF3A7BD5)),
              title: const Text('Edit Exam'),
              onTap: () {
                Navigator.pop(context);
                _showEditExamDialog(exam);
              },
            ),
            ListTile(
              leading:
              const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Exam'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(exam);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy,
                  color: Colors.green),
              title: const Text('Duplicate Exam'),
              onTap: () {
                Navigator.pop(context);
                _duplicateExam(exam);
              },
            ),
            ListTile(
              leading: Icon(
                exam.status == 1
                    ? Icons.toggle_on
                    : Icons.toggle_off,
                color: exam.status == 1 ? Colors.green : Colors.grey,
              ),
              title: Text(
                  exam.status == 1 ? 'Deactivate' : 'Activate'),
              onTap: () {
                Navigator.pop(context);
                _toggleExamStatus(exam);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Toggles the exam's active/inactive status.
  Future<void> _toggleExamStatus(ExamModel exam) async {
    try {
      final examService =
      Provider.of<ExamService>(context, listen: false);
      await examService.updateExamStatus(
          exam.uniqueId, exam.status == 1 ? 0 : 1);
      _refreshExams();
      _showErrorSnackbar(
          exam.status == 1 ? 'Exam deactivated' : 'Exam activated');
    } catch (e) {
      _showErrorSnackbar('Error updating status: ${e.toString()}');
    }
  }

  // Duplicates an exam.
  Future<void> _duplicateExam(ExamModel exam) async {
    try {
      final examService =
      Provider.of<ExamService>(context, listen: false);
      await examService.duplicateExam(exam.uniqueId);
      _refreshExams();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Exam duplicated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error duplicating exam: ${e.toString()}')),
      );
    }
  }

  // Shows a dialog to choose exam type for creating a new exam.
  void _showCreateExamDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Exam'),
        content: const Text('Select exam type to create'),
        actions: [
          TextButton(
            onPressed: () => _createExam('quiz'),
            child: const Text('Quiz'),
          ),
          TextButton(
            onPressed: () => _createExam('written'),
            child: const Text('Written'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Creates a new exam.
  void _createExam(String examType) async {
    Navigator.pop(context);
    try {
      final examService =
      Provider.of<ExamService>(context, listen: false);
      await examService.createNewExam(examType);
      _refreshExams();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('New exam created successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating exam: ${e.toString()}')),
      );
    }
  }

  // Shows a dialog for editing an exam.
  void _showEditExamDialog(ExamModel exam) {
    final titleController = TextEditingController(text: exam.title);
    final descController = TextEditingController(text: exam.description);
    final durationController =
    TextEditingController(text: exam.durationMinutes.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Exam'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                    labelText: 'Exam Title',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
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
            onPressed: () async {
              await _updateExam(
                exam,
                titleController.text,
                descController.text,
                int.tryParse(durationController.text) ?? exam.durationMinutes,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Updates an exam with new data.
  Future<void> _updateExam(ExamModel exam, String title, String description, int duration) async {
    try {
      final updatedExam = exam.copyWith(
        title: title,
        description: description,
        durationMinutes: duration,
      );
      final examService =
      Provider.of<ExamService>(context, listen: false);
      await examService.updateExam(updatedExam.examId,updatedExam);
      _refreshExams();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating exam: ${e.toString()}')),
      );
    }
  }

  // Shows a confirmation dialog for deleting an exam.
  Future<void> _showDeleteConfirmation(ExamModel exam) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: SingleChildScrollView(
          child: ListBody(children: [
            Text('Are you sure you want to delete "${exam.title}"?')
          ]),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
            onPressed: () async {
              try {
                final examService =
                Provider.of<ExamService>(context, listen: false);
                await examService.deleteExam(exam.uniqueId);
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Exam deleted successfully')));
                  _refreshExams();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting exam: ${e.toString()}')),
                  );
                }
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // Shows exam details in a modal bottom sheet.
  void _showExamDetails(ExamModel exam) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              exam.title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 8),
            Text(exam.description,
                style:
                TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.timer_outlined, 'Duration', '${exam.durationMinutes} minutes'),
            _buildDetailRow(_getExamTypeIcon(exam.examType), 'Exam Type', _formatExamType(exam.examType)),
            _buildDetailRow(Icons.calendar_today, 'Created', _formatDate(exam.createdAt)),
            _buildDetailRow(Icons.star, 'Status', exam.status == 1 ? 'Active' : 'Inactive'),
            const SizedBox(height: 24),
            if (exam.questions != null)
              Text('${exam.questions!.length} questions',
                  style:
                  TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToExamStart(exam);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A7BD5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Exam',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExamDetailsPage(exam: exam,),
                    ),
                  );
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => ExamDetailsPage(
                  //       questions: exam.questions ?? [],
                  //       examTitle: exam.title,
                  //       examDescription: exam.description,
                  //       durationMinutes: exam.durationMinutes,
                  //       examType: exam.examType,
                  //       createdAt: exam.createdAt,
                  //     ),
                  //   ),
                  // );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A7BD5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Details Exam',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(color: Color(0xFF3A7BD5))),
            ),
          ],
        ),
      ),
    );
  }

  // Builds a single detail row for the exam details view.
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF3A7BD5)),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// A simple ExamStartPage for demonstration.
class ExamStartPage extends StatelessWidget {
  final ExamModel exam;
  const ExamStartPage({Key? key, required this.exam}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exam.title),
        backgroundColor: const Color(0xFF3A7BD5),
      ),
      body: Center(
        child: Text(
          'Exam Start Page for ${exam.title}',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:black_box/model/exam/question_model.dart';
// import 'package:black_box/model/exam/exam_model.dart';
//
// class ExamListPage extends StatefulWidget {
//   const ExamListPage({Key? key}) : super(key: key);
//
//   @override
//   _ExamListPageState createState() => _ExamListPageState();
// }
//
// class _ExamListPageState extends State<ExamListPage> {
//   // Sample exam data - replace with your actual data source
//   final List<ExamModel> exams = [
//     ExamModel(
//       uniqueId: '1',
//       examId: 'math101',
//       title: 'Mathematics Final Exam',
//       description: 'Covers all topics from semester 1',
//       createdAt: '2023-05-15',
//       durationMinutes: 120,
//       status: 1,
//       examType: ExamTypes.quiz,
//       subjectId: 'math',
//       questions: [
//         QuestionModel(
//           quizId: 'math101',
//           questionTitle: 'What is 2+2?',
//           questionAnswers: ['3', '4', '5', '6'],
//           correctAnswer: '4',
//           explanation: 'Basic addition',
//           source: 'Math Basics',
//           type: 'mcq',
//           url: '',
//         ),
//       ],
//     ),
//     ExamModel(
//       uniqueId: '2',
//       examId: 'physics101',
//       title: 'Physics Midterm',
//       description: 'Mechanics and Thermodynamics',
//       createdAt: '2023-05-10',
//       durationMinutes: 90,
//       status: 1,
//       examType: ExamTypes.written,
//       subjectId: 'physics',
//     ),
//     ExamModel(
//       uniqueId: '3',
//       examId: 'chem101',
//       title: 'Chemistry Quiz',
//       description: 'Periodic table and reactions',
//       createdAt: '2023-05-05',
//       durationMinutes: 45,
//       status: 0,
//       examType: ExamTypes.quiz,
//       subjectId: 'chemistry',
//     ),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text('My Exams',
//             style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 22)),
//         centerTitle: true,
//         elevation: 0,
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Color(0xFF3A7BD5),
//                 Color(0xFF00D2FF),
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search, color: Colors.white),
//             onPressed: () {
//               // Implement search functionality
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Upcoming Exams',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF3A7BD5),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: exams.length,
//                 itemBuilder: (context, index) {
//                   final exam = exams[index];
//                   return _buildExamCard(exam);
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Add new exam functionality
//         },
//         backgroundColor: const Color(0xFF3A7BD5),
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//     );
//   }
//
//   Widget _buildExamCard(ExamModel exam) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: () {
//           // Navigate to exam details or start exam
//           _showExamDetails(exam);
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       exam.title,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF2C3E50),
//                       ),
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: _getStatusColor(exam.status),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       exam.status == 1 ? 'Active' : 'Inactive',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 exam.description,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Icon(
//                     _getExamTypeIcon(exam.examType),
//                     size: 16,
//                     color: const Color(0xFF3A7BD5),
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     _formatExamType(exam.examType),
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                   const Spacer(),
//                   Icon(
//                     Icons.timer_outlined,
//                     size: 16,
//                     color: Colors.grey[600],
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     '${exam.durationMinutes} min',
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               LinearProgressIndicator(
//                 value: 0.65, // Replace with actual progress
//                 backgroundColor: Colors.grey[200],
//                 valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D2FF)),
//                 minHeight: 6,
//                 borderRadius: BorderRadius.circular(3),
//               ),
//               const SizedBox(height: 4),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Created: ${exam.createdAt}',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[500],
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: () {
//                       // Start exam action
//                     },
//                     style: TextButton.styleFrom(
//                       padding: EdgeInsets.zero,
//                       minimumSize: const Size(50, 30),
//                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                     ),
//                     child: const Text(
//                       'START',
//                       style: TextStyle(
//                         color: Color(0xFF3A7BD5),
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Color _getStatusColor(int status) {
//     return status == 1 ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
//   }
//
//   IconData _getExamTypeIcon(String type) {
//     switch (type) {
//       case ExamTypes.written:
//         return Icons.edit;
//       case ExamTypes.quiz:
//         return Icons.quiz;
//       case ExamTypes.image:
//         return Icons.image;
//       case ExamTypes.edpuzzle:
//         return Icons.video_library;
//       default:
//         return Icons.help_outline;
//     }
//   }
//
//   String _formatExamType(String type) {
//     switch (type) {
//       case ExamTypes.written:
//         return 'Written Exam';
//       case ExamTypes.quiz:
//         return 'Quiz';
//       case ExamTypes.image:
//         return 'Image Exam';
//       case ExamTypes.edpuzzle:
//         return 'Video Exam';
//       default:
//         return 'Exam';
//     }
//   }
//
//   void _showExamDetails(ExamModel exam) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       isScrollControlled: true,
//       builder: (context) {
//         return Container(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Center(
//                 child: Container(
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 exam.title,
//                 style: const TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF2C3E50),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 exam.description,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               _buildDetailRow(Icons.timer_outlined, 'Duration',
//                   '${exam.durationMinutes} minutes'),
//               _buildDetailRow(
//                   _getExamTypeIcon(exam.examType),
//                   'Exam Type',
//                   _formatExamType(exam.examType)),
//               _buildDetailRow(Icons.calendar_today, 'Created', exam.createdAt),
//               const SizedBox(height: 24),
//               if (exam.questions != null)
//                 Text(
//                   '${exam.questions!.length} questions',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     // Start exam action
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF3A7BD5),
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const Text(
//                     'Start Exam',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 child: const Text(
//                   'Close',
//                   style: TextStyle(
//                     color: Color(0xFF3A7BD5),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildDetailRow(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           Icon(icon, size: 20, color: const Color(0xFF3A7BD5)),
//           const SizedBox(width: 12),
//           Text(
//             label,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF2C3E50),
//             ),
//           ),
//           const Spacer(),
//           Text(
//             value,
//             style: TextStyle(
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }