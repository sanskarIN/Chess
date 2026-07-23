# Practice and interactive tutorial

## Scope

Phase 8 provides an offline practice hub, a free legal-move board, strict custom
FEN loading, seventeen tutorial lessons, and five bundled exercises spanning
mate in one, mate in two, tactics, opening development, and pawn endgames.
Every move is checked by the same pure-Dart legal-move engine used by matches.
There is no network dependency.

## Tutorial contract

Each lesson has a stable ID, topic, initial position, one expected move or
coordinate, an objective, localized instructions, retry behavior, and a local
reward amount. The catalog covers:

1. board coordinates;
2. pawn, knight, bishop, rook, queen, and king movement;
3. captures, check, and checkmate;
4. castling, en passant, and promotion;
5. draws, basic tactics, opening principles, and basic endgames.

Incorrect attempts increment durable progress. Completion time is written only
once. The first-completion reward uses both a unique reward-ledger source and a
separate tutorial claim timestamp. Replaying a lesson is allowed, but cannot
mint another reward.

## Practice contract

The free board exposes legal destinations, captures, check state, undo, redo,
orientation, reset, and FEN copy. Custom FEN is parsed by `FenCodec`; all six
fields, king counts, adjacent kings, castling rights, and en-passant consistency
must be valid before a position opens.

Puzzle lines are UCI move sequences. The player supplies alternating solution
plies while the controller plays the documented reply. An incorrect move does
not change the board and records an attempt. A first solve grants ten local
coins through the idempotent reward ledger. Best move count and first solve time
are retained in SQLite schema v3.

## Persistence

`tutorial_progress` stores attempts, completion, reward claim, and update time.
`practice_progress` stores exercise type, attempts, first solve time, best move
count, and update time. In database-degraded mode, the same repository contract
uses process-memory storage and clearly does not promise persistence.

## Testing

Tests verify all seventeen expected tutorial moves, every bundled puzzle line,
incorrect-attempt behavior, automatic reply playback, first-only rewards, and
real SQLite progress semantics.
