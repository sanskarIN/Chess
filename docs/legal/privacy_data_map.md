# Privacy data map

| Data | Source | Storage/processor | Purpose | Retention/control |
|---|---|---|---|---|
| Settings and flags | User choices | Local SQLite | Configure app | Reset/delete/uninstall |
| Optional player names | User input | Local game/setup data | Display in local games/exports | Remembering toggle, saved-data deletion |
| Games, FEN, PGN, notes | Play/import | Local SQLite or user export | Save/review/share | Per-save delete, data reset, export control |
| Tutorial/puzzle progress | Local actions | Local SQLite | Progress display/reward-once | Practice reset/delete |
| Challenges and reward ledger | Local actions/date | Local SQLite | Offline challenge/economy integrity | Selective reset/delete/export |
| Friend room/session/moves | Players during active match | Configured relay memory and client memory | Synchronize match/reconnect | Relay expiry/disconnect; host infrastructure may log |
| IP/transport metadata | Network stack | Relay host/proxy/provider | Deliver/protect connection | Host policy; not stored by included app database |
| Diagnostics/logs | Runtime | Device console/process | Development/troubleshooting | Redacted; distributor/device controls retention |
| Clipboard exports/codes | Explicit user action | OS clipboard/other apps | Copy/share | User/OS/receiving-app control |
| External-link requests | Explicit user action | Browser/email and destination | Open support/source profiles | Destination policy |

There is no account, analytics, advertising identifier, contacts, location, or
behavioral-profile row because the current source does not collect them.

## Trust boundaries

Local SQLite and app-private files are inside the application boundary. User
exports, clipboard data, browsers, email clients, configured relays, reverse
proxies, hosting providers, app stores, and modified downstream builds are
outside it. Documentation and consent must not collapse those boundaries.
