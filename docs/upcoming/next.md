# Exact next work

Phase 3 is complete with 57 passing Flutter tests, zero analyzer issues, and a
passing independent chess-domain verifier.

Phase 4 starts with:

```text
lib/features/computer_player/domain/chess_engine.dart
```

Phase 4 implementation order:

1. engine-neutral models and `ChessEngine` interface;
2. documented difficulty configuration;
3. serialized `EngineService` lifecycle and cancellation;
4. UCI parser and Stockfish process adapter;
5. unsupported-architecture, timeout, crash, and recovery states;
6. Android ABI/source-build/checksum packaging contract;
7. computer-turn state and asynchronous thinking indicator;
8. automatic White first move when the player selected Black;
9. engine and computer-game tests;
10. Stockfish GPL/source-correspondence documentation.

The native binary must not be claimed or packaged until its source version,
license, architecture, checksum, Android loading, and release compatibility are
verified. A deterministic legal fallback may support tests, but it must never be
misrepresented as Stockfish.

Before the Android debug build can complete, install Android SDK command-line
tools and repair the incomplete NDK `28.2.13676358` installation. Accept any
remaining SDK licenses through the official tool. Do not configure or use a
release signing key.
