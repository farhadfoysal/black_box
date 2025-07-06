import 'package:connectivity_plus/connectivity_plus.dart';
import '../../db/course/course_dao.dart';
import '../../model/course/course_model.dart';
import '../../services/course/supabse_service.dart';

class CourseRepository {
  final SupabaseService supabaseService;
  final CourseDAO courseDAO;

  CourseRepository({
    required this.supabaseService,
    required this.courseDAO,
  });

  /// ✅ Check internet connectivity
  Future<bool> _isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// ✅ Add a course (local first, then online if connected)
  Future<void> addCourse(CourseModel course) async {
    await courseDAO.insertCourse(course);
    if (await _isConnected()) {
      try {
        await supabaseService.createCourse(course);
      } catch (e) {
        print('Failed to add course online: $e');
      }
    }
  }

  /// ✅ Get all courses (online if connected, else local)
  Future<List<CourseModel>> getCourses() async {
    if (await _isConnected()) {
      try {
        return await supabaseService.fetchCourses();
      } catch (e) {
        print('Failed to fetch online courses: $e');
        return await courseDAO.getAllCourses();
      }
    } else {
      return await courseDAO.getAllCourses();
    }
  }

  /// ✅ Get courses by userId
  Future<List<CourseModel>> getCoursesByUserId(String userId) async {
    if (await _isConnected()) {
      try {
        return await supabaseService.fetchCoursesByUserId(userId);
      } catch (e) {
        print('Failed to fetch courses by userId online: $e');
        return [];
      }
    } else {
      // Optional: If local DB had userId info — fetch from local too
      return [];
    }
  }

  /// ✅ Get single course by uniqueId
  Future<CourseModel?> getCourseByUniqueId(String uniqueId) async {
    if (await _isConnected()) {
      try {
        return await supabaseService.fetchCourseByUniqueId(uniqueId);
      } catch (e) {
        print('Failed to fetch course by uniqueId online: $e');
        return null;
      }
    } else {
      // Optional: If local DB had uniqueId info — fetch from local too
      return null;
    }
  }

  /// ✅ Update course (local first, then online)
  Future<void> updateCourse(CourseModel course) async {
    await courseDAO.updateCourse(course);
    if (await _isConnected()) {
      try {
        await supabaseService.updateCourse(course);
      } catch (e) {
        print('Failed to update course online: $e');
      }
    }
  }

  /// ✅ Delete course (local first, then online)
  Future<void> deleteCourse(int id) async {
    await courseDAO.deleteCourse(id);
    if (await _isConnected()) {
      try {
        await supabaseService.deleteCourse(id);
      } catch (e) {
        print('Failed to delete course online: $e');
      }
    }
  }
}



// import 'package:black_box/services/course/supabse_service.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
//
// import '../../db/course/course_dao.dart';
// import '../../model/course/course_model.dart';
//
// class CourseRepository {
//   final SupabaseService supabaseService = SupabaseService();
//   final CourseDAO courseDAO = CourseDAO();
//
//   Future<bool> _isConnected() async {
//     var connectivityResult = await Connectivity().checkConnectivity();
//     return connectivityResult != ConnectivityResult.none;
//   }
//
//   Future<void> addCourse(CourseModel course) async {
//     await courseDAO.insertCourse(course);
//     if (await _isConnected()) {
//       await supabaseService.createCourse(course);
//     }
//   }
//
//   Future<List<CourseModel>> getCourses() async {
//     if (await _isConnected()) {
//       final onlineCourses = await supabaseService.fetchCourses();
//       return onlineCourses;
//     } else {
//       return await courseDAO.getAllCourses();
//     }
//   }
//
//   Future<void> updateCourse(CourseModel course) async {
//     await courseDAO.updateCourse(course);
//     if (await _isConnected()) {
//       await supabaseService.updateCourse(course);
//     }
//   }
//
//   Future<void> deleteCourse(int id) async {
//     await courseDAO.deleteCourse(id);
//     if (await _isConnected()) {
//       await supabaseService.deleteCourse(id);
//     }
//   }
// }
