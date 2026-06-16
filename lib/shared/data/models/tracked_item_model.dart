import 'package:drift/drift.dart';

class TrackedItems extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get privateKey => text()();

  IntColumn get color => integer()();

  TextColumn get emoji => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocationPoints extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get trackedItemId => text().references(TrackedItems, #id)();

  RealColumn get latitude => real()();

  RealColumn get longitude => real()();

  DateTimeColumn get timestamp => dateTime()();
}
