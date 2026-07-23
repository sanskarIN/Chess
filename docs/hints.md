# Chess hints

Phase 7 implements the first two useful hint levels:

1. identify a suggested source square;
2. identify a suggested target square and describe the candidate briefly.

The built-in asynchronous local search analyzes the current position using an
independent engine instance. The game stays interactive only after the request
finishes, and the resulting source and target receive a distinct board color and
semantic labels. Capture candidates receive a capture-oriented explanation;
other moves receive a general strong-candidate explanation.

Hints are advisory. The explanation asks the player to consider the opponent's
reply and does not claim that the move guarantees a win. Hints are disabled in
local and friend setup and remain optional in computer setup.

## No-charge failure order

The exact order is:

1. show the 1-hint or 25-coin confirmation;
2. generate and validate a local legal suggestion;
3. atomically spend the chosen earned asset;
4. display and highlight the result.

The wallet is never charged before step 2 succeeds. A stable request ID prevents
a retried purchase acknowledgement from charging twice.
