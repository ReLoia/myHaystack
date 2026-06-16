import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/tracked_item.dart' as domain;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [TrackedItems, LocationPoints])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Stream<List<domain.TrackedItem>> watchItemsWithLatestLocation() {
    return select(trackedItems).watch().asyncMap((items) async {
      List<domain.TrackedItem> result = [];
      for (final item in items) {
        final latestLocation =
            await (select(locationPoints)
                  ..where((loc) => loc.trackedItemId.equals(item.id))
                  ..orderBy([
                    (loc) => OrderingTerm(
                      expression: loc.timestamp,
                      mode: OrderingMode.desc,
                    ),
                  ])
                  ..limit(1))
                .getSingleOrNull();

        result.add(
          domain.TrackedItem(
            id: item.id,
            name: item.name,
            privateKey: item.privateKey,
            color: item.color,
            emoji: item.emoji,
            currLocation: latestLocation != null
                ? LatLng(latestLocation.latitude, latestLocation.longitude)
                : const LatLng(0, 0),
          ),
        );
      }
      return result;
    });
  }

  Future<List<domain.TrackedItem>> getAllItemsWithLatestLocation() async {
    final items = await select(trackedItems).get();
    List<domain.TrackedItem> result = [];

    for (final item in items) {
      final latestLocation =
          await (select(locationPoints)
                ..where((loc) => loc.trackedItemId.equals(item.id))
                ..orderBy([
                  (loc) => OrderingTerm(
                    expression: loc.timestamp,
                    mode: OrderingMode.desc,
                  ),
                ])
                ..limit(1))
              .getSingleOrNull();

      result.add(
        domain.TrackedItem(
          id: item.id,
          name: item.name,
          privateKey: item.privateKey,
          color: item.color,
          emoji: item.emoji,
          currLocation: latestLocation != null
              ? LatLng(latestLocation.latitude, latestLocation.longitude)
              : const LatLng(0, 0),
        ),
      );
    }
    return result;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'haystack.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
