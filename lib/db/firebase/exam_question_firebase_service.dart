import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/exam/question_model.dart';

class ExamQuestionFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add or update an exam question in Firebase
  Future<QuestionModel> addOrUpdateExamQuestion(QuestionModel question) async {
    try {
      // If no qId set, create a new document
      if (question.qId == null || question.qId!.isEmpty) {
        final docRef = await _firestore.collection('questions').add(question.toJson());

        // Update question object with generated Firestore document ID
        question.qId = docRef.id;
      } else {
        // If qId exists, update the document
        await _firestore.collection('questions').doc(question.qId).set(question.toJson());
      }

      return question;
    } catch (e) {
      print("Error adding or updating exam question: $e");
      rethrow;
    }
  }

  /// Get all questions for a specific exam
  Future<List<QuestionModel>> getQuestionsByExamId(String examId) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .where('quiz_id', isEqualTo: examId)
          .get();

      return querySnapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching exam questions: $e");
      return [];
    }
  }

  /// Delete a question by its ID
  Future<void> deleteExamQuestion(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).delete();
    } catch (e) {
      print("Error deleting exam question: $e");
    }
  }

  /// Delete all questions for a specific exam
  Future<void> deleteQuestionsByExamId(String examId) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .where('quiz_id', isEqualTo: examId)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print("Error deleting exam questions by exam ID: $e");
    }
  }
}
