# Local data management

The data-management screen provides inspect, export, preview, merge, replace,
selective reset, and delete-all operations for local application data. No
operation uploads data.

## Snapshot format

Exports are UTF-8 JSON documents with:

```json
{
  "formatVersion": 1,
  "schemaVersion": 3,
  "createdAt": "2026-07-23T12:00:00.000Z",
  "tables": {}
}
```

The complete allowlist contains:

1. `app_settings`
2. `player_profiles`
3. `games`
4. `moves`
5. `saved_games`
6. `match_history`
7. `statistics`
8. `daily_challenges`
9. `challenge_progress`
10. `wallet_balances`
11. `reward_transactions`
12. `challenge_events`
13. `achievements`
14. `tutorial_progress`
15. `practice_progress`
16. `recent_opponents`
17. `developer_preferences`

Migration bookkeeping is diagnostic state and is not restored from user
snapshots. Multiplayer room codes, reconnect tokens, sockets, temporary relay
state, logs, and other secrets are not database snapshot fields.

## Validation and preview

Preview parses the complete document before showing table and row counts. It
rejects malformed JSON, unsupported snapshot versions, schema mismatch, invalid
timestamps, missing tables, extra tables, and non-object rows.

Import runs in one SQLite transaction:

- merge inserts missing primary keys and preserves existing conflicts;
- replace deletes allowlisted tables in foreign-key-safe reverse order and then
  inserts them in dependency order;
- `PRAGMA foreign_key_check` must be empty before commit;
- any parse, constraint, or integrity failure rolls back the complete import.

Import never evaluates JSON values as code and never derives SQL identifiers
from the document.

## Selective controls

Confirmed actions are available for:

- match history;
- statistics;
- saved games and their owned game/move rows;
- challenge definitions, progress, and event receipts;
- reward ledger and balances;
- recent opponents;
- all allowlisted local application data.

Delete-all requires typing the localized confirmation token `DELETE`. Other
destructive actions require an explicit confirmation dialog. The UI reports
success or failure and never claims completion after an exception.

Reward-ledger export is a smaller JSON document containing only wallet balances
and ledger transactions. It excludes profiles, opponents, games, and settings.

## Diagnostics

Diagnostics report the current schema version, `PRAGMA quick_check`, row count
for every allowlisted table, and newest migration status. They do not expose
database paths or device identifiers.

## Verification

Real in-memory SQLite tests create the complete production schema and seed every
allowlisted table. Tests cover export/preview, delete, replace restoration,
idempotent merge, targeted reset isolation, reward-only export, unavailable
storage, malformed/future/unknown snapshots, and foreign-key integrity.
