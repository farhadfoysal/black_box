import 'package:flutter/material.dart';
import 'omr_model.dart';

class ProfessionalOMRScanner extends StatefulWidget {
  final OMRExamConfig config;

  const ProfessionalOMRScanner({Key? key, required this.config}) : super(key: key);

  @override
  State<ProfessionalOMRScanner> createState() => _ProfessionalOMRScannerState();
}

class _ProfessionalOMRScannerState extends State<ProfessionalOMRScanner> {
  Map<int, String> scannedAnswers = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional OMR Scanner'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showAnalytics,
            tooltip: 'View Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveResults,
            tooltip: 'Save Results',
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildScannerHeader(),
            _buildAnswerSheet(),
            _buildResultSection(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.config.examName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _buildInfoItem('Student ID', widget.config.studentId),
                  _buildInfoItem('Mobile', widget.config.mobileNumber),
                  _buildInfoItem('Set Number', widget.config.setNumber.toString()),
                  _buildInfoItem('Date', _formatDate(widget.config.examDate)),
                  _buildInfoItem('Class', widget.config.className),
                  _buildInfoItem('Subject', widget.config.subjectName),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value.isEmpty ? 'N/A' : value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerSheet() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mark Your Answers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap on the circles to mark your answers',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              _buildProgressIndicator(),
              const SizedBox(height: 20),
              ..._buildQuestionGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final answered = scannedAnswers.length;
    final total = widget.config.numberOfQuestions;
    final percentage = total > 0 ? (answered / total * 100) : 0;

    return Column(
      children: [
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage == 100 ? Colors.green : const Color(0xFF2C3E50),
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text(
          '$answered/$total questions answered (${percentage.toStringAsFixed(1)}%)',
          style: TextStyle(
            fontSize: 12,
            color: percentage == 100 ? Colors.green : const Color(0xFF2C3E50),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildQuestionGrid() {
    final questionsPerRow = 2;
    final rows = (widget.config.numberOfQuestions / questionsPerRow).ceil();

    return List.generate(rows, (rowIndex) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: _buildQuestionRow(rowIndex * questionsPerRow + 1),
            ),
            if (rowIndex * questionsPerRow + 2 <= widget.config.numberOfQuestions)
              const SizedBox(width: 16),
            if (rowIndex * questionsPerRow + 2 <= widget.config.numberOfQuestions)
              Expanded(
                child: _buildQuestionRow(rowIndex * questionsPerRow + 2),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildQuestionRow(int questionNumber) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: scannedAnswers.containsKey(questionNumber)
            ? const Color(0xFFE8F5E8)
            : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q$questionNumber',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: scannedAnswers.containsKey(questionNumber)
                  ? Colors.green
                  : const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['A', 'B', 'C', 'D'].map((option) {
              final isSelected = scannedAnswers[questionNumber] == option;
              return GestureDetector(
                onTap: () => _selectAnswer(questionNumber, option),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? const Color(0xFF2C3E50) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2C3E50) : Colors.grey,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: const Color(0xFF2C3E50).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  Widget _buildResultSection() {
    final results = _calculateResults();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResultItem('Answered', '${scannedAnswers.length}', Icons.check_circle, Colors.blue),
                  _buildResultItem('Correct', '${results['correct']}', Icons.thumb_up, Colors.green),
                  _buildResultItem('Wrong', '${results['wrong']}', Icons.thumb_down, Colors.red),
                  _buildResultItem('Score', '${results['score']}%', Icons.grade, Colors.orange),
                ],
              ),
              const SizedBox(height: 16),
              if (scannedAnswers.isNotEmpty)
                LinearProgressIndicator(
                  value: results['score'] / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getScoreColor(results['score']),
                  ),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _clearAllAnswers,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: scannedAnswers.isEmpty ? null : _showDetailedResults,
              icon: const Icon(Icons.analytics),
              label: const Text('View Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C3E50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(int questionNumber, String option) {
    setState(() {
      if (scannedAnswers[questionNumber] == option) {
        scannedAnswers.remove(questionNumber);
      } else {
        scannedAnswers[questionNumber] = option;
      }
    });
  }

  Map<String, dynamic> _calculateResults() {
    int correct = 0;
    int wrong = 0;

    for (int i = 1; i <= widget.config.numberOfQuestions; i++) {
      if (scannedAnswers.containsKey(i)) {
        if (widget.config.correctAnswers.length >= i &&
            scannedAnswers[i] == widget.config.correctAnswers[i - 1]) {
          correct++;
        } else {
          wrong++;
        }
      }
    }

    final totalAnswered = scannedAnswers.length;
    final score = totalAnswered > 0 ? (correct / totalAnswered * 100) : 0;

    return {
      'correct': correct,
      'wrong': wrong,
      'score': score.roundToDouble(),
      'totalAnswered': totalAnswered,
    };
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAnalytics() {
    final results = _calculateResults();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exam Analytics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnalyticsItem('Total Questions', widget.config.numberOfQuestions.toString()),
              _buildAnalyticsItem('Questions Answered', scannedAnswers.length.toString()),
              _buildAnalyticsItem('Correct Answers', results['correct'].toString()),
              _buildAnalyticsItem('Wrong Answers', results['wrong'].toString()),
              _buildAnalyticsItem('Accuracy', '${results['score'].toStringAsFixed(1)}%'),
              _buildAnalyticsItem('Completion', '${(scannedAnswers.length / widget.config.numberOfQuestions * 100).toStringAsFixed(1)}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showDetailedResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Results'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.config.numberOfQuestions,
            itemBuilder: (context, index) {
              final questionNumber = index + 1;
              final userAnswer = scannedAnswers[questionNumber];
              final correctAnswer = widget.config.correctAnswers.length > index
                  ? widget.config.correctAnswers[index]
                  : 'N/A';
              final isCorrect = userAnswer == correctAnswer;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isCorrect ? Colors.green : Colors.red,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isCorrect ? Colors.green[50] : Colors.red[50],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                      child: Icon(
                        isCorrect ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question $questionNumber',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your Answer: ${userAnswer ?? "Not answered"}',
                            style: TextStyle(
                              color: userAnswer == null ? Colors.orange : Colors.black,
                            ),
                          ),
                          Text(
                            'Correct Answer: $correctAnswer',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _clearAllAnswers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Answers'),
        content: const Text('Are you sure you want to clear all answers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                scannedAnswers.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All answers cleared')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveResults() async {
    if (scannedAnswers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No answers to save')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    final results = _calculateResults();
    final List<int> answers = [];

    for (int i = 1; i <= widget.config.numberOfQuestions; i++) {
      final answer = scannedAnswers[i];
      answers.add(answer != null ? ['A', 'B', 'C', 'D'].indexOf(answer) : -1);
    }

    final response = OMRResponse(
      setNumber: widget.config.setNumber,
      studentId: widget.config.studentId,
      mobileNumber: widget.config.mobileNumber,
      answers: answers,
      score: results['score'],
      correctAnswers: results['correct'],
      totalQuestions: widget.config.numberOfQuestions,
      submissionTime: DateTime.now(),
    );

    setState(() {
      _isSubmitting = false;
    });

    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Results Saved Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${results['score'].toStringAsFixed(1)}%'),
            Text('Correct Answers: ${results['correct']}/${scannedAnswers.length}'),
            Text('Total Questions: ${widget.config.numberOfQuestions}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}