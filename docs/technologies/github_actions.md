# GitHub Actions

GitHub Actions runs independent Flutter analysis, Flutter tests, Android build,
and relay checks on pushes and pull requests. Workflows pin the Flutter version
and use committed dependency lockfiles.

CI is untrusted automation, not a secret store or release approval. Workflows
should use least permissions, pin or deliberately review third-party actions,
avoid printing environment values, and separate pull-request checks from
protected signing/release jobs. Artifact provenance and release signing remain
Phase 12 gates.

Localization, legal, documentation, engine, puzzle, and chess-domain verifiers
convert cross-file contracts into deterministic failures.
