import 'package:drift/drift.dart';

import '../../../core/services/macless_haystack_api_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/utils/findmy_crypto_utils.dart';
import '../../../core/utils/logger.dart';
import '../../domain/entities/tracked_item.dart' as domain;
import '../../domain/entities/tracked_item.dart';
import '../../domain/repositories/tracked_item_repository.dart';
import '../local/database.dart';
import '../models/decrypted_location_model.dart';
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
  Future<void> saveNewLocation(
    String trackedItemId,
    DecryptedLocationModel decrypted,
  ) async {
    await _db
        .into(_db.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            trackedItemId: trackedItemId,
            latitude: decrypted.latitude,
            longitude: decrypted.longitude,
            timestamp: decrypted.timestamp,
            accuracy: Value(decrypted.accuracy),
            batteryStatus: Value(decrypted.batteryStatus),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<int> syncLocationsWithServer() async {
    final items = await _db.select(_db.trackedItems).get();
    if (items.isEmpty) return 0;

    int totalSynced = 0;

    for (var item in items) {
      try {
        String normalizedKey = item.privateKey;
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

        for (var report in results) {
          final decrypted = FindMyCryptoUtils.decryptReport(
            report,
            normalizedKey,
          );

          if (decrypted != null) {
            saveNewLocation(item.id, decrypted);
            totalSynced++;
          }
        }
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
