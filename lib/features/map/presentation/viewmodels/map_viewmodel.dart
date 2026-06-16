import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/tracked_item.dart';
import '../../../../shared/presentation/providers/app_providers.dart';

class MapState {
  final List<TrackedItem> items;
  final int currentIndex;

  MapState({required this.items, this.currentIndex = 0});

  MapState copyWith({List<TrackedItem>? items, int? currentIndex}) {
    return MapState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class MapViewModel extends StreamNotifier<MapState> {
  @override
  Stream<MapState> build() {
    final repo = ref.watch(trackedItemRepositoryProvider);

    return repo.watchItems().map((dbItems) {
      final currentIdx = state.value?.currentIndex ?? 0;

      final safeIdx = currentIdx >= dbItems.length && dbItems.isNotEmpty
          ? dbItems.length - 1
          : currentIdx;

      return MapState(items: dbItems, currentIndex: safeIdx);
    });
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
