import 'package:black_box/screen_page/tutor/tutor_student_monthly_dates.dart';
import 'package:flutter/material.dart';

import '../../model/tutor/tutor_month.dart';
import '../../model/tutor/tutor_student.dart';
import '../../model/tutor/tutor_date.dart';

class TutorStudentMonth extends StatefulWidget {
  final TutorStudent student;

  TutorStudentMonth({required this.student});

  @override
  State<TutorStudentMonth> createState() => _TutorStudentMonthState();
}

class _TutorStudentMonthState extends State<TutorStudentMonth> {
  List<TutorMonth> tutorMonths = [];

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    setState(() {
      tutorMonths = [
        TutorMonth(
          id: 1,
          uniqueId: "20250101_123456",
          studentId: "STU123",
          userId: "TUTOR001",
          month: "January",
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 1, 31),
          paid: 1,
          dates: [
            TutorDate(
              id: 1,
              uniqueId: "20250101_123001",
              day: "Monday",
              date: "2025-01-01",
              dayDate: DateTime(2025, 1, 1),
              attendance: 1,
              minutes: 60,
            ),
            TutorDate(
              id: 2,
              uniqueId: "20250102_123002",
              day: "Wednesday",
              date: "2025-01-03",
              dayDate: DateTime(2025, 1, 3),
              attendance: 0,
              minutes: 0,
            ),
          ],
        ),
        TutorMonth(
          id: 2,
          uniqueId: "20250201_123457",
          studentId: "STU123",
          userId: "TUTOR001",
          month: "February",
          startDate: DateTime(2025, 2, 1),
          endDate: DateTime(2025, 2, 28),
          paid: 0,
          dates: [],
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.student.name}'s Profile"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Section
            _buildProfileSection(),

            Divider(thickness: 1.5),

            // Monthly Schedule Section
            _buildMonthlySchedule(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        // Profile Picture and Name
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 200,
              color: Colors.blueAccent,
            ),
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                widget.student.img ?? 'https://via.placeholder.com/150',
              ),
            ),
          ],
        ),
        SizedBox(height: 20),

        // Name and Status
        Text(
          widget.student.name ?? "Unknown",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Chip(
          label: Text(
            widget.student.activeStatus == 1 ? "Active" : "Inactive",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: widget.student.activeStatus == 1
              ? Colors.green
              : Colors.red,
        ),
        SizedBox(height: 20),

        // Personal Information
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoTile(
                icon: Icons.phone,
                label: "Phone",
                value: widget.student.phone ?? "N/A",
              ),
              InfoTile(
                icon: Icons.person,
                label: "Guardian Phone",
                value: widget.student.gaurdianPhone ?? "N/A",
              ),
              InfoTile(
                icon: Icons.calendar_today,
                label: "Date of Birth",
                value: widget.student.dob ?? "N/A",
              ),
              InfoTile(
                icon: Icons.school,
                label: "Education",
                value: widget.student.education ?? "N/A",
              ),
              InfoTile(
                icon: Icons.home,
                label: "Address",
                value: widget.student.address ?? "N/A",
              ),
              InfoTile(
                icon: Icons.date_range,
                label: "Admitted Date",
                value: widget.student.admittedDate
                    ?.toLocal()
                    .toString()
                    .split(' ')[0] ??
                    "N/A",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySchedule() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Monthly Schedule",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          tutorMonths.isNotEmpty
              ? ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: tutorMonths.length,
            itemBuilder: (context, index) {
              final month = tutorMonths[index];
              return GestureDetector(
                onTap: () {
                  // Navigate to TutorStudentMonthlyDates page with the selected month and student data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TutorStudentMonthlyDates(
                        student: widget.student,  // Passing the student data
                        month: month,              // Passing the selected month data
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Month: ${month.month ?? "N/A"}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Start Date: ${month.startDate?.toLocal().toString().split(' ')[0] ?? "N/A"}",
                        ),
                        Text(
                          "End Date: ${month.endDate?.toLocal().toString().split(' ')[0] ?? "N/A"}",
                        ),
                        Text(
                          "Paid: ${month.paid == 1 ? "Yes" : "No"}",
                        ),
                        if (month.dates != null && month.dates!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: month.dates!.map((date) {
                                return Text(
                                  "- ${date.day ?? "N/A"} (${date.date ?? "N/A"})",
                                  style: TextStyle(fontSize: 14),
                                );
                              }).toList(),
                            ),
                          )
                        else
                          Text(
                            "No specific dates available",
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )
              : Center(
            child: Text(
              "No monthly schedules available",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }


// Widget _buildMonthlySchedule() {
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           "Monthly Schedule",
  //           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //         ),
  //         SizedBox(height: 10),
  //         tutorMonths.isNotEmpty
  //             ? ListView.builder(
  //           shrinkWrap: true,
  //           physics: NeverScrollableScrollPhysics(),
  //           itemCount: tutorMonths.length,
  //           itemBuilder: (context, index) {
  //             final month = tutorMonths[index];
  //             return Card(
  //               margin: const EdgeInsets.symmetric(vertical: 8.0),
  //               child: Padding(
  //                 padding: const EdgeInsets.all(16.0),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       "Month: ${month.month ?? "N/A"}",
  //                       style: TextStyle(
  //                         fontSize: 16,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                     SizedBox(height: 5),
  //                     Text(
  //                       "Start Date: ${month.startDate?.toLocal().toString().split(' ')[0] ?? "N/A"}",
  //                     ),
  //                     Text(
  //                       "End Date: ${month.endDate?.toLocal().toString().split(' ')[0] ?? "N/A"}",
  //                     ),
  //                     Text(
  //                       "Paid: ${month.paid == 1 ? "Yes" : "No"}",
  //                     ),
  //                     if (month.dates != null && month.dates!.isNotEmpty)
  //                       Padding(
  //                         padding: const EdgeInsets.only(top: 8.0),
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: month.dates!.map((date) {
  //                             return Text(
  //                               "- ${date.day ?? "N/A"} (${date.date ?? "N/A"})",
  //                               style: TextStyle(fontSize: 14),
  //                             );
  //                           }).toList(),
  //                         ),
  //                       )
  //                     else
  //                       Text(
  //                         "No specific dates available",
  //                         style: TextStyle(color: Colors.grey),
  //                       ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         )
  //             : Center(
  //           child: Text(
  //             "No monthly schedules available",
  //             style: TextStyle(color: Colors.grey),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
