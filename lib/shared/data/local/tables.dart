import 'package:drift/drift.dart';

@DataClassName('TrackedItemDbData')
class TrackedItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get publicKey => text()();
  IntColumn get color => integer()();
  TextColumn get emoji => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocationPointData')
class LocationPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trackedItemId => text().references(TrackedItems, #id)();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get timestamp => dateTime()();

  IntColumn get accuracy => integer().withDefault(const Constant(0))();
  IntColumn get batteryStatus => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{trackedItemId, timestamp}];
}
