# Logging

`AppLogger` emits structured records with UTC time, severity, stable event name,
non-sensitive fields, and error type. Stack traces are routed to the development
logging backend but are not included in the record's user-exportable fields.

The logger redacts exact field names for:

- authorization and cookies
- email and network addresses
- player names
- room and team codes
- tokens

Callers should use stable event names such as `database.opened` and small scalar
fields. Do not log FEN/PGN by default, imported file content, full WebSocket
payloads, local paths, names, codes, IP addresses, tokens, secrets, or signing
configuration.

Production retention and diagnostic export are not implemented in Phase 1.
Future in-app diagnostics must be opt-in, previewable, bounded, and scrubbed
again at export time.
