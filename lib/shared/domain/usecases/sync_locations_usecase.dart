import '../repositories/tracked_item_repository.dart';

class SyncLocationsUseCase {
  final TrackedItemRepository repository;

  SyncLocationsUseCase(this.repository);

  Future<void> call() async {
    return await repository.syncLocationsWithServer();
  }
}