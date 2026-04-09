library drift_libsql;

import 'dart:async';

import 'package:drift/backends.dart';
import 'package:libsql_dart/libsql_dart.dart';

typedef ExtensionDescriptor = ({String path, String? entryPoint});

final class DriftLibsqlDatabase extends DelegatedDatabase {
  DriftLibsqlDatabase._(super.delegate);

  DriftLibsqlDatabase(
    String url, {
    String? authToken,
    String? syncUrl,
    int? syncIntervalSeconds,
    String? encryptionKey,
    bool? readYourWrites,
    bool? offline,
    bool enableExtensions = false,
    List<ExtensionDescriptor>? extensions,
  }) : this._(
          _LibsqlDelegate(
            LibsqlClient(
              url,
              authToken: authToken,
              syncUrl: syncUrl,
              syncIntervalSeconds: syncIntervalSeconds,
              encryptionKey: encryptionKey,
              readYourWrites: readYourWrites,
              offline: offline,
            ),
            extensions: extensions,
          ),
        );

  Future<void> sync() {
    return (delegate as _LibsqlDelegate).sync();
  }
}

final class _LibsqlDelegate extends DatabaseDelegate {
  final LibsqlClient _client;
  final List<ExtensionDescriptor> _extensions;

  bool _open = false;

  late DynamicVersionDelegate _versionDelegate;

  _LibsqlDelegate(
    this._client, {
    List<ExtensionDescriptor>? extensions,
  }) : _extensions = extensions ?? [];

  @override
  Future<void> runCustom(String statement, List<Object?> args) async {
    await _client.execute(statement, positional: args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    return _client.execute(statement, positional: args);
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

    _versionDelegate = await _VersionDelegateFactory.create(delegate: this);

    if (_extensions.isNotEmpty) {
      await _client.enableExtension();

      for (final ext in _extensions) {
        await _client.loadExtension(
          path: ext.path,
          entryPoint: ext.entryPoint,
        );
      }

      await _client.disableExtension();
    }

    _open = true;
  }

  Future<void> sync() async {
    await _client.sync();
  }

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  DbVersionDelegate get versionDelegate => _versionDelegate;
}

final class _VersionDelegateFactory {
  static Future<DynamicVersionDelegate> create(
      {required _LibsqlDelegate delegate}) async {
    final versionDelegate = _PragmaVersionDelegate(delegate: delegate);
    final completer = Completer<DynamicVersionDelegate>();
    versionDelegate.schemaVersion
        .then((_) => completer.complete(versionDelegate))
        .catchError((_) async {
      final tableVersionDelegate = _TableVersionDelegate(delegate: delegate);
      await tableVersionDelegate.init();
      completer.complete(tableVersionDelegate);
    });
    return completer.future;
  }
}

final class _TableVersionDelegate extends DynamicVersionDelegate {
  final _LibsqlDelegate delegate;

  _TableVersionDelegate({required this.delegate});

  Future<void> init({initial = 0}) async {
    await delegate.runCustom(
        'CREATE TABLE IF NOT EXISTS __drift_user_version (user_version INTEGER) STRICT;',
        []);
    final count = await delegate
        .runSelect('SELECT COUNT(*) FROM __drift_user_version;', []);
    if (count.rows.first.first == 0) {
      await delegate.runInsert(
          'INSERT INTO __drift_user_version (user_version) VALUES ($initial);',
          []);
    }
  }

  @override
  Future<int> get schemaVersion async {
    final result = await delegate._client
        .query('SELECT user_version FROM __drift_user_version;');
    return result.first['user_version'] as int;
  }

  @override
  Future<void> setSchemaVersion(int version) async {
    await delegate._client
        .execute('UPDATE __drift_user_version SET user_version = $version;');
  }
}

final class _PragmaVersionDelegate extends DynamicVersionDelegate {
  final _LibsqlDelegate delegate;

  _PragmaVersionDelegate({required this.delegate});

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
