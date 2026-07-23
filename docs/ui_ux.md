# UI and UX system

Phase 3 establishes a Material 3 design system shared by all current screens.
`DesignTokens` defines responsive page padding, spacing, radii, minimum touch
target guidance, and maximum content width. The app supports light, dark, and
system theme selection at the application level; user-facing theme selection
is added in Phase 9.

The visual language uses a forest-green seed, warm board neutrals, restrained
surface borders, large readable headings, and a code-drawn original knight
brand mark. The mark contains no copied external artwork and scales without a
raster dependency.

Layouts adapt at two main breakpoints:

- Compact layouts use a single scrolling column and a board constrained to the
  available width.
- Wide layouts place the board and match information side by side.
- Home actions use one, two, or three columns based on available width.

Animations are short and functional: splash entrance, onboarding page movement,
square state changes, piece transitions, and capture-panel resizing. Every such
animation uses zero duration when Android or Flutter reports disabled
animations.

Unavailable later-phase features remain discoverable but clearly report that
they are planned. Friend play is marked online and relay-required, with an
up-front explanation of temporary network processing. Screens always provide a
back, close, home, or continuation action.

The board palette does not carry meaning by color alone. A normal legal move is
shown as a center dot; a legal capture uses a ring; selection, last move, and
check also have distinct semantic labels. Settings later allow additional board,
piece, high-contrast, and color-vision-friendly themes.
