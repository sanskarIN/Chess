# Riverpod

`flutter_riverpod` 3.3.2 supplies dependency injection and observable application
state. The root `ProviderScope` owns environment configuration, the local
database abstraction, and the privacy-safe logger.

Features depend on repository interfaces exposed by providers, never global
mutable singletons. Provider overrides make unit/widget tests deterministic.
Experimental Riverpod persistence and mutation APIs are not used.
