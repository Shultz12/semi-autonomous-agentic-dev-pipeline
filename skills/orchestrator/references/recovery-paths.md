# Recovery Paths

Error and exception handling for the orchestrator core loop. Read this file when the developer returns a non-COMPLETED status, when COMPLETED includes deviations, or when a PARTIAL chain triggers continuation logic.

After handling any recovery path, update the orchestrator state file.

## Applicability

These recovery paths apply to both implementation developers and test-writer developers. When handling a test-writer's non-COMPLETED output:
- Use `test_write_attempts` counter instead of `impl_attempts`
- Use "Test quality limit reached" escalation instead of "Code quality limit reached"
- Test-writer BLOCKED with `blocking-cause: handoff-insufficient` targets the test plan handoff, not the implementation handoff
- All other logic is identical

## NOTIFY Deviations

When developer returns COMPLETED with `Has Deviations: true`:

1. Spawn plan-architect (`subagent_type: "plan-architect"`):
   ```
   Mode: update
   Target: deviation
   Plan Path: [path to plan]
   Completed Phase: [N]: [phase-name]
   Developer Report: [developer report path]
     → Read `## Deviation Report` section
   ```
2. Extract from plan-architect message: `Status`, `Routing`, `Change-Level`, `Target-Phase`, `Changelog`.
3. Route based on plan-architect's return:

   | Routing | Action |
   |---------|--------|
   | PROCEED_NEXT | Proceed to Step D (code review) for implementation developer, or code-reviewer (TEST_REVIEW) for test-writer |
   | RETRY_PHASE | Completed phase has gaps — re-dispatch developer for `Target-Phase` with `Plan Revised: true` (the plan was updated by the deviation reconciliation) and the updated plan → Step B |

4. If plan-architect returns `Status: ERROR` → escalate to user.

For `PROCEED_NEXT`: the current phase is not re-read — deviations were already applied by the developer.

## PARTIAL

Extract `Reason` and `Residual Artifact` from developer output. Route per the continuation matrix.

```
partial_continuations += 1
if partial_continuations >= 3 → ESCALATE ("Plan miscalibration suspected in Phase [N] — too many PARTIAL continuations")
```

| `Reason` | Action |
|---|---|
| `turn-limit-approached` | Spawn continuation developer (same Developer Type) with brief pointing at the residual-artifact contents. The continuation reads the residual artifact to learn what's left. → Step C on the continuation's return. |
| `scope-larger-than-estimated` | Same as `turn-limit-approached`, subject to the escalation rule above. |
| `partial-build-failure` | Spawn continuation developer focused on the build stragglers enumerated in the residual artifact. → Step C on return. |
| `transient-environment-issue` | Retry once (continuation developer with the same task set). If the second attempt also returns PARTIAL with `transient-environment-issue`, treat as BLOCKED and present to user. The retry counts against `partial_continuations`. |

Continuation developer dispatch shape:
```
Developer Type: [same as the originating developer]
Cycle: <cycle-slug>
Phase: [N]: [phase-name]
Objective: [from plan header]
Handoff Path: [unchanged from originating dispatch]
Report Directory: <cycle-path>/execution/developer-reports/
Report Name: phase-[N]-implementation-report-continuation-[partial_continuations].md
Resume: true

Residual Artifact: [path supplied in PARTIAL return]
  → Read this file in full to learn what remains to be done.

Tasks:
[non-convention-doc subset of the current phase's tasks — the continuation reconciles against the residual artifact]
```

Update state file (sub-step: `implementation` for impl phases, `test-writing` for test phases).

## BLOCKED

Extract `Blocking Cause` from developer output and route accordingly.

### `handoff-insufficient`

The plan is correct, but the handoff lacks information from prior phases. Developer has committed partial work.

Context-blocked rebuilds do not increment `impl_attempts`. The subsequent developer re-spawn does.

```
if handoff_rebuilds >= 2 → ESCALATE to user
handoff_rebuilds += 1
```

Report: "Developer blocked (handoff insufficient), requesting handoff rebuild (rebuild [handoff_rebuilds]/2)"

Spawn state-manager (`subagent_type: "state-manager"`):
```
Mode: rebuild
Cycle: <cycle-slug>
Cycle Path: <cycle-path>
Target Phase: [N]
Developer Report: [developer report path]
  → Read `## Problem Report` section for context rebuild
Rebuild Attempt: [handoff_rebuilds]
```

- If SUCCESS: store enriched handoff path, re-spawn developer with `Resume: true` → Step B
- If ESCALATE: escalate to user

### `spec-ambiguous`

The phase's specs/plan tasks cannot be implemented as written because of ambiguity the developer cannot resolve. Present to user:

```
BLOCKED (spec-ambiguous) — Phase [N]: [phase name]
Developer report: [developer report path]

The developer cannot proceed without clarification on the spec or plan.
Please review the report and provide direction.
```

Wait for user input. Do not auto-recover.

### `dependency-missing`

Read the `dependency-status` field from the developer report frontmatter (frontmatter only) to distinguish two cases. An Approved-but-not-installed dependency never reaches this path — the developer installs it in the worktree and continues (per the charter dependency rule in the developer's dev-rules); only the cases below escalate.

**`dependency-status: not-approved`** — the developer needs a technology (named, or just the capability) that is not Approved in the Tech Stack Charter. The charter must be amended before work can resume. Present to user:

```
BLOCKED (dependency-missing — not approved in charter) — Phase [N]: [phase name]
Developer report: [developer report path]

The developer needs a technology that is not Approved in the Tech Stack Charter.
Run /tech-stack-architect unblock to evaluate options and amend the charter, then re-run.
```

**No `dependency-status` hint** — a required dependency (credential, service, generated artifact, upstream feature) is missing from the environment and must be resolved externally. Present to user:

```
BLOCKED (dependency-missing) — Phase [N]: [phase name]
Developer report: [developer report path]

The developer found a missing dependency that must be resolved externally.
Please review the report and resolve, then re-run.
```

Wait for user input in both cases. Do not auto-recover.

### `environment-broken`

The workspace itself is in an inconsistent state (broken install, missing tooling, corrupted state). Present to user:

```
BLOCKED (environment-broken) — Phase [N]: [phase name]
Developer report: [developer report path]

The workspace is in an inconsistent state that the developer cannot recover from.
Please review the report and repair the workspace, then re-run.
```

Wait for user input. Do not auto-recover.

## Plan-Architect ERROR — `TECH_NOT_IN_CHARTER`

When `plan-architect` returns `Status: ERROR` with `TECH_NOT_IN_CHARTER: <need>` (it can arise from any plan-authoring target — the authoritative list is in plan-architect's contract Errors table), it has written no plan: a required technology is not Approved in the Tech Stack Charter. Do not dispatch `plan-auditor` (there is no plan to audit) and do not retry plan-architect. Present to user:

```
BLOCKED (tech-not-in-charter) — <plan target>
Need: <need from error>
The plan cannot be authored because a required technology is not Approved in the Tech Stack Charter.
Run /tech-stack-architect unblock to evaluate options and update the charter, then re-run.
```

Wait for user input. Do not auto-recover.
