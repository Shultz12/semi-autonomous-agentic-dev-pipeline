# Milestone Archivist Guide

## What It Does

Produces the immutable archive for a completed milestone. When a version `v<X.Y>` finishes (all its features accepted), this agent:

- Creates `.project/product/releases/v<X.Y>/` on main.
- Copies the current `ROADMAP.md` and `PRD.md` (if present) into that directory as a point-in-time snapshot.
- Synthesizes `CHANGELOG.md` from the milestone's feature summaries.
- Commits the archive via the `commit-to-git` skill (`Agent: milestone-archivist`), path-scoped (never a naive `git commit -m`).
- Creates an annotated git tag `v<X.Y>` on the archive commit and pushes it to origin.

Runs on main. Never invoked from a worktree.

## When to Use

Spawned automatically by `accept-feature` when `progress-tracker close --final-status=completed` returns `MilestoneCompleted: v<X.Y>` — i.e., the feature just accepted was the last in-progress feature in its milestone. Not for direct user invocation.

## What Happens

1. Validates inputs — `Milestone:` matches `^v\d+\.\d+$`, and every supplied cycle-summary path exists on main.
2. Refuses if `.project/product/releases/v<X.Y>/` already exists (archives are immutable; re-archival requires manual investigation).
3. Registers the expected output target so the SubagentStop hook can verify completion.
4. Creates the archive directory; copies ROADMAP.md and PRD.md (emits `prd-missing` warning if absent).
5. Synthesizes CHANGELOG.md from the feature summaries, ordered alphabetically by feature name.
6. Commit via the `commit-to-git` skill (`Agent: milestone-archivist`), subject `milestone: archive v<X.Y>`, paths `.project/product/releases/v<X.Y>/`.
7. Annotated tag + push: `git tag -a v<X.Y> -m "..."` then `git push origin v<X.Y>`. Push is best-effort — a failed push records `Push: failed` in `Warnings` but still returns SUCCESS (the local tag is the durable artifact).

## Return

```
Status: <SUCCESS | ERROR>
Milestone: <v<X.Y>>
Archive-Dir: <path | n/a>
Changelog: <path | n/a>
Commit: <short-hash | failed | n/a>
Tag: <v<X.Y> | failed | n/a>
Pushed: <true | false | n/a>
Warnings: [list]
```

On `Status: ERROR`, `Warnings` carries a failure category: `invalid-version`, `cycle-summary-missing`, `archive-exists`, `commit-failed`, or `tag-exists`. See the contract for each category's expected caller recovery.

## Idempotency

The archive-exists guard is the idempotency barrier: re-invoking for a milestone that has already been archived returns `Status: ERROR`, `Failure: archive-exists` rather than overwriting. A stray tag without a matching archive directory returns `Failure: tag-exists` (investigate manually — it indicates inconsistency).

## Related Files

| File | Purpose |
|------|---------|
| `.claude/agents/milestone-archivist/milestone-archivist.md` | Agent definition (authoritative spec) |
| `.claude/agents/milestone-archivist/changelog-template.md` | Template rendered by Phase 5 |
| `.claude/agents/interface-contracts/milestone-archivist.contract.md` | Input/output contract for callers |
| `.claude/skills/accept-feature/SKILL.md` | Caller (spawns this agent when a milestone completes) |
| `.claude/agents/progress-tracker/progress-tracker.md` | Produces `MilestoneCompleted` that triggers this agent |
