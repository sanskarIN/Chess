# Performance review

## Source review

- Chess rules and legal move generation are pure Dart and covered by perft.
- Computer search runs in an isolate with bounded time, depth, memory, thread,
  cancellation, and stale-result checks.
- Database changes use transactions and indexed history, game, challenge,
  reward, practice, and saved-game queries.
- Relay rooms are memory-only, rate limited, size limited, and expired.
- Startup does not connect to the relay or require Stockfish.
- Long lists use builders where item counts can grow; history is locally
  filtered after a single indexed load in the current pre-release design.
- No analytics, advertising SDK, background location, media capture, or cloud
  synchronization runs in the background.

## Device budgets

The following are release targets, not measurements:

| Metric | Target |
| --- | --- |
| Warm startup to usable home | under 1 second on representative mid-range device |
| UI frame budget | no sustained frame misses at 60 Hz |
| Computer move response | within selected difficulty time bound |
| Memory during ordinary match | stable; no growth across 10 rematches |
| Relay reconnect | bounded by configured timeout/backoff |
| Database export | responsive progress/error surface for representative data |

## Required measurement

Profile a release-mode build on a physical mid-range Android device. Capture
Flutter DevTools timeline, frame raster/UI statistics, startup trace, memory
snapshots before/after ten rematches, CPU and battery during a 30-minute
computer match, database export timing, and relay reconnect timing.

A debug APK exists, but no physical-device release-mode measurements have been
captured, so these targets are not reported as passed. Device performance
approval remains external.
