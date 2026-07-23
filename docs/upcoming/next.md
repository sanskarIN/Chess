# Exact next work

Phase 7 is complete with 108 passing Flutter tests, including real SQLite
creation/migration/concurrency coverage, zero Flutter analyzer issues, 7 passing
relay-server tests, a passing TypeScript type check, zero reported production
npm vulnerabilities, a passing independent chess-domain verifier, and a passing
native-engine manifest verification.

Phase 8 starts with:

```text
lib/features/practice/domain/practice_exercise.dart
```

Phase 8 implementation order:

1. versioned tutorial lessons and durable local completion/reward state;
2. free board and legal piece-movement exercises;
3. bundled, attributable mate-in-one, mate-in-two, and tactical puzzle library;
4. opening-position and endgame practice plus validated custom FEN loading;
5. in-app guide and factual features catalog;
6. atomic save, resume, rename, delete, PGN export, FEN copy, and validated
   FEN/PGN import;
7. completed-game review with move stepping and optional local engine analysis;
8. tutorial, practice, puzzle, saved-game, import, and review widget/domain tests;
9. substantive guide, practice, puzzle-source, save-format, and review docs.

Before the Android debug build can complete, install Android SDK command-line
tools and repair the incomplete NDK `28.2.13676358` installation. Accept any
remaining SDK licenses through the official tool. Do not configure or use a
release signing key.
