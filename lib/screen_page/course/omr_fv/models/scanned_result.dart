import 'dart:convert';

class ScannedResult {
  final String id;
  final String? studentId;
  final String? mobileNumber;
  final int? setNumber;
  final List<String> detectedAnswers; // A/B/C/D or ''
  final double confidence; // 0..1
  final String? errorMessage;

  String? syncKey;
  String? key;
  int? syncStatus;
  String? uniqueId;
  String? sId;
  String? sheetId;

  final DateTime createdAt;

  ScannedResult({
    required this.id,
    this.studentId,
    this.mobileNumber,
    this.setNumber,
    required this.detectedAnswers,
    required this.confidence,
    this.errorMessage,
    this.syncKey,
    this.key,
    this.syncStatus = 0,
    this.uniqueId,
    this.sId,
    this.sheetId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'mobileNumber': mobileNumber,
      'setNumber': setNumber,
      'detectedAnswers': jsonEncode(detectedAnswers),
      'confidence': confidence,
      'errorMessage': errorMessage,
      'syncKey': syncKey,
      'key': key,
      'syncStatus': syncStatus,
      'uniqueId': uniqueId,
      'sId': sId,
      'sheetId': sheetId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ScannedResult.fromMap(Map<String, dynamic> map) {
    return ScannedResult(
      id: map['id'],
      studentId: map['studentId'],
      mobileNumber: map['mobileNumber'],
      setNumber: map['setNumber'],
      detectedAnswers: List<String>.from(jsonDecode(map['detectedAnswers'])),
      confidence: map['confidence'],
      errorMessage: map['errorMessage'],
      syncKey: map['syncKey'],
      key: map['key'],
      syncStatus: map['syncStatus'],
      uniqueId: map['uniqueId'],
      sId: map['sId'],
      sheetId: map['sheetId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory ScannedResult.fromJson(Map<String, dynamic> json) =>
      ScannedResult.fromMap(json);

  ScannedResult copyWith({
    String? studentId,
    String? mobileNumber,
    int? setNumber,
    List<String>? detectedAnswers,
    double? confidence,
    String? errorMessage,
    int? syncStatus,
  }) {
    return ScannedResult(
      id: id,
      studentId: studentId ?? this.studentId,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      setNumber: setNumber ?? this.setNumber,
      detectedAnswers: detectedAnswers ?? this.detectedAnswers,
      confidence: confidence ?? this.confidence,
      errorMessage: errorMessage ?? this.errorMessage,
      syncKey: syncKey,
      key: key,
      syncStatus: syncStatus ?? this.syncStatus,
      uniqueId: uniqueId,
      sId: sId,
      sheetId: sheetId,
      createdAt: createdAt,
    );
  }
}