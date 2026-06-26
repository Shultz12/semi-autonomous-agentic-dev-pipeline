# Accept Feature Guide

## What It Does

Promotes a completed cycle — feature, refactor, primitives, or bugfix — from `completed-pending-approval` to `completed`. Merges the cycle's worktree branch into main (if not already merged) and delegates ROADMAP teardown to `progress-tracker close`. When the just-closed entry was the last in-progress entry in its milestone, the skill instructs the main agent (the agent that invoked the skill) to run the `quality-analyst` milestone fan-out (scoped per-(cycle × target) runs, then a `Mode: synthesis` roll-up) and then dispatch `milestone-archivist`, in that order. The skill itself never spawns those agents — it computes their inputs and returns them in the final report.

The actual writes are delegated:

- `progress-tracker close --final-status=completed` flips the relevant entry's `Status` in ROADMAP (when an entry exists), deletes the per-cycle tracking file, and — if this entry was the last in-progress entry in its milestone — also flips the milestone's own `Status` line and returns `MilestoneCompleted: v<X.Y>`.
- `quality-analyst` (run by the main agent on `MilestoneCompleted`) executes the milestone fan-out: scoped `Mode: agent` / `Mode: skill` runs per (cycle × target) across the milestone's cycles, then one `Mode: synthesis`, `Scope: milestone v<X.Y>` run that writes both the milestone synthesis report and `.project/pipeline/quality-reports/<DD-MM-YYYY>-v<X.Y>-knowledge-usage-report.md`.
- `milestone-archivist` (dispatched second by the main agent) snapshots ROADMAP.md and PRD.md into `.project/product/releases/v<X.Y>/`, synthesizes `CHANGELOG.md` from the supplied cycle-summary paths, commits the archive path-scoped, and creates an annotated `v<X.Y>` git tag (pushed to origin). The path-scoped archival commit picks up the new quality report alongside the milestone snapshot.

## Worktree types handled

| Worktree leaf | Worktree-Type | ROADMAP entry slug | Stage-based close-out |
|---|---|---|---|
| `<DD-MM-YYYY>-<feature-name>` | `feature` | `<DD-MM-YYYY>-<feature-name>` | (n/a — features have no `Stage` field) |
| `<DD-MM-YYYY>-refactor-from-<parent-name>` | `refactor` | `<DD-MM-YYYY>-refactor-from-<parent-name>` (always present from pre-curate start) | `Stage: post-curate` → approved path (phases ran). `Stage: pre-curate` → empty path (curate returned `NO_PROPOSALS_APPROVED`). Both close-outs reach `Status: completed-pending-approval` before `/accept-feature` runs. |
| `<DD-MM-YYYY>-primitives` | `primitives` | `<DD-MM-YYYY>-primitives` (always present from pre-curate start) | Both close-outs (approved or empty) flip the kept entry to `completed` — identical behavior — so `Scout-Result` is `n/a`. The entry's `Stage:` is informational only (it does not drive close). |
| `<DD-MM-YYYY>-fix-<name>` | `bugfix` | `<DD-MM-YYYY>-fix-<name>` (always present from intake) | (n/a — bug fixes have no `Stage` field; `Scout-Result: n/a`) |

## When to Use

After the orchestrator finishes a cycle, or independently to approve a deferred one. Accepts a slug, a feature-directory path, or no argument:

```
/accept-feature 19-04-2026-pdf-extraction
/accept-feature 19-04-2026-refactor-from-pdf-extraction
/accept-feature 19-04-2026-primitives
/accept-feature 19-04-2026-fix-hebrew-date-parse-crash
/accept-feature .project/cycles/19-04-2026-pdf-extraction/
/accept-feature
```

With no argument, the skill globs `.worktrees/*/` and lists every cycle awaiting approval. Every cycle — feature, refactor, primitives, bugfix — has a ROADMAP entry from start, so the worktree-type is read from each entry's `Type:` field.

When the caller has already merged the branch (the worktree's branch is in `git branch --merged main`), the skill detects this and skips its own merge step.

## What Happens

1. Resolves the target — worktree leaf and ROADMAP slug. The worktree-type (`feature` / `refactor` / `primitives` / `bugfix`) is read from the matched ROADMAP entry's authoritative `Type:` field, never inferred from the slug prefix — so a feature slug beginning `fix-` is never misread as a bug fix.
2. Reads ROADMAP.md and the entry's `Type:` field. All types require `Status: completed-pending-approval`; refactor inspects `Stage` to distinguish approved vs empty close-out paths. Primitives always has an entry and records `scout-result = n/a` (approved and empty close identically); bugfix records `scout-result = n/a`.
3. Resolves the branch name dynamically from the worktree (`git rev-parse --abbrev-ref HEAD` inside the worktree).
4. Checks whether the branch is already merged into main.
5. Asks you to confirm — shows worktree-type, scout-result if applicable, parent feature for refactor, merge state, and the possibility of milestone follow-up.
6. Merges the branch into main (unless already merged). On a merge conflict limited to ROADMAP/tracking paths, takes main's version and continues; on any other conflict, aborts and asks you to resolve manually.
7. Spawns `progress-tracker close` with the full input contract: `Mode`, `Slug`, `Final-Status: completed`, `Worktree-Type`, `Scout-Result`, `Parent-Feature`. Reads the response:
   - `Status: SUCCESS`, `MilestoneCompleted: false | n/a` → cycle accepted, no milestone follow-up.
   - `Status: SUCCESS`, `MilestoneCompleted: v<X.Y>` → cycle accepted AND milestone just completed; continue to step 8.
   - `Status: ERROR` → reports the failure and stops; re-running is safe.
8. (Milestone-only) Globs the feature directories listed under the just-completed milestone in ROADMAP, builds each `cycle-summary.md` path, verifies each exists. A missing summary blocks the milestone follow-up — the skill reports it and stops.
9. Offers cleanup: worktree removal (if applicable) and branch deletion (`git branch -d`, safe — refuses unmerged branches).
10. Reports the result. If `MilestoneCompleted: v<X.Y>` fired, the final report appends a "Next steps (for the main agent)" block listing the follow-up in order:
    1. The `quality-analyst` milestone fan-out — scoped `Mode: agent` / `Mode: skill` runs per (cycle × target) across the milestone's cycles, then one `Mode: synthesis`, `Scope: milestone v<X.Y>` run (which writes the knowledge-usage report).
    2. `milestone-archivist` with `Milestone: v<X.Y>` and the verified cycle-summary paths.

    The main agent is expected to perform the fan-out, then the synthesis, then the archival dispatch, sequentially after the skill returns.

## Idempotency

`/accept-feature` is safe to re-run. `progress-tracker close` is idempotent on both ROADMAP and tracking-file writes; `milestone-archivist` refuses to overwrite an existing archive directory (`Failure: archive-exists`); `quality-analyst` overwrites its report deterministically; branch deletion uses the safe `-d` form. A partial failure (e.g., merge succeeded but close failed) recovers by simply re-running.

## Related Files

| File | Purpose |
|------|---------|
| `.claude/skills/accept-feature/SKILL.md` | Skill definition (authoritative) |
| `.claude/agents/interface-contracts/accept-feature.contract.md` | Caller-facing contract for accept-feature |
| `.claude/agents/progress-tracker/progress-tracker.md` | Performs the ROADMAP/tracking writes (close mode) |
| `.claude/agents/interface-contracts/progress-tracker.contract.md` | Close-mode input/output contract, including `MilestoneCompleted` field |
| `.claude/agents/quality-analyst/quality-analyst.md` | Dispatched by the main agent on `MilestoneCompleted` (first) |
| `.claude/agents/milestone-archivist/milestone-archivist.md` | Dispatched by the main agent on `MilestoneCompleted` (second) |
| `.claude/agents/interface-contracts/milestone-archivist.contract.md` | Archival input/output contract |
