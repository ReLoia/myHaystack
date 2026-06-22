import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../presentation/providers/app_providers.dart';

class TrackedItem {
  final String id;
  final String name;
  final String publicKey;
  final int color;
  final String? emoji;
  final int orderIndex;
  final LatLng currLocation;

  final int? accuracy;
  final int? batteryStatus;
  final DateTime? lastSeen;

  TrackedItem({
    required this.id,
    required this.name,
    required this.publicKey,
    required this.color,
    this.orderIndex = 0,
    required this.currLocation,
    this.emoji,
    this.accuracy,
    this.batteryStatus,
    this.lastSeen,
  });

  @override
  String toString() {
    return 'TrackedItem(id: $id, name: $name, publicKey: $publicKey, color: $color, emoji: $emoji, orderIndex: $orderIndex, currLocation: $currLocation, accuracy: $accuracy, batteryStatus: $batteryStatus, lastSeen: $lastSeen)';
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

  bool get hasNoData {
    if (currLocation.latitude == 0 && currLocation.longitude == 0) return true;
    return false;
  }
}

extension TrackedItemSecurity on TrackedItem {
  Future<String?> getPrivateKey(Ref ref) {
    return ref.read(keyStorageServiceProvider).getPrivateKey(publicKey);
  }
}
