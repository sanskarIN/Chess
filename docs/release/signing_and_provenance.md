# Signing and provenance

## Ownership boundary

The project repository does not contain a release keystore, upload key,
password, service-account credential, or Play signing private key. Signing
material must be created, backed up, rotated, and accessed by the application
owner through a secret manager or protected build environment.

## Candidate provenance record

For an authorized release, record:

- source repository and exact commit;
- clean-tree status and protected-branch review;
- Flutter, Dart, Java, Gradle, Android SDK/NDK, Node, npm, and OS versions;
- lockfile and source-SBOM hashes;
- executed gate results and reviewer identities;
- build command and environment identifier;
- artifact name, size, SHA-256, version code/name, application ID, ABIs, and
  signing certificate fingerprint;
- corresponding source and notice location;
- store upload time and owner.

## Rules

- Never sign an artifact built from a dirty or unidentified source tree.
- Never reuse debug signing for public distribution.
- Never log passwords or export private keys with a release bundle.
- Verify the final store-delivered certificate and artifact metadata.
- If provenance cannot be traced from commit to artifact, stop distribution.

Current status: owner-controlled release signing and provenance attestation are
external and incomplete.
