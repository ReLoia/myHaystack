import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/tracked_item.dart';
import '../../../../shared/presentation/providers/app_providers.dart';

class MapState {
  final List<TrackedItem> items;
  final int currentIndex;
  final bool isSyncing;

  MapState({
    required this.items,
    this.currentIndex = 0,
    this.isSyncing = false,
  });

  MapState copyWith({
    List<TrackedItem>? items,
    int? currentIndex,
    bool? isSyncing,
  }) {
    return MapState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class MapViewModel extends StreamNotifier<MapState> {
  @override
  Stream<MapState> build() {
    final repo = ref.watch(trackedItemRepositoryProvider);

    return repo.watchItems().map((dbItems) {
      final currentIdx = state.value?.currentIndex ?? 0;
      final isSyncing = state.value?.isSyncing ?? false;

      final safeIdx = currentIdx >= dbItems.length && dbItems.isNotEmpty
          ? dbItems.length - 1
          : currentIdx;

      return MapState(
        items: dbItems,
        currentIndex: safeIdx,
        isSyncing: isSyncing,
      );
    });
  }

  Future<int> syncLocations() async {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(isSyncing: true));
    }

    int syncedCount = 0;

    try {
      final syncUseCase = ref.read(syncLocationsUseCaseProvider);
      syncedCount = await syncUseCase();
    } catch (e) {
      print("Sync error: $e");
    } finally {
      if (state.value != null) {
        state = AsyncData(state.value!.copyWith(isSyncing: false));
      }
    }

    return syncedCount;
  }

  void updateIndex(int index) {
    final currentState = state.value;
    if (currentState != null && currentState.currentIndex != index) {
      state = AsyncData(currentState.copyWith(currentIndex: index));
    }
  }
}

final mapViewModelProvider = StreamNotifierProvider<MapViewModel, MapState>(
  () => MapViewModel(),
);
