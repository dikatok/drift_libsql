import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_libsql_example/database.dart';
import 'package:drift_libsql_example/features/task/models/models.dart';
import 'package:drift_libsql_example/features/task/repositories/repositories.dart';

class LibsqlTaskRepository extends TaskRepository {
  final AppDatabase _database;

  LibsqlTaskRepository(this._database);

  @override
  Future<void> addTask(Task task) async {
    await _database.into(_database.taskTable).insert(TaskTableCompanion.insert(
        title: task.title,
        description: task.description,
        completed: task.completed));
  }

  @override
  Future<void> deleteTask(int id) async {
    await (_database.delete(_database.taskTable)..where((t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<List<Task>> getTasks() async {
    return (_database.select(_database.taskTable).map((t) => Task(
        id: t.id,
        title: t.title,
        description: t.description,
        completed: t.completed))).get();
  }

  @override
  Future<void> markTasksAsCompleted(List<int> ids) async {
    await (_database.update(_database.taskTable)..where((t) => t.id.isIn(ids)))
        .write(const TaskTableCompanion(completed: Value(true)));
  }
}
