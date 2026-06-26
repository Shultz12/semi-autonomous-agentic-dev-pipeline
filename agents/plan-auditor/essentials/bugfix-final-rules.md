# Bugfix-Final Rules

Extends `base-rules.md` for `Target: bugfix-final` audits. The target artifact is `.project/cycles/<slug>/plans/implementation-plan.md` — the second pass of the two-pass fix plan, a copy of the audited draft augmented with within-cycle REUSE / EXTRACT directives. This is the audit point at which the fix plan must demonstrate it is grounded in a usable investigation and that it only added to the audited draft.

The final preserves the draft's `## Objective`, so the full-audit plan-header check applies: `MISSING_OBJECTIVE` (ERROR, plan-level) when it is absent or empty.

## Two-pass plan check

The final is a copy of the draft plus additive directives — never a rewrite. Both files MUST exist in `.project/cycles/<slug>/plans/`:

- `implementation-plan-draft.md`
- `implementation-plan.md`

The final differs from the draft only by ADDITIONS:

- Every task header in the draft appears verbatim in the final (same line text).
- `Acceptance`, `Concern`, and `Target file(s)` fields on existing draft tasks are unchanged.
- New phases may be inserted before, between, or after draft phases.
- REUSE annotations (e.g., an `import from <path>` line) may be inserted INSIDE a draft task body, but never on the existing lines themselves.
- EXTRACT directives may insert a new earlier phase that later phases consume.

### Verification protocol

1. Read both files.
2. For each draft task header (verb-noun line), Grep the final for the verbatim header. Absence → violation.
3. For each draft task, compare `Acceptance`, `Concern`, and `Target file(s)` field values between draft and final. Any value change → violation.

### Violations

- `MISSING_DRAFT_PLAN: <slug>` — draft file absent. **Severity:** CRITICAL. **Confidence:** HIGH.
- `MISSING_FINAL_PLAN: <slug>` — final file absent. **Severity:** CRITICAL. **Confidence:** HIGH.
- `DRAFT_TASK_REWRITTEN: Phase N, Task N.M` — draft task header text changed in final. **Severity:** ERROR. **Confidence:** HIGH.
- `DRAFT_METADATA_CHANGED: Phase N, Task N.M: <field>` — `Acceptance` / `Concern` / `Target file(s)` value changed between draft and final. **Severity:** ERROR. **Confidence:** HIGH.

This rule is cross-phase by construction (compares two files). It runs in `full-audit` only; `phase-audit` skips it.

## Investigation-resolved check

Every investigation file the plan cites — at the plan header or referenced by a task — exists and carries a usable verdict. A `LEVEL_1` or `LEVEL_2` verdict is usable as authored; a `LEVEL_3` or `LEVEL_4` verdict is usable only once `code-investigator` resolution mode has recorded `resolved: true` in the file's frontmatter. A fix plan built on an unresolved high-severity investigation is planning against an unsettled cause.

### Verification protocol

1. Collect every investigation path cited in the plan (header citation and per-task references).
2. For each, Read the file. Absent or unreadable → violation.
3. Read the frontmatter severity verdict. `LEVEL_1` / `LEVEL_2` → usable. `LEVEL_3` / `LEVEL_4` → require `resolved: true` in the frontmatter; absent → violation.

**Violation:** `INVESTIGATION_UNRESOLVED: <investigation-path>` — a cited investigation is missing, unreadable, or carries a `LEVEL_3`/`LEVEL_4` verdict without `resolved: true`. **Severity:** CRITICAL. **Confidence:** HIGH.

## REUSE-directive grounding

Every REUSE directive lives inside a task body and names a real, existing symbol with its file path; the cited path resolves at HEAD via Glob.

**Violation:** `REUSE_PATH_NOT_FOUND: <path>` (Phase N, Task N.M) — a REUSE directive cites a path that does not resolve, or appears with no task that applies it (an orphan annotation). **Severity:** ERROR. **Confidence:** HIGH.

## EXTRACT-directive sanity

Every EXTRACT directive names a source and a destination and is consumed by at least one later task; the extraction is reflected in the task list, not left as a floating annotation. A single-consumer EXTRACT is premature abstraction.

**Violation:** `EXTRACT_NO_CONSUMER: Phase N` — the extracted util has no downstream consumer in a later phase, or the directive is orphaned (no task applies it). **Severity:** WARNING. **Confidence:** MEDIUM (heuristic — EXTRACT identification relies on pattern recognition; verify manually).

## ABSTRACT deferral

This rule mirrors `feature-final-rules.md`: `bugfix-final` emits REUSE/EXTRACT directives only and never authors ABSTRACT. ABSTRACT directives are emitted exclusively by `Target: refactor-plan` (sourced from `pattern-analyst`).

- The `<!-- ABSTRACT-deferred: candidate identified; deferred to a later refactor cycle -->` marker is INFORMATIONAL and **allowed** — a bug fix seeds no scout cycle of its own, so it records a candidate for a *later* refactor cycle (a subsequent feature's whole-codebase convergence-scout, or a user-initiated refactor cycle).
- Any `abstract-migration-phase` phase flag, or any `<!-- ABSTRACT directive applied... -->` annotation, is **disallowed**.

Distinguish by prefix: `ABSTRACT-deferred:` (allowed) vs `ABSTRACT directive applied` (disallowed).

### Verification protocol

1. Grep the plan for `abstract-migration-phase`. Any match → violation.
2. Grep the plan for `<!-- ABSTRACT directive applied`. Any match → violation.
3. Grep the plan for `<!-- ABSTRACT-deferred:`. Matches are allowed and not reported.

**Violation:** `ABSTRACT_IN_BUGFIX_FINAL_DISALLOWED: Phase N` — an applied-ABSTRACT artifact appears in a bugfix-final plan. **Severity:** ERROR. **Confidence:** HIGH.

## Self-Check

Before returning, run the self-check protocol in `essentials/self-check.md` against every CRITICAL and ERROR finding.
