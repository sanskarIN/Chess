# Feature status

Updated: 2026-07-23

The `Status` column uses only the master prompt's permitted classifications.
`Verification` states whether the evidence was executed in this environment.

| Capability | Status | Verification | Evidence or blocker |
| --- | --- | --- | --- |
| App configuration and bootstrap | Tested | Passed | Flutter widget flow test |
| Typed routing | Tested | Passed | Splash/onboarding/home and typed mode routes execute |
| Light/dark theme foundation | Implemented | Passed | Flutter analysis and widget rendering; device visual QA pending |
| Localization architecture | Tested | Passed | `flutter gen-l10n` and localized widget tests |
| Error and result types | Tested | Passed | Flutter unit suite |
| Privacy-safe structured logging | Tested | Passed | Redaction test |
| SQLite schema and lifecycle | Tested | Passed | Schema plus onboarding settings tests; device migration QA pending |
| Android host configuration | Implemented | Blocked | Command-line tools/licenses block APK build |
| Complete chess rules | Tested | Passed | Dart verifier plus detailed Flutter test source |
| Perft validation | Tested | Passed | Start d4; Kiwipete d3; rook/endgame d4 |
| Splash, onboarding, home, and setup | Tested | Passed | Flutter application/widget tests |
| Playable board and game UI | Tested | Passed | Legal moves, semantics, history, undo/redo, and result tests |
| Captured-pieces display | Tested | Passed | Domain capture and controller/widget coverage |
| Computer opponent | Tested | Passed | Four local-search levels, automatic turns, lock/thinking UI, cancellation, and retry |
| Stockfish UCI adapter | Tested | Passed | Fake-process handshake, configuration, search, timeout, stop, crash, and restart |
| Stockfish Android executable | Unavailable | Blocked | No distribution-verified ABI binary is declared or bundled |
| Local two-player | Tested | Passed | Offline names, clocks, orientation, approvals, draw, resign, pause, and rematch |
| Friend matches and relay server | Not started | Not run | Phase 6 |
| Daily challenges, coins, and hints | Not started | Not run | Phase 7 |
| Practice, tutorial, saves, and review | Not started | Not run | Phase 8 |
| Complete settings and developer options | Not started | Not run | Phase 9 |
| 33 locale options | Not started | Not run | Phase 10 |
| Complete legal and open-source package | Not started | Not run | Phase 11 |
| Beta release qualification | Not started | Not run | Phase 12 |

The engine manifest deliberately contains zero binaries. A native Stockfish
executable cannot become available until its exact source, ABI, checksums, and
debug/release loading evidence pass the committed verifier. Local match
presentation exists, but the mode is not classified as fully tested until Phase
5 clocks and approval policies are complete.
