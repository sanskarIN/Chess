# Release checklist

This checklist applies to each candidate commit. A checked source gate does not
authorize public distribution when an external or blocked gate remains.

## Source and dependency integrity

- [x] The candidate version agrees across `pubspec.yaml`, `AppVersion`, the
  changelog, and release status.
- [x] Dependency locks are committed.
- [x] The deterministic source SBOM is current.
- [x] No unverified Stockfish executable is declared or bundled.
- [x] Localization generation and the 33-locale parity verifier pass.
- [x] Puzzle schema and legal-line verification pass.
- [x] GPL text, notices, dependency license files, and distribution claims pass
  the legal verifier.
- [x] Repository Markdown links and required documentation sets pass.

## Automated quality gates

- [x] Dart formatting is unchanged after `dart format`.
- [x] Flutter/Dart static analysis reports zero issues.
- [x] Unit and widget tests pass.
- [x] The host integration smoke test passes.
- [x] Independent chess-domain verification passes.
- [x] Relay TypeScript checking, build, and tests pass.
- [x] The Android debug APK is produced, sized, and SHA-256 recorded.

The debug artifact proves the Android source builds. It is not a signed Play
Store release artifact and is not committed to the repository.

## Security, privacy, accessibility, and performance

- [x] Source security controls and threat-model review are complete.
- [x] Automated semantics, large-text, RTL, reduced-motion, and contrast-related
  widget coverage passes.
- [x] Source-level startup, engine-bound, database, network, and logging
  performance risks are reviewed.
- [ ] TalkBack is manually exercised on a physical Android device.
- [ ] Large-text and display-size behavior is manually approved across the
  supported Android device matrix.
- [ ] Startup, frame timing, memory, battery, and long-match profiling is
  captured from a representative release-mode Android device.
- [ ] Every non-English locale receives qualified native-speaker translation
  and independent review.

## Distribution authorization

- [ ] A developer-owned upload/app-signing configuration is available outside
  the repository.
- [ ] A signed AAB is built from the approved commit.
- [ ] APK/AAB contents, native libraries, notices, and checksums are inspected.
- [ ] Privacy, store-data-safety, content rating, screenshots, and listing text
  receive owner review.
- [ ] A qualified reviewer completes final legal authorization.
- [ ] Rollback owner, support window, and incident contact are confirmed.

No unchecked distribution item may be silently waived. A release owner must
update `release_status.json` with evidence and rerun the release verifier.
