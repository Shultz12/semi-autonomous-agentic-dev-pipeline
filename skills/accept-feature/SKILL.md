---
name: accept-feature
description: Promotes a completed feature, refactor, primitives, or bugfix cycle to approved, merges its worktree into main, delegates ROADMAP teardown to progress-tracker close, and — when the merged cycle was the last entry in its milestone — instructs the main agent to dispatch quality-analyst followed by milestone-archivist. Use after orchestrator finishes a cycle, or independently to approve a deferred one.
argument-hint: feature/refactor/primitives/bugfix slug, or .project/cycles/DD-MM-YYYY-name/
domain: dev-tooling
allowed-tools: Read, Glob, Grep, Bash, Agent, AskUserQuestion
---

# Accept Feature

Promote a completed cycle (feature, refactor, primitives, or bugfix) from `completed-pending-approval` to `completed`. Merge its branch into main, delegate ROADMAP and tracking-file teardown to `progress-tracker close`, and — when the cycle was the last in-progress entry in its milestone — instruct the main agent to dispatch `quality-analyst` then `milestone-archivist` in that order.

## Worktree types handled

| Worktree leaf | Worktree-Type | ROADMAP entry slug |
|---|---|---|
| `<DD-MM-YYYY>-<feature-name>` | `feature` | `<DD-MM-YYYY>-<feature-name>` |
| `<DD-MM-YYYY>-refactor-from-<parent-name>` | `refactor` | `<DD-MM-YYYY>-refactor-from-<parent-name>` (always present from pre-curate start) |
| `<DD-MM-YYYY>-primitives` | `primitives` | `<DD-MM-YYYY>-primitives` (always present from pre-curate start) |
| `<DD-MM-YYYY>-fix-<name>` | `bugfix` | `<DD-MM-YYYY>-fix-<name>` (always present from intake) |

A refactor entry's `Stage` distinguishes the close-out path: `Stage=post-curate` is the approved path (cycle went through phases); `Stage=pre-curate` is the empty path (curate returned `NO_PROPOSALS_APPROVED`, no phases ran). Both close-outs reach `Status=completed-pending-approval` before reaching this skill — the orchestrator dispatches `progress-tracker ship` on both post-phase completion and the empty close-out, so the `Status` field is uniform across the two paths and the entry's lifecycle invariant (`/accept-feature` consumes `completed-pending-approval`) holds for every cycle type. The merge proceeds and the bundled artifacts include findings/audit/approved-marker and their `-original.md` archives; the empty path has nothing more, the approved path also bundles the plan and code/conventions produced during phases.

## Usage

```
/accept-feature 19-04-2026-pdf-extraction
/accept-feature 19-04-2026-refactor-from-pdf-extraction
/accept-feature 19-04-2026-primitives
/accept-feature 19-04-2026-fix-hebrew-date-parse-crash
/accept-feature .project/cycles/19-04-2026-pdf-extraction/
/accept-feature
```

## Workflow

1. **Resolve target** — determine the worktree leaf and the ROADMAP slug. The worktree-type is read from the entry's authoritative `Type:` field in step 2 — never inferred from the slug prefix, so a feature whose name begins `fix-`, `refactor-`, or `primitives` is never misclassified.

   **No argument provided:** glob `.worktrees/*/` and cross-reference `.project/product/ROADMAP.md` for entries at `Status=completed-pending-approval`. Present the list and ask the user to pick one via `AskUserQuestion`.

   **Argument is a feature-directory path** (starts with `.project/cycles/`): extract the leaf from the path. The leaf is the directory name as-is — no slug translation.

   **Argument is a slug:** the worktree leaf and ROADMAP slug are both the input slug, verbatim — every cycle type uses its slug as both the worktree leaf and the ROADMAP entry heading.

   Verify `.worktrees/<leaf>/` exists. If not, report error and stop.

2. **Determine worktree-type and ROADMAP state** — read `.project/product/ROADMAP.md` and locate `### <slug>`. If no such entry exists, report the entry-not-found error and stop — the worktree-type is never guessed from the slug prefix. Read the entry's authoritative **`Type:` field** (`feature | refactor | primitives | bugfix`) and record it as `worktree-type`. Then apply the per-type state check:

   - **`feature`:** require `Status: completed-pending-approval`. If at a different status, report the actual status and stop.
   - **`refactor`:** the entry always exists from pre-curate start. Require `Status: completed-pending-approval`; inspect `Stage` to determine the close-out path:
     - **`Stage: post-curate`** → `scout-result = approved`. Cycle ran through phases.
     - **`Stage: pre-curate`** → `scout-result = empty`. Curate returned `NO_PROPOSALS_APPROVED`; only pre-curate artifacts need to merge. (The orchestrator dispatched `progress-tracker ship` on the empty close-out, so the entry is at `completed-pending-approval` before this skill is invoked.)
     - If `Status` is anything other than `completed-pending-approval` (e.g., still `in-progress` mid-phase, or `planned`) → report the actual status and stage and stop.
   - **`primitives`:** the entry always exists from pre-curate start. Require `Status: completed-pending-approval`. `scout-result = n/a` — a primitives cycle closes identically whether or not it approved proposals, so the approved-vs-empty outcome is not recomputed here. If at a different status, report the actual status and stop.
   - **`bugfix`:** require `Status: completed-pending-approval`. If at a different status, report the actual status and stop. `scout-result = n/a` and there is no parent feature — a bug fix seeds no scout cycle.

   Record:
   - `worktree-type` — `feature` | `refactor` | `primitives` | `bugfix`
   - `scout-result` — `n/a` (feature, primitives, bugfix) | `approved` | `empty` (refactor)
   - `parent-feature` — for `refactor`, the parent feature's slug (extract `<parent-name>` from the refactor slug, then locate the feature entry by globbing `.project/cycles/*-<parent-name>/` and matching the ROADMAP entry); for `feature`, `primitives`, and `bugfix`, `n/a`
   - `roadmap-slug` — the slug to pass as `Slug:` to `progress-tracker close`:
     - `feature` → feature slug
     - `refactor` (either result) → refactor slug (= worktree leaf)
     - `primitives` → primitives slug
     - `bugfix` → bugfix slug (= worktree leaf)

3. **Resolve branch** — determine the branch name dynamically from the worktree:

   ```
   BRANCH=$(git -C .worktrees/<leaf>/ rev-parse --abbrev-ref HEAD)
   ```

   This works for every worktree-type — the branch name equals the slug (the type is encoded in the slug itself, e.g. `-fix-`, `-refactor-from-`, `-primitives`; a feature slug carries no type marker), never a `type/` prefix. Resolving from the worktree avoids reconstructing the name from any pattern.

4. **Check if already merged** into main:

   ```
   git branch --merged main | grep -E "^[* ]+${BRANCH}$"
   ```

   Record: `already_merged = true | false`.

5. **Confirm with user** — show what will be promoted and what may follow. Use `AskUserQuestion`:

   ```
   Approve cycle: <slug>
   Type: <feature | refactor (result: approved|empty) | primitives | bugfix>
   Branch: <already merged into main | not yet merged>

   This may trigger quality-analyst and milestone-archivist if all other entries
   in the milestone are already approved.

   Proceed? [Yes / No]
   ```

6. **Merge with main** (only if not already merged) — perform the merge before delegating to `progress-tracker close`, so the close commit lands on a tree that already contains the worktree's work.

   **Already merged:** skip merge, report: "Branch already merged into main."

   **Not merged:** offer to merge:

   ```
   Cycle <slug> approved.
   Merge ${BRANCH} into main now? [Yes / No]
   ```

   **Yes:** execute the merge:

   ```
   git checkout main
   git merge --no-ff ${BRANCH}
   ```

   Report: "Merged ${BRANCH} into main."

   If merge fails (conflicts), inspect conflicting paths:

   ```
   git diff --name-only --diff-filter=U
   ```

   If every conflicting path is `.project/product/ROADMAP.md` or under `.project/product/cycles-in-progress/`, take main's version and continue the merge — a worktree-side conflict on these files indicates a bug to investigate, not text to merge. The completing commit follows the `commit-to-git` skill's merge-commit rule, attributing the merge to `accept-feature`:

   ```
   git checkout --ours -- .project/product/ROADMAP.md .project/product/cycles-in-progress/
   git add .project/product/ROADMAP.md .project/product/cycles-in-progress/
   git commit --no-edit --trailer "Agent: accept-feature"
   ```

   Report the resolution as an anomaly and continue to step 7.

   Otherwise, abort:

   ```
   git merge --abort
   ```

   Report: "Merge conflict detected on [paths]. Resolve manually or use the orchestrator's feature integration workflow." Stop — do not proceed to step 7.

   **No:** report branch name for manual handling and stop. Acceptance cannot complete without the merge.

7. **Dispatch `progress-tracker close`** — read `.claude/agents/interface-contracts/progress-tracker.contract.md` for the full close contract, then spawn `progress-tracker` (`subagent_type: "progress-tracker"`) with:

   ```
   Mode: close
   Slug: <roadmap-slug>
   Final-Status: completed
   Worktree-Type: <worktree-type>
   Scout-Result: <scout-result>
   Parent-Feature: <parent-feature>
   ```

   Field-mapping reference:

   | Worktree-Type | Scout-Result | Slug                | Parent-Feature        |
   |---|---|---|---|
   | feature    | n/a      | feature slug          | n/a                   |
   | refactor   | approved | refactor slug         | parent feature slug   |
   | refactor   | empty    | refactor slug         | parent feature slug   |
   | primitives | n/a      | primitives slug       | n/a                   |
   | bugfix     | n/a      | bugfix slug           | n/a                   |

   `progress-tracker close` flips the relevant ROADMAP `Status` (when an entry exists), deletes the per-cycle tracking file, and — if this was the last in-progress entry in its milestone — also flips the milestone's own `**Status:**` line to `completed` and returns `MilestoneCompleted: v<X.Y>`.

8. **Read the close output:**

   - **`Status: ERROR`** → report the failure (`Warnings:` field) and stop. The merge in step 6 may have already landed; that is acceptable — re-running `/accept-feature` is safe because `progress-tracker close` is idempotent on a missing tracking file.
   - **`Status: SUCCESS`, `MilestoneCompleted: false` or `n/a`** → cycle accepted; no milestone archival. Skip to step 10.
   - **`Status: SUCCESS`, `MilestoneCompleted: v<X.Y>`** → cycle accepted AND milestone just completed. Continue to step 9.

9. **Prepare the milestone follow-up sequence** — only when the close output carried `MilestoneCompleted: v<X.Y>`. This skill does NOT dispatch `quality-analyst` or `milestone-archivist` itself; it gathers the inputs the main agent needs and returns them in step 11.

   1. Read ROADMAP and list every entry under the just-completed milestone — features, refactors, primitives — recording each entry's slug.
   2. For each slug, map to the canonical feature directory:
      - `feature` slug → `.project/cycles/<slug>/`
      - `refactor` slug → `.project/cycles/<slug>/`
      - `primitives` slug → `.project/cycles/<slug>/`
   3. For each, build the path `.project/cycles/<dir>/execution/state/cycle-summary.md`. Verify each file exists (`test -f`). A missing summary indicates an entry that completed without `state-manager` finalizing its summary; surface that as a blocker and stop before reporting milestone completion.

10. **Cleanup** — after successful close (and after step 9 if it ran):

    Check for worktree:

    ```
    git worktree list
    ```

    If the worktree for this cycle exists, offer:

    ```
    Clean up worktree at .worktrees/<leaf>?
    a) Remove worktree + delete branch
    b) Keep for reference
    ```

    If no worktree, offer branch cleanup:

    ```
    Delete branch ${BRANCH}? [Yes / No]
    ```

    Use `git worktree remove` and `git branch -d` (lowercase — refuses on unmerged branches, which is the safety we want post-merge).

11. **Report result** — assemble the final user-facing report:

    ```
    Cycle <slug> accepted.
    Worktree-Type: <feature | refactor | primitives | bugfix>
    Scout-Result: <n/a | approved | empty>
    Status: completed-pending-approval -> completed
    Merge: <merged | already merged | no-op (no ROADMAP entry)>
    Tracking file: <deleted | n/a>
    ROADMAP commit: <short-hash | n/a>
    ```

    The `Worktree-Type` value mirrors the input passed to `progress-tracker close`. The `<slug>` printed on the first line is the cycle's primary slug — feature slug for `feature`, refactor slug for `refactor`, primitives slug for `primitives`, bugfix slug for `bugfix`.

    If the close output carried `MilestoneCompleted: v<X.Y>`, append the follow-up sequence the main agent must run:

    ```
    Milestone v<X.Y> completed.

    Next steps (for the main agent that invoked this skill):
      1. Run the quality-analyst milestone fan-out. quality-analyst has no milestone mode —
         the dispatcher (you) owns the fan-out; see quality-analyst.contract.md.
         a. For each completed cycle in the milestone, dispatch one scoped quality-analyst run
            per (cycle x target): Mode: agent (Target: <agent-name>, Cycle Path: <cycle-path>)
            or Mode: skill (Target: <skill-name>, Cycle Path: <cycle-path>). Each writes one
            scoped report under .project/pipeline/quality-reports/.
         b. Then dispatch one quality-analyst Mode: synthesis, Scope: milestone v<X.Y>.
            It rolls up the scoped reports and writes BOTH the milestone synthesis report and
            the knowledge-usage report at
            .project/pipeline/quality-reports/<DD-MM-YYYY>-v<X.Y>-knowledge-usage-report.md.
      2. Dispatch milestone-archivist with Milestone: v<X.Y> and these cycle-summary paths:
         - .project/cycles/<dir-1>/execution/state/cycle-summary.md
         - .project/cycles/<dir-2>/execution/state/cycle-summary.md
         ...
         (Creates .project/product/releases/v<X.Y>/, commits it path-scoped to main as
          "milestone: archive v<X.Y>", then tags v<X.Y> on that commit.
          The quality-report commit from step 1 lands just before this one in history;
          the v<X.Y> tag points at the archival commit only.)

    Dispatch in that order — the quality-analyst fan-out and synthesis first, then milestone-archivist.
    ```

    If cleanup happened, append the worktree/branch outcomes.

## Preserved invariants

- **Atomic merge** via `git merge --no-ff`. The merge is the integration point; this skill never edits the worktree's working tree.
- **No tagging.** Tag creation is owned by `milestone-archivist`; this skill never creates or pushes git tags.
- **Worktree cleanup** after successful merge, conditional on user approval.
- **Milestone-boundary detection** lives inside `progress-tracker close` — this skill only reacts to the `MilestoneCompleted` signal, never recomputes it.

## Idempotency

`/accept-feature` is safe to re-run. Each delegated step is idempotent:

- `progress-tracker close` is idempotent on both ROADMAP and tracking-file writes; re-running on an already-closed entry returns the same `MilestoneCompleted` signal without re-issuing writes.
- The post-skill milestone sequence is idempotent at the agent level: `milestone-archivist` refuses to overwrite an existing archive directory (`Failure: archive-exists`); `quality-analyst` overwrites its report deterministically.
- Branch deletion in step 10 uses `git branch -d` (safe, refuses unmerged), not `-D`.

A partial failure mid-flow (e.g., merge succeeded, close failed) can be recovered by re-running the command — no manual intervention required for the happy path.
