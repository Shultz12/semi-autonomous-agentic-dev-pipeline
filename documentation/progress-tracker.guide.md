# Progress Tracker Guide

## What It Does

Owns `.project/product/ROADMAP.md` and per-slug tracking files (`.project/product/cycles-in-progress/<slug>.md`) as the sole authoritative owner — it both creates the ROADMAP and applies every lifecycle transition to it. Always targets main, regardless of whether invoked from main or a worktree. Five modes cover the ROADMAP's entire lifecycle, from creation through completion, across four Types (feature, refactor, primitives, bugfix).

## When to Use

Invoked by `product-architect` to create the ROADMAP, by the orchestrator at pipeline milestones, and by `accept-feature` / `abandon-feature` on terminal transitions. Not for direct user invocation.

| Mode | Caller | Invoked from | Purpose |
|------|--------|--------------|---------|
| `init`   | product-architect                | main     | Bootstrap a fresh ROADMAP (North Star + milestone sections + backlog + What-We're-Not-Building), or append new milestone scaffolding to an existing one |
| `start`  | orchestrator                     | main     | Create, transition, or append a ROADMAP entry per decision matrix; optionally create tracking file |
| `update` | orchestrator                     | worktree | Record phase completion in tracking file |
| `ship`   | orchestrator                     | worktree | Flip ROADMAP entry's `Status` to `completed-pending-approval` after last phase |
| `close`  | accept-feature / abandon-feature | main     | Final ROADMAP transition + tracking-file deletion + milestone-completion check |

## ROADMAP file shape

ROADMAP entries are markdown headings (not table rows). Each entry is `### <slug>` followed by bullet fields:

```
### <slug>
- Type: feature | refactor | primitives | bugfix
- Status: planned | in-progress | completed-pending-approval | completed
- Worktree: .worktrees/<path>/         (omit when Status=planned or Status=completed)
- Stage: pre-curate | post-curate      (Type=refactor or Type=primitives; present while in-progress, removed on close)
- Trigger: standard | post-merge of <X> | manual (user-invoked) | bugfix
- Started: YYYY-MM-DD                  (omit when Status=planned)
- Completed: YYYY-MM-DD                (only when Status=completed)
- Scout-status: pending | in-progress | completed | empty-result | n/a
```

Entries cluster under `## Milestone: <version> — <description>` headings; each milestone section starts with a `**Status:**` line. `Scout-status` carries meaningful states only on `Type=feature` entries. `Stage` is present on `Type=refactor` and `Type=primitives` entries while in-progress and is removed when the entry closes; it drives close behavior for refactor (approved keeps+completes the entry, empty removes it) but is informational for primitives (both outcomes close identically).

## What Happens

- **init** — renders a fresh `ROADMAP.md` from the product's North Star, milestones, per-milestone backlog of not-yet-started features, and the "What We're Not Building" table. Against an existing ROADMAP it merges idempotently — only milestone sections and not-building rows not already present are appended; existing content is never overwritten. Does not touch any tracking file.
- **start** — single mode driven by a five-row decision matrix over `(Worktree-Type, Worktree, Roadmap-Action)`. Creates a ROADMAP entry, transitions one to `in-progress`, appends a new refactor/primitives/bugfix entry, or just flips a parent feature's `Scout-status`. May or may not create a tracking file depending on the matrix row. Returns `ERROR_AWAITING_APPROVAL` / `ERROR_ALREADY_IN_PROGRESS` / `ERROR_ALREADY_COMPLETED` if the target entry's state forbids the transition.
- **update** — rewrites the tracking file's Current state block and Phase history table. Idempotent by phase number: re-running with the same `Phase: N` overwrites the row in place. Does not touch ROADMAP.
- **ship** — flips the ROADMAP entry's `Status:` bullet to `completed-pending-approval`. Does not touch tracking file — the final phase was already recorded by `update`.
- **close** — applies a per-Type behavior matrix:
  - `Final-Status: completed` — set `Status: completed`, record `Completed:`, remove `Worktree:` (and `Stage:` if present, on refactor or primitives), set `Scout-status: pending` (feature) or update parent's `Scout-status` (refactor); primitives and bugfix leave `Scout-status: n/a`. Delete tracking file.
  - `Final-Status: abandoned` — revert feature entry to `planned` (or remove refactor/primitives/bugfix entries; for refactor, parent feature's `Scout-status` returns to `pending`). Delete tracking file.
  - Always runs the milestone-completion check on `completed`: walks every `### <slug>` block inside the matched `## Milestone:` section; if all are `Status: completed`, flips the milestone's own `**Status:**` line to `completed` and returns `MilestoneCompleted: v<X.Y>` so `accept-feature` can spawn `milestone-archivist`. Otherwise returns `false` or `n/a`.

## ROADMAP write protocol

ROADMAP read-modify-writes are performed inline (not delegated). Every write acquires an atomic mkdir-lock at `<main-root>/.project/product/.roadmap.lock.d`, with exponential-backoff retry, stale detection (> 2 min), and unconditional release on every exit path. The lock prevents concurrent worktree callers from silently overwriting each other.

All commits go through the `commit-to-git` skill (`Agent: progress-tracker`); its path-scoped form keeps unrelated staged work in main's index from being swept into the commit. ROADMAP and tracking files are main-only, so commits always target main (`git -C <main-root>`) even from the worktree-resident `update`/`ship` modes.

No other agent writes ROADMAP or tracking files directly — worktree-resident agents and main-side agents alike (including `product-architect`) delegate every ROADMAP write to this agent.

## Main-Root Resolution

- Called from main (`start`, `close`) — uses `pwd`.
- Called from worktree (`update`, `ship`) — parses `git worktree list --porcelain`; the entry not under `.worktrees/` is main root.

## Return

`Status`, `Mode`, `Slug`, `Tracking-File`, `ROADMAP-Commit`, `Tracking-Commit`, `MilestoneCompleted`, `Lock-Wait-ms`, `Lock-Was-Stale`, `Warnings`. Full contract at `.claude/agents/interface-contracts/progress-tracker.contract.md`.

`MilestoneCompleted` carries `v<X.Y>` when `close --final-status=completed` determines every entry in the same milestone is now `completed`; `false` when others are still in-flight; `n/a` for every other mode and for `close --final-status=abandoned`.

## Related Files

| File | Purpose |
|------|---------|
| `.claude/agents/progress-tracker/progress-tracker.md` | Agent definition (authoritative spec) |
| `.claude/agents/progress-tracker/modes/<mode>.md` | Per-mode workflow steps |
| `.claude/agents/progress-tracker/tracking-file-template.md` | Template rendered by `start` mode |
| `.claude/agents/interface-contracts/progress-tracker.contract.md` | Per-mode input/output contract |
| `.claude/skills/accept-feature/SKILL.md` | Caller (close mode) |
| `.claude/skills/abandon-feature/SKILL.md` | Caller (close mode) |
| `.claude/agents/milestone-archivist/milestone-archivist.md` | Triggered by `MilestoneCompleted` return from close mode |
