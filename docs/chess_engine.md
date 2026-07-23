# Chess engine architecture

The presentation layer knows only `EngineService` and
`ComputerOpponentController`. It does not import Stockfish, UCI, processes,
platform channels, or binary paths.

## Engine-neutral contract

`ChessEngine` supports start, stop, restart, new game, configuration, position
updates, best move, analysis, cancellation, health, and disposal.
`EngineConfiguration` defines depth, move time, skill, memory, and thread
budgets. `EngineMove` identifies whether a move came from native Stockfish or
the local search engine.

`EngineService` owns one engine and serializes lifecycle and search operations
so multiple callers cannot create competing searches. Cancellation remains
out-of-band so a long search can be stopped immediately.

## Built-in local search

The default Phase 4 computer opponent is an original deterministic legal-search
engine. It performs iterative alpha-beta search in a spawned isolate, orders
captures and promotions, evaluates material, supports cancellation by killing
the isolate, and always returns through the same `ChessEngine` interface.

Its difficulty names tune resource budgets:

| Difficulty | Depth ceiling | Move budget | Skill setting |
| --- | ---: | ---: | ---: |
| Beginner | 1 | 350 ms | 1 |
| Intermediate | 2 | 700 ms | 6 |
| Expert | 3 | 1.4 s | 12 |
| Grandmaster | 4 | 2.5 s | 20 |

These are device-limited presets, not calibrated human ratings. Beginner
occasionally selects the second-ranked move without ever selecting an illegal
move. Grandmaster shows a battery and thermal warning.

## Stockfish adapter

`StockfishEngine` implements UCI handshake, readiness, new-game reset, FEN
position, Skill Level, Hash, Threads, depth/move-time search, incremental
analysis, ponder move, stop, timeout, crash health, and restart. Output is parsed
as typed UCI messages and every returned move is validated again by the local
chess domain before it reaches the board.

`IoEngineProcess` is the only Dart `Process` implementation. Tests substitute a
fake line process and exercise the full UCI handshake without a native binary.

## Android boundary

The Android method channel reports `Build.SUPPORTED_ABIS` and verified-binary
metadata. It currently reports that no distribution-verified binary exists.
The resolver therefore keeps Stockfish unavailable and the app uses local
search. A developer can supply an unpackaged local executable with
`CHESS_MASTER_STOCKFISH_PATH`; it is visibly classified as unverified and cannot
be accepted by the release manifest.

`assets/engine/manifest.json` targets official Stockfish 18 source but contains
no binary entries. The verifier rejects unsupported ABIs, mismatched source
metadata, missing files, invalid or mismatched SHA-256 values, false load-test
flags, duplicate paths, and undeclared binaries.
