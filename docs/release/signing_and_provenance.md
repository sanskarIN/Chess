# Signing and provenance

## Ownership boundary

The project repository does not contain a release keystore, upload key,
password, service-account credential, or Play signing private key. Signing
material must be created, backed up, rotated, and accessed by the application
owner through a secret manager or protected build environment.

## Supported signing inputs

The Gradle release configuration accepts these environment variables from a
protected shell or CI secret store:

| Environment variable | Local property |
| --- | --- |
| `CHESS_MASTER_KEYSTORE_PATH` | `storeFile` |
| `CHESS_MASTER_STORE_PASSWORD` | `storePassword` |
| `CHESS_MASTER_KEY_ALIAS` | `keyAlias` |
| `CHESS_MASTER_KEY_PASSWORD` | `keyPassword` |

Alternatively, the owner may create the ignored `android/key.properties` file
containing those four local property names. Environment values take precedence.
Use an absolute keystore path with forward slashes on Windows, and restrict
file permissions. Never commit this file, paste credentials into a command
transcript, or put a keystore inside a source archive.

Debug builds need no release credentials. Release APK/AAB packaging fails early
when signing values are incomplete or the keystore is missing; there is no
fallback to a debug certificate. A source release does not run signing or
contain an APK/AAB. Only after the owner configures valid signing and approves
the Android distribution gates should they run:

```text
flutter build appbundle --release
flutter build apk --release
```

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
