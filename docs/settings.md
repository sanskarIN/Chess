# Settings system

Chess-Master stores application preferences locally in the SQLite
`app_settings` table. The application does not require an account and does not
send preferences to a server.

## Typed model

`AppSettings` is the single settings value used by the application.
Preferences with a bounded choice use Dart enums, including:

- theme and start screen;
- board and piece themes;
- coordinate and legal-move presentation;
- animation speed and promotion behavior;
- engine thinking time and haptic intensity;
- typed developer feature flags.

Boolean preferences use the `SettingFlag` enum. Unknown strings are never
looked up throughout the UI. The repository serializes enum names and bounded
values into a versioned JSON document under `app_settings_v1`. Corrupt JSON,
unsupported format versions, invalid enum values, unsafe string lengths, and
out-of-range numeric values fall back to documented defaults.

## Groups

The settings screen uses expandable groups so advanced options do not crowd the
primary flow:

- General: language, theme, start screen, confirmations, remembered name,
  onboarding reset, version, build, and release channel.
- Appearance: board/piece palettes, coordinates, move indicators, highlights,
  captured pieces, material, history, animation, reduced motion, fullscreen,
  and attribution visibility.
- Gameplay: default mode, difficulty, side, clock, promotion, undo, rotation,
  hints, auto-save, resume, awake mode, evaluation, and material estimate.
- Sound and haptics: master sound, individual system-sound events, haptic event
  types, and intensity.
- Computer opponent: thinking preference, strength limit, battery/background
  preferences, thinking indicator, evaluation, and analysis-line count.
- Multiplayer: four/six-digit room code, side, local display name, timeouts,
  reconnect duration, share template, warnings, diagnostics, recent opponents,
  and network-data explanation. Relay URL editing remains in Developer Options.
- Daily challenges and rewards: reminder preference, refresh explanation,
  animation and balance visibility, history, reset, export, and offline
  integrity limitations.
- Language: current/system language, search/preview entry point, RTL preview,
  missing-translation reporting, and English reset. The complete 33-option
  catalog is the Phase 10 boundary.
- Accessibility: high contrast, reduced motion, larger and stronger indicators,
  announcements, piece/SAN naming, haptic alternatives, color-blind palette,
  and screen-reader board mode.
- Privacy and data: policy explanations and the complete data-management screen.
- About and creator: identity, build, repository, GPL status, technologies,
  contributors, package licenses, changelog, features, support, and safe creator
  links.

## Runtime behavior

Theme and locale changes rebuild `MaterialApp` without a restart. Reduced motion
sets the application `MediaQuery.disableAnimations` preference. High contrast
can be selected as a theme or accessibility override.

`ChessBoard` reads settings through a narrow Riverpod selector. Board palette,
color-blind palette, coordinates, legal destinations, legal-marker style and
size, last-move/check highlighting, animation speed, and piece visual emphasis
therefore update without changing chess-domain state.

New-game setup reads saved side, difficulty, clock, name, hint, orientation, and
undo defaults. Active games apply auto-queen, sound/haptic feedback, hint and
coin confirmation, resignation and exit confirmation, captured/material/history
visibility, engine analysis visibility, fullscreen mode, and Android
keep-screen-on. Auto-save uses a stable per-game identifier and serialized
writes. Resume-last-game loads the newest valid local save after onboarding.

## Attribution

The watermark preference controls optional duplicate placements only. It does
not remove the required “Made by the Sanskar” attribution from project surfaces
where the project rules require it.

## Notifications and links

Saving the daily-reminder preference does not request Android notification
permission and does not schedule operating-system notifications. A future
notification implementation must ask at the point of use.

External links accept only `https:` and `mailto:` URIs. A launch failure copies
the target to the clipboard and shows a message. Opening a link does not collect
device or identity information.

## Tests

Automated coverage verifies defaults, full typed round-trip serialization,
corrupt/future-format fallback, reset, idempotent initialization, seven-tap
developer unlock, settings groups, toggle persistence, developer guarding, and
destructive data controls.
