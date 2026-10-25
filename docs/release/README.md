# Release documentation

Version `1.0.0+13` is the first stable **source-only** GitHub release, tagged
`v1.0.0`. It packages the implementation completed in all twelve source phases,
the source dependency SBOM, documentation, and build/test instructions.
Read the [1.0.0 release notes](v1.0.0.md) for features and limitations.

Source publication is separate from Android application distribution. No
APK/AAB or signing secret is attached. `readyForDistribution` remains false
until physical-device reviews, native translation review, signing, store
submission, and human legal authorization are complete. A stable source tag
does not override those gates or claim a verified multilingual Android binary.

## Release control

- [Release checklist](release_checklist.md)
- [Machine-readable gate status](release_status.json)
- [Test matrix](test_matrix.md)
- [Android build record](android_build.md)
- [Accessibility review](accessibility_review.md)
- [Performance review](performance_review.md)
- [Security review](security_review.md)
- [Known limitations](known_limitations.md)
- [Reproducible builds](reproducible_builds.md)
- [Signing and provenance](signing_and_provenance.md)
- [Store submission](store_submission.md)
- [Rollback and incident response](rollback_and_incident.md)
- [Release-notes template](release_notes_template.md)
- [Source dependency SBOM](source_sbom.json)

## Legal prerequisites

- [Release legal checklist](../legal/release_legal_checklist.md)
- [Dependency audit](../legal/dependency_audit.md)
- [Stockfish distribution obligations](../legal/stockfish_distribution.md)
- [Privacy data map](../legal/privacy_data_map.md)

`dart run tool/verify_release_readiness.dart` validates that the documentation,
source SBOM, version, and gate record agree. It validates evidence integrity; it
does not convert external approvals or blocked commands into passes.

Release signing material must remain developer-owned and outside the
repository.
