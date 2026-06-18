import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../shared/domain/entities/tracked_item.dart';
import 'package:uuid/uuid.dart';

class ItemImportService {
  Future<List<TrackedItem>> pickAndParseJson() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return [];

    final file = File(result.files.single.path!);
    final String content = await file.readAsString();
    final List<dynamic> jsonData = jsonDecode(content);

    return jsonData.map((item) {
      final List<dynamic> comps = item['colorComponents'] ?? [0, 0, 0, 1];
      final color = Color.fromARGB(
        ((comps[3] as num) * 255).round(), // A
        ((comps[0] as num) * 255).round(), // R
        ((comps[1] as num) * 255).round(), // G
        ((comps[2] as num) * 255).round(), // B
      ).toARGB32();

      return TrackedItem(
        id: const Uuid().v4(),
        name: item['name'] ?? 'Imported Item',
        privateKey: item['privateKey'] ?? '',
        color: color,
        emoji: null,
        currLocation: const LatLng(0, 0),
        accuracy: null,
        batteryStatus: null,
        lastSeen: null,
      );
    }).toList();
  }
}
