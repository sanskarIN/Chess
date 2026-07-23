# Exact next work

Phase 2 is complete and its required starting-position perft depth 4 passes.
Phase 3 starts with:

```text
lib/features/splash/presentation/splash_screen.dart
```

Phase 3 implementation order:

1. branded splash and transition timing;
2. optional onboarding flow;
3. responsive home and game-mode selection;
4. player setup with White, Black, and Random;
5. accessible board rendering and square semantics;
6. game controller connected only to the tested chess domain;
7. captured pieces, move history, clocks, and result presentation;
8. core widget and controller tests.

Flutter 3.44.7 still needs to be installed before widget tests and the Android
debug build can run. Pure-Dart domain changes must continue to pass:

```text
cd tool/chess_domain_verifier
dart run bin/verify.dart
dart analyze bin/verify.dart ../verify_chess_domain.dart ../../lib/features/chess/domain
```
