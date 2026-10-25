# Changelog

All notable project changes are documented here. Versions from 1.0.0 use
semantic versioning for source releases. Earlier versions tracked completed
implementation phases. A stable source tag does not certify Android binaries
or imply Play Store approval.

## 1.0.0 — 2026-10-25

- First stable, source-only GitHub release covering all twelve implementation
  phases, with complete source archives and the source dependency SBOM.
- Consolidated creator and support destinations at <https://sanskarin.github.io>;
  removed the old social and promotional contact links while preserving source,
  security, license, and dependency references.
- Added canonical project-link constants and regression tests for the website
  and creator section.
- Added protected environment/local-property Android release signing inputs
  and fail-closed release packaging; no keys or passwords are distributed.
- Added validated source-release scope, version/tag checks, release notes, and
  policy tests. Owner-signed Android distribution and device/native-translation
  reviews remain separately recorded external gates.

## 0.12.0 — 2026-08-04

- Added idempotent local match history, result/mode/color/difficulty filters,
  completed-game review, derived statistics with a preserved reset boundary,
  and fifteen one-time timestamped achievements.
- Added Android emulator integration coverage, comprehensive release-gate
  evidence, accessibility/security/performance reviews, a deterministic
  CycloneDX source SBOM, reproducible-build guidance, and release operations
  documentation.
- Repaired Android debug manifest merging, cross-drive Kotlin compilation, and
  the escaped Kotlin package declaration; a debug APK now builds successfully.

## 0.11.0 — 2026-07-26

- Added GPL-3.0-or-later licensing, copyright, notices, privacy, terms,
  security, contribution, conduct, support, governance, and release legal
  documentation.
- Added auditable dependency/license and documentation validation.
- Completed user-suggestion and technology documentation sets.

## 0.10.0 — 2026-07-26

- Added exactly 33 searchable, persistent language options.
- Added full ARB key/placeholder parity with honest English fallback drafts,
  contribution status, locale formatting, RTL behavior, accessibility, font
  fallbacks, pseudo-localization, tests, and CI checks.

## 0.9.0 and earlier

See `docs/development_manifest.md` for the complete phase-by-phase record and
published commit boundaries.
