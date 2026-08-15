import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart';

import '../../../../shared/domain/entities/location_point.dart';

class GroupedLocation {
  final List<LocationPoint> rawPoints;
  final LatLng averageLocation;
  final DateTime startTime;
  final DateTime endTime;
  final double averageAccuracy;
  final Widget? batteryIcon;

  GroupedLocation({
    required this.rawPoints,
    required this.averageLocation,
    required this.startTime,
    required this.endTime,
    required this.averageAccuracy,
    this.batteryIcon,
  });

  bool get isGroup => rawPoints.length > 1;
}
