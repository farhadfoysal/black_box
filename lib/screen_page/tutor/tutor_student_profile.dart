import 'package:flutter/material.dart';

import '../../model/tutor/tutor_student.dart';

class TutorStudentProfile extends StatelessWidget {
  final TutorStudent student;

  TutorStudentProfile({required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${student.name}'s Profile"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                    student.img ?? 'https://via.placeholder.com/150',
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Name and Status
            Text(
              student.name ?? "Unknown",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Chip(
              label: Text(
                student.activeStatus == 1 ? "Active" : "Inactive",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor:
              student.activeStatus == 1 ? Colors.green : Colors.red,
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
                    value: student.phone ?? "N/A",
                  ),
                  InfoTile(
                    icon: Icons.person,
                    label: "Guardian Phone",
                    value: student.gaurdianPhone ?? "N/A",
                  ),
                  InfoTile(
                    icon: Icons.calendar_today,
                    label: "Date of Birth",
                    value: student.dob ?? "N/A",
                  ),
                  InfoTile(
                    icon: Icons.school,
                    label: "Education",
                    value: student.education ?? "N/A",
                  ),
                  InfoTile(
                    icon: Icons.home,
                    label: "Address",
                    value: student.address ?? "N/A",
                  ),
                  InfoTile(
                    icon: Icons.date_range,
                    label: "Admitted Date",
                    value: student.admittedDate?.toLocal().toString().split(' ')[0] ?? "N/A",
                  ),
                ],
              ),
            ),
            Divider(thickness: 1.5),

            // Weekdays
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Weekly Schedule",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  student.days != null && student.days!.isNotEmpty
                      ? ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: student.days!.length,
                    itemBuilder: (context, index) {
                      final day = student.days![index];
                      return ListTile(
                        leading: Icon(
                          Icons.calendar_today,
                          color: Colors.blueAccent,
                        ),
                        title: Text(day.day ?? "Unknown"),
                        subtitle: Text(
                            "Time: ${day.time} - "),
                      );
                    },
                  )
                      : Center(
                    child: Text(
                      "No schedule available",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
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
