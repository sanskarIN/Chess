# Security threat model

## Protected assets

Legal game state, local saves/settings/progress, reward-ledger integrity,
privacy of optional names and games, friend-room availability/synchronization,
release source/signing integrity, and contributor trust are protected assets.

## Trust boundaries and threats

- Imported FEN/PGN/JSON can be malformed, oversized, inconsistent, or crafted
  to trigger expensive work. Parsing is bounded, typed, and validated before
  atomic persistence.
- WebSocket peers and relays can send malformed, replayed, duplicated,
  out-of-turn, oversized, or stale messages. The versioned protocol validates
  schema, room/session state, legal moves, ply, acknowledgements, and hashes.
- Room codes are invitations, not authentication secrets. Rate limits,
  expirations, reconnect tokens, TLS deployment, origin policy, and safe logs
  limit but do not eliminate guessing and denial of service.
- Device clock and local database owners can alter offline challenge/reward
  state. The ledger detects common inconsistency but is not tamper-proof and has
  no monetary/security claim.
- Dependencies, Gradle/npm packages, native engines, CI actions, and release
  tooling are supply-chain boundaries. Lockfiles, checksums, source manifests,
  notices, review, and artifact inspection are required.
- Logs, issues, exports, clipboards, screenshots, and support channels can leak
  names, games, codes, tokens, addresses, or keys. Redaction and user warnings
  are mandatory.

## Out of scope claims

The project does not claim resistance to a device owner with root/debug access,
perfect relay availability, cheat prevention, secure monetary balances, or
tournament-grade engine adjudication.

Security tests and policies reduce risk but do not prove absence of
vulnerabilities. Follow SECURITY.md for coordinated reports.
