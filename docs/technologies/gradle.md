# Gradle and Android builds

Gradle coordinates the Android plugin, Kotlin/Java compilation, resource
processing, dependency resolution, packaging, and variants beneath Flutter’s
build command.

The wrapper scripts and wrapper JAR are tool-generated and committed so builds
select a known Gradle version. A release record must capture Flutter, Dart,
Gradle, Android Gradle Plugin, JDK, SDK, build-tools, NDK, and dependency
versions. Dependency verification, repository restrictions, reproducible
inputs, and artifact hashes are supply-chain controls.

The current workstation’s missing Android command-line tools and incomplete NDK
are environment blockers. They must be repaired through official SDK tooling;
release signing is intentionally not configured.
