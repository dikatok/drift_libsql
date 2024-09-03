library drift_libsql;

import 'dart:async';

import 'package:drift/backends.dart';
import 'package:libsql_dart/libsql_dart.dart';

final class LibsqlDatabase extends DelegatedDatabase {
  LibsqlDatabase._(super.delegate);

  LibsqlDatabase(
    String url, {
    String? authToken,
    String? syncUrl,
    int? syncIntervalSeconds,
    String? encryptionKey,
    bool? readYourWrites,
  }) : this._(_HranaDelegate(LibsqlClient(
          url,
          authToken: authToken,
          syncUrl: syncUrl,
          syncIntervalSeconds: syncIntervalSeconds,
          encryptionKey: encryptionKey,
          readYourWrites: readYourWrites,
        )));
}

final class _HranaDelegate extends DatabaseDelegate {
  final LibsqlClient _client;

  bool _open = false;

  _HranaDelegate(this._client);

  @override
  Future<void> runCustom(String statement, List<Object?> args) async {
    await _client.execute(statement, positional: args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    final _ = await _client.query(statement, positional: args);
    return 0;
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    final res = await _client.query(statement, positional: args);
    return QueryResult.fromRows(res);
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    return _client.execute(statement, positional: args);
  }

  @override
  FutureOr<bool> get isOpen => Future.value(_open);

  @override
  Future<void> open(QueryExecutorUser db) async {
    await _client.connect();
    _open = true;
  }

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  DbVersionDelegate get versionDelegate =>
      _HranaVersionDelegate(delegate: this);
}

final class _HranaVersionDelegate extends DynamicVersionDelegate {
  final _HranaDelegate delegate;

  _HranaVersionDelegate({required this.delegate});

  @override
  Future<int> get schemaVersion async {
    final result = await delegate._client.query('pragma user_version;');
    return result.first['user_version'] as int;
  }

  @override
  Future<void> setSchemaVersion(int version) async {
    await delegate._client.execute('pragma user_version = $version;');
  }
}