# Exact next work

Phase 9 is complete with versioned typed settings, live board/game/startup
behavior, guarded Developer Options, diagnostics, production-codec chess tools,
ledger-safe economy/challenge tools, multiplayer simulations, and atomic
17-table local-data management. The Flutter suite, analyzer, chess verifier,
engine-manifest verifier, puzzle verifier, relay tests, type check, and
dependency audit are rerun at the phase boundary.

Phase 10 starts with:

```text
lib/l10n/supported_locales.dart
```

Phase 10 implementation order:

1. exact typed catalog for the 33 requested language options;
2. standard locale identifiers and documented internal identifiers/fallbacks;
3. English template completeness and generated localization configuration;
4. 32 additional ARB locale files with every template key and placeholder;
5. immediate search, selection, system reset, preview, and persistent locale
   switching;
6. Urdu and Sindhi RTL handling plus explicit RTL developer preview;
7. locale-aware number/date/duration/plural/relative-time behavior;
8. automated JSON, key, placeholder, locale-count, fallback, RTL, and generated
   delegate checks;
9. translation contribution workflow with native-speaker review status that
   does not overclaim unreviewed translations.

Before the Android debug build can complete, install Android SDK command-line
tools and repair the incomplete NDK `28.2.13676358` installation. Accept any
remaining SDK licenses through the official tool. Do not configure or use a
release signing key.
