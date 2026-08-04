# Android build record

## Candidate

- Version: `0.12.0+12`
- Flutter: `3.44.7`
- Dart: `3.12.2`
- Android SDK: `36.1.0`
- Android platform installed for the build: API 35 revision 2
- NDK: `28.2.13676358`
- Java source/target: `17`
- Build requested: debug APK using Flutter's debug signing only

## Executed result

The installed NDK directory was initially empty and missing
`source.properties`. After verifying that exact directory, it was removed and
Gradle downloaded the licensed NDK package and Android Platform 35. Compilation
then exposed and corrected three repository issues:

1. the debug manifest now explicitly overrides the release-safe cleartext
   setting only for local debug relay connections;
2. Kotlin incremental compilation is disabled because the pub cache and
   checkout occupy different Windows drive roots;
3. the Kotlin package segment `in` is escaped while the application ID remains
   `in.sanskar.chessmaster`.

The authoritative command completed successfully:

```text
flutter build apk --debug --no-pub
```

The final artifact path, byte size, and SHA-256 are recorded in
`release_status.json`. The APK is a generated local artifact and is not
committed. The API 36.1 emulator integration smoke test also built, installed,
and passed independently.

## Distribution boundary

This debug APK is not approved for public distribution. A distributor must
build an owner-signed release AAB from an approved clean commit, inspect the
merged manifest, permissions, ABIs, native libraries, notices, resources,
application/version identity, and certificate, and then record source-to-build
provenance. No release signing key or configuration is present in this source
tree.
