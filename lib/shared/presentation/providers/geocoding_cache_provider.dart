import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/nominatim_api_service.dart';

final nominatimApiProvider = Provider((ref) => NominatimApiService());

class GeocodingCacheNotifier extends Notifier<Map<String, String>> {
  final List<LatLng> _queue = [];
  bool _isProcessing = false;

  @override
  Map<String, String> build() {
    return {};
  }

  String getCacheKey(LatLng coords) {
    return '${coords.latitude.toStringAsFixed(4)},${coords.longitude.toStringAsFixed(4)}';
  }

  void fetchAddress(LatLng coords) {
    final key = getCacheKey(coords);

    if (state.containsKey(key)) return;

    state = {...state, key: 'Loading address...'};

    _queue.add(coords);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final coords = _queue.removeAt(0);
      final key = getCacheKey(coords);

      try {
        final api = ref.read(nominatimApiProvider);
        final address = await api.reverseLatLng(coordinates: coords);

        state = {...state, key: address};
      } catch (e) {
        state = {...state, key: 'Address not available'};
      }

      if (_queue.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    _isProcessing = false;
  }
}

final geocodingCacheProvider =
    NotifierProvider<GeocodingCacheNotifier, Map<String, String>>(() {
      return GeocodingCacheNotifier();
    });
