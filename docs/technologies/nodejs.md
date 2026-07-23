# Node.js

The optional friend relay targets Node.js 24 or later. Node provides the HTTP
health endpoint, cryptographically secure room tokens, timers, signal handling,
and the runtime for the WebSocket server. The Flutter app remains fully usable
for offline modes when this service is absent.

The exact dependency graph is locked in `server/package-lock.json`. CI uses
`npm ci`, strict TypeScript checking, automated tests, and a production
dependency audit.
