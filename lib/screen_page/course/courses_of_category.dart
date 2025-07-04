import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../components/components.dart';
import '../../model/course/video_course.dart';

class CoursesOfCategoryPage extends StatelessWidget {
  const CoursesOfCategoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final category = GoRouterState.of(context).extra as Category;

    // TODO: fetch courses for this category
    final courses = <VideoCourse>[];

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: courses.isEmpty
          ? Center(child: Text('No courses found in ${category.name}'))
          : ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, i) {
          final c = courses[i];
          return VideoCourseCard(
            item: c,
            onPressed: () {
              // TODO: navigate to course preview or detail
            },
          );
        },
      ),
    );
  }
}
