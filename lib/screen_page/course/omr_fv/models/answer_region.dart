// lib/omr/models/answer_region.dart
import 'dart:ui';

class AnswerRegion {
  final int questionNumber;
  final Rect region; // absolute pixel rect will be set by template mapping
  AnswerRegion({required this.questionNumber, required this.region});
}
