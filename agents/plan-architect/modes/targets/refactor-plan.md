# Target: refactor-plan

**Artifact (location depends on flow):**

- Scout-and-refactor: `.project/cycles/<DD-MM-YYYY>-refactor-from-<parent-name>/plans/implementation-plan.md`.
- Primitives: `.project/cycles/<DD-MM-YYYY>-primitives/plans/implementation-plan.md`.

## Inputs (any action)

- `pattern-approved.md` at `.project/cycles/<slug>/refactor-proposals/pattern-approved.md` from the refactor/primitives cycle subdirectory. **Sole source of work-item content.** Every directive (REUSE, EXTRACT, ABSTRACT, REMOVE, RELOCATE, etc.) is read from this file. ABSTRACT findings carry the complete decision payload (see hard-gate precondition below); this target does NOT re-derive or re-evaluate any ABSTRACT decision.
- Reference-only: `.project/knowledge/architecture.md`, `.project/knowledge/overview.md`, `.project/knowledge/sitemap.md`, and any `.project/knowledge/<type>/_index.md` needed to ground file paths and invariants. These are reference inputs, not work-item sources.

## Output

The appropriate `implementation-plan.md` per the flow. Verb-noun task headers, per-task metadata, phase sizing per `essentials/phase-sizing.md`. Every plan phase traces to one or more approved findings by ID.

A `## Objective` section (the consolidation goal) sits above Phase 1; a `## Open Questions` section optionally when the refactor leaves user-facing questions. No Quick Reference, no Meta — the auditor resolves `approved.md` from per-phase finding citations.

The within-feature reusability pass that `feature-final` runs is NOT re-run here — the refactor IS the reuse consolidation event.

## Convention-doc declarations

When the refactor introduces new shared utilities or modifies existing ones, the plan declares the corresponding convention-doc updates as a separate phase task with `Concern: convention-doc`. The orchestrator dispatches `state-manager` (`refactor-curation` mode) per-phase for any phase carrying such a task — there is no "at-refactor-close" sweep.

## Pipeline role rules

Worktree-side writer + committer. The refactor runs inside the refactor or primitives worktree.

- Never write `ROADMAP.md` or anything under `.project/product/cycles-in-progress/`.
- If a three-way merge conflicts on those paths, take main unconditionally — a worktree-side change there is a bug to investigate, not text to merge.
- After a successful write, commit the plan path-scoped: Read `.claude/skills/commit-to-git/SKILL.md` and follow it, passing `Agent: plan-architect`, the path of the refactor `implementation-plan.md` written (per the flow above), and the subject — `plan(<slug>): add refactor plan` for `create`, `plan(<slug>): revise refactor plan` for `update` (`<slug>` = basename of the refactor/primitives feature directory).

## ABSTRACT finding hard-gate precondition

Before authoring any plan phase derived from an `approved.md` finding whose `directive` is `ABSTRACT`, verify that the finding carries ALL fields below. Missing any field fails the entire dispatch with `ABSTRACT_FINDING_INCOMPLETE: <finding-id>: missing <comma-separated field list>` and writes nothing. The precondition is per-finding; one missing field fails the dispatch so the upstream (pattern-analyst or pattern-analyst-auditor) can revise.

Required fields per ABSTRACT finding:

- `source-file` — path of the existing narrow utility.
- `source-function` — name of the existing function/symbol.
- `current-signature` — the narrow utility's current signature.
- `generalized-signature` — the proposed generalized signature.
- `hard-gates` — both `type-and-contract-compatibility` and `migration-tractability` sub-fields, each with PASS/FAIL labels for every sub-check the matrix defines (see `pattern-analyst`'s `references/abstract-migration.md`).
- `scoring-axes` — all three of `variant-count`, `shape-congruence`, `call-site-stability` with PASS/FAIL labels (at least 2 must be PASS for an `APPROVE` verdict to be valid).
- `verdict` — must be `APPROVE`. Any other value indicates curate failed to filter the finding; refuse with `ABSTRACT_FINDING_NOT_APPROVED: <finding-id>`.
- `call-site-data` — totals (`total`, `.ts`, `.svelte`, `uncertain`) plus per-call-site lists (`file:line:column` entries) sourced from `pattern-analyst`'s `find-call-sites.ts` run.
- `stragglers` — explicit list of `file:line` entries the codemod cannot transform (may be empty list, MUST NOT be absent).
- `phase-splitting-recommendation` — exactly one of `one-phase` (codemod coverage ≥80%, codemod + manual stragglers in the same phase) or `two-phase` (codemod coverage in `50% ≤ x < 80%`, separate codemod phase then manual cleanup phase). The hard-gate threshold is ≥50%; 80% is the one-phase vs two-phase split, NOT the gate.

## ABSTRACT phase generation mechanic

For each ABSTRACT finding that passes the precondition:

1. Generate one or two migration phases per the finding's `phase-splitting-recommendation`:
   - `one-phase`: a single phase containing the standard five-task ABSTRACT migration spine (T1–T5) that the `developer` executes.
   - `two-phase`: phase A with T1–T4 (codemod authoring + execution + build), phase B with T5 only (manual straggler cleanup, explicit straggler list). If phase A's T4 build succeeds with no stragglers captured at runtime, the orchestrator skips phase B and advances.
2. Tag every generated phase header with the `abstract-migration-phase` flag so the orchestrator dispatches `code-reviewer` in `ABSTRACT_MIGRATION_REVIEW` mode.
3. Write an inline annotation immediately above each generated phase header citing the finding ID and surfacing only the data developers and reviewers need at the header. Full gate evaluations are NOT restated — they live in `approved.md` and plan-auditor verifies them against the cited finding ID.

## Inline ABSTRACT annotation format (canonical)

```markdown
## Phase 5: ABSTRACT migration — generalize add()
<!-- ABSTRACT directive applied per approved finding CF-3
  Source: .project/cycles/<slug>/refactor-proposals/pattern-approved.md#CF-3
  Source file: src/shared/math/add.ts
  Source function: add
  Generalized signature: (operator: '+'|'-'|'*'|'/', a: number, b: number) => number
  Phase split: one-phase (per finding's phase-splitting-recommendation)
  Call-site totals (per finding's call-site-data): total=32, .ts=27, .svelte=5, uncertain=2
  Stragglers (manual T5, per finding's stragglers field): src/legacy/dynamicLoad.ts:42, src/legacy/dynamicLoad.ts:78
-->
T1. ...
```

The annotation is informational; the authoritative payload for verification is the cited approved finding. Mismatch between annotation and finding is a defect plan-auditor catches when it verifies each annotation against its cited approved finding.

### When Mode: create

**Mechanic.** Single-pass authoring from `approved.md`. Validate each ABSTRACT finding's required fields per the hard-gate precondition; on any failure, return the error without writing. Then translate each approved finding into one or more plan phases per the writing discipline. For ABSTRACT findings, apply the ABSTRACT phase generation mechanic above.

### When Mode: update

**Additional inputs:** the existing refactor `implementation-plan.md` plus an amended `approved.md` (when curate revisits the cycle) or test-runner failures requiring plan revision.

**Mechanic.** Revise the existing refactor `implementation-plan.md` to reflect the amendment. Re-validate every ABSTRACT finding in the amended `approved.md` against the hard-gate precondition (a curate revisit may have introduced or removed fields). Preserve phase headers whose corresponding approved findings are unchanged.

## Errors

- `ABSTRACT_FINDING_INCOMPLETE: <finding-id>: missing <fields>` — required ABSTRACT field absent.
- `ABSTRACT_FINDING_NOT_APPROVED: <finding-id>` — `verdict` is not `APPROVE`.
- `MISSING_APPROVED: <slug>` — `pattern-approved.md` absent at the cited path.
- `MISSING_REFACTOR_PLAN: <slug>` — refactor `implementation-plan.md` absent at the `update` action's precondition check.
