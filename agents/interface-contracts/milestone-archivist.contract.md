# milestone-archivist Interface Contract

Archives a completed milestone: snapshots ROADMAP/PRD into `.project/product/releases/v<X.Y>/`, synthesizes `CHANGELOG.md` from the supplied feature summaries, commits the archive path-scoped, and creates an annotated git tag for the version. Runs on main; never invoked from a worktree.

## Input

Spawned by `accept-feature` only when accepting the last feature in a milestone (accept-feature returns `MilestoneCompleted: <version>`).

**Required:**

```
Milestone: v<X.Y>
Feature Summaries:
  - <path to cycle-summary.md>
  - <path to cycle-summary.md>
  ...
```

- `Milestone:` must match `^v\d+\.\d+$`. Anything else returns `Status: ERROR`, `Failure: invalid-version`.
- Every path under `Feature Summaries:` must exist on main. Each path is the canonical `cycle-summary.md` for one feature in the just-closed milestone. Order does not matter — the agent sorts features alphabetically when rendering the CHANGELOG.

### Example invocation

```
Milestone: v1.2
Feature Summaries:
  - .project/cycles/03-04-2026-auth/execution/state/cycle-summary.md
  - .project/cycles/08-04-2026-organization-management/execution/state/cycle-summary.md
  - .project/cycles/11-04-2026-credit-system/execution/state/cycle-summary.md
```

## Output

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

### Field semantics

| Field | Meaning |
|---|---|
| `Archive-Dir` | Path to the created archive directory on main. `n/a` only on early-stage validation failures. |
| `Changelog` | Path to the rendered CHANGELOG.md. `n/a` if the agent failed before Phase 5. |
| `Commit` | Short hash of the path-scoped archive commit. `failed` if the commit step failed (working-tree edits preserved); `n/a` if not reached. |
| `Tag` | The annotated tag created on the commit, equal to `Milestone`. `failed` if tag creation failed (tag-exists case); `n/a` if commit was skipped. |
| `Pushed` | `true` if `git push origin <Milestone>` succeeded, `false` if the push failed (best-effort — local tag is still authoritative), `n/a` if no tag was created. |
| `Warnings` | List of non-fatal observations: `prd-missing`, `push-failed`. |

### Failure categories

| Failure | Returned when |
|---|---|
| `invalid-version` | `Milestone:` did not match `^v\d+\.\d+$`. |
| `cycle-summary-missing` | One or more supplied summary paths do not exist on main. `Warnings` lists the missing paths. |
| `archive-exists` | `.project/product/releases/<Milestone>/` already exists on disk. Manual investigation required. |
| `commit-failed` | Path-scoped commit failed (hook rejection, nothing to commit, etc.). |
| `tag-exists` | Annotated tag `<Milestone>` already exists in the repo (tag without matching archive directory — inconsistency). |

## Guarantees

- Always resolves `<main-root>` via `pwd`; this agent runs on main only.
- Refuses to overwrite an existing `.project/product/releases/<Milestone>/` directory — the archive is immutable once produced.
- Never force-tags. A tag collision returns `Failure: tag-exists` rather than `git tag -f`.
- All commits go through the `commit-to-git` skill (`Agent: milestone-archivist`); its path-scoped form never sweeps unrelated staged work from main's index.
- Never writes `.project/product/ROADMAP.md` or any file under `.project/product/cycles-in-progress/`. The ROADMAP snapshot in the archive is a copy; the live ROADMAP is read-only to this agent.
- The CHANGELOG is synthesized only from the supplied cycle-summary paths — the agent does not glob the feature directory or infer the milestone's feature set independently.
- `Pushed: true` implies the local tag exists and the push to `origin` succeeded; `Pushed: false` implies the local tag exists but the push failed (caller can retry the push manually).
- On `Status: ERROR`, the working-tree state is consistent with the failure: no partial archive directory is left behind on validation failures (Phase 1–2); an uncommitted archive directory may remain on `commit-failed`; an unpushed tag may remain on push failures (which return SUCCESS with `Pushed: false`, not ERROR).

## Relationship to other agents/skills

- **Invoked by:** `accept-feature` skill, conditionally — only when accepting the last feature in a milestone (accept-feature returns `MilestoneCompleted: <version>`).
- **Invokes:** none. All work performed directly via `Read`, `Write`, `Glob`, `Grep`, `Bash`.
- **Never invoked by:** `orchestrator`, `state-manager`, or any worktree-side agent.
