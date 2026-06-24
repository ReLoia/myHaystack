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

  bool get hasNoData {
    return location.latitude == 0 && location.longitude == 0;
  }
}
