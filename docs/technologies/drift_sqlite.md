# SQLite persistence choice

The master prompt permits Drift or an equally suitable local database. Phase 1
uses `sqflite` 2.4.3 with explicit, reviewed SQL because it:

- provides asynchronous Android SQLite operations;
- avoids generated database source while the SDK is unavailable;
- supports transactional schema creation and migrations;
- keeps persistence behind `AppDatabase` and future repository interfaces.

The filename is retained as `drift_sqlite.md` to match the requested technology
documentation tree. Drift remains replaceable because feature domain and
application layers will not import `sqflite`.

The schema is versioned and constrained, but device-backed migration and
serialization tests have not yet run.
