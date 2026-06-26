# Mode: `start`

**CWD:** Main. Single mode driven by an input decision matrix. No sub-modes.

## Input

```
Mode: start
Slug: <required>
Worktree-Type: feature | refactor | primitives | bugfix (required)
Worktree: .worktrees/<path>/                   (optional)
Parent-Feature: <parent slug>                  (required iff Worktree-Type=refactor)
Roadmap-Action: auto                           (optional; default auto)
Total-Phases: <M>                              (required iff a tracking file will be created)
Milestone: <version>                           (required when creating or appending a ROADMAP entry,
                                                e.g., "v1.2")
```

`Total-Phases` is required for every row of the decision matrix below that creates a `cycles-in-progress/<slug>.md` file. Caller (orchestrator) reads `M` from `.project/cycles/<slug>/plans/implementation-plan.md` (count of `## Phase` headings) and passes it down; progress-tracker does not read the plan file itself. For the `refactor` row, the `primitives / present / auto` row, and the `bugfix / present / auto` row, no plan exists yet (refactor/primitives pre-curate; bugfix pre-plan — the fix plan is authored only after diagnosis) — caller passes `Total-Phases: 0` and the rendered Current state shows the stage name without a denominator.

`Milestone` is required for every row in the decision matrix below — each one creates, transitions, or appends a ROADMAP entry.

## Decision matrix

| `Worktree-Type` | `Worktree` | `Roadmap-Action` | Behavior |
|---|---|---|---|
| feature    | absent  | auto   | Create ROADMAP entry at `Status=planned`. No tracking file. |
| feature    | present | auto   | Create-or-transition the ROADMAP entry to `Status=in-progress`; record `Worktree:` and `Started:`. Create tracking file. |
| refactor   | present | auto   | Append a new refactor ROADMAP entry at `Status=in-progress, Stage=pre-curate`. Set the parent feature's `Scout-status=in-progress` on its existing ROADMAP entry. Create tracking file. |
| primitives | present | auto   | Append a new primitives ROADMAP entry at `Status=in-progress, Stage=pre-curate` (`Type=primitives`, `Trigger=manual (user-invoked)`, `Scout-status=n/a`). Create tracking file. |
| bugfix     | present | auto   | Create-or-transition the ROADMAP entry to `Status=in-progress`; record `Worktree:` and `Started:`. Create tracking file. (A bug fix has no `planned` backlog state — the entry is always created from scratch here; the create-or-transition wording matches the feature row's protocol, but the transition branch is unreachable for bugfix.) |

Any other combination is invalid — return `Status: ERROR` with `Warnings: [invalid-start-combination]`. There is intentionally no `bugfix / absent / auto` row: the orchestrator always creates the worktree before dispatching `start` for a bug fix, so the `Worktree: absent` combination is unreachable; an invalid combination falls through to `invalid-start-combination` rather than a placeholder row.

## Steps

1. Resolve main-root (`pwd`).
2. Compute paths:
   - Tracking file: `<main-root>/.project/product/cycles-in-progress/<slug>.md`
   - ROADMAP: `<main-root>/.project/product/ROADMAP.md`
3. Register output path (Completion Gate) — choose by the matrix row:
   - Rows that create a tracking file → tracking file path.
   - Rows that only touch ROADMAP → ROADMAP path.
   ```bash
   echo "<target>" > /tmp/.claude-agent-output-target
   ```
4. **Pre-flight on ROADMAP entry state** — per-row applicability:
   - **`feature / absent / auto`**, **`feature / present / auto`**, **`primitives / present / auto`**, **`bugfix / present / auto`**: acquire ROADMAP lock (per persona's "ROADMAP write protocol"); read the slug's `### <slug>` block if it exists.
     - If `Status=completed-pending-approval` → release lock; return `Status: ERROR` with `Warnings: [ERROR_AWAITING_APPROVAL]`. The user must run `/accept-feature` or `/abandon-feature` before `start` can transition the entry again.
     - If `Status=in-progress` → release lock; return `Status: ERROR` with `Warnings: [ERROR_ALREADY_IN_PROGRESS]`. Caller should resume via the existing worktree + tracking file, not re-`start`.
     - If `Status=completed` → release lock; return `Status: ERROR` with `Warnings: [ERROR_ALREADY_COMPLETED]`. Completed entries are immutable; new work requires a new slug.
     - Otherwise continue while holding the lock.
   - **`refactor / present / auto`**: acquire ROADMAP lock; check both the refactor slug's entry and the parent feature's entry.
     - If the refactor slug's `### <slug>` block already exists at `Status=in-progress` → release lock; return `Status: ERROR` with `Warnings: [ERROR_ALREADY_IN_PROGRESS]`. The cycle is already in flight; resume via its existing worktree + tracking file.
     - If the refactor slug's entry exists at `Status=completed-pending-approval` → release lock; return `Status: ERROR` with `Warnings: [ERROR_AWAITING_APPROVAL]`.
     - If the refactor slug's entry exists at `Status=completed` → release lock; return `Status: ERROR` with `Warnings: [ERROR_ALREADY_COMPLETED]`.
     - Read the parent feature's `### <parent-slug>` block (found via `Parent-Feature:`). If the parent is absent → release lock; return `Status: ERROR` with `Warnings: [roadmap-entry-missing]`. If the parent's `Scout-status=in-progress` → release lock; return `Status: ERROR` with `Warnings: [ERROR_ALREADY_IN_PROGRESS]` (a refactor cycle is already in flight for this parent).
     - Otherwise continue while holding the lock.
5. **ROADMAP write** (per the matrix row's Behavior column):
   - **feature / absent / auto:** Insert a new `### <slug>` block at the bottom of the `## Milestone: <version>` section identified by `Milestone:`. Fields: `Type: feature`, `Status: planned`, `Trigger: standard`, `Scout-status: n/a`. Omit `Worktree:`, `Started:`, `Completed:`.
   - **feature / present / auto:** If a `### <slug>` block exists at `Status=planned`, transition it to `Status=in-progress`; otherwise insert a new block at the bottom of the named milestone's section. Fields after this step: `Type: feature`, `Status: in-progress`, `Worktree: <worktree>`, `Trigger: standard`, `Started: <YYYY-MM-DD>`, `Scout-status: n/a`.
   - **refactor / present / auto:** Two writes within the same lock-held window:
     1. Insert a new `### <DD-MM-YYYY>-refactor-from-<parent-name>` block at the bottom of the named milestone's section. Fields: `Type: refactor`, `Status: in-progress`, `Worktree: <worktree>`, `Trigger: post-merge of <parent-feature>`, `Started: <YYYY-MM-DD>`, `Scout-status: n/a`, `Stage: pre-curate`. (`Started:` is today's date — the pre-curate start date.)
     2. Locate the parent feature's `### <parent-slug>` block (found via `Parent-Feature:`); set `Scout-status: in-progress`. Leave other parent fields untouched.
   - **primitives / present / auto:** Insert a new `### <DD-MM-YYYY>-primitives` block at the bottom of the named milestone's section. Fields: `Type: primitives`, `Status: in-progress`, `Worktree: <worktree>`, `Trigger: manual (user-invoked)`, `Started: <YYYY-MM-DD>`, `Scout-status: n/a`, `Stage: pre-curate`. (`Started:` is today's date — the pre-curate start date; `Stage:` mirrors the refactor flow — the orchestrator advances it to `post-curate` at the curate→plan transition.)
   - **bugfix / present / auto:** Insert a new `### <slug>` block at the bottom of the named milestone's section (slug form `<DD-MM-YYYY>-fix-<name>`). Fields: `Type: bugfix`, `Status: in-progress`, `Worktree: <worktree>`, `Trigger: bugfix`, `Started: <YYYY-MM-DD>`, `Scout-status: n/a`.
6. Commit ROADMAP per the `commit-to-git` skill (`Agent: progress-tracker`), subject `progress: <action-description for slug>`, path `.project/product/ROADMAP.md`. `<action-description>` examples: `start tracking <slug>` (reused for `feature / present / auto` and `bugfix / present / auto`; the subject is action-named, not type-named), `register planned <slug>`, `start refactor cycle <slug>` (for `refactor / present / auto`; the parent-mutation lands in the same commit), `start primitives cycle <slug>` (for `primitives / present / auto`).
7. Release ROADMAP lock (if acquired in step 4).
8. **Tracking-file write** (only for matrix rows whose Behavior column says "Create tracking file"):
   - Ensure directory exists: `mkdir -p "<main-root>/.project/product/cycles-in-progress"`.
   - Render the tracking file from `.claude/agents/progress-tracker/tracking-file-template.md`:
     - Substitute `<slug>`, `<worktree>`, `<DD-MM-YYYY>-` portions, the ISO timestamp for `Registered:` and `Last updated:`.
     - Current state: `Phase 0 of <Total-Phases>` for `Worktree-Type=feature` (or stage name without denominator for `Worktree-Type=refactor` pre-curate, `Worktree-Type=primitives` pre-curate, and `Worktree-Type=bugfix` pre-plan — for `bugfix` the initial stage name is `intake`); `Status: in-progress`.
     - Phase history table: empty.
     - Links section: include only links whose target paths apply for this Worktree-Type (see template's conditional rules).
   - Write the file.
   - Commit per the `commit-to-git` skill (`Agent: progress-tracker`), subject `progress: create tracking file for <slug>`, path `.project/product/cycles-in-progress/<slug>.md`.
9. Return.

## Error conditions

- `ERROR_AWAITING_APPROVAL`, `ERROR_ALREADY_IN_PROGRESS`, `ERROR_ALREADY_COMPLETED` — see step 4 above; returned without modifying any file.
- `milestone-missing` — `Milestone:` provided but no matching `## Milestone: <version>` heading exists in ROADMAP. Return `Status: ERROR` without writing.
- `invalid-start-combination` — the `(Worktree-Type, Worktree, Roadmap-Action)` triple is not in the decision matrix. Return `Status: ERROR` without writing.
