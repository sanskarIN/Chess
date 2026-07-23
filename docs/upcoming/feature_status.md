# Feature status

Updated: 2026-07-23

The `Status` column uses only the master prompt's permitted classifications.
`Verification` states whether the evidence was executed in this environment.

| Capability | Status | Verification | Evidence or blocker |
| --- | --- | --- | --- |
| App configuration and bootstrap | Implemented | Blocked | Source and tests exist; Flutter SDK absent |
| Typed routing | Implemented | Blocked | Root and error routes exist; Flutter SDK absent |
| Light/dark theme foundation | Implemented | Blocked | Material 3 definitions exist; no rendered-device QA |
| Localization architecture | Implemented | Blocked | ARB and `gen-l10n` config exist; generator unavailable |
| Error and result types | Implemented | Blocked | Unit tests authored; Dart/Flutter unavailable |
| Privacy-safe structured logging | Implemented | Blocked | Redaction test authored; Dart/Flutter unavailable |
| SQLite schema and lifecycle | Implemented | Blocked | v1 source and schema tests authored; device test unavailable |
| Android host configuration | Implemented | Blocked | Text configuration exists; wrapper and Flutter SDK absent |
| Complete chess rules | Tested | Passed | Dart verifier plus detailed Flutter test source |
| Perft validation | Tested | Passed | Start d4; Kiwipete d3; rook/endgame d4 |
| Playable board and game UI | Not started | Not run | Phase 3 |
| Computer opponent and Stockfish | Not started | Not run | Phase 4 |
| Local two-player | Not started | Not run | Phase 5 |
| Friend matches and relay server | Not started | Not run | Phase 6 |
| Daily challenges, coins, and hints | Not started | Not run | Phase 7 |
| Practice, tutorial, saves, and review | Not started | Not run | Phase 8 |
| Complete settings and developer options | Not started | Not run | Phase 9 |
| 33 locale options | Not started | Not run | Phase 10 |
| Complete legal and open-source package | Not started | Not run | Phase 11 |
| Beta release qualification | Not started | Not run | Phase 12 |

The temporary foundation screen is not a chess-game availability claim.
