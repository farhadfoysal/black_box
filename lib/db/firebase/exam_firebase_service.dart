import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/exam/exam_model.dart';

class ExamFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add or update an exam in Firebase
  Future<ExamModel> addOrUpdateExam(ExamModel exam) async {
    try {
      // If examId is not set (i.e., new exam), Firestore will auto-generate the document ID
      if (exam.examId.isEmpty) {
        final docRef = await _firestore.collection('quizzes').add(exam.toJson());

        // After creating the document, update the exam object with the new examId
        exam.examId = docRef.id;
      } else {
        // If examId is set (update existing exam)
        await _firestore.collection('quizzes').doc(exam.examId).set(exam.toJson());
      }

      return exam;
    } catch (e) {
      print("Error adding or updating exam: $e");
      rethrow;
    }
  }

  // Get an exam by its ID
  Future<ExamModel?> getExamById(String examId) async {
    try {
      final doc = await _firestore.collection('quizzes').doc(examId).get();
      if (doc.exists) {
        return ExamModel.fromJson(doc.data()!);
      }
    } catch (e) {
      print("Error fetching exam: $e");
    }
    return null;
  }

  // Get all exams
  Future<List<ExamModel>> getAllExams() async {
    try {
      final querySnapshot = await _firestore.collection('quizzes').get();
      return querySnapshot.docs
          .map((doc) => ExamModel.fromJson(doc.data()!))
          .toList();
    } catch (e) {
      print("Error fetching exams: $e");
      return [];
    }
  }

  // Delete an exam by its ID
  Future<void> deleteExam(String examId) async {
    try {
      await _firestore.collection('quizzes').doc(examId).delete();
    } catch (e) {
      print("Error deleting exam: $e");
    }
  }
}
