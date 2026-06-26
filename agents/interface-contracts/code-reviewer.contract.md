# code-reviewer Interface Contract

## Input — PHASE_REVIEW

Standard post-implementation code review after developer reports SUCCESS.

**Required:**
```
Reviewer Type: backend | frontend | infrastructure
Cycle: [feature-name, e.g., notification-system]
Phase: [N]: [phase-name]
Trigger: PHASE_REVIEW
Objective: [ultimate goal from plan header]
Review Output Directory: [path to execution/code-reviews/]
Review Attempt: [N — from orchestrator's attempt counter]
Prior Review Paths: [list of prior review file paths for this phase, or "none"]

Developer Report: [path to developer report file]
  → Read `## Files Modified` section to determine review scope

Phase Tasks:
[original phase tasks for context]
```

`Review Attempt` is used only for the filename and the body header — it does not change the review workflow.

`Prior Review Paths` lists all previous review files for this phase. When provided, the reviewer reads them to understand what was already checked and to evaluate whether fixes are proper resolutions or bandaid patches.

**Optional:**
```
Investigation File: [path to a code-investigator investigation file]
  → Present only on bugfix-flow PHASE_REVIEW dispatches. When present, the reviewer adds a
    root-cause-fidelity check to its standard PHASE_REVIEW analysis: a change that masks or
    suppresses the symptom instead of addressing the investigated cause is a `CRITICAL × LOGIC`
    finding that fails the phase.
```

### Example Invocation

```
Reviewer Type: backend
Cycle: notification-system
Phase: 2: Implement notification delivery service
Trigger: PHASE_REVIEW
Objective: Send notifications via email and in-app channels
Review Output Directory: .project/cycles/15-03-2026-notification-system/execution/code-reviews/
Review Attempt: 1
Prior Review Paths: none

Developer Report: .project/cycles/15-03-2026-notification-system/execution/developer-reports/phase-2-implementation-report.md
  → Read `## Files Modified` section to determine review scope

Phase Tasks:
1. Create NotificationService with sendNotification() method
2. Register module in service layer
3. Add controller endpoint for notification dispatch
```

### Example Invocation (bugfix flow)

```
Reviewer Type: backend
Cycle: 19-04-2026-fix-hebrew-date-parse-crash
Phase: 1: Correct Hebrew date parsing
Trigger: PHASE_REVIEW
Objective: Restore correct Hebrew date parsing so valid dates no longer crash the parser
Review Output Directory: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/execution/code-reviews/
Review Attempt: 1
Prior Review Paths: none

Developer Report: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/execution/developer-reports/phase-1-implementation-report.md
  → Read `## Files Modified` section to determine review scope

Investigation File: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/execution/code-investigations/19-04-2026-10-30-investigation.md
  → Bugfix-flow only: check the fix against the documented root cause; masking or suppression is CRITICAL × LOGIC

Phase Tasks:
1. Correct the month-index off-by-one in the Hebrew date parser
```

### Example Invocation (Attempt 2)

```
Reviewer Type: backend
Cycle: notification-system
Phase: 2: Implement notification delivery service
Trigger: PHASE_REVIEW
Objective: Send notifications via email and in-app channels
Review Output Directory: .project/cycles/15-03-2026-notification-system/execution/code-reviews/
Review Attempt: 2
Prior Review Paths:
- .project/cycles/15-03-2026-notification-system/execution/code-reviews/phase-2-code-review-attempt-1.md

Developer Report: .project/cycles/15-03-2026-notification-system/execution/developer-reports/phase-2-implementation-report.md
  → Read `## Files Modified` section to determine review scope

Phase Tasks:
1. Create NotificationService with sendNotification() method
2. Register module in service layer
3. Add controller endpoint for notification dispatch
```

## Input — VERIFICATION_FAILURE

Diagnosing lint/build failure after developer's 2 fix attempts.

**Required:**
```
Reviewer Type: backend | frontend | infrastructure
Cycle: [feature-name, e.g., notification-system]
Phase: [N]: [phase-name]
Trigger: VERIFICATION_FAILURE
Objective: [ultimate goal from plan header]
Review Output Directory: [path to execution/code-reviews/]
Review Attempt: [N — from orchestrator's attempt counter]
Prior Review Paths: [list of prior review file paths for this phase, or "none"]

Developer Report: [path to developer report file]
  → Read `## Files Modified`, `## Fix Attempt Summary`, and `## Original Error Output` sections

Phase Tasks:
[original phase tasks for context]
```

### Example Invocation

```
Reviewer Type: backend
Cycle: notification-system
Phase: 2: Implement notification delivery service
Trigger: VERIFICATION_FAILURE
Objective: Send notifications via email and in-app channels
Review Output Directory: .project/cycles/15-03-2026-notification-system/execution/code-reviews/
Review Attempt: 2
Prior Review Paths:
- .project/cycles/15-03-2026-notification-system/execution/code-reviews/phase-2-code-review-attempt-1.md

Developer Report: .project/cycles/15-03-2026-notification-system/execution/developer-reports/phase-2-implementation-report.md
  → Read `## Files Modified`, `## Fix Attempt Summary`, and `## Original Error Output` sections

Phase Tasks:
1. Create NotificationService with sendNotification method
2. Register module in service layer
3. Add controller endpoint for notification dispatch
```

## Input — TEST_REVIEW

Review of test files written by the developer (test type).

**Required:**
```
Reviewer Type: test
Cycle: [feature-name, e.g., notification-system]
Phase: [N]: [phase-name]
Trigger: TEST_REVIEW
Objective: [ultimate goal from plan header]
Review Output Directory: [path to execution/code-reviews/]
Review Attempt: [N — from orchestrator's attempt counter]
Prior Review Paths: [list of prior test review file paths for this phase, or "none"]

Developer Report: [path to test developer report file]
  → Read `## Files Modified` section to determine review scope

Phase Tasks:
[test plan tasks for context]
```

### Example Invocation

```
Reviewer Type: test
Cycle: notification-system
Phase: 2: Implement notification delivery service
Trigger: TEST_REVIEW
Objective: Send notifications via email and in-app channels
Review Output Directory: .project/cycles/15-03-2026-notification-system/execution/code-reviews/
Review Attempt: 1
Prior Review Paths: none

Developer Report: .project/cycles/15-03-2026-notification-system/execution/developer-reports/phase-2-test-report.md
  → Read `## Files Modified` section to determine review scope

Phase Tasks:
1. Write unit tests for NotificationService.sendNotification()
2. Write controller tests for dispatch endpoint
3. Cover error paths from BDD scenarios
```

## Input — CYCLE_REVIEW

Cross-phase feature-wide review after all phases are complete. Code-reviewer reads the feature summary to discover all files and phase details.

**Required:**
```
Reviewer Types: [list: backend, frontend, infrastructure, test — all types involved]
Cycle: [feature-name, e.g., notification-system]
Trigger: CYCLE_REVIEW
Objective: [ultimate goal from plan header]
Review Output Directory: [path to execution/code-reviews/]
Review Attempt: [N — from orchestrator's attempt counter]
Prior Review Paths: [list of prior feature review file paths, or "none"]
Cycle Summary Path: [path to cycle-summary.md]
```

Code-reviewer reads the feature summary to extract per-phase file lists, developer types, and artifact details. This keeps the orchestrator lean — it passes the path, not the data.

### Example Invocation

```
Reviewer Types: backend, frontend
Cycle: Notification delivery pipeline
Trigger: CYCLE_REVIEW
Objective: Send notifications via email and in-app channels
Review Output Directory: .project/cycles/15-03-2026-notification-system/execution/code-reviews/
Review Attempt: 1
Prior Review Paths: none
Cycle Summary Path: .project/cycles/15-03-2026-notification-system/execution/state/cycle-summary.md
```

## Input — INTEGRATION_VERIFICATION

Structural integration check after all phases are complete. Verifies artifacts exist, are substantive, and are wired into the system. Code-reviewer derives its own verification checklist from the plan and feature summary.

**Required:**
```
Reviewer Types: [list: backend, frontend, infrastructure — all types involved]
Cycle: [feature-name, e.g., notification-system]
Trigger: INTEGRATION_VERIFICATION
Objective: [ultimate goal from plan header]
Review Output Directory: [path to execution/code-reviews/]
Review Attempt: [N — from orchestrator's attempt counter]
Prior Review Paths: [list of prior integration verification file paths, or "none"]
Plan Path: [path to implementation-plan.md]
Cycle Summary Path: [path to cycle-summary.md]
```

Code-reviewer reads the plan's phase artifacts sections to derive requirements (what should exist), and reads the feature summary to get the complete file list (what was created/modified). This replaces explicit Requirements and file lists in the input — code-reviewer extracts both from source.

### Example Invocation

```
Reviewer Types: backend, frontend
Cycle: Notification delivery pipeline
Trigger: INTEGRATION_VERIFICATION
Objective: Send notifications via email and in-app channels
Review Output Directory: .project/cycles/15-03-2026-notification-system/execution/code-reviews/
Review Attempt: 1
Prior Review Paths: none
Plan Path: .project/cycles/15-03-2026-notification-system/plans/implementation-plan.md
Cycle Summary Path: .project/cycles/15-03-2026-notification-system/execution/state/cycle-summary.md
```

## Input — ABSTRACT_MIGRATION_REVIEW

Review of a phase carrying the `abstract-migration-phase` flag (emitted by `plan-architect` for refactor plans whose source is an approved `pattern-analyst` finding with `directive: ABSTRACT`).

**Required:**
```
Reviewer Types: [list of types whose code is touched by the migration — typically backend, frontend, or both]
Cycle: [feature-name, e.g., refactor-from-notification-system]
Phase: [N]: [phase-name]
Trigger: ABSTRACT_MIGRATION_REVIEW
Objective: [ultimate goal from plan header]
Review Output Directory: [path to execution/code-reviews/]
Review Attempt: [N — from orchestrator's attempt counter]
Prior Review Paths: [list of prior abstract-migration review file paths for this phase, or "none"]

Developer Report: [path to developer report file]
  → Read `## Files Modified` (authored T1/T2/T5 files) and `## Artifacts Produced` (T3 codemod modified-file count)

Approved Pattern Finding Path: [path to .project/cycles/<slug>/refactor-proposals/pattern-approved.md]
  → Read `generalized-signature`, `call-site-data` totals, and `stragglers` list

Phase Tasks:
[original phase tasks for context — should include T1 through T5]
```

### Example Invocation

```
Reviewer Types: backend
Cycle: refactor-from-notification-system
Phase: 3: Migrate sendNotification signature
Trigger: ABSTRACT_MIGRATION_REVIEW
Objective: Generalize sendNotification() to accept a channel-agnostic recipient object
Review Output Directory: .project/cycles/20-05-2026-refactor-from-notification-system/execution/code-reviews/
Review Attempt: 1
Prior Review Paths: none

Developer Report: .project/cycles/20-05-2026-refactor-from-notification-system/execution/developer-reports/phase-3-implementation-report.md
  → Read `## Files Modified` (authored T1/T2/T5 files) and `## Artifacts Produced` (T3 codemod modified-file count)

Approved Pattern Finding Path: .project/cycles/20-05-2026-refactor-from-notification-system/refactor-proposals/pattern-approved.md
  → Read `generalized-signature`, `call-site-data` totals, and `stragglers` list

Phase Tasks:
T1: Rewrite signature in notification.service.ts
T2: Author codemod at .project/cycles/20-05-2026-refactor-from-notification-system/codemods/migrate-send-notification.ts + tests
T3: Run codemod against codebase
T4: Run npm run build
T5: Manual cleanup of stragglers (only if T4 captured failures)
```

## Output

The code-reviewer constructs a filename from the trigger type, phase number, and attempt number, writes the review file to `Review Output Directory`, and returns a structured message. The review file is the source of truth for downstream agents (developer fix mode, state-manager, quality-analyst, knowledge-curator); the message provides routing data for the orchestrator.

### Naming Convention

| Trigger | Filename |
|---------|----------|
| PHASE_REVIEW, VERIFICATION_FAILURE | `phase-[N]-code-review-attempt-[K].md` |
| TEST_REVIEW | `phase-[N]-test-review-attempt-[K].md` |
| CYCLE_REVIEW | `cycle-review.md` |
| INTEGRATION_VERIFICATION | `integration-verification.md` |
| ABSTRACT_MIGRATION_REVIEW | `phase-[N]-abstract-migration-review-attempt-[K].md` |

Where [N] is the phase number and [K] is the `Review Attempt` value.

**Overwrite on existing path:** If a file already exists at the constructed path, the agent overwrites it. The orchestrator owns the `Review Attempt` counter — same K means same invocation (interrupted-commit recovery), and the resulting content is deterministic. The path-scoped commit reports `skipped` when the overwrite produced no diff against HEAD.

### Review File Format

Every review file starts with YAML frontmatter containing the fields the orchestrator needs for routing. The body contains checks performed and findings detail for downstream agents.

**YAML Frontmatter:**

```yaml
---
verdict: PASS | FAIL
trigger: PHASE_REVIEW | VERIFICATION_FAILURE | TEST_REVIEW | CYCLE_REVIEW | INTEGRATION_VERIFICATION | ABSTRACT_MIGRATION_REVIEW
phase: [N]
cycle: <slug>
attempt: [K]
highest-severity: CRITICAL | ERROR | WARNING (only if FAIL)
categories: [LOGIC, CONVENTION, ...] (only if FAIL)
finding-count: [N] (only if FAIL)
---
```

For CYCLE_REVIEW and INTEGRATION_VERIFICATION, `phase` is omitted.

**Per-Finding Block Format (standard modes):**

```markdown
## Finding: <id>
Severity: CRITICAL | ERROR | WARNING
Confidence: HIGH | MEDIUM
Category: LOGIC | VALIDATION | INTEGRATION | TYPE | SECURITY | CONVENTION
File: <path>:<line>
Issue: <one-sentence problem>
Recommended fix: <one sentence>
Suggested knowledge source: <path or "none">
```

`<id>` is `F1`, `F2`, … ordered by severity (CRITICAL first).

**Per-Finding Block Format (ABSTRACT_MIGRATION_REVIEW — adds `Task:`):**

```markdown
## Finding: <id>
Severity: CRITICAL | ERROR | WARNING
Confidence: HIGH | MEDIUM
Category: LOGIC | VALIDATION | INTEGRATION | TYPE | SECURITY | CONVENTION
Task: T1 | T2 | T2-tests | T5 | call-site-fail
File: <path>:<line>
Issue: <one-sentence problem>
Recommended fix: <one sentence>
Suggested knowledge source: <path or "none">
```

**Per-Finding Block Format (INTEGRATION_VERIFICATION — uses Evidence in place of File-with-line; categories differ):**

```markdown
## Finding: <id>
Severity: CRITICAL | ERROR | WARNING
Confidence: HIGH | MEDIUM
Category: MISSING | STUB | UNWIRED
File: <path>
Issue: <one-sentence problem>
Evidence: <Glob/Read/Grep result citation>
Recommended fix: <one sentence>
Suggested knowledge source: <path or "none">
```

**Review file body (PASS):**
```markdown
# Phase [N] [Code|Test|Abstract-Migration] Review — [Phase Name]

## Attempt [K] — PASS
**Reviewer Type(s):** [backend | frontend | infrastructure | test | comma-separated list]
**Files Reviewed:**
- [file-path]

### Checks Performed
- [Category]: [what was verified] ✓

All checks passed.
```

**Review file body (FAIL, standard modes):**
```markdown
# Phase [N] [Code|Test|Abstract-Migration] Review — [Phase Name]

## Attempt [K] — FAIL
**Reviewer Type(s):** [backend | frontend | infrastructure | test | comma-separated list]
**Files Reviewed:**
- [file-path]

### Checks Passed
- [Category]: [what was verified] ✓

### Root Cause
[1-2 sentences: source of the failure]

### Findings

## Finding: F1
[per-finding block per template above]

## Finding: F2
...

### Verification
- [commands to run after fixes are applied]
```

**Review file body (FAIL, INTEGRATION_VERIFICATION):**
```markdown
# Feature [Code] Review — [Feature Name]

## Attempt [K] — FAIL
**Reviewer Types:** [backend, frontend, ...]

### Integration Summary
- **Exists:** [count] | **Missing:** [count]
- **Substantive:** [count] | **Stub:** [count]
- **Wired:** [count] | **Unwired:** [count]

### Checks Passed
- [Category]: [what was verified] ✓

### Findings

## Finding: F1
[per-finding block per INTEGRATION_VERIFICATION template above]

### Verification
- [steps to re-verify after fixes]
```

Use "Code Review" in the title for PHASE_REVIEW, VERIFICATION_FAILURE, and CYCLE_REVIEW triggers. Use "Test Review" for TEST_REVIEW. Use "Abstract-Migration Review" for ABSTRACT_MIGRATION_REVIEW. For CYCLE_REVIEW and INTEGRATION_VERIFICATION, omit the phase number from the title.

### Message to Orchestrator

**PASS (all triggers):**
```
Verdict: PASS
Commit: [short-hash | skipped | failed]
Review File: [full path to written file]
Summary: Reviewed [N] files. Checks passed: [brief list of categories/areas verified].
```

**FAIL (all triggers):**
```
Verdict: FAIL
Commit: [short-hash | skipped | failed]
Highest Severity: CRITICAL | ERROR | WARNING
Categories: [comma-separated list]
Finding Count: [N]
Review File: [full path to written file]
Summary: Reviewed [N] files. [X] checks passed, [Y] issues found.
```

`Commit:` semantics:

| Value | Meaning |
|---|---|
| `<short-hash>` | The review file was written and successfully committed path-scoped to the worktree. |
| `skipped` | The overwrite produced no diff against HEAD (a re-dispatch reproduced byte-identical content). No commit was made — the prior commit's content is the source of truth. |
| `failed` | The commit step failed (lock contention, hook rejection, transient error). The review file exists on disk and can be committed manually. The orchestrator must not re-dispatch on `failed` — the file is written, so a re-dispatch would loop on the same commit failure. |
| `none` | Not applicable in this agent — the completion gate guarantees a review file is written on every invocation. Listed only for PC.A4 enumeration completeness. |

The orchestrator uses the presence of `Commit:` in the return as the interrupted-commit recovery signal: if the return is missing or `Commit:` is absent, the same invocation is re-dispatched. Idempotent overwrite in the write step guarantees the re-dispatch reaches the same outcome.

### Trigger Definitions

- `VERIFICATION_FAILURE` — Diagnosing lint/build failure after developer's 2 attempts
- `PHASE_REVIEW` — Standard post-implementation code review
- `TEST_REVIEW` — Review of test files written by developer (test type)
- `CYCLE_REVIEW` — Cross-phase feature-wide review after all phases complete
- `INTEGRATION_VERIFICATION` — Structural integration check after all phases complete
- `ABSTRACT_MIGRATION_REVIEW` — Review of a phase carrying the `abstract-migration-phase` flag (signature change, codemod, codemod tests, manual stragglers)

### Severity Definitions

- `CRITICAL` — Security, correctness, or data-integrity defect that blocks merge
- `ERROR` — Significant defect; must fix before phase passes
- `WARNING` — Quality issue; should fix but doesn't block

Severity and Category are **independent axes**: any (severity × category) combination is valid.

### Issue Categories (PHASE_REVIEW, VERIFICATION_FAILURE, TEST_REVIEW, CYCLE_REVIEW, ABSTRACT_MIGRATION_REVIEW)

- `LOGIC` — Algorithmic, control-flow, or business-rule defect
- `VALIDATION` — Input validation, invariants, guard clauses
- `INTEGRATION` — Wiring across modules, contract mismatches, missing call-site updates
- `TYPE` — Type safety, casts, generic misuse
- `SECURITY` — Auth, authorization, input sanitization, secret handling, multi-tenant scoping
- `CONVENTION` — Violation of a documented convention

### Integration Categories (INTEGRATION_VERIFICATION only)

- `MISSING` — Artifact file does not exist on disk
- `STUB` — Artifact exists but contains placeholder/stub implementation
- `UNWIRED` — Artifact exists and is substantive but not connected to the system

### `Suggested knowledge source` field

Required on every finding. Path of the file (from the reviewer's actual read set) that documents the violated rule, or `none` when no convention file applies. Path is grounded — speculation is forbidden. Downstream consumer is `knowledge-curator`, which uses this field to attribute findings to convention sources.

## Guarantees

- Reads project context (`.project/knowledge/architecture.md`, `overview.md`, `sitemap.md`) before every review
- Reads the per-Reviewer-Type `_index.md` (multi-dimensional for `test` per the developer's Section 10 read protocol) before every review
- Reads universal review rules and the persona-specific review file(s) for the Reviewer Type(s) before every review
- For `ABSTRACT_MIGRATION_REVIEW`, additionally reads `modes/abstract-migration-review.md` and the approved `pattern-analyst` finding cited by the phase
- Runs diagnostic commands independently (lint/build/type-check)
- Every finding backed by tool output (Grep results, lint errors, code evidence)
- Every finding carries one severity (CRITICAL | ERROR | WARNING) and one category from the appropriate closed set (Severity × Category are independent axes)
- Every finding carries a `Suggested knowledge source` field; the path is grounded in the reviewer's actual read set, never invented
- Fix instructions are exact (file, line, specific instruction)
- Issues ordered by severity: CRITICAL first, then ERROR, then WARNING
- Constructs review filename from trigger, phase, and attempt number; writes to `Review Output Directory`
- Overwrites if the constructed filename already exists; the orchestrator owns `Review Attempt` uniqueness and a same-K dispatch is an interrupted-commit re-dispatch whose deterministic output is safe to overwrite
- Reports checks performed in both PASS and FAIL reviews
- Reads prior review files when `Prior Review Paths` are provided to evaluate fix quality
- Never modifies source code — diagnoses and prescribes only
- Never asks the user directly — all communication goes through orchestrator
- CYCLE_REVIEW reads feature summary to extract per-phase file lists and developer types
- CYCLE_REVIEW loads all relevant type files and runs diagnostics for all involved types
- INTEGRATION_VERIFICATION reads the plan to derive requirements and the feature summary to get file lists
- INTEGRATION_VERIFICATION checks 3 levels: existence, substantiveness, wiring
- INTEGRATION_VERIFICATION findings are backed by Glob/Read/Grep evidence
- INTEGRATION_VERIFICATION does NOT run lint/build
- INTEGRATION_VERIFICATION does NOT test behavior — it verifies structural integration only
- ABSTRACT_MIGRATION_REVIEW verifies the codemod's modified-file count against the cited approved finding's `call-site-data` totals; mismatch in either direction is `CRITICAL × INTEGRATION` and fails the phase
- ABSTRACT_MIGRATION_REVIEW skips per-call-site review unless T2 codemod tests fail; on failure, narrows review to failing files
- A bugfix-flow `PHASE_REVIEW` carrying `Investigation File:` adds a root-cause-fidelity check to standard PHASE_REVIEW analysis; a symptom-masking or suppression fix (e.g., a blanket `@ts-ignore`, a swallowing `catch`, a NULL check hiding a wrong default) is `CRITICAL × LOGIC` and fails the phase
- Commits **only** its own review file — path-scoped, via the `commit-to-git` skill with `Agent: code-reviewer`, after the review file is written and before returning. Subject form: `review(<slug>): phase <N> <trigger> attempt <K>` (per-phase triggers) or `review(<slug>): <trigger> attempt <K>` (feature-wide triggers). Never stages or commits source code, other agents' artifacts, `ROADMAP.md`, or anything under `.project/product/`. This is the sole exception to its otherwise diagnose-and-prescribe-only write surface
- The return message contains the structured routing fields: `Verdict`, `Commit`, `Review File`, `Summary`, and if FAIL: `Highest Severity`, `Categories`, `Finding Count`
