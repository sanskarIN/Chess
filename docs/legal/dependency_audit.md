# Dependency and notice audit

## Locked sources

`pubspec.lock` is the complete resolved Flutter/Dart package graph.
`server/package-lock.json` is the complete resolved npm graph, including
development and platform-optional compiler packages. Both lockfiles include
versions and integrity hashes for hosted packages.

`dart run tool/verify_legal.dart` checks that:

- each hosted package in `pubspec.lock` resolves through
  `.dart_tool/package_config.json`;
- each resolved hosted Dart package has a non-empty `LICENSE`, `LICENSE.txt`,
  or `COPYING` file;
- each non-root npm lock entry declares a non-empty SPDX license expression;
- the complete project license and every required policy/notice exist;
- no project file claims that a Stockfish executable is currently bundled.

The verifier proves coverage, not legal compatibility. A human release reviewer
must inspect new license expressions, unusual terms, attribution requirements,
native artifacts, and whether a dependency is actually conveyed.

## Release artifact notices

Flutter registers dependency licenses in the compiled app. The Settings About
section calls `showLicensePage`, which displays `LicenseRegistry` entries.
Before release, open that screen in the exact release build, verify it is
non-empty, and compare it with the lockfile. Preserve NOTICE files that are not
fully represented by a license text.

For a relay image, extract npm production dependencies with `npm ci
--omit=dev`, retain package license files, and generate an image-specific bill
of materials. Optional/development entries may be omitted only when inspection
of the actual image confirms they are not conveyed.

## Dependency change gate

A pull request adding or updating a dependency must include:

1. purpose and why existing code is insufficient;
2. upstream repository and immutable resolved version;
3. license and compatibility review;
4. package integrity/lockfile change;
5. permissions, network, data, native code, maintenance, and supply-chain impact;
6. notice and source updates;
7. tests and removal/rollback plan.
