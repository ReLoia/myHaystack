import 'package:latlong2/latlong.dart';

class TrackedItem {
  final String id;
  final String name;
  final String privateKey;
  final int color;
  final LatLng currLocation;
  final String? emoji;

  TrackedItem({
    required this.name,
    required this.id,
    required this.privateKey,
    required this.color,
    required this.currLocation,
    this.emoji,
  });
}
