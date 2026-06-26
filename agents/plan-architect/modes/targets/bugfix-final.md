# Target: bugfix-final

**Artifact:** `.project/cycles/<slug>/plans/implementation-plan.md`.

Second pass of the Stage 2 two-pass fix plan. Copies the audited draft and augments it with within-cycle reuse directives — because the root cause is sometimes duplicated functionality or a missing shared abstraction, and the cleanest fix is to consolidate rather than patch in place.

## Inputs (any action)

- `Plan Draft Path:` — `.project/cycles/<slug>/plans/implementation-plan-draft.md` (required, preserved).
- `Investigation Files:` — the same set passed to the draft pass (required).
- `Bug Report:` — `<Cycle Path>/specs/bug-report.md` (required).
- `.project/knowledge/tech-stack/charter.md` — the approved-technology allowlist, read from the **main root** (main-canonical). Neither a REUSE import nor an EXTRACT util may rest on an off-charter dependency. The charter-absent WARNING authored in the draft `## Objective` is copied through unchanged; this target does not re-author it.
- Every `.project/knowledge/<type>/_index.md`; convention bodies on candidate token-overlap match.
- `.claude/agents/developer/essentials/<dev-type>/knowledge-map.md` per dev-type touched.

This target reads no SRS, SDD, or BDD. It does NOT run `find-call-sites.ts` and does NOT evaluate ABSTRACT viability — all ABSTRACT decisions belong to `pattern-analyst` (post-merge refactor cycle). `bugfix-final` is restricted to within-cycle REUSE / EXTRACT analysis.

## Output

`.project/cycles/<slug>/plans/implementation-plan.md` — the final fix plan with inline directive annotations for **REUSE** and **EXTRACT** only.

## Responsibilities (any action)

1. Tokenize each draft task's verb-noun header and metadata for matching.
2. Read every `.project/knowledge/<type>/_index.md`. For each candidate row whose token-overlap with a draft task is non-empty, Read the convention body to confirm signature/contract.
3. Identify reuse opportunities in two categories:
   - **REUSE** — import an existing util into a task body.
   - **EXTRACT** — pattern observed across this fix's own tasks; create a shared util in an early phase, consume in later phases.
4. Apply directives per the per-action mechanic.

## ABSTRACT-deferred handling

If a candidate looks like ABSTRACT (an existing util is parametrically narrow vs. the fix's need), record it as a comment and emit a REUSE directive against the narrow util OR an EXTRACT directive for a cycle-local util:

```
<!-- ABSTRACT-deferred: candidate identified; deferred to a later refactor cycle -->
```

Unlike a feature — whose completion seeds a post-merge `pattern-analyst convergence-scout` over its own merge — a bug fix seeds **no** scout cycle of its own (`Scout-status` stays `n/a`; see `progress-tracker`). The deferred candidate is a breadcrumb only: the leftover duplication is consolidated opportunistically — when a *later* feature's post-merge `convergence-scout` re-scans the whole codebase at HEAD (if the cluster still meets that scout's duplication thresholds), or when the user launches a refactor/primitives cycle manually. The `ABSTRACT-deferred:` prefix is distinct from the `ABSTRACT directive applied...` annotation emitted only by `refactor-plan`; plan-auditor allows the deferral comment here and rejects an applied-ABSTRACT annotation.

## Output discipline

The `## Objective` (and `## Open Questions`, if present) authored in the draft are copied to the final unchanged along with all task content; `bugfix-final` adds only REUSE/EXTRACT task annotations and never authors or alters the header. Audit signals: (a) both `implementation-plan-draft.md` and `implementation-plan.md` exist; (b) the diff between draft and final shows only additive REUSE/EXTRACT directives — no rewrites of draft task headers or metadata.

### Reproduction-test ordering invariant

Any phase inserted or renumbered by directive analysis (e.g., an EXTRACT phase) must preserve the draft's ordering invariant — each bug's reproduction test still flips GREEN at exactly one phase, and no phase introduces a new failure in an unrelated test.

## Pipeline role rules

Worktree-side writer + committer. The final fix plan is authored inside the bugfix worktree.

- Never write `ROADMAP.md` or anything under `.project/product/cycles-in-progress/`.
- If a three-way merge conflicts on those paths, take main unconditionally — a worktree-side change there is a bug to investigate, not text to merge.
- After a successful write, commit path-scoped via `.claude/skills/commit-to-git/SKILL.md`, passing `Agent: plan-architect`, the path `.project/cycles/<slug>/plans/implementation-plan.md`, and the subject — `plan(<slug>): add bugfix plan` for `create`, `plan(<slug>): revise bugfix plan` for `update`.

### When Mode: create

**Precondition.** `implementation-plan-draft.md` MUST exist at the `Plan Draft Path`. If absent, fail fast with `MISSING_DRAFT_PLAN: <slug>` and write nothing. (The base `create` precondition — that `implementation-plan.md` does NOT exist — also applies.)

**Mechanic.** COPY the draft to `implementation-plan.md`, then MUTATE the copy in place by adding REUSE/EXTRACT directives. Never remove or rewrite draft tasks. REUSE inserts `import from <path>` into a task body; EXTRACT inserts an earlier phase that later phases consume. ABSTRACT is NEVER inserted by this mechanic; no `abstract-migration-phase` flag is tagged.

### When Mode: update

**Precondition.** Both `implementation-plan-draft.md` AND `implementation-plan.md` MUST exist. Missing either fails with `MISSING_DRAFT_PLAN: <slug>` or `MISSING_FINAL_PLAN: <slug>` respectively and writes nothing.

**Additional inputs:** the existing `implementation-plan.md` plus the optionally revised `implementation-plan-draft.md`.

**Mechanic.** Re-run the directive analysis against the current draft; replace or extend REUSE/EXTRACT directives where context shifted, preserving any directive whose conclusion remains valid.

## Errors

- `MISSING_DRAFT_PLAN: <slug>` — draft absent at precondition check.
- `MISSING_FINAL_PLAN: <slug>` — final absent during `Mode: update`.
- `MISSING_INVESTIGATION: <path>` — investigation file(s) absent.
- `TECH_NOT_IN_CHARTER: <need>` — a REUSE or EXTRACT directive would rest on a technology not Approved in the charter. Write nothing; surfaced via `/tech-stack-architect unblock`.
- `ABSTRACT_IN_BUGFIX_FINAL` — internal guard: this target's mechanic emitted an `abstract-migration-phase` flag or `ABSTRACT directive applied...` annotation. Aborts the write.
