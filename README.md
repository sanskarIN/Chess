# Chess-Master

Chess-Master is an in-progress, privacy-respecting, offline-first Android chess
game built with Flutter. The project is intended to become a complete
open-source game with standards-compliant chess rules, local and optional
self-hosted friend play, computer opponents, training, daily challenges, and
accessible multilingual interfaces.

**Open-source chess game**

**Made by the Sanskar**

> Development status: Phase 8 tutorial, practice, puzzle, guide, feature
> catalog, saved-game, validated FEN/PGN import, and move-review flows are
> implemented offline. Tutorial and practice rewards use idempotent local
> ledger sources, and SQLite schema v3 stores durable progress and saves. No
> real-money purchase or unverified native executable is bundled. See
> [feature status](docs/upcoming/feature_status.md) and the
> [continuation manifest](docs/development_manifest.md) for exact evidence.

## Privacy principles

- No account, login, analytics, advertising identifier, or behavioral tracking.
- Durable settings and game data stay in the application database on the device.
- Android cloud backup is disabled; explicit export/import will be user-controlled.
- Friend matches use an optional temporary WebSocket relay. That relay
  necessarily processes active room messages but does not permanently store
  games, names, profiles, or session tokens.
- Offline features must not wait for the multiplayer service during startup.
- Challenge progress, balances, and reward history stay in local SQLite. The app
  explicitly does not claim that a device-clock-based open-source economy is
  tamper-proof.

## Current application

- Configurable displayed app name with `Chess-Master` as the default.
- Material 3 light and dark themes with accessible target sizes.
- Typed GoRouter navigation.
- ARB-based localization generation with English as the fallback template.
- Riverpod dependency injection.
- Explicit success/failure values for expected application errors.
- Structured logging with redaction of names, addresses, tokens, and team codes.
- Versioned SQLite schema and atomic first-run creation.
- Privacy-safe Android manifest, local backup exclusions, and cleartext disabled
  outside debug builds.
- Fast branded splash with reduced-motion support.
- Optional ten-page onboarding with durable completion state.
- Responsive home, play-mode selection, and optional player setup.
- Legal-move-driven accessible chessboard with promotion choice.
- Captured-piece panels, material advantage, SAN history, undo/redo, board flip,
  draw, resignation, pause surface, PGN copy, and match result summary.
- Asynchronous computer play at four resource-bounded difficulty levels with
  move locking, thinking status, analysis details, cancellation, and recovery.
- Engine-neutral lifecycle API plus a tested UCI Stockfish process adapter.
- Android ABI discovery and a strict source/checksum/load-test manifest gate for
  any future native Stockfish package.
- Fully offline local two-player coordination with optional names and no server
  or network dependency.
- Monotonic two-sided clocks with increment, pause/resume, lifecycle pause,
  timeout results, rematch reset, and clock-aware history restoration.
- Fixed White, fixed Black, or automatic after-move orientation and explicit
  opponent approval for undo, redo, and draw offers.
- Optional friend matches with validated four- or six-digit room codes,
  create/join/waiting/ready flow, assigned colors, move acknowledgement,
  state-hash verification, reconnect handling, and actionable failure states.
- A self-hostable Node.js/TypeScript WebSocket relay with authoritative legal
  move validation, memory-only rooms, expiring reconnect sessions, rate limits,
  input limits, origin controls, health checks, and graceful shutdown.
- Deterministic local-date daily challenges with midnight rollover, progress,
  completed/claim/claimed states, history, streak, debug date simulation, and
  explicit offline integrity limits.
- Non-negative local coin/hint wallet and atomic, idempotent SQLite ledger with
  before/after balances, stable sequence, challenge links, app version, chained
  integrity fields, validation, and JSON clipboard export.
- Confirmed computer-game hints that show and semantically highlight a suggested
  source/target move; failed generation never charges the wallet.
- Seventeen interactive tutorial lessons with objectives, instructions, legal
  validation, retry, durable progress, and first-completion rewards.
- Offline free-board and legal-move practice, strict custom FEN loading, and a
  schema-verified original CC0 puzzle catalog for mate, tactics, openings, and
  endgames.
- Searchable in-app chess/privacy/troubleshooting guide and factual feature
  catalog with availability labels.
- Local save, resume, rename, delete, FEN copy, PGN export, validated FEN/PGN
  import, and immutable move-by-move review with optional local evaluation.

## Technology baseline

The source is verified with Flutter 3.44.7 stable and Dart 3.12.2. The available
machine currently has:

- Android Studio and an Android SDK
- Node.js 24.14.0
- npm 11.18.0
- Git 2.55.0.windows.3
- Java 8 on `PATH`, which is too old for this Android build; Android Studio's
  bundled OpenJDK 21 can compile the configured Java 17 target
- Dart SDK 3.12.2 stable
- Flutter 3.44.7 stable in a temporary SDK location
- Android SDK 36.1, with command-line tools and license acceptance still needed
  before an Android APK can be built

Use the JDK bundled with a current Android Studio or install JDK 17.

## Get started

1. Install Flutter 3.44.7 stable with its bundled Dart SDK.
2. Install Android Studio, Android SDK API 36, Android build tools, and JDK 17.
3. Resolve packages and generated localizations:

   ```powershell
   flutter pub get
   flutter gen-l10n
   ```

4. Verify the project:

   ```powershell
   dart format --set-exit-if-changed .
   flutter analyze
   flutter test
   flutter build apk --debug
   ```

The resolved `pubspec.lock`, Gradle wrapper scripts, and wrapper JAR are
committed. They were generated by the Flutter/Gradle toolchain, not hand-authored.

## Build-time configuration

The visible Flutter title can be changed without restructuring the application:

```powershell
flutter run --dart-define=CHESS_MASTER_APP_NAME="KnightForge"
```

Optional development values:

```text
CHESS_MASTER_ENVIRONMENT
CHESS_MASTER_RELAY_URL
CHESS_MASTER_STOCKFISH_PATH
```

No production relay URL is invented by default. Friend multiplayer remains
disabled until a distributor or self-hoster supplies an explicit `ws://` or
`wss://` relay URL. See [friend multiplayer](docs/friend_multiplayer.md) and
[server setup](server/README.md).

`CHESS_MASTER_STOCKFISH_PATH` is a development-only escape hatch for a local UCI
executable. It is classified as unverified and is never accepted as release
evidence. See [chess engine architecture](docs/chess_engine.md).

The Android launcher label is in
`android/app/src/main/res/values/strings.xml`. Update it alongside the build-time
Flutter title when preparing a renamed distribution.

## Documentation

- [Documentation index](docs/index.md)
- [Architecture](docs/architecture.md)
- [System requirements](docs/system_requirements.md)
- [Database migrations](docs/database_migrations.md)
- [Localization](docs/localization.md)
- [Logging](docs/logging.md)
- [Application flow](docs/app_flow.md)
- [UI and UX](docs/ui_ux.md)
- [Accessibility](docs/accessibility.md)
- [Splash screen](docs/splash_screen.md)
- [Captured pieces](docs/captured_pieces.md)
- [Game modes](docs/game_modes.md)
- [Chess engine](docs/chess_engine.md)
- [Local multiplayer](docs/local_multiplayer.md)
- [Friend multiplayer and relay](docs/friend_multiplayer.md)
- [Daily challenges](docs/daily_challenges.md)
- [Local reward economy](docs/reward_economy.md)
- [Chess hints](docs/hints.md)
- [Practice and tutorial](docs/practice_and_tutorial.md)
- [Puzzle catalog](docs/puzzle_catalog.md)
- [Saved games and review](docs/saved_games_and_review.md)
- [Roadmap phases](docs/upcoming/phases.md)
- [Exact next work](docs/upcoming/next.md)
- [Technology notes](docs/technologies/README.md)

The required `docs/users_suggest/`, expanded `docs/technologies/`, and
`docs/upcoming/` documentation sets are scheduled in the master phase order.
Files are added only when they contain substantive guidance.

## Repository and creator

- Repository: <https://www.github.com/sanskarIN/Chess>
- Creator: <https://www.github.com/sanskarIN>
- YouTube: <https://youtube.com/@Sanskar-in>
- LinkedIn: <https://www.linkedin.com/in/sanskarin>
- X: <https://www.x.com/Sanskar_in>
- Support: <mailto:supportramsandesh@gmail.com>
- Development contact: <mailto:sanskarin@outlook.in>

## License status

The intended project license is GNU GPL v3.0 or later because distributing
Stockfish has GPL compatibility consequences. A strict manifest and documented
rebuild process now guard the native packaging boundary. The complete license,
copyright notices, Stockfish source correspondence, and dependency audit will
be added and reviewed in Phase 11 before any binary distribution. No Stockfish
binary or source is included in the current repository.

This repository is not ready for Play Store publication. Signing, legal review,
policy review, accessibility testing, localization review, device testing, and
release QA remain required.
