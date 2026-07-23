# Repository structure

The repository currently contains only substantive Phase 1 directories:

```text
android/                 Android host and privacy configuration
docs/                    Architecture, setup, technology, and status records
lib/app/                 Application composition
lib/core/                Errors, results, logging, and database foundation
lib/features/foundation/ Temporary factual status presentation
lib/l10n/                Localization source
test/                    Foundation unit and widget tests
```

Additional feature, asset, server, CI, integration-test, and documentation
directories will be added in the phase that implements their contents. This
follows the master prompt's instruction not to create meaningless empty
directories merely to resemble a target tree.

Generated files are intentionally absent until the Flutter toolchain runs:

- `pubspec.lock`
- `lib/l10n/app_localizations*.dart`
- `android/gradlew`
- `android/gradlew.bat`
- `android/gradle/wrapper/gradle-wrapper.jar`
- `android/local.properties` (local-only and never committed)
