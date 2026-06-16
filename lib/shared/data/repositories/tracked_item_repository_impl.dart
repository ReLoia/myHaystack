import 'package:drift/drift.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/tracked_item.dart' as domain;
import '../../domain/entities/tracked_item.dart';
import '../../domain/repositories/tracked_item_repository.dart';
import '../local/database.dart';

class TrackedItemRepositoryImpl implements TrackedItemRepository {
  final AppDatabase _db;

  TrackedItemRepositoryImpl(this._db);

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
}
