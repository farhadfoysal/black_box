import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import 'omr_result.dart';

class OMRProcessor {
  // Configuration
  final double qrSizePx = 420.0; // visual QR size used when rendering at high-res

  Future<OMRResult> processImageForOMR(Uint8List bytes, {required String anchorQrData}) async {
    // Parse QR payload
    String studentId = '';
    String phone = '';

    try {
      final parsed = json.decode(anchorQrData);
      studentId = parsed['studentId']?.toString() ?? '';
      phone = parsed['phone']?.toString() ?? '';
    } catch (_) {
      // Fallback: if anchor string is 'S123|017...' format
      if (anchorQrData.contains('|')) {
        final parts = anchorQrData.split('|');
        studentId = parts[0];
        phone = parts.length > 1 ? parts[1] : '';
      } else {
        studentId = anchorQrData;
      }
    }

    // Load image
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception("Invalid image bytes");
    }

    // Convert to grayscale
    final gray = img.grayscale(image);

    // Heuristic crop: top-left area for QR detection
    final int searchW = (gray.width * 0.5).toInt();
    final int searchH = (gray.height * 0.4).toInt();

    final rect = img.copyCrop(
      gray,
      x: 0,
      y: 0,
      width: searchW,
      height: searchH,
    );

    // Find densest square region
    final win = (searchW * 0.2).toInt();
    int bestX = 0, bestY = 0;
    double bestScore = -1;

    for (int y = 0; y <= rect.height - win; y += (win ~/ 6)) {
      for (int x = 0; x <= rect.width - win; x += (win ~/ 6)) {
        double sum = 0;
        for (int yy = y; yy < y + win; yy += 6) {
          for (int xx = x; xx < x + win; xx += 6) {
            final p = rect.getPixel(xx, yy);
            final l = img.getLuminance(p);
            sum += (255 - l);
          }
        }
        if (sum > bestScore) {
          bestScore = sum;
          bestX = x;
          bestY = y;
        }
      }
    }

    // Map back to original image coordinates
    final qrX = bestX;
    final qrY = bestY;
    final qrW = win;

    // Estimate bubble grid region
    final gridLeft = (qrX + qrW + 40).clamp(0, image.width - 1).toInt();
    final gridTop = (qrY + qrW + 24).clamp(0, image.height - 1).toInt();
    final gridWidth = (image.width - gridLeft - 40).clamp(20, image.width - gridLeft).toInt();
    final gridHeight = (image.height - gridTop - 60).clamp(20, image.height - gridTop).toInt();

    final gridCrop = img.copyCrop(
      gray,
      x: gridLeft,
      y: gridTop,
      width: gridWidth,
      height: gridHeight,
    );

    // Sample bubble grid: 5 columns, 4 options (A-D)
    const options = ['A', 'B', 'C', 'D'];
    const questionCount = 20;
    const cols = 5;
    final rows = (questionCount / cols).ceil();

    final cellW = gridCrop.width / cols;
    final cellH = gridCrop.height / rows;

    List<String?> answers = List<String?>.filled(questionCount, null);

    for (int q = 0; q < questionCount; q++) {
      final col = q % cols;
      final row = q ~/ cols;
      final baseX = (col * cellW).toInt();
      final baseY = (row * cellH).toInt();

      final startX = (baseX + cellW * 0.15).toInt();
      final startYOpt = (baseY + cellH * 0.35).toInt();
      final stepX = ((cellW - (cellW * 0.3)) / 4).toInt();

      double bestDark = -1;
      int bestIdx = -1;

      for (int o = 0; o < 4; o++) {
        final sx = (startX + o * stepX).clamp(0, gridCrop.width - 1).toInt();
        final sy = startYOpt.clamp(0, gridCrop.height - 1).toInt();

        int darkSum = 0;
        int samples = 0;

        for (int yy = sy - 6; yy <= sy + 6; yy += 3) {
          for (int xx = sx - 6; xx <= sx + 6; xx += 3) {
            final xcl = xx.clamp(0, gridCrop.width - 1).toInt();
            final ycl = yy.clamp(0, gridCrop.height - 1).toInt();
            final p = gridCrop.getPixel(xcl, ycl);
            final lum = img.getLuminance(p);
            darkSum += (255 - lum.toInt());
            samples++;
          }
        }


        final avgDark = darkSum / samples;
        if (avgDark > bestDark) {
          bestDark = avgDark;
          bestIdx = o;
        }
      }

      // Mark answer if sufficiently dark
      if (bestDark > 30 && bestIdx >= 0) {
        answers[q] = options[bestIdx];
      } else {
        answers[q] = null;
      }
    }

    return OMRResult(
      studentId: studentId,
      phone: phone,
      answers: answers,
    );
  }
}



// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:image/image.dart' as img;
//
// import 'omr_result.dart';
//
// class OMRProcessor {
//   // Configuration: positions are relative to the QR anchor box (we assume QR at top-left of tag)
//   // These values were chosen to match the TagPainter layout in generator, but real-world adjustments may be needed.
//   final double qrSizePx = 420.0; // visual QR size used when rendering at high-res
//
//   Future<OMRResult> processImageForOMR(Uint8List bytes, {required String anchorQrData}) async {
//     // Parse QR payload
//     String studentId = '';
//     String phone = '';
//     try {
//       final parsed = json.decode(anchorQrData);
//       studentId = parsed['studentId']?.toString() ?? '';
//       phone = parsed['phone']?.toString() ?? '';
//     } catch (_) {
//       // Fallback: if anchor string is 'S123|017...' format
//       if (anchorQrData.contains('|')) {
//         final parts = anchorQrData.split('|');
//         studentId = parts[0];
//         phone = parts.length > 1 ? parts[1] : '';
//       } else {
//         studentId = anchorQrData;
//       }
//     }
//
//     // Load image
//     final image = img.decodeImage(bytes)!;
//
//     // Convert to grayscale
//     final gray = img.grayscale(image);
//
//     // Heuristic crop: assume the tag occupies most of the image; locate QR by searching for a dense dark square in top-left area
//     final int searchW = (gray.width * 0.5).toInt();
//     final int searchH = (gray.height * 0.4).toInt();
//     final rect = img.copyCrop(gray, 0, 0, searchW, searchH);
//
//     // Find the densest square region (naive approach): sliding window compute average darkness
//     final win = (searchW * 0.2).toInt();
//     int bestX = 0, bestY = 0;
//     double bestScore = -1;
//     for (int y = 0; y <= rect.height - win; y += (win ~/ 6)) {
//       for (int x = 0; x <= rect.width - win; x += (win ~/ 6)) {
//         double sum = 0;
//         for (int yy = y; yy < y + win; yy += 6) {
//           for (int xx = x; xx < x + win; xx += 6) {
//             final p = rect.getPixel(xx, yy);
//             final l = img.getLuminance(p);
//             sum += (255 - l);
//           }
//         }
//         if (sum > bestScore) {
//           bestScore = sum;
//           bestX = x;
//           bestY = y;
//         }
//       }
//     }
//
//     // Map bestX,bestY back to original image coordinates
//     final qrX = bestX;
//     final qrY = bestY;
//     final qrW = win;
//
//     // Estimate bubble grid region relative to detected QR
//     // These offsets were tuned to match the generator layout - might need calibration for printed sizes.
//     final gridLeft = (qrX + qrW + 40).clamp(0, image.width - 1).toInt();
//     final gridTop = (qrY + qrW + 24).clamp(0, image.height - 1).toInt();
//     final gridWidth = (image.width - gridLeft - 40).clamp(20, image.width - gridLeft).toInt();
//     final gridHeight = (image.height - gridTop - 60).clamp(20, image.height - gridTop).toInt();
//
//     final gridCrop = img.copyCrop(gray, gridLeft, gridTop, gridWidth, gridHeight);
//
//     // Now sample bubble positions assuming layout: 5 cols, variable rows, options 4 (A-D)
//     const options = ['A', 'B', 'C', 'D'];
//     final questionCount = 20; // default — ideally encoded in QR or passed as param
//
//     final cols = 5;
//     final rows = (questionCount / cols).ceil();
//
//     // compute per-cell area
//     final cellW = gridCrop.width / cols;
//     final cellH = gridCrop.height / rows;
//
//     List<String?> answers = List<String?>.filled(questionCount, null);
//
//     for (int q = 0; q < questionCount; q++) {
//       final col = q % cols;
//       final row = q ~/ cols;
//       final baseX = (col * cellW).toInt();
//       final baseY = (row * cellH).toInt();
//
//       // sample 4 option centers horizontally
//       final startX = baseX + (cellW * 0.15).toInt();
//       final startYOpt = baseY + (cellH * 0.35).toInt();
//       final stepX = ((cellW - (cellW * 0.3)) / 4).toInt();
//
//       double bestDark = -1;
//       int bestIdx = -1;
//
//       for (int o = 0; o < 4; o++) {
//         final sx = (startX + o * stepX).clamp(0, gridCrop.width - 1).toInt();
//         final sy = startYOpt.clamp(0, gridCrop.height - 1).toInt();
//
//         // Sample small box around candidate
//         int darkSum = 0;
//         int samples = 0;
//         for (int yy = sy - 6; yy <= sy + 6; yy += 3) {
//           for (int xx = sx - 6; xx <= sx + 6; xx += 3) {
//             final xcl = xx.clamp(0, gridCrop.width - 1);
//             final ycl = yy.clamp(0, gridCrop.height - 1);
//             final p = gridCrop.getPixel(xcl, ycl);
//             final lum = img.getLuminance(p);
//             darkSum += (255 - lum);
//             samples++;
//           }
//         }
//         final avgDark = darkSum / samples;
//         if (avgDark > bestDark) {
//           bestDark = avgDark;
//           bestIdx = o;
//         }
//       }
//
//       // Thresholding: if bestDark passes threshold, mark
//       if (bestDark > 30) {
//         answers[q] = options[bestIdx];
//       } else {
//         answers[q] = null;
//       }
//     }
//
//     // Return result
//     return OMRResult(studentId: studentId, phone: phone, answers: answers);
//   }
// }