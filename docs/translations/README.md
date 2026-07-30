# Chess-Master translations

English is the verified source locale. The other 32 locale packs are complete
English fallback resources awaiting qualified community translation and
native-speaker review. This is intentional: automated or guessed translations
must not be represented as reviewed language support.

The source of truth is:

- `lib/l10n/app_en.arb` for messages and placeholder contracts;
- `lib/l10n/supported_locales.dart` for the exact 33 product options;
- `lib/l10n/translation_status.json` for review status;
- `tool/verify_localizations.dart` for key, metadata, fallback, and RTL checks.

Start with [contributing.md](contributing.md). Locale identifiers and script
fallback decisions are documented in [locale_identifiers.md](locale_identifiers.md).
The current status is in [completeness.md](completeness.md).

## Quality policy

A translation can be called reviewed only when a proficient human reviewer has
checked meaning, chess terminology, ICU plural/select behavior, placeholders,
layout at large text sizes, and spoken output. Machine translation can be used
as a private drafting aid only when the contributor verifies every message; it
is never sufficient evidence for the review flag.

Do not translate:

- ARB keys;
- `@@locale`;
- placeholder names inside braces;
- metadata property names;
- protocol values, FEN, PGN, SAN, URLs, hashes, or source identifiers.

English fallback remains active for any message that cannot yet be translated
with confidence.
