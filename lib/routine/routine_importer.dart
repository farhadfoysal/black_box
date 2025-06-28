import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'db_helper.dart';

class RoutineImporter {
  static Future<void> pickAndImportRoutine() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      await importExcelRoutine(file);
    }
  }

  static Future<void> importExcelRoutine(File file) async {
    var bytes = await file.readAsBytes();
    var excel = Excel.decodeBytes(bytes);

    var sheet = excel['Class Routine'];

    DatabaseHelper dbHelper = DatabaseHelper.instance;

    for (var row in sheet.rows.skip(3)) { // Skipping header rows
      if (row.length < 5) continue; // Ensure row has enough columns

      String? day = row[0]?.value?.toString();
      String? room = row[1]?.value?.toString();
      String? courseData = row[2]?.value?.toString();
      String? time = row[3]?.value?.toString();

      if (courseData != null && time != null) {
        List<String> parts = courseData.split(' ');
        if (parts.length > 1) {
          String courseCode = parts[0] + " " + parts[1]; // Extract "CSE 327.2"
          String instructor = parts.length > 2 ? parts[2] : "Unknown"; // Extract instructor if available

          await dbHelper.insertRoutine({
            'course_code': courseCode,
            'day': day ?? "Unknown",
            'room': room ?? "Unknown",
            'time': time,
            'instructor': instructor,
          });
        }
      }
    }
  }
}
