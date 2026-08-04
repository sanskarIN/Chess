# Repository structure

The completed source tree is organized by executable responsibility:

```text
.github/                 CI workflows, issue forms, and pull-request policy
android/                 Android host, manifests, resources, Gradle, and Kotlin bridge
assets/                  Engine manifest and original CC0 puzzle catalog
docs/                    Architecture, features, legal, translation, and release evidence
integration_test/        Android application smoke flow
lib/app/                 Application composition, routing, version, and configuration
lib/core/                Database, errors, logging, platform, theme, and shared widgets
lib/features/            Chess, computer, multiplayer, training, history, settings, and data
lib/l10n/                English source, 32 fallback ARBs, catalog, and review metadata
server/                  Optional memory-only TypeScript WebSocket relay
test/                    Unit, widget, SQLite, protocol, accessibility, and regression tests
tool/                    Deterministic generators and repository verifiers
```

Generated or machine-local files are intentionally untracked:

- `.dart_tool/` and generated `app_localizations*.dart` files;
- `build/`, Gradle caches, relay `node_modules/`, and compiled relay output;
- `android/local.properties` and machine-specific SDK paths;
- coverage output, APK/AAB artifacts, signing keys, passwords, and credentials.

The committed lockfiles, Gradle wrapper, localization source, SBOM generator,
and verification tools define the reproducible source boundary. The generated
CycloneDX source inventory is committed at
[`docs/release/source_sbom.json`](../docs/release/source_sbom.json).
