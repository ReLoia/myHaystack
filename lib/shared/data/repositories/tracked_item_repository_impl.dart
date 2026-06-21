import 'package:drift/drift.dart';

import '../../../core/services/key_storage_service.dart';
import '../../../core/services/macless_haystack_api_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/utils/findmy_crypto_utils.dart';
import '../../../core/utils/logger.dart';
import '../../domain/entities/tracked_item.dart' as domain;
import '../../domain/entities/tracked_item.dart';
import '../../domain/repositories/tracked_item_repository.dart';
import '../local/database.dart';
import '../models/location_report_model.dart';

class TrackedItemRepositoryImpl implements TrackedItemRepository {
  final AppDatabase _db;
  final MaclessHaystackApiService apiService;
  final PreferencesService _prefs;
  final KeyStorageService _keyStorage;

  TrackedItemRepositoryImpl(this._db, this.apiService, this._prefs, this._keyStorage);

  @override
  Stream<List<TrackedItem>> watchItems() {
    return _db.watchItemsWithLatestLocation();
  }

  @override
  Future<List<TrackedItem>> getAllItems() {
    return _db.getAllItemsWithLatestLocation();
  }

  @override
  Future<void> addTrackedItem(domain.TrackedItem item) async {
    await _db
        .into(_db.trackedItems)
        .insert(
          TrackedItemDbData(
            id: item.id,
            name: item.name,
            publicKey: item.publicKey,
            color: item.color,
            emoji: item.emoji,
            orderIndex: item.orderIndex,
          ),
          mode: InsertMode.replace,
        );
  }

  @override
  Future<void> updateTrackedItem(domain.TrackedItem item) async {
    await _db
        .update(_db.trackedItems)
        .replace(
          TrackedItemDbData(
            id: item.id,
            name: item.name,
            publicKey: item.publicKey,
            color: item.color,
            emoji: item.emoji,
            orderIndex: item.orderIndex,
          ),
        );
  }

  @override
  Future<void> reorderTrackedItems(List<domain.TrackedItem> items) async {
    await _db.transaction(() async {
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        await _db
            .update(_db.trackedItems)
            .replace(
              TrackedItemDbData(
                id: item.id,
                name: item.name,
                publicKey: item.publicKey,
                color: item.color,
                emoji: item.emoji,
                orderIndex: i,
              ),
            );
      }
    });
  }

  @override
  Future<void> deleteTrackedItem(String itemId) async {
    await (_db.delete(
      _db.trackedItems,
    )..where((t) => t.id.equals(itemId))).go();
  }

  @override
  Future<int> syncLocationsWithServer() async {
    final items = await _db.select(_db.trackedItems).get();
    if (items.isEmpty) return 0;

    int totalSynced = 0;

    for (var item in items) {
      try {
        String? privateKey = await _keyStorage.getPrivateKey(item.publicKey);
        if (privateKey == null) {
          Logger.error("No private key for item '${item.name}'", prefix: "TrackedItemRepository");
          continue;
        }

        String normalizedKey = privateKey;
        while (normalizedKey.length % 4 != 0) {
          normalizedKey += '=';
        }

        final hashedKey = FindMyCryptoUtils.getHashedAdvKeyFromPrivateKey(
          normalizedKey,
        );

        final List<LocationReportModel> results = await apiService
            .fetchLocationReports(
              hashedAdvertisementKeys: [hashedKey],
              daysToFetch: _prefs.daysRetrieval,
              serverUrl: _prefs.serverUrl,
              username: _prefs.username,
              password: _prefs.password,
            );

        final companions = <LocationPointsCompanion>[];

        for (var report in results) {
          final decrypted = FindMyCryptoUtils.decryptReport(
            report,
            normalizedKey,
          );

          if (decrypted != null) {
            companions.add(
              LocationPointsCompanion.insert(
                trackedItemId: item.id,
                latitude: decrypted.latitude,
                longitude: decrypted.longitude,
                timestamp: decrypted.timestamp,
                accuracy: Value(decrypted.accuracy),
                batteryStatus: Value(decrypted.batteryStatus),
              ),
            );
          }
        }

        if (companions.isEmpty) continue;

        final countExp = _db.locationPoints.id.count();
        final countQuery = _db.selectOnly(_db.locationPoints)
          ..addColumns([countExp])
          ..where(_db.locationPoints.trackedItemId.equals(item.id));

        final countBefore = await countQuery
            .map((row) => row.read(countExp))
            .getSingle();

        await _db.batch((batch) {
          batch.insertAll(
            _db.locationPoints,
            companions,
            mode: InsertMode.insertOrIgnore,
          );
        });

        final countAfter = await countQuery
            .map((row) => row.read(countExp))
            .getSingle();

        Logger.info(
          "The stored location is now $countAfter, before $countBefore",
          prefix: "TrackedItemRepository",
        );

        totalSynced += (countAfter! - countBefore!);
      } catch (e) {
        Logger.error(
          "Skipping item '${item.name}' (ID: ${item.id}) or sync failed: $e",
          prefix: "TrackedItemRepository",
        );
        continue;
      }
    }

    return totalSynced;
  }
}
