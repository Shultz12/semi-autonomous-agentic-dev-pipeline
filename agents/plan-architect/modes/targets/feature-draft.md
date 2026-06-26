# Target: feature-draft

**Artifact:** `.project/cycles/<cycle>/plans/implementation-plan-draft.md`.

## Inputs (any action)

- `.project/knowledge/architecture.md`
- `.project/knowledge/overview.md`
- `.project/knowledge/sitemap.md`
- `.project/knowledge/tech-stack/charter.md` — the approved technology allowlist, read from the **main root** (the charter is main-canonical, never a worktree copy). Plan phases may only assume technologies the charter lists as Approved. If the charter is absent, treat it as "no constraint" and emit a WARNING in the plan `## Objective` that no charter exists.
- The Developer-Type knowledge map at `.claude/agents/developer/essentials/<dev-type>/knowledge-map.md` for each `<dev-type>` the feature touches (sanity-check stack assumptions).

## Output

The draft plan at the path above:

- A `## Objective` section (1–2 sentences, derived from the SRS) above Phase 1. A `## Open Questions` section only when the SRS/BDD/SDD left unresolved questions for the user; omit otherwise. No Quick Reference, no Meta.
- Verb-noun task headers per `essentials/allowed-verbs.md`.
- Per-task metadata block (`Target file(s)`, `Acceptance`, `Concern`) per `essentials/writing-discipline.md`.
- Phase boundaries per `essentials/phase-sizing.md`.
- Each phase carries a `Developer:` field naming one of `backend`, `frontend`, `infrastructure`, `test`.

## Preservation guarantee

Once written, `implementation-plan-draft.md` is preserved untouched by every subsequent pass — including every `feature-final` invocation. The draft is the audit reference for the diff against the final plan, which plan-auditor checks by comparing the draft against the final. Only the `update` action against this same target may modify it, and only when the upstream spec has changed.

## Pipeline role rules

Design-time writer + committer in both contexts: main-side on main, worktree-side inside `.worktrees/<cycle>/`.

**Main-side.** Before editing the draft on main, check for an active worktree at `<main-root>/.worktrees/<cycle-slug>/`. If one exists, refuse with `WORKTREE_ACTIVE: <cycle>`. The worktree was cut against a specific base; changing it underneath silently invalidates the running plan. The caller decides whether to finish the run and amend post-acceptance or run `/abandon-feature` and restart. This guard gates only main-side design-time edits — it does not block the worktree-side commit path below.

**Worktree-side.** Never write `ROADMAP.md` or anything under `.project/product/cycles-in-progress/`. If a three-way merge ever conflicts on those paths, take main unconditionally — a worktree-side change there is a bug to investigate, not text to merge.

**Commit (either context).** After a successful write, commit the draft path-scoped: Read `.claude/skills/commit-to-git/SKILL.md` and follow it, passing `Agent: plan-architect`, the path `.project/cycles/<cycle>/plans/implementation-plan-draft.md`, and the subject — `plan(<slug>): add implementation plan draft` for `create`, `plan(<slug>): revise implementation plan draft` for `update` (`<slug>` = basename of `<cycle>`).

### When Mode: create

**Additional inputs:** SRS + BDD + SDD at `.project/cycles/<cycle>/specs/`.

**Mechanic.** Build the draft from scratch, deriving phases from the SRS/BDD/SDD content and project context. Apply the writing discipline. No reuse analysis at this stage — directive annotations are added later by `feature-final`.

### When Mode: update

**Additional inputs:** the existing `implementation-plan-draft.md` and the revised SRS, BDD, or SDD (the trigger is a spec deviation or design revision).

**Mechanic.** Rewrite `implementation-plan-draft.md` reflecting the revised spec. Subsequent `feature-final` invocations rebuild from the updated draft.

## Errors

- `MISSING_SPECS: <missing files>` — any of SRS, BDD CONTEXT, BDD `.feature` files, or SDD absent at `Mode: create`.
- `MISSING_DRAFT: <cycle>` — draft absent at the `update` action's base precondition check.
- `WORKTREE_ACTIVE: <cycle>` — active worktree blocks design-time edit on main.
- `TECH_NOT_IN_CHARTER: <need>` — the SDD or requirements force a technology (framework, library, external service) that is not Approved in `.project/knowledge/tech-stack/charter.md`. Write no plan and return this error so the orchestrator can surface it to the user, who resolves it via `/tech-stack-architect unblock`. `<need>` is specific (`archiver`) when the SDD named it, or descriptive (`ZIP archive generation library`) when only the capability is implied.
