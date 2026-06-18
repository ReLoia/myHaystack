import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myhaystack/core/services/macless_haystack_api_service.dart';

import '../../data/local/database.dart';
import '../../data/repositories/tracked_item_repository_impl.dart';
import '../../domain/repositories/tracked_item_repository.dart';
import '../../domain/usecases/sync_locations_usecase.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final maclessHaystackAPIServiceProvider = Provider<MaclessHaystackApiService>((ref) {
  return MaclessHaystackApiService();
});

final trackedItemRepositoryProvider = Provider<TrackedItemRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final apiService = ref.watch(maclessHaystackAPIServiceProvider);
  return TrackedItemRepositoryImpl(db, apiService);
});

final syncLocationsUseCaseProvider = Provider<SyncLocationsUseCase>((ref) {
  final repository = ref.watch(trackedItemRepositoryProvider);

  return SyncLocationsUseCase(repository);
});
