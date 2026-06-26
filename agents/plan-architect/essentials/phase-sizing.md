# Phase Sizing

Plans are sized so each phase ships as one orchestrator dispatch — a single developer instance, a single review, a single test run. A developer instance runs on a fixed turn budget (~100 turns); a phase that exceeds it dies mid-task and leaves half-written code. Phase size is therefore measured by **effort**, not by raw task count — a one-line config task and a concurrency-heavy service are not interchangeable units.

## Effort tiers

Every task carries an `Effort: S | M | L` field in its metadata block (per `writing-discipline.md` Rule D). The tier is the **highest** tier reached on any of three axes — a task that triggers L on even one axis is L:

| Axis | S (1 pt) | M (2 pts) | L (3 pts) |
|------|----------|-----------|-----------|
| Files touched | 1 | 2 | ≥3 |
| Logic | declarative / mechanical — package, env var, doc comment, re-export, thin wrapper | one bounded unit of deterministic logic — a single service, component, or use-case | non-trivial algorithm, concurrency / race handling, DB transaction, state machine, schema migration, or drag-and-drop interaction |
| Acceptance | ≤2 distinct asserted behaviors | 3–6 | >6 |

Assign the tier honestly from the task as written; under-labeling to fit the budget is caught by the auditor's consistency check against the file and assertion axes.

## Phase budget

- **Hard cap: ≤ 8 effort points per phase.** Exceeding it blocks the audit.
- **Hard cap: ≤ 6 tasks per phase.** Backstop against a phase of many trivial tasks; whichever cap binds first wins.
- **Hard cap: ≤ 15 files per phase** (touched + new combined).
- **Soft target: 4–6 points** when tasks span more than one file or entity. A single-file, single-entity phase may run leaner.

The fix for an over-budget phase is splitting it, never shrinking tasks artificially or under-labeling effort.

## Mandatory phase boundaries

Start a new phase whenever any of the following holds:

- **Budget overflow.** Accumulated effort would exceed 8 points, or task count would exceed 6. Split the phase along its internal dependency or cohesion lines — **even when the developer type and target subarea are unchanged**. Each resulting phase must stand as an independently reviewable unit.
- **Developer Type changes** — `backend` → `frontend` → `infrastructure` → `test`. Different developer personas run different phases; mixing them in one phase corrupts the persona handoff.
- **Target subarea changes within the same Developer Type.** OK to keep `src/billing/controllers` and `src/billing/services` together. NOT OK to keep `src/billing` and `src/auth` together — different subareas need separate review boundaries.
- **Commit-dependency boundary.** If task B depends on task A being committed (not merely written), task B starts a new phase. The pipeline commits at phase close.

## Phase headers

Every phase carries a `Developer:` field naming one of `backend`, `frontend`, `infrastructure`, `test`. The orchestrator selects the matching developer persona; an absent or unrecognized `Developer:` blocks dispatch.

Phase numbering is sequential within a plan. When updates renumber phases (e.g., inserting an EXTRACT phase via `feature-final`, or splitting an over-budget phase), all later phase numbers shift; the action file's diff discipline governs whether renumbering is permitted.
