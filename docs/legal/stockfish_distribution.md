# Stockfish distribution obligations

Chess-Master contains an engine-neutral API and a UCI Stockfish process adapter.
The current repository and build do **not** include a Stockfish executable,
source archive, opening book, tablebase, or neural-network file. Computer play
uses the project’s Dart local-search implementation.

Stockfish is GPLv3 software. A distributor adding Stockfish object code must
complete all of the following before publishing any APK/AAB:

1. Select an official, immutable Stockfish release/source commit.
2. Record upstream URL, commit/tag, source archive SHA-256, build scripts,
   compiler/NDK versions, flags, patches, target ABI, and resulting binary
   SHA-256 in the engine distribution manifest.
3. Build every ABI from the recorded corresponding source; do not download an
   unexplained executable.
4. Run protocol handshake, legal-move, crash/restart, timeout/stop, and on-device
   load tests for every shipped ABI.
5. Provide the complete machine-readable Corresponding Source required by GPL
   section 6, including build/installation scripts and project integration
   source, with equivalent no-charge access next to the binary.
6. Preserve Stockfish copyright/license notices and include GPL-3.0 text.
7. State modifications and dates, including local patches.
8. Ensure installation information obligations are reviewed for the
   distribution model.
9. Update NOTICE, THIRD_PARTY_NOTICES.md, the in-app license screen, release
   notes, source offer/access URL, SBOM, and artifact manifest.
10. Have a release reviewer verify that source access remains available for the
    legally required period and that the exact binary is reproducible from it.

The existing `tool/verify_engine_manifest.dart` intentionally fails unsafe
declarations. Passing that technical gate is necessary but not a legal opinion.
If source or distribution obligations cannot be satisfied, do not ship the
binary.
