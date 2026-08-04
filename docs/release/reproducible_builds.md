# Reproducible build procedure

The repository pins Flutter/Dart package versions, the Gradle wrapper, Android
configuration, and Node package integrity. This supports repeatable builds but
does not claim byte-for-byte Android reproducibility.

## Clean source procedure

1. Check out the exact candidate commit with no uncommitted files.
2. Install Flutter `3.44.7`, Dart `3.12.2`, JDK 21 (targeting Java 17), Android
   SDK 36, the required build tools, and NDK `28.2.13676358`.
3. Record `flutter doctor -v`, Java, Gradle, Node, npm, OS, SDK, and NDK output.
4. Run `flutter pub get` and `npm ci` in `server/`.
5. Run localization, SBOM, legal, documentation, puzzle, engine-manifest, and
   release-readiness checks.
6. Run formatting check, analysis, Flutter tests, integration tests, relay
   checks/build/tests, and the independent chess verifier.
7. Build the unsigned/debug candidate or owner-signed release artifact using the
   documented command.
8. Record SHA-256, file size, manifest, ABIs, native libraries, licenses, and
   source commit.

## Comparison

Build on a second clean machine with the same toolchain. If hashes differ,
compare ZIP entry ordering/timestamps, compiled resource metadata, native
toolchain output, signing blocks, and generated files. Do not call a build
reproducible until the comparison method and expected signing differences are
documented.

Secrets, keystores, passwords, service-account files, and Play credentials must
never enter the repository or build logs.
