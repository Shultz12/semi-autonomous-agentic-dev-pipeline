# Coordination

Cross-agent sequencing rules and routing knowledge. Read this file once per session, when beginning phase work, alongside core-loop.md. Contents here govern when you invoke `progress-tracker`, which files you never touch, and how to react when those files surface in merge conflicts.

## Files you never write directly

Two files are main-branch-only. You never write to them, and no agent you dispatch writes to them either:

- `.project/product/ROADMAP.md`
- `.project/product/cycles-in-progress/<slug>.md`

Even when you're executing from a worktree, these files live on main and require a cross-tree write delegated to the dedicated pipeline-side dispatch described in § progress-tracker sequencing below. If you're about to route a dispatch that would modify either path, stop and re-route to that dispatch instead.

**One narrow carve-out** — at a refactor or primitives cycle's pre-curate → post-curate transition (orchestrator SKILL.md Step 5, `APPROVED_PROPOSALS_EXIST` branch), the orchestrator mutates the in-progress refactor or primitives entry's `Stage:` line in `.project/product/ROADMAP.md` directly. This is the single ROADMAP-write the orchestrator authors; every other ROADMAP write, and every write to `.project/product/cycles-in-progress/`, stays delegated. The write acquires the same mkdir-lock protocol `progress-tracker` uses and commits main-side via `commit-to-git`.

## Worktree boundary

Three boundaries govern what writes are allowed from where:

1. **Specs and main's plan are frozen while a worktree is active.** Once `.worktrees/<slug>/` exists, the feature's `specs/` and `plans/implementation-plan.md` on main are not amendable. If the user asks to change them mid-execution, direct them to finish execution and amend post-acceptance, or to `/abandon-feature` and restart.
2. **The worktree's plan is its own.** Mid-execution plan revisions (plan-architect invoked from inside a worktree) write only to the worktree's `plans/implementation-plan.md`. Main's copy stays frozen until merge.
3. **ROADMAP and tracking files are main-only.** See the delegation rule above. This invariant is what backs the merge-conflict rule below.

## progress-tracker sequencing

You invoke `progress-tracker` at three points in the work lifecycle and reach its fourth mode indirectly. You do not need to know what it writes — only when to call it.

| Mode | When you invoke it | Your CWD at invocation |
|------|---------------------|------------------------|
| `start`  | After `git worktree add` succeeds and you've `cd`'d into the new worktree. New work items only — never on resume. | Worktree |
| `update` | Inside Core Loop Step I, after `state-manager` returns for any phase. Also dispatched from Startup Step 4 (Plan Bookkeeping) once the standard-feature plan exists, to set `total-phases`. | Worktree |
| `ship`   | At the start of Feature Completion, after the last phase's Step I completes. | Worktree |
| `close`  | Reached indirectly via `/accept-feature` (on successful merge) or `/abandon-feature` (user-triggered). You do not invoke `close` directly. | — |

Pass the per-flow input fields to every `start` invocation: `slug`, `worktree-type`, `worktree` (when the matrix row requires it), `parent-feature` (refactor only), `roadmap-action` (`auto`), `total-phases` (when the matrix row creates a tracking file), `milestone` (required for every start flow, since each creates a ROADMAP entry). The orchestrator's Startup Step 0f matrix specifies the values per start flow.

Resume behavior: on a resumed session, skip `start` — the slug was registered on its original run. Continue to dispatch `update` for each phase that completes after the resume point, and `ship` when the final phase clears Step I.

## Soft-transactional start

`git worktree add` and `progress-tracker start` must succeed or fail together. Worktree creation is the atomic claim; the `start` dispatch follows. The sequence:

1. Run `git worktree add -b <slug> .worktrees/<leaf>/ origin/main`. If it fails, stop and surface the error — no progress-tracker registration was made, nothing to roll back.
2. `cd` into the worktree.
3. Dispatch `progress-tracker start` with the appropriate matrix row.
4. If `start` fails, roll back the worktree: `git worktree remove --force .worktrees/<leaf>/` and `git branch -D <slug>`. Report the failure and stop.

Do not skip the rollback. A worktree without a corresponding ROADMAP entry leaves an orphan that future `/orchestrator` invocations will detect as anomalous on-disk state.

## Merge conflicts on ROADMAP and tracking files

If a merge produces a conflict on `.project/product/ROADMAP.md` or `.project/product/cycles-in-progress/*.md`, the resolution is always to take main's version — no case-by-case judgment. These paths are main-only writes; a conflict on either means a worktree-side agent wrote to them in violation of the delegation rule. That is a bug to investigate, not a merge to resolve.

Mechanically: `git checkout --theirs -- <conflicting-path>` (main is "theirs" when merging a feature branch into main via the standard merge direction), then `git add <path>` and continue the merge. After completing the merge, surface the anomaly to the user so the source of the unauthorized write can be found.

## Mid-execution feature rename

Renaming a feature (changing its directory name or the name registered in ROADMAP) is not supported mid-execution. If the user asks, direct them to `/abandon-feature` and re-register under the new name. Tracking files, branch names, worktree paths, and plan paths all key off the original slug; a rename mid-flight leaves orphans across every one of those.
