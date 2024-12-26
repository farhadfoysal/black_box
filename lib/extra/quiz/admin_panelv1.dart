import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/question1.dart';

class AdminPanelv1 extends StatefulWidget {
  @override
  _AdminPanelV1State createState() => _AdminPanelV1State();
}

class _AdminPanelV1State extends State<AdminPanelv1> {
  final _formKey = GlobalKey<FormState>();
  String _questionText = '';
  String _mediaUrl = '';
  String _quizId = '';
  String _schoolId = '';
  List<String> _options = [];
  String _id = '';

  // Question type (default: MCQ)
  QuestionType _selectedType = QuestionType.mcq;

  final _optionController = TextEditingController();


  Future<void> saveQuestion(Question1 question) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('questions').doc(question.id);
      await docRef.set(question.toJson());
      print('Question saved successfully');
    } catch (e) {
      print('Error saving question: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel - Add Question')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Question ID'),
                  onSaved: (value) {
                    _id = value ?? '';
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a Question ID';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Question Text'),
                  onSaved: (value) {
                    _questionText = value ?? '';
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a question';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<QuestionType>(
                  value: _selectedType,
                  items: QuestionType.values.map((QuestionType type) {
                    return DropdownMenuItem<QuestionType>(
                      value: type,
                      child: Text(type.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Question Type'),
                ),
                if (_selectedType == QuestionType.mcq)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Options (Add one by one):'),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _optionController,
                              decoration: InputDecoration(hintText: 'Option'),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _options.add(_optionController.text);
                                _optionController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                      Wrap(
                        children: _options
                            .map((option) => Chip(
                          label: Text(option),
                          onDeleted: () {
                            setState(() {
                              _options.remove(option);
                            });
                          },
                        ))
                            .toList(),
                      ),
                    ],
                  ),
                if (_selectedType == QuestionType.image ||
                    _selectedType == QuestionType.url ||
                    _selectedType == QuestionType.driveLink)
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Media URL'),
                    onSaved: (value) {
                      _mediaUrl = value ?? '';
                    },
                  ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Quiz ID'),
                  onSaved: (value) {
                    _quizId = value ?? '';
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a Quiz ID';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'School ID'),
                  onSaved: (value) {
                    _schoolId = value ?? '';
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a School ID';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final question = Question1(
                        id: _id,
                        type: _selectedType,
                        questionText: _questionText,
                        options: _options.isNotEmpty ? _options : null,
                        mediaUrl: _mediaUrl.isNotEmpty ? _mediaUrl : null,
                        quizId: _quizId,
                        schoolId: _schoolId,
                      );

                      await saveQuestion(question);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Question saved successfully')),
                      );

                      // Clear form after saving
                      setState(() {
                        _formKey.currentState?.reset();
                        _options.clear();
                      });
                    }
                  },
                  child: Text('Save Question'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
