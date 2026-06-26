# Mode: `init`

**CWD:** Main. **Touches:** ROADMAP only (creates the file, or appends new milestone scaffolding to an existing one). **Does NOT touch any tracking file.** Bootstraps `ROADMAP.md` so the rest of the pipeline has a heading-format file to transition against.

This is the creation half of progress-tracker's ownership of `ROADMAP.md`. It is dispatched by `product-architect` once the product's milestones and feature decomposition are settled — `product-architect` never writes the ROADMAP itself. `init` lays down the North Star, the milestone sections, the backlog of not-yet-started features, and the "What We're Not Building" table. Per-feature `### <slug>` entries are NOT created here — those come later from `start` when a feature is picked up.

## Input

```
Mode: init
Product: <product name>
North-Star: <single sentence>

Milestones:
### <version> — <description>
Status: planned | in-progress | completed
Success-Criteria: <text>
Backlog:
- <cycle-slug> — <short description>
- <cycle-slug> — <short description>

### <version> — <description>
Status: planned
Success-Criteria: <text>
Backlog:
- <cycle-slug> — <short description>

Not-Building:
- <request> | <reason> | <revisit-when>
- <request> | <reason> | <revisit-when>
```

- `Product` and `North-Star` are required.
- At least one milestone block (`### <version> — <description>` + `Status:` + `Success-Criteria:` + optional `Backlog:`) is required.
- `Not-Building` is optional; when omitted, the "What We're Not Building" table is rendered with a header row and no data rows.
- Each `Backlog:` bullet is a feature name and a short description, separated by ` — `. Backlog items carry no slug; the dated `### <slug>` entry is created later by `start` when the item is picked up.

## Behavior

| ROADMAP.md state | Behavior |
|---|---|
| absent | Render the full file from scratch: title, `## Product:` + North Star, the self-documenting "Roadmap format" section, every milestone section, and the "What We're Not Building" table. |
| present | Idempotent merge. For each milestone in the input whose `## Milestone: <version>` heading is NOT already in the file, insert its section immediately before the `## What We're Not Building` heading (or at end of file if that heading is absent). For each `Not-Building` row whose `Request` value is NOT already in the table, append it. Milestones and rows that already exist are left untouched — `init` never overwrites an existing milestone, entry, or row. |

## Steps

1. Resolve main-root (`pwd`).
2. Compute path: ROADMAP = `<main-root>/.project/product/ROADMAP.md`.
3. Register output path (Completion Gate):
   ```bash
   echo "<main-root>/.project/product/ROADMAP.md" > /tmp/.claude-agent-output-target
   ```
4. Validate input: `Product`, `North-Star`, and at least one milestone block present. If any required field is missing, return `Status: ERROR` with `Warnings: [invalid-init-input]` without writing.
5. **ROADMAP write** (per persona's "ROADMAP write protocol"):
   - Acquire the ROADMAP lock.
   - Read the ROADMAP fresh if it exists; determine absent vs. present.
   - **Absent →** render the full file (see "Rendered shape" below).
   - **Present →** for each input milestone whose `## Milestone: <version>` heading is absent, insert its rendered section before `## What We're Not Building` (or at EOF); for each `Not-Building` row whose `Request` is absent from the table, append it. Leave everything else byte-for-byte intact.
   - Ensure the directory exists: `mkdir -p "<main-root>/.project/product"`.
   - Write back.
   - Commit per the `commit-to-git` skill (`Agent: progress-tracker`), subject `progress: <action> ROADMAP`, path `.project/product/ROADMAP.md`. `<action>` is `initialize` when the file was created, `extend` when milestones/rows were appended to an existing file. When the merge found nothing new to add, the commit is a no-op — set `ROADMAP-Commit: skipped`.
   - Release the lock.
6. Return.

## Rendered shape (file created from scratch)

```markdown
# Roadmap

## Product: <Product>
**North Star:** <North-Star>

---

## Roadmap format

Each work item is a `### <slug>` heading under its milestone, followed by a fixed field block:

- **Type:** `feature` | `refactor` | `primitives` | `bugfix`
- **Status:** `planned` | `in-progress` | `completed-pending-approval` | `completed`
- **Worktree:** `.worktrees/<slug>/` — present only while `in-progress`
- **Trigger:** `standard` | `post-merge of <feature>` | `manual (user-invoked)` | `bugfix`
- **Started:** `YYYY-MM-DD` — present once work begins
- **Completed:** `YYYY-MM-DD` — present only when `completed`
- **Scout-status:** `pending` | `in-progress` | `completed` | `empty-result` | `n/a`

Slug formats: feature `<DD-MM-YYYY>-<name>`; refactor `<DD-MM-YYYY>-refactor-from-<parent>`; primitives `<DD-MM-YYYY>-primitives`; bugfix `<DD-MM-YYYY>-fix-<name>`.

Live phase-by-phase progress lives in `.project/product/cycles-in-progress/<slug>.md`, not here — this file carries only lifecycle status. Backlog items carry no slug until work begins; the dated `### <slug>` entry is created when the item is picked up.

---

## Milestone: <version> — <description>
**Status:** <status>
**Success Criteria:** <success-criteria>

**Backlog (not yet started):**
- <cycle-slug> — <short description>
- <cycle-slug> — <short description>

---

## Milestone: <version> — <description>
**Status:** <status>
**Success Criteria:** <success-criteria>

**Backlog (not yet started):**
- <cycle-slug> — <short description>

---

## What We're Not Building
| Request | Reason | Revisit When |
|---------|--------|-------------|
| <request> | <reason> | <revisit-when> |
```

The "Roadmap format" section is fixed boilerplate — it documents this agent's own entry format and is emitted verbatim on creation. A milestone with no backlog items omits the `**Backlog (not yet started):**` block.

## Idempotency

- Re-running `init` against an existing ROADMAP never clobbers it: existing milestones, `### <slug>` entries, and "What We're Not Building" rows are preserved exactly. Only genuinely-new milestone sections and not-building rows are added.
- A re-run that finds nothing new performs no write; the commit is reported as `skipped`.

## Error conditions

- `invalid-init-input` — `Product`, `North-Star`, or all milestone blocks missing. Return `Status: ERROR` without writing.
- `roadmap-write-failed` / `commit-failed` — surface in `Warnings`.
