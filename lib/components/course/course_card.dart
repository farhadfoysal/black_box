import 'package:barcode_widget/barcode_widget.dart';
import 'package:black_box/model/course/course.dart';
import 'package:black_box/model/course/course_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CourseCard extends StatefulWidget {
  CourseModel courseModel;
  String courseImage;
  String courseName;
  String trackingNumber;
  String? mentorName;
  String totalVideo;
  String totalTime;
  double? rating;
  final VoidCallback? onEnroll;
  final VoidCallback? onMark;

  CourseCard({
    Key? key,
    required this.courseModel,
    required this.courseImage,
    required this.courseName,
    required this.trackingNumber,
    this.mentorName,
    this.rating,
    required this.totalTime,
    required this.totalVideo,
    this.onEnroll,
    this.onMark,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => CourseCardState();
}

class CourseCardState extends State<CourseCard> {
  void copyCourseCode(CourseModel course) {
    String? tempNum = course.trackingNumber;

    if (tempNum != null && tempNum.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: tempNum)).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course Tracking Number copied: $tempNum')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to copy: $error')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No Tracking Number to copy')),
      );
    }
  }

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
                      widget.courseImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, Object exception, stackTrace) {
                        return Image.asset(
                          'assets/background.jpg',
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
                            Text('${widget.rating}'),
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
                    widget.courseName,
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
                        label: widget.totalTime,
                      ),
                      const SizedBox(width: 8),
                      GreenChipWidget(
                        icon: Icons.videocam,
                        label: "${widget.totalVideo}",
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'favourite') {
                            widget.onMark?.call();
                          } else if (value == 'copy') {
                            copyCourseCode(widget.courseModel);
                          } else if (value == 'share') {
                            shareCourse(widget.courseModel);
                          } else if (value == 'mentor') {
                            // _openWhatsApp(student.phone??"");
                          } else if (value == 'enroll') {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm'),
                                content: Text(
                                    'Are you sure you want to enroll "${widget.courseModel.courseName}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      widget.onEnroll?.call();
                                      Navigator.pop(context, true);
                                    },
                                    child: const Text(
                                      'Continue to Enroll',
                                      style: TextStyle(color: Colors.red),
                                    ),
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
                              value: 'copy', child: Text('Copy Trk')),
                          const PopupMenuItem(
                              value: 'share', child: Text('Share')),
                          const PopupMenuItem(
                              value: 'enroll', child: Text('Enroll')),
                          const PopupMenuItem(
                              value: 'schedule', child: Text('Schedule')),
                          const PopupMenuItem(
                              value: 'go', child: Text('Attendance')),
                          const PopupMenuItem(
                              value: 'mentor', child: Text('Mentor')),
                          const PopupMenuItem(
                              value: 'favourite', child: Text('Favourite')),
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

  void shareCourse(CourseModel course) {
    String? tempNum = course.trackingNumber;
    String? tempCode = course.uniqueId;

    if (tempNum != null && tempCode != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Share Course'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Barcode for Tracking Number:'),
                SizedBox(height: 10),
                BarcodeWidget(
                  barcode: Barcode.code128(), // Choose the barcode format
                  data: tempNum,
                  width: 200,
                  height: 100,
                ),
                SizedBox(height: 20),
                Text('QR Code for Course UniqueId:'),
                SizedBox(height: 10),
                BarcodeWidget(
                  barcode: Barcode.qrCode(), // QR code format
                  data: tempCode,
                  width: 200,
                  height: 200,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course data is incomplete for sharing')),
      );
    }
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
