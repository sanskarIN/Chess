# Chess-Master

Chess-Master is an in-progress, privacy-respecting, offline-first Android chess
game built with Flutter. The project is intended to become a complete
open-source game with standards-compliant chess rules, local and optional
self-hosted friend play, computer opponents, training, daily challenges, and
accessible multilingual interfaces.

**Open-source chess game**

**Made by the Sanskar**

> Development status: Phase 1 foundation source has been created. It has not
> yet been validated with Flutter on this machine because the Flutter and Dart
> SDKs are not installed. Chess play is not available in this build yet. See
> [feature status](docs/upcoming/feature_status.md) and the
> [continuation manifest](docs/development_manifest.md) for exact evidence.

## Privacy principles

- No account, login, analytics, advertising identifier, or behavioral tracking.
- Durable settings and game data stay in the application database on the device.
- Android cloud backup is disabled; explicit export/import will be user-controlled.
- Future friend matches will use a temporary WebSocket relay. That relay will
  necessarily process active session messages but will not permanently store games.
- Offline features must not wait for the multiplayer service during startup.

## Current foundation

- Configurable displayed app name with `Chess-Master` as the default.
- Material 3 light and dark themes with accessible target sizes.
- Typed GoRouter navigation.
- ARB-based localization generation with English as the fallback template.
- Riverpod dependency injection.
- Explicit success/failure values for expected application errors.
- Structured logging with redaction of names, addresses, tokens, and team codes.
- Versioned SQLite schema and atomic first-run creation.
- Privacy-safe Android manifest, local backup exclusions, and cleartext disabled
  outside debug builds.

## Technology baseline

The source targets Flutter 3.44.7 and Dart 3.12.x. These are the current stable
documentation baseline and compatible Dart line selected on 2026-07-23, not a
claim that this workstation ran them. The available machine currently has:

- Android Studio and an Android SDK
- Node.js 24.14.0
- npm 11.18.0
- Git 2.55.0.windows.3
- Java 8 on `PATH`, which is too old for this Android build; Android Studio's
  bundled OpenJDK 21 can compile the configured Java 17 target
- no Flutter or standalone Dart command on `PATH`

Use the JDK bundled with a current Android Studio or install JDK 17.

## Get started

1. Install Flutter 3.44.7 stable with its bundled Dart SDK.
2. Install Android Studio, Android SDK API 36, Android build tools, and JDK 17.
3. From the repository root, generate any missing platform wrapper files:

   ```powershell
   flutter create --platforms=android --org in.sanskar --project-name chess_master .
   ```

   Review generated changes before keeping them. The repository already contains
   intentional Android security and branding configuration.

4. Resolve packages and generated localizations:

   ```powershell
   flutter pub get
   flutter gen-l10n
   ```

5. Verify the project:

   ```powershell
   dart format --set-exit-if-changed .
   flutter analyze
   flutter test
   flutter build apk --debug
   ```

The generated `pubspec.lock` and Gradle wrapper files must be committed after
the first successful SDK-backed verification. Do not hand-author the wrapper JAR.

## Build-time configuration

The visible Flutter title can be changed without restructuring the application:

```powershell
flutter run --dart-define=CHESS_MASTER_APP_NAME="KnightForge"
```

Optional development values:

```text
CHESS_MASTER_ENVIRONMENT
CHESS_MASTER_RELAY_URL
```

No production relay URL is invented by default. A relay will only be configured
after the versioned protocol and self-hostable server exist.

The Android launcher label is in
`android/app/src/main/res/values/strings.xml`. Update it alongside the build-time
Flutter title when preparing a renamed distribution.

## Documentation

- [Documentation index](docs/index.md)
- [Architecture](docs/architecture.md)
- [System requirements](docs/system_requirements.md)
- [Database migrations](docs/database_migrations.md)
- [Localization](docs/localization.md)
- [Logging](docs/logging.md)
- [Roadmap phases](docs/upcoming/phases.md)
- [Exact next work](docs/upcoming/next.md)
- [Technology notes](docs/technologies/README.md)

The required `docs/users_suggest/`, expanded `docs/technologies/`, and
`docs/upcoming/` documentation sets are scheduled in the master phase order.
Files are added only when they contain substantive guidance.

## Repository and creator

- Repository: <https://www.github.com/sanskarIN/Chess>
- Creator: <https://www.github.com/sanskarIN>
- YouTube: <https://youtube.com/@Sanskar-in>
- LinkedIn: <https://www.linkedin.com/in/sanskarin>
- X: <https://www.x.com/Sanskar_in>
- Support: <mailto:supportramsandesh@gmail.com>
- Development contact: <mailto:sanskarin@outlook.in>

## License status

The intended project license is GNU GPL v3.0 or later because distributing
Stockfish in a future phase has GPL compatibility consequences. The complete
license, copyright notices, Stockfish source correspondence, and dependency
audit will be added and reviewed in Phase 11 before any binary distribution.
No Stockfish binary or source is included in the current foundation.

This repository is not ready for Play Store publication. Signing, legal review,
policy review, accessibility testing, localization review, device testing, and
release QA remain required.
