# Exact next work

Phase 6 is complete with 92 passing Flutter tests, 7 passing relay-server tests,
zero Flutter analyzer issues, a passing TypeScript type check, zero reported
production npm vulnerabilities, a passing independent chess-domain verifier,
and a passing native-engine manifest verification.

Phase 7 starts with:

```text
lib/features/challenges/domain/daily_challenge.dart
```

Phase 7 implementation order:

1. deterministic local-date challenge generation and date simulation boundary;
2. persisted challenge progress, history, completion, and idempotent claiming;
3. atomic local coin/hint wallet and integrity-bearing transaction ledger;
4. successful-result-first hint purchase and generation coordination;
5. daily countdown, progress, claim, claimed, history, and limitation UI;
6. localized first-version source/target hint explanation and confirmation UI;
7. progress hooks for implemented game events without inventing unavailable
   practice, tutorial, save, or review outcomes;
8. database migration, transaction, date rollover, tamper-limit, UI, and
   duplicate-request tests;
9. economy, daily challenge, hint, privacy, and developer-tool documentation.

Before the Android debug build can complete, install Android SDK command-line
tools and repair the incomplete NDK `28.2.13676358` installation. Accept any
remaining SDK licenses through the official tool. Do not configure or use a
release signing key.
