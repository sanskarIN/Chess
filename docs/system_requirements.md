# System requirements

This document separates required development baselines from values actually
observed on the current workstation on 2026-07-23.

## Development baseline

| Component | Requirement | Rationale |
| --- | --- | --- |
| Flutter | 3.44.7 stable | Current stable documentation baseline selected for the project |
| Dart | 3.12.x bundled with Flutter | `sqflite` 2.4.3 requires Dart 3.12 |
| Java | JDK 17 | Android Gradle source and target compatibility |
| Android Studio | Current stable | Android SDK, emulator, profiler, and bundled JDK |
| Android SDK | API 36 installed | Current Flutter Android setup guidance |
| Android minimum SDK | API 24 (Android 7.0) | Required by the selected `path_provider` 2.1.6 release |
| Git | 2.40 or newer recommended | Source control and reproducible contribution workflow |
| Node.js | Not required until Phase 6; use an active LTS line for the relay | Server runtime will be pinned with its lockfile |
| npm | Bundled compatible version | Server dependency installation and checks |
| Docker | Optional | Reproducible relay deployment and integration testing |

Windows, macOS, and Linux can host Flutter development. Android Studio must have
the Android SDK command-line tools, platform tools, API 36 platform, build tools,
and at least one API 24-or-newer device target. Accept Android SDK licenses with
`flutter doctor --android-licenses`.

A physical Android device or hardware-accelerated emulator is required for
integration tests. Stockfish ABI verification later requires at least an
`arm64-v8a` physical device and an `x86_64` emulator when that ABI is shipped.

Development storage and memory figures will be published only after the complete
SDK, emulator, engine sources, and build caches are measured. Until then, follow
the current Flutter and Android Studio installation guidance rather than relying
on an unsupported project-specific estimate.

## Current workstation evidence

| Component | Observed result |
| --- | --- |
| Operating system | Windows workspace |
| Flutter | Not found on `PATH` or common local SDK paths |
| Dart | Not found on `PATH` or common local SDK paths |
| Android Studio | Installed |
| Android SDK | Present at `C:\Users\dell\AppData\Local\Android\Sdk` |
| Installed Android platforms | API 36, 36.1, and 37.1 |
| Java on `PATH` | 1.8.0_501; unsuitable for this build |
| Android Studio JBR | OpenJDK 21.0.10; suitable for compiling the Java 17 target |
| Node.js | 24.14.0 |
| npm | 11.18.0 |
| Git | 2.55.0.windows.3 |

These observations are not a project compatibility certification. Run
`flutter doctor -v` after installing Flutter and selecting JDK 17.

## End-user baseline

- Android 7.0 (API 24) or newer is the current source-level minimum.
- No account is required.
- All planned modes except friend matches are offline-first.
- Friend matches require an Internet connection to a configured temporary relay.
- Sound is optional; the game remains usable with audio disabled.
- Exact installed size, peak RAM, and engine requirements are not yet measured.
  They must be recorded from release-profile builds before beta publication.
