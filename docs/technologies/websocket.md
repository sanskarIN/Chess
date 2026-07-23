# WebSocket

WebSocket supports the relay's small bidirectional session messages without
polling. The server accepts upgrades only at `/ws`, caps payloads at 16 KiB,
disables compression, optionally checks browser origins, and rate-limits each
connection. Application heartbeat messages and WebSocket ping intervals detect
dead sessions.

WebSocket transport does not provide durable storage or privacy by itself.
Production deployments must use TLS (`wss://`), minimize proxy logs, bound
connections, and protect reconnect tokens. The `/health` endpoint exposes only
status, protocol version, room count, and uptime.
