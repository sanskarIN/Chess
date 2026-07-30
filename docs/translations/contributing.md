# Contributing a translation

1. Open `lib/l10n/app_en.arb` and the target `app_<id>.arb`.
2. Confirm the target ID in `locale_identifiers.md`.
3. In `lib/l10n/translation_status.json`, change the target locale’s `content`
   from `english_fallback` to `community_translation`. Keep `status` as
   `community_review_required` and `nativeSpeakerReviewed` as `false`.
4. Translate message values only. Keep every key, metadata object, ICU branch,
   and placeholder name intact.
5. Prefer established chess vocabulary used by players of the language. If a
   term is disputed or unclear, keep the English fallback and note it in the
   pull request.
6. Run:

   ```text
   flutter gen-l10n
   dart run tool/verify_localizations.dart
   flutter test test/l10n
   flutter test
   ```

7. Test the selector by native and English name, all principal screens, long
   values, plural messages, a complete local game, saved-game review, and
   TalkBack labels. For Kashmiri, Sindhi, or Urdu, also test RTL navigation and
   verify that SAN, FEN, PGN, chess files/ranks, and logical squares retain
   their chess meaning.
8. In the pull request, identify the translator and independent reviewer,
   describe proficiency, list terminology references, and list devices/font
   configurations tested.

## Review-status update

Do not edit `nativeSpeakerReviewed` to `true` merely because all keys have text.
The status may change to `reviewed`, `reviewed_translation`, and `true` only
after an independent proficient reviewer approves the complete locale. The
generator drift check only owns records still marked `english_fallback`; never
run the fallback generator with `--force` over translated work.

## Placeholder examples

Given:

```json
"secondsValue": "{count} seconds"
```

translate the surrounding words but retain `{count}` exactly. For plural/select
messages, retain all required ICU branches and nested braces. The verifier
rejects changed placeholder metadata, missing keys, empty values, or hidden
extra resources.
