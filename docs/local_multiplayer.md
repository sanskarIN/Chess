# Local multiplayer

Local two-player matches run entirely on the Android device. They do not open a
socket, call a relay, require an account, or copy player names outside the
in-memory match setup.

## Setup

Both names are optional and use localized `Player 1` and `Player 2` defaults.
Player 1 may choose White, Black, or Random. The setup also provides the common
clock presets, three orientation modes, and two undo policies:

- `Ask the opponent` creates a named approval request before undo or redo.
- `Always allow undo` applies the history action immediately.

Draw offers always require the other named player to approve. A declined action
does not change the board, clock, or result.

## Clock correctness

`GameClock` uses an injected monotonic time source backed by `Stopwatch`; wall
clock changes therefore cannot add or remove thinking time. The clock stores
microsecond-precision durations and the UI rounds positive values upward only
for display. It:

- charges only the active side;
- adds increment after a legal completed move;
- clamps expiration at zero;
- delegates timeout adjudication to the chess domain, including draw-by-timeout
  when the opponent cannot possibly mate;
- pauses while the explicit pause surface or application lifecycle hides play;
- stops after any terminal result;
- resets both sides for rematch.

Every completed move stores before/after clock snapshots with a move token.
Undo, redo, and alternate continuations therefore move the clock history cursor
with the board history cursor. A different continuation discards stale redo
clock state.

`MatchClockController` observes the canonical chess controller, so human moves,
computer moves, undo, redo, terminal moves, and rematches follow the same clock
path. A timeout during computer search ends the match and cancels the in-flight
search before a late move can be applied.

## Orientation and actions

The board can keep White or Black at the bottom, rotate after every move, or be
flipped manually. Rotation happens only after a completed legal move.

Pause blocks board interaction and clock consumption. Resignation is confirmed
for the side to move. Rematch creates a new game identifier, clears pending
approvals, restores both clocks, and returns White to move.
