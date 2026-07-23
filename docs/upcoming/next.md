# Exact next work

Phase 2 starts with:

```text
lib/features/chess/domain/board/square.dart
```

Before Phase 2 implementation, a toolchain-enabled environment must:

1. Install Flutter 3.44.7 stable and select JDK 17.
2. Generate the Gradle wrapper and Flutter project metadata.
3. Run `flutter pub get` and commit `pubspec.lock`.
4. Run `flutter gen-l10n`.
5. Run formatter, analyzer, foundation tests, and Android debug build.
6. Fix every discovered foundation error and update the development manifest.

Then implement pure-Dart chess value types in this order:

1. squares, files, ranks, colors, and piece types;
2. immutable pieces, moves, castling rights, and game state;
3. FEN parsing/serialization;
4. pseudo-legal and legal move generation;
5. checks, pins, special rules, and terminal results;
6. position hashing/history, SAN, PGN, undo/redo;
7. known perft and rule-specific tests.

Do not begin the core game UI until the required perft positions pass.
