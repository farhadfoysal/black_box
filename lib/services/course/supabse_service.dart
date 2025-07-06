import 'package:supabase_flutter/supabase_flutter.dart';
import '../../model/course/course_model.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// ✅ Create new course
  Future<void> createCourse(CourseModel course) async {
    await supabase.from('courses').insert(course.toJson());
  }

  /// ✅ Fetch all courses
  Future<List<CourseModel>> fetchCourses() async {
    final res = await supabase.from('courses').select();

    return (res as List).map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// ✅ Update existing course (requires non-null id)
  Future<int> updateCourse(CourseModel course) async {
    if (course.id == null) {
      throw ArgumentError('Course id cannot be null for update');
    }

    final res = await supabase
        .from('courses')
        .update(course.toJson())
        .eq('id', course.id!)
        .select(); // returns updated records list

    return res.length;
  }

  /// ✅ Delete course by id (requires non-null id)
  Future<int> deleteCourse(int id) async {
    final res = await supabase
        .from('courses')
        .delete()
        .eq('id', id)
        .select(); // returns deleted records list

    return res.length;
  }

  /// ✅ Fetch all courses by userId
  Future<List<CourseModel>> fetchCoursesByUserId(String userId) async {
    final res = await supabase.from('courses').select().eq('user_id', userId);

    return (res as List).map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// ✅ Fetch a single course by uniqueId
  Future<CourseModel?> fetchCourseByUniqueId(String uniqueId) async {
    final res = await supabase
        .from('courses')
        .select()
        .eq('unique_id', uniqueId)
        .maybeSingle();

    if (res != null) {
      return CourseModel.fromJson(res as Map<String, dynamic>);
    } else {
      return null;
    }
  }
}



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
