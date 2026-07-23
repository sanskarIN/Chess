# Puzzle assets

`training_positions.json` contains original Chess-Master positions released as
CC0-1.0. `schema.json` defines the accepted file shape. Every FEN and solution
move is validated by `tool/verify_puzzles.dart`; mate exercises must terminate
in checkmate, and the mate-in-two line must contain exactly three plies.

`daily_challenges.json` records the location and license of the deterministic
Dart challenge generator. It is metadata rather than a second source of runtime
challenge definitions.
