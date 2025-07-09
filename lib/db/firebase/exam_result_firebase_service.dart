import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/quiz/QuizResult.dart';

class QuizResultFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new quiz result to Firestore
  Future<void> addQuizResult(QuizResult quizResult) async {
    try {
      await _firestore.collection('quiz_results').add(quizResult.toMap());
    } catch (e) {
      print('Error saving quiz result to Firestore: $e');
      rethrow;
    }
  }

  /// Check if a student has already performed a specific quiz
  Future<bool> hasUserPerformedQuiz(
      String studentId, String phoneNumber, String quizId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quiz_results')
          .where('studentId', isEqualTo: studentId)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('quizId', isEqualTo: quizId)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking quiz performance: $e');
      return false;
    }
  }

  /// Get a specific quiz result by student ID, phone number, and quiz ID
  Future<QuizResult?> getQuizResult(
      String studentId, String phoneNumber, String quizId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quiz_results')
          .where('studentId', isEqualTo: studentId)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('quizId', isEqualTo: quizId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final document = querySnapshot.docs.first;
        return QuizResult.fromMap(document.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      print('Error retrieving quiz result: $e');
      return null;
    }
  }

  /// Get all quiz results for a specific quiz
  Future<List<QuizResult>> getResultsByQuizId(String quizId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quiz_results')
          .where('quizId', isEqualTo: quizId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => QuizResult.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching quiz results: $e');
      return [];
    }
  }

  /// Delete a specific quiz result by document ID
  Future<void> deleteQuizResult(String docId) async {
    try {
      await _firestore.collection('quiz_results').doc(docId).delete();
    } catch (e) {
      print('Error deleting quiz result: $e');
    }
  }

  /// Delete all results for a specific quiz
  Future<void> deleteResultsByQuizId(String quizId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quiz_results')
          .where('quizId', isEqualTo: quizId)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting quiz results by quiz ID: $e');
    }
  }
}
