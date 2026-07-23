# Third-party notices

This inventory is based on declared direct dependencies. The final
transitive inventory must be generated from `pubspec.lock` after Flutter
dependency resolution and reviewed again before every release.

| Component | Selected version | License | Purpose |
| --- | --- | --- | --- |
| Flutter SDK | 3.44.7 target | BSD-3-Clause | Android UI framework and tooling |
| Dart SDK | 3.12.x target | BSD-3-Clause | Language and runtime |
| flutter_riverpod | 3.3.2 | MIT | Dependency injection and state |
| go_router | 17.3.0 | BSD-3-Clause | Typed declarative routing |
| intl | 0.20.2 | BSD-3-Clause | Generated localization support |
| path | 1.9.1 | BSD-3-Clause | Cross-platform path joining |
| path_provider | 2.1.6 | BSD-3-Clause | Application directory discovery |
| sqflite | 2.4.3 | BSD-3-Clause | Asynchronous local SQLite |
| crypto | 3.0.7 | BSD-3-Clause | Client state hashing and engine checksum verification |
| flutter_lints | 6.0.0 | BSD-3-Clause | Static analysis rules |
| sqflite_common_ffi | 2.4.2 | BSD-2-Clause | Development-time real SQLite migration and transaction tests |
| Node.js | 24.14.0 verification runtime | MIT and third-party notices | Friend relay runtime |
| chess.js | 1.4.0 | BSD-2-Clause | Authoritative relay-side chess validation |
| ws | 8.21.1 | MIT | Relay WebSocket server |
| TypeScript | 7.0.2 | Apache-2.0 | Relay compilation and type checking |
| @types/node | 26.1.1 | MIT | Relay development type declarations |
| @types/ws | 8.18.1 | MIT | Relay development type declarations |

Package license texts and copyright statements remain with their respective
authors. Version and license data must be confirmed from the resolved lockfile;
this table is not a transitive dependency audit. The relay's exact resolved npm
tree is locked in `server/package-lock.json`.

Stockfish executable code is not included. The source target for the implemented
UCI adapter is official Stockfish 18 (`sf_18`, commit prefix `cb3d4ee`),
GPL-3.0-only. If a future release bundles it, the exact source revision, build
instructions, binary and archive checksums, GNU GPL text, copyright notices,
network files, ABI evidence, load tests, and corresponding-source availability
must be completed before distribution.
