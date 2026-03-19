// import 'package:black_box/model/course/enrollment.dart';
// import 'package:black_box/model/course/favorite.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../model/course/course_model.dart';
// import '../../model/course/video_lesson.dart';
//
// class SupabaseService {
//   static final SupabaseClient supabase = Supabase.instance.client;
//
//   static SupabaseClient get client => supabase;
//
//   // -----------------------
//   // 📌 COURSES
//   // -----------------------
//
//   Future<void> createCourse(CourseModel course) async {
//     await supabase.from('courses').insert(course.toJson());
//   }
//
//   Future<List<CourseModel>> fetchCourses() async {
//     final res = await supabase.from('courses').select();
//     return (res as List)
//         .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
//         .toList();
//   }
//
//   Future<int> updateCourse(CourseModel course) async {
//     if (course.id == null) {
//       throw ArgumentError('Course id cannot be null for update');
//     }
//     final res = await supabase
//         .from('courses')
//         .update(course.toJson())
//         .eq('id', course.id!)
//         .select();
//     return res.length;
//   }
//
//   Future<int> deleteCourse(int id) async {
//     final res = await supabase.from('courses').delete().eq('id', id).select();
//     return res.length;
//   }
//
//   Future<List<CourseModel>> fetchCoursesByUserId(String userId) async {
//     final res = await supabase.from('courses').select().eq('user_id', userId);
//     return (res as List)
//         .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
//         .toList();
//   }
//
//   Future<CourseModel?> fetchCourseByUniqueId(String uniqueId) async {
//     final res = await supabase
//         .from('courses')
//         .select()
//         .eq('unique_id', uniqueId)
//         .maybeSingle();
//
//     return res != null
//         ? CourseModel.fromJson(res as Map<String, dynamic>)
//         : null;
//   }
//
//   // -----------------------
//   // 📌 ENROLLMENTS
//   // -----------------------
//
//   Future<void> enrollCourse(Enrollment enrollment) async {
//     await supabase.from('course_enrollments').insert(enrollment.toMap());
//   }
//
//   Future<void> disenrollCourse(String userId, String courseId) async {
//     await supabase
//         .from('course_enrollments')
//         .delete()
//         .eq('user_id', userId)
//         .eq('course_id', courseId);
//   }
//
//   Future<List<String>> getEnrolledCourseIds(String userId) async {
//     final res = await supabase
//         .from('course_enrollments')
//         .select('course_id')
//         .eq('user_id', userId);
//
//     return (res as List).map((e) => e['course_id'].toString()).toList();
//   }
//
//   // -----------------------
//   // 📌 FAVORITES
//   // -----------------------
//
//   Future<void> favoriteCourse(Favorite favorite) async {
//     await supabase.from('course_favorites').insert(favorite.toMap());
//   }
//
//   Future<void> unfavoriteCourse(String userId, String courseId) async {
//     await supabase
//         .from('course_favorites')
//         .delete()
//         .eq('user_id', userId)
//         .eq('course_id', courseId);
//   }
//
//   Future<List<String>> getFavoriteCourseIds(String userId) async {
//     final res = await supabase
//         .from('course_favorites')
//         .select('course_id')
//         .eq('user_id', userId);
//
//     return (res as List).map((e) => e['course_id'].toString()).toList();
//   }
//
//   // -----------------------
//   // 📌 COURSE VIDEOS
//   // -----------------------
//
//   Future<void> addVideo(VideoLesson video) async {
//     await supabase.from('course_videos').insert(video.toMap());
//   }
//
//   Future<List<VideoLesson>> getVideosByCourseId(String courseId) async {
//     final res =
//     await supabase.from('course_videos').select().eq('course_id', courseId);
//
//     return (res as List)
//         .map((e) => VideoLesson.fromMap(e as Map<String, dynamic>))
//         .toList();
//   }
//
//   Future<void> deleteVideo(String videoId) async {
//     await supabase.from('course_videos').delete().eq('id', videoId);
//   }
// }



// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../model/course/course_model.dart';
//
// class SupabaseService {
//   final SupabaseClient supabase = Supabase.instance.client;
//
//   /// ✅ Create new course
//   Future<void> createCourse(CourseModel course) async {
//     await supabase.from('courses').insert(course.toJson());
//   }
//
//   /// ✅ Fetch all courses
//   Future<List<CourseModel>> fetchCourses() async {
//     final res = await supabase.from('courses').select();
//
//     return (res as List).map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
//   }
//
//   /// ✅ Update existing course (requires non-null id)
//   Future<int> updateCourse(CourseModel course) async {
//     if (course.id == null) {
//       throw ArgumentError('Course id cannot be null for update');
//     }
//
//     final res = await supabase
//         .from('courses')
//         .update(course.toJson())
//         .eq('id', course.id!)
//         .select(); // returns updated records list
//
//     return res.length;
//   }
//
//   /// ✅ Delete course by id (requires non-null id)
//   Future<int> deleteCourse(int id) async {
//     final res = await supabase
//         .from('courses')
//         .delete()
//         .eq('id', id)
//         .select(); // returns deleted records list
//
//     return res.length;
//   }
//
//   /// ✅ Fetch all courses by userId
//   Future<List<CourseModel>> fetchCoursesByUserId(String userId) async {
//     final res = await supabase.from('courses').select().eq('user_id', userId);
//
//     return (res as List).map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
//   }
//
//   /// ✅ Fetch a single course by uniqueId
//   Future<CourseModel?> fetchCourseByUniqueId(String uniqueId) async {
//     final res = await supabase
//         .from('courses')
//         .select()
//         .eq('unique_id', uniqueId)
//         .maybeSingle();
//
//     if (res != null) {
//       return CourseModel.fromJson(res as Map<String, dynamic>);
//     } else {
//       return null;
//     }
//   }
// }



// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../model/course/course_model.dart';
//
// class SupabaseService {
//   final SupabaseClient supabase = Supabase.instance.client;
//
//   /// ✅ Create new course
//   Future<void> createCourse(CourseModel course) async {
//     await supabase.from('courses').insert(course.toJson());
//   }
//
//   /// ✅ Fetch all courses
//   Future<List<CourseModel>> fetchCourses() async {
//     final res = await supabase.from('courses').select();
//
//     return (res as List).map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
//   }
//
//   /// ✅ Update existing course
//   Future<int> updateCourse(CourseModel course) async {
//     final res = await supabase
//         .from('courses')
//         .update(course.toJson())
//         .eq('id', course.id)
//         .execute();
//
//     return res.count ?? 0;
//   }
//
//   /// ✅ Delete course by id
//   Future<int> deleteCourse(int id) async {
//     final res = await supabase.from('courses').delete().eq('id', id).execute();
//     return res.count ?? 0;
//   }
//
//   /// ✅ Fetch all courses by userId
//   Future<List<CourseModel>> fetchCoursesByUserId(String userId) async {
//     final res = await supabase.from('courses').select().eq('user_id', userId);
//
//     return (res as List).map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
//   }
//
//   /// ✅ Fetch a single course by uniqueId
//   Future<CourseModel?> fetchCourseByUniqueId(String uniqueId) async {
//     final res = await supabase
//         .from('courses')
//         .select()
//         .eq('unique_id', uniqueId)
//         .limit(1)
//         .maybeSingle();
//
//     if (res != null) {
//       return CourseModel.fromJson(res as Map<String, dynamic>);
//     } else {
//       return null;
//     }
//   }
// }


// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../model/course/course_model.dart';
//
//
// class SupabaseService {
//   final supabase = Supabase.instance.client;
//
//   Future<void> createCourse(CourseModel course) async {
//     await supabase.from('courses').insert(course.toJson());
//   }
//
//   Future<List<CourseModel>> fetchCourses() async {
//     final res = await supabase.from('courses').select();
//     return (res as List).map((e) => CourseModel.fromJson(e)).toList();
//   }
//
//   Future<void> updateCourse(CourseModel course) async {
//     await supabase
//         .from('courses')
//         .update(course.toJson())
//         .eq('id', course.id as int);
//   }
//
//   Future<void> deleteCourse(int id) async {
//     await supabase.from('courses').delete().eq('id', id);
//   }
// }
