# Exact next work

All 12 planned source phases are complete. There is no next implementation
phase or placeholder source file.

The next release work is external qualification against the current candidate:

1. run TalkBack, largest-text, display-size, theme, RTL, lifecycle, and input
   review on the documented physical-device matrix;
2. capture release-mode startup, frame, memory, CPU, battery, long-match,
   database-export, and relay-reconnect performance evidence;
3. replace the 32 English fallback locale packs only through qualified
   translation and independent native-speaker review;
4. obtain final human legal/privacy/store-policy approval;
5. configure developer-owned release signing outside the repository, build an
   AAB from an approved clean commit, inspect it, and record provenance;
6. complete the Play Console listing, data-safety declarations, pre-launch
   report, staged rollout, support ownership, and rollback readiness.

The source-level release record is maintained in:

```text
docs/release/release_status.json
```

No external gate may be converted to `passed` without its own evidence. No
keystore, signing password, service-account credential, or Play Console secret
may be added to this repository.
