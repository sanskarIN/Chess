# Game modes

## Play vs Computer

The computer flow supports optional player name, White/Black/Random assignment,
four difficulty presets, standard time-control labels, and hints. The built-in
legal local-search engine runs asynchronously in an isolate, makes the first
move when the computer is White, locks input while thinking, publishes analysis,
and exposes retryable errors. This flow is covered by unit and widget tests.

The UCI Stockfish adapter is also tested, but a native executable is not bundled
until source correspondence, checksum, ABI, and debug/release load evidence can
be supplied. The app therefore does not mislabel its current local search as
Stockfish.

## Local Two-Player

The local mode is fully offline and requires no server, account, or Internet
connection. It supports optional names with localized defaults, White/Black/
Random assignment, no-clock and common clock presets, increments, pause,
timeout adjudication, fixed White, fixed Black, automatic rotation after each
move, manual flip, and rematch.

Undo and redo either happen immediately when `Always allow undo` was selected or
show a named hand-off approval dialog for the other player. Draw offers always
require the named opponent to approve. Resignation still requires confirmation
from the side to move. Clock snapshots follow the move-history cursor, so an
approved undo or redo restores both board and clock state consistently.

## Friend Match

The mode is visible and marked `Online · Experimental`, but cannot start a room
yet. Its screen explains that active session messages require a temporary relay
and that no permanent server-side match history is planned. Four- and six-digit
rooms, reconnection, synchronization, and the self-hostable Node.js relay are
Phase 6.

## Daily challenges, practice, and saved games

These home actions remain discoverable and return an explicit planned-feature
message. They are implemented in Phases 7 and 8. They are not presented as
available in the current build.
