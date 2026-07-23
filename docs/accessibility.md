# Accessibility

Phase 3 implements the first executable accessibility contract.

The chessboard is one semantic container containing 64 focusable square
controls. Each square announces its coordinate, occupant, and applicable state.
Examples include:

- `White knight on G1`
- `E4, empty, legal move`
- `Black king on E8, in check`
- `D5, legal capture`

Piece glyphs are excluded from duplicate semantics because the square provides
the complete label. Legal moves and captures use different shapes as well as
colors. Player banners announce the player name, color, displayed timer, and
turn state. Captured-piece rows announce every captured piece and any material
advantage. The match-status banner is a live region so check, turn, and terminal
state changes can be announced.

All standard controls use Material touch targets and tooltips. Dialogs use
ordinary text and buttons with predictable focus order. No interaction depends
on sound. The interface uses flexible widgets, scrolling, wrapping, and bounded
content widths to support text scaling and portrait/landscape layouts.

Reduced motion is read from `MediaQuery.disableAnimationsOf`. Splash,
onboarding, square, piece, and captured-list animations become instantaneous
when reduced motion is active.

Automated widget tests verify semantic piece and legal-move descriptions. Device
TalkBack, large-font, keyboard, switch-access, and high-contrast audits remain
required in Phase 12 because widget tests cannot replace assistive-technology
testing on Android hardware.
