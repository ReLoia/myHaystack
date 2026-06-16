import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class TrackedItem {
  final String name;
  final String status;
  final LatLng location;
  final IconData icon;

  TrackedItem({
    required this.name,
    required this.status,
    required this.location,
    required this.icon,
  });
}