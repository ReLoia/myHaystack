import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/item_export_service.dart';
import '../../../../core/services/item_import_service.dart';
import '../../../../shared/domain/entities/tracked_item.dart';
import '../../../../shared/presentation/providers/app_providers.dart';

class ItemManagementViewModel extends StreamNotifier<List<TrackedItem>> {
  @override
  Stream<List<TrackedItem>> build() {
    return ref.watch(trackedItemRepositoryProvider).watchItems();
  }

  Future<void> addItem({
    required String name,
    required String privateKey,
    required int color,
    String? emoji,
  }) async {
    final repo = ref.read(trackedItemRepositoryProvider);

    final String generatedId = const Uuid().v4();

    await repo.addTrackedItem(
      TrackedItem(
        id: generatedId,
        name: name,
        privateKey: privateKey,
        color: color,
        currLocation: const LatLng(0, 0),
        emoji: emoji?.isNotEmpty == true ? emoji : null,
        accuracy: null,
        batteryStatus: null,
        lastSeen: null,
      ),
    );
  }

  Future<void> updateItem(TrackedItem item) async {
    final repo = ref.read(trackedItemRepositoryProvider);
    await repo.updateTrackedItem(item);
  }

  Future<void> deleteItem(String itemId) async {
    final repo = ref.read(trackedItemRepositoryProvider);
    await repo.deleteTrackedItem(itemId);
  }

  Future<void> importItems() async {
    try {
      final importService = ref.read(itemImportServiceProvider);
      final repo = ref.read(trackedItemRepositoryProvider);

      final newItems = await importService.pickAndParseJson();

      for (final item in newItems) {
        await repo.addTrackedItem(item);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> importJsonContent(String content) async {
    try {
      final importService = ref.read(itemImportServiceProvider);
      final repo = ref.read(trackedItemRepositoryProvider);

      final newItems = importService.parseJsonContent(content);

      for (final item in newItems) {
        await repo.addTrackedItem(item);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> exportItems(List<TrackedItem> itemsToExport) async {
    final exportService = ref.read(itemExportServiceProvider);

    final success = await exportService.exportItemsToJson(itemsToExport);

    if (!success) {
      throw Exception('Export canceled by user');
    }
  }
}

final itemExportServiceProvider = Provider((ref) => ItemExportService());

final itemImportServiceProvider = Provider((ref) => ItemImportService());

final itemManagementViewModelProvider =
    StreamNotifierProvider<ItemManagementViewModel, List<TrackedItem>>(
      () => ItemManagementViewModel(),
    );
