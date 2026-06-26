# State-Manager Guide

## What It Does

The State-Manager distills raw phase outputs into structured, curated artifacts so the orchestrator stays lean and future developers get exactly the context they need. It also curates project-level convention files under `.project/knowledge/<type>/**`. It runs entirely inside the worktree where it was invoked, commits the artifacts it just wrote path-scoped (worktree-side, no `-C <main-root>`), and returns a `Commit:` field on every invocation — every artifact reaches main exclusively via `/accept-feature`'s atomic merge. It does not touch ROADMAP, the per-feature tracking file, or any milestone state — those belong to `progress-tracker` and `milestone-archivist`.

**Model:** Claude Sonnet

**Key Points:**
- Four modes — `cycle-phase`, `cycle-close`, `rebuild`, `refactor-curation`
- Produces phase summaries, an execution-index, handoffs, and a feature summary on close
- Writes project-level convention files when invoked in `refactor-curation` mode
- Worktree-side writes and worktree-side commits — never targets main, pushes, or runs `git -C <main-root> ...`
- Commits own artifacts in one path-scoped commit per mode invocation via the `commit-to-git` skill
- Returns a `Commit:` field so the caller can detect interrupted commits and re-dispatch
- Stateless — spawned fresh each invocation, reads what it needs, produces artifacts, commits, exits
- Handoffs are always built from source (phase summaries + execution-index), never copied from previous handoffs

## When It Runs

Spawned by the orchestrator after each successful phase, after the last phase's per-phase work completes, when a developer reports `BLOCKED: handoff-insufficient`, or when convention-doc tasks must be processed. Also spawned directly by the user to execute the project-level items in an approved knowledge-cleanup proposal.

```
orchestrator
  FOR EACH PHASE:
    developer → implements phase
        ↓
    code-reviewer → validates code
        ↓
    test pipeline → plan, write, execute, investigate
        ↓
    [state-manager cycle-phase] → writes phase summary + execution-index entry + handoff
        ↓
    if phase has Concern: convention-doc tasks:
        [state-manager refactor-curation] → writes convention files + _index.md updates
        ↓
    orchestrator → progress-tracker update (records phase on main)
        ↓
    next phase (developer receives handoff)

  AFTER LAST PHASE'S PER-PHASE WORK COMPLETES:
    [state-manager cycle-close] → writes cycle-summary.md
        ↓
    progress-tracker ship → flips ROADMAP to completed-pending-approval
        ↓
    user → /accept-feature
        ↓
    accept-feature → atomic merge of the worktree into main
        ↓
    progress-tracker close (feature + possibly milestone)
        ↓
    if milestone completed → accept-feature → quality-analyst → milestone-archivist
```

State-manager exits the picture once the last phase's per-phase artifacts and the feature summary are written.

## Four Modes

| Mode | Trigger | Purpose |
|------|---------|---------|
| **cycle-phase** | Every phase, after the full per-phase pipeline completes | Write phase summary, append execution-index entry, generate handoff for next phase (or `Handoff: none` on last phase) |
| **cycle-close** | After all per-phase state-manager dispatches for the last phase have returned, before `/accept-feature` | Write `cycle-summary.md` consolidating all phases |
| **rebuild** | Developer reports `BLOCKED: handoff-insufficient` | Enrich handoff with missing context, sourced from phase summaries |
| **refactor-curation** | Phase contains `Concern: convention-doc` tasks, OR user dispatches with an approved knowledge-cleanup proposal | Author convention files; update `_index.md` rows; execute approved cleanup items (project-level only) |

`cycle-phase` and `refactor-curation` are additive — both run in a phase that mixes code work and convention-doc work, processing disjoint output domains.

## What It Produces

### Per-Phase Artifacts (cycle-phase mode)

| Artifact | Path | Lifecycle |
|----------|------|-----------|
| Phase summary | `execution/state/phase-summaries/phase-N-summary.md` | Write-once, never modified |
| Failed phase summary | `execution/state/phase-summaries/phase-N-failed-summary.md` | Write-once, re-execution only |
| Execution index | `execution/state/execution-index.md` | Append-only across phases (replacement entry on re-execution preserves history) |
| Handoff | `execution/state/handoffs-to-developer/handoff.md` | Regenerated each phase; skipped on last phase |
| Handoff archive | `execution/state/handoffs-to-developer/archive/phase-N-handoff.md` | Previous handoff preserved before overwrite |

All per-phase paths are relative to `.project/cycles/<cycle>/`.

### Feature Completion (cycle-close mode)

| Artifact | Path | Purpose |
|----------|------|---------|
| Feature summary | `execution/state/cycle-summary.md` | Consolidated record with testing statistics; consumed later by `milestone-archivist` for the milestone CHANGELOG |

### Convention Domain (refactor-curation mode)

| Artifact | Path | Lifecycle |
|----------|------|-----------|
| Convention file | `.project/knowledge/<type>/<feature-slug>/<convention>.md` (feature-local) or `.project/knowledge/<type>/<convention>.md` (top-level) | Authored per the `context-curation` skill; carries `created-during: <feature-slug>` frontmatter |
| Index row | `.project/knowledge/<type>/_index.md` | Added/refined when a convention is added, promoted, or has its trigger phrase updated |
| Rebuild archive | `execution/state/handoffs-to-developer/archive/phase-N-rebuild-M-handoff.md` | (rebuild mode) Previous handoff preserved before enrichment |

### What State-Manager Does Not Do

- Does NOT write `.project/product/ROADMAP.md` or any file under `.project/product/cycles-in-progress/` — those belong to `progress-tracker`.
- Does NOT commit to main, push, or run any `git -C <main-root> ...` command. Every commit is worktree-side; artifacts reach main exclusively via `/accept-feature`'s atomic merge.
- Does NOT write user-level files under `.claude/`.
- Does NOT stage or commit files it did not write this invocation — the path-scoped commit names only the artifacts produced.

## Commit Behavior

Each mode finishes with one path-scoped commit that names every path it just wrote. The commit form, attribution trailer (`Agent: state-manager`), and worktree-side variant come from the `commit-to-git` skill — state-manager Reads that skill at its commit step (progressive disclosure) and follows it. The commit covers the full file set produced by the invocation:

| Mode | Files committed in one commit | Commit subject |
|---|---|---|
| `cycle-phase` (intermediate) | phase summary, execution-index, current handoff, archived previous handoff (rename) | `state(<slug>): phase <N> summary` |
| `cycle-phase` (last phase) | phase summary, execution-index | `state(<slug>): phase <N> summary` |
| `cycle-phase` (re-execution) | phase summary, failed-phase summary, execution-index, current handoff, archived previous handoff | `state(<slug>): phase <N> summary` |
| `cycle-close` | cycle-summary.md | `state(<slug>): feature close` |
| `rebuild` | current handoff, archived previous handoff (rename) | `state(<slug>): phase <N> rebuild <M>` |
| `refactor-curation` Variant A | every convention file + every `_index.md` touched | `state(<slug>): phase <N> curation` |
| `refactor-curation` Variant B | every project-level item's target file + every `_index.md` touched | `state: curation proposal <date>` |

For handoff archive operations (the `mv` of the previous `handoff.md`), both source and destination paths appear in the commit so git records the rename atomically as one commit — never a half-rename across two commits.

### `Commit:` field semantics

Every return carries a `Commit:` field. The caller (orchestrator or user) uses it as the interrupted-commit recovery signal.

| Value | Meaning |
|---|---|
| `<short-hash>` | Artifacts written and successfully committed path-scoped to the worktree. |
| `skipped` | Write produced no diff against HEAD — a re-dispatch reproduced byte-identical content. No commit was made. |
| `failed` | The commit step failed (lock contention, hook rejection, transient error). Files exist on disk and can be committed manually. The caller must NOT re-dispatch on `failed`. |
| `none` | No write occurred this invocation (ESCALATE before any write, or rebuild-attempt-limit-exceeded). |

## Interrupted-Commit Recovery

If a dispatch ends before state-manager commits — process killed, max-turns hit, hook-blocked stop, transient error — the caller's return either has no `Commit:` field or the dispatch produced no return at all. The caller re-dispatches the same invocation. State-manager handles recovery transparently:

1. At the start of each mode (after reading inputs), it normalizes every target file in the invocation's deterministic file set to a known HEAD state — `git checkout HEAD -- <path>` if tracked at HEAD (discards uncommitted leftover), `rm -f <path>` if untracked (orphan from crashed prior write), no-op if absent.
2. The re-dispatched attempt then re-runs every write and commits in one path-scoped commit.
3. If the re-write reproduces byte-identical content (no diff against HEAD), `commit-to-git` reports `Commit: skipped` — no empty commit is forced.

The caller does NOT re-dispatch on `Commit: failed` (the files are written; a re-dispatch would loop on the same failure).

## Understanding Handoffs

Handoffs are the core value of `cycle-phase` and `rebuild` modes. They are curated context packages for the next developer.

**Residual-only content rule.** A fact appears in the handoff only if the next developer cannot get it from any of:

(a) the plan task,
(b) the actual files in the worktree,
(c) the next developer's persona,
(d) a skill referenced by the next developer,
(e) memory.

**What's typically included:**
- Artifacts from prior phases that the next phase depends on (based on plan's `depends_on`)
- Plan corrections (the actual correct approach, not what the plan originally said)
- Dependencies installed in prior phases

**What's excluded:**
- Code review findings (mistakes caught and fixed)
- Attempt counts, rebuild counts, testing statistics
- Dead ends and failed approaches

**Built from source.** Handoffs are always built from source (phase summaries + execution-index), never by rewriting a previous handoff. Files under `state/handoffs-to-developer/archive/` are forensic records for `quality-analyst` and human retrospective — they are never read as input to a new handoff.

## Rebuild Mode

When a developer reports `BLOCKED: handoff-insufficient`:

1. The orchestrator re-invokes state-manager in `rebuild` mode with the developer's complaint
2. State-manager finds the missing information in the relevant phase summaries
3. A new, enriched handoff replaces the current one; the old one is archived as `phase-N-rebuild-M-handoff.md`
4. Maximum 2 rebuilds per phase. On attempt 3+, state-manager returns `Status: ESCALATE` with `Reason: rebuild-attempt-limit-exceeded` — the root cause is plan or spec, not handoff.

## Refactor-Curation Mode

`refactor-curation` mode loads the `context-curation` skill on-demand at mode entry (Read of `.claude/skills/context-curation/SKILL.md`) and applies its authoring discipline.

**Two input variants:**

- **Per-phase (Variant A)** — dispatched by the orchestrator additively with `cycle-phase` whenever a phase contains at least one `Concern: convention-doc` task. Processes only the convention-doc tasks of that phase. Non-convention tasks are handled by the developer in the same phase.

- **Proposal (Variant B)** — dispatched by the user with an approved knowledge-cleanup proposal at `.project/pipeline/knowledge-cleanup-proposals/<YYYY-MM-DD>-knowledge-cleanup-proposal-run-<K>.md`. Processes only items in the proposal's `## Project-level items` section; ignores `## User-level items` (those are routed separately by the user, typically to `agent-architect`'s `promote-skill` or `update-knowledge-map` modes).

**Destruction discipline.** Removals are permitted ONLY when (a) the input is an approved knowledge-cleanup proposal, (b) the proposal item's category is `Remove`, and (c) the user has approved that specific item.

## Feature Status Lifecycle

State-manager does not flip ROADMAP status. The lifecycle below is owned by `progress-tracker`:

| Status | Set By | Meaning |
|--------|--------|---------|
| `planned` | `product-architect` | Entry created; no dispatch yet |
| `in-progress` | `progress-tracker start` | Worktree created, phases dispatching |
| `completed-pending-approval` | `progress-tracker ship` (after final phase update) | All phases done, awaiting acceptance |
| `completed` | `progress-tracker close` via `/accept-feature` | User approved |

## Execution Statistics

Phase summaries record strike counters and testing statistics as diagnostic metrics:

- **Implementation attempts** — Developer invocations before code review passed
- **Test-writing attempts** — Test-writer invocations before test review passed
- **CODE_BUG / TEST_BUG fixes** — Fix attempts after test-runner detected bugs
- **Handoff rebuilds** — Times the handoff was rebuilt due to BLOCKED developers

Feature summaries aggregate these across all phases, including which phases had re-executions, accepted failures, and investigation counts. Quality-analyst consumes these for retrospective analysis.

## Re-Execution

When a Level 3 investigation causes a plan revision and phase restart:

1. State-manager writes `phase-N-failed-summary.md` — records why the original attempt failed (sourced from the investigation file)
2. State-manager writes `phase-N-summary.md` — the canonical summary for the successful re-execution
3. The execution-index entry is replaced with an expanded format linking both summaries and tracking removed artifacts

The failed summary preserves lessons for `quality-analyst` without polluting the canonical summary that downstream agents consume.

## ESCALATE Conditions

State-manager returns `Status: ESCALATE` with a `Reason:` field in these cases:

| Mode | Reason | Meaning |
|------|--------|---------|
| `cycle-phase` | `phase-summary-write-failed` | Step 5 write failed; index untouched |
| `cycle-phase` | `execution-index-write-failed` | Step 6 write failed after summary succeeded; recoverable on retry |
| `rebuild` | `rebuild-attempt-limit-exceeded` | Attempt 3+ — root cause is plan/spec, not handoff |
| `refactor-curation` | (one-line reason) | Destruction-discipline precondition violation or similar |

## Limitations

- Does not read or analyze source code — works only with phase results, plan tasks, and convention proposals.
- Does not write ROADMAP, per-feature tracking files, or milestone archives — those are owned by `progress-tracker` and `milestone-archivist`.
- Does not modify the implementation plan.
- Cannot exceed 2 rebuild attempts — escalates to the orchestrator.
- Stateless — has no memory of prior invocations.
- Never writes user-level files under `.claude/`.

## Related Files

| File | Purpose |
|------|---------|
| `.claude/agents/state-manager/state-manager.md` | Base persona (mode router + cross-mode invariants) |
| `.claude/agents/state-manager/modes/cycle-phase.md` | Per-phase distillation workflow |
| `.claude/agents/state-manager/modes/cycle-close.md` | Last-phase rollup workflow |
| `.claude/agents/state-manager/modes/rebuild.md` | Handoff-rebuild workflow |
| `.claude/agents/state-manager/modes/refactor-curation.md` | Convention authoring/curation workflow |
| `.claude/agents/state-manager/essentials/templates.md` | Artifact templates |
| `.claude/agents/interface-contracts/state-manager.contract.md` | Interface contract |
| `.claude/skills/context-curation/SKILL.md` | Convention-file authoring discipline (loaded on-demand by `refactor-curation`) |
| `.claude/agents/progress-tracker/progress-tracker.md` | ROADMAP and tracking-file owner |
| `.claude/agents/milestone-archivist/milestone-archivist.md` | Consumes `cycle-summary.md` files when a milestone closes |
