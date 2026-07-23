# Puzzle catalog

## File format

Training positions live in `assets/puzzles/training_positions.json`. The
machine-readable contract is `assets/puzzles/schema.json`. Each item requires:

- a stable lowercase-hyphenated ID;
- one supported type;
- localized title and description keys;
- a valid FEN;
- a non-empty UCI solution;
- a difficulty;
- source and license attribution.

The current five-position catalog was written for Chess-Master and dedicated
under CC0-1.0. It does not copy a commercial puzzle database. Attribution and
license information remain attached to every record.

## Verification

Run:

```powershell
dart run tool/verify_puzzles.dart
```

The verifier rejects malformed envelopes, duplicate IDs, missing attribution,
invalid FEN, illegal moves, non-mating mate solutions, and incorrect mate-line
lengths. Flutter tests independently load the application asset and replay
every move through `ChessGame`. CI runs the verifier before the Flutter suite.

Adding a position requires updating the JSON catalog, English localization
keys, any translated locale packs, source/license records, and tests. Never add
a position from a restricted or unattributed database.
