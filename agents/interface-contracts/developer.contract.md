# developer Interface Contract

## Input — Standard Mode

When developer receives a new phase to implement:

**Required:**
```
Developer Type: backend | frontend | infrastructure | test
Cycle: [feature-name, e.g., credit-system]
Phase: [N]: [phase-name]
Objective: [ultimate goal from plan header]
Handoff Path: [path to handoff.md, e.g., .project/cycles/.../execution/state/handoffs-to-developer/handoff.md, or "none" for Phase 1]
Report Directory: [path to developer-reports/, e.g., .project/cycles/08-02-2026-credit-system/execution/developer-reports/]
Report Name: [phase-{N}-implementation-report.md when Developer Type ∈ {backend, frontend, infrastructure}; phase-{N}-test-report.md when Developer Type is test]
Resume: true | false (optional, default false)
Reset To Commit: [commit hash] (optional — when present, reset codebase to this commit before starting)
Plan Revised: true (optional — when present, developer deletes any existing active report and sibling archive folder before implementing, ensuring downstream agents see only the fresh run)
Residual Artifact: [path] (optional — present on PARTIAL continuations; the prior PARTIAL return's `residual-artifact` path, round-tripped by the orchestrator so the continuation developer reads the truth source for remaining work)

Tasks:
[phase tasks from implementation plan or test plan]
```

**Developer Type note:** The orchestrator selects the Developer Type matching the phase's persona. Each value triggers a different read protocol (encoded in the developer persona at `.claude/agents/developer/developer.md`) — in particular, `test` is multi-dimensional and derives covered dev-types from each task's `Target file(s)` paths. The orchestrator does NOT include a per-task `targets` field; the read protocol routes via the developer's persona and knowledge map.

**Resume note:** Set `Resume: true` only when re-invoking after a previous interruption (crash recovery). Developer will check for existing artifacts and skip completed tasks. Distinct from PARTIAL continuation, which uses `Residual Artifact:` instead.

**Reset note:** Set `Reset To Commit` when the phase is being restarted after a plan revision (Level 3 investigation), a BLOCKED revert, or a verification revert. Developer performs a code-scoped revert: code returns to `[hash]` while committed `.project/**` artifacts (prior developer report, code-reviews, test-results, investigations) are preserved. `Resume` and `Reset To Commit` are mutually exclusive — reset implies a fresh start.

**Plan Revised note:** Set `Plan Revised: true` when re-dispatching after the plan has been modified since the prior invocation — BLOCKED `spec-ambiguous` fix, LEVEL_3 plan deviation resolution, or NOTIFY deviation RETRY_PHASE. The developer deletes the active report at `{Report Directory}/{Report Name}` and the sibling `{Report Name without .md}.runs/` archive folder before implementing. Prior run history is discarded because it reflects a superseded plan, and downstream consumers must see only the fresh run. `Plan Revised` composes with both `Reset To Commit` (the two cleanups run sequentially) and `Resume: true` (Plan Revised wipes the report; Resume operates on code artifacts via filesystem checks — they do not conflict).

**Residual Artifact note:** Set `Residual Artifact: <path>` on a PARTIAL continuation. The path is the `residual-artifact` value returned by the prior PARTIAL developer instance; the orchestrator round-trips it verbatim. The continuation developer reads the residual artifact as the authoritative source for remaining work (`Residual Artifact:` is read in Step 1 of the developer workflow). `Residual Artifact:` is mutually exclusive with `Reset To Commit` (continuation resumes from the prior savepoint, not a reset point); composes with `Plan Revised: true` only if the plan was revised mid-continuation (rare).

**`abstract-migration-phase` flag note:** Phases authored by `plan-architect` (`Target: refactor-plan`) for an approved ABSTRACT finding carry an `abstract-migration-phase` flag on the phase header along with an inline annotation citing the approved finding (e.g., `.project/cycles/<slug>/refactor-proposals/pattern-approved.md#CF-3`). When the `Tasks:` block reflects a flagged phase, the developer follows the T1–T5 ABSTRACT Migration Phase Task Spine documented in `.claude/agents/developer/developer.md` § ABSTRACT Migration Phase Task Spine. The orchestrator dispatches the developer with the phase tasks verbatim from the plan; no additional input field signals the flag — the persona detects it from the phase header annotation.

### Example — Standard Mode (backend)

```
Developer Type: backend
Cycle: credit-system
Phase: 2: Core Service Layer
Objective: Add credit-based document processing with organization-scoped access control
Handoff Path: .project/cycles/08-02-2026-credit-system/execution/state/handoffs-to-developer/handoff.md
Report Directory: .project/cycles/08-02-2026-credit-system/execution/developer-reports/
Report Name: phase-2-implementation-report.md

Tasks:
2.1: Create CreditService at backend/src/modules/credits/credit.service.ts
  Action: Implement deductCredits(), getBalance(), hasEnoughCredits()
  Target file(s): backend/src/modules/credits/credit.service.ts (to create)
  Reference: backend/src/modules/documents/document.service.ts:15-40
  Concern: persistence
  Wave: 1
  Verify: npm run build
```

### Example — Standard Mode (test)

```
Developer Type: test
Cycle: credit-system
Phase: 1: Core Service Tests
Objective: Add credit-based document processing with organization-scoped access control
Handoff Path: .project/cycles/08-02-2026-credit-system/execution/state/handoffs-to-developer/handoff.md
Report Directory: .project/cycles/08-02-2026-credit-system/execution/developer-reports/
Report Name: phase-1-test-report.md

Tasks:
1.1: Create CreditService unit tests
  Action: Create unit tests for deductCredits(), getBalance(), hasEnoughCredits()
  Target file(s): backend/src/modules/credits/credit.service.spec.ts (to create)
  Reference: backend/src/modules/credits/credit.service.ts:15-80
  Scenario: credit-system.feature:deduct credits on document processing
  Concern: test
  Wave: 1
  Verify: npx tsc --noEmit backend/src/modules/credits/credit.service.spec.ts
```

(The `test` Developer Type derives covered dev-types from each task's `Target file(s)` paths and reads only the corresponding `.project/knowledge/<derived-type>/_index.md` files — never pre-emptively all four.)

**Per-task assertion field (test).** Each test task carries exactly one assertion-contract field naming what the test must assert:
- `Scenario: <feature-file>:<scenario-name>` — feature tests; the assertion is anchored to a BDD Gherkin scenario the developer reads before writing the test.
- `Bug-Expectation: <one-sentence expected behavior>` — bugfix reproduction tests; a single declarative sentence drawn verbatim from the bug report's `## Expected Behavior`. The developer asserts it directly, with no BDD-file lookup.

### Example — Standard Mode (test — bugfix reproduction)

```
Developer Type: test
Cycle: 19-04-2026-fix-hebrew-date-parse-crash
Phase: 0: bugfix-reproduce
Objective: Restore correct Hebrew date parsing — see specs/bug-report.md
Handoff Path: none
Report Directory: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/execution/developer-reports/
Report Name: reproduction-test-report.md

Tasks:
1.1: Add a failing reproduction test for the Hebrew date parse crash
  Action: Write a test asserting the parser returns a valid Date for a Hebrew-locale input string
  Target file(s): backend/src/modules/dates/hebrew-date.parser.spec.ts (to create)
  Reference: backend/src/modules/dates/hebrew-date.parser.ts:30-55
  Bug-Expectation: Parsing a Hebrew-locale date string returns a valid Date instead of throwing.
  Concern: test
  Wave: 1
  Verify: npx tsc --noEmit backend/src/modules/dates/hebrew-date.parser.spec.ts
```

### Example — Standard Mode (PARTIAL continuation)

```
Developer Type: backend
Cycle: credit-system
Phase: 5: ABSTRACT migration — generalize add()
Objective: Generalize add() into compute(operator, a, b) per approved finding CF-3
Handoff Path: .project/cycles/08-02-2026-credit-system/execution/state/handoffs-to-developer/handoff.md
Report Directory: .project/cycles/08-02-2026-credit-system/execution/developer-reports/
Report Name: phase-5-implementation-report.md
Residual Artifact: .project/cycles/08-02-2026-credit-system/execution/2026-05-20-codemod-stragglers-credit-system.md

Tasks:
T5: Manual cleanup of stragglers (continuation)
  Action: Continue fixing stragglers per residual artifact
  Concern: transformation
```

## Input — Fix Mode (from code review)

When developer receives fix instructions after code-reviewer diagnosis:

**Required:**
```
Developer Type: backend | frontend | infrastructure | test
Cycle: [cycle-slug]
Phase: [N]: [phase-name]
Objective: [ultimate goal from plan header]
Handoff Path: [path]
Report Directory: [path]
Report Name: [phase-{N}-implementation-report.md or phase-{N}-test-report.md]

Tasks:
[phase tasks from implementation plan or test plan]

Code Review Path: [path to code-reviewer's review file]

Instruction: Apply fixes described in the code review, then re-run verification.
```

## Input — Fix Mode (from investigation)

When developer receives fix instructions after code-investigator diagnosis:

**Required:**
```
Developer Type: backend | frontend | infrastructure | test
Cycle: [cycle-slug]
Phase: [N]: [phase-name]
Objective: [ultimate goal from plan header]
Handoff Path: [path]
Report Directory: [path]
Report Name: [phase-{N}-implementation-report.md or phase-{N}-test-report.md]

Tasks:
[phase tasks from implementation plan or test plan]

Investigation File: [path to investigation file]

Instruction: Read the investigation file, apply the prescribed fixes, then re-run verification.
```

## Output

The developer writes a structured report file to the `Report Directory` before returning its message. The report file is the source of truth; the message provides routing data for the orchestrator.

### Report File Format

The active report at `{Report Directory}/{Report Name}` always contains a **single run** — the current invocation's state. Prior runs are preserved in a sibling archive folder (see Archive Folder Convention below), so downstream consumers reading the active path see only current state.

Every report file starts with YAML frontmatter containing the fields the orchestrator needs for routing. The body contains detail for downstream agents (code-reviewer, state-manager, code-investigator, plan-architect).

```
---
status: COMPLETED | PARTIAL | BLOCKED
commit: [hash or "none"]
report-type: implementation | test
phase: [N]
cycle: <slug>
blocking-cause: handoff-insufficient | spec-ambiguous | dependency-missing | environment-broken (only if BLOCKED)
dependency-status: not-approved (optional — only on a BLOCKED dependency-missing that is a charter Not-Approved case)
residual-artifact: [path] (only if PARTIAL)
reason: turn-limit-approached | scope-larger-than-estimated | partial-build-failure | transient-environment-issue (only if PARTIAL)
has-notify-deviations: true | false (only if COMPLETED)
---

# Phase [N] Developer Report — [phase-name]

## Artifacts Produced
| Artifact | Type | Location | Description |
|----------|------|----------|-------------|
| [name] | [Service/Component/etc] | [file-path] | [brief description] |

(or "None")

## Files Modified
- [path]

## Shared utilities

### Reused
- [path] — [one-line description of what was imported and from where]

(or "None")

### Created
- [path] — [signature]: [one-line description of the new shared utility]

(or "None")

## Implementation Reasoning

### Phase Interpretation
[1-3 sentences: what this phase needed to accomplish and why.
If the interpretation conflicted with codebase reality, state that.]

### Key Decisions
- [decision]: [rationale] — guided by: [source]
(2-6 items. Source labels: plan | handoff | persona | knowledge-map | context-index | base rules | project rules | codebase | codebase (not found) | code-review | investigation | approved-finding)

### Assumptions
- [what was assumed]: [why] — gap in: [source]
(or "None" — 0-3 items. Only things not explicitly stated that the developer inferred.)

## Deviations
| Tier | Description | Action Taken | Impact |
|------|-------------|--------------|--------|
| [1-3] | [what happened] | [what was done] | SILENT / NOTIFY |

(or "None")

## Deviation Report (only if NOTIFY deviations exist)
| Tier | What Changed | Old Reference | New Reference | Impact |
|------|-------------|---------------|---------------|--------|
| [tier] | [description] | [old or "(did not exist)"] | [new] | NOTIFY |

## Findings Addressed (only if input included Code Review Path or Investigation File)
| # | File | Issue | Resolution |
|---|------|-------|------------|
| [from source] | [file] | [original finding summary] | [what was done to fix it] |

## Resumed Tasks (only if Resume: true was set in input)
- [N.M]: [task name] — skipped (artifact verified at [path])
- [N.M]: [task name] — re-implemented (artifact missing/partial)

## Residual Work (only if PARTIAL)
Pointer to `[residual-artifact path]`. Summary of what remains:
- [short bullet enumeration of remaining tasks or files]

## Problem Report (only if BLOCKED)
[if blocking-cause is `spec-ambiguous`: Problem Report following the format defined in plan-architect contract, targeting the plan file]
[if blocking-cause is `handoff-insufficient`: description of what's missing from the handoff — artifact, phase, expected location]
[if blocking-cause is `dependency-missing`: missing package/credential/service and where it was expected]
[if blocking-cause is `environment-broken`: broken component, what was attempted, what failed; ORIGINAL error output if applicable]

## Tasks Completed
- [N.M]: [task name]
(or "None")

## Tasks Remaining (only if PARTIAL or BLOCKED)
- [N.M]: [task name]
```

### Archive Folder Convention

Before writing a new active report, the developer moves any existing active file to a sibling archive folder so downstream consumers never see stale runs in the active path. The archive location is:

`{Report Directory}/{Report Name without .md}.runs/run-{K}-{status}.md`

Where:
- `{K}` is the sequential archive index (1, 2, 3, ...), determined by counting existing archive files and adding 1.
- `{status}` is the prior run's status, read from the existing file's frontmatter before moving.

**Example archive folder after three runs (BLOCKED → PARTIAL → COMPLETED):**

```
execution/developer-reports/
├── phase-2-implementation-report.md              ← active, COMPLETED (current state)
└── phase-2-implementation-report.runs/
    ├── run-1-BLOCKED.md
    └── run-2-PARTIAL.md
```

The archive folder is created lazily — it exists only once there is at least one prior run.

The developer uses `mv` (not `cp`) to archive. If a subsequent write to the active path fails, the active path is empty and the SubagentStop hook blocks the return. This is intentional: silent staleness (where downstream agents read a superseded active file as if fresh) is strictly worse than a loud failure.

**Archive lifetime:** survives across developer invocations within a phase. Discarded only when the input includes `Plan Revised: true`, at which point the developer deletes both the active file and the entire archive folder before implementing — producing a clean slate for the fresh run on a revised plan.

### Fix Mode

When the input includes a Code Review Path or an Investigation File, the developer applies the prescribed fixes to the code and writes a fresh active report documenting the post-fix state. The existing active report (which described the pre-fix state) is archived following the Archive Folder Convention above.

The fresh active report includes the `## Findings Addressed` table identifying which findings from the review or investigation were fixed. Implementation Reasoning still applies — the developer captures decisions made while implementing the fixes, using `code-review` or `investigation` as source labels for `guided by:` attribution.

Every fix invocation follows the same archive-and-write pattern as any other re-invocation. The pre-fix context remains accessible via the archive folder for human review and quality analysis.

### Message to Orchestrator

The developer returns the structured output:

```
Status: COMPLETED | PARTIAL | BLOCKED
Commit: [hash | none | skipped | failed]
Report: [path to report file]
Has Notify Deviations: true | false (only on COMPLETED)
Residual Artifact: [path] (only on PARTIAL)
Reason: turn-limit-approached | scope-larger-than-estimated | partial-build-failure | transient-environment-issue (only on PARTIAL)
Blocking Cause: handoff-insufficient | spec-ambiguous | dependency-missing | environment-broken (only on BLOCKED)
```

### Status Definitions

| Status | When |
|--------|------|
| COMPLETED | Implementation complete, verification passed |
| PARTIAL | Some tasks satisfied; remaining work explicitly enumerated in the residual artifact; another developer instance can resume |
| BLOCKED | Cannot proceed without external action; no developer instance can make further progress without orchestrator-level routing |

### PARTIAL Reasons

| Reason | When |
|---|---|
| `turn-limit-approached` | Ran out of turns before completing all tasks; remaining work captured in residual artifact |
| `scope-larger-than-estimated` | Tasks proved larger than the plan estimated; remaining work captured |
| `partial-build-failure` | Verification failed after 2 fix attempts on first invocation for this phase; the cause appears transient or stragglers-bound, retry warranted |
| `transient-environment-issue` | Hit a flaky environment state (intermittent failure) that may resolve on retry |

### Blocking Cause Classification (BLOCKED only)

| Cause | When |
|---|---|
| `handoff-insufficient` | Plan is fine but handoff lacks needed artifacts from prior phases |
| `spec-ambiguous` | Plan/spec is wrong: broken references, ambiguity, contradictions, or self-conflict |
| `dependency-missing` | Environment lacks a required package, credential, or service the plan correctly assumed |
| `environment-broken` | Environment is in a broken state; includes the case of second 2-attempt verification fail on a PARTIAL continuation |

**Routing (orchestrator-side):**
- `handoff-insufficient` → orchestrator dispatches `state-manager rebuild`, then re-dispatches developer with the rebuilt handoff. Max 2 rebuilds per phase.
- `spec-ambiguous` → orchestrator presents revert/keep options to user, then routes to `plan-architect update` mode.
- `dependency-missing` → orchestrator surfaces to user; does not proceed. When the report frontmatter also carries `dependency-status: not-approved`, the orchestrator directs the user to `/tech-stack-architect unblock` (the needed technology is not Approved in the charter); otherwise the missing dependency is resolved externally.
- `environment-broken` → orchestrator surfaces to user; does not proceed.

The Problem Report format (for `spec-ambiguous`) is defined in the plan-architect interface contract at `.claude/agents/interface-contracts/plan-architect.contract.md`.

## Guarantees

- The active report at `{Report Directory}/{Report Name}` always reflects a single run — the current invocation's state — and exists BEFORE the developer returns its message
- Before writing a new active report, any existing active file is moved (not copied) to `{Report Name without .md}.runs/run-{K}-{status}.md` so prior runs survive re-invocation without polluting the active path
- The archive folder is created lazily and survives across developer invocations within a phase
- Fix invocations (Code Review Path or Investigation File present) follow the same archive-and-write pattern as any other re-invocation
- When `Plan Revised: true` is in the input, the developer deletes the active report file and the sibling archive folder before implementing
- `Plan Revised` composes with `Reset To Commit` (cleanups run sequentially) and `Resume: true` (Plan Revised wipes the report; Resume operates on code artifacts via filesystem checks)
- The Developer Type field selects a deterministic read protocol; for `test`, covered dev-types are derived per-task from `Target file(s)` paths and only the corresponding `.project/knowledge/<derived-type>/_index.md` files are read (never pre-emptively all four)
- Developer reads universal dev-rules, the per-type persona file, the per-type persona dev-rules, the per-type knowledge map, and the universal project context (architecture.md, overview.md, sitemap.md) before implementing
- Developer reads the handoff file (if provided) before implementing
- Developer reads the residual artifact (if `Residual Artifact:` is in input) before implementing; the artifact is the authoritative truth source for remaining work on PARTIAL continuation
- When `Reset To Commit` is present, developer performs a code-scoped revert: code returns to `[hash]` while committed `.project/**` artifacts (prior developer report, code-reviews, test-results, investigations) are preserved, so they survive `/accept-feature`'s `git merge --no-ff`
- `Resume` and `Reset To Commit` are mutually exclusive — reset implies a fresh start, resume implies continuing
- `Residual Artifact` and `Reset To Commit` are mutually exclusive — continuation resumes from the prior savepoint
- When `Investigation File` is present, developer reads the investigation file at the given path to obtain fix instructions
- All file paths referenced in the plan are verified before implementation starts
- Existing patterns/utilities are searched before creating new code
- The developer never runs the project's test suite; `test-runner` is the sole executor of tests across the pipeline
- The developer never re-runs `find-call-sites.ts` during ABSTRACT migration; the call-site enumeration is read from the approved `pattern-analyst` finding cited by the phase's inline annotation
- A savepoint commit is created after implementation, before verification
- Verification is run after every implementation (lint + build for non-test personas, compilation check for test persona)
- Fix attempts are never committed — only the savepoint commit exists
- Failed fix attempts are deterministically reverted via `git checkout -- .` and `git clean -fd`
- If a fix succeeds, `git commit --amend` folds the fix into the savepoint
- Max 2 fix attempts. On first invocation, a 2-attempt fail returns PARTIAL `partial-build-failure`; on a continuation invocation, a 2-attempt fail returns BLOCKED `environment-broken`
- Problem Reports for `spec-ambiguous` follow the standard format from plan-architect contract
- Developer never asks the user directly — all communication goes through orchestrator
- Developer classifies every deviation as SILENT or NOTIFY using deterministic criteria
- BLOCKED output includes `blocking-cause` (one of `handoff-insufficient | spec-ambiguous | dependency-missing | environment-broken`) for orchestrator routing
- On a BLOCKED `dependency-missing` caused by a technology not Approved in the Tech Stack Charter, the report frontmatter carries the optional `dependency-status: not-approved` hint; the orchestrator keys off it to route to `/tech-stack-architect unblock`. The developer never installs an un-Approved dependency, but installs an Approved-but-missing dependency in the worktree and continues without blocking
- PARTIAL output includes `residual-artifact: <path>` and `reason` (one of `turn-limit-approached | scope-larger-than-estimated | partial-build-failure | transient-environment-issue`)
- Before reporting PARTIAL, developer commits work-so-far + the residual artifact so a continuation developer can resume from a stable HEAD
- Before reporting BLOCKED, developer commits any completed work for clean git boundary
- When `Resume: true`, developer verifies artifact substance before skipping (not just file existence)
- Deviations table is always present in COMPLETED reports (contains "None" if no deviations)
- Implementation Reasoning section is present on all report statuses with source-attributed decisions and assumptions
- Test persona writes only test files — never modifies implementation code
- Test persona maps every test to its assertion contract — a BDD scenario via the `Scenario:` field for feature tests, or the bug report's expected behavior via the `Bug-Expectation:` field for bugfix reproduction tests
- The `## Shared utilities` section in the report enumerates reused and newly-created shared utilities so quality-analyst and knowledge-curator can detect reuse trends and drift
- The return message contains the structured routing fields: `Status`, `Commit`, `Report`, `Has Notify Deviations` (on COMPLETED), `Residual Artifact` + `Reason` (on PARTIAL), `Blocking Cause` (on BLOCKED)
- When `Plan Revised: true` removes previously-committed report files, developer commits the deletions via `commit-to-git` (`Agent: developer`, subject `chore: clear prior report after plan revision`) before implementing, so the worktree stays clean
- At the end of Step 9, developer commits the active report file via `commit-to-git` (`Agent: developer`, subject `report: Phase N - [phase name] (<status>)`), path-scoped to the active report path and — when the same invocation moved a prior run to the archive via `mv` — the archive path; naming both paths in one commit preserves rename atomicity
- The return message's `Commit` field is one of: the hash of the developer's final commit (typically the report commit), `none` if no commits were produced, `skipped` if the would-be commit was a no-op (content byte-identical to HEAD) per convention 0.3.7, or `failed` if a commit was attempted but `commit-to-git` returned an error; on `failed` or on a missing field (interrupted invocation), the orchestrator re-dispatches the same invocation
- For phases flagged `abstract-migration-phase`, developer follows the T1–T5 task spine documented in `.claude/agents/developer/developer.md` § ABSTRACT Migration Phase Task Spine; T5 cadence updates the codemod-stragglers residual artifact every 5 files
