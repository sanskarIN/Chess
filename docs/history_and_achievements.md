# Match history, statistics, and achievements

## Completed-match recording

Every completed computer, local, or friend match is submitted once to the local
history repository. A deterministic history ID makes repeated completion
notifications idempotent. The SQLite transaction stores the setup, initial and
final positions, every move, result/reason, perspective color, opponent mode,
duration, move count, hint count, difficulty, time control, and local completion
timestamp.

No team code, relay URL, reconnect token, IP address, or protocol session value
is stored in history or exported PGN.

## History and review

The home History destination supports All, Wins, Losses, Draws, Computer,
Local, Friend, White, Black, and all four computer-difficulty filters. Each
entry shows the requested opponent, color, outcome, reason context, date,
duration, move count, difficulty where applicable, time control, and hint count.
Selecting an entry opens the immutable move-by-move review with FEN copy and PGN
export.

For same-device local matches, White is the statistics perspective because both
players are local users. The underlying result and player names remain present
in the stored game.

## Statistics

The statistics tab derives games, wins/losses/draws, difficulty wins, side
results, average/fastest/longest durations, moves, captures, hints, completed
challenges, earned coins/hints, solved puzzles, and daily streaks from local
SQLite evidence.

Reset writes a local UTC reset boundary. It starts future statistics at zero
without deleting match history, challenge/reward records, solved puzzles, or
one-time achievement unlocks. The destructive data-management actions remain
separate and require confirmation.

## Achievements

Fifteen definitions cover the master prompt’s First Move, First Win, First
Checkmate, Win as Black, Castle Successfully, Promote a Pawn, Puzzle Beginner,
Puzzle Solver, Challenge Starter, Challenge Master, No-Hint Victory, Ten Games,
Fifty Games, Local Match, and Friend Match milestones.

Progress is derived from durable local match/move/challenge/practice data.
SQLite conflict handling preserves the first `unlocked_at` timestamp, clamps
display progress to the target, and prevents a one-time unlock from being
awarded repeatedly. Statistics reset does not relock an achievement.

## Degraded storage mode

When SQLite startup is unavailable, the application uses a process-memory
repository so gameplay can continue. That history is intentionally not durable
and disappears when the process exits, consistent with other degraded-mode
repositories.
