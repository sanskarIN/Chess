# Dart

The package requires Dart `>=3.12.0 <4.0.0`. Dart 3.12 is required by the selected
SQLite plugin version. The Dart SDK is supplied by Flutter and is not installed
separately for normal Flutter development.

The code uses sound null safety, sealed result/error types, exhaustive pattern
matching, strict casts, strict inference, and strict raw-type checking. Domain
code in Phase 2 will remain pure Dart so chess rules can run quickly in unit
tests without Flutter UI dependencies.

The authoring machine did not have `dart` on `PATH`; formatting and analysis
remain blocked until the Flutter SDK is installed.
