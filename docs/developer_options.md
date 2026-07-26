# Developer Options

Developer Options are documented, local, and disabled by default. Tap the
version row seven times in Settings → About. Each tap reports the remaining
count; the seventh tap persists the typed `developerOptionsEnabled` preference.

The route remains guarded even if it is opened directly. Development controls
are displayed under a warning that they can alter local data and do not make
the open-source offline economy tamper-proof.

## Diagnostics

The diagnostics group reports app/build, tested Flutter baseline, runtime Dart,
Android runtime where applicable, architecture/runtime description, SQLite
schema, local engine name and health, available-memory limitation, locale,
theme, last migration, and multiplayer protocol. It deliberately excludes
hardware identifiers, advertising identifiers, network addresses, room tokens,
player names, and relay URL contents.

Privacy-safe diagnostics copy only version, schema, protocol, locale, theme, and
whether a relay is configured.

## Debug controls and feature flags

Every debug switch is a `TypedFeatureFlag`; no hidden string keys are spread
through the codebase. The switches cover debug/performance overlays, layout and
repaint guidance, state/navigation/database/engine/multiplayer loggers,
localization-key inspection, accessibility-label inspection, experimental
analysis, pseudolocalization, expanded text, and RTL preview.

Sensitive loggers default to disabled. Enabling a flag does not bypass the
structured logger's redaction rules.

## Chess tools

- FEN editor and validator;
- PGN importer and legal replay validator;
- board-position editor for placement, side, castling, en-passant, and move
  counters;
- depth-three perft;
- checkmate, stalemate, promotion, en-passant, castling, and insufficient
  material positions.

The editors call the production FEN/PGN codecs and legal chess model. Invalid
positions are rejected rather than partially applied.

## Economy and challenge tools

Developer coin/hint additions and signed removals use the production atomic
ledger. They are marked `developerAdjustment`, reject negative balances, remain
idempotent by typed transaction key, and preserve the integrity chain.

The screen can simulate a reward, test duplicate rejection, view/export the
ledger, route to confirmed ledger reset, generate a date, simulate adjacent
dates, reset progress, complete a challenge through a domain event, test a
duplicate claim, preview feedback, and inspect refresh timing.

## Multiplayer tools

Relay editing accepts empty, `ws:`, or `wss:` values with a host. Server health
opens and immediately closes a bounded WebSocket health connection only after
the user taps the control. Other controls simulate latency, packet loss,
disconnect/reconnect, protocol selection, and privacy-safe room state without
inventing real peers or identifiers. State hashes use SHA-256 over a canonical
simulated state.

## Localization tools

Pseudolocalization, expanded text, and RTL preview are typed flags. The group
also exposes missing/untranslated reports, immediate locale switching, and
locale-aware number/date previews. Phase 10 supplies the exact 33-locale
catalog and automated translation completeness audit.

## Storage tools

Storage controls show table counts, schema, quick-check result, and last
migration. Safe export, backup, restore, corruption rejection, integrity check,
migration inspection, and confirmed local reset route through the same
versioned data-management service used by normal settings.

## Open-source links

The screen states that the game is fully open source and links to the
repository, GPL identifier, contribution guide, security guide, issue chooser,
and source-build instructions. The referenced repository documents are
completed at the Phase 11 legal/documentation boundary.
