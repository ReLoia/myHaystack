import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/tracked_item.dart';

class ItemExportService {
  final Ref _ref;

  ItemExportService(this._ref);

  Future<bool> exportItemsToJson(List<TrackedItem> items) async {
    final List<Map<String, dynamic>> jsonData = [];
    
    for (var item in items) {
      final color = Color(item.color);
      final privateKey = await item.getPrivateKey(_ref);

      jsonData.add({
        "id": item.id,
        "colorComponents": [color.r, color.g, color.b, color.a],
        "name": item.name,
        "privateKey": privateKey ?? '',
        "icon": "tortoise.fill",
        "isActive": true,
        "additionalKeys": [],
      });
    }

    const encoder = JsonEncoder.withIndent('  ');
    final String jsonString = encoder.convert(jsonData);

    final Uint8List fileBytes = Uint8List.fromList(utf8.encode(jsonString));

    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Save Items Export',
      fileName: 'tracked_items_export.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: fileBytes,
    );

    return outputFile != null;
  }
}
