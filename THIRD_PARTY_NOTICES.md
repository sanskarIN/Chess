# Third-party notices

This file describes the source boundary at version 0.11.0. It is not a
substitute for the license text shipped by each dependency.

## Flutter application

The resolved Flutter/Dart graph is pinned by `pubspec.lock`. `flutter pub get`
places each hosted package’s own `LICENSE`, `LICENSE.txt`, or `COPYING` file in
the package cache. `dart run tool/verify_legal.dart` proves that every hosted
package in the lockfile is present in `.dart_tool/package_config.json` and has
a non-empty license file. Flutter’s generated license registry combines
package notices for display through Settings → About → Third-party licenses.

Direct application dependencies:

| Component | Pinned version | Upstream/source | Notice source |
|---|---:|---|---|
| Flutter SDK and localizations | 3.44.7 | <https://github.com/flutter/flutter> | Flutter SDK `LICENSE` and engine notices |
| `crypto` | 3.0.7 | <https://pub.dev/packages/crypto> | package `LICENSE` |
| `flutter_riverpod` | 3.3.2 | <https://pub.dev/packages/flutter_riverpod> | package `LICENSE` |
| `go_router` | 17.3.0 | <https://pub.dev/packages/go_router> | package `LICENSE` |
| `intl` | 0.20.2 | <https://pub.dev/packages/intl> | package `LICENSE` |
| `path` | 1.9.1 | <https://pub.dev/packages/path> | package `LICENSE` |
| `path_provider` | 2.1.6 | <https://pub.dev/packages/path_provider> | package `LICENSE` |
| `sqflite` | 2.4.3 | <https://pub.dev/packages/sqflite> | package `LICENSE` |
| `url_launcher` | 6.3.2 | <https://pub.dev/packages/url_launcher> | package `LICENSE` |

Developer/test dependencies are pinned in the same lockfile and are validated
by the same tool. They are not necessarily included in a release artifact.

## Friend relay

The relay graph is pinned by `server/package-lock.json`. npm’s lockfile records
the exact package, integrity value, development/optional status, and SPDX
license expression for every resolved package. The legal verifier rejects any
non-root lock entry with a missing license field.

Direct relay dependencies are `chess.js` 1.4.0 and `ws` 8.21.1. Development
dependencies are `typescript` 7.0.2, `@types/node` 26.1.1, and `@types/ws`
8.18.1. TypeScript 7 also resolves platform-specific optional compiler
packages; those entries remain represented in the lockfile and audit.

## Project assets

- The knight brand mark and launcher foreground are drawn from project-owned
  vector paths/code and are covered by the project license.
- The five bundled puzzle positions and prose are original project data
  dedicated under CC0-1.0. The catalog embeds its license and source metadata.
- No font file is bundled. Named Noto/system families are fallback requests to
  the operating system; a future bundled font must add its exact license text.
- No Stockfish binary, source archive, opening book, tablebase, or neural
  network file is bundled.

## Distributor obligation

Before distributing an APK/AAB or relay image, regenerate the dependency graph,
run the legal verifier, inspect the actual artifact for native libraries and
assets, preserve every dependency notice, and provide GPL corresponding source
for all GPL-covered object code. See
`docs/legal/release_legal_checklist.md`.
