# Friend multiplayer

Friend play is optional and online. It cannot honestly be described as using
zero network data: the configured relay temporarily processes player names,
team codes, reconnect credentials, readiness, moves, and connection metadata
while a room is active.

Durable application data remains on the device. The provided relay has no
database, user profile, account, analytics, advertising identifier, or
permanent match-history storage. Users may run it themselves and change the
relay URL through build configuration now and developer options in Phase 9.

## User flows

Hosts choose an optional name, White/Black/Random, and a four- or six-digit
code. Six digits is the default. The waiting room displays the assigned color,
copy/share actions, expiration time, connected players, and ready state.

Joiners enter an optional name and exactly four or six digits. Incorrect,
expired, full-room, unavailable-server, protocol, rate-limit, illegal-move, and
state-mismatch failures have distinct user-facing messages. The match begins
only after two players are connected and both select `I’m ready`.

## Synchronization

The server is authoritative for room membership and move order. A move includes
its expected ply and previous verified SHA-256 state hash. The server checks:

1. protocol version and input bounds;
2. bound room and opaque reconnect token;
3. assigned color and side to move;
4. ply and previous state hash;
5. UCI syntax and chess legality through `chess.js`.

It then broadcasts FEN, complete UCI history, players, and a new state hash.
Flutter verifies the hash, legally replays every move with the independent Dart
chess domain, and refuses divergent state. Optimistic local input remains
locked until relay acknowledgement.

## Reconnection and deletion

Unexpected disconnects use bounded exponential retry. A reconnect presents the
temporary room code, opaque session token, and last verified hash. The server
replaces stale sockets and sends authoritative state.

Rooms are deleted at their absolute expiration. If every player disconnects,
the room is deleted after the short reconnect grace period. Process restart
deletes all rooms immediately because all state is memory-only.

## Self-hosting

See [`server/README.md`](../server/README.md) for Node 24, environment,
Docker, TLS, origin, health, rate-limit, and log guidance. Release Android
builds require `wss://`; cleartext `ws://` is limited to debug development.
The relay URL is never invented by the app.
