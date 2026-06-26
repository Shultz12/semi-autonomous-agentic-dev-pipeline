# State-Manager Templates

Templates for all artifacts produced by state-manager. Read the relevant template before producing each artifact.

## Phase Summary Template

Path: `.project/cycles/<cycle>/execution/state/phase-summaries/phase-<N>-summary.md`

Write-once. Never modify after creation.

```markdown
---
status: SUCCESS
mode: cycle-phase
phase: [N]
cycle: <slug>
handoff-path: execution/state/handoffs-to-developer/handoff.md (or "none" for last phase)
cycle-summary-path: execution/state/cycle-summary.md (last phase only, omit otherwise)
---

# Phase [N] Summary — [Phase Name]

## Outcome
- **Status:** [completed | completed-with-deviations]
- **Plan tasks completed:** [N/M]
- **Implementation attempts:** [number — 1 original + N fixes]
- **Handoff rebuilds:** [number of times state-manager was re-invoked in rebuild mode for this phase's handoff]

## Files Created
| File | Purpose |
|------|---------|
| `path/to/file.ts` | [what it does] |

## Files Modified
| File | What Changed |
|------|-------------|
| `path/to/file.ts` | [description of change] |

## Exports Added
| Export | Location | Signature |
|--------|----------|-----------|
| `functionName` | `path/to/file.ts:line` | `(params) => ReturnType` |

## Schema Changes
[If any Prisma/DB changes — model names, fields added, relations. "None" if no schema changes.]

## Key Decisions
[Architectural or design choices made during implementation that weren't in the plan. These inform future phases.]
- [Decision]: [Rationale]

## Dependencies Installed
| Package | Why |
|---------|-----|
| `package-name` | [reason] |

[Or "None" if no new dependencies.]

## Plan Corrections
[Things done differently from the plan because the plan was wrong or incomplete. These represent the ACTUAL correct approach — included in handoffs for future phases.]
- [What the plan said] → [What was actually done]: [Why the plan was wrong]

[Or "None" if plan was followed exactly.]

## Code Review Findings
[Issues flagged by code-reviewer and how they were resolved. Recorded for retrospective analysis — NOT included in handoffs.]
- [Finding]: [Resolution]

[Or "None" if passed first review.]

## Testing
- **Test plan:** [path to test plan]
- **Tests created:** [count] files, [count] test cases
- **Test results:** [all pass | N failures]
- **Test-writing attempts:** [1 original + N fixes]
- **CODE_BUG fixes:** [N]
- **TEST_BUG fixes:** [N]
- **Accepted failures:** [N, with test names and reasons if any]
- **Investigations:** [N, with paths if any]
```

## Failed Phase Summary Template

Path: `.project/cycles/<cycle>/execution/state/phase-summaries/phase-<N>-failed-summary.md`

Write-once. Produced only during re-execution — records the failed attempt for retrospective analysis.

```markdown
# Phase [N] Failed Summary — [Phase Name]

## Outcome
- **Status:** failed — superseded by re-execution
- **Investigation:** [path to Level 3/4 investigation file]

## What Was Attempted
[Brief description sourced from the investigation file's root cause and context sections — what the implementation tried to do and how far it got before failure.]

## Why It Failed
[Root cause from the investigation file.]

## Resolution
[The chosen resolution from the investigation file — which option the user selected and why.]

## Failed Attempt Artifacts
[Paths to execution/ files from the failed attempt that were preserved, if any. "None" if all artifacts were from the re-execution only.]

## Lessons
[What quality-analyst can learn from this failure — extracted from the investigation's root cause and the gap between plan and reality.]
```

## Execution-Index Entry Template

Path: `.project/cycles/<cycle>/execution/state/execution-index.md`

Append-only. Each `cycle-phase` mode invocation appends its phase section. Create the file on Phase 1 with the header below.

**Header (Phase 1 only):**

```markdown
# Execution Index — [Feature Name]

Cumulative index of all phase outputs. Each section is appended by state-manager after a phase completes.
```

**Per-phase section (appended each time):**

```markdown
## Phase [N]: [Phase Name]
- **Files created:** [list with paths]
- **Files modified:** [list with paths]
- **Exports added:** [function/class signatures with locations]
- **Schema changes:** [if any, or "None"]
- **Dependencies installed:** [if any, or "None"]
- **Key decisions:** [architectural choices made]
- **Plan corrections:** [if any — what changed from the original plan, or "None"]
- **Test plan:** plans/test-plans/phase-[N]-test-plan.md
- **Test files:** [list of test file paths created by developer (Developer Type test)]
- **Test results:** execution/test-results/phase-[N]-results.md
- **Code reviews:** execution/code-reviews/phase-[N]-code-review-attempt-*.md
- **Test reviews:** execution/code-reviews/phase-[N]-test-review-attempt-*.md
- **Investigations:** [list of investigation file paths, or "None"]
```

## Re-Execution Execution-Index Entry Template

Replaces the original phase section when a phase is re-executed after a Level 3 investigation. The original section is removed and replaced with the expanded format below that preserves history.

```markdown
## Phase [N]: [Phase Name] (re-executed after plan revision)
**Original execution failed** — see execution/state/phase-summaries/phase-[N]-failed-summary.md
**Re-executed due to:** Level 3 investigation (see [investigation file path])

### Current Artifacts
- **Files created:** [list with paths — from re-execution]
- **Files modified:** [list with paths — from re-execution]
- **Exports added:** [function/class signatures with locations]
- **Schema changes:** [if any, or "None"]
- **Dependencies installed:** [if any, or "None"]
- **Key decisions:** [architectural choices made]
- **Plan corrections:** [if any, or "None"]

### Removed Artifacts
[Files that existed in the failed attempt's execution-index entry but are absent in the re-execution. Determined by diffing the original entry against the developer's re-execution output.]
- [file path] — [brief reason, e.g., "removed during plan revision"]

[Or "None — all original files retained."]

### Test Artifacts
- **Test plan:** plans/test-plans/phase-[N]-test-plan.md [add "(regenerated)" if re-execution produced a new test plan]
- **Test files:** [list of test file paths]
- **Test results:** execution/test-results/phase-[N]-results.md
- **Code reviews:** execution/code-reviews/phase-[N]-code-review-attempt-*.md
- **Test reviews:** execution/code-reviews/phase-[N]-test-review-attempt-*.md
- **Investigations:** [list of ALL investigation file paths — both from failed attempt and re-execution]
```

## Handoff Template

Path: `.project/cycles/<cycle>/execution/state/handoffs-to-developer/handoff.md`

Regenerated after each phase. Built from source (plan + execution-index + phase summaries), never from a previous handoff. The previous handoff is archived to `state/handoffs-to-developer/archive/phase-[N]-handoff.md` before this file is written.

```markdown
---
mode: handoff
phase: [N+1]
cycle: <slug>
source-phase: [N], or 'initial' for the phase-1 handoff
artifacts-count: [integer — count of rows in "Artifacts Available"]
plan-corrections-count: [integer — count of entries in "Plan Corrections"]
dependencies-listed-count: [integer — count of rows in "Dependencies Available"]
rebuild: [false | integer rebuild-attempt number]
---

# Handoff — Phase [N+1]: [Next Phase Name]

## Context
[What the next developer needs to know about the current state of the feature. Sourced from relevant phase summaries based on the next phase's `depends_on` field. Residual-only — include a fact only if the next developer cannot get it from the plan task, worktree files, persona, referenced skills, or memory.]

## Artifacts Available
[Exports, files, schemas, and dependencies from prior phases that the next phase depends on. Include file paths, function signatures, and type definitions.]

| Artifact | Location | Signature/Details |
|----------|----------|-------------------|
| `name` | `path/to/file.ts:line` | `description or signature` |

## Plan Corrections
[Corrections from prior phases that affect the next phase's work. These represent the actual correct approach — the next developer should follow these instead of the original plan where they conflict.]
- Phase [N]: [What the plan said] → [What was actually done]

[Or "None — plan followed exactly in all prior phases."]

## Dependencies Available
[Packages installed in prior phases that the next developer can use.]
| Package | Installed In | Purpose |
|---------|-------------|---------|
| `package-name` | Phase [N] | [what it provides] |

[Or "None."]

## Next Phase Tasks
[Copied from the implementation plan for reference — the next phase's task list.]
```

The frontmatter `phase` is the next phase's number (`[N+1]`); `source-phase` is the phase that produced this handoff (`[N]`), or `initial` for the handoff that precedes phase 1. `artifacts-count`, `plan-corrections-count`, and `dependencies-listed-count` are the row/entry counts of the `## Artifacts Available` table, the `## Plan Corrections` list, and the `## Dependencies Available` table respectively. `rebuild` is `false` for a normal `cycle-phase` handoff and the rebuild-attempt integer when the handoff is written by `rebuild` mode. Never add `handoff-quality`, `completeness-score`, `is-sufficient`, or `likely-to-trigger-rebuild` — a handoff records what it carries, never a self-assessment of its own sufficiency.

## Cycle Summary Template

Path: `.project/cycles/<cycle>/execution/state/cycle-summary.md`

Produced by `cycle-close` mode after the last phase's per-phase work has completed.

```markdown
---
cycle: <slug>
phases-completed: [integer]
deviations:
  minor: [integer]   # localized adjustments, plan intent preserved
  major: [integer]   # plan restructured (phase split, task removed, etc.)
files-created-count: [integer]
files-modified-count: [integer]
total-test-count: [integer]
---

# Cycle Summary — [Cycle Name]

## Overview
- **Cycle:** [name]
- **Phases completed:** [N]
- **Plan followed:** [yes | yes-with-deviations]

## What Was Built
[2-3 paragraph description of what the feature does and how it was implemented, written for a developer who needs to understand the feature without reading every phase summary.]

## All Files Created
| File | Phase | Purpose |
|------|-------|---------|
| `path/to/file.ts` | 1 | [what it does] |

## All Files Modified
| File | Phase | What Changed |
|------|-------|-------------|
| `path/to/file.ts` | 2 | [description] |

## Schema Changes
[Consolidated view of all DB/Prisma changes across all phases. "None" if no schema changes.]

## Key Architectural Decisions
[Consolidated from all phase summaries — decisions that affect future work on this area of the codebase.]
- [Decision]: [Rationale] (Phase [N])

## Public API Surface
[Exports, endpoints, services, or components that other features may depend on.]
| Export | Location | Signature |
|--------|----------|-----------|
| `functionName` | `path/to/file.ts:line` | `(params) => ReturnType` |

## Dependencies Installed
[Consolidated from all phases. "None" if no new dependencies.]
| Package | Phase | Why |
|---------|-------|-----|
| `package-name` | 2 | [reason] |

## Plan Corrections
[Consolidated from all phase summaries. Shows the delta between the original plan and what was actually implemented.]
- Phase [N]: [What the plan said] → [What was actually done]: [Why]

[Or "None — plan followed exactly."]

## Testing Summary
- **Total test files:** [N]
- **Total test cases:** [N]
- **Phases with CODE_BUG fixes:** [list of phase numbers, or "None"]
- **Phases with TEST_BUG fixes:** [list of phase numbers, or "None"]
- **Phases re-executed:** [list of phase numbers with investigation paths, or "None"]
- **Accepted failures:** [N total, with test names and reasons]
- **Code review findings path:** execution/code-reviews/
- **Test results path:** execution/test-results/
- **Investigations path:** execution/code-investigations/

## Execution Statistics
- **Code review first-pass rate:** [X/N phases passed on first review]
- **BLOCKED events:** [count]
- **Handoff rebuilds:** [count]
- **Escalations to user:** [count]
```

The frontmatter `phases-completed` mirrors the Overview `**Phases completed:**` line; `files-created-count` and `files-modified-count` are the row counts of `## All Files Created` and `## All Files Modified`; `total-test-count` is the `**Total test cases:**` value from `## Testing Summary`. `deviations.minor` and `deviations.major` are derived by classifying the consolidated `## Plan Corrections` entries (and any phase-summary deviation notes) against the two definitions in the schema comments — a minor deviation is a localized adjustment that preserves plan intent, a major deviation restructures the plan (phase split, task removed, etc.); do not add a new template section for them. The human-readable `**Plan followed:**` line in the Overview stays as-is. Never add `cycle-quality`, `would-ship`, or `confidence-in-completion` — the cycle summary records what was built, never a self-grade of the cycle.
