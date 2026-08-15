import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../../shared/domain/entities/location_point.dart';
import '../../../../shared/presentation/providers/app_providers.dart';
import '../../data/models/grouped_location.dart';
import '../utils/map_math_utils.dart';

final itemHistoryProvider = FutureProvider.autoDispose
    .family<List<LocationPoint>, String>((ref, itemId) async {
      final repo = ref.read(trackedItemRepositoryProvider);
      final history = await repo.getItemLocationHistory(itemId);
      history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return history;
    });

class SelectedDateNotifier extends Notifier<DateTime?> {
  SelectedDateNotifier(this.itemId);

  final String itemId;

  @override
  DateTime? build() => null;

  void select(DateTime date) => state = date.dateOnly;

  void shift(int delta, List<DateTime> availableDates) {
    final current = state ?? availableDates.last;
    final index = availableDates.indexOf(current) + delta;
    if (index >= 0 && index < availableDates.length) {
      state = availableDates[index];
    }
  }
}

final selectedDateProvider = NotifierProvider.autoDispose
    .family<SelectedDateNotifier, DateTime?, String>(
      (arg) => SelectedDateNotifier(arg),
    );

const _distanceCalc = Distance();
const _distanceThresholdMeters = 30.0;
const _maxGroupTimeMinutes = 30;

List<GroupedLocation> _groupLocations(List<LocationPoint> rawPoints) {
  if (rawPoints.isEmpty) return [];

  final grouped = <GroupedLocation>[];
  var currentGroup = <LocationPoint>[rawPoints.first];

  for (var i = 1; i < rawPoints.length; i++) {
    final point = rawPoints[i];
    final groupStart = currentGroup.first;

    final distance = _distanceCalc.as(
      LengthUnit.Meter,
      groupStart.location,
      point.location,
    );
    final durationMinutes = point.timestamp
        .difference(groupStart.timestamp)
        .inMinutes;

    if (distance <= _distanceThresholdMeters &&
        durationMinutes <= _maxGroupTimeMinutes) {
      currentGroup.add(point);
    } else {
      grouped.add(_createGroup(currentGroup));
      currentGroup = [point];
    }
  }
  grouped.add(_createGroup(currentGroup));
  return grouped;
}

GroupedLocation _createGroup(List<LocationPoint> points) {
  double sumLat = 0, sumLng = 0, sumAcc = 0;
  for (final p in points) {
    sumLat += p.location.latitude;
    sumLng += p.location.longitude;
    sumAcc += p.accuracy ?? 0;
  }
  final count = points.length;
  return GroupedLocation(
    rawPoints: points,
    averageLocation: LatLng(sumLat / count, sumLng / count),
    startTime: points.first.timestamp,
    endTime: points.last.timestamp,
    averageAccuracy: sumAcc / count,
    batteryIcon: points.last.batteryIcon,
  );
}

class ItemHistoryViewData {
  final DateTime selectedDate;
  final List<DateTime> availableDates;
  final List<GroupedLocation> groupedLocations;
  final List<GroupedLocation> timelineItems;
  final List<LatLng> smoothLinePoints;

  const ItemHistoryViewData({
    required this.selectedDate,
    required this.availableDates,
    required this.groupedLocations,
    required this.timelineItems,
    required this.smoothLinePoints,
  });

  static ItemHistoryViewData empty(DateTime fallbackDate) =>
      ItemHistoryViewData(
        selectedDate: fallbackDate,
        availableDates: const [],
        groupedLocations: const [],
        timelineItems: const [],
        smoothLinePoints: const [],
      );
}

final itemHistoryViewDataProvider = Provider.autoDispose
    .family<AsyncValue<ItemHistoryViewData>, String>((ref, itemId) {
      final historyAsync = ref.watch(itemHistoryProvider(itemId));

      return historyAsync.whenData((locations) {
        if (locations.isEmpty)
          return ItemHistoryViewData.empty(DateTime.now().dateOnly);

        final availableDates =
            locations.map((l) => l.timestamp.dateOnly).toSet().toList()..sort();
        final selectedDate =
            ref.watch(selectedDateProvider(itemId)) ?? availableDates.last;

        final dayLocations = locations
            .where((l) => l.timestamp.dateOnly == selectedDate)
            .toList();
        final grouped = _groupLocations(dayLocations);

        return ItemHistoryViewData(
          selectedDate: selectedDate,
          availableDates: availableDates,
          groupedLocations: grouped,
          timelineItems: grouped.reversed.toList(),
          smoothLinePoints: MapMathUtils.generateSmoothCurve(
            grouped.map((g) => g.averageLocation).toList(),
          ),
        );
      });
    });
