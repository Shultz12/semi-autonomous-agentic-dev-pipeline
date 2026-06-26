# Target: test-plan

**Artifact:** `.project/cycles/<cycle>/plans/test-plans/phase-<N>-test-plan.md` (per-phase).

## Dispatch model

The `test-plan` target is invoked per implementation phase by the orchestrator, after the phase's code-review returns PASS and before test-writing begins. The dispatch carries `Implementation Phase: <N>`. Not a feature-level one-shot — one plan per implementation phase.

## Inputs (any action)

- `Implementation Phase: <N>` from the dispatch.
- `.project/cycles/<cycle>/specs/bdd/CONTEXT.md` and every `.project/cycles/<cycle>/specs/bdd/*.feature`.
- `.project/cycles/<cycle>/specs/SRS.md`.
- Implemented code paths in the feature worktree, extracted from the phase's developer report (`## Artifacts Produced` and `## Files Modified`).

## Output

`.project/cycles/<cycle>/plans/test-plans/phase-<N>-test-plan.md`.

- Opens with a `## Objective` section (1–2 sentences) stating what the phase's tests verify — the behaviors delivered by `Implementation Phase: <N>`, anchored to the BDD scenarios the tasks trace to (e.g., "Verify the Hebrew-date parsing behavior delivered in Phase 2 against its BDD scenarios.").
- A `## Meta` section below the Objective with one line — `BDD Specs: .project/cycles/<cycle>/specs/bdd/`.
- Header section order: `## Objective` → `## Meta` → test tasks. When planning surfaced unresolved questions, a `## Open Questions` section follows `## Meta`. No Quick Reference section.
- Every phase carries `Developer: test`.
- Verb-noun headers + per-task metadata (`Target file(s)`, `Acceptance`, `Concern: test`).
- Phase sizing identical to feature plans.
- Every test task references at least one BDD scenario by ID via a `Scenario:` field (e.g., `Scenario: tabu-extraction-errors.feature:malformed-pdf`). Plan-auditor's `test-plan-rules.md` enforces this trace.

## Pipeline role rules

Worktree-side writer + committer. The orchestrator dispatches test-plan creation from inside `.worktrees/<cycle>/`.

- Never write `ROADMAP.md` or anything under `.project/product/cycles-in-progress/`.
- If a three-way merge conflicts on those paths, take main unconditionally — a worktree-side change there is a bug to investigate, not text to merge.
- After a successful write, commit the test plan path-scoped: Read `.claude/skills/commit-to-git/SKILL.md` and follow it, passing `Agent: plan-architect`, the path `.project/cycles/<cycle>/plans/test-plans/phase-<N>-test-plan.md` (include the test-plan changelog companion in the same commit when this write created or updated one), and the subject — `plan(<slug>): add phase <N> test plan` for `create`, `plan(<slug>): revise phase <N> test plan` for `update` (`<slug>` = basename of `<cycle>`).

### When Mode: create

**Additional inputs:** code-reviewer findings for phase `<N>` at `.project/cycles/<cycle>/execution/code-reviews/phase-<N>-code-review-attempt-*.md` (where they suggest test coverage gaps).

**Mechanic.** Author the test plan from BDD + implemented code paths in phase `<N>`. Each test phase task references at least one BDD scenario by ID. Where code-reviewer findings flagged a gap, an explicit test task covers it.

### When Mode: update

**Additional inputs:** the existing `phase-<N>-test-plan.md` plus the trigger — revised BDD, new code paths, or test-runner failures.

**Mechanic.** Revise `phase-<N>-test-plan.md` with phase additions or task amendments addressing the trigger. Existing task headers whose underlying scenario is unchanged are preserved. The `## Objective` is preserved unchanged unless the phase's covered behavior changed.

## Errors

- `MISSING_PHASE_NUMBER` — dispatch omitted `Implementation Phase: <N>`.
- `MISSING_DEVELOPER_REPORT: phase-<N>` — phase developer report not found at the canonical path.
- `MISSING_BDD: <cycle>` — `CONTEXT.md` or `.feature` files absent.
- `MISSING_SRS: <cycle>` — SRS absent.
- `MISSING_TEST_PLAN: phase-<N>` — `phase-<N>-test-plan.md` absent at the `update` action's precondition check.
