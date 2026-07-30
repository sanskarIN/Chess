# Exact next work

Phase 11 is complete in source with the full GPL-3.0-or-later license,
copyright and third-party notices, dependency-license evidence, Stockfish
distribution boundaries, privacy and terms documents, security and contribution
policies, community templates, expanded technology documentation, in-app legal
summaries, and automated legal/link verification.

Phase 12 starts with:

```text
docs/release/release_checklist.md
```

Phase 12 implementation order:

1. define an auditable release gate model and record pass, blocked, external,
   and not-applicable states without converting unexecuted checks into passes;
2. add source, dependency, localization, legal, accessibility, privacy,
   performance, Android build, signing, store-listing, device, rollback, and
   support checklists;
3. generate a deterministic source dependency bill of materials from the
   committed Flutter and Node lockfiles;
4. add release-notes, test-matrix, known-limitations, reproducible-build,
   provenance, signing, incident, and rollback templates;
5. add a repository verifier that rejects incomplete or contradictory release
   evidence and enforce it in CI;
6. run formatting, analysis, complete Flutter and relay tests, coverage,
   localization, puzzle, engine, legal, documentation, and release checks;
7. attempt an unsigned Android debug APK with the available official toolchain
   and preserve the exact blocker if the SDK/NDK remains incomplete;
8. keep release signing, Play Console actions, device accessibility approval,
   native-speaker translation approval, and legal sign-off explicitly external.

Before the Android debug build can complete, install Android SDK command-line
tools and repair the incomplete NDK `28.2.13676358` installation. Accept any
remaining SDK licenses through the official tool. Do not configure or use a
release signing key.
