---
name: abandon-feature
description: >
  Escape hatch for an in-progress cycle (feature, refactor, primitives, or
  bugfix). Use when work should be discarded without merging — design
  drift mid-execution, failed transactional rollback after `git worktree add`,
  or the user changing their mind. Removes the worktree and branch (no merge),
  then delegates ROADMAP and tracking cleanup to `progress-tracker close
  --final-status=abandoned`. Preserves specs/plan on main so a feature can be
  restarted later; refactor cycles re-queue via the parent feature's
  Scout-status=pending; primitives and bugfix cycles simply disappear.
user-invocable: true
disable-model-invocation: true
argument-hint: "[feature/refactor/primitives/bugfix slug]"
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Agent
model: sonnet
domain: dev-tooling
---

# abandon-feature

Abandon an in-progress cycle: remove its worktree and branch (no merge), reset ROADMAP to the appropriate abandon state, delete the tracking file. Feature specs/plan on main are preserved so a feature can be restarted later.

## Worktree types handled

| Worktree leaf | Worktree-Type | Abandon outcome (per `progress-tracker close` matrix) |
|---|---|---|
| `<DD-MM-YYYY>-<feature-name>` | `feature` | Feature ROADMAP entry reverts to `Status=planned` (re-runnable); tracking file deleted. |
| `<DD-MM-YYYY>-refactor-from-<parent-name>` | `refactor` | The refactor ROADMAP entry (created at pre-curate start; always present during execution) is removed. Parent feature's `Scout-status` returns to `pending` (re-queues the post-merge investigation). Tracking file deleted. |
| `<DD-MM-YYYY>-primitives` | `primitives` | The primitives ROADMAP entry (created at pre-curate start; always present during execution) is removed. Tracking file deleted. |
| `<DD-MM-YYYY>-fix-<name>` | `bugfix` | Bugfix ROADMAP entry removed entirely; tracking file deleted; cycle directory `.project/cycles/<slug>/` discarded as part of the worktree teardown (bug-report.md, investigations, plans all go with it; nothing of it is on main to delete separately). A future re-attempt requires `/orchestrator bug fix` with a fresh description. |
| any leaf, no ROADMAP entry | `orphan` | Worktree and branch removed (type-agnostic teardown); there is no ROADMAP entry to mutate and no tracking file to delete. Recovers a worktree stranded by a failed or interrupted intake. |

## Usage

```
/abandon-feature 19-04-2026-pdf-extraction
/abandon-feature 19-04-2026-refactor-from-pdf-extraction
/abandon-feature 19-04-2026-primitives
/abandon-feature 19-04-2026-fix-hebrew-date-parse-crash
/abandon-feature
```

## Input Contract (programmatic invocation)

When invoked via the Skill tool (not a slash command), callers may pass:

```
slug: <slug>                       # required
programmatic: true | false         # default false
reason: <string>                   # REQUIRED when programmatic: true
```

`programmatic: true` + non-empty `reason` skips the `AskUserQuestion` confirm step (see Step 2). The `reason` is written to the return output so post-mortems can trace why the confirmation guardrail was bypassed. A `programmatic: true` call with an empty or missing `reason` is rejected with `Status: ERROR`.

Slash-command invocation (`/abandon-feature <slug>`) always runs interactively — ignores any `programmatic` field a user tries to pass.

## Workflow

### 1. Resolve target

- **Arg provided** — validate that `.worktrees/<slug>/` exists; if not, error out (see Error Cases) — there is nothing to abandon. Read `.project/product/ROADMAP.md` and locate `### <slug>`:

  - **Entry found** — read the entry's authoritative **`Type:` field** (`feature | refactor | primitives | bugfix`) and record it as `worktree-type`. The type is never guessed from the slug prefix, so a feature whose name begins `fix-`, `refactor-`, or `primitives` is never misclassified. Only genuinely slug-derived data stays slug-derived — for `refactor`, extract `<parent-name>` from the slug.
  - **No entry** — the worktree is an **orphan**: an interrupted or failed intake (`git worktree add` succeeded, but `progress-tracker start` never registered the entry) left a worktree with no ROADMAP entry. Record `worktree-type = orphan` and take the orphan teardown path — Steps 2–3 remove the worktree and branch; Step 4 is skipped because there is no entry or tracking file to delegate. An orphan needs no type discriminator: with no entry to mutate, there is nothing type-specific to do, so no slug-prefix inference is performed.

  For `feature`, also validate `.project/cycles/*-<feature-name>/` exists. If the feature directory is missing → error out (see Error Cases). Refactor and primitives worktrees may have no feature directory (curate returned `NO_PROPOSALS_APPROVED`) — that's expected, not an error. For `bugfix`, the cycle directory lives only inside the worktree (it reaches main solely via the accept-time merge), so there is no main-side directory to check.

- **No arg** — glob `.worktrees/*/` and cross-reference with `.project/product/ROADMAP.md`, reading each matched entry's `Type:` field (every live cycle — feature, refactor, primitives, bugfix — has a ROADMAP entry from start). A worktree with no matching `### <slug>` entry is an **orphan** cleanup candidate — list it as such. Present all candidates via `AskUserQuestion`.

Record:

- `worktree-type` — `feature` | `refactor` | `primitives` | `bugfix` (read from the entry's `Type:` field) | `orphan` (worktree with no ROADMAP entry)
- `parent-feature` — for `refactor`, the parent feature's slug (locate by globbing `.project/cycles/*-<parent-name>/`); for `feature`, `primitives`, `bugfix`, and `orphan`, `n/a`
- `roadmap-slug` — the slug to pass as `Slug:` to `progress-tracker close`:
  - `feature` → feature slug
  - `refactor` → refactor slug (= worktree leaf; the refactor entry always exists from pre-curate start)
  - `primitives` → primitives slug
  - `bugfix` → bugfix slug (= worktree leaf)
  - `orphan` → not applicable (Step 4 is skipped)

### 2. Preflight & Confirm

Use `AskUserQuestion` to show what will be destroyed and what will be preserved:

- **Destroyed:** worktree `.worktrees/<slug>/`, the cycle's branch, tracking file `.project/product/cycles-in-progress/<slug>.md`, and the appropriate ROADMAP mutation per the table at the top of this file. For `bugfix`, the cycle directory `.project/cycles/<slug>/` — `bug-report.md`, investigations, and any plans — is discarded **as part of the worktree teardown** (it exists only inside the worktree pre-accept; nothing of it is on main to delete separately). For an `orphan`, only the worktree and its branch are removed — there is no ROADMAP entry to mutate and no tracking file to delete.
- **Preserved:**
  - For `feature` — `.project/cycles/<DD-MM-YYYY>-<name>/` with specs/plan.
  - For `refactor` — the parent feature's specs and the parent feature's ROADMAP entry; the parent's `Scout-status` returns to `pending`.
  - For `primitives` — nothing beyond what is already on main.
  - For `bugfix` — nothing. The cycle directory is removed along with the worktree. A re-attempt is a fresh `/orchestrator bug fix`.
  - For `orphan` — nothing; nothing of it ever reached main.

Options: **Confirm** / **Cancel**. No archive option — the tracking file is deleted; phase history is lost by design.

If the input contract carries `programmatic: true` and a non-empty `reason`, skip the `AskUserQuestion` and record the reason in the return output.

Never abandon a cycle whose ROADMAP status is `completed` — warn and stop (completed entries shouldn't have worktrees; investigate manually). This check does not apply to an `orphan` (it has no entry, hence no status).

### 3. Execute removal

Resolve the branch dynamically from the worktree (works for every worktree-type — the branch name equals the slug, with the type encoded in the slug itself, e.g. `-fix-`, `-refactor-from-`, `-primitives` (a feature slug carries no type marker), and never a `type/` prefix; an orphan's branch is whatever `git worktree add` created):

```bash
BRANCH=$(git -C .worktrees/<slug>/ rev-parse --abbrev-ref HEAD)
git worktree remove .worktrees/<slug>/ --force
git branch -D "$BRANCH"
```

For an `orphan`, this is the entire teardown — proceed to Step 5 (Step 4 is skipped).

### 4. Delegate cleanup

Skip this step entirely for an `orphan` worktree-type — there is no ROADMAP entry or tracking file to delegate. If a stray tracking file `.project/product/cycles-in-progress/<slug>.md` exists despite the missing entry, do not guess a type to drive `close`; surface it as a partial-start anomaly for manual inspection (see Error Cases).

For every other worktree-type: read `.claude/agents/interface-contracts/progress-tracker.contract.md` for the close contract, then invoke `progress-tracker` via the `Agent` tool with the expanded abandon input. Do not touch `.project/product/ROADMAP.md` or `.project/product/cycles-in-progress/` directly. See the Delegation Protocol section below.

### 5. Report

Summarise what was removed (worktree, branch, tracking file, ROADMAP mutation) and what remains. For `feature`, suggest `/spec-architect` or `/plan-architect` as restart entry points if applicable. For `refactor`, note that the parent feature now has `Scout-status=pending` and will be re-queued. For `primitives`, no follow-up. For `bugfix`, no follow-up; to re-attempt the fix, run `/orchestrator bug fix` and re-describe the bug. For an `orphan`, report that a worktree stranded by a failed or interrupted intake was cleaned — worktree and branch removed; no ROADMAP entry existed.

## Error Cases

| Condition | Handling |
|---|---|
| Worktree missing | Error out — there is nothing to abandon. (Re-running `/abandon-feature <fix-slug>` after a bugfix worktree is already gone hits this branch cleanly — the intended idempotent outcome for `bugfix`, whose cycle directory vanished with the worktree.) |
| Worktree present, no `### <slug>` ROADMAP entry | Not an error — treat as an `orphan`: type-agnostic teardown (remove worktree + branch, skip `progress-tracker close`), report as an orphan cleanup. This is the documented recovery for a failed transactional rollback after `git worktree add`. |
| Stray tracking file present but no `### <slug>` entry | Partial-start anomaly. Remove the worktree + branch, then surface the inconsistency for manual inspection — do not guess a type to delete the tracking file via `close`. |
| Feature directory missing (worktree-type=feature) | Error out. |
| Worktree exists, branch missing | Warn; still remove worktree, then call `progress-tracker close`. |
| Worktree-type=refactor but parent feature not locatable in ROADMAP | Error out — abandon cannot proceed without the parent slug. |
| `progress-tracker close` returns `ERROR` | Report the error. Worktree/branch are already destroyed (Step 3). User can re-run — `progress-tracker close` is idempotent on a missing tracking file. |

## Delegation Protocol

Step 4 hands off to `progress-tracker` via the `Agent` tool. (Not reached for an `orphan` worktree-type — see Step 4.)

**Input sent:**

```
Mode: close
Slug: <roadmap-slug>
Final-Status: abandoned
Worktree-Type: <worktree-type>
Scout-Result: n/a
Parent-Feature: <parent-feature>
```

Field mapping per worktree-type:

| Worktree-Type | Slug                                          | Parent-Feature        |
|---|---|---|
| feature    | feature slug                                    | n/a                   |
| refactor   | refactor slug                                   | parent feature slug   |
| primitives | primitives slug                                 | n/a                   |
| bugfix     | bugfix slug                                      | n/a                   |

`Scout-Result` is always `n/a` on the abandon path — the abandoned matrix in `progress-tracker close` is keyed on `Worktree-Type` alone.

**Expected return statuses:**

| Status | Handling |
|---|---|
| `SUCCESS` | Report to caller: ROADMAP mutated per matrix, tracking file deleted. Include `ROADMAP-Commit` and `Tracking-Commit` from progress-tracker's return. |
| `ERROR`   | Worktree and branch are already destroyed (Step 3). Report the error; caller can re-run `/abandon-feature` — `progress-tracker close` is idempotent on missing tracking files. Do not attempt to recreate the worktree. |

Do not proceed past Step 4 without a structured return from progress-tracker. If the Agent tool itself errors (not a structured `Status: ERROR`), treat as ERROR and report.

## Safety Constraints

1. **Always confirm destructive action with the user** via `AskUserQuestion`, unless the input contract carries `programmatic: true` AND a non-empty `reason`. *Why:* the worktree may contain uncommitted work; silent destruction can lose data. Slash-command invocations always confirm regardless of any passed flags — slash flags cannot bypass the guardrail.
2. **Never delete `.project/cycles/<DD-MM-YYYY>-<name>/` contents on main, for any worktree-type.** *Why:* a feature's hand-crafted SRS/SDD/BDD and plan on main are the basis for later restart or for a refactor cycle's parent feature; abandoning throws away execution work, not design work. This constraint guards the **main** working tree's `.project/cycles/`. For `bugfix` (and an `orphan`), no main-side copy exists pre-accept — the cycle directory lives only in the worktree and is removed by `git worktree remove`, so never add a separate main-side `rm` of `.project/cycles/<slug>/`; the worktree teardown is the only removal. The preservation intent (keeping design work for restart) applies to `feature`-type cycles and a refactor's parent feature.
3. **Never abandon a cycle with `Status: completed`.** *Why:* completed entries shouldn't have a live worktree; that combination indicates a bug that needs investigation, not a destructive action.
4. **Never reimplement ROADMAP or tracking-file writes; always delegate to `progress-tracker close`.** *Why:* a direct write would bypass the ROADMAP lock and leave the tracking file in an inconsistent format. (An `orphan` worktree-type has no entry and no tracking file, hence no write to make — `close` is correctly skipped, not reimplemented.)
