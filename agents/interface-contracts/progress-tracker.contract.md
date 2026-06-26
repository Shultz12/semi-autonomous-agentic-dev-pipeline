# progress-tracker Interface Contract

Sole owner of `.project/product/ROADMAP.md` (creation and all lifecycle transitions) and `.project/product/cycles-in-progress/<slug>.md`. Five modes; always targets **main** regardless of caller CWD. ROADMAP read-modify-writes use an inline mkdir-lock protocol for concurrent-write safety across worktrees.

## ROADMAP entry format

Each entry is a `### <slug>` heading followed by a fixed bullet block (`Type`, `Status`, `Worktree?`, `Trigger`, `Started?`, `Completed?`, `Scout-status`, `Stage?`). `Type` is one of `feature | refactor | primitives | bugfix`. `Trigger` is one of `standard | post-merge of <X> | manual (user-invoked) | bugfix`. `Stage` is present on `Type=refactor` and `Type=primitives` entries while in-progress, with values `pre-curate | post-curate` (for refactor it drives close behavior; for primitives it is informational only). `Scout-status` carries meaningful states only on `Type=feature` entries; on `Type=refactor`, `Type=primitives`, and `Type=bugfix` it stays `n/a` for the entry's full lifecycle. Slug formats per Type: `feature` → `<DD-MM-YYYY>-<name>`; `refactor` → `<DD-MM-YYYY>-refactor-from-<parent-name>`; `primitives` → `<DD-MM-YYYY>-primitives`; `bugfix` → `<DD-MM-YYYY>-fix-<name>`. Entries cluster under `## Milestone: <version> — <description>` headings; each milestone section starts with a `**Status:**` line.

## Input — `init` mode

`product-architect` spawns `init` from main once the product's milestones and feature decomposition are settled. Bootstraps a fresh `ROADMAP.md` (North Star + milestone sections + backlog + "What We're Not Building"), or — when a ROADMAP already exists — appends only the milestone sections and not-building rows that are not yet present (idempotent merge; never clobbers existing content).

**Required:**
```
Mode: init
Product: [product name]
North-Star: [single sentence]

Milestones:
### [version] — [description]
Status: [planned | in-progress | completed]
Success-Criteria: [text]
Backlog:
- [cycle-slug] — [short description]
...

Not-Building:                          # optional
- [request] | [reason] | [revisit-when]
...
```

At least one milestone block is required. Backlog items carry no slug; the dated `### <slug>` entry is created later by `start` when the item is picked up.

### Example Invocation (init — fresh ROADMAP)

```
Mode: init
Product: Smartabu
North-Star: Monthly PDF extractions across all organizations

Milestones:
### v1.0 — Core Platform
Status: in-progress
Success-Criteria: End-to-end extraction works reliably — upload a Tabu PDF, extract data, download formatted Excel.
Backlog:
- excel-generation — Excel template rendering and download
- extraction-history — past-conversions listing

### v1.1 — Custom Templates
Status: planned
Success-Criteria: Organizations can create and manage custom Excel templates.
Backlog:
- template-management — advanced custom Excel template features

Not-Building:
- Public API | Web app is the primary interface | Significant enterprise demand for programmatic access
```

## Input — `start` mode

Single mode driven by an input decision matrix. The caller selects behavior by combining `Worktree-Type`, `Worktree` presence, and `Roadmap-Action`.

**Required:**
```
Mode: start
Slug: [slug]
Worktree-Type: [feature | refactor | primitives | bugfix]
Worktree: [.worktrees/<path>/]              # required for every row except feature/absent/auto
Parent-Feature: [parent slug]               # required iff Worktree-Type=refactor
Roadmap-Action: [auto]                      # optional; default auto
Total-Phases: [M]                           # required iff a tracking file will be created
                                            # (pass 0 for refactor pre-curate, primitives pre-curate,
                                            # and bugfix pre-plan — no plan exists yet)
Milestone: [version]                        # required when creating or appending a ROADMAP entry
                                            # (required for bugfix — the bugfix entry is always
                                            # created from scratch under the active milestone)
```

### Decision matrix

| `Worktree-Type` | `Worktree` | `Roadmap-Action` | Behavior |
|---|---|---|---|
| feature    | absent  | auto   | Create ROADMAP entry at `Status=planned`. No tracking file. |
| feature    | present | auto   | Create-or-transition the ROADMAP entry to `Status=in-progress`; record `Worktree:` and `Started:`. Create tracking file. |
| refactor   | present | auto   | Append refactor ROADMAP entry at `Status=in-progress, Stage=pre-curate`. Set parent feature's `Scout-status=in-progress`. Create tracking file. |
| primitives | present | auto   | Append primitives ROADMAP entry (`Type=primitives`, `Trigger=manual (user-invoked)`, `Scout-status=n/a`) at `Status=in-progress, Stage=pre-curate`. Create tracking file. |
| bugfix     | present | auto   | Create-or-transition the ROADMAP entry to `Status=in-progress`; record `Worktree:` and `Started:`; entry fields: `Type=bugfix`, `Trigger=bugfix`, `Scout-status=n/a`. Create tracking file. (No `bugfix / absent / auto` row — the orchestrator always creates the worktree before dispatching `start` for a bug fix.) |

### Example Invocation (start — feature, planned)

```
Mode: start
Slug: 19-04-2026-pdf-extraction
Worktree-Type: feature
Roadmap-Action: auto
Milestone: v0.4
```

### Example Invocation (start — feature, dispatching the worktree)

```
Mode: start
Slug: 19-04-2026-pdf-extraction
Worktree-Type: feature
Worktree: .worktrees/19-04-2026-pdf-extraction/
Roadmap-Action: auto
Total-Phases: 5
Milestone: v0.4
```

### Example Invocation (start — refactor, post-merge investigation)

```
Mode: start
Slug: 19-04-2026-refactor-from-pdf-extraction
Worktree-Type: refactor
Worktree: .worktrees/19-04-2026-refactor-from-pdf-extraction/
Parent-Feature: 19-04-2026-pdf-extraction
Roadmap-Action: auto
Total-Phases: 0
Milestone: v0.4
```

### Example Invocation (start — primitives)

```
Mode: start
Slug: 19-04-2026-primitives
Worktree-Type: primitives
Worktree: .worktrees/19-04-2026-primitives/
Roadmap-Action: auto
Total-Phases: 0
Milestone: v0.4
```

### Example Invocation (start — bugfix)

```
Mode: start
Slug: 19-04-2026-fix-hebrew-date-parse-crash
Worktree-Type: bugfix
Worktree: .worktrees/19-04-2026-fix-hebrew-date-parse-crash/
Roadmap-Action: auto
Total-Phases: 0
Milestone: v0.4
```

## Input — `update` mode

Orchestrator spawns `update` from the worktree, after each `state-manager` return. Idempotent by phase number: rerunning with the same `Phase: N` overwrites the row in place rather than appending.

**Required:**
```
Mode: update
Slug: [slug]
Phase: [N]
Phase-Name: [name | stage-name]
Phase-Status: [completed | blocked | checkpoint | in-progress]
Phase-Started: [ISO-timestamp]
Phase-Completed: [ISO-timestamp | "—"]
```

### Example Invocation (update)

```
Mode: update
Slug: 19-04-2026-pdf-extraction
Phase: 2
Phase-Name: "Session management"
Phase-Status: completed
Phase-Started: 2026-04-15T09:14:02Z
Phase-Completed: 2026-04-15T11:22:47Z
```

## Input — `ship` mode

Orchestrator spawns `ship` from the worktree, after the final phase's `update` returns SUCCESS. Flips the ROADMAP entry's `Status` to `completed-pending-approval`; `ship` owns this transition exclusively.

**Required:**
```
Mode: ship
Slug: [slug]
```

### Example Invocation (ship)

```
Mode: ship
Slug: 19-04-2026-pdf-extraction
```

## Input — `close` mode

`accept-feature` or `abandon-feature` spawns `close` from main.

**Required:**
```
Mode: close
Slug: [slug]
Final-Status: [completed | abandoned]
Worktree-Type: [feature | refactor | primitives | bugfix]
Scout-Result: [empty | approved | n/a]   # n/a when Worktree-Type=feature, bugfix, or primitives;
                                         # empty or approved when Worktree-Type=refactor
Parent-Feature: [slug | n/a]              # required when Worktree-Type=refactor
```

### Behavior matrices

`Final-Status: completed`:

| `Worktree-Type` | `Scout-Result` | Behavior |
|---|---|---|
| feature    | `n/a`      | Entry → `completed`, set `Completed`, remove `Worktree`, set `Scout-status: pending`. Delete tracking file. |
| refactor   | `approved` | Refactor entry → `completed`, remove `Stage:` and `Worktree:`. Parent's `Scout-status: completed`. Delete tracking file. |
| refactor   | `empty`    | Remove refactor entry's heading block entirely. Parent's `Scout-status: empty-result`. Delete tracking file. |
| primitives | `n/a`      | Entry → `completed`, set `Completed`, remove `Worktree` and `Stage`. Delete tracking file. (Kept as a ran-found-nothing record; approved-vs-empty drives no close behavior, so `Scout-Result` is `n/a`.) |
| bugfix     | `n/a`      | Entry → `completed`, set `Completed`, remove `Worktree`. `Scout-status` stays `n/a` (a bug fix seeds no scout cycle). Delete tracking file. |

`Final-Status: abandoned`:

| `Worktree-Type` | Behavior |
|---|---|
| feature    | Entry reverts to `Status: planned`; remove `Worktree`, `Started`. Delete tracking file. |
| refactor   | Remove refactor entry's heading block entirely (it always exists post-`start`). Parent's `Scout-status: pending`. Delete tracking file. |
| primitives | Remove primitives entry's heading block entirely (it always exists post-`start`). Delete tracking file. |
| bugfix     | Remove bugfix entry's heading block entirely. A bug fix has no `planned` backlog state to revert to, so removal is the only correct teardown. Delete tracking file. |

### Example Invocation (close, feature accepted)

```
Mode: close
Slug: 19-04-2026-pdf-extraction
Final-Status: completed
Worktree-Type: feature
Scout-Result: n/a
Parent-Feature: n/a
```

### Example Invocation (close, refactor merged with proposals)

```
Mode: close
Slug: 19-04-2026-refactor-from-pdf-extraction
Final-Status: completed
Worktree-Type: refactor
Scout-Result: approved
Parent-Feature: 19-04-2026-pdf-extraction
```

### Example Invocation (close, primitives abandoned)

```
Mode: close
Slug: 19-04-2026-primitives
Final-Status: abandoned
Worktree-Type: primitives
Scout-Result: n/a
Parent-Feature: n/a
```

### Example Invocation (close, bugfix accepted)

```
Mode: close
Slug: 19-04-2026-fix-hebrew-date-parse-crash
Final-Status: completed
Worktree-Type: bugfix
Scout-Result: n/a
Parent-Feature: n/a
```

### Example Invocation (close, bugfix abandoned)

```
Mode: close
Slug: 19-04-2026-fix-hebrew-date-parse-crash
Final-Status: abandoned
Worktree-Type: bugfix
Scout-Result: n/a
Parent-Feature: n/a
```

## Output

```
Status: [SUCCESS | ERROR]
Mode: [init | start | update | ship | close]
Slug: [slug | n/a]
Tracking-File: [path | deleted | skipped | n/a]
ROADMAP-Commit: [short-hash | skipped | failed | n/a]
Tracking-Commit: [short-hash | skipped | failed | n/a]
MilestoneCompleted: [v<X.Y> | false | n/a]
Lock-Wait-ms: [milliseconds | n/a]
Lock-Was-Stale: [true | false | n/a]
Warnings: [list]
```

### Per-mode ROADMAP/tracking expectations

| Mode    | Tracking-File         | ROADMAP-Commit | MilestoneCompleted |
|---------|-----------------------|----------------|---------------------|
| init    | n/a                   | short-hash (or skipped when nothing new to add) | n/a |
| start (matrix rows that create tracking) | path (just created) | short-hash  | n/a |
| start (matrix rows that only touch ROADMAP) | n/a | short-hash | n/a |
| update  | path                  | n/a            | n/a                 |
| ship    | n/a                   | short-hash     | n/a                 |
| close   | deleted               | short-hash     | v<X.Y>, false, or n/a (see below) |

### `MilestoneCompleted` semantics

- `n/a` for `start`, `update`, `ship`, and for `close --final-status=abandoned`.
- `false` for `close --final-status=completed` when at least one other entry in the just-closed entry's milestone is still in any non-`completed` state.
- `v<X.Y>` for `close --final-status=completed` when every entry in the milestone (including this one) is now `completed`. `close` also flips the milestone's own `**Status:**` line to `completed` in the same invocation.

The caller (`accept-feature`) reads this field as the trigger to spawn `milestone-archivist`. A `v<X.Y>` value means the milestone-row write has already occurred; the caller's responsibility is archival, not ROADMAP mutation.

## Guarantees

- Always resolves main-root via `git worktree list --porcelain` when invoked from a worktree (`update`, `ship`); uses `pwd` when invoked from main (`start`, `close`).
- All commits go through the `commit-to-git` skill (`Agent: progress-tracker`); its path-scoped form never sweeps unrelated staged work from main's index. ROADMAP and tracking files are main-only, so commits target main (`git -C <main-root>`) even from worktree-resident modes.
- All ROADMAP read-modify-writes acquire an inline mkdir-lock at `<main-root>/.project/product/.roadmap.lock.d` with exponential-backoff retry, stale detection (> 2 min), and unconditional release on every exit path.
- `update` is idempotent by phase number; `start` is NOT idempotent — re-entry against an existing in-progress, pending-approval, or completed entry returns a typed error.
- `init` is non-destructive: against an existing ROADMAP it only appends milestone sections and "What We're Not Building" rows that are not yet present, leaving all existing milestones, `### <slug>` entries, and rows byte-for-byte intact. A re-run with nothing new to add performs no write (`ROADMAP-Commit: skipped`).
- `start` creates `.project/product/cycles-in-progress/` if missing.
- `ship` never touches the tracking file — the final phase was already recorded by the preceding `update`; `ship` owns only the ROADMAP entry's `Status` transition.
- `close --final-status=abandoned` deletes the tracking file (abandoned tracking files are deleted, not archived — phase history is lost by design so the canonical state is "this work was never finished").
- `close` is idempotent on a missing tracking file: the ROADMAP write still runs; the rm + commit are skipped.
- `close --final-status=completed` performs the milestone-completion check unconditionally and is idempotent on it.
- The agent writes nothing outside `.project/product/ROADMAP.md` and `.project/product/cycles-in-progress/<slug>.md`.

## Failure modes

- **ERROR: invalid-init-input** — `init` was missing `Product`, `North-Star`, or all milestone blocks. Nothing is written.
- **ERROR_AWAITING_APPROVAL** — `start` found the entry at `Status=completed-pending-approval`; user must run `/accept-feature` or `/abandon-feature` before re-`start`.
- **ERROR_ALREADY_IN_PROGRESS** — `start` found the entry already at `Status=in-progress`; caller should resume via the existing worktree + tracking file, not re-`start`.
- **ERROR_ALREADY_COMPLETED** — `start` found the entry at `Status=completed`; completed entries are immutable, new work requires a new slug.
- **ERROR: tracking-file-missing** — returned by `update` if the expected tracking file isn't on main (indicates `start` was never called or was rolled back).
- **ERROR: roadmap-entry-missing** — `ship` or `close` couldn't find the `### <slug>` heading.
- **ERROR: milestone-missing** — the entry isn't inside any `## Milestone:` section (blocks milestone-completion check).
- **ERROR: roadmap-write-failed** — write or commit failed after lock acquire; lock released; warnings surfaced.
- Commit failures (hook rejection, nothing to commit) are non-fatal: recorded as `skipped` or `failed` in the output, working-tree edit preserved.

## Relationship to other agents/skills

- Invoked by: `product-architect` skill (init), `orchestrator` skill (start, update, ship), `accept-feature` skill (close), `abandon-feature` skill (close).
- Invokes: none. ROADMAP writes are direct and exclusive to this agent — it is the only writer of `.project/product/ROADMAP.md` for both creation and transitions.
- Triggers (indirectly): `milestone-archivist` agent — `accept-feature` spawns it when this agent's `close` output carries `MilestoneCompleted: v<X.Y>`.
- Never invoked by: `state-manager`, `developer`, `code-reviewer`, `test-runner`, `plan-architect`.
