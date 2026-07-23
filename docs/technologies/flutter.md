# Flutter

Chess-Master targets Flutter 3.44.7 stable. This was the current stable
documentation baseline selected on 2026-07-23. Flutter was not installed on the
authoring machine, so this version remains a CI/local verification target rather
than a passed test result.

Flutter provides the Android host integration, Material 3 widget system,
accessibility semantics, localization generation, rendering, animation, and
future cross-platform expansion. Android is the mandatory supported platform.

The project avoids prerelease framework APIs. The next toolchain-enabled session
must record the exact `flutter --version` output in the continuation manifest,
generate `pubspec.lock`, and run analyze, test, and a debug APK build.
