# state-manager Interface Contract

state-manager runs in one of four modes selected by the `Mode:` field in the prompt: `cycle-phase`, `cycle-close`, `rebuild`, `refactor-curation`. All modes write only inside the worktree where they are invoked; no mode runs `git -C <main-root> ...` or any equivalent main-side action. Every commit is worktree-side; artifacts reach main exclusively via `/accept-feature`'s atomic merge. As the final step of each mode, state-manager commits the artifacts it just wrote path-scoped via the `commit-to-git` skill — one commit per invocation, naming every path written that invocation — and returns a `Commit:` field so the caller can detect interrupted commits and re-dispatch.

## Input — `cycle-phase` mode

Dispatched by the orchestrator after each phase completes the full pipeline (implementation, testing). Always dispatched, every phase.

**Required:**
```
Mode: cycle-phase
Cycle: [cycle-slug]
Cycle Path: [.project/cycles/<cycle>/]
Completed Phase: [N] of [total]
Plan Path: [path to implementation-plan.md]

Developer Report: [path to developer report file]
Code Reviews: [list of code review file paths, e.g. path/phase-N-code-review-attempt-1.md, path/phase-N-code-review-attempt-2.md]

Counters:
  Implementation Attempts: [N]
  Test Writing Attempts: [N]
  CODE_BUG Fixes: [N]
  TEST_BUG Fixes: [N]
  Handoff Rebuilds: [N]

Test Artifact Paths:
  Test Plan: [cycle-path]/plans/test-plans/phase-[N]-test-plan.md
  Test Report: [path to test developer report]
    → Read `## Files Modified` section for test file paths
  Test Reviews: [list of test review file paths]
  Test Results: [cycle-path]/execution/test-results/phase-[N]-results.md
  Investigations: [list of investigation file paths, or "none"]
```

state-manager reads the developer report file to extract artifacts produced, files modified, deviations, and plan corrections. It reads all code-review files (across attempts) to extract findings for the phase summary — using the latest attempt's verdict as the canonical outcome.

**Re-Execution fields (present only when the phase was re-executed after Level 3 resolution):**
```
Re-Execution: true
Investigation Path: [path to Level 3 investigation file that caused re-execution]
```

### Example Invocation (cycle-phase mode)

```
Mode: cycle-phase
Cycle: document-upload
Cycle Path: .project/cycles/15-03-2026-document-upload/
Completed Phase: 2 of 4
Plan Path: .project/cycles/15-03-2026-document-upload/plans/implementation-plan.md

Developer Report: .project/cycles/15-03-2026-document-upload/execution/developer-reports/phase-2-implementation-report.md
Code Reviews:
  - .project/cycles/15-03-2026-document-upload/execution/code-reviews/phase-2-code-review-attempt-1.md

Counters:
  Implementation Attempts: 1
  Test Writing Attempts: 1
  CODE_BUG Fixes: 0
  TEST_BUG Fixes: 0
  Handoff Rebuilds: 0

Test Artifact Paths:
  Test Plan: .project/cycles/15-03-2026-document-upload/plans/test-plans/phase-2-test-plan.md
  Test Report: .project/cycles/15-03-2026-document-upload/execution/developer-reports/phase-2-test-report.md
    → Read `## Files Modified` section for test file paths
  Test Reviews:
    - .project/cycles/15-03-2026-document-upload/execution/code-reviews/phase-2-test-review-attempt-1.md
  Test Results: .project/cycles/15-03-2026-document-upload/execution/test-results/phase-2-results.md
  Investigations: none
```

## Input — `cycle-close` mode

Dispatched by the orchestrator once per feature, after ALL per-phase state-manager dispatches for the last phase have returned (both `cycle-phase` and, when applicable, `refactor-curation`) and before `/accept-feature` runs.

**Required:**
```
Mode: cycle-close
Cycle: [cycle-slug]
Cycle Path: [.project/cycles/<cycle>/]
Total Phases: [N]
Plan Path: [path to implementation-plan.md]
Cycle Review Path: [path to .project/cycles/<cycle>/execution/code-reviews/cycle-review.md, or "none"]
```

### Example Invocation (cycle-close mode)

```
Mode: cycle-close
Cycle: document-upload
Cycle Path: .project/cycles/15-03-2026-document-upload/
Total Phases: 4
Plan Path: .project/cycles/15-03-2026-document-upload/plans/implementation-plan.md
Cycle Review Path: .project/cycles/15-03-2026-document-upload/execution/code-reviews/cycle-review.md
```

## Input — `rebuild` mode

Dispatched by the orchestrator when a developer reports `BLOCKED: handoff-insufficient`.

**Required:**
```
Mode: rebuild
Cycle: [cycle-slug]
Cycle Path: [.project/cycles/<cycle>/]
Target Phase: [N — the phase the developer is trying to execute]
Developer Report: [path to developer report]
  → Read `## Problem Report` section for context rebuild
Rebuild Attempt: [1 or 2]
```

### Example Invocation (rebuild mode)

```
Mode: rebuild
Cycle: document-upload
Cycle Path: .project/cycles/15-03-2026-document-upload/
Target Phase: 3
Developer Report: .project/cycles/15-03-2026-document-upload/execution/developer-reports/phase-3-implementation-report.md
  → Read `## Problem Report` section for context rebuild
Rebuild Attempt: 1
```

## Input — `refactor-curation` mode

Dispatched by the orchestrator per-phase ADDITIVELY with `cycle-phase` whenever any task in the phase carries `Concern: convention-doc`. Also dispatched directly by the user to execute the project-level items in an approved knowledge-cleanup proposal. The two input variants are distinguished by which fields are present.

### Variant A — per-phase, orchestrator-dispatched

**Required:**
```
Mode: refactor-curation
Cycle: [cycle-slug]
Cycle Path: [.project/cycles/<cycle>/]
Phase: [N]
Plan Path: [path to implementation-plan.md]
```

### Variant B — approved knowledge-cleanup proposal, user-dispatched

**Required:**
```
Mode: refactor-curation
Proposal Path: .project/pipeline/knowledge-cleanup-proposals/[YYYY-MM-DD]-knowledge-cleanup-proposal-run-[K].md
```

### Example Invocations

```
Mode: refactor-curation
Cycle: pdf-extraction
Cycle Path: .project/cycles/19-04-2026-pdf-extraction/
Phase: 3
Plan Path: .project/cycles/19-04-2026-pdf-extraction/plans/implementation-plan.md
```

```
Mode: refactor-curation
Proposal Path: .project/pipeline/knowledge-cleanup-proposals/2026-05-19-knowledge-cleanup-proposal-run-1.md
```

## Output

state-manager writes its artifacts inside the worktree, commits them path-scoped, and returns a structured message. The artifacts are the source of truth for downstream consumers; the message provides routing data — including the commit signal — for the caller.

### Message — `cycle-phase` (intermediate phase)
```
Status: SUCCESS
Mode: cycle-phase
Summary: [path to phase summary]
Handoff: [path to handoff]
Commit: [short-hash | skipped | failed]
```

### Message — `cycle-phase` (last phase)
```
Status: SUCCESS
Mode: cycle-phase
Summary: [path to phase summary]
Handoff: none
Commit: [short-hash | skipped | failed]
```

### Message — `cycle-phase` (write failure)
```
Status: ESCALATE
Mode: cycle-phase
Reason: phase-summary-write-failed | execution-index-write-failed
Commit: none
```

### Message — `cycle-close`
```
Status: SUCCESS
Mode: cycle-close
Cycle Summary: [path to cycle-summary.md]
Commit: [short-hash | skipped | failed]
```

### Message — `rebuild` (success)
```
Status: SUCCESS
Mode: rebuild
Handoff: [path to enriched handoff]
Commit: [short-hash | skipped | failed]
```

### Message — `rebuild` (limit exceeded)
```
Status: ESCALATE
Mode: rebuild
Reason: rebuild-attempt-limit-exceeded
Commit: none
```

### Message — `refactor-curation` (Variant A)
```
Status: SUCCESS
Mode: refactor-curation
Variant: per-phase
Conventions Written: [count]
Index Updates: [count]
Files:
  - [path]
  - [path]
  ...
Commit: [short-hash | skipped | failed]
```

### Message — `refactor-curation` (Variant B)
```
Status: SUCCESS
Mode: refactor-curation
Variant: proposal
Proposal: [proposal path]
Items Processed: [count]
Files:
  - [path] — [action]
  - [path] — [action]
  ...
Commit: [short-hash | skipped | failed]
```

### Message — `refactor-curation` (failure)
```
Status: ESCALATE
Mode: refactor-curation
Reason: [one-line reason]
Commit: none
```

`Commit:` semantics (shared across all modes and message variants):

| Value | Meaning |
|---|---|
| `<short-hash>` | The artifacts were written and successfully committed path-scoped to the worktree. |
| `skipped` | The write produced no diff against HEAD (a re-dispatch reproduced byte-identical content). No commit was made — the prior commit's content is the source of truth. |
| `failed` | The commit step failed (lock contention, hook rejection, transient error). The artifacts exist on disk and can be committed manually. The caller must not re-dispatch on `failed` (the files are written, so a re-dispatch would loop on the same failure). |
| `none` | No write occurred this invocation (ESCALATE before any write, or rebuild-attempt-limit-exceeded). Nothing to commit. |

## Recovery

If the caller's dispatch returns without a `Commit:` field (process killed mid-run, max-turns hit, hook-blocked stop, no return at all), the caller re-dispatches the same invocation. state-manager normalizes each target file to a known starting state before writing — `git checkout HEAD -- <path>` if the file is tracked at HEAD (discards uncommitted changes from a crashed prior attempt), `rm -f <path>` if untracked (the orphan was never in the audit trail), or no-op if absent. The re-dispatched attempt then re-runs every write and commits. The caller does NOT re-dispatch on `Commit: failed` — the files are written and a re-dispatch would loop on the same failure.

For modes that use `mv` to archive a previous handoff (`cycle-phase`, `rebuild`), the path-scoped commit names both the source path (the prior `state/handoffs-to-developer/handoff.md`, recorded as deleted from its old location) and the destination path (the new archive file) so git records the rename atomically as one commit — never a half-rename across two commits.

## Guarantees

- Every write lands inside the worktree where state-manager was invoked. No mode runs `git -C <main-root> ...` or any equivalent main-side action; every commit is worktree-side and artifacts reach main exclusively via `/accept-feature`.
- Reads developer reports and code-review files (across attempts) from paths provided in input — never receives inline data.
- Phase summaries are write-once outside the documented re-execution path — existing summaries are never overwritten except during re-execution after Level 3 resolution, where the canonical summary is replaced and the failed attempt is preserved via `phase-<N>-failed-summary.md`.
- Phase summaries include YAML frontmatter with routing fields for orchestrator fallback.
- The handoff carries YAML frontmatter above its `# Handoff` heading: `mode: handoff`, `phase`, `cycle`, `source-phase` (`initial` for the phase-1 handoff), `artifacts-count` / `plan-corrections-count` / `dependencies-listed-count` (row/entry counts of the corresponding sections), and `rebuild` (`false` for a `cycle-phase` handoff, the rebuild-attempt integer in `rebuild` mode). It never carries self-evaluation fields (`handoff-quality`, `completeness-score`, `is-sufficient`, `likely-to-trigger-rebuild`).
- The cycle-summary carries YAML frontmatter above its `# Cycle Summary` heading: `cycle`, `phases-completed`, `deviations.minor` / `deviations.major` (recorded plan corrections / deviations classified by the minor-vs-major definitions), `files-created-count`, `files-modified-count`, `total-test-count`. It never carries self-evaluation fields (`cycle-quality`, `would-ship`, `confidence-in-completion`); the human-readable `**Plan followed:**` line stays in the body.
- The execution-index is append-only for new phases — prior phase sections are never modified (except replacement during re-execution, which preserves history via the failed summary and re-execution entry format).
- Handoffs are always built from source (plan + execution-index + phase summaries), never from a previous handoff. Files under `state/handoffs-to-developer/archive/` are forensic-only and are never read as input to a new handoff.
- The previous handoff is archived via `mv` before a new one is generated. Archive filenames are `phase-<N>-handoff.md` (after `cycle-phase`) or `phase-<N>-rebuild-<M>-handoff.md` (after `rebuild`).
- Handoffs exclude code-review findings, attempt counts, rebuild counts, and testing statistics — only the residual content (facts the next developer cannot otherwise obtain) is included.
- ROADMAP and per-feature tracking files under `.project/product/` are never written by state-manager. On a merge conflict touching those paths, main's version is taken unconditionally.
- Feature completion produces a `cycle-summary.md` under the worktree but does not flip ROADMAP status — the `completed-pending-approval` transition happens later, on main.
- Maximum 2 rebuild attempts per phase — attempt 3+ returns `Status: ESCALATE`.
- Every file path referenced in handoffs has been verified to exist via Glob or Read.
- Re-execution produces both a failed summary (for retrospective analysis) and a normal summary (as the canonical record), with the execution-index entry linking both.
- Strike counter values from the orchestrator are recorded in phase summaries for quality-analyst consumption.
- The return message contains the structured routing fields: `Status`, `Mode`, mode-specific artifact paths, and a `Commit:` field on every invocation.
- `refactor-curation` mode processes only project-level items from an approved knowledge-cleanup proposal (never user-level items); deletes a convention file or `_index.md` row only when the input is an approved proposal, the item's category is `Remove`, and the user has approved that specific item.
- `refactor-curation` mode never writes user-level files (paths under `.claude/`).
- Normalizes each target file to HEAD state before writing — uncommitted content from a crashed prior dispatch is discarded so the re-dispatched invocation produces a clean result.
- Commits **only** its own artifacts — path-scoped, via the `commit-to-git` skill with `Agent: state-manager`, after all writes complete and before returning. Subject form per mode:
  - `cycle-phase` → `state(<slug>): phase <N> summary`
  - `cycle-close` → `state(<slug>): feature close`
  - `rebuild` → `state(<slug>): phase <N> rebuild <M>`
  - `refactor-curation` Variant A → `state(<slug>): phase <N> curation`
  - `refactor-curation` Variant B → `state: curation proposal <date>` (no `<slug>` — Variant B is feature-wide)
- One commit per mode invocation. The commit names every path written that invocation in a single path-scoped commit. For handoff archive `mv` operations, both source and destination paths appear in the commit so git records the rename atomically.
- Never stages or commits source code, test code, other agents' artifacts, `ROADMAP.md`, or anything under `.project/product/`.
