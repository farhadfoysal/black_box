import 'package:black_box/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../model/course/video_course.dart';
import '../../components/components.dart';
import '../../components/course/course_card.dart';
import '../../model/course/course_model.dart';

class CoursesOfCategoryPage extends StatefulWidget {
  const CoursesOfCategoryPage({Key? key}) : super(key: key);

  @override
  State<CoursesOfCategoryPage> createState() => _CoursesOfCategoryPageState();
}

class _CoursesOfCategoryPageState extends State<CoursesOfCategoryPage> {
  late Category category;
  final TextEditingController controller = TextEditingController();

  final List<CourseModel> allCourses = [
    CourseModel(
      courseName: 'Flutter Beginner',
      totalVideo: 10,
      totalRating: 4.5,
      totalTime: '2h 30m',
      courseImage: 'https://fastly.picsum.photos/id/870/200/300.jpg?blur=2&grayscale&hmac=ujRymp644uYVjdKJM7kyLDSsrqNSMVRPnGU99cKl6Vs',
      level: 'Beginner',
      countStudents: 120,
      createdAt: DateTime.now(),
    ),
    CourseModel(
      courseName: 'Dart Fundamentals',
      totalVideo: 8,
      totalRating: 4.2,
      totalTime: '1h 50m',
      courseImage: 'https://fastly.picsum.photos/id/50/200/300.jpg?hmac=wlHRGoenBSt-gzxGvJp3cBEIUD71NKbWEXmiJC2mQYE',
      level: 'Beginner',
      countStudents: 95,
      createdAt: DateTime.now(),
    ),
    CourseModel(
      courseName: 'Mobile App Security',
      totalVideo: 7,
      totalRating: 4.8,
      totalTime: '3h 20m',
      courseImage: 'https://fastly.picsum.photos/id/443/200/300.jpg?grayscale&hmac=3KGsrU5Oo_hghp3-Xuzs6myA2cu1cKEvgsz05yWhKWA',
      level: 'Intermediate',
      countStudents: 80,
      createdAt: DateTime.now(),
    ),
    CourseModel(
      courseName: 'Backend Development',
      totalVideo: 12,
      totalRating: 4.7,
      totalTime: '2h 45m',
      // courseImage: 'https://fastly.picsum.photos/id/866/200/300.jpg?hmac=rcadCENKh4rD6MAp6V_ma-AyWv641M4iiOpe1RyFHeI',
      level: 'Intermediate',
      countStudents: 150,
      createdAt: DateTime.now(),
    ),
  ];


  List<CourseModel> filteredCourses = [];

  @override
  void initState() {
    super.initState();
    filteredCourses = List.from(allCourses);
  }

  void _searchCourses(String query) {
    final results = allCourses.where((course) {
      final courseName = course.courseName?.toLowerCase() ?? '';
      return courseName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredCourses = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    category = GoRouterState.of(context).extra as Category;

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
                hintText: 'Search course...',
              ),
              onChanged: _searchCourses,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredCourses.isEmpty
                  ? Center(
                child: Text(
                  'No courses found in ${category.name}',
                  style: const TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: filteredCourses.length,
                itemBuilder: (context, index) {
                  final course = filteredCourses[index];
                  return GestureDetector(
                    onTap: () async {
                      context.push(Routes.courseDetailPage, extra: course);
                    },
                    child: CourseCard(
                      courseImage: course.courseImage ?? '',
                      courseName: course.courseName ?? '',
                      rating: course.totalRating ?? 0,
                      totalTime: course.totalTime ?? '',
                      totalVideo: course.totalVideo?.toString() ?? '0',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
//
// import '../../components/components.dart';
// import '../../model/course/course_model.dart';
// import '../../model/course/video_course.dart';
//
// class CoursesOfCategoryPage extends StatelessWidget {
//   const CoursesOfCategoryPage({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final category = GoRouterState.of(context).extra as Category;
//
//     bool isEmpty = false;
//     TextEditingController controller = TextEditingController();
//
//     // final courses = <VideoCourse>[];
//
//     final List<CourseModel> allCourses = [
//       CourseModel(courseName: 'Flutter Beginner', totalVideo: 10),
//       CourseModel(courseName: 'Dart Fundamentals', totalVideo: 8),
//       CourseModel(courseName: 'Mobile App Security', totalVideo: 7),
//       CourseModel(courseName: 'Backend Development', totalVideo: 12),
//     ];
//
//     List<CourseModel> filteredCourses = [];
//
//
//
//     return Scaffold(
//       appBar: AppBar(title: Text(category.name)),
//       // body: courses.isEmpty
//       //     ? Center(child: Text('No courses found in ${category.name}'))
//       //     : ListView.builder(
//       //   itemCount: courses.length,
//       //   itemBuilder: (context, i) {
//       //     final c = courses[i];
//       //     return VideoCourseCard(
//       //       item: c,
//       //       onPressed: () {
//       //         // TODO: navigate to course preview or detail
//       //       },
//       //     );
//       //   },
//       // ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // const SearchBar(),
//             TextField(
//               controller: controller,
//               decoration: const InputDecoration(
//                 prefixIcon: Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.all(
//                     Radius.circular(20),
//                   ),
//                 ),
//                 hintText: 'Search course...',
//               ),
//               onChanged: (val) {
//
//               },
//             ),
//             const SizedBox(height: 8),
//
//             Expanded(
//               child: ListView.builder(
//                 physics: const BouncingScrollPhysics(),
//                 itemCount: course.allCourse?.length ?? 0,
//                 itemBuilder: (context, index) {
//                   return GestureDetector(
//                     onTap: () async {
//                       await Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => DetailCourseScreen(
//                             courseId: course.allCourse?[index],
//                           ),
//                         ),
//                       );
//                     },
//                     child: CourseCard(
//                       courseImage: course.allCourse?[index].courseImage ?? '',
//                       courseName: course.allCourse?[index].courseName ?? '',
//                       rating: course.allCourse?[index].totalRating ?? 0,
//                       totalTime: course.allCourse?[index].totalTime ?? '',
//                       totalVideo:
//                       course.allCourse?[index].totalVideo.toString() ?? '',
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
