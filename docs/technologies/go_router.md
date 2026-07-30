# GoRouter

GoRouter provides declarative typed-path navigation. `AppRoutes` centralizes
paths while route builders validate required typed `extra` values and show a
localized error screen instead of unsafe casts.

Navigation must not carry secrets in URLs. Game setup and review launch values
are process-memory objects; durable resume data is loaded by repository ID.
Deep links are not represented as supported until Android intent filters,
validation, privacy, restoration, and tests exist.
