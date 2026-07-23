# Development continuation manifest

## Project identity

- Version: `0.3.0+3`
- Completed phase: 3 — Core UI
- Next phase: 4 — Computer Opponent
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

The target repository was empty before Phase 1, so `main` was initialized
directly without overwriting history. Phase 3 is ready for its boundary commit
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

## Commands executed for Phase 3

```text
flutter --version
flutter doctor -v
flutter pub get
flutter gen-l10n
dart format lib test tool
flutter analyze --no-pub
flutter test --no-pub
dart run tool/chess_domain_verifier/bin/verify.dart
```

## Verification results

```text
57 Flutter tests passed.
Flutter analysis: No issues found.
Chess domain verification passed.
```

Executed Phase 3 coverage includes:

- splash, onboarding persistence, skip, and home transition;
- malformed and invalid onboarding preference recovery;
- optional and Unicode player names;
- White, Black, and seeded Random assignment;
- legal square selection and move delegation;
- undo, redo, alternate continuation, captures, draw, resignation, and restart;
- semantic piece, square, and legal-move labels;
- game-screen move, SAN history, undo, and redo interaction;
- complete match-result content and selected action.

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
- Flutter unit/widget tests: 57 passed.
- Independent chess verifier: passed.
- Android resource compilation/linking: previously passed against API 36.
- Android debug APK: attempted. Flutter generated the Gradle 9.1 wrapper and
  selected Android Studio JDK 21. Gradle accepted the NDK license, then the
  automatic NDK `28.2.13676358` install stalled with a zero-byte archive; no APK
  was produced.
- Release app bundle: not run; signing is intentionally not configured.

## Known limitations

- The Stockfish adapter and native engine are not present; Phase 4 is next.
- Accurate monotonic local clocks and approval policy remain Phase 5.
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
lib/features/computer_player/domain/chess_engine.dart
```
