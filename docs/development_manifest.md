# Development continuation manifest

## Project identity

- Version: `0.5.0+5`
- Completed phase: 5 — Local Multiplayer
- Next phase: 6 — Friend Multiplayer
- Updated: 2026-07-23
- Default name: Chess-Master
- Watermark: Made by the Sanskar
- Repository: <https://github.com/sanskarIN/Chess>
- Active branch: `main`
- Commit identity: `Sanskar <sanskarin@outlook.in>`

## Published boundaries

Phase 1 was committed and pushed before Phase 2 as requested.

| Boundary | Commit | Remote state |
| --- | --- | --- |
| Phase 1 foundation | `c10351b3b735b80dd7e3201d83c6feffbc673f91` | Published on `origin/main` |
| Phase 2 chess domain | `498d41333ca6c9b227a86e7df506df815c2fff75` | Published on `origin/main` |
| Phase 3 core UI | `1be99bd9ed4618285faaa34fffb8cd378746f0fe` | Published on `origin/main` |
| Phase 4 computer opponent | `31717765384f61a8b1aa0b531992962af6670a95` | Published on `origin/main` |

The target repository was empty before Phase 1, so `main` was initialized
directly without overwriting history. Phase 5 is ready for its boundary commit
after this manifest update.

## Phase 1 completed source

- Flutter bootstrap and global error capture
- Configurable application identity and version
- Riverpod dependency injection
- GoRouter navigation and localized route errors
- Material 3 light/dark themes
- ARB localization architecture
- Structured application errors and explicit result values
- Redacting structured logger
- SQLite v1 schema, constraints, indices, lifecycle, and atomic creation
- Privacy-safe Android manifest, network policy, backup exclusions, adaptive
  icons, and launch resources
- Initial unit/widget tests, CI, and documentation

## Phase 2 completed source

- Canonical board, piece, move, castling, and immutable position models
- Legal generation, attack/check detection, castling, en passant, promotion,
  pins, double check, mate, and stalemate
- Threefold repetition, fifty-move rule, insufficient material, draw agreement,
  resignation, and timeout
- Stable game/move IDs, capture and position history, undo/redo, branching, and
  validated restoration
- FEN, SAN, PGN, perft, public domain barrel, detailed tests, and independent
  dependency-free verifier

## Phase 3 completed source

- Original scalable code-drawn Chess-Master knight mark
- Fast localized splash with reduced-motion handling and storage-degraded flow
- Ten-page optional onboarding with back/next/skip/finish, persistent
  `do not show again`, and corruption-safe preference reads
- Responsive home dashboard and typed play-mode routes
- Honest offline, online, experimental, and planned feature states
- Computer and local player setup with optional names, safe validation,
  White/Black/Random side selection, difficulty, clocks, hints, and rotation
- Typed game setup and a `ChangeNotifier` application controller
- Responsive portrait/landscape chessboard driven only by legal domain moves
- Semantic square, piece, move, capture, last-move, selected, and check labels
- Color-independent move dot and capture ring
- Promotion picker for queen, rook, bishop, and knight
- Player banners, displayed time controls, turn/check live status
- Captured-by-White and captured-by-Black panels with optional material lead
- SAN move history, undo, redo, draw agreement, resignation, pause surface,
  board flip, settings/sound/hint status messaging, and permanent watermark
- Match result dialog with reason, winner, duration, move/capture/hint counts,
  rewards status, rematch, review, PGN copy, and home
- Phase 3 UI, accessibility, flow, game-mode, splash, and capture documentation

## Phase 4 completed source

- Engine-neutral contracts for lifecycle, configuration, moves, analysis,
  health, failure, process transport, cancellation, and disposal
- Four validated difficulty presets with bounded depth, time, memory, skill, and
  single-thread CPU use
- Isolate-backed iterative legal search used by the current computer player
- Serialized engine service and computer-turn controller with automatic White
  opening, stale-move prevention, and legal-move revalidation
- Typed UCI parser and Stockfish adapter for handshake, readiness, options, FEN,
  search, analysis, best move, timeout, stop, crash, restart, and disposal
- Android supported-ABI reporting and explicit verified-distribution metadata
  boundary
- Locked board/action interaction while thinking, progress status, analysis,
  errors, retry, and Grandmaster performance warning
- Strict native-engine JSON manifest/schema/verifier and documented official
  Stockfish 18 source/rebuild/GPL requirements
- Domain, local-search, controller, UCI, process-adapter, and widget tests

## Phase 5 completed source

- Monotonic time-source boundary and two-sided clock domain
- Initial time, per-move increment, active-side switching, zero clamping, and
  timeout detection
- Pause/resume and app-lifecycle pause without charging hidden time
- Move-token clock history with undo, redo, alternate-branch, and rematch reset
- Match clock coordinator covering both local and computer game screens
- Local match controller with named requester/approver actions
- Configurable always-allowed or opponent-approved undo and redo
- Opponent-approved draw offers, resignation, pause, and rematch coordination
- Fixed White, fixed Black, rotating, and manual board orientation
- Live, accessible tabular clock display in both player banners
- Clock, controller, setup, timeout, approval, orientation, and widget tests

## Toolchain evidence

```text
Flutter 3.44.7 • channel stable
Framework revision 84fc5cbb22
Engine revision 69c8c61792
Dart 3.12.2
DevTools 2.57.0
Android SDK 36.1.0
```

`flutter doctor -v` passed Flutter, Windows, Chrome, Visual Studio, connected
devices, and network resources. It reported:

- Android SDK command-line tools missing;
- Android license status unknown;
- Flutter and Dart temporary SDK paths not added permanently to `PATH`.

## Commands executed through Phase 5

```text
flutter --version
flutter doctor -v
flutter pub get
flutter gen-l10n
dart format lib test tool
flutter analyze --no-pub
flutter test --no-pub
dart run tool/chess_domain_verifier/bin/verify.dart
dart run tool/verify_engine_manifest.dart
```

## Verification results

```text
79 Flutter tests passed.
Flutter analysis: No issues found.
Chess domain verification passed.
Engine manifest valid; no native binary is declared or bundled.
```

Executed coverage through Phase 5 includes:

- splash, onboarding persistence, skip, and home transition;
- malformed and invalid onboarding preference recovery;
- optional and Unicode player names;
- White, Black, and seeded Random assignment;
- legal square selection and move delegation;
- undo, redo, alternate continuation, captures, draw, resignation, and restart;
- semantic piece, square, and legal-move labels;
- game-screen move, SAN history, undo, and redo interaction;
- complete match-result content and selected action.
- difficulty validation and preset resource limits;
- local-search legal move selection, cancellation, and lifecycle state;
- UCI handshake, option configuration, search, stop, timeout, crash, and retry;
- computer automatic White opening and post-search legal move application;
- disabled board semantics and visible status while the computer is thinking;
- engine source/checksum/ABI/declaration manifest validation.
- monotonic clock consumption, increments, pause/resume, and zero clamping;
- timeout result declaration and in-flight computer-search cancellation;
- clock state restoration for undo, redo, and branched history;
- named opponent approval and decline for undo, redo, and draw;
- always-allow local undo policy;
- fixed Black and automatic after-move board rotation;
- local setup controls, live clock rendering, rematch, and resignation.

Phase 2 perft remains:

| Position | Depth 1 | Depth 2 | Depth 3 | Depth 4 |
| --- | ---: | ---: | ---: | ---: |
| Standard start | 20 | 400 | 8,902 | 197,281 |
| Kiwipete | 48 | 2,039 | 97,862 | Not run |
| Rook/en-passant endgame | 14 | 191 | 2,812 | 43,238 |

## Build status

- Dependency resolution: passed; root `pubspec.lock` generated.
- Localization generation: passed; English Dart output generated.
- Dart formatting: passed.
- Flutter static analysis: passed with zero issues.
- Flutter unit/widget tests: 79 passed.
- Independent chess verifier: passed.
- Native engine manifest verifier: passed with zero binaries declared.
- Android resource compilation/linking: previously passed against API 36.
- Android debug APK: attempted. Flutter generated the Gradle 9.1 wrapper and
  selected Android Studio JDK 21. Gradle accepted the NDK license, then the
  automatic NDK `28.2.13676358` install stalled with a zero-byte archive; no APK
  was produced.
- Release app bundle: not run; signing is intentionally not configured.

## Known limitations

- The Stockfish adapter is implemented and tested, but no distribution-verified
  native binary is bundled. Computer play uses the built-in local search.
- Friend rooms, WebSocket protocol, and relay remain Phase 6.
- Daily challenges, coins, and purchasable hints remain Phase 7.
- Practice, tutorial, saves, and review mode remain Phase 8.
- Settings/developer options remain Phase 9.
- Only English is generated; all 33 locale packs remain Phase 10.
- Complete legal files, notices, and final documentation remain Phase 11.
- Android command-line tools and a complete NDK installation are required
  before repeating the debug APK build.
- Android, device accessibility, performance, integration, and release checks
  remain Phase 12.

## Exact next file

```text
lib/features/friend_multiplayer/domain/team_code.dart
```
