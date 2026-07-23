# Stockfish

Stockfish is a strong UCI chess engine distributed under GNU GPL version 3.
Chess-Master includes a UCI adapter and an Android verification boundary but
does not currently include a Stockfish executable.

The selected source target is the official Stockfish 18 release:

- repository: <https://github.com/official-stockfish/Stockfish>
- release tag: `sf_18`
- release commit prefix: `cb3d4ee`
- license file in upstream source: `Copying.txt`

Official release artifacts include Android ARM archives with published archive
SHA-256 values. A future Chess-Master release must verify the downloaded archive
checksum and separately calculate the extracted executable checksum. Source tag,
commit, NDK, compiler, ABI, flags, network files, output hash, packaging, debug
load, release load, and corresponding-source location all belong in the release
evidence.

Bundling Stockfish makes GPL compliance a distribution requirement, not an
optional notice. The complete corresponding source and build scripts for the
exact executable must remain available. Chess-Master uses GPL-3.0-or-later to
remain compatible, while Stockfish's own notices and GPL-3.0 terms remain
preserved.

See [engine architecture](../chess_engine.md), the
[`assets/engine` staging policy](../../assets/engine/README.md), and the
[rebuild procedure](../../tool/stockfish/README.md).
