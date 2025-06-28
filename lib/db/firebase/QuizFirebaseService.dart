import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/quiz/quiz.dart';

class QuizFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add or update a quiz in Firebase
  Future<void> addOrUpdateQuiz1(Quiz quiz) async {
    try {
      await _firestore.collection('quizzes').doc(quiz.qId).set(quiz.toJson());
    } catch (e) {
      print("Error adding or updating quiz: $e");
    }
  }

  Future<Quiz> addOrUpdateQuiz(Quiz quiz) async {
    try {
      // If the qId is not set (i.e., new quiz), Firestore will auto-generate the document ID
      if (quiz.qId.isEmpty) {
        final docRef = await _firestore.collection('quizzes').add(quiz.toJson());

        // After creating the document, update the quiz object with the new qId
        quiz.qId = docRef.id;  // Firestore generates a unique ID for new documents
      } else {
        // If the qId is set (i.e., update existing quiz), update the document with the given qId
        await _firestore.collection('quizzes').doc(quiz.qId).set(quiz.toJson());
      }

      return quiz;  // Return the updated or newly created quiz
    } catch (e) {
      print("Error adding or updating quiz: $e");
      rethrow;
    }
  }


  // Get a quiz by its ID
  Future<Quiz?> getQuizById(String quizId) async {
    try {
      final doc = await _firestore.collection('quizzes').doc(quizId).get();
      if (doc.exists) {
        return Quiz.fromJson(doc.data()!);
      }
    } catch (e) {
      print("Error fetching quiz: $e");
    }
    return null;
  }

  // Get all quizzes
  Future<List<Quiz>> getAllQuizzes() async {
    try {
      final querySnapshot = await _firestore.collection('quizzes').get();
      return querySnapshot.docs
          .map((doc) => Quiz.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error fetching quizzes: $e");
      return [];
    }
  }

  // Delete a quiz by its ID
  Future<void> deleteQuiz(String quizId) async {
    try {
      await _firestore.collection('quizzes').doc(quizId).delete();
    } catch (e) {
      print("Error deleting quiz: $e");
    }
  }
}
