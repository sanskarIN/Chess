# Chess rules domain

The Chess-Master rules layer is pure Dart. It imports no Flutter widgets,
database plugins, engine code, or networking code. Every game mode will use this
same layer so local, computer, saved, puzzle, and friend matches cannot silently
diverge on legality.

## Board and state

Squares use canonical indices `0..63`, where `a1` is zero and `h8` is 63.
Positions are immutable and contain:

- exactly 64 piece slots;
- the side to move;
- four independent castling rights;
- an optional en passant target;
- the halfmove clock;
- the fullmove number.

`Position.applyUnchecked` is the single state transition used after a move has
been validated. It handles rook movement during castling, removal of an en
passant pawn, mandatory promotion choice, castling-right loss, en passant target
creation, clocks, captures, and turn changes.

## Legal move generation

`MoveGenerator` creates piece-specific pseudo-legal moves and filters every move
that leaves the moving king attacked. Attack detection is independent of legal
move generation, so pinned pieces still defend squares as required for king
safety.

Implemented rules:

- pawn single/double movement and diagonal captures;
- knight, bishop, rook, queen, and king movement;
- king-side and queen-side castling;
- castling-right, empty-path, in-check, through-check, and destination checks;
- en passant, including discovered self-check rejection;
- queen, rook, bishop, and knight promotion;
- check, checkmate, stalemate, pins, and double check;
- prevention of king capture and self-check.

## Results and history

`ChessGame` owns a stable game ID, immutable position history, stable move IDs,
SAN records, captured pieces, and an undo/redo cursor. New play after undo
replaces the abandoned redo branch.

Automatic results:

- checkmate;
- stalemate;
- threefold repetition;
- fifty-move rule at 100 halfmoves;
- conventional insufficient-material dead positions.

Declared results:

- draw agreement;
- resignation;
- timeout, including a draw when the nominal winner has no possible mating
  material;
- imported/adjudicated PGN result.

Repetition identity uses piece placement, side to move, castling rights, and an
en passant square only when a legal en passant capture exists.

## Notation

`FenCodec` strictly reads and writes all six FEN fields. It validates rank sizes,
pieces, king count and adjacency, clocks, castling pieces, and en passant state.

`SanCodec` writes and reads:

- piece letters and pawn moves;
- captures;
- file/rank/both disambiguation;
- castling;
- promotion;
- check and checkmate suffixes.

`PgnCodec` writes tag pairs and wrapped movetext. Import validates tag
duplicates, FEN setup, SAN legality, comments, numeric annotation glyphs,
variations, and result consistency. Every imported move is replayed through the
local legal-move generator.

## Executed validation

The dependency-free verifier runs the real domain source with Dart 3.12.2:

```text
cd tool/chess_domain_verifier
dart pub get
dart run bin/verify.dart
dart analyze bin/verify.dart ../verify_chess_domain.dart ../../lib/features/chess/domain
```

Passed reference counts:

| Position | Depth 1 | Depth 2 | Depth 3 | Depth 4 |
| --- | ---: | ---: | ---: | ---: |
| Standard start | 20 | 400 | 8,902 | 197,281 |
| Kiwipete | 48 | 2,039 | 97,862 | Not run |
| Rook/en-passant endgame | 14 | 191 | 2,812 | 43,238 |

The verifier also executes castling, pinned en passant, four promotion choices,
stalemate, threefold repetition, fifty-move detection, insufficient material,
PGN checkmate round-trip, and timeout material handling.

Flutter unit-test files cover the same behavior plus detailed FEN, SAN, PGN,
capture, undo/redo, restoration, pin, double-check, and result cases. Those
Flutter test files remain pending until the Flutter SDK is installed.
