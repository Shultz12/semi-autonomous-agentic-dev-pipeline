# Tracking file template

Rendered by `progress-tracker` in `start` mode. Substitute every `<placeholder>` with the concrete value. The file lives at `<main-root>/.project/product/cycles-in-progress/<slug>.md`.

The template supports four render shapes selected by the dispatch's `Worktree-Type`:

- **feature** — renders the full template (Phase counter with `of M`, full Links section).
- **refactor (pre-curate)** — drops the Phase denominator; Links section omits Plan/SRS/SDD lines (no plan exists yet).
- **primitives (pre-curate)** — same shape as refactor pre-curate.
- **bugfix (pre-plan)** — drops the Phase denominator (the tracking file is created at intake, before the fix plan exists); Links section carries the bug report, the investigations directory, and the (forward-referenced) implementation plan only. Omits SRS, SDD, plan-changelog, and Findings — a bug fix has no specs and no refactor proposals.

The refactor tracking file persists across the pre-curate → post-curate transition (same slug, same file). Subsequent `update` calls record the curate-stage entries and then the refactor-plan phases incrementally; the rendered shape from `start` is overwritten in place and remains valid throughout the cycle. The bugfix tracking file likewise persists across the intake → reproduce → investigate → checkpoint → plan → fix-phase-<N> sub-stages (same slug, same file); `update` overwrites the Current state and appends phase-history rows in place.

---

```markdown
# <slug>

- **Worktree:** `<worktree-path>`
- **Registered:** <ISO-timestamp>
- **Last updated:** <ISO-timestamp>

## Current state

- **Phase:** <N> of <M> — "<phase-or-stage-name>"
  <!-- For refactor pre-curate, primitives pre-curate, and bugfix pre-plan, the `of <M>` portion -->
  <!-- is omitted: "Phase: <N> — <stage-name>". For bugfix the initial stage-name is "intake".   -->
  <!-- `update` preserves whichever form `start` rendered.                                       -->
- **Status:** <in-progress | completed | blocked | checkpoint>

## Phase history

| Phase | Name | Status | Started | Completed |
|-------|------|--------|---------|-----------|
| 1 | <name> | ✅ completed | <ts> | <ts> |

## Links

<!-- For Worktree-Type=feature, render the Plan/SRS/SDD/Plan-changelog lines (omit Findings,    -->
<!--   Bug report, Investigations).                                                              -->
<!-- For Worktree-Type=refactor pre-curate, render only the Findings line (omit the rest).      -->
<!-- For Worktree-Type=primitives pre-curate, same as refactor pre-curate.                      -->
<!-- For Worktree-Type=bugfix pre-plan, render Bug report, Investigations, Reproduction plan,    -->
<!--   and Implementation plan (omit SRS, SDD, Plan-changelog, Findings, and the generic Plan    -->
<!--   line — a bug fix has no specs and no refactor proposals, and uses the two-plan model:     -->
<!--   the reproduction plan and the final implementation plan; the transient                    -->
<!--   implementation-plan-draft.md is not linked).                                              -->
<!-- After the post-curate transition, `update` does not retroactively add the Plan link;       -->
<!-- orchestrator-level tooling owns that if desired.                                            -->

- Plan: `.project/cycles/<slug>/plans/implementation-plan.md`
- SRS: `.project/cycles/<slug>/specs/SRS.md`
- SDD: `.project/cycles/<slug>/specs/SDD.md`
- Plan changelog: `.project/cycles/<slug>/execution/plan-changelog.md`
- Findings: `.project/cycles/<slug>/refactor-proposals/`
- Bug report: `.project/cycles/<slug>/specs/bug-report.md`
- Investigations: `.project/cycles/<slug>/execution/code-investigations/`
- Reproduction plan: `.project/cycles/<slug>/plans/reproduction-plan.md`
- Implementation plan: `.project/cycles/<slug>/plans/implementation-plan.md`
```

---

Timestamps use ISO-8601 UTC (`2026-05-19T14:32:07Z`). Phase status glyphs for readability: `✅ completed`, `⏳ in-progress`, `🛑 blocked`, `⏸ checkpoint`. Rendering logic lives in `start.md` — this file is the template, not the rules.
