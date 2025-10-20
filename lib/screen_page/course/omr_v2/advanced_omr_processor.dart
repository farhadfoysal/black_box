import 'package:image/image.dart' as img;
import 'dart:math';

class AdvancedOMRProcessor {
  static const double BUBBLE_FILL_THRESHOLD = 0.6;

  /// Enhanced bubble detection with adaptive thresholding
  static BubbleDetectionResult detectBubbles(
      img.Image image, {
        required List<BubbleRegion> regions,
        bool useAdaptiveThreshold = true,
      }) {
    final result = BubbleDetectionResult();
    final grayImage = _preprocessImage(image);

    for (final region in regions) {
      final isFilled = _analyzeBubbleRegion(
        grayImage,
        region,
        useAdaptiveThreshold: useAdaptiveThreshold,
      );

      result.detectedBubbles.add(
        DetectedBubble(
          region: region,
          isFilled: isFilled,
          confidence: _calculateConfidence(grayImage, region),
        ),
      );
    }

    return result;
  }

  static img.Image _preprocessImage(img.Image image) {
    // Convert to grayscale
    img.Image processed = img.grayscale(image);

    // Apply Gaussian blur to reduce noise
    processed = img.gaussianBlur(processed, radius: 2);

    return processed;
  }

  static bool _analyzeBubbleRegion(
      img.Image image,
      BubbleRegion region, {
        bool useAdaptiveThreshold = true,
      }) {
    final bubblePixels = _extractBubblePixels(image, region);

    if (useAdaptiveThreshold) {
      return _adaptiveBubbleDetection(bubblePixels);
    } else {
      return _simpleBubbleDetection(bubblePixels);
    }
  }

  static List<PixelData> _extractBubblePixels(img.Image image, BubbleRegion region) {
    final pixels = <PixelData>[];
    final centerX = region.x + region.width ~/ 2;
    final centerY = region.y + region.height ~/ 2;
    final radius = min(region.width, region.height) ~/ 2;

    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        if (dx * dx + dy * dy <= radius * radius) {
          final x = centerX + dx;
          final y = centerY + dy;

          if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
            final pixel = image.getPixel(x, y);
            final luminance = img.getLuminance(pixel);
            pixels.add(PixelData(x: x, y: y, luminance: luminance));
          }
        }
      }
    }

    return pixels;
  }

  static bool _adaptiveBubbleDetection(List<PixelData> pixels) {
    if (pixels.isEmpty) return false;

    final threshold = _calculateOtsuThreshold(pixels);

    final darkPixels = pixels.where((p) => p.luminance < threshold).length;
    final fillRatio = darkPixels / pixels.length;

    final circularity = _calculateCircularity(pixels, threshold);

    return fillRatio > BUBBLE_FILL_THRESHOLD && circularity > 0.7;
  }

  static double _calculateOtsuThreshold(List<PixelData> pixels) {
    final histogram = List<int>.filled(256, 0);

    for (final pixel in pixels) {
      histogram[pixel.luminance.toInt()]++;
    }

    final total = pixels.length.toDouble();
    double sum = 0;
    for (int i = 0; i < 256; i++) sum += i * histogram[i];

    double sumB = 0;
    double wB = 0;
    double maxVariance = 0;
    double threshold = 0;

    for (int i = 0; i < 256; i++) {
      wB += histogram[i];
      if (wB == 0) continue;

      final wF = total - wB;
      if (wF == 0) break;

      sumB += i * histogram[i];
      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;

      final variance = wB * wF * (mB - mF) * (mB - mF);
      if (variance > maxVariance) {
        maxVariance = variance;
        threshold = i.toDouble();
      }
    }

    return threshold;
  }

  static double _calculateCircularity(List<PixelData> pixels, double threshold) {
    double centerX = 0, centerY = 0;
    int count = 0;

    for (final pixel in pixels) {
      if (pixel.luminance < threshold) {
        centerX += pixel.x;
        centerY += pixel.y;
        count++;
      }
    }

    if (count == 0) return 0.0;

    centerX /= count;
    centerY /= count;

    double avgDistance = 0;
    for (final pixel in pixels) {
      if (pixel.luminance < threshold) {
        avgDistance += sqrt(pow(pixel.x - centerX, 2) + pow(pixel.y - centerY, 2));
      }
    }
    avgDistance /= count;

    double variance = 0;
    for (final pixel in pixels) {
      if (pixel.luminance < threshold) {
        final distance = sqrt(pow(pixel.x - centerX, 2) + pow(pixel.y - centerY, 2));
        variance += pow(distance - avgDistance, 2);
      }
    }
    variance /= count;

    return avgDistance / (sqrt(variance) + 1e-5);
  }

  static double _calculateConfidence(img.Image image, BubbleRegion region) {
    final pixels = _extractBubblePixels(image, region);
    final threshold = _calculateOtsuThreshold(pixels);
    final darkPixels = pixels.where((p) => p.luminance < threshold).length;
    return fillRatio(darkPixels, pixels.length);
  }

  static bool _simpleBubbleDetection(List<PixelData> pixels) {
    if (pixels.isEmpty) return false;
    final avgLuminance = pixels.map((p) => p.luminance).reduce((a, b) => a + b) / pixels.length;
    final threshold = avgLuminance * 0.7;
    final darkPixels = pixels.where((p) => p.luminance < threshold).length;
    return fillRatio(darkPixels, pixels.length) > BUBBLE_FILL_THRESHOLD;
  }

  static double fillRatio(int darkPixels, int totalPixels) {
    return totalPixels == 0 ? 0.0 : darkPixels / totalPixels;
  }
}

class BubbleRegion {
  final int x, y, width, height;
  final String identifier;

  BubbleRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.identifier,
  });
}

class DetectedBubble {
  final BubbleRegion region;
  final bool isFilled;
  final double confidence;

  DetectedBubble({
    required this.region,
    required this.isFilled,
    required this.confidence,
  });
}

class BubbleDetectionResult {
  List<DetectedBubble> detectedBubbles = [];

  List<DetectedBubble> get filledBubbles =>
      detectedBubbles.where((bubble) => bubble.isFilled).toList();

  DetectedBubble? getBubbleByIdentifier(String identifier) {
    try {
      return detectedBubbles.firstWhere(
            (bubble) => bubble.region.identifier == identifier,
      );
    } catch (e) {
      // Not found
      return null;
    }
  }

}

class PixelData {
  final int x, y;
  final num luminance;

  PixelData({
    required this.x,
    required this.y,
    required this.luminance,
  });
}
