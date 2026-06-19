import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myhaystack/core/services/macless_haystack_api_service.dart';
import 'package:myhaystack/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/database.dart';
import '../../data/repositories/tracked_item_repository_impl.dart';
import '../../domain/repositories/tracked_item_repository.dart';
import '../../domain/usecases/sync_locations_usecase.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main.dart');
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService(ref.watch(sharedPreferencesProvider));
});

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final maclessHaystackAPIServiceProvider = Provider<MaclessHaystackApiService>((ref) {
  return MaclessHaystackApiService();
});

final trackedItemRepositoryProvider = Provider<TrackedItemRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final apiService = ref.watch(maclessHaystackAPIServiceProvider);
  final prefs = ref.watch(preferencesServiceProvider);
  return TrackedItemRepositoryImpl(db, apiService, prefs);
});

final syncLocationsUseCaseProvider = Provider<SyncLocationsUseCase>((ref) {
  final repository = ref.watch(trackedItemRepositoryProvider);

  return SyncLocationsUseCase(repository);
});
