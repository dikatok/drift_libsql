# drift_libsql

Binding for Turso/Libsql database client for Drift

```
 replicaClient = AppDatabase(DriftLibsqlDatabase(
    "${dir.path}/replica.db",
    syncUrl: url,
    authToken: token,
    readYourWrites: true,
    syncIntervalSeconds: 3,
  ));
```
