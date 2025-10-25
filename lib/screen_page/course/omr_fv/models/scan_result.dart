// lib/omr/models/scan_result.dart
class ScanResult {
  final String? studentId;
  final String? mobileNumber;
  final int? setNumber;
  final List<String> detectedAnswers; // indexed 0..n-1 -> A/B/C/D or '' if none
  final double confidence; // 0..1
  final String? errorMessage;

  ScanResult({
    this.studentId,
    this.mobileNumber,
    this.setNumber,
    required this.detectedAnswers,
    required this.confidence,
    this.errorMessage,
  });
}
