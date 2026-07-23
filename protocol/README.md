# Friend-match protocol

Protocol version `1` uses UTF-8 JSON objects over WebSocket. Every message has:

- `protocolVersion`
- `type`
- `requestId`

The client sends `create_room`, `join_room`, `ready`, `move`, `reconnect`, and
`ping`. The server sends `room_created`, `room_joined`, `reconnected`,
`room_update`, `game_started`, `state`, `pong`, and `error`.

Reconnect tokens are 32 random bytes represented by 64 lowercase hexadecimal
characters. They are bearer credentials for one temporary room slot and must
never be logged, put in URLs, or persisted as a user profile.

Move messages contain the expected ply and the SHA-256 of the last verified
state. The canonical hash input is:

```text
<FEN>\n<comma-separated UCI moves>
```

The server validates membership, token, turn, ply, previous hash, UCI syntax,
and chess legality. It broadcasts the new FEN, complete UCI history, and state
hash. The client recalculates the hash and replays the history through its own
legal chess domain. The shared fixtures in `friend_state_fixtures.json` prevent
Dart/Node canonicalization drift.

Team codes identify rooms but are not authentication secrets. Four-digit codes
are convenient but have a smaller search space; six digits are the default.
Rate limiting, short room lifetime, and opaque reconnect tokens limit abuse.

Protocol errors use stable machine codes:

- `invalid_code`
- `expired_code`
- `room_full`
- `protocol_mismatch`
- `state_hash_mismatch`
- `illegal_move`
- `rate_limited`
- `invalid_message`
- `internal_error`

Unknown fields may be ignored within protocol version 1, but required fields are
validated strictly. A breaking shape or semantic change requires a new protocol
version.
