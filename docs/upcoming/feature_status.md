# Feature status

Updated: 2026-08-04

`Tested` means the source behavior has executed in the recorded automated
environment. External human/device/distribution gates remain separately
identified and are not implied by source completion.

| Capability | Status | Verification | Evidence or boundary |
| --- | --- | --- | --- |
| App bootstrap, routing, theme, errors, logging, and SQLite lifecycle | Tested | Passed | Analysis, unit/widget flow, persistence, redaction, and schema tests |
| Complete chess rules, notation, game history, and perft | Tested | Passed | 161-test Flutter suite plus independent domain verifier |
| Accessible board and complete game UI | Tested | Passed | Widget semantics, legal interaction, captured pieces, result, undo/redo, and review tests |
| Four-level local computer opponent | Tested | Passed | Search, cancellation, lifecycle, UCI fake-process, and UI tests |
| Distribution-verified Stockfish Android executable | Unavailable | Not applicable | No native executable is declared or bundled; built-in Dart search is used |
| Local two-player and clocks | Tested | Passed | Monotonic clock, orientation, approval, draw, resign, lifecycle, and screen tests |
| Friend matches and self-hostable relay | Tested | Passed | Flutter protocol/UI coverage plus clean TypeScript build and 7 relay tests |
| Daily challenges, coins, ledger, and hints | Tested | Passed | Determinism, real SQLite transactions, idempotency, integrity chain, and UI tests |
| Tutorials, practice, puzzles, saves, import, and review | Tested | Passed | Legal replay, reward-once, persistence, validation, and widget coverage |
| History, statistics, and fifteen achievements | Tested | Passed | Real SQLite idempotency/filter/reset/unlock tests and complete widget flow |
| Settings, Developer Options, and local data management | Tested | Passed | Typed persistence, guarded tools, 17-table export/import/reset, and widget tests |
| Exactly 33 locale options | Tested | Passed | 931-message key/metadata/placeholder parity, RTL, formatting, fonts, and widget tests |
| Complete legal/open-source documentation | Tested | Passed | GPL/source verifier, 18 policy/notice files, 100 Dart licenses, 26 npm licenses, and link verifier |
| Source SBOM and release-control package | Tested | Passed | Deterministic CycloneDX 1.5 SBOM and machine-readable 20-gate verifier |
| Android debug build | Implemented | Passed | Flutter 3.44.7 debug APK built after NDK/manifest/Kotlin corrections |
| Android integration smoke flow | Tested | Passed | API 36.1 emulator: 1 test passed |
| Physical-device accessibility and performance | External | Not run | Requires qualified physical-device evidence |
| Native-speaker translation review | External | Not run | 32 complete English fallback drafts remain clearly marked |
| Release signing, store submission, and legal authorization | External | Not run | Developer/reviewer-owned actions; no signing material is stored here |

Source implementation is complete, but `readyForDistribution` remains false
until every external release gate has evidence and approval. See
[the release status](../release/release_status.json).
