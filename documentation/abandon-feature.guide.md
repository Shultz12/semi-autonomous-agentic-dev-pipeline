# Abandon Feature Guide

## What It Does

Throws away an in-progress cycle — feature, refactor, or primitives — without merging. Removes the worktree and the cycle's branch (with `--force`, unmerged commits lost), then delegates ROADMAP and tracking-file cleanup to `progress-tracker close --final-status=abandoned`. Feature specs and plan on main are preserved (for feature and refactor cycles), so a feature can be restarted later and a refactor can be re-queued via the parent feature's `Scout-status=pending`.

## Worktree types handled

| Worktree leaf | Worktree-Type | Abandon outcome (per `progress-tracker close` matrix) |
|---|---|---|
| `<DD-MM-YYYY>-<feature-name>` | `feature` | Feature ROADMAP entry reverts to `Status=planned` (re-runnable); tracking file deleted. |
| `<DD-MM-YYYY>-refactor-from-<parent-name>` | `refactor` | The refactor ROADMAP entry (created at pre-curate start; always present during execution) is removed. Parent feature's `Scout-status` returns to `pending` (re-queues the post-merge investigation). Tracking file deleted. |
| `<DD-MM-YYYY>-primitives` | `primitives` | If a `Type=primitives` entry was appended, it is removed. Tracking file deleted. |

## When to Use

```
/abandon-feature 19-04-2026-pdf-extraction
/abandon-feature 19-04-2026-refactor-from-pdf-extraction
/abandon-feature 19-04-2026-primitives
/abandon-feature
```

Use when:

- Design drift mid-execution — specs no longer match what's being built.
- Transactional rollback after a failed `git worktree add` — called programmatically by the orchestrator to undo the `progress-tracker start` registration so cycle setup is soft-transactional.
- User changes their mind about the cycle.
- Fatal BLOCKED from orchestrator that can't be recovered by a plan amendment.

**Don't use when:**

- Cycle status is `completed` — worktree shouldn't exist; investigate manually.
- Cycle status is `completed-pending-approval` — use `/accept-feature` instead.
- You want to pause work — there's no pause. Either finish and amend, or abandon and restart.
- You want to keep the branch for cherry-picking — cherry-pick manually first, then invoke.

## Interactive vs. Programmatic

Two invocation paths:

- **Slash command** (`/abandon-feature <slug>`) — always shows an `AskUserQuestion` confirm dialog. Any `programmatic` flag passed as a slash arg is ignored.
- **Skill tool** — may pass `programmatic: true` + a non-empty `reason` string to skip the confirm. Missing or empty `reason` with `programmatic: true` returns `Status: ERROR`.

The mandatory `reason` field makes silent bypass loud: a caller that forgets it gets an immediate error, not a destroyed worktree. The `reason` is also written to the return output for post-mortem traceability.

See `SKILL.md` for the authoritative input contract.

## What Happens

1. Resolves the cycle from the argument (or asks via `AskUserQuestion` if no arg). Detects worktree-type from the slug prefix (`refactor-from-…` → refactor; `…-primitives` → primitives; otherwise feature). For refactor, locates the parent feature.
2. Preflight: refuses `Status: completed`; confirms with user unless programmatic.
3. Resolves the branch name dynamically from the worktree (`git rev-parse --abbrev-ref HEAD`). `git worktree remove --force` the worktree, `git branch -D` the branch.
4. Delegates to `progress-tracker` with the expanded close input: `Mode: close`, `Slug`, `Final-Status: abandoned`, `Worktree-Type`, `Scout-Result: n/a`, `Parent-Feature`. Progress-tracker applies the abandon matrix — feature → planned; refactor → remove refactor entry + parent's Scout-status → pending; primitives → remove primitives entry if appended; tracking file deleted in all three cases.
5. Reports what was removed (worktree, branch, tracking file, ROADMAP mutation) and what survives (feature dir on main for feature cycles; parent feature's specs/plan for refactor cycles).

## Recovery

If `progress-tracker close` errors after the worktree/branch are already gone, re-run `/abandon-feature <slug>` — close is idempotent on missing tracking files and will still apply the ROADMAP mutation. Do not recreate the worktree to "undo" — restart via `/orchestrator` instead.

## Related Files

| File | Purpose |
|------|---------|
| `.claude/skills/abandon-feature/SKILL.md` | Skill definition (authoritative spec) |
| `.claude/agents/progress-tracker/progress-tracker.md` | Delegated close mode |
| `.claude/agents/interface-contracts/progress-tracker.contract.md` | Close-mode input/output contract |
| `.claude/skills/accept-feature/SKILL.md` | Counterpart for completed cycles |
