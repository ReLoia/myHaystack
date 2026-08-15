/*
 * Note by reloia:
 * Done using an LLM (I suck at math)
 */

import 'dart:math';

import 'package:latlong2/latlong.dart';

class MapMathUtils {
  static List<LatLng> generateSmoothCurve(List<LatLng> points) {
    if (points.length < 3) return points;

    List<LatLng> curvedPoints = [];
    const int segments = 15;

    for (int i = 0; i < points.length - 1; i++) {
      LatLng p0 = i == 0 ? points[0] : points[i - 1];
      LatLng p1 = points[i];
      LatLng p2 = points[i + 1];
      LatLng p3 = i == points.length - 2 ? points[i + 1] : points[i + 2];

      for (int t = 0; t < segments; t++) {
        double t1 = t / segments;
        double t2 = t1 * t1;
        double t3 = t2 * t1;

        double lat =
            0.5 *
            ((2.0 * p1.latitude) +
                (-p0.latitude + p2.latitude) * t1 +
                (2.0 * p0.latitude -
                        5.0 * p1.latitude +
                        4.0 * p2.latitude -
                        p3.latitude) *
                    t2 +
                (-p0.latitude +
                        3.0 * p1.latitude -
                        3.0 * p2.latitude +
                        p3.latitude) *
                    t3);
        double lng =
            0.5 *
            ((2.0 * p1.longitude) +
                (-p0.longitude + p2.longitude) * t1 +
                (2.0 * p0.longitude -
                        5.0 * p1.longitude +
                        4.0 * p2.longitude -
                        p3.longitude) *
                    t2 +
                (-p0.longitude +
                        3.0 * p1.longitude -
                        3.0 * p2.longitude +
                        p3.longitude) *
                    t3);

        curvedPoints.add(LatLng(lat, lng));
      }
    }
    curvedPoints.add(points.last);
    return curvedPoints;
  }

  static LatLng offsetLatLngForDrawer(
    LatLng center,
    double offsetYPixels,
    double zoom,
  ) {
    const double tileSize = 256.0;
    final double scale = pow(2.0, zoom).toDouble();
    final double worldSize = tileSize * scale;

    final double x = (center.longitude + 180.0) / 360.0 * worldSize;
    final double sinLat = sin(center.latitude * pi / 180.0);
    final double y =
        (0.5 - log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * pi)) * worldSize;

    final double newY = y + offsetYPixels;

    final double newLng = (x / worldSize) * 360.0 - 180.0;
    final double newLat =
        (2.0 * atan(exp(pi - 2.0 * pi * newY / worldSize)) - pi / 2.0) *
        180.0 /
        pi;

    return LatLng(newLat, newLng);
  }
}
