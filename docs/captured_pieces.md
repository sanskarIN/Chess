# Captured pieces

`ChessGame` records the captured piece on every validated move, including en
passant. `ChessGameController.capturedBy` derives the pieces captured by each
side from the current move cursor. Undo, redo, alternate continuation, and
restoration therefore update the display from authoritative history instead of
maintaining a second mutable capture list.

The UI shows separate `Captured by White` and `Captured by Black` rows. Pieces
are ordered queen, rook, bishop, knight, pawn. Kings never appear because legal
chess ends by checkmate rather than king capture.

Optional material advantage uses conventional display-only values:

| Piece | Value |
| --- | ---: |
| Pawn | 1 |
| Knight | 3 |
| Bishop | 3 |
| Rook | 5 |
| Queen | 9 |
| King | none |

The leading side receives a `+N` value. These values do not affect rules,
results, engine evaluation, rewards, or statistics. Phase 9 exposes the setting
that hides material scores. Friend matches synchronize the same move history for
friend matches rather than sending an untrusted capture list.
