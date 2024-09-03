import 'package:drift_libsql/drift_libsql.dart';
import 'package:drift_libsql_example/database.dart';
import 'package:drift_libsql_example/features/task/repositories/task_repository.dart';
import 'package:drift_libsql_example/features/task/task_list.dart';
import 'package:drift_libsql_example/infra/libsql_task_repository.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

const url = String.fromEnvironment("TURSO_URL");
const token = String.fromEnvironment("TURSO_TOKEN");

late AppDatabase memoryClient;
late AppDatabase localClient;
late AppDatabase remoteClient;
late AppDatabase replicaClient;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationCacheDirectory();

  memoryClient = AppDatabase(DriftLibsqlDatabase(":memory:"));
  localClient = AppDatabase(DriftLibsqlDatabase("${dir.path}/local.db"));
  remoteClient = AppDatabase(DriftLibsqlDatabase(url, authToken: token));
  replicaClient = AppDatabase(DriftLibsqlDatabase(
    "${dir.path}/replica.db",
    syncUrl: url,
    authToken: token,
    readYourWrites: true,
    syncIntervalSeconds: 3,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Libsql Dart Example')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Builder(builder: (context) {
            return Center(
              child: Column(
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Provider<TaskRepository>(
                            create: (context) =>
                                LibsqlTaskRepository(memoryClient),
                            child: const TaskList(),
                          ),
                        ),
                      );
                    },
                    child: const Text("Memory"),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Provider<TaskRepository>(
                            create: (context) =>
                                LibsqlTaskRepository(localClient),
                            child: const TaskList(),
                          ),
                        ),
                      );
                    },
                    child: const Text("Local"),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Provider<TaskRepository>(
                            create: (context) =>
                                LibsqlTaskRepository(remoteClient),
                            child: const TaskList(),
                          ),
                        ),
                      );
                    },
                    child: const Text("Remote"),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Provider<TaskRepository>(
                            create: (context) =>
                                LibsqlTaskRepository(replicaClient),
                            child: const TaskList(),
                          ),
                        ),
                      );
                    },
                    child: const Text("Replica"),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
