# Dart

The package requires Dart `>=3.12.0 <4.0.0`. Dart 3.12 is required by the selected
SQLite plugin version. The Dart SDK is supplied by Flutter and is not installed
separately for normal Flutter development.

The code uses sound null safety, sealed result/error types, exhaustive pattern
matching, strict casts, strict inference, and strict raw-type checking. Domain
code in Phase 2 will remain pure Dart so chess rules can run quickly in unit
tests without Flutter UI dependencies.

Dart 3.12.2 stable was installed on 2026-07-23. It formatted, executed, and
statically analyzed the complete pure-Dart chess domain. Flutter-dependent
analysis remains blocked until the Flutter SDK is installed.
