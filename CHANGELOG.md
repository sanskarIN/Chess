# Changelog

All notable project changes are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
semantic versioning while the project remains pre-1.0.

## [Unreleased]

### Added

- Phase 3 core UI with a configurable branded splash, reduced-motion entrance,
  durable optional onboarding, responsive home, mode selection, and player setup.
- Accessible interactive chessboard with semantic squares, shape-based legal
  move and capture indicators, last-move/check highlights, and promotion choice.
- Game presentation for player identity, time-control display, turn status,
  captured material, SAN move history, undo/redo, draw, resignation, pause,
  board flip, PGN copying, and detailed match results.
- Flutter 3.44.7 dependency lockfile, generated English localization API, and
  Phase 3 application/widget tests.
- Complete pure-Dart Phase 2 chess domain with legal move generation, all
  standard special moves, FEN, SAN, PGN, perft, history, undo/redo, captures,
  restoration, repetition, clocks, and terminal results.
- Executable dependency-free chess verifier with passing standard perft depth 4,
  Kiwipete depth 3, and rook/endgame depth 4 references.
- Rule-specific unit tests for castling, en passant, promotion, pins, double
  check, mate, stalemate, repetition, insufficient material, notation, and
  saved-game restoration.
- Phase 1 Flutter application shell with configurable Chess-Master branding.
- Material 3 light and dark themes and typed navigation.
- English localization template and generated-localization configuration.
- Typed application errors and result values.
- Structured, redacting application logger.
- Versioned SQLite schema and database bootstrap.
- Android host configuration with cleartext disabled for non-debug builds and
  Android backup disabled.
- Foundation unit and widget tests.
- Initial architecture, technology, setup, and continuation documentation.

### Known limitations

- The Flutter application is formatted, analyzed, and tested. Android SDK
  command-line tools are missing, and the automatic NDK 28.2 download stalled,
  so the debug APK build has not completed.
- The Stockfish engine, clocks, friend relay, challenges/economy, training,
  settings, complete locale set, legal package, and release QA remain in their
  prescribed later phases.
