# Refactor-Plan Rules

Extends `base-rules.md` for `Target: refactor-plan` audits. The target artifact is `.project/cycles/<DD-MM-YYYY>-refactor-from-<parent-name>/plans/implementation-plan.md` (scout-and-refactor flow) or `.project/cycles/<DD-MM-YYYY>-primitives/plans/implementation-plan.md` (primitives flow).

## Sole-input check

Every plan phase traces to at least one approved finding by ID. The `approved.md` file (`.project/cycles/<slug>/refactor-proposals/pattern-approved.md`) is the sole source of work-item content.

### Verification protocol

1. Locate the approved-findings file. Plan tasks cite findings using identifiers (e.g., `CF-3`, `F-42`, `DF-7`) inside phase annotations or task bodies.
2. Read the cited `approved.md` (path resolved from a citation or from the plan's Meta).
3. For each phase, verify at least one finding ID is cited and that the cited ID exists in `approved.md`.

### Violations

- `PHASE_NO_FINDING_CITATION: Phase N` — phase cites no approved finding. **Severity:** ERROR. **Confidence:** HIGH.
- `PHASE_FINDING_NOT_FOUND: Phase N: <finding-id>` — phase cites a finding ID that does not exist in `approved.md`. **Severity:** ERROR. **Confidence:** HIGH.
- `APPROVED_FILE_NOT_FOUND: <path>` — cited `approved.md` does not resolve. **Severity:** CRITICAL. **Confidence:** HIGH.

## Convention-doc declarations

Phases that introduce new shared utilities (or modify existing ones such that the canonical `.project/knowledge/<type>/` documentation must change) declare the corresponding convention-doc updates as a separate task with `Concern: convention-doc`.

### Verification protocol

1. Identify phases whose tasks create or modify shared utilities (heuristic: `Target file(s)` in `src/shared/`, `src/utils/`, or any path covered by an existing `.project/knowledge/<type>/_index.md` row).
2. For each such phase, verify at least one task carries `Concern: convention-doc`.

### Violation

`MISSING_CONVENTION_DOC_TASK: Phase N` — phase introduces or modifies a shared utility without a `Concern: convention-doc` task. **Severity:** WARNING. **Confidence:** MEDIUM (heuristic — utility identification relies on path patterns; verify manually).

The `convention-doc` concern is orchestrator-routing: tasks bearing it dispatch to `state-manager` (`refactor-curation` mode) rather than to `developer`. Plan-auditor verifies the declaration; it does NOT verify state-manager's execution.

## ABSTRACT phase rules

Apply ONLY to phases whose header carries the `abstract-migration-phase` flag (tag emitted by `plan-architect`'s `targets/refactor-plan.md` for ABSTRACT migration phases).

### Cited-finding existence

The phase's inline ABSTRACT annotation cites a finding ID. Plan-auditor Reads the `approved.md` file referenced in the annotation and verifies the finding ID exists in it.

**Violation:** `ABSTRACT_FINDING_NOT_FOUND: <finding-id>` (Phase N) — **Severity:** CRITICAL. **Confidence:** HIGH.

### Cited-finding completeness

The cited APPROVE finding carries ALL fields required by `plan-architect`'s hard-gate precondition:

- `source-file`
- `source-function`
- `current-signature`
- `generalized-signature`
- `hard-gates` — both `type-and-contract-compatibility` and `migration-tractability` with PASS/FAIL per sub-check (including `migration-tractability.codemod-coverage-≥50%`)
- `scoring-axes` — `variant-count`, `shape-congruence`, `call-site-stability`, each with PASS/FAIL
- `verdict: APPROVE`
- `call-site-data` — `total`, `.ts`, `.svelte`, `uncertain`, plus per-call-site list (`file:line:column` entries)
- `stragglers` — explicit list (may be empty; MUST be present)
- `phase-splitting-recommendation` — `one-phase` or `two-phase`

**Violation:** `ABSTRACT_FINDING_INCOMPLETE: <finding-id>: missing <comma-separated fields>` (Phase N) — **Severity:** CRITICAL. **Confidence:** HIGH.

### Cited-finding verdict

The cited finding's `verdict` MUST be `APPROVE`. Any other value indicates curate failed to filter or plan-architect ignored the verdict.

**Violation:** `ABSTRACT_FINDING_NOT_APPROVED: <finding-id>: verdict=<actual>` (Phase N) — **Severity:** CRITICAL. **Confidence:** HIGH.

### Annotation/finding consistency

Values surfaced in the inline annotation MUST match the cited finding's corresponding fields exactly:

- Source file
- Source function
- Generalized signature
- Phase split (`one-phase` / `two-phase`)
- Call-site totals (`total`, `.ts`, `.svelte`, `uncertain`)
- Stragglers (file:line entries)

**Violation:** `ABSTRACT_ANNOTATION_DRIFT: <finding-id>: <field>: annotation=<a> finding=<f>` (Phase N) — **Severity:** ERROR. **Confidence:** HIGH.

### Phase-split execution

The plan's phase structure for the cited finding must match `phase-splitting-recommendation`:

- `one-phase` → exactly one `abstract-migration-phase` for that finding, containing T1–T5 in the same phase.
- `two-phase` → exactly two consecutive `abstract-migration-phase` phases for that finding: phase A with T1–T4 and phase B with T5 only.

Mismatches include wrong phase count, T5 in phase A, T1 in phase B, or non-consecutive A/B phases.

**Violation:** `ABSTRACT_PHASE_SPLIT_MISMATCH: <finding-id>` (Phase N) — **Severity:** ERROR. **Confidence:** HIGH.

## Out of scope

Plan-auditor does NOT re-run `find-call-sites.ts` to verify call-site counts. Call-site data is finding-content authored by `pattern-analyst`; the auditor verifies the plan's faithfulness to the finding, not the finding's freshness against HEAD. Drift between approved-time call-sites and review-time call-sites is caught later by `code-reviewer` (`ABSTRACT_MIGRATION_REVIEW` mode), which compares the codemod's modification count to the finding's totals.

Plan-auditor does NOT load `pattern-analyst`'s `references/abstract-migration.md`. The cited finding's `verdict: APPROVE` is trusted as the upstream signal; verdict re-derivation belongs to `pattern-analyst-auditor`, not this audit.
