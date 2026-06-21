import 'package:flutter/material.dart';
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

  @override
  String toString() {
    return 'TrackedItem(id: $id, name: $name, privateKey: $privateKey, color: $color, emoji: $emoji, currLocation: $currLocation, accuracy: $accuracy, batteryStatus: $batteryStatus, lastSeen: $lastSeen)';
  }

  ColorScheme getColorScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: Color(color),
      brightness: brightness,
    );
  }

  bool get isOffline {
    if (lastSeen == null) return true;
    return DateTime.now().difference(lastSeen!).inHours >= 6;
  }
}
