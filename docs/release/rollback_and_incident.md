# Rollback and incident response

## Stop conditions

Halt rollout for illegal chess moves, database corruption, repeated rewards,
privacy-policy mismatch, credential exposure, remote state divergence, startup
failure, signing/provenance mismatch, severe accessibility regression, or a
high-severity dependency/security issue.

## Response

1. Pause or halt the staged rollout.
2. Preserve the affected version, commit, artifact hash, logs, reproduction
   details, and environment without collecting unnecessary user data.
3. Classify security/privacy incidents through `SECURITY.md`; use public issues
   only for non-sensitive defects.
4. Disable or isolate an optional relay deployment when server behavior is the
   cause; offline play must remain available.
5. Prepare a forward-fix version. Android stores generally do not permit
   downgrading version codes, so a corrected build uses a higher code.
6. Rerun all source, artifact, policy, device, signing, and store gates.
7. Publish accurate release notes and support guidance.

## Data compatibility

Schema downgrade is unsupported. A fix must preserve or safely migrate local
settings, games, history, statistics reset markers, achievements, rewards,
challenges, tutorials, practice progress, and saves. Never instruct users to
erase local data unless no safer recovery exists and the consequence is clear.
