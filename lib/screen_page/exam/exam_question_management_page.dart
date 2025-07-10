import 'package:black_box/db/exam/exam_dao.dart';
import 'package:black_box/db/exam/question_dao.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

import '../../db/firebase/exam_question_firebase_service.dart';
import '../../model/exam/exam_model.dart';
import '../../model/exam/question_model.dart';
import '../../utility/unique.dart';

class ExamQuestionManagementPage extends StatefulWidget {
  final ExamModel exam;

  const ExamQuestionManagementPage({super.key, required this.exam});

  @override
  State<ExamQuestionManagementPage> createState() =>
      _ExamQuestionManagementPageState();
}

class _ExamQuestionManagementPageState
    extends State<ExamQuestionManagementPage> {
  bool _isLoading = false;
  bool isOnline = true;

  List<QuestionModel> _questions = [];

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      if (isOnline) {
        _questions = await ExamQuestionFirebaseService()
            .getQuestionsByExamId(widget.exam.uniqueId);
      } else {
        _questions =
            await QuestionDAO().getQuestionsByExamId(widget.exam.uniqueId);
      }
      setState(() {});
    } catch (e) {
      _showError("Error loading questions: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteQuestion(String qId) async {
    try {
      if (isOnline) {
        await ExamQuestionFirebaseService().deleteExamQuestion(qId);
      } else {
        await QuestionDAO().deleteQuestionByUniqueId(qId);
      }
      _loadQuestions();
      _showError("Question deleted successfully.");
    } catch (e) {
      _showError("Error deleting question: $e");
    }
  }

  Future<void> _addOrEditQuestion(QuestionModel? question) async {
    final TextEditingController questionTitleController =
    TextEditingController(text: question?.questionTitle);
    final TextEditingController explanationController =
    TextEditingController(text: question?.explanation);
    final TextEditingController sourceController =
    TextEditingController(text: question?.source);
    final TextEditingController urlController =
    TextEditingController(text: question?.url ?? '');

    String selectedType = question?.type ?? "TEXT";

    List<TextEditingController> optionControllers =
        question?.questionAnswers
            .map((answer) => TextEditingController(text: answer))
            .toList() ??
            [TextEditingController(), TextEditingController()];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Scaffold(
                backgroundColor: Colors.deepPurple.shade50,
                appBar: AppBar(
                  title: Text(question == null ? 'Add New Exam Question' : 'Edit Question'),
                  backgroundColor: Colors.deepPurple,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Lottie Animation
                      SizedBox(
                        height: 150,
                        child: Lottie.asset('animation/ (1).json'),
                      ),
                      const SizedBox(height: 16),

                      // Question Title
                      TextFormField(
                        controller: questionTitleController,
                        maxLines: 3,
                        decoration: _styledInputDecoration('Question Title', Icons.edit_note),
                      ),
                      const SizedBox(height: 16),

                      // Options List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: optionControllers.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: optionControllers[index],
                              maxLines: 2,
                              decoration: _styledInputDecoration('Option ${index + 1}', Icons.list_alt),
                            ),
                          );
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              optionControllers.add(TextEditingController());
                            });
                          },
                          icon: const Icon(Icons.add, color: Colors.deepPurple),
                          label: const Text('Add Option', style: TextStyle(color: Colors.deepPurple)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Question Type Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: _styledInputDecoration('Question Type', Icons.category),
                        items: ["TEXT", "IMAGE", "VIDEO", "AUDIO", "YOUTUBE"].map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedType = value ?? "TEXT";
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // URL Field
                      TextFormField(
                        controller: urlController,
                        maxLines: 2,
                        decoration: _styledInputDecoration('URL (Image/Video/Audio)', Icons.link),
                      ),
                      const SizedBox(height: 16),

                      // Explanation
                      TextFormField(
                        controller: explanationController,
                        maxLines: 3,
                        decoration: _styledInputDecoration('Explanation', Icons.lightbulb_outline),
                      ),
                      const SizedBox(height: 16),

                      // Source
                      TextFormField(
                        controller: sourceController,
                        maxLines: 2,
                        decoration: _styledInputDecoration('Source', Icons.source),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (questionTitleController.text.isEmpty ||
                                optionControllers.any((controller) => controller.text.isEmpty)) {
                              _showError('Please fill in all fields.');
                              return;
                            }

                            String uniqueId = Unique().generateUniqueID();

                            final newQuestion = QuestionModel(
                              qId: question?.qId ?? uniqueId,
                              quizId: widget.exam.uniqueId,
                              questionTitle: questionTitleController.text,
                              questionAnswers: optionControllers.map((controller) => controller.text).toList(),
                              correctAnswer: '', // Optionally handle correct answer selection
                              explanation: explanationController.text,
                              source: sourceController.text,
                              type: selectedType,
                              url: urlController.text,
                            );

                            try {
                              if (isOnline) {
                                await ExamQuestionFirebaseService().addOrUpdateExamQuestion(newQuestion);
                              } else {
                                await QuestionDAO().insertQuestion(newQuestion);
                              }
                              Navigator.of(context).pop();
                              _loadQuestions();
                            } catch (e) {
                              _showError("Error saving question: $e");
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: Text(question == null ? 'Add Question' : 'Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _styledInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleOnlineOffline() {
    setState(() => isOnline = !isOnline);
    _loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('${widget.exam.title} - Questions'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Exam Manager',
                  style: TextStyle(fontSize: 24, color: Colors.white)),
            ),
            ListTile(
              title: Text(isOnline ? 'Switch to Offline' : 'Switch to Online'),
              onTap: _toggleOnlineOffline,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final q = _questions[index];
                return Dismissible(
                  key: Key(q.qId!),
                  direction: DismissDirection.endToStart,
                  onDismissed: (dir) => _deleteQuestion(q.qId!),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                    elevation: 3,
                    child: ListTile(
                      title: Text(q.questionTitle),
                      subtitle: Text("Type: ${q.type}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.deepPurple),
                        onPressed: () => _addOrEditQuestion(q),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditQuestion(null),
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
        tooltip: 'Add New Question',
      ),
    );
  }
}
