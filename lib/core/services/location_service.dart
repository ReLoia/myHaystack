import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

final locationServiceProvider = Provider((ref) => LocationService());

final userLocationProvider = StreamProvider<LatLng>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.watchUserLocation();
});

class LocationService {
  Future<LatLng?> getUserLocation() async {
    final hasPerms = await _handlePermissions();
    if (!hasPerms) return null;

    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  Stream<LatLng> watchUserLocation() async* {
    final hasPerms = await _handlePermissions();
    if (!hasPerms) return;

    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).map((pos) => LatLng(pos.latitude, pos.longitude));
  }

  Future<bool> _handlePermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }
}
