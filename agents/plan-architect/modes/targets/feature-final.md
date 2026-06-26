# Target: feature-final

**Artifact:** `.project/cycles/<cycle>/plans/implementation-plan.md`.

## Inputs (any action)

- `.project/cycles/<cycle>/plans/implementation-plan-draft.md` (preserved).
- `.project/knowledge/tech-stack/charter.md` — the approved technology allowlist, read from the **main root** (main-canonical, never a worktree copy). Reuse analysis assumes only Approved technologies — neither a REUSE import nor an EXTRACT util may rest on an off-charter dependency. The charter-absent WARNING is authored once in the draft `## Objective` and copied through unchanged; this target does not re-author it.
- Every `.project/knowledge/<type>/_index.md`.
- Convention bodies on candidate token-overlap match.

This target does NOT run `find-call-sites.ts` and does NOT evaluate ABSTRACT viability. All ABSTRACT decisions belong to `pattern-analyst` (post-merge, scout-and-refactor flow). `feature-final` is restricted to within-feature reuse analysis only.

## Output

`.project/cycles/<cycle>/plans/implementation-plan.md` — the final plan with inline directive annotations for **REUSE** and **EXTRACT** only.

## Responsibilities (any action)

1. Tokenize each draft task's verb-noun header and metadata for matching.
2. Read every `.project/knowledge/<type>/_index.md`. For each candidate row whose token-overlap with a draft task is non-empty, Read the convention body to confirm signature/contract.
3. Identify reuse opportunities across two categories:
   - **REUSE** — import an existing util into a task body.
   - **EXTRACT** — pattern observed across this feature's own tasks; create a shared util in an early phase, consume in later phases.
4. Apply directives per the per-action mechanic.

## ABSTRACT-deferred handling

If a candidate looks like ABSTRACT (existing util is parametrically narrow vs. the feature's need), record it as a comment and emit a REUSE directive against the narrow util OR an EXTRACT directive for a feature-local util:

```
<!-- ABSTRACT-deferred: candidate identified; deferred to post-merge refactor cycle -->
```

The post-merge `pattern-analyst convergence-scout` cycle detects the resulting duplication and proposes ABSTRACT in the next refactor cycle. The `ABSTRACT-deferred:` prefix is distinct from the `ABSTRACT directive applied...` annotation emitted by `refactor-plan`; plan-auditor allows the deferral comment in a feature-final plan and rejects an applied-ABSTRACT annotation there.

## Output discipline

The `## Objective` (and `## Open Questions`, if present) authored in the draft are copied to the final unchanged along with all task content; `feature-final` adds only REUSE/EXTRACT task annotations and never authors or alters the header. Audit signals: (a) both `implementation-plan-draft.md` and `implementation-plan.md` exist; (b) the diff between draft and final shows only additive REUSE/EXTRACT directives — no rewrites of draft task headers or metadata.

## Pipeline role rules

Design-time writer + committer in both contexts: main-side on main, worktree-side inside `.worktrees/<cycle>/`.

**Main-side.** Check for `<main-root>/.worktrees/<cycle-slug>/` before editing. If present, refuse with `WORKTREE_ACTIVE: <cycle>` — the worktree was cut against the current base and changing it underneath invalidates the running plan. This guard gates only main-side design-time edits; it does not block the worktree-side commit path.

**Worktree-side.** Never write `ROADMAP.md` or anything under `.project/product/cycles-in-progress/`. If a three-way merge ever conflicts on those paths, take main unconditionally — a worktree-side change there is a bug to investigate, not text to merge.

**Commit (either context).** After a successful write, commit the plan path-scoped: Read `.claude/skills/commit-to-git/SKILL.md` and follow it, passing `Agent: plan-architect`, the path `.project/cycles/<cycle>/plans/implementation-plan.md`, and the subject — `plan(<slug>): add implementation plan` for `create`, `plan(<slug>): revise implementation plan` for `update` (`<slug>` = basename of `<cycle>`).

### When Mode: create

**Precondition.** `implementation-plan-draft.md` MUST exist at `.project/cycles/<cycle>/plans/implementation-plan-draft.md`. If absent, fail fast with `MISSING_DRAFT_PLAN: <cycle>` and write nothing. (The base `create` precondition — that `implementation-plan.md` does NOT exist — also applies.)

**Mechanic.** COPY `implementation-plan-draft.md` to `implementation-plan.md`, then MUTATE the copy in place by adding REUSE/EXTRACT directives. Never remove or rewrite draft tasks. REUSE inserts `import from <path>` into a task body. EXTRACT inserts a new earlier phase that later phases consume. ABSTRACT is NEVER inserted by this mechanic; no `abstract-migration-phase` flag is tagged.

### When Mode: update

**Precondition.** Both `implementation-plan-draft.md` AND `implementation-plan.md` MUST exist. Missing either fails with `MISSING_DRAFT_PLAN: <cycle>` or `MISSING_FINAL_PLAN: <cycle>` respectively and writes nothing.

**Additional inputs:** the existing `implementation-plan.md` plus the optionally revised `implementation-plan-draft.md`.

**Mechanic.** Re-run the directive analysis against the current draft. Replace or extend REUSE/EXTRACT directives where context has shifted; preserve any directive whose conclusion remains valid.

## Errors

- `MISSING_DRAFT_PLAN: <cycle>` — draft absent at precondition check.
- `MISSING_FINAL_PLAN: <cycle>` — final absent during `Mode: update`.
- `WORKTREE_ACTIVE: <cycle>` — active worktree blocks design-time edit on main.
- `TECH_NOT_IN_CHARTER: <need>` — a REUSE or EXTRACT directive would rest on a technology that is not Approved in `.project/knowledge/tech-stack/charter.md`. Write no plan and return this error so the orchestrator can surface it to the user, who resolves it via `/tech-stack-architect unblock`. `<need>` is specific (`archiver`) when named, or descriptive (`ZIP archive generation library`) when only the capability is implied.
- `ABSTRACT_IN_FEATURE_FINAL` — internal guard: this target's mechanic emitted an `abstract-migration-phase` flag or `ABSTRACT directive applied...` annotation. Aborts the write.
