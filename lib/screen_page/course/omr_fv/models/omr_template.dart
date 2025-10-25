// lib/omr/models/omr_template.dart
import 'dart:ui';

class RelativeRect {
  final double left, top, width, height;
  const RelativeRect(this.left, this.top, this.width, this.height);

  Rect toAbsolute(int imageWidth, int imageHeight) {
    final l = left * imageWidth;
    final t = top * imageHeight;
    final w = width * imageWidth;
    final h = height * imageHeight;
    return Rect.fromLTWH(l, t, w, h);
  }

  Map<String, double> toJson() => {
    'left': left,
    'top': top,
    'width': width,
    'height': height,
  };

  static RelativeRect fromJson(Map<String, dynamic> m) => RelativeRect(
    (m['left'] as num).toDouble(),
    (m['top'] as num).toDouble(),
    (m['width'] as num).toDouble(),
    (m['height'] as num).toDouble(),
  );
}

class OMRTemplate {
  final RelativeRect setRegion;
  final RelativeRect studentIdRegion;
  final RelativeRect mobileRegion;
  final RelativeRect answersRegion;
  final int questions;
  final int columns;
  final int optionsPerQuestion;

  const OMRTemplate({
    required this.setRegion,
    required this.studentIdRegion,
    required this.mobileRegion,
    required this.answersRegion,
    this.questions = 40,
    this.columns = 3,
    this.optionsPerQuestion = 4,
  });

  Map<String, dynamic> toJson() => {
    'setRegion': setRegion.toJson(),
    'studentIdRegion': studentIdRegion.toJson(),
    'mobileRegion': mobileRegion.toJson(),
    'answersRegion': answersRegion.toJson(),
    'questions': questions,
    'columns': columns,
    'optionsPerQuestion': optionsPerQuestion,
  };

  static OMRTemplate fromJson(Map<String, dynamic> m) => OMRTemplate(
    setRegion: RelativeRect.fromJson(Map<String, dynamic>.from(m['setRegion'])),
    studentIdRegion: RelativeRect.fromJson(Map<String, dynamic>.from(m['studentIdRegion'])),
    mobileRegion: RelativeRect.fromJson(Map<String, dynamic>.from(m['mobileRegion'])),
    answersRegion: RelativeRect.fromJson(Map<String, dynamic>.from(m['answersRegion'])),
    questions: (m['questions'] as num).toInt(),
    columns: (m['columns'] as num).toInt(),
    optionsPerQuestion: (m['optionsPerQuestion'] as num).toInt(),
  );

  /// Default relative mapping tuned to the sheet you provided; edit if needed.
  static const OMRTemplate defaultTemplate = OMRTemplate(
    setRegion: RelativeRect(0.18, 0.12, 0.64, 0.04),
    studentIdRegion: RelativeRect(0.04, 0.18, 0.48, 0.13),
    mobileRegion: RelativeRect(0.52, 0.18, 0.44, 0.13),
    answersRegion: RelativeRect(0.04, 0.36, 0.92, 0.45),
    questions: 40,
    columns: 3,
    optionsPerQuestion: 4,
  );
}






// // lib/omr/models/omr_template.dart
// import 'dart:ui';
//
// /// A template that maps logical OMR regions to relative coordinates (0..1).
// /// Each Rect is (left, top, width, height) in relative percentages.
// class RelativeRect {
//   final double left, top, width, height;
//   const RelativeRect(this.left, this.top, this.width, this.height);
//
//   Rect toAbsolute(int imageWidth, int imageHeight) {
//     final l = left * imageWidth;
//     final t = top * imageHeight;
//     final w = width * imageWidth;
//     final h = height * imageHeight;
//     return Rect.fromLTWH(l, t, w, h);
//   }
// }
//
// /// Template: all areas as relative rectangles (0..1)
// class OMRTemplate {
//   final RelativeRect setRegion; // area containing the 4 set bubbles horizontally
//   final RelativeRect studentIdRegion; // area containing student id grid (10 columns x 10 rows)
//   final RelativeRect mobileRegion; // area containing mobile number grid (11 columns x 10 rows)
//   final RelativeRect answersRegion; // big area containing all answers
//   final int questions; // total questions
//   final int columns; // number of answer columns (3 in example)
//   final int optionsPerQuestion; // typically 4 (A,B,C,D)
//
//   const OMRTemplate({
//     required this.setRegion,
//     required this.studentIdRegion,
//     required this.mobileRegion,
//     required this.answersRegion,
//     this.questions = 40,
//     this.columns = 3,
//     this.optionsPerQuestion = 4,
//   });
//
//   /// Default template tuned for the sheet you provided (may need small adjustments).
//   /// All values are relative (percent of image).
//   static const OMRTemplate defaultTemplate = OMRTemplate(
//     setRegion: RelativeRect(0.18, 0.12, 0.64, 0.04),
//     studentIdRegion: RelativeRect(0.04, 0.18, 0.48, 0.13),
//     mobileRegion: RelativeRect(0.52, 0.18, 0.44, 0.13),
//     answersRegion: RelativeRect(0.04, 0.36, 0.92, 0.45),
//     questions: 40,
//     columns: 3,
//     optionsPerQuestion: 4,
//   );
// }
