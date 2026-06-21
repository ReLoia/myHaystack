import '../../data/models/decrypted_location_model.dart';
import '../entities/tracked_item.dart';

abstract class TrackedItemRepository {
  Stream<List<TrackedItem>> watchItems();

  Future<List<TrackedItem>> getAllItems();

  Future<void> addTrackedItem(TrackedItem item);

  Future<void> updateTrackedItem(TrackedItem item);

  Future<void> deleteTrackedItem(String itemId);

  Future<void> saveNewLocation(String trackedItemId, DecryptedLocationModel decrypted);

  Future<int> syncLocationsWithServer();
}
