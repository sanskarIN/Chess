# Development continuation manifest

## Project identity

- Version: `0.12.0+12`
- Completed phase: 12 — QA and release preparation
- Next phase: none — all planned source phases are complete
- Updated: 2026-08-04
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
| Phase 5 local multiplayer | `df5f9d37b18d6939b20d05a8aa51c4ac83466dc4` | Published on `origin/main` |
| Phase 6 friend multiplayer | `7b4cf5b330ab316128cc65dbd290ea288f6c4e1d` | Published on `origin/main` |
| Phase 7 challenges and economy | `e139bbf99e39544e88c69139d71d851439bf3609` | Published on `origin/main` |
| Phase 8 practice and guide | `e7b0104048e1d2021549870944e8eb905be09213` | Published on `origin/main` |
| Phase 9 settings and developer options | `b3390cf016a7c5bd736af5a480a616de383df4ca` | Published on `origin/main` |
| Phase 10 localization | `721d3817dcc75ee7f966226deb0d33d59680d27c` | Published on `origin/main` |
| Phase 11 legal and documentation | `a4b231ed4121c6d469d8e1026f6d38511a91e850` | Published on `origin/main` |

The target repository was empty before Phase 1, so `main` was initialized
directly without overwriting history. Every completed boundary through Phase 11
is present on `origin/main`.

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

## Phase 6 completed source

- Validated four- and six-digit team-code value object with leading-zero support
- Versioned JSON WebSocket envelope and shared cross-language state-hash fixtures
- Create, join, waiting-room, copy/share, ready, assigned-color, expiry, privacy,
  service-failure, and synchronization-failure UI
- Reconnecting Flutter WebSocket transport with bounded backoff and session tokens
- Optimistic local move locking until authoritative relay acknowledgement
- Legal remote-history replay and state-hash verification before UI application
- Self-hostable Node.js/TypeScript relay under `server/`
- Memory-only rooms with no accounts, profiles, database, analytics, advertising,
  or permanent game/name/session history
- Authoritative `chess.js` turn, ply, legal-move, FEN, and state-hash validation
- Room expiry, reconnect grace, tombstones, rate and message-size limits, optional
  origin allowlist, safe logging, health endpoint, and graceful shutdown
- Flutter client/controller/lobby/game tests and Node protocol/room/server tests
- Relay CI, protocol, deployment, privacy, security, and troubleshooting docs

## Phase 7 completed source

- Strict local-date value object and deterministic versioned three-challenge
  generation with a stable all-player legal-move challenge
- Stored title/description localization keys, type, target, progress, coin/hint
  reward, date, completion/claim timestamps, version, difficulty, and eligibility
- Stable game-event receipts for move, queen capture, castle, promotion, en
  passant, completed/no-hint/local matches, side wins, and computer difficulty
- SQLite v2 creation and safe v1 upgrade preserving challenges and reward rows
- Explicit non-negative coin/hint wallet and atomic transaction ledger with
  sequence, before/after balances, source, challenge, app version, and hash chain
- One-time 50-coin/1-hint onboarding grant, concurrent-safe idempotent claims,
  duplicate hint purchase protection, and negative-balance rejection
- Daily screen with countdown, balances, streak, progress, completed/claim/
  claimed states, reward animation, history, integrity notice, ledger validation,
  JSON copy, pull refresh, and debug date simulation/reset
- Successful-result-first local hint search with token/coin confirmation,
  no-charge failure handling, source/target highlight, semantics, and explanation
- Real SQLite clean-creation, v1 migration, foreign-key, concurrent-claim, and
  spending tests plus domain/controller/game/widget coverage
- Daily challenge, reward economy, hint, migration, flow, and UI documentation

## Phase 8 completed source

- SQLite v3 practice-progress table plus saved-game and tutorial query indices
- Seventeen interactive tutorial lessons with localized objectives,
  instructions, legal validation, retry, durable attempts/completion, and
  idempotent first-completion coin rewards
- Offline free board with legal destinations, captures, check state, promotion,
  undo, redo, reset, orientation, and FEN copy
- Strict custom-FEN loading through the canonical six-field position validator
- Original, attributed CC0 training catalog for mate in one, mate in two,
  tactics, opening development, and pawn endgames
- JSON Schema contract, legal-line/mate verifier, catalog asset tests, and CI
  verification for bundled puzzles
- Durable practice attempts, first solve, and best move count in SQLite with a
  process-memory degraded-mode implementation
- Searchable in-app guide covering rules, modes, rewards, privacy, accessibility,
  settings, developer tools, troubleshooting, and upcoming work
- Searchable feature catalog with factual Available, Beta, Planned, and Premium
  candidate labels
- Atomic local save/update, resume, rename, confirmed delete, FEN copy, PGN
  export, and strictly validated FEN/PGN import
- Versioned complete game-setup serialization and full move-history restoration
- Immutable first/previous/next/last/direct-ply review with FEN/PGN copy and
  explicitly requested bounded local evaluation when enabled
- Practice, puzzle-source, tutorial, save-format, import, review, and guide
  documentation

## Phase 9 completed source

- Versioned, corruption-safe `AppSettings` serialization with typed enums,
  typed boolean settings, typed feature flags, bounded values, memory fallback,
  reset, and live Riverpod controller
- General, appearance, gameplay, sound/haptic, computer, multiplayer,
  challenge/reward, language, accessibility, privacy/data, about, and creator
  groups using progressive disclosure
- Live theme, high-contrast, reduced-motion, locale, start-route, board palette,
  legal-marker, coordinate, highlight, animation, piece emphasis, panel
  visibility, engine evaluation, promotion, feedback, and confirmation behavior
- Saved new-game name/side/difficulty/clock/hints/orientation/undo defaults,
  explicit disabled undo policy, per-game auto-save, and resume-newest-save
- Android keep-screen-on method channel and fullscreen restoration with
  non-Android/test-host fallback
- Safe `https:`/`mailto:` creator links with clipboard fallback and exact
  repository/support/development destinations
- Seven-tap persisted developer unlock with remaining-step messages and a
  guarded direct route
- Application, runtime, engine, database, migration, locale, theme, and
  multiplayer diagnostics without sensitive identifiers
- Typed debug/log/localization flags disabled by default
- Production-codec FEN, PGN, board-state, validation, perft, and special-position
  tools
- Ledger-safe signed/idempotent developer balance adjustments, reward duplicate
  checks, ledger export, challenge completion/claim/date/refresh tools
- Validated relay editing, opt-in bounded health connection, local latency/loss/
  disconnect/reconnect simulations, privacy-safe room state/hash, and protocol
  display
- Versioned 17-table JSON snapshot preview/export/atomic merge/atomic replace,
  foreign-key verification, diagnostics, selective resets, reward-only export,
  and typed DELETE confirmation
- Real SQLite full-table round-trip/merge/reset/integrity tests plus settings,
  controller, screen, developer guard, data confirmation, ledger adjustment,
  and board integration coverage
- Settings, Developer Options, and local data-format documentation

## Phase 10 completed source

- Exact typed product catalog for Assamese, Bengali, Bodo, Dogri, Gujarati,
  Hindi, Kannada, Kashmiri, Konkani, Maithili, Malayalam, Manipuri/Meitei,
  Marathi, Nepali, Odia, Punjabi, Sanskrit, Santali, Sindhi, Tamil, Telugu,
  Urdu, Bhojpuri, Rajasthani, Chhattisgarhi, Tulu, Garhwali, Kumaoni, Magahi,
  Haryanvi, Awadhi, Gondi, and English
- Standard base resource/settings identifiers plus documented `Arab`, `Guru`,
  `Mtei`, and `Olck` runtime script subtags
- Exactly 33 ARB files with 931 non-empty messages each, exact key/metadata/
  placeholder parity, and English fallback instead of raw keys or empty text
- Explicit translation status distinguishing the verified English source from
  32 `community_review_required` fallback drafts
- Contribution-safe generator ownership that preserves translation drafts once
  a locale moves to `community_translation` or `reviewed_translation`
- Searchable native/English/alias/identifier selector, device-language reset,
  immediate switching without restart, and durable settings persistence
- English fallback for unsupported system locales and for failed number/date
  formatting, with documented related-language formatting fallbacks
- Right-to-left navigation for Kashmiri, Sindhi, and Urdu plus a left-to-right
  chessboard boundary preserving logical file/rank/square/notation order
- Native-and-English TalkBack semantics, selected state, expanded-text preview,
  font fallback stack, pseudo-localization, and uncommon-locale delegate fallback
- CI-enforced locale generation drift, resource JSON, key, placeholder, empty
  value, locale count, status, RTL, formatting, pseudo, glyph, semantics,
  large-text, persistence, and logical-board-direction coverage
- Complete localization, identifier, completeness, review policy, and
  contributor documentation without claiming unreviewed translations

## Phase 11 completed source

- Complete GNU GPL version 3 license text with the project’s
  `GPL-3.0-or-later` grant, copyright record, notice, authorship, and changelog
- Dependency notice inventory spanning Flutter/Dart, the Node relay, original
  assets, puzzle data, fonts, and the explicitly unbundled Stockfish boundary
- Automated verification of the complete project license, required legal and
  policy documents, resolved hosted Dart package license files, npm lockfile
  license expressions, and non-bundling claims
- Stockfish corresponding-source, build-script, checksum, ABI, notice, offer,
  and artifact-inspection requirements for any future distributor
- Privacy policy and implementation-level data map covering SQLite, exports,
  relay memory, logs, Android backup, links, and optional network activity
- Terms, security reporting, threat model, support, conduct, contribution,
  governance, authorship, and community decision policies
- Structured GitHub issue forms and pull-request template with privacy,
  testing, accessibility, licensing, and scope checks
- Substantive user-suggestion workflow, triage rubric, proposal template, and
  community-priority record
- Expanded Android, Material 3, GoRouter, localization, GitHub Actions, Gradle,
  and release technology notes with a checked documentation index
- Localized in-app copyright, GPL, no-warranty, source, and changelog summaries
  plus Flutter’s runtime third-party license registry
- CI-enforced relative-link, documentation-set, legal-file, dependency-license,
  distribution-claim, localization, source, test, and analysis verification

## Phase 12 completed source

- Idempotent completed-match recording across games, moves, and local history,
  with result/mode/color/difficulty filters and immutable review reconstruction
- Complete derived statistics for results, difficulty, side, length, moves,
  captures, hints, challenges, rewards, puzzles, and current/best play streaks
- Confirmed statistics reset boundary that preserves match history and one-time
  achievement unlock timestamps
- Fifteen deterministic achievements spanning first actions, wins, checkmate,
  castling, promotion, puzzles, challenges, no-hint play, game counts, and local/
  friend completion
- History, statistics, and achievements UI with local privacy disclosure,
  filtering, empty states, review routing, locale-aware dates, progress, and
  reset confirmation
- Real SQLite repository tests, presentation tests, and an Android emulator
  integration smoke flow
- Deterministic CycloneDX 1.5 source SBOM covering locked Flutter/Dart and Node
  dependency graphs
- Machine-readable 20-gate release status plus accessibility, security,
  performance, Android build, reproducibility, provenance, signing, store,
  rollback, incident, limitation, and release-note documentation
- Android build fixes for debug cleartext override, cross-drive Kotlin caches,
  and Kotlin's reserved `in` package segment
- Successful debug APK build with size/checksum evidence while release signing,
  store mutation, physical-device approval, translations, and legal sign-off
  remain external

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
devices, and network resources. It reported missing Android command-line tools
for interactive SDK/license management, but Gradle successfully installed the
accepted NDK `28.2.13676358` and Android Platform 35 required by the build.

## Commands executed through Phase 12

```text
flutter --version
flutter doctor -v
flutter pub get
flutter gen-l10n
dart run tool/generate_locale_fallbacks.dart --check
dart run tool/generate_source_sbom.dart --check
dart run tool/verify_localizations.dart
dart run tool/verify_legal.dart
dart run tool/verify_documentation.dart
dart run tool/verify_release_readiness.dart
dart format lib test integration_test tool
dart analyze lib test integration_test tool
flutter test --coverage --no-pub
flutter test --no-pub -d emulator-5554 integration_test/app_smoke_test.dart
flutter build apk --debug --no-pub
dart run tool/chess_domain_verifier/bin/verify.dart
dart run tool/verify_engine_manifest.dart
dart run tool/verify_puzzles.dart
cd server
npm ci --offline
npm run check
npm test
```

## Verification results

```text
161 Flutter unit/widget tests passed.
1 Android API 36.1 integration test passed.
Coverage baseline: 8,204 / 43,250 lines (18.97%).
7 Node relay tests passed.
Flutter analysis: No issues found.
TypeScript type check passed.
npm production dependency audit: 0 vulnerabilities at the Phase 8 boundary;
the relay lockfile is unchanged in Phase 9.
Chess domain verification passed.
Engine manifest valid; no native binary is declared or bundled.
Puzzle catalog valid: 5 positions.
```

Executed coverage through Phase 11 includes:

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
- four- and six-digit room-code parsing, leading zeros, invalid input, and
  redacted representation;
- protocol envelope parsing and deterministic shared Dart/Node state hashes;
- create, join, ready, move acknowledgement, duplicate action protection, and
  verified state synchronization;
- reconnect session resumption, exhausted reconnect attempts, and typed relay
  failures;
- friend lobby create/join/privacy/waiting behavior and synchronized game moves;
- relay rate limiting, room lifecycle, legal move validation, HTTP health,
  WebSocket ping/pong, and graceful shutdown.
- local-date parsing, impossible-date rejection, deterministic selection, and
  stable three-challenge generation;
- duplicate event receipts, target clamping, completion, repeated claim, and
  wallet credit exactly once;
- SQLite v2 clean creation and v1 upgrade with retained challenge/reward data;
- concurrent claim serialization, idempotent hint spending, insufficient funds,
  and non-negative balance enforcement;
- reward ledger hash-chain validation and JSON-ready complete fields;
- simulated date rollover without changing the device clock;
- failed hint generation with no purchase entry and successful-result-first
  token/coin charging;
- challenge cards, balance display, progress, offline notice, claim animation,
  source/target hint presentation, and actual game-event hooks.
- all seventeen tutorial objectives use a legal expected move or coordinate;
- tutorial incorrect attempts, retry, first completion, and reward-once behavior;
- all five puzzle solutions replay legally and mating lines end in checkmate;
- puzzle wrong moves, automatic opponent replies, solving, and reward-once behavior;
- SQLite v3 tutorial/practice persistence, first timestamps, and best move count;
- saved-game save/update/load/rename/delete and complete move restoration;
- strict FEN and PGN import success and malformed-input rejection;
- immutable review stepping, FEN generation, and PGN export;
- interactive tutorial/puzzle boards, custom-FEN error UI, saved-game metadata,
  review controls, guide search, and feature-status widget behavior.
- complete typed settings default/round-trip/corruption/reset behavior;
- exactly seven version taps, persistent developer unlock, and direct-route
  guarding;
- settings-group rendering, toggle persistence, and all data-management actions;
- real SQLite 17-table export/preview/delete/replace restoration, idempotent
  merge, selective reset isolation, and foreign-key checks;
- signed idempotent developer ledger adjustments and negative-balance rejection;
- disabled local undo, auto-queen/game feedback integration, and live board
  preference behavior;
- deterministic friend reconnect signaling under full parallel test load.
- exact 33-language catalog ordering, native/English/alias search, base/resource
  identifiers, runtime script tags, system resolution, and English fallback;
- 33 ARB resources with 931 non-empty messages each, exact key/metadata/
  placeholder parity, and accurate translation-review status;
- number/date/duration non-empty formatting across every locale, balanced-ICU
  pseudo-localization, native-script rendering, and expanded-text resilience;
- language selection persistence, native/English TalkBack labels, selected
  semantics, Kashmiri RTL app navigation, framework-localization fallback, and
  logical chessboard coordinate order under RTL.
- canonical GPL section, required policy-file, hosted Dart package license,
  npm lockfile license-expression, and Stockfish non-bundling verification;
- substantive Markdown-set and relative-link validation across repository,
  documentation, relay, and GitHub community files.
- match-history idempotency, mode/result/side/difficulty filters, review
  restoration, complete statistics, reset isolation, and first-unlock timestamps;
- history/statistics/achievement tabs, localized dates, privacy text, empty
  states, filtering, progress, and reset confirmation;
- source-SBOM determinism, release-gate schema/status consistency, Android APK
  build, and API 36.1 emulator application smoke flow.

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
- Flutter unit/widget tests: 161 passed.
- Android integration tests: 1 passed on an API 36.1 emulator.
- TypeScript type checking: passed.
- Node relay tests: 7 passed.
- npm production dependency audit: last passed with 0 vulnerabilities at the
  Phase 8 boundary; `server/package-lock.json` remains unchanged.
- Relay Docker image: not built because Docker is unavailable on this machine.
- Independent chess verifier: passed.
- Native engine manifest verifier: passed with zero binaries declared.
- Puzzle schema/legal-line verifier: passed with 5 positions.
- Legal/source verifier: passed.
- Documentation and relative-link verifier: passed.
- Android resource compilation/linking: previously passed against API 36.
- Android debug APK: passed after Gradle installed NDK `28.2.13676358` and
  Android Platform 35 and repository manifest/Kotlin issues were corrected.
  Final artifact size and SHA-256 are recorded in the release status.
- Release app bundle: not run; signing is intentionally not configured.

## Known limitations

- The Stockfish adapter is implemented and tested, but no distribution-verified
  native binary is bundled. Computer play uses the built-in local search.
- The 32 non-English packs remain English fallback drafts until qualified
  community translators and independent native-speaker reviewers approve them.
- Physical-device accessibility and release-mode performance profiling remain
  external even though the debug APK and emulator smoke flow pass.
- Release artifact inspection/signing, store review, native translation review,
  and final legal authorization remain external human/distributor gates.

## Exact next action

```text
docs/release/release_status.json — attach external approvals without changing
an unexecuted gate to passed
```
