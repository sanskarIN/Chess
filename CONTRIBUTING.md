# Contributing to Chess-Master

Thank you for helping build a private, accessible, open-source chess game.

## Before coding

1. Search existing issues and `docs/upcoming/feature_status.md`.
2. For a large or behavior-changing proposal, open a feature request before
   implementation. Do not present planned features as available.
3. Read CODE_OF_CONDUCT.md, SECURITY.md, the architecture, and the relevant
   feature document.
4. Never commit signing keys, secrets, personal data, proprietary puzzle sets,
   unverified native binaries, or generated dependency caches.

## Development baseline

Use Flutter 3.44.7 stable, Dart 3.12.2, and Node.js 24 for the relay. Resolve
dependencies from the committed lockfiles.

```text
flutter pub get
flutter gen-l10n
dart format .
flutter analyze
flutter test
dart run tool/chess_domain_verifier/bin/verify.dart
dart run tool/verify_engine_manifest.dart
dart run tool/verify_puzzles.dart
dart run tool/verify_localizations.dart
dart run tool/verify_legal.dart
dart run tool/verify_documentation.dart
cd server
npm ci
npm run check
npm test
npm audit --omit=dev
```

Android changes should also pass a debug APK build with an official SDK/JDK.
Do not configure release signing merely to make a pull request pass.

## Change requirements

- Use the canonical chess domain instead of duplicating move legality in UI.
- Keep expected failures typed and user messages localized.
- Add or update tests for behavior, edge cases, persistence, accessibility,
  privacy, and migrations.
- Keep offline features independent of relay health.
- Bound untrusted input, redact identifiers, and avoid logging names, tokens,
  room codes, addresses, or imported content.
- Update documentation, feature status, legal notices, and the continuation
  manifest when applicable.
- Explain migration and compatibility consequences.

Translations follow `docs/translations/contributing.md`. Suggestions follow
`docs/users_suggest/README.md`. Native engine work follows
`docs/legal/stockfish_distribution.md`.

## Pull requests

Keep commits scoped. Complete the pull-request template with user impact,
privacy/security implications, validation evidence, screenshots for visible UI,
and source/license evidence for new dependencies or assets. By contributing,
you license your contribution under GPL-3.0-or-later and confirm you have the
right to submit it.
