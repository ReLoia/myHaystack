import '../entities/tracked_item.dart';

abstract class TrackedItemRepository {
  Stream<List<TrackedItem>> watchItems();

  Future<List<TrackedItem>> getAllItems();

  Future<void> addTrackedItem(TrackedItem item);

  Future<void> updateTrackedItem(TrackedItem item);

  Future<void> reorderTrackedItems(List<TrackedItem> items);

  Future<void> deleteTrackedItem(String itemId);

  Future<int> syncLocationsWithServer();
}
