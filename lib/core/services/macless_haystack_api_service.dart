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
