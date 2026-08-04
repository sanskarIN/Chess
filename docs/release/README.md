# Release documentation

Version `0.12.0+12` completes source-level QA and release preparation. The
repository is not represented as publicly distributable: the current release
status remains false until physical-device reviews, native translation review,
signing, store submission, and human legal authorization are complete.

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
