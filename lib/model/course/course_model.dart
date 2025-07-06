import 'package:black_box/model/course/category.dart';
import 'package:json_annotation/json_annotation.dart';

import 'review_model.dart';
import 'section_model.dart';
import 'tools_model.dart';

part 'course_model.g.dart';

@JsonSerializable()
class CourseModel {
  int? id;

  @JsonKey(name: 'course_name')
  String? courseName;

  @JsonKey(name: 'course_image')
  String? courseImage;

  Category? category;
  String? description;

  @JsonKey(name: 'total_video')
  int? totalVideo;

  @JsonKey(name: 'total_times')
  String? totalTime;

  @JsonKey(name: 'total_rating')
  double? totalRating;

  List<Section>? sections;
  List<Review>? reviews;
  List<Tools>? tools;

  final String level;
  @JsonKey(name: 'count_students')
  final int countStudents;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  CourseModel({
    this.id,
    this.courseName,
    this.courseImage,
    this.category,
    this.description,
    this.totalVideo,
    this.totalTime,
    this.totalRating,
    this.sections,
    this.reviews,
    this.tools,
    required this.level,
    required this.countStudents,
    required this.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) =>
      _$CourseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CourseModelToJson(this);
}


// import 'package:black_box/model/course/category.dart';
// import 'package:json_annotation/json_annotation.dart';
//
// import 'review_model.dart';
// import 'section_model.dart';
// import 'tools_model.dart';
// part 'course_model.g.dart';
//
// @JsonSerializable()
// class CourseModel {
//   int? id;
//   @JsonKey(name: 'course_name')
//   String? courseName;
//   @JsonKey(name: 'course_image')
//   String? courseImage;
//   Category? category;
//   String? description;
//   @JsonKey(name: 'total_video')
//   int? totalVideo;
//   @JsonKey(name: 'total_times')
//   String? totalTime;
//   @JsonKey(name: 'total_rating')
//   double? totalRating;
//   List<Section>? sections;
//   List<Review>? reviews;
//   List<Tools>? tools;
//
//   final String level;
//   final int countStudents;
//   final DateTime createdAt;
//
//   CourseModel({
//     this.id,
//     this.courseName,
//     this.courseImage,
//     this.category,
//     this.description,
//     this.totalVideo,
//     this.totalTime,
//     this.totalRating,
//     this.sections,
//     this.reviews,
//     this.tools,
//   });
//
//   factory CourseModel.fromJson(Map<String, dynamic> json) =>
//       _$CourseModelFromJson(json);
//   Map<String, dynamic> toJson() => _$CourseModelToJson(this);
// }