// ============================================================
// attendance_sync.dart
// ============================================================
//
// FIXES vs original
// -----------------
// 1. Was only syncing sync_status=0 (pending upserts).
//    Now also processes sync_status=2 (pending deletes) — FIX for the
//    bug where deleted records were never removed from Firestore.
//
// 2. autoSync() previously used a.sCourseId as the Firestore path,
//    which is correct IF the value is always populated. Added a guard
//    to skip rows with empty sCourseId.
//
// 3. After a confirmed remote delete, the local row is hard-deleted
//    instead of left as a zombie sync_status=2 record.
// ============================================================

import '../../db/attendance/attendance_database.dart';
import '../../model/attendance/attendance.dart';
import 'attendance_serevice.dart';

class AttendanceSync {
  const AttendanceSync._();

  /// Call this whenever connectivity is restored, or on app resume.
  static Future<void> sync(String courseId) async {
    await _pushUpserts(courseId);
    await _pushDeletes(courseId);
  }

  // ── push created / updated records ───────────────────────────
  static Future<void> _pushUpserts(String courseId) async {
    final pending = await AttendanceDatabase.pendingUpserts();

    for (final m in pending) {
      final a = Attendance.fromMap(m);

      // FIX 2: guard against empty sCourseId
      final cid = a.sCourseId.isNotEmpty ? a.sCourseId : courseId;
      if (cid.isEmpty) continue;

      try {
        await AttendanceService().save(cid, a);
        await AttendanceDatabase.markSynced(a.uniqueId);
      } catch (_) {
        // Leave sync_status=0 so it retries next time.
      }
    }
  }

  // ── push deletions ────────────────────────────────────────────
  // FIX 1 & 3: was entirely missing.
  static Future<void> _pushDeletes(String courseId) async {
    final pending = await AttendanceDatabase.pendingDeletes();

    for (final m in pending) {
      final a = Attendance.fromMap(m);
      final cid = a.sCourseId.isNotEmpty ? a.sCourseId : courseId;
      if (cid.isEmpty) continue;

      try {
        final ok = await AttendanceService().delete(cid, a.uniqueId);
        if (ok) {
          // FIX 3: physically remove the local row now that remote is clean.
          await AttendanceDatabase.hardDelete(a.uniqueId);
        }
      } catch (_) {
        // Leave sync_status=2; retry next cycle.
      }
    }
  }
}


// import '../../db/attendance/attendance_database.dart';
// import '../../model/attendance/attendance.dart';
// import 'attendance_serevice.dart';
//
// class AttendanceSync {
//   static Future<void> sync(String courseId) async {
//     final list = await AttendanceDatabase.unsynced();
//
//     for (var m in list) {
//       try {
//         final a = Attendance.fromMap(m);
//
//         await AttendanceService().save(courseId, a);
//
//         await AttendanceDatabase.markSynced(a.uniqueId);
//       } catch (e) {
//         print("Sync error: $e");
//       }
//     }
//   }
// }