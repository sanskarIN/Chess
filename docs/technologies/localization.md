# Flutter localization and intl

Flutter `gen-l10n` converts the English ARB contract and 32 fallback resources
into typed delegates. `intl` supplies supported date/number behavior; the
project records safe formatting fallbacks for locales without dedicated data.

The catalog separates resource/settings identifiers from runtime script
subtags. Validation enforces exactly 33 resources, non-empty values, complete
keys, identical placeholder metadata, accurate review status, and the three RTL
languages. See `docs/localization.md` and `docs/translations/`.

Generated Dart files are not hand-edited. Real translations move out of
generator ownership through `translation_status.json` before ARB values change.
