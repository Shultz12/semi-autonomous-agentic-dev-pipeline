# Target: bugfix-reproduction

**Artifact:** `.project/cycles/<slug>/plans/reproduction-plan.md`.

Single-pass authoring of the Stage 1 reproduction plan: one or more failing tests that pin a behavioral bug to a concrete, observable assertion. The plan is consumed by the test `developer`; the resulting test must compile cleanly and fail at runtime (RED) before any fix is planned.

## Inputs (any action)

- `Bug Report:` — `<Cycle Path>/specs/bug-report.md` (required). Supplies the `## Objective` (the one-line bug summary) and, per symptom, the `## Expected Behavior` text used verbatim as each task's `Bug-Expectation:`.
- `Investigation Files:` — zero or more paths under `<Cycle Path>/execution/code-investigations/`. Absent on the reproduce-first path; present when the orchestrator investigated first to find the deterministic trigger conditions. When present, ground each test's setup in the investigation's reproduction conditions.
- `Affected Test Files Hint:` — optional; the bug report's `## Affected Area`. A starting hint for where to co-locate the reproduction test beside the affected module; not authoritative.
- Reference-only: `.project/knowledge/architecture.md`, `.project/knowledge/overview.md`, `.project/knowledge/sitemap.md` — ground test-file paths.
- `.claude/agents/developer/essentials/test/knowledge-map.md` — test-persona routing and conventions.

This target reads no SRS, SDD, BDD, or tech-stack charter — a reproduction test exercises existing behavior with the existing test stack. The inputs above are the exhaustive input set.

## Output

`.project/cycles/<slug>/plans/reproduction-plan.md`:

- A `## Objective` section (1–2 sentences naming the bug the plan reproduces, drawn from the bug report). No Quick Reference, no Meta. A `## Open Questions` section only when reproduction surfaced an unresolved question for the user.
- A single phase with `Developer: test`. For a bundled bug report (multiple distinct symptoms), one task per symptom — each its own test.
- Verb-noun task headers per `essentials/allowed-verbs.md`, naming the behavior the test exercises.
- Per-task metadata block per `essentials/writing-discipline.md`, plus the reproduction-specific `Bug-Expectation:` field:

```
- Target file(s): new: <test file path>
- Acceptance: <single-file typecheck/lint predicate — the test compiles cleanly; it is expected to FAIL at runtime until the fix lands>
- Concern: test
- Effort: S | M | L
- Bug-Expectation: <verbatim from the bug report's ## Expected Behavior for this symptom>
```

`Bug-Expectation:` is the reproduction plan's per-task assertion contract — the analogue of the `Scenario:` field that `test-plan` tasks carry, for a flow with no BDD scenarios. The test developer asserts the named behavior directly. Because the test is expected RED at runtime, the `Acceptance:` predicate verifies the test *compiles* (single-file typecheck/lint), never that it passes.

## Pipeline role rules

Worktree-side writer + committer. The orchestrator dispatches reproduction-plan authoring from inside the bugfix worktree.

- Never write `ROADMAP.md` or anything under `.project/product/cycles-in-progress/`.
- If a three-way merge conflicts on those paths, take main unconditionally — a worktree-side change there is a bug to investigate, not text to merge.
- After a successful write, commit the plan path-scoped: Read `.claude/skills/commit-to-git/SKILL.md` and follow it, passing `Agent: plan-architect`, the path `.project/cycles/<slug>/plans/reproduction-plan.md`, and the subject — `plan(<slug>): add reproduction plan` for `create`, `plan(<slug>): revise reproduction plan` for `update`.

### When Mode: create

**Mechanic.** Single-pass authoring from the bug report (and investigation files when present). Emit one test task per distinct symptom, each carrying its `Bug-Expectation:` verbatim. No directive analysis.

### When Mode: update

**Additional inputs:** the existing `reproduction-plan.md` plus the trigger — a refined investigation (the reproduce-first path that re-investigated to find deterministic conditions) or an audit finding requiring revision.

**Mechanic.** Revise the reproduction plan reflecting the trigger; preserve task headers whose `Bug-Expectation:` is unchanged.

## Errors

- `MISSING_BUG_REPORT: <path>` — `bug-report.md` absent at the cited path. Write nothing.
