# drift_libsql

Turso/Libsql database dart client for Drift

## Getting Started

### Add it to your `pubspec.yaml`.

```
drift_libsql:
```

### Follow drift docs per usual with the addition of DriftLibsqlDatabase

```dart
class TaskTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  BoolColumn get completed => boolean()();
}

@DriftDatabase(tables: [TaskTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

final db = AppDatabase(DriftLibsqlDatabase(
    "${dir.path}/replica.db",
    syncUrl: url,
    authToken: token,
    readYourWrites: true,
    syncIntervalSeconds: 3,
  ));

await db.into(db.taskTable).insert(TaskTableCompanion.insert(
	title: task.title,
	description: task.description,
	completed: task.completed));
```
