# Development continuation manifest

## Project identity

- Version: `0.2.0+2`
- Completed phase: 2 — Chess Domain
- Next phase: 3 — Core UI
- Updated: 2026-07-23
- Default name: Chess-Master
- Watermark: Made by the Sanskar
- Repository: <https://github.com/sanskarIN/Chess>

## Published Phase 1 boundary

Phase 1 was committed and pushed before Phase 2 as requested.

- Branch: `main`
- Commit: `c10351b3b735b80dd7e3201d83c6feffbc673f91`
- Commit author: `Sanskar <sanskarin@outlook.in>`
- Remote verification: `origin/main` resolved to the same commit
- Repository-local Git credential username: `Sanskar-in`

The remote repository had no refs before this root commit, so `main` was
initialized directly. No existing history was overwritten and no pull request
was applicable.

## Phase 1 completed source

- Flutter bootstrap and global error capture
- Configurable application identity and version
- Riverpod dependency injection
- GoRouter root and error routes
- Material 3 light/dark themes
- English ARB template and `gen-l10n` configuration
- Structured application errors and explicit result values
- Structured logger with sensitive-field redaction
- SQLite v1 schema, constraints, indices, lifecycle, and atomic creation
- Android Gradle configuration, manifest, network policy, backup exclusions,
  adaptive icons, and light/dark launch resources
- Foundation unit/widget test source
- Initial architecture, setup, technology, and status documentation
- Flutter analysis/test/Android build CI workflows

## Phase 2 completed source

- Canonical 64-square board coordinates
- Piece colors, types, pieces, moves, and castling rights
- Immutable position model and single state transition
- Pseudo-legal and legal move generation
- Attack and check detection
- King-side and queen-side castling with all path restrictions
- En passant with discovered-check rejection
- Four promotion choices
- Pins, double check, mate, and stalemate
- Threefold repetition identity
- Fifty-move and insufficient-material results
- Draw agreement, resignation, and timeout results
- Stable game/move IDs, captured pieces, position/move history
- Undo, redo, alternate continuation, and validated restoration
- Strict six-field FEN parsing and serialization
- SAN encoding, decoding, disambiguation, check, and mate suffixes
- PGN tag/movetext export and validated import
- Perft traversal
- Public `chess_domain.dart` API
- Detailed rule and notation test source
- Dependency-free executable verifier

## Commands executed for Phase 2

```text
winget install --id Google.DartSDK -e --source winget
dart --version
dart format lib/features/chess/domain test/features/chess/domain tool
cd tool/chess_domain_verifier
dart pub get
dart run bin/verify.dart
dart analyze bin/verify.dart ../verify_chess_domain.dart ../../lib/features/chess/domain
```

Installed toolchain:

```text
Dart SDK version: 3.12.2 (stable)
```

## Tests completed

The executable verifier passed using the production domain source.

Perft results:

| Position | Depth 1 | Depth 2 | Depth 3 | Depth 4 |
| --- | ---: | ---: | ---: | ---: |
| Standard start | 20 | 400 | 8,902 | 197,281 |
| Kiwipete | 48 | 2,039 | 97,862 | Not run |
| Rook/en-passant endgame | 14 | 191 | 2,812 | 43,238 |

Additional executed checks:

- castling availability
- pinned en passant rejection
- en passant state transition
- queen/rook/bishop/knight promotion choices
- threefold repetition
- fifty-move rule
- stalemate
- insufficient material
- checkmate PGN round-trip
- timeout without mating material

Static analysis result:

```text
No issues found!
```

The standalone formatter emitted expected warnings that the root
`flutter_lints` package cannot resolve without Flutter. The domain analyzer
itself completed with zero issues.

## Authored Flutter tests pending execution

- foundation unit/widget tests
- square and FEN tests
- standard start, Kiwipete, and endgame perft tests
- castling, en passant, promotion, pin, and double-check tests
- game result, history, capture, undo/redo, and restoration tests
- SAN and PGN tests

## Build status

The pure-Dart chess domain is formatted, analyzed, and executable.

The Flutter application remains blocked from a full build by:

- missing Flutter 3.44.7 SDK;
- missing root `pubspec.lock`;
- missing generated localization source;
- missing Flutter-generated Gradle wrapper scripts/JAR and metadata.

Android XML and resources previously parsed, compiled, and linked successfully
against API 36 with minimum API 24 and target API 36.

## Known limitations

- No playable board UI exists yet; Phase 3 is next.
- Flutter tests and Android APK build have not run.
- No Stockfish binary/source is included.
- No multiplayer relay is included.
- Only English localization source exists.
- The complete verbatim GPL text and final legal/license audit remain Phase 11.
- Offline rewards and challenges do not exist yet.

## Exact next file

```text
lib/features/splash/presentation/splash_screen.dart
```
