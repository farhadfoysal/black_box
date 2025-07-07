import 'package:black_box/model/course/video_lesson.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../db/course/course_dao.dart';
import '../../model/course/course_model.dart';
import '../../model/course/enrollment.dart';
import '../../model/course/favorite.dart';
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

  // --------------------------------------------------
  // 📌 COURSES
  // --------------------------------------------------

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

  Future<List<CourseModel>> getCoursesByUserId(String userId) async {
    if (await _isConnected()) {
      try {
        return await supabaseService.fetchCoursesByUserId(userId);
      } catch (e) {
        print('Failed to fetch courses by userId online: $e');
        return [];
      }
    } else {
      return [];
    }
  }

  Future<CourseModel?> getCourseByUniqueId(String uniqueId) async {
    if (await _isConnected()) {
      try {
        return await supabaseService.fetchCourseByUniqueId(uniqueId);
      } catch (e) {
        print('Failed to fetch course by uniqueId online: $e');
        return null;
      }
    } else {
      return null;
    }
  }

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

  // --------------------------------------------------
  // 📌 ENROLLMENTS
  // --------------------------------------------------

  Future<void> enrollCourse(Enrollment enrollment) async {
    if (await _isConnected()) {
      try {
        await supabaseService.enrollCourse(enrollment);
      } catch (e) {
        print('Failed to enroll: $e');
      }
    } else {
      print('No connection. Enrollment skipped.');
    }
  }

  Future<void> disenrollCourse(String userId, String courseId) async {
    if (await _isConnected()) {
      try {
        await supabaseService.disenrollCourse(userId, courseId);
      } catch (e) {
        print('Failed to disenroll: $e');
      }
    } else {
      print('No connection. Disenrollment skipped.');
    }
  }

  Future<List<String>> getEnrolledCourseIds(String userId) async {
    if (await _isConnected()) {
      try {
        return await supabaseService.getEnrolledCourseIds(userId);
      } catch (e) {
        print('Failed to fetch enrolled courses: $e');
        return [];
      }
    } else {
      return [];
    }
  }

  // Future<List<String>> getEnrolledCourseIds(String userId) async {
  //   final hasConnection = await InternetConnectionChecker().hasConnection;
  //
  //   try {
  //     if (hasConnection) {
  //       // ✅ Online from Supabase
  //       return await supabaseService.getEnrolledCourseIds(userId);
  //     } else {
  //       // ✅ Offline from Sqflite
  //       return await CourseEnrollmentDAO().getEnrolledCourseIds(userId);
  //     }
  //   } catch (e) {
  //     print("Failed to fetch enrolled course IDs: $e");
  //     return [];
  //   }
  // }

  // Future<List<String>> getFavoriteCourseIds(String userId) async {
  //   final hasConnection = await InternetConnectionChecker().hasConnection;
  //
  //   try {
  //     if (hasConnection) {
  //       // ✅ Online from Supabase
  //       return await supabaseService.getFavoriteCourseIds(userId);
  //     } else {
  //       // ✅ Offline from Sqflite
  //       return await CourseFavoriteDAO().getFavoriteCourseIds(userId);
  //     }
  //   } catch (e) {
  //     print("Failed to fetch favorite course IDs: $e");
  //     return [];
  //   }
  // }

  Future<List<CourseModel>> getEnrolledCourses(String userId) async {
    final courseIds = await getEnrolledCourseIds(userId);
    if (courseIds.isEmpty) return [];

    final hasConnection = await InternetConnectionChecker.instance.hasConnection;

    try {
      if (hasConnection) {
        final allCourses = await supabaseService.fetchCourses();
        return allCourses.where((c) => courseIds.contains(c.uniqueId)).toList();
      } else {
        final allCourses = await courseDAO.getAllCourses();
        return allCourses.where((c) => courseIds.contains(c.uniqueId)).toList();
      }
    } catch (e) {
      print("Failed to fetch enrolled courses: $e");
      return [];
    }
  }

  Future<List<CourseModel>> getFavoriteCourses(String userId) async {
    final courseIds = await getFavoriteCourseIds(userId);
    if (courseIds.isEmpty) return [];

    final hasConnection = await InternetConnectionChecker.instance.hasConnection;

    try {
      if (hasConnection) {
        final allCourses = await supabaseService.fetchCourses();
        return allCourses.where((c) => courseIds.contains(c.uniqueId)).toList();
      } else {
        final allCourses = await courseDAO.getAllCourses();
        return allCourses.where((c) => courseIds.contains(c.uniqueId)).toList();
      }
    } catch (e) {
      print("Failed to fetch favorite courses: $e");
      return [];
    }
  }


  // --------------------------------------------------
  // 📌 FAVORITES
  // --------------------------------------------------

  Future<void> favoriteCourse(Favorite favorite) async {
    if (await _isConnected()) {
      try {
        await supabaseService.favoriteCourse(favorite);
      } catch (e) {
        print('Failed to favorite: $e');
      }
    } else {
      print('No connection. Favorite skipped.');
    }
  }

  Future<void> unfavoriteCourse(String userId, String courseId) async {
    if (await _isConnected()) {
      try {
        await supabaseService.unfavoriteCourse(userId, courseId);
      } catch (e) {
        print('Failed to unfavorite: $e');
      }
    } else {
      print('No connection. Unfavorite skipped.');
    }
  }

  Future<List<String>> getFavoriteCourseIds(String userId) async {
    if (await _isConnected()) {
      try {
        return await supabaseService.getFavoriteCourseIds(userId);
      } catch (e) {
        print('Failed to fetch favorites: $e');
        return [];
      }
    } else {
      return [];
    }
  }

  // --------------------------------------------------
  // 📌 COURSE VIDEOS
  // --------------------------------------------------

  Future<void> addVideoToCourse(VideoLesson video) async {
    if (await _isConnected()) {
      try {
        await supabaseService.addVideo(video);
      } catch (e) {
        print('Failed to add video: $e');
      }
    } else {
      print('No connection. Video upload skipped.');
    }
  }

  Future<List<VideoLesson>> getVideosByCourseId(String courseId) async {
    if (await _isConnected()) {
      try {
        return await supabaseService.getVideosByCourseId(courseId);
      } catch (e) {
        print('Failed to fetch course videos: $e');
        return [];
      }
    } else {
      return [];
    }
  }

  Future<void> deleteVideo(String videoId) async {
    if (await _isConnected()) {
      try {
        await supabaseService.deleteVideo(videoId);
      } catch (e) {
        print('Failed to delete video: $e');
      }
    } else {
      print('No connection. Delete video skipped.');
    }
  }
}




// import 'package:connectivity_plus/connectivity_plus.dart';
// import '../../db/course/course_dao.dart';
// import '../../model/course/course_model.dart';
// import '../../services/course/supabse_service.dart';
//
// class CourseRepository {
//   final SupabaseService supabaseService;
//   final CourseDAO courseDAO;
//
//   CourseRepository({
//     required this.supabaseService,
//     required this.courseDAO,
//   });
//
//   /// ✅ Check internet connectivity
//   Future<bool> _isConnected() async {
//     final connectivityResult = await Connectivity().checkConnectivity();
//     return connectivityResult != ConnectivityResult.none;
//   }
//
//   /// ✅ Add a course (local first, then online if connected)
//   Future<void> addCourse(CourseModel course) async {
//     await courseDAO.insertCourse(course);
//     if (await _isConnected()) {
//       try {
//         await supabaseService.createCourse(course);
//       } catch (e) {
//         print('Failed to add course online: $e');
//       }
//     }
//   }
//
//   /// ✅ Get all courses (online if connected, else local)
//   Future<List<CourseModel>> getCourses() async {
//     if (await _isConnected()) {
//       try {
//         return await supabaseService.fetchCourses();
//       } catch (e) {
//         print('Failed to fetch online courses: $e');
//         return await courseDAO.getAllCourses();
//       }
//     } else {
//       return await courseDAO.getAllCourses();
//     }
//   }
//
//   /// ✅ Get courses by userId
//   Future<List<CourseModel>> getCoursesByUserId(String userId) async {
//     if (await _isConnected()) {
//       try {
//         return await supabaseService.fetchCoursesByUserId(userId);
//       } catch (e) {
//         print('Failed to fetch courses by userId online: $e');
//         return [];
//       }
//     } else {
//       // Optional: If local DB had userId info — fetch from local too
//       return [];
//     }
//   }
//
//   /// ✅ Get single course by uniqueId
//   Future<CourseModel?> getCourseByUniqueId(String uniqueId) async {
//     if (await _isConnected()) {
//       try {
//         return await supabaseService.fetchCourseByUniqueId(uniqueId);
//       } catch (e) {
//         print('Failed to fetch course by uniqueId online: $e');
//         return null;
//       }
//     } else {
//       // Optional: If local DB had uniqueId info — fetch from local too
//       return null;
//     }
//   }
//
//   /// ✅ Update course (local first, then online)
//   Future<void> updateCourse(CourseModel course) async {
//     await courseDAO.updateCourse(course);
//     if (await _isConnected()) {
//       try {
//         await supabaseService.updateCourse(course);
//       } catch (e) {
//         print('Failed to update course online: $e');
//       }
//     }
//   }
//
//   /// ✅ Delete course (local first, then online)
//   Future<void> deleteCourse(int id) async {
//     await courseDAO.deleteCourse(id);
//     if (await _isConnected()) {
//       try {
//         await supabaseService.deleteCourse(id);
//       } catch (e) {
//         print('Failed to delete course online: $e');
//       }
//     }
//   }
// }



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
