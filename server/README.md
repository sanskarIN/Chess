# Chess-Master friend relay

This optional Node.js/TypeScript service relays active friend matches over
WebSockets. It stores rooms only in process memory. It has no account system,
profile store, analytics SDK, advertising identifier, or match-history
database.

## Run locally

```powershell
npm ci
npm test
npm start
```

The default endpoints are:

- WebSocket: `ws://localhost:8080/ws`
- health: `http://localhost:8080/health`

Configure a debug app with:

```powershell
flutter run --dart-define=CHESS_MASTER_RELAY_URL=ws://10.0.2.2:8080/ws
```

Android release builds reject cleartext traffic. Production deployments must
terminate TLS and use `wss://`.

## Configuration

| Environment variable | Default | Meaning |
| --- | ---: | --- |
| `HOST` | `0.0.0.0` | Bind address |
| `PORT` | `8080` | HTTP/WebSocket port |
| `ROOM_TTL_MS` | `1800000` | Absolute temporary room lifetime |
| `RECONNECT_GRACE_MS` | `30000` | Retention after every player disconnects |
| `RATE_LIMIT_WINDOW_MS` | `10000` | Per-connection sliding window |
| `RATE_LIMIT_MESSAGES` | `40` | Messages allowed per window |
| `ALLOWED_ORIGINS` | empty | Optional comma-separated browser origins |

Use a reverse proxy for TLS, request-size enforcement, connection limits, and
deployment health checks. Do not put team codes, player names, reconnect tokens,
or client network addresses in proxy access logs.

## Privacy and lifecycle

The relay briefly sees player names, team codes, reconnect credentials, moves,
and connection metadata because those are necessary for the active session.
Those values remain in memory and are not intentionally written to production
logs. A room is destroyed at its absolute expiration, or after all players have
been disconnected for the reconnect grace period. Restarting the process
destroys every room.

The server verifies protocol version, input shapes, session credentials, turn,
ply, legal chess moves, and previous state hashes. Clients verify the returned
SHA-256 state hash and replay every move through their independent chess domain.
