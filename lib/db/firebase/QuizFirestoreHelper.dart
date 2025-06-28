import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../model/quiz/QResult.dart';
import '../../model/quiz/QuizResult.dart';
import '../../quiz/QuizResult.dart';

class Quizfirestorehelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveQuizResultToFirestore(QuizResult quizResult) async {
    try {
      // Get a reference to the Firestore collection
      final quizResultCollection = FirebaseFirestore.instance.collection('quiz_results');

      // Convert the quiz result to a map
      final quizResultMap = quizResult.toMap();

      // Save the result to Firestore
      await quizResultCollection.add(quizResultMap);
    } catch (e) {
      print('Error saving quiz result to Firestore: $e');
      throw e; // Rethrow the error if needed
    }
  }
  // Save the quiz result to Firestore
  // Future<void> saveQuizResultToFirestore(QuizResult quizResult) async {
  //   String resultId = Uuid().v4(); // Generate a unique ID for each result
  //   await _firestore.collection('quiz_results').doc(resultId).set({
  //     'studentId': quizResult.studentId,
  //     'phoneNumber': quizResult.phoneNumber,
  //     'quizId': quizResult.quiz.qId,
  //     'quizName': quizResult.quiz.quizName,
  //     'correctCount': quizResult.correctCount,
  //     'incorrectCount': quizResult.incorrectCount,
  //     'uncheckedCount': quizResult.uncheckedCount,
  //     'percentage': quizResult.percentage,
  //     'timestamp': FieldValue.serverTimestamp(),
  //   });
  // }


  Future<bool> hasUserPerformedQuiz(String studentId, String phoneNumber, String quizId) async {
    try {
      // Query Firestore to check if the document with the same studentId, phoneNumber, and quizId exists
      final querySnapshot = await _firestore.collection('quiz_results')
          .where('studentId', isEqualTo: studentId)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('quizId', isEqualTo: quizId)
          .get();

      // If the query returns documents, it means the user has already performed the quiz
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking quiz performance in Firestore: $e');
      return false; // Handle the error case
    }
  }

  Future<QResult?> getQuizResult(String studentId, String phoneNumber, String quizId) async {
    try {
      // Query Firestore to get the quiz result for the specific student and quiz
      final querySnapshot = await _firestore.collection('quiz_results')
          .where('studentId', isEqualTo: studentId)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('quizId', isEqualTo: quizId)
          .get();

      // If a document is found, return the quiz result
      if (querySnapshot.docs.isNotEmpty) {
        final document = querySnapshot.docs.first;
        // Assuming your QuizResult class has a fromMap method to convert Firestore data to an object
        return QResult.fromMap(document.data() as Map<String, dynamic>);
      } else {
        return null; // No quiz result found
      }
    } catch (e) {
      print('Error retrieving quiz result from Firestore: $e');
      return null; // Return null if an error occurs
    }
  }

  Future<List<QResult>> getOnlineResults(String quizId) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('quiz_results')
        .where('quizId', isEqualTo: quizId)
        .get();

    // Convert Firestore documents into a list of QResult objects
    return snapshot.docs.map((doc) {
      return QResult.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }


}
