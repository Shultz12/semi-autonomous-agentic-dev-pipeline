# Target: deviation

**Artifact:** the plan already under execution — an `implementation-plan.md` or a `phase-<N>-test-plan.md`, named at dispatch by `Plan Path`. Unlike the plan-authoring targets, this target owns no fixed output path; it patches the file it is handed.

This target is **update-only**. It reconciles a plan against a phase's recorded deviations — a lightweight pass, not authoring. `Mode: create` is rejected.

## Inputs

- `Plan Path` — the existing plan to reconcile (dispatch field).
- `Completed Phase: <N>: <phase-name>` (dispatch field).
- `Developer Report` — its `## Deviation Report` section is the trigger input (dispatch field).

## Output

The plan at `Plan Path`, patched in place. A changelog entry is appended to the feature's `plan-changelog.md` (or the test-plan changelog when `Plan Path` is a test plan) on every invocation — including no-change passes — so the reconciliation is auditable.

## When Mode: create

Unsupported. A deviation reconciliation presupposes a plan already in execution; there is nothing to author. Fail fast with `CREATE_UNSUPPORTED_FOR_DEVIATION` and write nothing.

## When Mode: update

**Precondition** (on top of the base `update` precondition that the artifact at `Plan Path` exists): the developer report exists and contains a `## Deviation Report` section. If absent, fail with `MISSING_DEVIATION_REPORT: <path>` and write nothing. If no plan exists at `Plan Path`, fail with `MISSING_PLAN: <path>`.

**Mechanic.**

1. Read the `## Deviation Report` from the developer report. Act only on NOTIFY rows — SILENT deviations are filtered out upstream.
2. Read the plan at `Plan Path`.
3. For each NOTIFY deviation, scan the phases **after** the completed phase:
   - A reference to a renamed, moved, or re-signed symbol → update it to the new value in the affected task body or metadata.
   - A helper the deviation already created → if a later phase plans to create the same thing, convert that task to consume the existing one (a substitutive edit per `actions/update.md` diff discipline).
   - A load-bearing task the deviation skipped → restore it in the completed phase and set `Routing: RETRY_PHASE`.
4. Preserve verb-noun headers and the per-task metadata block (`Target file(s)`, `Acceptance`, `Concern`). Never renumber phases — downstream handoffs and summaries index by phase number.
5. Append the changelog entry, then write the plan back to `Plan Path` if anything changed. If nothing changed, skip the plan write but still log the NO_CHANGE entry.

**Scope.** Scan only phases after the completed phase; never edit completed or current phases — except the one case above, where a skipped load-bearing task is restored in the completed phase and the pass returns `RETRY_PHASE`.

**Changelog entry format:**

```markdown
## Update [sequential-number] — [YYYY-MM-DD]
- **Trigger:** DEVIATION
- **Phase:** [N]: [phase-name] (completed)
- **Change-Level:** [NONE | PATCH | STRUCTURAL]
- **Routing:** [PROCEED_NEXT | RETRY_PHASE]
- **Phases Scanned:** [N+1] through [last]
- **Changes:**
  - [each reference update, or "None — no stale references found"]
- **Original Instructions** (changed tasks only):
  > [verbatim original task block that was modified]
```

Omit the "Original Instructions" block for NONE changes.

**Return fields.**

- **Change-Level** — `NONE` (already aligned, no write), `PATCH` (reference/wording fixes in existing tasks), `STRUCTURAL` (a future task converted to consume an existing helper, or a task restored/removed).
- **Routing** — `PROCEED_NEXT` when remaining phases are aligned; `RETRY_PHASE` when the completed phase left a gap.
- **Target-Phase** — completed phase for `RETRY_PHASE`; next unstarted phase for `PROCEED_NEXT`.

**Return shape:**

```
Status: SUCCESS
Mode: update
Target: deviation
Routing: [PROCEED_NEXT | RETRY_PHASE]
Trigger: DEVIATION
Change-Level: [NONE | PATCH | STRUCTURAL]
Target-Phase: [N]
Phases-Updated: [list or "none"]
Changelog: [changelog file path]
Changes: [1-2 sentence summary, or "No stale references found"]
```

## Pipeline role rules

**Worktree-side writer + committer.** `deviation` runs inside `.worktrees/<cycle>/` during execution. It never writes `ROADMAP.md` or anything under `.project/product/cycles-in-progress/`. If a three-way merge ever conflicts on those paths, take main unconditionally — a worktree-side change there is a bug to investigate, not text to merge.

After the reconciliation pass writes (the changelog on every invocation; the plan at `Plan Path` only when anything changed), commit path-scoped: Read `.claude/skills/commit-to-git/SKILL.md` and follow it, passing `Agent: plan-architect`, the path(s) written (the changelog, plus the plan at `Plan Path` when Change-Level is PATCH or STRUCTURAL), and the subject `plan(<slug>): reconcile plan with phase <N> deviations` (`<N>` = the completed phase number, `<slug>` = basename of `<cycle>`).

## Errors

- `CREATE_UNSUPPORTED_FOR_DEVIATION` — `Mode: create` dispatched against this target.
- `MISSING_PLAN: <path>` — no plan file at `Plan Path` (base `update` precondition).
- `MISSING_DEVIATION_REPORT: <path>` — developer report lacks a `## Deviation Report` section.
