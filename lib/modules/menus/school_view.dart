import 'dart:ffi';

import 'package:black_box/components/common/photo_avatar.dart';
import 'package:black_box/cores/cores.dart';
import 'package:black_box/model/user/user.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as b;
import 'package:flutter_svg/svg.dart';
import 'package:ionicons/ionicons.dart';

import '../../components/components.dart';
import '../../dummies/categories_d.dart';
import '../../dummies/video_courses_d.dart';
import '../../model/course/video_course.dart';

class SchoolView extends StatefulWidget {

  const SchoolView({super.key});

  @override
  State<StatefulWidget> createState() {
    return SchoolViewState();
  }
}

class SchoolViewState extends State<SchoolView> {
  late User user;
  final categories = <Category>[];
  final newCourses = <VideoCourse>[];
  final popularCourses = <VideoCourse>[];

  @override
  void initState() {
    loadData();
    super.initState();
  }

  Future<void> loadData() async {
    setState(() {
      user = User(
        uname: "Farhad Foysal",
        pass: '369725',
        phone: '01770627875',
      );
    });

    final now = DateTime.now();
    final categories = categoriesJSON.map((e) => Category.fromJson(e));
    final courses = videoCoursesJSON.map((e) => VideoCourse.fromJson(e));
    final newCourses = courses.where((e) => now.difference(e.createdAt).inDays < 17);
    final popularCourses = courses.where((e) => e.countStudents > 17000);

    this.categories
      ..clear()
      ..addAll(categories);
    this.newCourses
      ..clear()
      ..addAll(newCourses);
    this.popularCourses
      ..clear()
      ..addAll(popularCourses);

  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppPullRefresh(
        onRefresh: loadData,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 25, top: 6),
          children: [
            _ProfileHeader(user: user),
            _CategoriesListView(categories: categories),
            _NewCoursesListView(newCourses: newCourses),
            _PopularCoursesListView(popularCourses: popularCourses),
          ],
        ),
      ),
    );
  }

}

class _ProfileHeader extends StatelessWidget {
  final User user;
  const _ProfileHeader({required this.user});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0.0),
      child: Row(
        children: [
          XAvatarCircle(
            photoURL:
            "https://gratisography.com/wp-content/uploads/2024/11/gratisography-augmented-reality-800x525.jpg",
            membership: "U",
            progress: 60,
            color: context.themeD.primaryColor,
          ),
          Expanded(
              child: Padding(
                padding: EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.7),
                      child: Text(
                        "Courses",
                        style: p21.bold,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "Fihan Farique Wafi",
                        style: p14.bold.grey,
                      ),
                    )
                  ],
                ),
              )),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Icon(Icons.search_rounded,size: 40,),
            ),
          ),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: b.Badge(
                badgeStyle: b.BadgeStyle(
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                  badgeColor: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(13),
                  elevation: 0,
                ),
                badgeContent: Text("7",style: TextStyle(color: Colors.white,fontSize: 12)),
                child: Icon(Icons.notifications_outlined,size: 40,),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesListView extends StatelessWidget {
  const _CategoriesListView({
    required this.categories,
  });

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      height: 100, // You can adjust height based on your UI
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories
              .map(
                (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _MenuButton(
                onPressed: () {},
                title: item.name,
                imagePath: item.imagePath,
              ),
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}


// class _CategoriesListView extends StatelessWidget {
//   const _CategoriesListView({
//     required this.categories,
//   });
//
//   final List<Category> categories;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: categories
//             .map(
//               (item) => _MenuButton(
//             onPressed: () {},
//             title: item.name,
//             imagePath: item.imagePath,
//           ),
//         )
//             .toList(),
//       ),
//     );
//   }
// }

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.title,
    required this.imagePath,
    required this.onPressed,
  });

  final String title;
  final String imagePath;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const radius = 17.00;

    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            padding: const EdgeInsets.all(12),
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: const Color(0xFF94BFF8).withOpacity(0.3),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: SvgPicture.asset(
              imagePath,
              width: 50,
              height: 50,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 13.5),
          ),
        ),
      ],
    );
  }
}

class _NewCoursesListView extends StatelessWidget {
  const _NewCoursesListView({
    required this.newCourses,
  });

  final List<VideoCourse> newCourses;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SubHeader(
              title: 'New Courses',
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            width: context.screenWidth,
            child: ListView(
              primary: false,
              padding: const EdgeInsets.symmetric(horizontal: 13.0),
              scrollDirection: Axis.horizontal,
              children: newCourses
                  .map(
                    (item) => NewCourseCard(
                  onPressed: () {},
                  title: item.title,
                  countPlays: item.countPreviewVideoPlays,
                  imageUrl: item.imageUrl,
                ),
              )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularCoursesListView extends StatelessWidget {
  const _PopularCoursesListView({
    required this.popularCourses,
  });

  final List<VideoCourse> popularCourses;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 23),
      child: Column(
        children: [
          SubHeader(
            title: 'Popular Courses',
            onPressed: () {},
          ),
          const SizedBox(height: 20),
          ListView(
            primary: false,
            shrinkWrap: true,
            children: popularCourses
                .map(
                  (item) => VideoCourseCard(
                onPressed: () {},
                item: item,
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }
}