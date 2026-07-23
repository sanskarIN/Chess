# Exact next work

Phase 5 is complete with 79 passing Flutter tests, zero analyzer issues, a
passing independent chess-domain verifier, and a passing native-engine manifest
verification.

Phase 6 starts with:

```text
lib/features/friend_multiplayer/domain/team_code.dart
```

Phase 6 implementation order:

1. validated four- and six-digit team-code value objects;
2. versioned client/server message protocol and state hashing;
3. create, join, waiting-room, error, and privacy UI;
4. reconnecting WebSocket client with explicit relay configuration;
5. self-hostable TypeScript WebSocket server under `server/`;
6. in-memory room lifecycle, rate limiting, validation, and expiration;
7. authoritative legal move and synchronized-state handling;
8. reconnect, health, graceful-shutdown, client, server, and protocol tests;
9. deployment, privacy, security, and troubleshooting documentation.

Before the Android debug build can complete, install Android SDK command-line
tools and repair the incomplete NDK `28.2.13676358` installation. Accept any
remaining SDK licenses through the official tool. Do not configure or use a
release signing key.
