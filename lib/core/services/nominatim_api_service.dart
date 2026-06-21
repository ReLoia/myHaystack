import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:myhaystack/core/utils/logger.dart';

class NominatimApiService {
  final Dio _dio;

  NominatimApiService() : _dio = Dio() {
    if (kDebugMode) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    }
  }

  Future<String> reverseLatLng({
    required LatLng coordinates,
  }) async {
    try {
      final response = await _dio.get(
        "https://nominatim.openstreetmap.org/reverse",
        queryParameters: {
          'lat': coordinates.latitude,
          'lon': coordinates.longitude,
          'format': 'jsonv2',
          'addressdetails': '1',
        },
        options: Options(
          headers: {
            'User-Agent': 'it.reloia.myhaystack (reloia@proton.me)',
          },
        ),
      );

      var address = response.data['address'];

      return address != null ? "${address['road']}, ${address['town'] ?? address['city']}, ${address['country']}" : 'No address found';
    } on DioException catch (e) {
      Logger.error(e.message ?? "No error message", prefix: "Nominatim API Service");
      throw Exception("Network error: ${e.message}");
    } catch (e) {
      Logger.error(e.toString(), prefix: "Nominatim API Service");
      throw Exception("Error: ${e.toString()}");
    }
  }
}
