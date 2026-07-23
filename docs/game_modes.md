# Game modes

## Play vs Computer

Phase 3 provides the complete setup and match presentation for optional player
name, White/Black/Random assignment, four difficulty labels, standard time
controls, and hints. The Stockfish-backed move service is Phase 4, so current
documentation does not classify the computer opponent as tested or available.

## Local Two-Player

The Phase 3 controller already supports two optional names, default localized
names, side assignment, board flipping, optional rotation after a move,
no-clock or preset clock display, legal play, undo/redo, draw agreement,
resignation, rematch, review, and PGN copy. Accurate monotonic countdown clocks
and local approval policy are implemented in Phase 5 before the entire mode is
classified as tested.

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
