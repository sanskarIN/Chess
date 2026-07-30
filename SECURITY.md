# Security policy

## Supported versions

Until the first production release, only the current `main` branch receives
security fixes. No APK/AAB from this repository is represented as production
supported.

## Report a vulnerability

Prefer a private GitHub security advisory for
`https://github.com/sanskarIN/Chess`. If that is unavailable, email
`sanskarin@outlook.in` with the subject `Chess-Master security report`.

Include the affected commit/version, component, reproduction steps, expected
impact, and whether the report contains personal or secret data. Do not include
real credentials, private keys, unrelated personal information, or room
sessions. Use a minimal test room and redact network identifiers.

Please do not open a public issue for an unpatched vulnerability. Maintainers
should acknowledge a report, reproduce it safely, decide severity/scope,
prepare a coordinated fix and tests, rotate exposed secrets if any, and publish
an advisory once users have a reasonable update path. No bounty or response
deadline is promised.

## Security boundaries

- Core chess and local data are offline-first.
- Friend multiplayer crosses a trust boundary to a configured relay and its
  hosting/network stack.
- Import files, FEN, PGN, ARB, protocol JSON, and WebSocket messages are
  untrusted inputs and must remain bounded and validated.
- Release signing keys must never enter the repository, logs, issues, test
  fixtures, or support messages.
- A native engine may be bundled only after source, checksum, ABI, load-test,
  license, and corresponding-source evidence passes the engine manifest gate.

See `docs/security_threat_model.md`, `server/SECURITY.md`, and
`docs/legal/release_legal_checklist.md`.
