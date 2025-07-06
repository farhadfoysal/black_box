// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseModel _$CourseModelFromJson(Map<String, dynamic> json) => CourseModel(
  id: json['id'] as int?,
  uniqueId: json['unique_id'] as String?,
  userId: json['user_id'] as String?,
  courseName: json['course_name'] as String?,
  courseImage: json['course_image'] as String?,
  category: json['category'] as String?,
  description: json['description'] as String?,
  totalVideo: json['total_video'] as int?,
  totalTime: json['total_times'] as String?,
  totalRating: (json['total_rating'] as num?)?.toDouble(),
  fee: (json['fee'] as num?)?.toDouble(),
  trackingNumber: json['tracking_number'] as String?,
  discount: (json['discount'] as num?)?.toDouble(),
  sections: (json['sections'] as List<dynamic>?)
      ?.map((e) => Section.fromJson(e as Map<String, dynamic>))
      .toList(),
  reviews: (json['reviews'] as List<dynamic>?)
      ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
      .toList(),
  tools: (json['tools'] as List<dynamic>?)
      ?.map((e) => Tools.fromJson(e as Map<String, dynamic>))
      .toList(),
  level: json['level'] as String,
  countStudents: json['count_students'] as int,
  createdAt: DateTime.parse(json['created_at'] as String),
  status: json['status'] as String,
);

Map<String, dynamic> _$CourseModelToJson(CourseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'unique_id': instance.uniqueId,
      'user_id': instance.userId,
      'course_name': instance.courseName,
      'course_image': instance.courseImage,
      'category': instance.category,
      'description': instance.description,
      'total_video': instance.totalVideo,
      'total_times': instance.totalTime,
      'total_rating': instance.totalRating,
      'fee': instance.fee,
      'tracking_number': instance.trackingNumber,
      'discount': instance.discount,
      'sections': instance.sections,
      'reviews': instance.reviews,
      'tools': instance.tools,
      'level': instance.level,
      'count_students': instance.countStudents,
      'created_at': instance.createdAt?.toIso8601String(),
      'status': instance.status,
    };


// // GENERATED CODE - DO NOT MODIFY BY HAND
//
// part of 'course_model.dart';
//
// // **************************************************************************
// // JsonSerializableGenerator
// // **************************************************************************
//
// CourseModel _$CourseModelFromJson(Map<String, dynamic> json) => CourseModel(
//   id: json['id'] as int?,
//   uniqueId: json['unique_id'] as String?,
//   userId: json['user_id'] as String?,
//   courseName: json['course_name'] as String?,
//   courseImage: json['course_image'] as String?,
//   category: json['category'] == null
//       ? null
//       : Category.fromJson(json['category'] as Map<String, dynamic>),
//   description: json['description'] as String?,
//   totalVideo: json['total_video'] as int?,
//   totalTime: json['total_times'] as String?,
//   totalRating: (json['total_rating'] as num?)?.toDouble(),
//   sections: (json['sections'] as List<dynamic>?)
//       ?.map((e) => Section.fromJson(e as Map<String, dynamic>))
//       .toList(),
//   reviews: (json['reviews'] as List<dynamic>?)
//       ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
//       .toList(),
//   tools: (json['tools'] as List<dynamic>?)
//       ?.map((e) => Tools.fromJson(e as Map<String, dynamic>))
//       .toList(),
//   level: json['level'] as String,
//   countStudents: json['count_students'] as int,
//   createdAt: DateTime.parse(json['created_at'] as String),
//   status: json['status'] as String,
// );
//
// Map<String, dynamic> _$CourseModelToJson(CourseModel instance) =>
//     <String, dynamic>{
//       'id': instance.id,
//       'unique_id': instance.uniqueId,
//       'user_id': instance.userId,
//       'course_name': instance.courseName,
//       'course_image': instance.courseImage,
//       'category': instance.category,
//       'description': instance.description,
//       'total_video': instance.totalVideo,
//       'total_times': instance.totalTime,
//       'total_rating': instance.totalRating,
//       'sections': instance.sections,
//       'reviews': instance.reviews,
//       'tools': instance.tools,
//       'level': instance.level,
//       'count_students': instance.countStudents,
//       'created_at': instance.createdAt.toIso8601String(),
//       'status': instance.status,
//     };
