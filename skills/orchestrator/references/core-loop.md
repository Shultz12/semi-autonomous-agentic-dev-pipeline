# Core Loop

Read this file once per session, when beginning phase work. Do not re-read on subsequent phases — the loop is identical for every phase.

For the bugfix flow, see `references/bugfix-loop.md` — the same per-phase loop structure with a bugfix-specific Stage 0 / Stage 1 / Stage 2 prelude and a per-scenario step mapping for Stage 3.

For each phase, reset counters, path accumulators, and capture starting state:
```
impl_attempts = 0
test_write_attempts = 0
code_bug_fixes = 0
test_bug_fixes = 0
handoff_rebuilds = 0
partial_continuations = 0
phase_start_commit = git rev-parse HEAD
code_review_paths = []
test_review_paths = []
```

Also reset the state-file `Resumed:` flag to `false` (see `essentials/state-format.md`). A prior session may have set it `true` during intra-phase resume; the new phase's accumulators start fresh, so the next Step I summary is complete and unmarked.

Phase tracking (accumulate throughout the phase):
- `files_read` — list of (path, reason) for every file the orchestrator reads during this phase
- `bash_commands` — list of (command, reason) for every Bash command the orchestrator runs during this phase
- `agent_dispatches` — list of (agent, trigger, status, report_path) for every agent spawned
- `incidents` — list of (title, type, agent, detail, resolution) for anything abnormal
- `decisions` — list of (context, decision, outcome) for user decisions

Report: "Starting Phase [N]: [name]"

Before Step B, partition the current phase's tasks by `Concern:` field. If any task carries `Concern: convention-doc`, separate them from the non-convention-doc subset. Only the non-convention-doc subset goes to developer in Step B; the convention-doc subset is dispatched to state-manager's `refactor-curation` mode in Step I. If the phase contains ONLY `convention-doc` tasks, skip Steps B, D, F, G, H entirely — proceed directly to Step I and run only the `refactor-curation` dispatch followed by progress-tracker `update`.

## Step A: Read Current Phase

Read only the current phase section from the plan — tasks, `Developer:` type, `Depends on:`, verification, artifacts, and any phase-level flags (`abstract-migration-phase`). Do not read any other phase.

## Step B: Dispatch Developer

```
impl_attempts += 1
```

Spawn developer (`subagent_type: "developer"`):
```
Developer Type: [from phase's Developer: field]
Cycle: <cycle-slug>
Phase: [N]: [phase-name]
Objective: [from plan header]
Handoff Path: [from state-manager's previous output, or "none" for Phase 1]
Report Directory: <cycle-path>/execution/developer-reports/
Report Name: phase-[N]-implementation-report.md
Resume: [true only when re-spawning after interruption, false otherwise]

Tasks:
[non-convention-doc subset of the current phase's tasks]
```

For `Developer Type: test` dispatches (Step G), use `Report Name: phase-[N]-test-report.md`.

## Step C: Route Developer Output

Extract from developer message: `Status`, `Report`, `Has Deviations` (on COMPLETED), `Reason` (on PARTIAL), `Residual Artifact` (on PARTIAL), `Blocking Cause` (on BLOCKED).

| Status | Sub-fields | Route |
|--------|-----------|-------|
| COMPLETED, `Has Deviations: false` | — | → Step D |
| COMPLETED, `Has Deviations: true` | — | Read [recovery-paths.md](recovery-paths.md) § NOTIFY Deviations, then → Step D |
| PARTIAL | `Reason`, `Residual Artifact` | Read [recovery-paths.md](recovery-paths.md) § PARTIAL |
| BLOCKED | `Blocking Cause` | Read [recovery-paths.md](recovery-paths.md) § BLOCKED |

Store the developer report path. Update orchestrator state file (sub-step: `implementation`).

## Step D: Code Review

For phases without the `abstract-migration-phase` flag, dispatch `code-reviewer` with `Trigger: PHASE_REVIEW`. For phases with the flag, dispatch with `Trigger: ABSTRACT_MIGRATION_REVIEW`.

Spawn code-reviewer (`subagent_type: "code-reviewer"`):
```
Reviewer Type: [same Developer Type as this phase]
Cycle: <cycle-slug>
Phase: [N]: [phase-name]
Trigger: PHASE_REVIEW   (or ABSTRACT_MIGRATION_REVIEW)
Objective: [from plan header]
Review Output Directory: <cycle-path>/execution/code-reviews/
Review Attempt: [impl_attempts]
Prior Review Paths: [code_review_paths joined as list, or "none"]

Developer Report: [developer report path]

Phase Tasks:
[non-convention-doc subset of the current phase's tasks]
```

For `ABSTRACT_MIGRATION_REVIEW`, additionally pass the approved-findings path cited by the phase's inline annotation:
```
Approved Findings Path: .project/cycles/<refactor-slug>/refactor-proposals/pattern-approved.md
```

Append the code review path to `code_review_paths`. Update state file (sub-step: `implementation-review`).

## Step E: Route Code Review

Extract from code-reviewer message: `Verdict`, `Review File`, `Categories`, `Severity Counts`.

- **PASS** → proceed to Step F (or Step H for refactor/primitives post-curate flows; Steps F and G are skipped there).
- **FAIL** → consult [diagnostic-routing.md](diagnostic-routing.md) using the categories and severities present in the review:
  - If any finding is at `CRITICAL` severity, or if any category routes to "always diagnose": spawn `code-investigator` with `Trigger: CODE_REVIEW_FAILURE`; route the investigation verdict per [investigation-routing.md](investigation-routing.md).
  - Otherwise: re-dispatch developer (same Developer Type) with the code review path as input; loop back to Step C.

```
if impl_attempts > 3 → ESCALATE (see counters-and-escalation.md)
```

## Step F: Create and Validate Test Plan (standard feature flow only)

Skipped for refactor and primitives post-curate flows.

1. Dispatch `plan-architect`:
   ```
   Mode: create
   Target: test-plan
   Implementation Phase: <N>
   Cycle: <cycle-slug>
   Cycle Path: <cycle-path>
   ```

2. Dispatch `plan-auditor`:
   ```
   Plan Path: <cycle-path>/plans/test-plans/phase-<N>-test-plan.md
   Target: test-plan
   Mode: full-audit
   ```

3. If INVALID (cap at 3 total plan-auditor runs):
   - Dispatch `plan-architect` with `Mode: update, Target: test-plan, Implementation Phase: <N>` and the audit findings.
   - Re-dispatch `plan-auditor`.

Update state file (sub-step: `test-planning`, then `test-plan-validation`).

## Step G: Write Tests and Review (standard feature flow only)

Skipped for refactor and primitives post-curate flows.

```
test_write_attempts += 1
```

1. Dispatch `developer` with `Developer Type: test`. Inputs mirror Step B's dispatch, with `Tasks:` populated from the validated test plan.

2. Route output per Step C, using `test_write_attempts` in place of `impl_attempts` for counter checks (see recovery-paths.md § Applicability).

3. On COMPLETED, dispatch `code-reviewer` with `Trigger: TEST_REVIEW`. Route per Step E using TEST_REVIEW rules in diagnostic-routing.md.

Append test review paths to `test_review_paths`. Update state file (sub-step: `test-writing`, then `test-review`).

## Step H: Test Execution and Investigation

Dispatch `test-runner`:
```
Cycle: <cycle-slug>
Cycle Path: <cycle-path>
Phase: [N]
Mode: phase
Results Output Path: <cycle-path>/execution/test-results/phase-[N]-test-results.md
```

Update state file (sub-step: `test-execution`).

**ALL PASS** → proceed to Step I.

**FAIL** — every attribution is dispatched to code-investigator first. Per the attribution table in `.claude/agents/interface-contracts/test-runner.contract.md`, test-runner returns `Attribution: CODE_BUG | TEST_BUG | UNCLEAR` for each failing test. Dispatch `code-investigator` regardless of attribution:

```
Mode: investigation
Trigger: TEST_FAILURE
Phase: [N]
Cycle Path: <cycle-path>
Investigation Output Path: <cycle-path>/execution/code-investigations/phase-[N]-investigation-<attempt>.md
Investigation Attempt: <attempt number>
Minimum Depth: 0
Plan Path: <plan path>
Manifest Path: <cycle-path>/execution/manifest.md
Test Results Path: <cycle-path>/execution/test-results/phase-[N]-test-results.md
```

Update state file (sub-step: `investigation`). Route the investigation verdict per [investigation-routing.md](investigation-routing.md).

If code-investigator reclassifies the failure as a test-plan defect rather than test-code, dispatch `plan-architect` with `Mode: update, Target: test-plan, Implementation Phase: <N>` instead of dispatching developer.

## Step I: State Curation (additive dispatch)

Write the per-phase orchestration summary to `<cycle-path>/execution/orchestration-summaries/phase-[N]-orchestration-summary.md` per [orchestration-summary-format.md](orchestration-summary-format.md). The write must precede state-manager dispatch so the summary is on disk before state-manager curates the phase artifacts.

Before composing the summary, check the state-file `Resumed:` flag (see `essentials/state-format.md`). If `Resumed: true`, prepend the resume marker described in `orchestration-summary-format.md` above the Overview heading — the in-context phase-tracking accumulators are missing events from the prior session, and the marker tells future readers the data is partial. If `Resumed: false`, omit the marker.

After writing the orchestration-summary, commit it path-scoped via the `commit-to-git` skill (invoke it with the Skill tool), passing `Agent: orchestrator`, subject `orchestration(<slug>): phase <N> summary`, and the orchestration-summary path as the only path argument. The skill owns the path-scoped form that keeps unrelated staged work in the worktree's index out of the commit. The commit is idempotent under resume — `commit-to-git` reports `Commit: skipped` when the regenerated content matches HEAD rather than forcing an empty commit. Do not bundle other paths into this commit; state-manager commits its own outputs in its own commit.

Dispatch `state-manager` in `cycle-phase` mode — always, every phase:
```
Mode: cycle-phase
Cycle: <cycle-slug>
Cycle Path: <cycle-path>
Phase: [N]
Developer Report: [developer report path or "none" for convention-doc-only phases]
Code Reviews: [code_review_paths joined as list]
Test Reviews: [test_review_paths joined as list]
Test Results: [test results path]
Investigations: [investigation paths joined as list, or "none"]
Phase Start Commit: <phase_start_commit>
```

If the current phase contains ANY `Concern: convention-doc` task, ALSO dispatch `state-manager` in `refactor-curation` mode AFTER `cycle-phase` returns:
```
Mode: refactor-curation
Cycle: <cycle-slug>
Cycle Path: <cycle-path>
Phase: [N]
Tasks: [convention-doc subset of the current phase's tasks]
```

Update state file (sub-step: `state-curation`, then `convention-curation` if applicable).

**Last phase only:** after ALL state-manager dispatches for this phase have returned (both `cycle-phase` and, if applicable, `refactor-curation`), dispatch `state-manager` again in `cycle-close` mode:
```
Mode: cycle-close
Cycle: <cycle-slug>
Cycle Path: <cycle-path>
```

Capture the `Cycle Summary Path` returned by `cycle-close` for use in Feature Completion.

Then dispatch `progress-tracker update`:
```
Mode: update
Slug: <slug>
Field: current-phase
Value: [N completed]
Last Action: [brief description, e.g., "phase-[N] complete; tests passing"]
```

Update state file (sub-step: `progress-update`).

## Step J: Report to User

Present:
```
Phase [N] of [total]: [phase-name] — complete
Developer Type: [type]
Outcome: [completed | escalated]
Counters: impl_attempts=[N], test_write_attempts=[N], code_bug_fixes=[N], test_bug_fixes=[N], handoff_rebuilds=[N], partial_continuations=[N]
Reports: [paths]

Proceed to Phase [N+1]? [Yes / No]
```

If user declines, halt and remain at this position (state file already updated).

If this is the last phase, proceed to Feature Completion (skip Step K).

Update state file (sub-step: `awaiting-user`).

## Step K: Advance

Reset per-phase counters and tracking, set `Current Phase` to [N+1], return to Step A.
