import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'omr_database_manager.dart';

class ExportManager {
  static Future<File> generatePDFReport(Exam exam, List<OMRResult> results) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('OMR Exam Report')),
              pw.Text('Exam: ${exam.name}'),
              pw.Text('Date: ${exam.date}'),
              pw.Text('Total Questions: ${exam.totalQuestions}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['Rank', 'Student ID', 'Score', 'Set', 'Mobile', 'Confidence'],
                  ...results.asMap().entries.map((e) {
                    final result = e.value;
                    return [
                      (e.key + 1).toString(),
                      result.studentId,
                      '${result.score.toStringAsFixed(2)}%',
                      result.setNumber.toString(),
                      result.mobileNumber ?? 'N/A',
                      '${(result.confidence * 100).toStringAsFixed(1)}%',
                    ];
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Add detailed results page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(level: 1, child: pw.Text('Detailed Results')),
              ...results.map((result) => _buildStudentDetail(result, exam)),
            ],
          );
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildStudentDetail(OMRResult result, Exam exam) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Student ID: ${result.studentId}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Score: ${result.score.toStringAsFixed(2)}%'),
          pw.Text('Answers:'),
          pw.Wrap(
            children: result.answers.asMap().entries.map((e) {
              final isCorrect = e.key < exam.correctAnswers.length &&
                  String.fromCharCode(e.value) == exam.correctAnswers[e.key];
              return pw.Container(
                margin: pw.EdgeInsets.all(2),
                padding: pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  color: isCorrect ? PdfColors.green : PdfColors.red,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(
                  'Q${e.key + 1}: ${String.fromCharCode(e.value)}',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 8),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static Future<File> exportToCSV(Exam exam, List<OMRResult> results) async {
    final List<List<dynamic>> csvData = [];

    // Header
    csvData.add([
      'Rank',
      'Student ID',
      'Score',
      'Set Number',
      'Mobile Number',
      'Confidence',
      ...List.generate(exam.totalQuestions, (i) => 'Q${i + 1}'),
    ]);

    // Data
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      csvData.add([
        i + 1,
        result.studentId,
        result.score,
        result.setNumber,
        result.mobileNumber ?? '',
        result.confidence,
        ...result.answers.map((a) => String.fromCharCode(a)),
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/results_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvString);

    return file;
  }

  static Future<void> shareFile(File file, String subject) async {
    await Share.shareXFiles([XFile(file.path)], subject: subject);
  }
}