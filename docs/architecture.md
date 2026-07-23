# Architecture

Chess-Master uses feature-first clean architecture. Dependencies point inward:

```text
presentation -> application -> domain
                     |
                     v
              repository interface
                     ^
                     |
                   data
```

The domain layer is pure Dart and must not import Flutter, platform plugins, or
storage implementations. Application services coordinate use cases through
typed repository interfaces. Data adapters implement those interfaces for
SQLite, engines, files, or WebSockets. Presentation code observes application
state through Riverpod and does not perform database or network calls directly.

## Foundation composition

`main.dart` delegates to `bootstrap.dart`. Bootstrap initializes Flutter,
configures the error boundary, attempts to open local storage, and injects
configuration, logging, and database dependencies into one `ProviderScope`.
Database failure is represented as a `StorageError`; the UI starts in a limited
state and displays recovery guidance instead of silently crashing.

`ChessMasterApp` owns the router for its lifecycle. Routes build feature
presentation widgets, including the local daily-challenge dashboard.

## Boundaries

- `lib/app/`: composition, configuration, routing, theme, version.
- `lib/core/`: cross-feature abstractions with no feature-specific behavior.
- `lib/features/<feature>/domain/`: immutable rules and repository contracts.
- `lib/features/<feature>/application/`: use cases and state transitions.
- `lib/features/<feature>/data/`: persistence, engine, and network adapters.
- `lib/features/<feature>/presentation/`: accessible Flutter UI.
- `lib/l10n/`: ARB source and generated localization output.

## Error policy

Expected outcomes use `Result<T>`, `Success<T>`, and `Failure<T>`. The failure
contains a structured `AppError` with a stable code and localization key.
Exceptions are reserved for programmer errors, corrupted invariants, or
unexpected platform failures and are translated at an adapter boundary.

Technical details may enter diagnostics but never become raw user-facing text.

## Privacy and networking

No startup path depends on the optional multiplayer relay. Durable data belongs
in the local database. The WebSocket adapter exchanges temporary room messages
only after explicit user action and validates every remote move against the same
local chess domain used by offline games. Daily rewards never contact the relay.
