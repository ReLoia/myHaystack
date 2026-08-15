import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class LocationPoint {
  final int? id;
  final String trackedItemId;
  final LatLng location;
  final DateTime timestamp;
  final int accuracy;
  final int? batteryStatus;

  LocationPoint({
    this.id,
    required this.trackedItemId,
    required this.location,
    required this.timestamp,
    this.accuracy = 0,
    this.batteryStatus,
  });

  @override
  String toString() {
    return 'LocationPoint(id: $id, trackedItemId: $trackedItemId, location: $location, timestamp: $timestamp, accuracy: $accuracy, batteryStatus: $batteryStatus)';
  }

  bool get hasBatteryData => batteryStatus != null;

  Widget get batteryIcon {
    final (batteryIcon, batteryColor) = switch (batteryStatus) {
      0 => (Icons.battery_full_rounded, Colors.green),
      1 => (Icons.battery_6_bar_rounded, Colors.amber),
      2 => (Icons.battery_3_bar_rounded, Colors.orange),
      _ => (Icons.battery_alert_rounded, Colors.red),
    };

    return Icon(batteryIcon, color: batteryColor);
  }

  bool get hasNoData {
    return location.latitude == 0 && location.longitude == 0;
  }
}
