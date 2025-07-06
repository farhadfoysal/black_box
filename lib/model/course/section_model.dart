import 'package:json_annotation/json_annotation.dart';

import 'course_model.dart';
import 'materials_model.dart';
part 'section_model.g.dart';

@JsonSerializable()
class Section {
  int id;
  CourseModel? course;
  @JsonKey(name: 'section_name')
  String? sectionName;
  List<Materials>? materials;

  Section({
    required this.id,
    this.course,
    this.sectionName,
    this.materials
  });

  factory Section.fromJson(Map<String, dynamic> json) =>
      _$SectionFromJson(json);
  Map<String, dynamic> toJson() => _$SectionToJson(this);
}