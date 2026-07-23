# Getting started

## 1. Install prerequisites

Install Git, Flutter 3.44.7 stable, Android Studio, Android SDK API 36, and JDK 17.
Keep Flutter on the stable channel. Confirm the setup:

```text
flutter --version
dart --version
flutter doctor -v
```

On Windows, select Android Studio's bundled JDK when a legacy Java installation
appears first on `PATH`.

## 2. Prepare generated project files

This foundation was authored on a machine without Flutter. Let the matching
Flutter SDK generate wrapper binaries and metadata:

```text
flutter create --platforms=android --org in.sanskar --project-name chess_master .
```

Before accepting generated changes, preserve the existing application ID,
network security config, backup exclusions, release shrinking, and launcher
resources under `android/`.

Do not commit `android/local.properties`; it contains a machine-specific SDK path.
Do commit the Gradle wrapper scripts and JAR produced by the trusted Flutter SDK.

## 3. Resolve and generate

```text
flutter pub get
flutter gen-l10n
```

`flutter pub get` creates `pubspec.lock`. Commit it because this is an application.
Generated localization Dart files remain ignored because they are reproducible
from reviewed ARB source.

## 4. Verify

```text
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

An Android debug build is not a release artifact. Release signing, policy,
license, security, accessibility, and device checks remain separate gates.

## 5. Run

Start an API 24-or-newer emulator or connect a device with USB debugging enabled:

```text
flutter devices
flutter run
```

Override the development display name without changing architecture:

```text
flutter run --dart-define=CHESS_MASTER_APP_NAME="KnightForge"
```
