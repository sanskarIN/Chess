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
| Computer opponent and Stockfish | Not started | Not run | Phase 4 |
| Local two-player | Not started | Not run | Phase 5 |
| Friend matches and relay server | Not started | Not run | Phase 6 |
| Daily challenges, coins, and hints | Not started | Not run | Phase 7 |
| Practice, tutorial, saves, and review | Not started | Not run | Phase 8 |
| Complete settings and developer options | Not started | Not run | Phase 9 |
| 33 locale options | Not started | Not run | Phase 10 |
| Complete legal and open-source package | Not started | Not run | Phase 11 |
| Beta release qualification | Not started | Not run | Phase 12 |

Computer setup exists, but the computer opponent remains unavailable until the
Phase 4 engine boundary passes its tests. Local match presentation exists, but
the mode is not classified as fully tested until Phase 5 clocks and approval
policies are complete.
