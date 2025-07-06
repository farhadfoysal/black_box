import 'course_model.dart';

extension CourseModelDbMapper on CourseModel {
  /// ✅ Map CourseModel to Map<String, dynamic> for Sqflite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unique_id': uniqueId,
      'user_id': userId,
      'course_name': courseName,
      'course_image': courseImage,
      'category': category?.name,
      'description': description,
      'total_video': totalVideo,
      'total_times': totalTime,
      'total_rating': totalRating,
      'fee': fee,
      'tracking_number': trackingNumber,
      'discount': discount,
      'level': level,
      'count_students': countStudents,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  /// ✅ Map Map<String, dynamic> to CourseModel for Sqflite
  static CourseModel fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] as int?,
      uniqueId: map['unique_id'],
      userId: map['user_id'],
      courseName: map['course_name'],
      courseImage: map['course_image'],
      category: map['category'],
      description: map['description'],
      totalVideo: map['total_video'],
      totalTime: map['total_times'],
      totalRating: (map['total_rating'] as num?)?.toDouble(),
      fee: (map['fee'] as num?)?.toDouble(),
      trackingNumber: map['tracking_number'],
      discount: (map['discount'] as num?)?.toDouble(),
      level: map['level'],
      countStudents: map['count_students'],
      createdAt: DateTime.parse(map['created_at']),
      status: map['status'],
    );
  }
}



// import 'course_model.dart';
//
//
// extension CourseModelDbMapper on CourseModel {
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'unique_id': uniqueId,
//       'user_id': userId,
//       'course_name': courseName,
//       'course_image': courseImage,
//       'category': category?.name,
//       'description': description,
//       'total_video': totalVideo,
//       'total_times': totalTime,
//       'total_rating': totalRating,
//       'level': level,
//       'count_students': countStudents,
//       'created_at': createdAt.toIso8601String(),
//       'status': status,
//     };
//   }
//
//   static CourseModel fromMap(Map<String, dynamic> map) {
//     return CourseModel(
//       id: map['id'] as int?,
//       uniqueId: map['unique_id'],
//       userId: map['user_id'],
//       courseName: map['course_name'],
//       courseImage: map['course_image'],
//       category: map['category'],
//       description: map['description'],
//       totalVideo: map['total_video'],
//       totalTime: map['total_times'],
//       totalRating: (map['total_rating'] as num?)?.toDouble(),
//       level: map['level'],
//       countStudents: map['count_students'],
//       createdAt: DateTime.parse(map['created_at']),
//       status: map['status'],
//     );
//   }
// }
