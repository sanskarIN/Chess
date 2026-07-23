# Flutter

Chess-Master is verified with Flutter 3.44.7 stable, framework revision
`84fc5cbb22`, engine revision `69c8c61792`, Dart 3.12.2, and DevTools 2.57.0.
The SDK was initialized and executed on the authoring machine on 2026-07-23.

Flutter provides the Android host integration, Material 3 widget system,
accessibility semantics, localization generation, rendering, animation, and
future cross-platform expansion. Android is the mandatory supported platform.

The project avoids prerelease framework APIs. Dependency resolution,
localization generation, static analysis, and the Flutter test suite pass.
The debug APK build reached Gradle and generated the wrapper, but the automatic
NDK 28.2 installation stalled with a zero-byte download. Android SDK
command-line tools and a complete NDK install are required before retrying.
