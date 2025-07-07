import 'package:black_box/model/course/course_model.dart';
import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  CourseModel courseModel;
  String courseImage;
  String courseName;
  String trackingNumber;
  String? mentorName;
  String totalVideo;
  String totalTime;
  double? rating;

  CourseCard(
      {Key? key,
        required this.courseModel,
        required this.courseImage,
        required this.courseName,
        required this.trackingNumber,
        this.mentorName,
        this.rating,
        required this.totalTime,
        required this.totalVideo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isAvailable = true;
    return Container(
      height: 116,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.blue,
              ),
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(
                      courseImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, Object exception, stackTrace) {
                        return Image.asset(
                          'assets/empty_image.png',
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white,
                      ),
                      width: 36,
                      height: 18,
                      child: FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            Text('$rating'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              width: 100,
              height: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      CircleAvatar(radius: 8),
                      SizedBox(width: 8),
                      Text(''),
                      // isAvailable ? mentorName! : '',
                    ],
                  ),
                  Row(
                    children: [
                      GreenChipWidget(
                        icon: Icons.timelapse,
                        label: totalTime,
                      ),
                      const SizedBox(width: 8),
                      GreenChipWidget(
                        icon: Icons.videocam,
                        label: '$totalVideo Video',
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            // Implement edit logic
                          } else if (value == 'share') {
                            // _makePhoneCall(student.phone??"");
                          } else if (value == 'mentor') {
                            // _openWhatsApp(student.phone??"");
                          } else if (value == 'delete') {

                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Confirm Deletion"),
                                content: Text("Are you sure you want to delete this Student?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      // await deleteStudentFromFirebaseAndOffline(student);
                                    },
                                    child: Text("Delete", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );


                          } else if (value == 'schedule') {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) =>
                            //         TutorStudentProfile(
                            //             student: student),
                            //   ),
                            // );

                          } else if (value == 'go') {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) =>
                            //         TutorStudentMonthly(
                            //             student: student),
                            //   ),
                            // );

                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'share',
                              child: Text('Share')),
                          const PopupMenuItem(
                              value: 'mentor',
                              child: Text('Mentor')),
                          const PopupMenuItem(
                              value: 'schedule',
                              child: Text('Schedule')),
                          const PopupMenuItem(
                              value: 'go',
                              child: Text('Attendance')),
                          const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit')),
                          const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GreenChipWidget extends StatelessWidget {
  GreenChipWidget({Key? key, required this.icon, required this.label})
      : super(key: key);

  IconData icon;
  String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: const Color(0xFFC3CFCE),
      ),
      width: 74,
      height: 20,
      child: FittedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 16),
            Text(label),
          ],
        ),
      ),
    );
  }
}