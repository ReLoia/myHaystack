import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:myhaystack/features/map/presentation/viewmodels/map_viewmodel.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/item_export_service.dart';
import '../../../../core/services/item_import_service.dart';
import '../../../../core/utils/findmy_crypto_utils.dart';
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
    final keyStorage = ref.read(keyStorageServiceProvider);

    final String publicKey = FindMyCryptoUtils.getHashedPublicKeyFromPrivateKey(privateKey);
    await keyStorage.savePrivateKey(publicKey, privateKey);

    final String generatedId = const Uuid().v4();
    final currentState = state.value ?? [];

    await repo.addTrackedItem(
      TrackedItem(
        id: generatedId,
        name: name,
        publicKey: publicKey,
        color: color,
        currLocation: const LatLng(0, 0),
        emoji: emoji?.isNotEmpty == true ? emoji : null,
        orderIndex: currentState.length,
        accuracy: null,
        batteryStatus: null,
        lastSeen: null,
      ),
    );

    ref.read(mapViewModelProvider.notifier).syncLocations();
  }

  Future<void> updateItem(TrackedItem item) async {
    final repo = ref.read(trackedItemRepositoryProvider);
    await repo.updateTrackedItem(item);
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
    final currentState = state.value;
    if (currentState == null || currentState.isEmpty) return;

    final List<TrackedItem> items = List.from(currentState);
    final TrackedItem item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    state = AsyncData(items);

    final repo = ref.read(trackedItemRepositoryProvider);
    await repo.reorderTrackedItems(items);
  }

  Future<void> deleteItem(String itemId) async {
    final repo = ref.read(trackedItemRepositoryProvider);
    final currentState = state.value;
    
    if (currentState != null) {
      final itemToDelete = currentState.firstWhere((item) => item.id == itemId);
      final keyStorage = ref.read(keyStorageServiceProvider);
      await keyStorage.deletePrivateKey(itemToDelete.publicKey);
    }
    
    await repo.deleteTrackedItem(itemId);
  }

  Future<void> importItems() async {
    try {
      final importService = ref.read(itemImportServiceProvider);
      
      final newItems = await importService.pickAndParseJson();
      for (final item in newItems) {
        await addItem(
          name: item.name,
          privateKey: item.privateKey,
          color: item.color,
          emoji: item.emoji,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> importJsonContent(String content) async {
    try {
      final importService = ref.read(itemImportServiceProvider);
      
      final newItems = importService.parseJsonContent(content);
      for (final item in newItems) {
        await addItem(
          name: item.name,
          privateKey: item.privateKey,
          color: item.color,
          emoji: item.emoji,
        );
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

final itemExportServiceProvider = Provider((ref) {
  return ItemExportService(ref);
});

final itemImportServiceProvider = Provider((ref) => ItemImportService());

final itemManagementViewModelProvider =
    StreamNotifierProvider<ItemManagementViewModel, List<TrackedItem>>(
      () => ItemManagementViewModel(),
    );
