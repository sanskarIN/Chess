# Release documentation

No public production build exists yet. Phase 12 turns the repository’s tested
source into release-candidate evidence without configuring or exposing a
production signing key.

Release preparation covers the exact toolchain, clean dependency restore,
format/analyze/test/verifier matrix, relay audit, Android lint/debug build,
artifact inspection, SBOM/checksums, accessibility/device matrix, privacy/store
declarations, reproducibility, rollback, and maintainer sign-off.

The legal portion is already mandatory through
`docs/legal/release_legal_checklist.md`. A missing Android SDK/NDK, device,
reviewer, or signing environment is recorded as a blocker; it is never replaced
by a fabricated passing result.
