import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../db/attendance/attendance_database.dart';
import '../../../../model/attendance/attendance.dart';
import '../../../../model/attendance/monthly_report.dart';
import '../../../../services/attendance/attendance_serevice.dart';

class AdvancedMonthlyReportScreen extends StatefulWidget {
  final String courseId;

  const AdvancedMonthlyReportScreen({super.key, required this.courseId});

  @override
  State<AdvancedMonthlyReportScreen> createState() =>
      _AdvancedMonthlyReportScreenState();
}

class _AdvancedMonthlyReportScreenState
    extends State<AdvancedMonthlyReportScreen> {
  DateTime selectedMonth = DateTime.now();
  bool studentWise = true;
  bool loading = false;

  List<MonthlyReport> reports = [];

  Future<void> load() async {
    setState(() => loading = true);

    final month =
        "${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}";

    List<Attendance> data = [];

    try {
      // 🔥 Try online first
      data = await AttendanceService()
          .getByMonth(widget.courseId, month);
    } catch (_) {
      // 🔁 fallback to local
      final local =
      await AttendanceDatabase.getByDate("$month", widget.courseId);
      data = local.map((e) => Attendance.fromMap(e)).toList();
    }

    if (studentWise) {
      final map = buildStudentReport(data, {});
      reports = map.values.toList();

      // 🔥 sort by best attendance
      reports.sort((a, b) =>
          b.attendancePercent.compareTo(a.attendancePercent));
    } else {
      reports = [buildCourseReport(data)];
    }

    setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  MonthlyReport buildCourseReport(List<Attendance> list) {
    int total = list.length;
    int present = 0;
    int absent = 0;
    double marks = 0;

    for (var a in list) {
      if (a.status == 'P') present++;
      else absent++;

      marks += a.marks;
    }

    return MonthlyReport(
      id: "course",
      name: "Course Summary",
      totalClasses: total,
      present: present,
      absent: absent,
      attendancePercent: total == 0 ? 0 : (present / total) * 100,
      avgMarks: total == 0 ? 0 : marks / total,
    );
  }

  Map<String, MonthlyReport> buildStudentReport(
      List<Attendance> list,
      Map<String, String> studentNames) {

    final Map<String, MonthlyReport> report = {};

    for (var a in list) {
      final id = a.studentId;

      if (!report.containsKey(id)) {
        report[id] = MonthlyReport(
          id: id,
          name: studentNames[id] ?? "Unknown",
          totalClasses: 0,
          present: 0,
          absent: 0,
          attendancePercent: 0,
          avgMarks: 0,
        );
      }

      final r = report[id]!;

      r.totalClasses++;
      if (a.status == 'P') {
        r.present++;
      } else {
        r.absent++;
      }

      r.avgMarks += a.marks;
    }

    // finalize
    report.forEach((key, r) {
      if (r.totalClasses > 0) {
        r.attendancePercent =
            (r.present / r.totalClasses) * 100;
        r.avgMarks = r.avgMarks / r.totalClasses;
      }
    });

    return report;
  }

  Color getColor(double percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 60) return Colors.orange;
    return Colors.red;
  }

  String getPerformance(double percent) {
    if (percent >= 80) return "Excellent";
    if (percent >= 60) return "Average";
    return "Poor";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monthly Performance"),
        actions: [
          Row(
            children: [
              const Text("Student"),
              Switch(
                value: studentWise,
                onChanged: (v) {
                  studentWise = v;
                  load();
                },
              ),
            ],
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          ListTile(
            title: Text(
                "${selectedMonth.year}-${selectedMonth.month}"),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: selectedMonth,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );

              if (d != null) {
                selectedMonth = d;
                load();
              }
            },
          ),

          Expanded(
            child: ListView.builder(
              itemCount: reports.length,
              itemBuilder: (_, i) {
                final r = reports[i];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(r.name),

                    subtitle: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Attendance: ${r.attendancePercent.toStringAsFixed(1)}%"),

                        LinearProgressIndicator(
                          value: r.attendancePercent / 100,
                          color: getColor(r.attendancePercent),
                        ),

                        Text(
                            "Marks Avg: ${r.avgMarks.toStringAsFixed(1)}"),

                        Text(
                          getPerformance(r.attendancePercent),
                          style: TextStyle(
                            color: getColor(r.attendancePercent),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    trailing: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Text("P: ${r.present}"),
                        Text("A: ${r.absent}"),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}