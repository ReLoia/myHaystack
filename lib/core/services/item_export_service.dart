import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/domain/entities/tracked_item.dart';

class ItemExportService {
  final Ref _ref;

  ItemExportService(this._ref);

  Future<Map<String, dynamic>> _itemToMap(TrackedItem item) async {
    final color = Color(item.color);
    final privateKey = await item.getPrivateKey(_ref);

    return {
      "id": item.id,
      "colorComponents": [color.r, color.g, color.b, color.a],
      "name": item.name,
      "privateKey": privateKey ?? '',
      "icon": "tortoise.fill",
      "isActive": true,
      "additionalKeys": [],
    };
  }

  Future<bool> _saveToFile(dynamic data, String defaultFileName) async {
    const encoder = JsonEncoder.withIndent('  ');
    final String jsonString = encoder.convert(data);
    final Uint8List fileBytes = Uint8List.fromList(utf8.encode(jsonString));

    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Save Export',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: fileBytes,
    );

    return outputFile != null;
  }

  Future<bool> _shareFile(dynamic data, String defaultFileName) async {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final String jsonString = encoder.convert(data);

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$defaultFileName');
      await file.writeAsString(jsonString);

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Exported Items',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('Error sharing file: $e');
      return false;
    }
  }

  Future<bool> exportItemsToJson(List<TrackedItem> items) async {
    final List<Map<String, dynamic>> jsonData = [];
    for (var item in items) {
      jsonData.add(await _itemToMap(item));
    }
    return await _saveToFile(jsonData, 'myhaystack_items.json');
  }

  Future<bool> shareItems(List<TrackedItem> items) async {
    final List<Map<String, dynamic>> jsonData = [];
    for (var item in items) {
      jsonData.add(await _itemToMap(item));
    }
    return await _shareFile(jsonData, 'myhaystack_items.json');
  }

  Future<bool> exportSingleItemToJson(TrackedItem item) async {
    final itemMap = await _itemToMap(item);
    return await _saveToFile([itemMap], '${item.name}_export.json');
  }

  Future<bool> shareSingleItem(TrackedItem item) async {
    final itemMap = await _itemToMap(item);
    return await _shareFile([itemMap], '${item.name}_export.json');
  }
}
