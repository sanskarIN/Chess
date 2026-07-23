# Localization

English ARB source lives in `lib/l10n/app_en.arb`. Flutter's `gen-l10n` writes
source into `lib/l10n/` rather than the removed synthetic `flutter_gen` package.
Every message includes translator metadata, and generated getters are non-null.

Run:

```text
flutter gen-l10n
```

The generated Dart files are reproducible and ignored. ARB source, `l10n.yaml`,
and localization validation tools are reviewed and committed.

User-facing strings must not be hardcoded in widgets. Stable application error
objects store localization keys rather than English sentences. The only
build-configured identity value is the displayed application name.

English is the only source locale in Phase 1. The 33 requested locale options,
key parity validation, fallback behavior, locale picker, and RTL verification
belong to Phase 10. No translation is represented as reviewed before a human
reviewer confirms it.
