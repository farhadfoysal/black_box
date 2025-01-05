import 'package:flutter/material.dart';

import '../../model/tutor/tutor_month.dart';
import '../../model/tutor/tutor_student.dart';
import '../../model/tutor/tutor_date.dart';

class TutorStudentDates extends StatefulWidget {
  final TutorStudent student;
  final TutorMonth month;

  TutorStudentDates({required this.student, required this.month});

  @override
  State<TutorStudentDates> createState() =>
      _TutorStudentDatesState();
}

class _TutorStudentDatesState extends State<TutorStudentDates> {
  @override
  void initState() {
    super.initState();
  }

  void _toggleAttendance(TutorDate date) {
    setState(() {
      date.attendance = date.attendance == 1 ? 0 : 1;  // Toggle attendance
      if (date.attendance == 0) {
        date.minutes = 0;  // Reset minutes if absent
      }
    });
  }

  void _setMinutes(TutorDate date, String minutes) {
    setState(() {
      date.minutes = int.tryParse(minutes) ?? 0;
    });
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
          widget.month.dates!.isNotEmpty
              ? ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.month.dates?.length,
            itemBuilder: (context, index) {
              final date = widget.month.dates?[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Date: ${date?.date ?? "N/A"}",
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Day: ${date?.day ?? "N/A"}",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => _toggleAttendance(date!),
                            child: Text(
                              "Attendance: ${date?.attendance == 1 ? 'Present' : 'Absent'}",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: date?.attendance == 1
                                      ? Colors.green
                                      : Colors.red),
                            ),
                          ),
                          SizedBox(height: 5),
                          if (date?.attendance == 1)
                            Row(
                              children: [
                                Text(
                                  "Minutes: ",
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700]),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  width: 50,
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: "Min",
                                      hintStyle: TextStyle(fontSize: 12),
                                    ),
                                    onChanged: (value) {
                                      _setMinutes(date, value);
                                    },
                                    controller: TextEditingController(
                                        text: date!.minutes! > 0
                                            ? date.minutes.toString()
                                            : ""),
                                  ),
                                ),
                              ],
                            ),
                          if (date?.attendance == 0)
                            Text(
                              "Attended Time: N/A",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700]),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          )
              : Center(
            child: Text(
              "No dates available for this month",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
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



// import 'package:flutter/material.dart';
//
// import '../../model/tutor/tutor_month.dart';
// import '../../model/tutor/tutor_student.dart';
// import '../../model/tutor/tutor_date.dart';
//
// class TutorStudentMonthlyDates extends StatefulWidget {
//   final TutorStudent student;
//   final TutorMonth month;
//
//   TutorStudentMonthlyDates({required this.student, required this.month});
//
//   @override
//   State<TutorStudentMonthlyDates> createState() =>
//       _TutorStudentMonthlyDatesState();
// }
//
// class _TutorStudentMonthlyDatesState extends State<TutorStudentMonthlyDates> {
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   Widget _buildProfileSection() {
//     return Column(
//       children: [
//         // Profile Picture and Name
//         Stack(
//           alignment: Alignment.bottomCenter,
//           children: [
//             Container(
//               height: 200,
//               color: Colors.blueAccent,
//             ),
//             CircleAvatar(
//               radius: 60,
//               backgroundImage: NetworkImage(
//                 widget.student.img ?? 'https://via.placeholder.com/150',
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: 20),
//
//         // Name and Status
//         Text(
//           widget.student.name ?? "Unknown",
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 10),
//         Chip(
//           label: Text(
//             widget.student.activeStatus == 1 ? "Active" : "Inactive",
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: widget.student.activeStatus == 1
//               ? Colors.green
//               : Colors.red,
//         ),
//         SizedBox(height: 20),
//
//         // Personal Information
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               InfoTile(
//                 icon: Icons.phone,
//                 label: "Phone",
//                 value: widget.student.phone ?? "N/A",
//               ),
//               InfoTile(
//                 icon: Icons.person,
//                 label: "Guardian Phone",
//                 value: widget.student.gaurdianPhone ?? "N/A",
//               ),
//               InfoTile(
//                 icon: Icons.calendar_today,
//                 label: "Date of Birth",
//                 value: widget.student.dob ?? "N/A",
//               ),
//               InfoTile(
//                 icon: Icons.school,
//                 label: "Education",
//                 value: widget.student.education ?? "N/A",
//               ),
//               InfoTile(
//                 icon: Icons.home,
//                 label: "Address",
//                 value: widget.student.address ?? "N/A",
//               ),
//               InfoTile(
//                 icon: Icons.date_range,
//                 label: "Admitted Date",
//                 value: widget.student.admittedDate
//                     ?.toLocal()
//                     .toString()
//                     .split(' ')[0] ??
//                     "N/A",
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildMonthlySchedule() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Monthly Schedule",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 10),
//           widget.month.dates!.isNotEmpty
//               ? ListView.builder(
//             shrinkWrap: true,
//             physics: NeverScrollableScrollPhysics(),
//             itemCount: widget.month.dates?.length,
//             itemBuilder: (context, index) {
//               final date = widget.month.dates?[index];
//               return Card(
//                 margin: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             "Date: ${date?.date ?? "N/A"}",
//                             style: TextStyle(fontSize: 14),
//                           ),
//                           SizedBox(height: 5),
//                           Text(
//                             "Day: ${date?.day ?? "N/A"}",
//                             style: TextStyle(fontSize: 14),
//                           ),
//                         ],
//                       ),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Text(
//                             "Attendance: ${date?.attendance == 1 ? 'Present' : 'Absent'}",
//                             style: TextStyle(
//                                 fontSize: 14,
//                                 color: date?.attendance == 1
//                                     ? Colors.green
//                                     : Colors.red),
//                           ),
//                           SizedBox(height: 5),
//                           Text(
//                             "Attended Time: ${date?.attendance == 1 ? '${date?.minutes} min' : 'N/A'}",
//                             style: TextStyle(
//                                 fontSize: 14, color: Colors.grey[700]),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           )
//               : Center(
//             child: Text(
//               "No dates available for this month",
//               style: TextStyle(color: Colors.grey),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("${widget.student.name}'s Profile"),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             // Profile Section
//             _buildProfileSection(),
//
//             Divider(thickness: 1.5),
//
//             // Monthly Schedule Section
//             _buildMonthlySchedule(),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class InfoTile extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//
//   InfoTile({required this.icon, required this.label, required this.value});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.blueAccent),
//           SizedBox(width: 15),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//                 SizedBox(height: 5),
//                 Text(
//                   value,
//                   style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
