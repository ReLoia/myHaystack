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
    return customSelect(
      '''
    SELECT 
      t.id, 
      t.name, 
      t.private_key, 
      t.color, 
      t.emoji,
      l.latitude, 
      l.longitude, 
      l.accuracy,
      l.timestamp,
      l.battery_status
    FROM tracked_items t
    LEFT JOIN location_points l ON l.tracked_item_id = t.id
    AND l.timestamp = (
      SELECT MAX(timestamp) 
      FROM location_points 
      WHERE tracked_item_id = t.id
    )
    ''',
      readsFrom: {trackedItems, locationPoints},
    ).watch().map((rows) {
      return rows.map((row) {
        final lat = row.read<double?>('latitude');
        final lng = row.read<double?>('longitude');

        return domain.TrackedItem(
          id: row.read<String>('id'),
          name: row.read<String>('name'),
          privateKey: row.read<String>('private_key'),
          color: row.read<int>('color'),
          emoji: row.read<String?>('emoji'),
          currLocation: LatLng(
            lat ?? 0.0,
            lng ?? 0.0,
          ),
          accuracy: row.read<int?>('accuracy'),
          lastSeen: row.read<DateTime?>('timestamp'),
          batteryStatus: row.read<int?>('battery_status'),
        );
      }).toList();
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
