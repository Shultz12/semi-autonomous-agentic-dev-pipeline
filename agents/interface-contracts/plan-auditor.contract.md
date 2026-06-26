# plan-auditor Interface Contract

## Input

**Required fields in the dispatch prompt:**

```
Plan Path: <path to plan file>
Target: feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final
Mode: full-audit | phase-audit          (optional; defaults to full-audit)
Phase: <N>                              (required when Mode: phase-audit)
```

`feature-draft` is audited with `base-rules` only (plus the `## Objective` header check), catching verb / concern / metadata / sizing / path defects before `feature-final` copies the draft's task headers verbatim. The two-pass diff and the REUSE/EXTRACT/ABSTRACT checks are deferred to the `feature-final` audit — a draft has no final to diff and carries no directives.

**Example — draft audit (the first gate, before the final is generated):**

```
Validate the plan at: .project/cycles/06-02-2026-user-auth/plans/implementation-plan-draft.md
Target: feature-draft
```

**Example — full audit of a feature-final plan:**

```
Validate the plan at: .project/cycles/06-02-2026-user-auth/plans/implementation-plan.md
Target: feature-final
```

**Example — phase audit after plan-architect (Mode: update) revised one phase:**

```
Validate the plan at: .project/cycles/06-02-2026-user-auth/plans/implementation-plan.md
Target: feature-final
Mode: phase-audit
Phase: 3
```

**Example — refactor-plan audit:**

```
Validate the plan at: .project/cycles/19-04-2026-refactor-from-user-auth/plans/implementation-plan.md
Target: refactor-plan
```

**Example — bugfix reproduction-plan audit (Stage 1):**

```
Validate the plan at: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/plans/reproduction-plan.md
Target: bugfix-reproduction
```

**Example — bugfix draft-plan audit (Stage 2, pass 1):**

```
Validate the plan at: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/plans/implementation-plan-draft.md
Target: bugfix-draft
```

**Example — bugfix final-plan audit (Stage 2, pass 2):**

```
Validate the plan at: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/plans/implementation-plan.md
Target: bugfix-final
```

## Output

### VALID

```
Status: VALID
Target: [feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final]
Plan: [plan file path]
Report: [report file path]
Issues: 0 critical, 0 errors, [N] warnings, [N] info

[Optional warnings/info listed here]
```

`phase-audit` mode adds a `Phase: <N>: [phase-name]` line below `Plan:`.

### INVALID (full-audit)

```
Status: INVALID
Target: [feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final]
Plan: [plan file path]
Report: [report file path]
Issues: [N] critical, [N] errors, [N] warnings, [N] info

Issues:
1. [SEVERITY] (HIGH|MEDIUM) [Code] — Location: [Phase N, Task N.M | plan-level | <table>]
   [violation description]
   Suggestion: [how to fix]
   [If MEDIUM: "Heuristic — verify manually"]
…
```

### INVALID (phase-audit) — with Problem Report

```
Status: INVALID
Target: [feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final]
Plan: [plan file path]
Phase: <N>: [phase-name]
Report: [report file path]
Issues: [N] critical, [N] errors, [N] warnings, [N] info

Problem Report:
**Reporter:** plan-auditor
**Target:** [plan file path]
**Phase:** <N>: [phase-name]
**Task:** [N.M] | "Phase-level"
**Type:** AMBIGUITY | MISSING_REFERENCE | CONTRADICTION | INVALID_STRUCTURE
**Severity:** BLOCKING
**Confidence:** HIGH | MEDIUM

### Problem
[description, with the rule's identifier code (e.g., `UNDOCUMENTED_VERB`)]

### Evidence
- [tool-backed references]

### Attempted Resolution
N/A
```

The Problem Report format matches what `plan-architect` (`Mode: update`) expects as input on its next revision pass.

### Written Report

Written to:

| Target | Path |
|--------|------|
| `feature-draft` | `<feature-dir>/plans/plan-audit/draft/plan-audit-report-attempt-<K>.md` |
| `feature-final` | `<feature-dir>/plans/plan-audit/plan-audit-report-attempt-<K>.md` |
| `test-plan` | `<feature-dir>/plans/test-plans/plan-audit/plan-audit-report-attempt-<K>.md` |
| `refactor-plan` | `<feature-dir>/plans/plan-audit/plan-audit-report-attempt-<K>.md` |
| `bugfix-reproduction` | `<feature-dir>/plans/plan-audit/bugfix-reproduction/plan-audit-report-attempt-<K>.md` |
| `bugfix-draft` | `<feature-dir>/plans/plan-audit/bugfix-draft/plan-audit-report-attempt-<K>.md` |
| `bugfix-final` | `<feature-dir>/plans/plan-audit/bugfix-final/plan-audit-report-attempt-<K>.md` |

`phase-audit` mode prefixes the filename with `phase-<N>-` (e.g., `phase-3-plan-audit-report-attempt-<K>.md`).

K is self-determined by globbing existing report files and incrementing. Reports are never overwritten — each audit run produces a new attempt file to preserve the audit trail.

### Report Frontmatter

The persistent report opens with YAML frontmatter above the `# Plan Audit Report` heading (the prose `**Target:** / **Mode:** / **Status:** / **Issues:**` header is retained below it as the human-readable mirror):

```yaml
---
target: <feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final>
mode: <full-audit | phase-audit>
verdict: <VALID | INVALID>
attempt: <K>
issues:
  critical: <integer>
  error: <integer>
  warning: <integer>
  info: <integer>
plan-path: <relative path of audited plan>
---
```

`target` is the dispatch's actual Target (one of the seven values); `mode` is the run's mode; `verdict` mirrors the prose `**Status:**`; `attempt` is the globbed `<K>`; `issues` carries the same severity tally as the prose `**Issues:**` line.

### Issues Format

Each issue contains:

| Field | Type | Description |
|-------|------|-------------|
| severity | `CRITICAL` \| `ERROR` \| `WARNING` \| `INFO` | Drives VALID/INVALID decision |
| confidence | `HIGH` \| `MEDIUM` | HIGH for deterministic checks; MEDIUM for heuristic judgment |
| code | string | Rule identifier (e.g., `UNDOCUMENTED_VERB`, `ABSTRACT_FINDING_INCOMPLETE`) |
| location | string | `Phase N, Task N.M` \| `plan-level` \| `<table-section>` |
| description | string | One-sentence violation summary |
| suggestion | string | How to fix |

### Severity Definitions

| Severity | Meaning | Effect on Status |
|----------|---------|------------------|
| **CRITICAL** | Plan is structurally broken or unauditable (e.g., file not loaded, missing draft) | INVALID |
| **ERROR** | Required element missing or wrong; plan cannot proceed to execution as-is | INVALID |
| **WARNING** | Suboptimal but plan is usable | VALID (with warnings noted) |
| **INFO** | Suggestion for improvement | VALID |

## Loaded Rule Sets

For every dispatch, the agent loads:

1. `essentials/self-check.md` — confidence calibration and disconfirmation protocol.
2. `essentials/base-rules.md` — applies to every target.
3. `essentials/<target>-rules.md` — target-specific extension.
4. `modes/<mode>.md` — drives application of the loaded rules.

### Base rules (`essentials/base-rules.md`)

- Verb-noun discipline — every task verb either on the allowed-verbs list or accompanied by an extension request file. Violation: `UNDOCUMENTED_VERB`.
- One-concern discipline — exactly one `Concern` field per task from a closed nine-value enum (`validation`, `persistence`, `transformation`, `rendering`, `side-effect`, `authorization`, `infrastructure`, `test`, `convention-doc`). Violations: `MISSING_CONCERN`, `INVALID_CONCERN`, `MULTIPLE_CONCERNS`.
- Domain-noun discipline — generic placeholders (`input`, `data`, `payload`, `value`) rejected in noun position. Violation: `GENERIC_NOUN`.
- Per-task metadata — every task carries `Target file(s)`, `Acceptance`, `Concern`, `Effort` (`S`|`M`|`L`). Violation: `MISSING_TASK_METADATA`.
- Effort-tier consistency — a task's declared `Effort` must be at least the tier implied by its file count (≥3 → `L`, =2 → ≥`M`) and acceptance-assertion count (>6 → `L`, 3–6 → ≥`M`). Violation: `PHASE_EFFORT_UNDERWEIGHTED` (HIGH on the countable axes; MEDIUM when invoking the logic axis).
- Phase sizing — effort-budget based: ≤8 effort points per phase (`S`=1, `M`=2, `L`=3), ≤6 tasks, ≤15 files; mandatory phase boundaries on budget overflow, Developer Type changes, subarea changes, and intra-phase commit dependencies. Violations: `PHASE_OVER_BUDGET`, `PHASE_TOO_MANY_TASKS`, `PHASE_TOO_MANY_FILES`, `PHASE_MIXED_DEVELOPER_TYPE`, `PHASE_MIXED_SUBAREA`, `PHASE_INTRA_COMMIT_DEPENDENCY`, plus the WARNING-level soft-target `PHASE_SOFT_TARGET_EFFORT`.
- Code-reference grounding — every cited path resolves at HEAD via Glob. Violations: `PATH_NOT_FOUND`, `PATH_NEW_BUT_EXISTS`.
- Charter grounding — tasks introducing a new third-party dependency (a package import absent from `package.json`, an install Action, or an external-service Integration) are checked against `.project/knowledge/tech-stack/charter.md` (read main-canonical). Violations: `OFF_CHARTER_DEPENDENCY` (ERROR, MEDIUM confidence — heuristic), `CHARTER_MISSING` (WARNING, plan-level). Backstop to `design-auditor`'s primary SDD-stage gate.

Full-audit plan-wide check (all targets): `## Objective` section present and non-empty, else `MISSING_OBJECTIVE` (ERROR, plan-level). Full-audit only; skipped in phase-audit.

### Feature-draft extension (`essentials/feature-draft-rules.md`)

- Loads `base-rules.md` only — adds no violation codes of its own. The draft is VALID when it has no CRITICAL or ERROR base-rule findings.
- The two-pass diff, REUSE/EXTRACT, and ABSTRACT checks are deferred to the `feature-final` audit (a draft has no final to diff and carries no directives).

### Feature-final extension (`essentials/feature-final-rules.md`)

- Two-pass plan check (cross-phase; `full-audit` only) — `implementation-plan-draft.md` and `implementation-plan.md` both exist; final differs from draft by additions only. Violations: `MISSING_DRAFT_PLAN`, `MISSING_FINAL_PLAN`, `DRAFT_TASK_REWRITTEN`, `DRAFT_METADATA_CHANGED`.
- No-ABSTRACT-in-feature-final — no `abstract-migration-phase` tag or `ABSTRACT directive applied` annotation. `ABSTRACT-deferred:` markers are allowed. Violation: `ABSTRACT_IN_FEATURE_FINAL_DISALLOWED`.
- REUSE-directive existence — every cited REUSE path resolves at HEAD. Violation: `REUSE_PATH_NOT_FOUND`.
- EXTRACT-directive sanity — every EXTRACT phase has at least one downstream consumer. Violation: `EXTRACT_NO_CONSUMER`.

### Test-plan extension (`essentials/test-plan-rules.md`)

- BDD trace — every task references at least one BDD scenario by ID. Violations: `MISSING_BDD_TRACE`, `BDD_SCENARIO_NOT_FOUND`, `BDD_SOURCE_UNAVAILABLE`.
- Coverage scope — every task references implemented code. Violations: `MISSING_TEST_REFERENCE`, `TEST_TARGET_UNIMPLEMENTED`.
- Carries a `## Objective` (what the phase's tests verify); `MISSING_OBJECTIVE` applies (plan-wide, base-rules).

### Refactor-plan extension (`essentials/refactor-plan-rules.md`)

- Sole-input check — every phase cites at least one approved finding by ID; finding exists in `approved.md`. Violations: `PHASE_NO_FINDING_CITATION`, `PHASE_FINDING_NOT_FOUND`, `APPROVED_FILE_NOT_FOUND`.
- Convention-doc declarations — phases introducing or modifying shared utilities carry a `Concern: convention-doc` task. Violation: `MISSING_CONVENTION_DOC_TASK`.
- ABSTRACT phase rules (applied to `abstract-migration-phase`-tagged phases only):
  - `ABSTRACT_FINDING_NOT_FOUND` — cited finding ID absent from `approved.md`.
  - `ABSTRACT_FINDING_INCOMPLETE` — APPROVE finding missing required fields (`source-file`, `source-function`, `current-signature`, `generalized-signature`, `hard-gates`, `scoring-axes`, `verdict`, `call-site-data`, `stragglers`, `phase-splitting-recommendation`).
  - `ABSTRACT_FINDING_NOT_APPROVED` — cited finding's `verdict` ≠ `APPROVE`.
  - `ABSTRACT_ANNOTATION_DRIFT` — annotation field disagrees with cited finding's corresponding field.
  - `ABSTRACT_PHASE_SPLIT_MISMATCH` — phase structure disagrees with `phase-splitting-recommendation` (`one-phase` vs `two-phase`, T-task distribution, phase count).

### Bugfix-reproduction extension (`essentials/bugfix-reproduction-rules.md`)

- Bug-Expectation present — every task carries a non-empty `Bug-Expectation:` (the bug report's `## Expected Behavior` verbatim; the reproduction analogue of `test-plan`'s `Scenario:`). Violation: `MISSING_BUG_EXPECTATION`.
- Test-only tasks — every task targets a test file and is `Concern: test`. Violation: `NON_TEST_TARGET_IN_REPRODUCTION_PLAN`.
- Compile-clean acceptance — `Acceptance:` is a single-file typecheck/lint predicate, not a runtime test pass (the reproduction test is expected RED). Violation: `RUNTIME_VERIFY_IN_REPRODUCTION_TASK`.
- Carries a `## Objective` (the bug it reproduces); `MISSING_OBJECTIVE` applies (plan-wide, base-rules).

### Bugfix-draft extension (`essentials/bugfix-draft-rules.md`)

- Loads `base-rules.md` (verb / concern / metadata / sizing / path-grounding / charter); adds no new violation codes. Implementation-file tasks are allowed; directive analysis is deferred to `bugfix-final`.
- Advisory only — a plan-level INFO note when the phase decomposition appears to split one bundled bug's fix across phases (best-effort; never affects the verdict).
- Carries a `## Objective` (the intended-vs-actual the fix restores); `MISSING_OBJECTIVE` applies (plan-wide, base-rules).

### Bugfix-final extension (`essentials/bugfix-final-rules.md`)

- Two-pass plan check (cross-phase; `full-audit` only) — `implementation-plan-draft.md` and `implementation-plan.md` both exist; final differs from draft by additive REUSE/EXTRACT directives only. Violations: `MISSING_DRAFT_PLAN`, `MISSING_FINAL_PLAN`, `DRAFT_TASK_REWRITTEN`, `DRAFT_METADATA_CHANGED`.
- Investigation-resolved — every cited investigation exists and carries `LEVEL_1`/`LEVEL_2`, or a `LEVEL_3`/`LEVEL_4` with `resolved: true` in frontmatter. Violation: `INVESTIGATION_UNRESOLVED`.
- REUSE/EXTRACT grounding — mirrors `feature-final-rules.md`; directives must attach to tasks. Violations: `REUSE_PATH_NOT_FOUND`, `EXTRACT_NO_CONSUMER`.
- ABSTRACT deferral — `ABSTRACT-deferred:` comment allowed; an applied `ABSTRACT directive applied…` annotation or `abstract-migration-phase` flag is disallowed. Violation: `ABSTRACT_IN_BUGFIX_FINAL_DISALLOWED`.
- Preserves the draft's `## Objective`; `MISSING_OBJECTIVE` applies (plan-wide, base-rules).

## Guarantees

- Loading is deterministic: `Target` selects exactly one rule extension; `Mode` selects exactly one mode file. Mismatched values fail the dispatch CRITICAL on parse.
- File path claims are verified via Glob; the auditor never trusts a plan-architect path without tool confirmation.
- Every finding includes severity, confidence, rule code, location, description, and suggestion.
- Every CRITICAL and ERROR finding passes the self-check protocol (disconfirmation + severity calibration) before being reported. LOW-confidence findings are re-investigated once; those that cannot reach MEDIUM are dropped.
- Every reported finding carries Confidence = HIGH (deterministic check) or MEDIUM (heuristic). LOW-confidence findings are never reported.
- Severities match what the rule files specify; the auditor does not inflate or deflate.
- Output format is consistent across VALID and INVALID.
- Read-only with respect to plan files; the plan file is never modified.
- Commits **only** its own audit report — path-scoped, via the `commit-to-git` skill with `Agent: plan-auditor`, after the report is written and before returning (subject `audit(<slug>): <target> audit attempt <K>`). Never stages or commits plan files, `ROADMAP.md`, or anything under `.project/product/`. This is the sole exception to its otherwise audit-only, report-only write surface.
- A persistent report is written to the target's canonical report directory with attempt numbering.
- The auditor never executes pipeline scripts. `find-call-sites.ts`, `inventory-utils.ts`, and `curate-approved.ts` are `pattern-analyst`'s sole property; their data is read from finding-content (`approved.md`).
- `phase-audit` skips cross-phase rules (e.g., two-pass plan check, plan-wide ABSTRACT coherence across phases) — those produce false positives mid-revision. Phase-only INVALID returns a Problem Report matching `plan-architect` (`Mode: update`)'s expected input.

## Phase-Audit Rule Subset

`phase-audit` applies only per-task and per-phase rules from the loaded essentials. Skipped:

- Two-pass plan check (`feature-final-rules.md`) — requires plan-wide stability.
- Any rule whose evidence requires reading sections outside the phase scope.

Run in phase audit:

- All base rules.
- `feature-final-rules.md`: no-ABSTRACT signal, REUSE existence, EXTRACT sanity (only when the phase IS an EXTRACT phase).
- `test-plan-rules.md`: BDD trace, coverage scope.
- `refactor-plan-rules.md`: sole-input check, convention-doc declarations, ABSTRACT phase rules (cited-finding existence, completeness, verdict, annotation/finding consistency, phase-split execution in scoped form).
