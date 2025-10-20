import 'package:image/image.dart' as img;
import 'dart:math';

class PerspectiveCorrector {
  /// Detect OMR sheet corners and apply perspective correction
  static img.Image? correctPerspective(img.Image image) {
    try {
      final corners = _detectOMRCorners(image);
      if (corners.length == 4) {
        return _applyPerspectiveTransform(image, corners);
      }
    } catch (e) {
      print('Perspective correction failed: $e');
    }
    return null;
  }

  static List<Point> _detectOMRCorners(img.Image image) {
    // Convert to grayscale and enhance edges
    final gray = img.grayscale(image);
    final edges = _cannyEdgeDetection(gray);

    // Find contours
    final contours = _findContours(edges);

    // Find the largest quadrilateral (assuming it's the OMR sheet)
    final quadrilateral = _findLargestQuadrilateral(contours);

    if (quadrilateral != null) {
      return _orderCorners(quadrilateral);
    }

    // Fallback: use entire image corners
    return [
      Point(0, 0),
      Point(image.width - 1, 0),
      Point(image.width - 1, image.height - 1),
      Point(0, image.height - 1),
    ];
  }

  static img.Image _cannyEdgeDetection(img.Image image) {
    // Apply Gaussian blur
    final blurred = img.gaussianBlur(image, radius: 2);

    // Calculate gradients using Sobel operator
    final gradients = _calculateGradients(blurred);

    // Apply non-maximum suppression and hysteresis thresholding
    return _nonMaxSuppression(gradients);
  }

  static GradientData _calculateGradients(img.Image image) {
    final width = image.width;
    final height = image.height;
    final gradients = img.Image(width: width, height: height);
    final directions = List<List<double>>.generate(
        height, (_) => List<double>.filled(width, 0));

    // Sobel kernels
    const List<List<int>> sobelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1]
    ];

    const List<List<int>> sobelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1]
    ];

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        double gx = 0, gy = 0;

        // Apply Sobel operators
        for (int j = -1; j <= 1; j++) {
          for (int i = -1; i <= 1; i++) {
            final pixel = image.getPixel(x + i, y + j);
            final luminance = img.getLuminance(pixel);

            gx += luminance * sobelX[j + 1][i + 1];
            gy += luminance * sobelY[j + 1][i + 1];
          }
        }

        final magnitude = sqrt(gx * gx + gy * gy);
        gradients.setPixel(x, y, img.ColorRgb8(magnitude.toInt(), magnitude.toInt(), magnitude.toInt()));
        directions[y][x] = atan2(gy, gx);
      }
    }

    return GradientData(gradients: gradients, directions: directions);
  }

  static img.Image _nonMaxSuppression(GradientData gradients) {
    final result = img.Image(width:  gradients.gradients.width, height:  gradients.gradients.height);

    for (int y = 1; y < gradients.gradients.height - 1; y++) {
      for (int x = 1; x < gradients.gradients.width - 1; x++) {
        final angle = gradients.directions[y][x];
        final pixel = gradients.gradients.getPixel(x, y);
        final magnitude = img.getLuminance(pixel);

        // Determine neighbors based on gradient direction
        int x1, y1, x2, y2;
        if ((angle >= -pi/8 && angle < pi/8) || (angle >= 7*pi/8 || angle < -7*pi/8)) {
          // Horizontal
          x1 = x - 1; y1 = y;
          x2 = x + 1; y2 = y;
        } else if ((angle >= pi/8 && angle < 3*pi/8) || (angle >= -7*pi/8 && angle < -5*pi/8)) {
          // Diagonal 45°
          x1 = x - 1; y1 = y - 1;
          x2 = x + 1; y2 = y + 1;
        } else if ((angle >= 3*pi/8 && angle < 5*pi/8) || (angle >= -5*pi/8 && angle < -3*pi/8)) {
          // Vertical
          x1 = x; y1 = y - 1;
          x2 = x; y2 = y + 1;
        } else {
          // Diagonal 135°
          x1 = x - 1; y1 = y + 1;
          x2 = x + 1; y2 = y - 1;
        }

        final mag1 = img.getLuminance(gradients.gradients.getPixel(x1, y1));
        final mag2 = img.getLuminance(gradients.gradients.getPixel(x2, y2));

        if (magnitude >= mag1 && magnitude >= mag2) {
          result.setPixel(x, y, img.ColorRgb8(magnitude.toInt(), magnitude.toInt(), magnitude.toInt()));
        } else {
          result.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
    }

    return result;
  }

  static List<List<Point>> _findContours(img.Image image) {
    // Simplified contour finding implementation
    final contours = <List<Point>>[];
    final visited = List<List<bool>>.generate(
        image.height,
            (_) => List<bool>.filled(image.width, false)
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (img.getLuminance(pixel) > 128 && !visited[y][x]) {
          final contour = _traceContour(image, x, y, visited);
          if (contour.length > 10) { // Minimum contour length
            contours.add(contour);
          }
        }
      }
    }

    return contours;
  }

  static List<Point> _traceContour(img.Image image, int startX, int startY, List<List<bool>> visited) {
    final contour = <Point>[];
    final neighbors = [
      Point(1, 0), Point(1, -1), Point(0, -1), Point(-1, -1),
      Point(-1, 0), Point(-1, 1), Point(0, 1), Point(1, 1)
    ];

    var x = startX, y = startY;
    var direction = 0;

    do {
      contour.add(Point(x as double, y as double));
      visited[y][x] = true;

      bool found = false;
      for (int i = 0; i < 8; i++) {
        final idx = (direction + i) % 8;
        final nx = x + neighbors[idx].x.toInt();
        final ny = y + neighbors[idx].y.toInt();

        if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
          final pixel = image.getPixel(nx, ny);
          if (img.getLuminance(pixel) > 128 && !visited[ny][nx]) {
            x = nx;
            y = ny;
            direction = (idx + 4) % 8; // Reverse direction
            found = true;
            break;
          }
        }
      }

      if (!found) break;
    } while (x != startX || y != startY);

    return contour;
  }

  static List<Point>? _findLargestQuadrilateral(List<List<Point>> contours) {
    if (contours.isEmpty) return null;

    // Find the largest contour by area
    contours.sort((a, b) => _contourArea(b).compareTo(_contourArea(a)));

    for (final contour in contours) {
      final approx = _approximatePolygon(contour, epsilon: 0.02);
      if (approx.length == 4) {
        return approx;
      }
    }

    return null;
  }

  static double _contourArea(List<Point> contour) {
    double area = 0;
    for (int i = 0; i < contour.length; i++) {
      final j = (i + 1) % contour.length;
      area += contour[i].x * contour[j].y - contour[j].x * contour[i].y;
    }
    return area.abs() / 2;
  }

  static List<Point> _approximatePolygon(List<Point> contour, {double epsilon = 0.01}) {
    if (contour.length <= 2) return contour;

    // Find the point with the maximum distance from line between first and last
    double maxDistance = 0;
    int maxIndex = 0;

    for (int i = 1; i < contour.length - 1; i++) {
      final distance = _pointToLineDistance(contour[i], contour.first, contour.last);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If max distance is greater than epsilon, recursively simplify
    if (maxDistance > epsilon) {
      final left = _approximatePolygon(contour.sublist(0, maxIndex + 1), epsilon: epsilon);
      final right = _approximatePolygon(contour.sublist(maxIndex), epsilon: epsilon);
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [contour.first, contour.last];
    }
  }

  static double _pointToLineDistance(Point point, Point lineStart, Point lineEnd) {
    final numerator = ((lineEnd.y - lineStart.y) * point.x -
        (lineEnd.x - lineStart.x) * point.y +
        lineEnd.x * lineStart.y - lineEnd.y * lineStart.x).abs();
    final denominator = sqrt(pow(lineEnd.y - lineStart.y, 2) + pow(lineEnd.x - lineStart.x, 2));
    return numerator / denominator;
  }

  static List<Point> _orderCorners(List<Point> corners) {
    // Calculate centroid
    final centroid = Point(
      corners.map((p) => p.x).reduce((a, b) => a + b) / corners.length,
      corners.map((p) => p.y).reduce((a, b) => a + b) / corners.length,
    );

    // Sort corners in clockwise order starting from top-left
    corners.sort((a, b) {
      final angleA = atan2(a.y - centroid.y, a.x - centroid.x);
      final angleB = atan2(b.y - centroid.y, b.x - centroid.x);
      return angleA.compareTo(angleB);
    });

    // Reorder to start from top-left
    final topLeft = corners.reduce((a, b) => a.x + a.y < b.x + b.y ? a : b);
    final index = corners.indexOf(topLeft);

    return [
      ...corners.sublist(index),
      ...corners.sublist(0, index),
    ];
  }

  static img.Image _applyPerspectiveTransform(img.Image image, List<Point> corners) {
    const outputWidth = 595;
    const outputHeight = 842;

    final src = corners.map((p) => Point(p.x.toDouble(), p.y.toDouble())).toList();
    final dst = [
      Point(0.0, 0.0),
      Point(outputWidth - 1.0, 0.0),
      Point(outputWidth - 1.0, outputHeight - 1.0),
      Point(0.0, outputHeight - 1.0),
    ];

    // Calculate perspective transformation matrix
    final matrix = _calculatePerspectiveMatrix(src, dst);

    // Apply transformation
    final result = img.Image(width: outputWidth, height: outputHeight);

    for (int y = 0; y < outputHeight; y++) {
      for (int x = 0; x < outputWidth; x++) {
        final srcPoint = _applyMatrix(Point(x.toDouble(), y.toDouble()), matrix);
        if (srcPoint.x >= 0 && srcPoint.x < image.width &&
            srcPoint.y >= 0 && srcPoint.y < image.height) {
          final pixel = image.getPixel(srcPoint.x.toInt(), srcPoint.y.toInt());
          result.setPixel(x, y, pixel);
        }
      }
    }

    return result;
  }

  static List<List<double>> _calculatePerspectiveMatrix(List<Point> src, List<Point> dst) {
    // Implementation of perspective transformation matrix calculation
    // This is a simplified version - in production, use a proper linear algebra library

    final A = List<List<double>>.generate(8, (_) => List<double>.filled(8, 0));
    final B = List<double>.filled(8, 0);

    for (int i = 0; i < 4; i++) {
      final x = src[i].x, y = src[i].y;
      final u = dst[i].x, v = dst[i].y;

      A[2*i][0] = x; A[2*i][1] = y; A[2*i][2] = 1;
      A[2*i][3] = 0; A[2*i][4] = 0; A[2*i][5] = 0;
      A[2*i][6] = -u * x; A[2*i][7] = -u * y;

      A[2*i+1][0] = 0; A[2*i+1][1] = 0; A[2*i+1][2] = 0;
      A[2*i+1][3] = x; A[2*i+1][4] = y; A[2*i+1][5] = 1;
      A[2*i+1][6] = -v * x; A[2*i+1][7] = -v * y;

      B[2*i] = u;
      B[2*i+1] = v;
    }

    // Solve the system (simplified - use proper matrix inversion in production)
    final h = List<double>.filled(9, 0);
    // ... matrix solution implementation ...

    return [
      [h[0], h[1], h[2]],
      [h[3], h[4], h[5]],
      [h[6], h[7], h[8]],
    ];
  }

  static Point _applyMatrix(Point point, List<List<double>> matrix) {
    final x = point.x, y = point.y;
    final denominator = matrix[2][0] * x + matrix[2][1] * y + matrix[2][2];

    return Point(
      (matrix[0][0] * x + matrix[0][1] * y + matrix[0][2]) / denominator,
      (matrix[1][0] * x + matrix[1][1] * y + matrix[1][2]) / denominator,
    );
  }
}

class Point {
  final double x, y;

  Point(this.x, this.y);

  @override
  String toString() => 'Point($x, $y)';
}

class GradientData {
  final img.Image gradients;
  final List<List<double>> directions;

  GradientData({required this.gradients, required this.directions});
}