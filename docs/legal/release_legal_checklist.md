# Release legal checklist

Complete this for the exact commit and artifact. Store evidence with the release.

## Project and source

- [ ] Version/tag/commit and source archive are immutable and publicly available.
- [ ] LICENSE is the unmodified GPLv3 text; project metadata says
      GPL-3.0-or-later.
- [ ] COPYRIGHT, NOTICE, AUTHORS, changelog, and modification dates are current.
- [ ] Corresponding source includes build scripts, generated-source inputs,
      lockfiles, relay source, and integration code.

## Dependencies and assets

- [ ] Legal/documentation/engine/puzzle/localization verifiers pass.
- [ ] Flutter LicenseRegistry was inspected in the exact release build.
- [ ] `pubspec.lock`, npm production tree, Gradle graph, native libraries,
      resources, fonts, icons, puzzles, and other data were inventoried.
- [ ] Every conveyed third-party item has compatible license/source/notices.
- [ ] SBOM and SHA-256 artifact manifest were generated from final artifacts.

## Stockfish/native code

- [ ] No Stockfish/native engine exists, or every item in
      stockfish_distribution.md is complete.
- [ ] Every APK split/ABI was inspected; no undeclared `.so` or executable exists.
- [ ] Corresponding-source access was tested from a clean machine.

## Privacy, safety, and stores

- [ ] Actual runtime traffic and Android permissions match PRIVACY.md.
- [ ] Configured relay host policy, retention, origin/TLS, and processor data are
      documented.
- [ ] Store data-safety/content/age declarations match the artifact.
- [ ] Terms, support, security reporting, deletion/export, and external links work.
- [ ] No test endpoint, debug overlay, sensitive log, sample personal data, or
      signing material is present.

## Approval

- [ ] Release QA passed on supported devices and accessibility configurations.
- [ ] Signing uses protected release infrastructure, not repository files.
- [ ] Maintainer recorded reviewer, date, known limitations, and rollback plan.

An unchecked item blocks public distribution unless an explicit, documented
decision explains why it does not apply.
