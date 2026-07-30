# Material 3

Material 3 provides adaptive Android-first controls, color schemes, typography,
touch targets, dialogs, navigation, and accessibility semantics. Chess-Master
uses a restrained theme layer so domain state is not encoded only by color.

Material widgets do not remove the need for product-specific checks. Board
markers have shape differences, actions have semantic labels, destructive
operations have explicit confirmation, large text uses scroll/flex layouts,
and RTL app navigation is separated from logical chessboard orientation.

Theme changes must test light, dark, high contrast, color-blind palette, reduced
motion, 200% text, TalkBack, and disabled/busy states.
