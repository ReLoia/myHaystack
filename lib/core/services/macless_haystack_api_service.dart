import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/data/models/location_report_model.dart';
import '../utils/logger.dart';

class MaclessHaystackApiService {
  final Dio _dio;

  MaclessHaystackApiService() : _dio = Dio() {
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

  Future<bool> checkConnection({
    required String serverUrl,
    String? username,
    String? password,
  }) async {
    final headers = {"Content-Type": "application/json"};

    if (username != null && username.isNotEmpty) {
      final authString = base64.encode(utf8.encode("$username:$password"));
      headers['Authorization'] = 'Basic $authString';
    }

    try {
      final response = await _dio.post(
        serverUrl,
        data: {"ids": [], "days": 1},
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception("Authentication failure. Check Username and Password.");
      } else if (e.response?.statusCode == 404) {
        throw Exception("Server found, but endpoint is incorrect (404).");
      }
      throw Exception("Network error: ${e.message}");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  Future<List<LocationReportModel>> fetchLocationReports({
    required List<String> hashedAdvertisementKeys,
    required int daysToFetch,
    required String serverUrl,
    String? username,
    String? password,
  }) async {
    final headers = {"Content-Type": "application/json"};

    if (username != null && username.isNotEmpty) {
      final authString = base64.encode(utf8.encode("$username:$password"));
      headers['Authorization'] = 'Basic $authString';
    }

    Logger.info(
      "Request the location reports of ${hashedAdvertisementKeys.length} items",
      prefix: "MaclessHaystack API Service",
    );

    try {
      final response = await _dio.post(
        serverUrl,
        data: {"ids": hashedAdvertisementKeys, "days": daysToFetch},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        var responseData = response.data;

        if (responseData is String) {
          responseData = jsonDecode(responseData);
        }

        final List<dynamic> resultsList =
            responseData["results"] as List<dynamic>? ?? [];

        final List<LocationReportModel> parsedReports = resultsList
            .map(
              (json) =>
                  LocationReportModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        Logger.info(
          "Got ${resultsList.length} results from the server",
          prefix: "MaclessHaystack API Service",
        );

        return parsedReports;
      } else {
        throw Exception(
          "Failed to fetch reports. Status: ${response.statusCode}",
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception("Authentication failure.");
      }
      throw Exception("Network error: ${e.message}");
    }
  }
}
