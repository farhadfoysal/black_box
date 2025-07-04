import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../components/components.dart';
import '../../model/course/video_course.dart';

class MyCoursesPage extends StatelessWidget {
  const MyCoursesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: fetch actual enrolled courses
    final courses = <VideoCourse>[];

    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      body: courses.isEmpty
          ? const Center(child: Text('No enrolled courses yet.'))
          : ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, i) {
          final c = courses[i];
          return VideoCourseCard(
            item: c,
            onPressed: () {
              // Navigate to course detail
            },
          );
        },
      ),
    );
  }
}
