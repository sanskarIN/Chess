# Known limitations

- No distribution-verified Stockfish Android executable is bundled. Computer
  play uses the bounded built-in Dart search; the UCI Stockfish adapter is
  implemented and fake-process tested.
- Friend play requires an explicitly configured trusted/self-hosted relay.
  Rooms are temporary and memory-only, but an active relay operator can observe
  room traffic and disrupt a match.
- Local challenge/reward integrity is not tamper-proof against a modified client
  or manipulated device clock.
- The 32 non-English ARB files are complete English fallback drafts pending
  qualified native-speaker translation and independent review.
- Platform system click/alert sounds are used; no external sound-effect asset
  pack is bundled. Available sound and haptic controls remain device-dependent.
- Physical-device TalkBack, large-display, battery, memory, and frame profiling
  are not complete.
- A debug APK and API 36.1 emulator smoke result exist, but the complete
  physical-device/version/ABI/accessibility/performance matrix is not approved.
- Release signing, AAB build, Play Console data safety/listing, legal approval,
  and public distribution authorization are not complete.
- The source SBOM inventories locked source dependencies. It is not a substitute
  for inspecting the contents of a produced APK/AAB.

These limitations are product/release facts, not hidden failures. Maintainers
must update this file whenever one is resolved or a new limitation is found.
