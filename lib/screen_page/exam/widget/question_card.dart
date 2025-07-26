import 'package:flutter/material.dart';
import '../../../model/exam/question_model.dart';
import 'edpuzzle_video_widget.dart';
import 'image_input_widget.dart';

class QuestionCard extends StatefulWidget {
  final QuestionModel question;
  final int questionNumber;
  final ValueChanged<String?> onAnswerSelected;

  const QuestionCard({
    Key? key,
    required this.question,
    required this.questionNumber,
    required this.onAnswerSelected,
  }) : super(key: key);

  @override
  _QuestionCardState createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  String? selectedAnswer;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A7BD5).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.questionNumber}',
                    style: const TextStyle(
                      color: Color(0xFF3A7BD5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Question ${widget.questionNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Question Content
            if (widget.question.type == 'image')
              _buildImageQuestion()
            else if (widget.question.type == 'video')
              _buildVideoQuestion()
            else
              _buildTextQuestion(),

            const SizedBox(height: 16),

            // Answer Options
            if (widget.question.type == 'mcq')
              _buildMCQOptions()
            else if (widget.question.type == 'text')
              _buildTextInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextQuestion() {
    return Text(
      widget.question.questionTitle,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF2C3E50),
        height: 1.4,
      ),
    );
  }

  Widget _buildImageQuestion() {
    return Column(
      children: [
        Text(
          widget.question.questionTitle,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2C3E50),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            widget.question.url!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoQuestion() {
    return Column(
      children: [
        Text(
          widget.question.questionTitle,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2C3E50),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        EdpuzzleVideoWidget(videoUrl: widget.question.url!),
      ],
    );
  }

  Widget _buildMCQOptions() {
    return Column(
      children: widget.question.getShuffledAnswers().map((answer) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                selectedAnswer = answer;
                widget.onAnswerSelected(answer);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: selectedAnswer == answer
                    ? const Color(0xFF3A7BD5).withOpacity(0.1)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedAnswer == answer
                      ? const Color(0xFF3A7BD5)
                      : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedAnswer == answer
                            ? const Color(0xFF3A7BD5)
                            : Colors.grey[500]!,
                        width: 2,
                      ),
                    ),
                    child: selectedAnswer == answer
                        ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3A7BD5),
                        ),
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      answer,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextInput() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A7BD5)),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      maxLines: 3,
      onChanged: (value) {
        widget.onAnswerSelected(value);
      },
    );
  }
}
