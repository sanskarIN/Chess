# Exact next work

Phase 8 is complete with offline tutorial, practice, puzzles, guide, feature
catalog, saved games, strict FEN/PGN import, and review mode. The Flutter suite,
real SQLite tests, puzzle verifier, analyzer, chess verifier, engine-manifest
verifier, relay tests, type check, and dependency audit are rerun at the phase
boundary.

Phase 9 starts with:

```text
lib/features/settings/domain/app_settings.dart
```

Phase 9 implementation order:

1. typed settings model and grouped local persistence;
2. appearance, gameplay, sound, accessibility, language, privacy, and data UI;
3. deliberate developer-options unlock and warning;
4. diagnostics, FEN editor, locale tester, economy and challenge tools;
5. multiplayer relay diagnostics and safe log export;
6. data view, export, import preview, selective reset, and delete-all controls;
7. settings, migration, validation, destructive-confirmation, and widget tests;
8. substantive settings, developer, diagnostics, and data-format documentation.

Before the Android debug build can complete, install Android SDK command-line
tools and repair the incomplete NDK `28.2.13676358` installation. Accept any
remaining SDK licenses through the official tool. Do not configure or use a
release signing key.
