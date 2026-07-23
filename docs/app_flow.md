# Application flow

The application starts at `/`, where the Flutter splash screen completes the
brand entrance while reading only the local onboarding preference. Startup does
not contact a multiplayer service.

When onboarding has not been completed, the router moves to `/onboarding`.
Users can move through ten pages, go back, skip, finish, and choose whether the
flow appears again. Completion is stored in the local `app_settings` table.
Unreadable or malformed preference data safely causes onboarding to reappear.

The home route is `/home`. Its current working actions are:

1. Play vs Computer setup at `/play/computer`.
2. Local Two-Player setup at `/play/local`.
3. Friend Match team-code lobby at `/play/friend`.
4. Expanded mode selection at `/play`.
5. Daily challenges and rewards at `/challenges`.

Friend Match requires an explicitly configured optional relay. Its lobby creates
or joins temporary four- or six-digit rooms, waits for both players, then passes
the live session to `/friend-game`. Daily challenges open the deterministic
local-date dashboard with wallet, claim, history, ledger, and offline-integrity
information. Practice, saved games, history, and settings still show an honest
unavailable message rather than opening empty screens.

Computer and local setup collect optional names, side assignment, time control,
and mode-specific preferences. A valid setup is passed as typed route state to
`/game`; navigating directly to `/game` without that state produces the normal
localized route-error screen.

The game screen sends square selections to `ChessGameController`. The controller
uses only the tested chess domain for legal moves and state transitions. It
publishes selection, captures, check, history, undo/redo, draw, resignation,
board orientation, and result state to the widgets. No widget applies a chess
move directly.

Terminal results open a non-dismissible summary with rematch, review, PGN copy,
and return-home actions. Review keeps the completed position visible. Rematch
creates a new stable game ID and resets the start time.

Eligible computer and local game events are submitted to the challenge
controller using stable receipt IDs. Hint-enabled computer games generate a
local candidate before spending the confirmed earned coin or hint cost.
