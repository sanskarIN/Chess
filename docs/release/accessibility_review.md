# Accessibility review

## Automated source evidence

The Flutter suite covers semantic square/piece/move labels, selected and legal
move states, result content, language option native/English labels, expanded
text, RTL application direction, logical LTR chess coordinates, reduced motion,
and uncommon-locale framework fallback. Material targets use the shared design
tokens and the board conveys move state by shape as well as color.

These source checks are passed for the current candidate. They do not prove
physical-device accessibility.

## Required Android review

Using TalkBack on a physical device:

1. traverse splash, onboarding, home, setup, game, result, history, settings,
   language, guide, challenges, practice, saves, and data management;
2. verify focus order follows reading order in LTR and RTL;
3. verify every chess square announces coordinate, piece, color, selection,
   legal move/capture, last move, and check without relying on the glyph;
4. play a complete match without sight and confirm promotion, clock, draw,
   resignation, result, review, and export controls;
5. confirm live statuses do not interrupt every move excessively;
6. confirm platform sound can be disabled and haptic alternatives are
   independently controllable.

Repeat with largest font and display size, light/dark/high-contrast themes,
reduced motion, and at least one RTL locale. Capture device/OS, screen recording
where safe, defects, and reviewer approval.

## Current disposition

Automated accessibility review is passed. Physical-device TalkBack and display
matrix approval are external gates and remain incomplete; public distribution
is therefore not authorized.
