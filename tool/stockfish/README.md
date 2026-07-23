# Rebuilding the Android engine

Chess-Master currently targets the official Stockfish 18 release tag `sf_18`
and commit prefix `cb3d4ee`. No native engine is committed.

## Reproducible preparation

1. Clone the official repository:

   ```powershell
   git clone --branch sf_18 --depth 1 https://github.com/official-stockfish/Stockfish.git stockfish-sf18
   git -C stockfish-sf18 rev-parse HEAD
   ```

2. Confirm the resolved commit begins with `cb3d4ee`.
3. Read `Copying.txt`, `README.md`, the `src/Makefile`, and the release
   documentation from that checkout.
4. Use a pinned Android NDK on a clean build host. Record the NDK version,
   compiler version, command line, target ABI, CPU feature set, and environment.
5. Build from `src/` using the official Makefile and the NDK compiler tuple for
   each selected ABI. Do not rename a shared library to look executable or copy
   an incompatible desktop executable into Android packaging.
6. Run the resulting executable directly on a matching physical device or
   emulator and verify `uci`, `isready`, `position`, `go`, `stop`, and `quit`.
7. Calculate SHA-256:

   ```powershell
   Get-FileHash -Algorithm SHA256 path\to\stockfish
   ```

8. Test both Android debug and unsigned release builds. Record the extracted
   APK/AAB native packaging path and confirm the file remains executable.
9. Add one manifest entry per ABI and run:

   ```powershell
   dart run tool/verify_engine_manifest.dart
   ```

10. Make the exact complete corresponding source, build instructions, license,
    network files, and project source available with the distributed version.

Official release archives can be used instead of a local compile only after
their published archive SHA-256 is checked and the extracted executable receives
its own SHA-256 entry. Never infer a binary checksum from the archive checksum.
