import 'package:flutter/material.dart';
import '../models/exam_result_model.dart';

class ResultCardWidget extends StatelessWidget {
  final ExamResult result;
  final VoidCallback? onTap;

  const ResultCardWidget({
    Key? key,
    required this.result,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(result.percentage);
    final gradeInfo = _getGradeInfo(result.percentage);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.studentName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ID: ${result.studentId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scoreColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${result.percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          gradeInfo['grade']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: scoreColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.assignment,
                    result.examName,
                    Colors.blue,
                  ),
                  SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.calendar_today,
                    _formatDate(result.scannedAt),
                    Colors.purple,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildScoreDetail(
                      'Correct',
                      result.correctCount.toString(),
                      Color(0xFF2ECC71),
                    ),
                  ),
                  Expanded(
                    child: _buildScoreDetail(
                      'Wrong',
                      result.wrongCount.toString(),
                      Color(0xFFE74C3C),
                    ),
                  ),
                  Expanded(
                    child: _buildScoreDetail(
                      'Skipped',
                      result.unansweredCount.toString(),
                      Color(0xFFF39C12),
                    ),
                  ),
                  Expanded(
                    child: _buildScoreDetail(
                      'Total',
                      result.totalQuestions.toString(),
                      Color(0xFF3498DB),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: result.percentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDetail(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Color(0xFF2ECC71);
    if (percentage >= 60) return Color(0xFF3498DB);
    if (percentage >= 40) return Color(0xFFF39C12);
    return Color(0xFFE74C3C);
  }

  Map<String, String> _getGradeInfo(double percentage) {
    if (percentage >= 90) return {'grade': 'A+', 'status': 'Excellent'};
    if (percentage >= 80) return {'grade': 'A', 'status': 'Very Good'};
    if (percentage >= 70) return {'grade': 'B+', 'status': 'Good'};
    if (percentage >= 60) return {'grade': 'B', 'status': 'Satisfactory'};
    if (percentage >= 50) return {'grade': 'C', 'status': 'Pass'};
    if (percentage >= 40) return {'grade': 'D', 'status': 'Below Average'};
    return {'grade': 'F', 'status': 'Fail'};
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}