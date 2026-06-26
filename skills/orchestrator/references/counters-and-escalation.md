# Counters and Escalation

## Counter Rules

All counters are per-phase, reset at the start of each phase.

**`impl_attempts`** — max 3 (1 original + up to 2 fixes). Beyond 3, the likely cause is a persistent plan or code problem requiring human judgment.
- Each developer spawn (standard or fix mode) increments by 1
- Context-rebuild itself does not increment (subsequent developer re-spawn does)

**`test_write_attempts`** — max 3 (1 original + up to 2 fixes). Same counting rules as `impl_attempts`.

**`code_bug_fixes`** — max 2. The first test-runner run that detects the bug is the detection, not a fix attempt. Each developer fix spawn after investigation increments by 1.

**`test_bug_fixes`** — max 2. Same as `code_bug_fixes` but for test-writer fix spawns.

**`handoff_rebuilds`** — max 2. Each state-manager rebuild invocation increments by 1.

**`partial_continuations`** — escalates when the count reaches 3 (up to 2 continuations spawned per phase). Tracks chained PARTIAL returns within a single phase. Three PARTIALs on the same phase suggests plan miscalibration.
- Each PARTIAL return increments by 1 before the continuation is spawned, so when the count reaches 3 the orchestrator escalates without spawning another continuation
- A retry triggered by `reason: transient-environment-issue` increments by 1 and is capped at 1 retry; subsequent PARTIAL on the same `transient-environment-issue` is treated as BLOCKED

When any limit is reached, escalate to user.

## Escalation Format

When escalating to the user:

```
ESCALATION — Phase [N]: [phase name]
Reason: [specific reason]
History:
  - Attempt 1: [what happened]
  - Attempt 2: [what happened]
  - ...
What I need from you: [specific question or decision needed]
```

## Escalation Types

| Escalation | Trigger | Message |
|------------|---------|---------|
| Implementation quality | `impl_attempts > 3` | "Code quality limit reached for Phase [N]" |
| Test quality | `test_write_attempts > 3` | "Test quality limit reached for Phase [N]" |
| Code bug unresolvable | `code_bug_fixes > 2` | "Test-detected code bug unresolvable in Phase [N]" |
| Test bug unresolvable | `test_bug_fixes > 2` | "Test-detected test bug unresolvable in Phase [N]" |
| Context rebuild | `handoff_rebuilds > 2` | "Context rebuild limit reached for Phase [N]" |
| Partial continuation | `partial_continuations >= 3` | "Plan miscalibration suspected in Phase [N] — too many PARTIAL continuations" |
| Attribution unclear | code-investigator can't resolve | "Test failure attribution unclear — needs human judgment" |
| Plan deviation | code-investigator LEVEL_3 | "Plan deviation detected — user decision required" |
| User intervention | code-investigator LEVEL_4 | "Architectural issue detected — user intervention required" |
| Plan update failed | plan-architect returns error | "Plan update failed — user decision required" |
| Plan audit failed | plan-auditor INVALID after retry | "Plan audit failed — user decision required" |
