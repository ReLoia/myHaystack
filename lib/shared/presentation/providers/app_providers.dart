import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../data/repositories/tracked_item_repository_impl.dart';
import '../../domain/repositories/tracked_item_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final trackedItemRepositoryProvider = Provider<TrackedItemRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TrackedItemRepositoryImpl(db);
});
