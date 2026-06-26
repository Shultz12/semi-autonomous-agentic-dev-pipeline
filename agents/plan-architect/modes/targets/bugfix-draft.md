# Target: bugfix-draft

**Artifact:** `.project/cycles/<slug>/plans/implementation-plan-draft.md`.

First pass of the Stage 2 two-pass fix plan. Authors the fix as plain phased tasks derived from the investigation(s); reuse directives are added later by `bugfix-final`.

## Inputs (any action)

- `Bug Report:` — `<Cycle Path>/specs/bug-report.md` (required). Supplies the plan's `## Objective` (the intended-vs-actual behavior the fix restores).
- `Investigation Files:` — one or more paths under `<Cycle Path>/execution/code-investigations/` (required). **The sole content-source for the fix** — every fix phase traces to a documented root cause, not to assumption.
- `.project/knowledge/architecture.md`, `.project/knowledge/overview.md`, `.project/knowledge/sitemap.md`.
- `.project/knowledge/tech-stack/charter.md` — the approved-technology allowlist, read from the **main root** (main-canonical). The fix may only assume Approved technologies; this keeps a bug fix from drifting onto off-charter tech or reinventing capability the charter already sanctions. If the charter is absent, treat it as "no constraint" and emit a WARNING in the plan `## Objective`.
- `.claude/agents/developer/essentials/<dev-type>/knowledge-map.md` for each `<dev-type>` the fix touches.

This target reads no SRS, SDD, or BDD — the bug-fix flow operates on pure code, anchored by the bug report and the investigation(s).

## Output

`.project/cycles/<slug>/plans/implementation-plan-draft.md`:

- A `## Objective` section (1–2 sentences from the bug report) above Phase 1. `## Open Questions` only when planning surfaced one. No Quick Reference, no Meta.
- Tasks organized into phases. Verb-noun headers per `essentials/allowed-verbs.md`; per-task metadata block (`Target file(s)`, `Acceptance`, `Concern`, `Effort`) per `essentials/writing-discipline.md`. No REUSE / EXTRACT / ABSTRACT directives at this pass.
- Each phase carries `Developer: backend | frontend | infrastructure | test`.
- Phase boundaries per `essentials/phase-sizing.md`. An over-budget phase is **split**, never shrunk.

### Reproduction-test ordering invariant

When the fix spans many files, or the bug report bundled multiple distinct symptoms, decompose into phases ordered so that **each bug's reproduction test flips GREEN at exactly one phase**. Earlier phases may leave that bug's reproduction test RED, but must not cause any **other** test to start failing. Every phase stands as an independently reviewable unit that keeps the suite green except for the not-yet-fixed reproduction test(s).

## Preservation guarantee

Once written, `implementation-plan-draft.md` is preserved untouched by every `bugfix-final` pass — it is the audit reference for the draft-vs-final diff. Only the `update` action against this target may modify it.

## Pipeline role rules

Worktree-side writer + committer. The fix plan is authored inside the bugfix worktree.

- Never write `ROADMAP.md` or anything under `.project/product/cycles-in-progress/`.
- If a three-way merge conflicts on those paths, take main unconditionally — a worktree-side change there is a bug to investigate, not text to merge.
- After a successful write, commit path-scoped via `.claude/skills/commit-to-git/SKILL.md`, passing `Agent: plan-architect`, the path `.project/cycles/<slug>/plans/implementation-plan-draft.md`, and the subject — `plan(<slug>): add bugfix plan draft` for `create`, `plan(<slug>): revise bugfix plan draft` for `update`.

### When Mode: create

**Mechanic.** Build the draft from scratch, deriving fix phases from the investigation(s) and the bug report. Apply the writing discipline. No reuse analysis at this stage — directive annotations are added later by `bugfix-final`.

### When Mode: update

**Additional inputs:** the existing `implementation-plan-draft.md` and the trigger — a deeper re-investigation (mid-fix deepening) or an audit finding.

**Mechanic.** Rewrite the draft reflecting the trigger. The subsequent `bugfix-final` pass rebuilds from the updated draft.

## Errors

- `MISSING_BUG_REPORT: <path>` — `bug-report.md` absent.
- `MISSING_INVESTIGATION: <path>` — no investigation file present at the cited path(s); the fix has no documented cause to plan from.
- `TECH_NOT_IN_CHARTER: <need>` — the prescribed fix forces a technology not Approved in the charter. Write nothing; the orchestrator surfaces it for resolution via `/tech-stack-architect unblock`.
