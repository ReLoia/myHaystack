import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/domain/entities/tracked_item.dart';

class ItemImportService {
  Future<List<TrackedItem>> pickAndParseJson() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return [];

    final file = File(result.files.single.path!);
    final String content = await file.readAsString();
    return parseJsonContent(content);
  }

  List<TrackedItem> parseJsonContent(String content) {
    try {
      final dynamic decoded = jsonDecode(content);

      final List<dynamic> jsonData;
      if (decoded is List) {
        jsonData = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('items') && decoded['items'] is List) {
          jsonData = decoded['items'] as List<dynamic>;
        } else {
          jsonData = [decoded];
        }
      } else {
        return [];
      }

      final List<TrackedItem> items = [];

      for (final item in jsonData) {
        if (item is! Map<String, dynamic>) continue;

        final privateKey = item['privateKey'];
        if (privateKey == null || privateKey is! String || privateKey.isEmpty) {
          continue;
        }

        final List<dynamic> comps = item['colorComponents'] is List
            ? item['colorComponents']
            : [0, 0, 0, 1];

        Color color = Colors.blue;
        try {
          color = Color.fromARGB(
            ((comps.length > 3 ? comps[3] as num : 1) * 255).round(), // A
            ((comps.isNotEmpty ? comps[0] as num : 0) * 255).round(), // R
            ((comps.length > 1 ? comps[1] as num : 0) * 255).round(), // G
            ((comps.length > 2 ? comps[2] as num : 1) * 255).round(), // B
          );
        } catch (_) {}

        items.add(
          TrackedItem(
            id: const Uuid().v4(),
            name: item['name']?.toString() ?? 'Imported Item',
            privateKey: privateKey,
            color: color.toARGB32(),
            emoji: item['emoji']?.toString(),
            currLocation: const LatLng(0, 0),
            accuracy: null,
            batteryStatus: null,
            lastSeen: null,
          ),
        );
      }

      return items;
    } catch (e) {
      debugPrint('Failed to parse JSON: $e');
      return [];
    }
  }
}
