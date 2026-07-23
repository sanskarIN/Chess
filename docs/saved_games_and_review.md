# Saved games, import, and review

## Local save format

A save has its own stable ID, title, optional notes, full game setup, initial
FEN, current FEN, move sequence, player display names, result, and timestamps.
SQLite stores the game and moves under foreign-key constraints. Updating a save
replaces its owned move rows inside one transaction. Deleting a save cascades
only through its owned game record.

The serialized setup has `formatVersion: 1` and includes mode, names, human
color, time control, difficulty, hint setting, board orientation, rotation, and
undo policy. Unsupported setup formats fail closed.

## Operations

The saved-games screen supports:

- saving or updating the current match;
- resuming an active or imported position;
- renaming with a 1–80 character title;
- deleting with confirmation;
- copying current FEN;
- exporting PGN without relay URLs, room codes, or session details;
- importing strict FEN or PGN;
- opening move-by-move review.

Imports are treated only as chess text. FEN uses the canonical six-field
validator. PGN rejects duplicate or conflicting result tags, malformed tags,
illegal SAN, moves after the result, unmatched comments, and unmatched
variations. Imported data is never executed.

## Review

Review mode operates on the immutable `positionHistory` already produced by the
rules domain. First, previous, next, last, and direct move selection change only
the review cursor. FEN copy and PGN export remain available at every cursor.

When the saved setup had hints or analysis enabled, the user may request a
bounded local evaluation for the displayed position. Analysis is explicit,
asynchronous, canceled on disposal, and never required to review moves.

## Limitations

Phase 8 does not expose whole-application backup merge/replace. That belongs to
Phase 9 data management. Phase 8 also does not claim imported player names are
verified identities.
