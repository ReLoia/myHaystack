import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../../shared/domain/entities/tracked_item.dart';
import '../viewmodels/item_history_viewmodel.dart';
import 'history_timeline_item.dart';

class HistoryBottomSheet extends ConsumerWidget {
  final TrackedItem item;
  final ValueChanged<LatLng> onLocationTapped;

  const HistoryBottomSheet({
    super.key,
    required this.item,
    required this.onLocationTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewDataAsync = ref.watch(itemHistoryViewDataProvider(item.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      builder: (context, sheetScrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: viewDataAsync.when(
            loading: () => _buildSheetStatus(
              sheetScrollController,
              theme,
              child: const CircularProgressIndicator(),
              text: "Loading history...",
            ),
            error: (error, _) => _buildSheetStatus(
              sheetScrollController,
              theme,
              child: _buildErrorState(ref, theme),
            ),
            data: (viewData) {
              if (viewData.groupedLocations.isEmpty) {
                return _buildSheetStatus(
                  sheetScrollController,
                  theme,
                  child: const Text('No history found.'),
                );
              }

              final currentIndex = viewData.availableDates.indexOf(
                viewData.selectedDate,
              );

              return Column(
                children: [
                  SingleChildScrollView(
                    controller: sheetScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildDragHandle(theme),
                        _buildDayControlHeader(
                          context,
                          ref,
                          viewData,
                          currentIndex,
                        ),
                        const Divider(height: 1),
                        _buildDataOverview(
                          viewData.groupedLocations.length,
                          viewData.groupedLocations.fold<int>(
                            0,
                            (sum, g) => sum + g.rawPoints.length,
                          ),
                          theme,
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: viewData.timelineItems.length,
                      itemBuilder: (context, index) {
                        final group = viewData.timelineItems[index];
                        return HistoryTimelineItem(
                          group: group,
                          index: index,
                          totalLength: viewData.timelineItems.length,
                          onTap: () => onLocationTapped(group.averageLocation),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(ThemeData theme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildSheetStatus(
    ScrollController controller,
    ThemeData theme, {
    required Widget child,
    String? text,
  }) {
    return SingleChildScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildDragHandle(theme),
          const SizedBox(height: 40),
          child,
          if (text != null) ...[
            const SizedBox(height: 16),
            Text(text, style: TextStyle(color: theme.colorScheme.outline)),
          ],
        ],
      ),
    );
  }

  Widget _buildDayControlHeader(
    BuildContext context,
    WidgetRef ref,
    ItemHistoryViewData viewData,
    int currentIndex,
  ) {
    final notifier = ref.read(selectedDateProvider(item.id).notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: currentIndex > 0
                ? () => notifier.shift(-1, viewData.availableDates)
                : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  viewData.selectedDate.formatDateTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () => _pickDate(context, ref, viewData),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: currentIndex < viewData.availableDates.length - 1
                ? () => notifier.shift(1, viewData.availableDates)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDataOverview(int groupedCount, int rawCount, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, color: theme.colorScheme.outline, size: 24),
          const SizedBox(width: 8),
          Text(
            "$groupedCount Data points (Collapsed from $rawCount)",
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.warning_rounded, color: theme.colorScheme.error, size: 48),
        const SizedBox(height: 16),
        const Text("An error occurred while fetching history"),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => ref.invalidate(itemHistoryProvider(item.id)),
          child: const Text("Retry"),
        ),
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    ItemHistoryViewData viewData,
  ) async {
    if (viewData.availableDates.isEmpty) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: viewData.selectedDate,
      firstDate: viewData.availableDates.first,
      lastDate: viewData.availableDates.last,
      selectableDayPredicate: (day) =>
          viewData.availableDates.contains(day.dateOnly),
    );

    if (picked != null && picked != viewData.selectedDate) {
      ref.read(selectedDateProvider(item.id).notifier).select(picked);
    }
  }
}
