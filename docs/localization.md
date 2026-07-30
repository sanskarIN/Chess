# Localization

Chess-Master exposes exactly 33 language choices in Settings → Language. A
selection is persisted locally and is applied immediately; reinstalling or
restarting the app is not required. “System language” follows the device
preference and falls back to English when the device language is unsupported.

`lib/l10n/app_en.arb` is the canonical source. Every supported locale has a
complete ARB with the same 864 message keys, metadata, ICU syntax, and
placeholders. The 32 non-English resources currently contain the complete
English fallback copy. They are deliberately marked
`community_review_required` in `lib/l10n/translation_status.json`; no draft is
presented as a native-speaker-reviewed translation.

The fallback-copy policy prevents raw localization keys, empty labels, and
partially translated screens while enabling contributors to translate and
review one locale at a time. Runtime failures in locale-specific number or date
formatting retry with English formatting, then use a deterministic plain
representation as a final non-empty safeguard.

## Developer commands

```text
flutter gen-l10n
dart run tool/generate_locale_fallbacks.dart --check
dart run tool/verify_localizations.dart
flutter test test/l10n
```

`generate_locale_fallbacks.dart --force` is only for rebuilding the initial
English-fallback baseline. It refuses to overwrite a divergent locale unless
`--force` is explicit, and refuses to remove a non-generated ARB. Do not use it
after real translations have been accepted.

Generated `app_localizations*.dart` files are reproducible and ignored.
Contributor-edited ARBs, the catalog, status JSON, validation tools, and
documentation are reviewed and committed.

## Runtime behavior

- Native and English language names, aliases, and locale identifiers are
  searchable.
- Kashmiri, Sindhi, and Urdu render app navigation right-to-left.
- Chess positions retain chess-domain square/file/rank meaning; text direction
  never changes the underlying square identifiers or move notation.
- Runtime script subtags are retained for Kashmiri (`Arab`), Sindhi (`Arab`),
  Punjabi (`Guru`), Meitei (`Mtei`), and Santali (`Olck`).
- Theme font fallbacks cover the scripts used by every native language name,
  while Android’s system font fallback remains the final glyph source.
- TalkBack options announce both the native and English names and expose the
  selected state.
- Developer Options includes pseudo-localization, expanded-text, RTL, locale,
  date, number, missing-key, and completeness previews.

See [the translation guide](translations/README.md), [locale identifier
mapping](translations/locale_identifiers.md), [completeness
report](translations/completeness.md), and [contribution
workflow](translations/contributing.md).
