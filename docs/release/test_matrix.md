# Test matrix

## Executed source matrix

| Area | Automated evidence | Current source result |
| --- | --- | --- |
| Chess rules | Unit tests, perft, independent verifier | Passed |
| Chess UI | Widget interaction and semantics tests | Passed |
| Computer player | Search, cancellation, lifecycle, UCI fake-process tests | Passed |
| Local multiplayer | Clocks, orientation, approvals, timeout, screen tests | Passed |
| Friend multiplayer | Dart controller/widgets plus Node protocol/server tests | Passed |
| Challenges/economy | Determinism, real SQLite transactions, ledger integrity | Passed |
| Practice/puzzles | Schema, legal solution replay, progress and widgets | Passed |
| Saves/review | Real SQLite serialization, FEN/PGN import, review stepping | Passed |
| History/statistics | Real SQLite idempotency, filters, reset, achievements | Passed |
| Settings/data | Typed round trip, developer guard, 17-table import/export | Passed |
| Localization | 33 resources, formatting, RTL, fonts, semantics, large text | Passed |
| App flow | 161 host unit/widget tests plus API 36.1 integration smoke flow | Passed |
| Relay | TypeScript check, build, seven Node tests | Passed |

Host line coverage for the Phase 12 run was 8,204 of 43,250 instrumented lines
(18.97%). This is a recorded baseline, not a waived quality target; future work
should increase exercised application/service paths while retaining all domain
and integration gates.

## Android device matrix still required

Run the candidate on at least:

| Dimension | Required samples |
| --- | --- |
| Android version | Minimum supported, one middle version, current stable |
| ABI | `arm64-v8a`; any additional ABI actually distributed |
| Screen | Compact phone, large phone, tablet or foldable-sized surface |
| Theme | Light, dark, high contrast |
| Text/display | Default, largest supported text, increased display size |
| Direction | English LTR and Urdu/Kashmiri/Sindhi RTL |
| Input | Touch, keyboard/D-pad where supported, TalkBack exploration |
| Lifecycle | Background/resume, interruption, process recreation |
| Network | Offline, relay unavailable, packet loss, reconnect, server restart |
| Storage | Clean install, upgrade, export/import, low-storage failure |

Record model, OS build, app commit, result, evidence path, and issue link for
each run. Emulator evidence is useful but does not replace the physical-device
accessibility and performance passes.

## Release regression focus

- Legal move highlighting must never allow an illegal move.
- Clocks must not charge time while lifecycle-paused.
- Reward claims and achievement unlocks must remain idempotent.
- Match history must be local-only and must not export relay connection data.
- Unsupported locales must fall back to complete English rather than keys.
- Startup must not wait for relay or engine network availability.
