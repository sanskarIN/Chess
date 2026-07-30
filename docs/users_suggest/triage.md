# Suggestion triage

Each suggestion receives one factual state:

- `needs-information`: the problem or evidence is incomplete;
- `candidate`: plausible and awaiting design/priority;
- `accepted-for-design`: approved to produce a technical proposal, not code;
- `in-progress`: an owner and reviewed implementation plan exist;
- `blocked`: a named dependency or safety/legal issue prevents progress;
- `deferred`: valid but not scheduled;
- `declined`: outside scope or unacceptable tradeoffs;
- `completed`: merged, verified, documented, and correctly shown as available.

Review criteria, in order:

1. chess correctness and data integrity;
2. user safety, privacy, security, and licensing;
3. accessibility and localization;
4. offline behavior and failure recovery;
5. maintainability, testability, performance, and migration cost;
6. benefit relative to complexity and roadmap priority.

Maintainers should record rationale, duplicates, dependencies, acceptance
criteria, and the next decision point. Popularity alone does not override a
correctness, privacy, or licensing blocker.
