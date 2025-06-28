import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/quiz/question.dart';

class QuestionFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add or update a question in Firebase
  Future<void> addOrUpdateQuestion(Question question) async {
    try {
      await _firestore
          .collection('questions')
          .doc(question.qId)
          .set(question.toJson());
    } catch (e) {
      print("Error adding or updating question: $e");
    }
  }

  Future<Question> addOrUpdateQuestionn(Question question) async {
    try {
      // If the qId is not set, create a new document (Firestore will auto-generate the ID)
      if (question.qId!.isEmpty) {
        final docRef = await _firestore.collection('questions').add(question.toJson());

        // After creating the document, update the question object with the new qId
        question.qId = docRef.id;  // Firestore generates a unique ID
      } else {
        // If the qId is set, update the existing document
        await _firestore.collection('questions').doc(question.qId).set(question.toJson());
      }

      return question;  // Return the updated question
    } catch (e) {
      print("Error adding or updating question: $e");
      rethrow;
    }
  }

  // Get all questions for a specific quiz
  Future<List<Question>> getQuestionsByQuizId(String quizId) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .where('quiz_id', isEqualTo: quizId)
          .get();

      return querySnapshot.docs
          .map((doc) => Question.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching questions: $e");
      return [];
    }
  }

  // Delete a question by its ID
  Future<void> deleteQuestion(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).delete();
    } catch (e) {
      print("Error deleting question: $e");
    }
  }

  // Delete all questions for a specific quiz
  Future<void> deleteQuestionsByQuizId(String quizId) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .where('quiz_id', isEqualTo: quizId)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print("Error deleting questions by quiz ID: $e");
    }
  }
}
