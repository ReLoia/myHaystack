import 'package:latlong2/latlong.dart';

class TrackedItem {
  final String id;
  final String name;
  final String privateKey;
  final int color;
  final String? emoji;
  final LatLng currLocation;

  final int? accuracy;
  final int? batteryStatus;
  final DateTime? lastSeen;

  TrackedItem({
    required this.id,
    required this.name,
    required this.privateKey,
    required this.color,
    required this.currLocation,
    this.emoji,
    this.accuracy,
    this.batteryStatus,
    this.lastSeen,
  });
}
