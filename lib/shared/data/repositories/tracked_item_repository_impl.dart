import 'package:drift/drift.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/macless_haystack_api_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/utils/findmy_crypto_utils.dart';
import '../../domain/entities/tracked_item.dart' as domain;
import '../../domain/entities/tracked_item.dart';
import '../../domain/repositories/tracked_item_repository.dart';
import '../local/database.dart';
import '../models/location_report_model.dart';

class TrackedItemRepositoryImpl implements TrackedItemRepository {
  final AppDatabase _db;
  final MaclessHaystackApiService apiService;
  final PreferencesService _prefs;

  TrackedItemRepositoryImpl(this._db, this.apiService, this._prefs);

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
            privateKey: item.privateKey,
            color: item.color,
            emoji: item.emoji,
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
            privateKey: item.privateKey,
            color: item.color,
            emoji: item.emoji,
          ),
        );
  }

  @override
  Future<void> deleteTrackedItem(String itemId) async {
    await (_db.delete(
      _db.trackedItems,
    )..where((t) => t.id.equals(itemId))).go();
  }

  @override
  Future<void> saveNewLocation(String trackedItemId, LatLng location) async {
    await _db
        .into(_db.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            trackedItemId: trackedItemId,
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> syncLocationsWithServer() async {
    final items = await _db.select(_db.trackedItems).get();
    if (items.isEmpty) return;

    Map<String, TrackedItemDbData> hashedKeyToItem = {};

    for (var item in items) {
      try {
        String normalizedKey = item.privateKey;
        while (normalizedKey.length % 4 != 0) {
          normalizedKey += '=';
        }

        final hashedKey = FindMyCryptoUtils.getHashedAdvKeyFromPrivateKey(
          normalizedKey,
        );
        hashedKeyToItem[hashedKey] = item;
      } catch (e) {
        print(
          "Skipping item '${item.name}' (ID: ${item.id}): Invalid private key format.",
        );
        continue;
      }
    }

    if (hashedKeyToItem.isEmpty) {
      print("No valid keys found to sync.");
      return;
    }

    final List<LocationReportModel> results = await apiService
        .fetchLocationReports(
          hashedAdvertisementKeys: hashedKeyToItem.keys.toList(),
          daysToFetch: _prefs.daysRetrieval,
          serverUrl: _prefs.serverUrl,
          username: _prefs.username,
          password: _prefs.password,
        );

    for (var report in results) {
      for (var item in hashedKeyToItem.values) {
        String normalizedKey = item.privateKey;
        while (normalizedKey.length % 4 != 0) {
          normalizedKey += '=';
        }

        final decrypted = FindMyCryptoUtils.decryptReport(
          report,
          normalizedKey,
        );

        if (decrypted != null) {
          await _db
              .into(_db.locationPoints)
              .insert(
                LocationPointsCompanion.insert(
                  trackedItemId: item.id,
                  latitude: decrypted.latitude,
                  longitude: decrypted.longitude,
                  timestamp: decrypted.timestamp,
                  accuracy: Value(decrypted.accuracy),
                  batteryStatus: Value(decrypted.batteryStatus),
                ),
                mode: InsertMode.insertOrIgnore,
              );

          break;
        }
      }
    }
  }
}
