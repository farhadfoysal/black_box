import '../../db/attendance/attendance_database.dart';
import '../../model/attendance/attendance.dart';
import 'attendance_serevice.dart';

class AttendanceSync {
  static Future<void> sync(String courseId) async {
    final list = await AttendanceDatabase.unsynced();

    for (var m in list) {
      try {
        final a = Attendance.fromMap(m);

        await AttendanceService().save(courseId, a);

        await AttendanceDatabase.markSynced(a.uniqueId);
      } catch (e) {
        print("Sync error: $e");
      }
    }
  }
}