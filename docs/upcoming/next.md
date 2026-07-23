# Exact next work

Phase 4 is complete with 67 passing Flutter tests, zero analyzer issues, a
passing independent chess-domain verifier, and a passing native-engine manifest
verification.

Phase 5 starts with:

```text
lib/features/local_multiplayer/domain/game_clock.dart
```

Phase 5 implementation order:

1. monotonic, pause-aware two-sided game clock;
2. clock increment and timeout integration with the chess controller;
3. local match controller coordinating rotation and action policies;
4. automatic, fixed-White, and fixed-Black orientation;
5. configurable immediate or two-player-approved undo;
6. draw-offer approval, resignation, pause, and rematch coordination;
7. offline controller, timing, lifecycle, and widget tests;
8. local multiplayer and clock documentation.

Before the Android debug build can complete, install Android SDK command-line
tools and repair the incomplete NDK `28.2.13676358` installation. Accept any
remaining SDK licenses through the official tool. Do not configure or use a
release signing key.
