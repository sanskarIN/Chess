# SQLite persistence choice

The master prompt permits Drift or an equally suitable local database. Phase 1
uses `sqflite` 2.4.3 with explicit, reviewed SQL because it:

- provides asynchronous Android SQLite operations;
- avoids generated database source while the SDK is unavailable;
- supports transactional schema creation and migrations;
- keeps persistence behind `AppDatabase`, `TransactionalDatabase`, and feature
  repository interfaces.

The filename is retained as `drift_sqlite.md` to match the requested technology
documentation tree. Drift remains replaceable because feature domain and
application layers will not import `sqflite`.

The schema is versioned and constrained. Phase 7 executes clean schema creation,
v1-to-v2 data preservation, foreign-key validation, concurrent reward claims,
and balance constraints against a real SQLite engine using
`sqflite_common_ffi`. Android device migration QA remains part of release
qualification.
