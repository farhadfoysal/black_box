import 'package:black_box/model/exam/quiz_result_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizResultFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new quiz result to Firestore
  Future<void> addQuizResult(QuizResultModel quizResult) async {
    try {
      await _firestore.collection('quiz_results').add(quizResult.toJson());
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
          .where('student_id', isEqualTo: studentId)
          .where('phone_number', isEqualTo: phoneNumber)
          .where('quiz_id', isEqualTo: quizId)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking quiz performance: $e');
      return false;
    }
  }

  /// Get a specific quiz result by student ID, phone number, and quiz ID
  Future<QuizResultModel?> getQuizResult(
      String studentId, String phoneNumber, String quizId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quiz_results')
          .where('student_id', isEqualTo: studentId)
          .where('phone_number', isEqualTo: phoneNumber)
          .where('quiz_id', isEqualTo: quizId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final document = querySnapshot.docs.first;
        return QuizResultModel.fromJson(document.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      print('Error retrieving quiz result: $e');
      return null;
    }
  }

  /// Get all quiz results for a specific quiz
  Future<List<QuizResultModel>> getResultsByQuizId(String quizId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quiz_results')
          .where('quiz_id', isEqualTo: quizId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => QuizResultModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching quiz results: $e');
      return [];
    }
  }

  /// Get all quiz results for a quiz (alternate method)
  Future<List<QuizResultModel>> getOnlineResults(String quizId) async {
    try {
      final snapshot = await _firestore
          .collection('quiz_results')
          .where('quiz_id', isEqualTo: quizId)
          .get();

      return snapshot.docs
          .map((doc) => QuizResultModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching online quiz results: $e');
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
          .where('quiz_id', isEqualTo: quizId)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting quiz results by quiz ID: $e');
    }
  }
}
