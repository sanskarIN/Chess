# Daily challenges

The daily challenge system is local, deterministic, and available without an
account or Internet connection. Opening `/challenges` ensures three definitions
for the effective device-local date. The first challenge is always the broadly
eligible `Play 10 legal moves`; two more are selected by a versioned,
deterministic shuffle of the built-in catalog.

## Date and refresh behavior

- Calendar identity is `YYYY-MM-DD` in the device's local timezone.
- A challenge set remains stable throughout that local day.
- The screen shows an informational countdown to the next local midnight.
- Opening the screen, pulling to refresh, or recording a game event checks for a
  date rollover and creates the new set atomically.
- The effective last challenge date is stored in `app_settings` alongside the
  dated challenge rows.
- Prior dated rows remain available as challenge history.
- Debug builds expose a date picker that changes only the challenge date; it
  never changes the device clock. Unclaimed progress for the simulated date can
  be reset for migration and rollover testing.

This design intentionally has no mandatory time server. A fully offline app
cannot securely prevent a user from changing the device clock or modifying an
open-source local database. Chess-Master therefore never describes challenge
dates, coins, hints, ledger hashes, or streaks as tamper-proof.

## Definitions and eligibility

Each stored challenge contains an ID, title and description localization keys,
type, target, current progress, coin and hint reward, local date, completion and
claim timestamps, definition version, difficulty, and JSON eligibility rules.
The version-1 catalog covers legal moves, completed matches, no-hint matches,
White/Black wins, Beginner/Intermediate wins, queen captures, castling,
promotion, en passant, and local-match completion.

Only computer and local games emit Phase 7 progress. Friend matches do not
produce local rewards. Every game event has a stable receipt ID. Replayed
listeners, undo/redo notification repeats, and duplicate result callbacks cannot
increase progress twice for the same receipt.

## Completion and claiming

Progress is clamped to its target. Completion records a UTC timestamp, while the
challenge retains its separate local date. Claiming runs in one SQLite
transaction:

1. read and validate the challenge;
2. reject incomplete or missing challenges;
3. return the existing state when it is already claimed;
4. add each reward asset to the ledger and wallet;
5. mark the challenge claimed.

The presentation includes accessible progress bars, completed and claimed
states, a one-time reward animation, balances, streak, history, and an explicit
offline-integrity explanation.
