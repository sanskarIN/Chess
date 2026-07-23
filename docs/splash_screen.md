# Splash screen

Chess-Master has two coordinated splash layers.

The Android launch theme uses local vector resources and follows system light or
dark appearance. Flutter then renders the original code-drawn knight mark,
configurable app name, `Open-source chess game`, and `Made by the Sanskar`.

The Flutter entrance lasts at most 420 milliseconds while the local onboarding
preference is read. It is not a network wait and becomes instantaneous when
reduced motion is enabled. The app does not add a separate branding delay after
the entrance completes.

If SQLite initialization fails, the splash shows a localized warning and an
explicit `Continue without saving` action. This makes the degraded behavior
clear: temporary play can continue, but durable progress cannot be written.

The mark is rendered with `CustomPainter`, so no proprietary logo or unlicensed
raster asset is included. Android adaptive-icon specifications remain in the
existing launcher resources. Store-listing raster exports are generated and
reviewed during release preparation rather than claimed as completed assets.
