import 'package:black_box/screen_page/exam/attempt_exam_page.dart';
import 'package:flutter/material.dart';
import 'package:black_box/model/exam/exam_model.dart';

import '../../model/exam/question_model.dart';

class ExamDetailsPage extends StatelessWidget {
  final ExamModel exam;

  const ExamDetailsPage({Key? key, required this.exam}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Exam Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3A7BD5),
                Color(0xFF00D2FF),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(),
            SizedBox(height: 24),

            // Exam Info Cards
            _buildInfoGrid(),
            SizedBox(height: 24),

            // Description Section
            _buildDescriptionSection(),
            SizedBox(height: 24),

            // Questions Section
            if (exam.questions != null && exam.questions!.isNotEmpty)
              _buildQuestionsSection(),

            // Action Buttons
            SizedBox(height: 32),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exam.title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text(
              'Created: ${_formatDate(exam.createdAt)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.6,
      children: [
        _buildInfoCard(
          icon: Icons.timer_outlined,
          title: 'Duration',
          value: '${exam.durationMinutes} min',
          color: const Color(0xFF3A7BD5),
        ),
        _buildInfoCard(
          icon: _getExamTypeIcon(exam.examType),
          title: 'Type',
          value: _formatExamType(exam.examType),
          color: const Color(0xFF4CAF50),
        ),
        _buildInfoCard(
          icon: Icons.help_outline,
          title: 'Questions',
          value: exam.questions?.length.toString() ?? '0',
          color: const Color(0xFF9C27B0),
        ),
        _buildInfoCard(
          icon: Icons.star,
          title: 'Status',
          value: exam.status == 1 ? 'Active' : 'Inactive',
          color: exam.status == 1 ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            // Expanded will ensure that the text doesn't overflow the card width
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
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



  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        SizedBox(height: 8),
        Text(
          exam.description.isNotEmpty ? exam.description : 'No description provided',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questions (${exam.questions!.length})',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: exam.questions!.length > 5 ? 5 : exam.questions!.length,
          separatorBuilder: (context, index) => Divider(height: 16),
          itemBuilder: (context, index) {
            final question = exam.questions![index];
            return _buildQuestionItem(question, index + 1);
          },
        ),
        if (exam.questions!.length > 5)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '+ ${exam.questions!.length - 5} more questions...',
              style: TextStyle(
                color: Color(0xFF3A7BD5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionItem(QuestionModel question, int number) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color(0xFF3A7BD5).withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              color: Color(0xFF3A7BD5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.questionTitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2C3E50),
                ),
              ),
              if (question.questionAnswers != null && question.questionAnswers!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Text(
                      'Options: ${question.questionAnswers!.join(', ')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Start exam action
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttemptExamPage(exam: exam),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3A7BD5),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Start Exam',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF3A7BD5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.more_vert, color: Color(0xFF3A7BD5)),
            onPressed: () {
              _showExamOptions(context);
            },
          ),
        ),
      ],
    );
  }

  void _showExamOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Color(0xFF3A7BD5)),
                title: Text('Edit Exam'),
                onTap: () {
                  Navigator.pop(context);
                  // Edit exam action
                },
              ),
              ListTile(
                leading: Icon(Icons.content_copy, color: Colors.green),
                title: Text('Duplicate Exam'),
                onTap: () {
                  Navigator.pop(context);
                  // Duplicate exam action
                },
              ),
              ListTile(
                leading: Icon(
                  exam.status == 1 ? Icons.toggle_on : Icons.toggle_off,
                  color: exam.status == 1 ? Colors.green : Colors.grey,
                ),
                title: Text(exam.status == 1 ? 'Deactivate' : 'Activate'),
                onTap: () {
                  Navigator.pop(context);
                  // Toggle status action
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete Exam', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Exam'),
        content: Text('Are you sure you want to delete "${exam.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete exam action
              Navigator.pop(context); // Also pop the details page
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getExamTypeIcon(String type) {
    switch (type) {
      case 'written': return Icons.edit;
      case 'quiz': return Icons.quiz;
      case 'image': return Icons.image;
      case 'edpuzzle': return Icons.video_library;
      default: return Icons.help_outline;
    }
  }

  String _formatExamType(String type) {
    switch (type) {
      case 'written': return 'Written';
      case 'quiz': return 'Quiz';
      case 'image': return 'Image';
      case 'edpuzzle': return 'Video';
      default: return 'Exam';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

// Placeholder for ExamStartPage
class ExamStartPage extends StatelessWidget {
  final ExamModel exam;

  const ExamStartPage({Key? key, required this.exam}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exam.title),
      ),
      body: Center(
        child: Text('Exam Start Page for ${exam.title}'),
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:black_box/model/exam/question_model.dart';
//
// class ExamDetailsPage extends StatelessWidget {
//   final List<QuestionModel> questions;
//   final String examTitle;
//   final String examDescription;
//   final int durationMinutes;
//   final String examType;
//   final String createdAt;
//
//   const ExamDetailsPage({
//     Key? key,
//     required this.questions,
//     required this.examTitle,
//     required this.examDescription,
//     required this.durationMinutes,
//     required this.examType,
//     required this.createdAt,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text(
//           'Exam Details',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
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
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header Section
//             _buildHeaderSection(),
//             const SizedBox(height: 24),
//
//             // Exam Info Cards
//             _buildInfoGrid(),
//             const SizedBox(height: 24),
//
//             // Description Section
//             _buildDescriptionSection(),
//             const SizedBox(height: 24),
//
//             // Questions Section
//             _buildQuestionsSection(),
//
//             // Action Buttons
//             const SizedBox(height: 32),
//             _buildActionButtons(context),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeaderSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           examTitle,
//           style: const TextStyle(
//             fontSize: 28,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF2C3E50),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
//             const SizedBox(width: 4),
//             Text(
//               'Created: ${_formatDate(createdAt)}',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildInfoGrid() {
//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       childAspectRatio: 2.6,
//       children: [
//         _buildInfoCard(
//           icon: Icons.timer_outlined,
//           title: 'Duration',
//           value: '$durationMinutes min',
//           color: const Color(0xFF3A7BD5),
//         ),
//         _buildInfoCard(
//           icon: _getExamTypeIcon(examType),
//           title: 'Type',
//           value: _formatExamType(examType),
//           color: const Color(0xFF4CAF50),
//         ),
//         _buildInfoCard(
//           icon: Icons.help_outline,
//           title: 'Questions',
//           value: questions.length.toString(),
//           color: const Color(0xFF9C27B0),
//         ),
//         _buildInfoCard(
//           icon: Icons.bar_chart,
//           title: 'Difficulty',
//           value: _calculateDifficulty(),
//           color: const Color(0xFFFF9800),
//         ),
//       ],
//     );
//   }
//
//   String _calculateDifficulty() {
//     if (questions.isEmpty) return 'N/A';
//     final mcqCount = questions.where((q) => q.type == 'mcq').length;
//     final ratio = mcqCount / questions.length;
//     if (ratio < 0.3) return 'Hard';
//     if (ratio < 0.7) return 'Medium';
//     return 'Easy';
//   }
//
//   Widget _buildInfoCard({
//     required IconData icon,
//     required String title,
//     required String value,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(icon, size: 20, color: color),
//             ),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF2C3E50),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDescriptionSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Description',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF2C3E50),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           examDescription.isNotEmpty ? examDescription : 'No description provided',
//           style: TextStyle(
//             fontSize: 14,
//             color: Colors.grey[600],
//             height: 1.5,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildQuestionsSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Question Preview',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF2C3E50),
//           ),
//         ),
//         const SizedBox(height: 12),
//         ...questions.take(3).map((question) => _buildQuestionPreview(question)).toList(),
//         if (questions.length > 3)
//           Padding(
//             padding: const EdgeInsets.only(top: 8),
//             child: Text(
//               '+ ${questions.length - 3} more questions...',
//               style: const TextStyle(
//                 color: Color(0xFF3A7BD5),
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
//
//   Widget _buildQuestionPreview(QuestionModel question) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 2,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             question.questionTitle,
//             style: const TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w500,
//               color: Color(0xFF2C3E50),
//             ),
//           ),
//           const SizedBox(height: 12),
//           if (question.type == 'mcq')
//             Column(
//               children: question.getShuffledAnswers().map((answer) => Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 20,
//                       height: 20,
//                       margin: const EdgeInsets.only(right: 12),
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         border: Border.all(
//                           color: const Color(0xFF3A7BD5),
//                           width: 1.5,
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       child: Text(
//                         answer,
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey[700],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               )).toList(),
//             ),
//           if (question.type != 'mcq')
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 '${question.type.toUpperCase()} Question',
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontStyle: FontStyle.italic,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButtons(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: ElevatedButton(
//             onPressed: () {
//               // Start exam action
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ExamStartPage(questions: questions),
//                 ),
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF3A7BD5),
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Text(
//               'Start Exam',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 16),
//         Container(
//           decoration: BoxDecoration(
//             border: Border.all(color: const Color(0xFF3A7BD5)),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: IconButton(
//             icon: const Icon(Icons.more_vert, color: Color(0xFF3A7BD5)),
//             onPressed: () {
//               _showExamOptions(context);
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   void _showExamOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.edit, color: Color(0xFF3A7BD5)),
//                 title: const Text('Edit Exam'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   // Edit exam action
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.content_copy, color: Colors.green),
//                 title: const Text('Duplicate Exam'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   // Duplicate exam action
//                 },
//               ),
//               const Divider(),
//               ListTile(
//                 leading: const Icon(Icons.delete, color: Colors.red),
//                 title: const Text('Delete Exam', style: TextStyle(color: Colors.red)),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _showDeleteConfirmation(context);
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   void _showDeleteConfirmation(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Exam'),
//         content: Text('Are you sure you want to delete "$examTitle"?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.pop(context); // Also pop the details page
//             },
//             child: const Text(
//               'Delete',
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Helper methods
//   IconData _getExamTypeIcon(String type) {
//     switch (type) {
//       case 'written': return Icons.edit;
//       case 'quiz': return Icons.quiz;
//       case 'image': return Icons.image;
//       case 'video': return Icons.video_library;
//       default: return Icons.help_outline;
//     }
//   }
//
//   String _formatExamType(String type) {
//     switch (type) {
//       case 'written': return 'Written';
//       case 'quiz': return 'Quiz';
//       case 'image': return 'Image';
//       case 'video': return 'Video';
//       default: return 'Exam';
//     }
//   }
//
//   String _formatDate(String dateString) {
//     try {
//       final date = DateTime.parse(dateString);
//       return '${date.day}/${date.month}/${date.year}';
//     } catch (e) {
//       return dateString;
//     }
//   }
// }
//
// // Placeholder for ExamStartPage
// class ExamStartPage extends StatelessWidget {
//   final List<QuestionModel> questions;
//
//   const ExamStartPage({Key? key, required this.questions}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Exam Session'),
//       ),
//       body: Center(
//         child: Text('${questions.length} questions ready'),
//       ),
//     );
//   }
// }