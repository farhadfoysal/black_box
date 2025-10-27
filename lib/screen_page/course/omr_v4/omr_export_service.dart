// import 'dart:io';
// import 'dart:typed_data';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:share_plus/share_plus.dart';
// import 'dart:convert';
//
// import 'omr_enhanced_service.dart';
//
// class OMRExportService {
//   Future<File> exportToJSON(EnhancedOMRResult result, String fileName) async {
//     final data = {
//       'scanDate': DateTime.now().toIso8601String(),
//       'sheetType': result.detectedSheetType.toString(),
//       'isValid': result.isValid,
//       'overallConfidence': result.overallConfidence,
//       'studentInfo': {
//         'studentId': result.studentInfo.studentId,
//         'rollNumber': result.studentInfo.rollNumber,
//         'mobileNumber': result.studentInfo.mobileNumber,
//         'setNumber': result.studentInfo.setNumber,
//       },
//       'answers': result.answers.map((a) => {
//         'questionNumber': a.questionNumber,
//         'selectedOption': a.selectedOption,
//         'isMultipleMarked': a.isMultipleMarked,
//         'confidence': a.confidence,
//         'detectedOptions': a.detectedOptions,
//       }).toList(),
//       'summary': {
//         'totalQuestions': result.answers.length,
//         'answered': result.answers.where((a) => a.selectedOption != null).length,
//         'unanswered': result.unansweredQuestions.length,
//         'multipleMarked': result.multipleMarkedQuestions.length,
//         'lowConfidence': result.lowConfidenceQuestions.length,
//       },
//       'diagnostics': result.diagnostics,
//     };
//
//     final jsonString = JsonEncoder.withIndent('  ').convert(data);
//     final directory = await getApplicationDocumentsDirectory();
//     final file = File('${directory.path}/$fileName.json');
//     await file.writeAsString(jsonString);
//     return file;
//   }
//
//   Future<File> exportToCSV(EnhancedOMRResult result, String fileName) async {
//     final buffer = StringBuffer();
//     buffer.writeln('Question,Answer,Confidence,Status');
//
//     for (final answer in result.answers) {
//       String status;
//       if (answer.isMultipleMarked) {
//         status = 'Multiple';
//       } else if (answer.selectedOption == null) {
//         status = 'Unanswered';
//       } else {
//         status = 'Answered';
//       }
//
//       buffer.writeln(
//           '${answer.questionNumber},'
//               '${answer.selectedOption ?? ""},'
//               '${answer.confidence.toStringAsFixed(2)},'
//               '$status'
//       );
//     }
//
//     final directory = await getApplicationDocumentsDirectory();
//     final file = File('${directory.path}/$fileName.csv');
//     await file.writeAsString(buffer.toString());
//     return file;
//   }
//
//   Future<File> exportToPDF(EnhancedOMRResult result, String fileName) async {
//     final pdf = pw.Document();
//
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) {
//           return [
//             pw.Header(
//               level: 0,
//               child: pw.Text(
//                 'OMR Scan Report',
//                 style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
//               ),
//             ),
//             pw.SizedBox(height: 20),
//             pw.Container(
//               padding: const pw.EdgeInsets.all(10),
//               decoration: pw.BoxDecoration(
//                 border: pw.Border.all(),
//                 borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
//               ),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(
//                     'Scan Information',
//                     style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
//                   ),
//                   pw.SizedBox(height: 10),
//                   _buildInfoRow('Date', DateTime.now().toString()),
//                   _buildInfoRow('Sheet Type', result.detectedSheetType.toString()),
//                   _buildInfoRow('Status', result.isValid ? 'Valid' : 'Invalid'),
//                   _buildInfoRow('Overall Confidence',
//                       '${(result.overallConfidence * 100).toStringAsFixed(1)}%'),
//                 ],
//               ),
//             ),
//             pw.SizedBox(height: 20),
//             pw.Container(
//               padding: const pw.EdgeInsets.all(10),
//               decoration: pw.BoxDecoration(
//                 border: pw.Border.all(),
//                 borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
//               ),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(
//                     'Student Information',
//                     style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
//                   ),
//                   pw.SizedBox(height: 10),
//                   _buildInfoRow('Student ID', result.studentInfo.studentId ?? 'N/A'),
//                   _buildInfoRow('Roll Number', result.studentInfo.rollNumber ?? 'N/A'),
//                   _buildInfoRow('Mobile', result.studentInfo.mobileNumber ?? 'N/A'),
//                   _buildInfoRow('Set Number', result.studentInfo.setNumber ?? 'N/A'),
//                 ],
//               ),
//             ),
//             pw.SizedBox(height: 20),
//             pw.Container(
//               padding: const pw.EdgeInsets.all(10),
//               decoration: pw.BoxDecoration(
//                 border: pw.Border.all(),
//                 borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
//               ),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(
//                     'Answer Summary',
//                     style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
//                   ),
//                   pw.SizedBox(height: 10),
//                   pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
//                     children: [
//                       _buildStatBox('Total', result.answers.length.toString()),
//                       _buildStatBox('Answered',
//                           result.answers.where((a) => a.selectedOption != null).length.toString()),
//                       _buildStatBox('Unanswered',
//                           result.unansweredQuestions.length.toString()),
//                       _buildStatBox('Multiple',
//                           result.multipleMarkedQuestions.length.toString()),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             pw.SizedBox(height: 20),
//             pw.Text(
//               'Detailed Answers',
//               style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
//             ),
//             pw.SizedBox(height: 10),
//             pw.Table.fromTextArray(
//               headers: ['Q#', 'Answer', 'Confidence', 'Status'],
//               data: result.answers.map((answer) {
//                 String status;
//                 if (answer.isMultipleMarked) {
//                   status = 'Multiple';
//                 } else if (answer.selectedOption == null) {
//                   status = 'Unanswered';
//                 } else if (answer.confidence < 0.7) {
//                   status = 'Low Conf.';
//                 } else {
//                   status = 'OK';
//                 }
//
//                 return [
//                   answer.questionNumber.toString(),
//                   answer.selectedOption ?? '-',
//                   '${(answer.confidence * 100).toStringAsFixed(0)}%',
//                   status,
//                 ];
//               }).toList(),
//               cellAlignment: pw.Alignment.center,
//               headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//               headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
//               cellHeight: 25,
//               cellAlignments: {
//                 0: pw.Alignment.center,
//                 1: pw.Alignment.center,
//                 2: pw.Alignment.center,
//                 3: pw.Alignment.center,
//               },
//             ),
//           ];
//         },
//       ),
//     );
//
//     final directory = await getApplicationDocumentsDirectory();
//     final file = File('${directory.path}/$fileName.pdf');
//     await file.writeAsBytes(await pdf.save());
//     return file;
//   }
//
//   pw.Widget _buildInfoRow(String label, String value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.symmetric(vertical: 3),
//       child: pw.Row(
//         children: [
//           pw.SizedBox(
//             width: 120,
//             child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//           ),
//           pw.Text(value),
//         ],
//       ),
//     );
//   }
//
//   pw.Widget _buildStatBox(String label, String value) {
//     return pw.Container(
//       padding: const pw.EdgeInsets.all(10),
//       decoration: pw.BoxDecoration(
//         border: pw.Border.all(),
//         borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
//       ),
//       child: pw.Column(
//         children: [
//           pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
//           pw.SizedBox(height: 5),
//           pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
//         ],
//       ),
//     );
//   }
//
//   Future<void> shareResults(
//       EnhancedOMRResult result,
//       String format, {
//         String? customFileName,
//       }) async {
//     final fileName = customFileName ?? 'omr_result_${DateTime.now().millisecondsSinceEpoch}';
//
//     File? file;
//
//     switch (format.toLowerCase()) {
//       case 'json':
//         file = await exportToJSON(result, fileName);
//         break;
//       case 'csv':
//         file = await exportToCSV(result, fileName);
//         break;
//       case 'pdf':
//         file = await exportToPDF(result, fileName);
//         break;
//       default:
//         throw Exception('Unsupported format: $format');
//     }
//
//     await Share.shareXFiles(
//       [XFile(file.path)],
//       subject: 'OMR Scan Results',
//       text: 'OMR scan results for ${result.studentInfo.studentId ?? "Unknown Student"}',
//     );
//   }
//
//   String generateTextSummary(EnhancedOMRResult result) {
//     final buffer = StringBuffer();
//
//     buffer.writeln('=' * 50);
//     buffer.writeln('OMR SCAN REPORT');
//     buffer.writeln('=' * 50);
//     buffer.writeln();
//
//     buffer.writeln('Scan Date: ${DateTime.now()}');
//     buffer.writeln('Sheet Type: ${result.detectedSheetType}');
//     buffer.writeln('Status: ${result.isValid ? "Valid" : "Invalid"}');
//     buffer.writeln('Overall Confidence: ${(result.overallConfidence * 100).toStringAsFixed(1)}%');
//     buffer.writeln();
//
//     buffer.writeln('-' * 50);
//     buffer.writeln('STUDENT INFORMATION');
//     buffer.writeln('-' * 50);
//     buffer.writeln('Student ID: ${result.studentInfo.studentId ?? "N/A"}');
//     buffer.writeln('Roll Number: ${result.studentInfo.rollNumber ?? "N/A"}');
//     buffer.writeln('Mobile: ${result.studentInfo.mobileNumber ?? "N/A"}');
//     buffer.writeln('Set Number: ${result.studentInfo.setNumber ?? "N/A"}');
//     buffer.writeln();
//
//     buffer.writeln('-' * 50);
//     buffer.writeln('SUMMARY STATISTICS');
//     buffer.writeln('-' * 50);
//     buffer.writeln('Total Questions: ${result.answers.length}');
//     buffer.writeln('Answered: ${result.answers.where((a) => a.selectedOption != null).length}');
//     buffer.writeln('Unanswered: ${result.unansweredQuestions.length}');
//     buffer.writeln('Multiple Marked: ${result.multipleMarkedQuestions.length}');
//     buffer.writeln('Low Confidence: ${result.lowConfidenceQuestions.length}');
//     buffer.writeln();
//
//     if (result.unansweredQuestions.isNotEmpty) {
//       buffer.writeln('Unanswered Questions: ${result.unansweredQuestions.join(", ")}');
//       buffer.writeln();
//     }
//
//     if (result.multipleMarkedQuestions.isNotEmpty) {
//       buffer.writeln('Multiple Marked Questions: ${result.multipleMarkedQuestions.join(", ")}');
//       buffer.writeln();
//     }
//
//     buffer.writeln('-' * 50);
//     buffer.writeln('DETAILED ANSWERS');
//     buffer.writeln('-' * 50);
//
//     for (final answer in result.answers) {
//       String status;
//       if (answer.isMultipleMarked) {
//         status = '[MULTIPLE]';
//       } else if (answer.selectedOption == null) {
//         status = '[UNANSWERED]';
//       } else if (answer.confidence < 0.7) {
//         status = '[LOW CONF]';
//       } else {
//         status = '';
//       }
//
//       buffer.writeln(
//           'Q${answer.questionNumber.toString().padLeft(2, '0')}: '
//               '${answer.selectedOption?.padRight(2) ?? "--"} '
//               '(${(answer.confidence * 100).toStringAsFixed(0).padLeft(3)}%) '
//               '$status'
//       );
//     }
//
//     buffer.writeln();
//     buffer.writeln('=' * 50);
//
//     return buffer.toString();
//   }
// }
//
// class OMRBatchProcessor {
//   final EnhancedOMRScannerService scanner;
//   final OMRExportService exporter;
//
//   OMRBatchProcessor({
//     EnhancedOMRScannerService? scanner,
//     OMRExportService? exporter,
//   })  : scanner = scanner ?? EnhancedOMRScannerService(),
//         exporter = exporter ?? OMRExportService();
//
//   Future<List<EnhancedOMRResult>> processBatch(
//       List<Uint8List> images, {
//         void Function(int current, int total)? onProgress,
//       }) async {
//     final results = <EnhancedOMRResult>[];
//
//     for (int i = 0; i < images.length; i++) {
//       onProgress?.call(i + 1, images.length);
//
//       try {
//         final result = await scanner.processOMRSheet(images[i]);
//         results.add(result);
//       } catch (e) {
//         results.add(EnhancedOMRResult(
//           studentInfo: EnhancedStudentInfo(),
//           answers: [],
//           isValid: false,
//           errorMessage: 'Failed to process image ${i + 1}: $e',
//         ));
//       }
//     }
//
//     return results;
//   }
//
//   Future<File> exportBatchResults(List<EnhancedOMRResult> results, String format) async {
//     if (format.toLowerCase() == 'csv') {
//       return await _exportBatchToCSV(results);
//     } else if (format.toLowerCase() == 'json') {
//       return await _exportBatchToJSON(results);
//     } else {
//       throw Exception('Unsupported batch format: $format');
//     }
//   }
//
//   Future<File> _exportBatchToCSV(List<EnhancedOMRResult> results) async {
//     final buffer = StringBuffer();
//
//     buffer.writeln('StudentID,RollNo,SetNo,Q1,Q2,Q3,Q4,Q5,Q6,Q7,Q8,Q9,Q10,'
//         'Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,'
//         'Q21,Q22,Q23,Q24,Q25,Q26,Q27,Q28,Q29,Q30,'
//         'Q31,Q32,Q33,Q34,Q35,Q36,Q37,Q38,Q39,Q40,'
//         'TotalAnswered,Confidence,Status');
//
//     for (final result in results) {
//       final row = <String>[
//         result.studentInfo.studentId ?? '',
//         result.studentInfo.rollNumber ?? '',
//         result.studentInfo.setNumber ?? '',
//       ];
//
//       for (int i = 1; i <= 40; i++) {
//         final answer = result.answers.firstWhere(
//               (a) => a.questionNumber == i,
//           orElse: () => EnhancedAnswer(questionNumber: i),
//         );
//
//         if (answer.isMultipleMarked) {
//           row.add('MULTI');
//         } else {
//           row.add(answer.selectedOption ?? '');
//         }
//       }
//
//       row.add(result.answers.where((a) => a.selectedOption != null).length.toString());
//       row.add((result.overallConfidence * 100).toStringAsFixed(1));
//       row.add(result.isValid ? 'Valid' : 'Invalid');
//
//       buffer.writeln(row.join(','));
//     }
//
//     final directory = await getApplicationDocumentsDirectory();
//     final fileName = 'batch_results_${DateTime.now().millisecondsSinceEpoch}.csv';
//     final file = File('${directory.path}/$fileName');
//     await file.writeAsString(buffer.toString());
//     return file;
//   }
//
//   Future<File> _exportBatchToJSON(List<EnhancedOMRResult> results) async {
//     final data = {
//       'batchDate': DateTime.now().toIso8601String(),
//       'totalSheets': results.length,
//       'validSheets': results.where((r) => r.isValid).length,
//       'results': results.map((result) => {
//         'studentId': result.studentInfo.studentId,
//         'rollNumber': result.studentInfo.rollNumber,
//         'setNumber': result.studentInfo.setNumber,
//         'isValid': result.isValid,
//         'confidence': result.overallConfidence,
//         'answers': result.answersMap,
//         'summary': {
//           'answered': result.answers.where((a) => a.selectedOption != null).length,
//           'unanswered': result.unansweredQuestions.length,
//           'multipleMarked': result.multipleMarkedQuestions.length,
//         },
//       }).toList(),
//     };
//
//     final jsonString = JsonEncoder.withIndent('  ').convert(data);
//     final directory = await getApplicationDocumentsDirectory();
//     final fileName = 'batch_results_${DateTime.now().millisecondsSinceEpoch}.json';
//     final file = File('${directory.path}/$fileName');
//     await file.writeAsString(jsonString);
//     return file;
//   }
//
//   Map<String, dynamic> generateBatchStatistics(List<EnhancedOMRResult> results) {
//     final validResults = results.where((r) => r.isValid).toList();
//
//     if (validResults.isEmpty) {
//       return {'error': 'No valid results'};
//     }
//
//     final totalQuestions = validResults.first.answers.length;
//     final answerDistribution = <String, int>{};
//
//     for (int q = 1; q <= totalQuestions; q++) {
//       for (final option in ['A', 'B', 'C', 'D']) {
//         final count = validResults.where((r) {
//           final answer = r.answers.firstWhere(
//                 (a) => a.questionNumber == q,
//             orElse: () => EnhancedAnswer(questionNumber: q),
//           );
//           return answer.selectedOption == option;
//         }).length;
//
//         answerDistribution['Q$q-$option'] = count;
//       }
//     }
//
//     return {
//       'totalSheets': results.length,
//       'validSheets': validResults.length,
//       'invalidSheets': results.length - validResults.length,
//       'averageConfidence': validResults.isEmpty
//           ? 0.0
//           : validResults.map((r) => r.overallConfidence).reduce((a, b) => a + b) / validResults.length,
//       'averageAnswered': validResults.isEmpty
//           ? 0.0
//           : validResults.map((r) => r.answers.where((a) => a.selectedOption != null).length)
//           .reduce((a, b) => a + b) / validResults.length,
//       'answerDistribution': answerDistribution,
//     };
//   }
// }