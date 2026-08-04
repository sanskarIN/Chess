# Security review

## Source controls reviewed

- No accounts, persistent server profiles, telemetry, advertising identifier,
  cloud database, location, contacts, microphone, or camera permissions.
- Android backup is disabled and cleartext is disabled outside debug policy.
- Player names, team codes, relay URLs, protocol messages, moves, FEN, PGN,
  backups, settings, challenges, and reward operations are validated.
- Relay messages have size/rate limits, protocol versions, room expiry,
  reconnect token handling, authoritative legal validation, and state hashes.
- Logs redact names, network addresses, room/team codes, tokens, email, cookie,
  and authorization fields.
- SQLite mutations for rewards, imports, history, and saves use transactions and
  constraints; idempotency keys prevent repeated grants/unlocks.
- Native Stockfish remains unavailable unless manifest source, checksum, ABI,
  and load evidence is complete.
- Dependency versions and integrity evidence are locked; legal/source and SBOM
  verification are automated.

## Residual risks

- A modified open-source client can alter device-clock-based local rewards.
- A malicious relay operator can observe active room traffic and disrupt a
  match, though permanent server storage is not implemented.
- Developer-supplied relay and engine paths extend the trust boundary.
- Local exports are readable by recipients chosen by the user.
- Device compromise can expose local SQLite and exports.

## Release actions

Review dependency advisories, Android manifest merge output, APK/AAB contents,
network security configuration, relay production origin/TLS configuration, and
source-to-artifact provenance for every release. Report vulnerabilities through
the private process in `SECURITY.md`.

The source review is passed. A final artifact penetration review and production
relay deployment review are distributor-owned gates.
