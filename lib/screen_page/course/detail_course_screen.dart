import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../components/course/review_card.dart';
import '../../components/course/tools_card.dart';
import '../../model/course/course_model.dart';
import '../../style/color/app_color.dart';

class DetailCourseScreen extends StatefulWidget {
  final CourseModel course;
  const DetailCourseScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DetailCourseScreenState();
}


class DetailCourseScreenState extends State<DetailCourseScreen>{


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    CourseModel course = widget.course;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(250),
          child: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textLight),
            ),
            centerTitle: true,
            title: const Text(
              'Course Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textLight),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) =>
                  //         TutorStudentMonthly(
                  //             student: student),
                  //   ),
                  // );
                },
                icon: const Icon(Icons.dashboard_customize, color: AppColors.textLight),
                tooltip: 'Course Manager',
              ),
            ],
            flexibleSpace: Container(
              color: Colors.black54, // fallback background
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image with error handling
                  (course.courseImage != null && course.courseImage!.isNotEmpty)
                      ? Image.network(
                    course.courseImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/background.jpg',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                      : Image.asset(
                    'assets/background.jpg',
                    fit: BoxFit.cover,
                  ),

                  // Dark overlay
                  Container(
                    color: Colors.black.withOpacity(0.5),
                  ),

                  // Foreground content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      Text(
                        course.courseName ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          final firstVideoUrl = course.sections?.first.materials?.first.url ?? '';
                          final videoId = YoutubePlayer.convertUrlToId(firstVideoUrl);
                          if (videoId != null) {
                            showDialog(
                              context: context,
                              builder: (context) => SimpleDialog(
                                contentPadding: EdgeInsets.zero,
                                children: [
                                  SizedBox(
                                    height: 200,
                                    child: YoutubePlayer(
                                      controller: YoutubePlayerController(
                                        initialVideoId: videoId,
                                        flags: const YoutubePlayerFlags(autoPlay: true),
                                      ),
                                      bottomActions: const [
                                        CurrentPosition(),
                                        ProgressBar(isExpanded: true),
                                        RemainingDuration(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.play_circle_outline_outlined, color: AppColors.textLight),
                        label: const Text(
                          'Preview Course',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            bottom: const TabBar(
              indicatorColor: AppColors.textLight,
              labelColor: AppColors.textLight,
              unselectedLabelColor: AppColors.textMuted,
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'About'),
                Tab(text: 'Lessons'),
                Tab(text: 'Quiz'),
                Tab(text: 'Tools'),
                Tab(text: 'Reviews'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // About
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(
                course.description ?? 'No description available.',
                style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textPrimary),
              ),
            ),

            // Lessons
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: course.sections?.length ?? 0,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final sec = course.sections![index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sec.sectionName ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sec.materials?.length ?? 0,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, subIndex) {
                        final mat = sec.materials![subIndex];
                        final icon = switch (mat.materialType) {
                          'slide' => Icons.slideshow_rounded,
                          'quiz' => Icons.quiz_outlined,
                          _ => Icons.play_circle_fill_rounded,
                        };
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Icon(icon, color: AppColors.primary),
                            title: Text(
                              mat.materialName ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            // Quiz
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: course.tools?.length ?? 0,
              itemBuilder: (context, index) {
                final tool = course.tools![index];
                return ToolsCard(
                  toolsName: tool.toolsName,
                  imgUrl: tool.toolsIcon,
                  toolUrl: tool.url,
                );
              },
            ),

            // Tools
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: course.tools?.length ?? 0,
              itemBuilder: (context, index) {
                final tool = course.tools![index];
                return ToolsCard(
                  toolsName: tool.toolsName,
                  imgUrl: tool.toolsIcon,
                  toolUrl: tool.url,
                );
              },
            ),

            // Reviews
            GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: course.reviews?.length ?? 0,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final r = course.reviews![index];
                return ReviewCard(
                  img: 'https://via.placeholder.com/100',
                  title: r.user?.uname ?? 'Anonymous',
                  rating: r.rating ?? 0,
                  desc: r.review ?? '',
                );
              },
            ),
          ],
        ),
      ),
    );
  }


}

// import 'package:flutter/material.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
//
// import '../../components/course/review_card.dart';
// import '../../components/course/tools_card.dart';
// import '../../model/course/course_model.dart';
//
// class DetailCourseScreen extends StatelessWidget {
//   final CourseModel course;
//   const DetailCourseScreen({Key? key, required this.course}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 4,
//       child: Scaffold(
//         appBar: PreferredSize(
//           preferredSize: const Size.fromHeight(250),
//           child: AppBar(
//             leading: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 7),
//               child: CircleAvatar(
//                 backgroundColor: Colors.white30,
//                 child: IconButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   icon: const Icon(Icons.chevron_left_outlined, color: Colors.white),
//                 ),
//               ),
//             ),
//             centerTitle: true,
//             title: const Text('Details Course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             flexibleSpace: (course.courseImage != null && course.courseImage!.isNotEmpty)
//                 ? Container(
//               decoration: BoxDecoration(
//                 image: DecorationImage(
//                   image: NetworkImage(course.courseImage!),
//                   fit: BoxFit.cover,
//                   colorFilter: ColorFilter.mode(
//                     Colors.black.withOpacity(0.5),
//                     BlendMode.darken,
//                   ),
//                 ),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const SizedBox(height: 50),
//                   Text(course.courseName ?? '', style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 8),
//                   TextButton.icon(
//                     onPressed: () {
//                       final firstVideoUrl = course.sections?.first.materials?.first.url ?? '';
//                       final videoId = YoutubePlayer.convertUrlToId(firstVideoUrl);
//                       if (videoId != null) {
//                         showDialog(
//                           context: context,
//                           builder: (context) => SimpleDialog(
//                             contentPadding: EdgeInsets.zero,
//                             children: [
//                               SizedBox(
//                                 height: 200,
//                                 child: YoutubePlayer(
//                                   controller: YoutubePlayerController(
//                                     initialVideoId: videoId,
//                                     flags: const YoutubePlayerFlags(autoPlay: true),
//                                   ),
//                                   bottomActions: const [
//                                     CurrentPosition(),
//                                     ProgressBar(isExpanded: true),
//                                     RemainingDuration(),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       }
//                     },
//                     icon: const Icon(Icons.play_circle_outline_outlined, color: Colors.white),
//                     label: const Text('Preview Course', style: TextStyle(color: Colors.white)),
//                   ),
//                 ],
//               ),
//             )
//                 : null,
//             bottom: const TabBar(
//               indicatorColor: Colors.white,
//               labelColor: Colors.white,
//               tabs: [
//                 Tab(text: 'About'),
//                 Tab(text: 'Lesson'),
//                 Tab(text: 'Tools'),
//                 Tab(text: 'Reviews'),
//               ],
//             ),
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             SingleChildScrollView(
//               padding: const EdgeInsets.all(24),
//               child: Text(course.description ?? 'No description available.'),
//             ),
//             ListView.separated(
//               padding: const EdgeInsets.all(12),
//               itemCount: course.sections?.length ?? 0,
//               separatorBuilder: (_, __) => const SizedBox(height: 12),
//               itemBuilder: (context, index) {
//                 final sec = course.sections![index];
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(sec.sectionName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                     const SizedBox(height: 8),
//                     ListView.separated(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: sec.materials?.length ?? 0,
//                       separatorBuilder: (_, __) => const SizedBox(height: 6),
//                       itemBuilder: (context, subIndex) {
//                         final mat = sec.materials![subIndex];
//                         final icon = switch (mat.materialType) {
//                           'slide' => Icons.slideshow,
//                           'quiz' => Icons.quiz,
//                           _ => Icons.play_circle_fill,
//                         };
//                         return ListTile(
//                           tileColor: Colors.grey[200],
//                           leading: Icon(icon),
//                           title: Text(mat.materialName ?? ''),
//                         );
//                       },
//                     )
//                   ],
//                 );
//               },
//             ),
//             ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: course.tools?.length ?? 0,
//               itemBuilder: (context, index) {
//                 final tool = course.tools![index];
//                 return ToolsCard(
//                   toolsName: tool.toolsName,
//                   imgUrl: tool.toolsIcon,
//                   toolUrl: tool.url,
//                 );
//               },
//             ),
//             GridView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: course.reviews?.length ?? 0,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
//               itemBuilder: (context, index) {
//                 final r = course.reviews![index];
//                 return ReviewCard(
//                   img: 'https://via.placeholder.com/100',
//                   title: r.user?.uname ?? 'Anonymous',
//                   rating: r.rating ?? 0,
//                   desc: r.review ?? '',
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



// flexibleSpace: (course.courseImage != null && course.courseImage!.isNotEmpty)
// ? Container(
// decoration: BoxDecoration(
// image: DecorationImage(
// image: NetworkImage(course.courseImage!),
// errorBuilder: (context, Object exception, stackTrace) {
// return Image.asset(
// 'assets/empty_image.png',
// fit: BoxFit.cover,
// );
// },
// fit: BoxFit.cover,
// colorFilter: ColorFilter.mode(
// Colors.black.withOpacity(0.5),
// BlendMode.darken,
// ),
//
// ),
// ),
// child: Column(
// mainAxisAlignment: MainAxisAlignment.center,
// children: [
// const SizedBox(height: 50),
// Text(
// course.courseName ?? '',
// style: const TextStyle(
// fontSize: 24,
// color: AppColors.textLight,
// fontWeight: FontWeight.bold,
// ),
// textAlign: TextAlign.center,
// ),
// const SizedBox(height: 16),
// TextButton.icon(
// onPressed: () {
// final firstVideoUrl = course.sections?.first.materials?.first.url ?? '';
// final videoId = YoutubePlayer.convertUrlToId(firstVideoUrl);
// if (videoId != null) {
// showDialog(
// context: context,
// builder: (context) => SimpleDialog(
// contentPadding: EdgeInsets.zero,
// children: [
// SizedBox(
// height: 200,
// child: YoutubePlayer(
// controller: YoutubePlayerController(
// initialVideoId: videoId,
// flags: const YoutubePlayerFlags(autoPlay: true),
// ),
// bottomActions: const [
// CurrentPosition(),
// ProgressBar(isExpanded: true),
// RemainingDuration(),
// ],
// ),
// ),
// ],
// ),
// );
// }
// },
// icon: const Icon(Icons.play_circle_outline_outlined, color: AppColors.textLight),
// label: const Text(
// 'Preview Course',
// style: TextStyle(
// color: AppColors.textLight,
// fontWeight: FontWeight.w500,
// fontSize: 14,
// ),
// ),
// style: TextButton.styleFrom(
// foregroundColor: Colors.white,
// shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
// ),
// ),
// ],
// ),
// )
// : null,