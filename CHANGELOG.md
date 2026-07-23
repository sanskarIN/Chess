# Changelog

All notable project changes are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
semantic versioning while the project remains pre-1.0.

## [Unreleased]

### Added

- Phase 7 deterministic device-local daily challenges with stable versioned
  definitions, midnight refresh, event-receipt deduplication, progress,
  completion, idempotent claiming, history, streak, and debug date simulation.
- SQLite schema v2 migration with non-negative coin/hint wallets, preserved v1
  reward data, explicit before/after balances, related challenge and app-version
  fields, stable ledger sequence, and chained integrity hashes.
- Local non-monetary reward UI with balance chips, accessible progress bars,
  completed/claimed states, claim animation, ledger validation, and JSON copy.
- Successful-result-first computer hints with 1-token or 25-earned-coin
  confirmation, source/target board highlights, localized explanations, and
  guaranteed no charge when generation fails.
- Real SQLite migration/concurrency tests plus generator, rollover, duplicate
  claim/spend, hint failure, challenge widget, and game-event integration tests.
- Phase 6 friend multiplayer create/join/waiting/ready flow using validated
  four- or six-digit team codes, assigned colors, privacy disclosure, clipboard
  and Android share actions, and explicit room/service error states.
- Versioned WebSocket client protocol with session-token reconnection,
  authoritative move acknowledgement, legal history replay, deterministic state
  hashes, synchronization failure handling, and bounded reconnect backoff.
- Self-hostable Node.js/TypeScript relay with memory-only expiring rooms,
  reconnect grace, rate/input/origin limits, authoritative `chess.js` move
  validation, safe structured logging, health endpoint, and graceful shutdown.
- Shared cross-language state-hash fixtures, Flutter client/widget tests, relay
  protocol/room/integration tests, CI workflow, and deployment/privacy/security
  documentation.
- Phase 5 fully offline local multiplayer coordinator with optional names,
  same-device action approval, draw offers, resignation, and rematch.
- Monotonic two-sided chess clock with common presets, per-move increment,
  pause/resume, lifecycle handling, timeout adjudication, and history-aware
  undo/redo restoration.
- Fixed-White, fixed-Black, and automatic after-each-move board orientation.
- Local setup controls for orientation and opponent-approved or always-allowed
  undo policy.
- Clock, timeout, approval, rotation, setup, and local game widget tests.
- Phase 4 engine-neutral computer-player domain, serialized service lifecycle,
  typed health/failure states, cancellation, restart, and incremental analysis.
- Isolate-backed legal local search with four documented difficulty presets,
  bounded depth/time/memory/thread configuration, and automatic computer turns.
- UCI message parser and Stockfish process adapter covering handshake,
  configuration, FEN positions, search, timeout, cancellation, crash, and retry.
- Android ABI discovery channel and strict native-engine source, checksum,
  packaging, load-test, and declaration verifier.
- Computer-game thinking progress, board and action locking, analysis display,
  performance warning, error reporting, and retry UI.
- Engine application, process-adapter, local-search, parser, lifecycle, and
  computer-game widget tests.
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
- No distribution-verified Stockfish executable is bundled; the tested UCI
  adapter currently falls back to the built-in local search opponent.
- Training, settings, complete locale set, legal package, and release QA remain
  in their prescribed later phases.
