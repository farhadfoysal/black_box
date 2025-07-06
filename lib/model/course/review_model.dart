import 'package:black_box/model/user/user.dart';

import 'package:json_annotation/json_annotation.dart';

import 'course_model.dart';
part 'review_model.g.dart';

@JsonSerializable()
class Review {
  int? id;
  double? rating;
  String? review;
  User? user;
  CourseModel? course;

  Review({
    required this.id,
    this.user,
    this.course,
    this.rating,
    this.review,
  });

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}