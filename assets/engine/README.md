# Engine distribution staging

This directory intentionally contains no Stockfish executable.

Chess-Master can use its built-in pure-Dart legal-search engine today. A native
Stockfish binary may be added only after `manifest.json` contains a verified
entry for every packaged ABI and `dart run tool/verify_engine_manifest.dart`
passes.

Required release ABIs are:

- `arm64-v8a`
- `armeabi-v7a` when the selected Stockfish release and device testing support it
- `x86_64` for emulator testing when practical

Each entry must identify the exact source tag and commit, extracted binary path,
binary SHA-256, archive source, archive SHA-256, license, and successful debug
and release loading checks. Undeclared files under `assets/engine/bin/` fail
verification.

Development can point to a locally built executable without packaging it:

```powershell
flutter run --dart-define=CHESS_MASTER_STOCKFISH_PATH="C:\path\to\stockfish.exe"
```

Such a binary is labeled a development binary and is never treated as
distribution-verified.
