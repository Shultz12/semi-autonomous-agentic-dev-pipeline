# Plan Auditor Guide

## What It Does

The Plan Auditor validates plans produced by `plan-architect` for four target artifacts — feature-draft and feature-final implementation plans, per-phase test plans, and refactor plans — before downstream execution begins. It catches missing per-task metadata, broken file references, faithfulness drift between approved findings and ABSTRACT phases, and verb-noun vocabulary violations — preventing wasted effort from executing malformed plans.

**Model:** Claude Sonnet (`claude-sonnet-4-6`).

**Input:** Plan file path plus `Target` (one of `feature-draft`, `feature-final`, `test-plan`, `refactor-plan`), optionally a `Mode` and `Phase` (see Dispatch Contract below).

**Output:** `VALID` or `INVALID` result with a list of severity-tagged issues (CRITICAL, ERROR, WARNING, INFO), each carrying a rule identifier code (e.g., `UNDOCUMENTED_VERB`, `ABSTRACT_FINDING_INCOMPLETE`).

## Audit Posture

The auditor adopts a strict, by-the-book posture by design. It defaults to doubt: every phase, every task, and every code reference is suspect until each loaded rule has been checked against it. A VALID verdict is earned by coverage — every loaded rule × every phase × every referenced code path — not by scanning the table of contents. File paths the plan names are verified with Glob before being trusted, and severities are applied as the rule files define them rather than inflated or invented. This is balanced by a Self-Check pass that drops LOW-confidence findings (those not directly backed by tool output) before the report is written: rigor here means thorough coverage, not fabricated issues or inflated severities.

Every reported finding carries a Confidence value (HIGH or MEDIUM) alongside its Severity:

- **HIGH** — deterministic check (field absent, Glob returned no match, direct plan quote contradicting the rule).
- **MEDIUM** — heuristic judgment (subarea boundary inferred from path prefix, EXTRACT phase identified by pattern, soft-target threshold breach). MEDIUM-confidence ERROR findings carry a "Heuristic — verify manually" note.

LOW-confidence findings are never reported — they are re-investigated once and either lifted to MEDIUM/HIGH with stronger evidence, or dropped.

## When It Runs

Invoked by the orchestrator after `plan-architect` produces or revises a target artifact. The auditor sits in the pipeline between plan creation and downstream execution:

```
plan-architect → plan-auditor → orchestrator (per-phase dispatch)
```

It also runs as a fast scoped re-audit after `plan-architect` (`Mode: update`) revises a single phase in response to a Problem Report.

## Dispatch Contract

The orchestrator provides:

| Field | Values | Required |
|-------|--------|----------|
| `Plan Path` | Path to the plan file | Yes |
| `Target` | `feature-draft` \| `feature-final` \| `test-plan` \| `refactor-plan` | Yes |
| `Mode` | `full-audit` \| `phase-audit` | No (default `full-audit`) |
| `Phase` | `<phase-number>` | Required when `Mode: phase-audit` |

`feature-draft` is audited with `base-rules` only (plus the `## Objective` header check), so verb / concern / metadata / sizing / path defects are caught before `feature-final` copies the draft's task headers verbatim. The two-pass diff and the REUSE/EXTRACT/ABSTRACT checks are deferred to the `feature-final` audit — a draft has no final to diff and carries no directives.

### Target × Artifact Map

| Target | Artifact under audit |
|--------|----------------------|
| `feature-draft` | `.project/cycles/<cycle>/plans/implementation-plan-draft.md` |
| `feature-final` | `.project/cycles/<cycle>/plans/implementation-plan.md` |
| `test-plan` | `.project/cycles/<cycle>/plans/test-plans/phase-<N>-test-plan.md` |
| `refactor-plan` | `.project/cycles/<DD-MM-YYYY>-refactor-from-<parent-name>/plans/implementation-plan.md` (scout-and-refactor) or `.project/cycles/<DD-MM-YYYY>-primitives/plans/implementation-plan.md` (primitives) |

## How the Audit Runs

On dispatch, the agent loads:

1. `essentials/self-check.md` — confidence calibration and disconfirmation protocol.
2. `essentials/base-rules.md` — applies to every target.
3. `essentials/<target>-rules.md` — target-specific extension.
4. `modes/<mode>.md` — drives application of the loaded rules.

The mode file specifies the order: per-task rules first, then per-phase rules, then plan-wide rules. `full-audit` runs every loaded rule against the whole plan; `phase-audit` runs per-task and per-phase rules against a single phase and skips cross-phase rules.

## What Gets Checked

### Base rules (applied to every target)

| Rule | Codes | Severity |
|------|-------|----------|
| Verb-noun discipline | `UNDOCUMENTED_VERB` | ERROR |
| One-concern discipline | `MISSING_CONCERN`, `INVALID_CONCERN`, `MULTIPLE_CONCERNS` | ERROR / ERROR / WARNING |
| Domain-noun discipline | `GENERIC_NOUN` | WARNING |
| Per-task metadata | `MISSING_TASK_METADATA` | ERROR |
| Phase sizing — hard caps | `PHASE_TOO_MANY_TASKS`, `PHASE_TOO_MANY_FILES` | ERROR |
| Phase sizing — mandatory boundaries | `PHASE_MIXED_DEVELOPER_TYPE`, `PHASE_MIXED_SUBAREA`, `PHASE_INTRA_COMMIT_DEPENDENCY` | ERROR |
| Phase sizing — soft targets | `PHASE_SOFT_TARGET_TASKS`, `PHASE_SOFT_TARGET_COMPLEXITY` | WARNING |
| Code-reference grounding | `PATH_NOT_FOUND`, `PATH_NEW_BUT_EXISTS` | ERROR / WARNING |

In addition, `full-audit` applies one plan-wide header check on `feature-draft`, `feature-final`, and `refactor-plan` targets: the plan must carry a non-empty `## Objective` section above the first `## Phase` heading, else `MISSING_OBJECTIVE` (ERROR, plan-level). This check is skipped in `phase-audit` and does not apply to `test-plan`.

The verb-noun rule consults the closed allowed-verbs list at `.claude/agents/plan-architect/essentials/allowed-verbs.md`. An unlisted verb is acceptable if (and only if) the plan references a vocabulary extension request at `.claude/docs/vocabulary-extensions/<YYYY-MM-DD>-<verb>.md`. Plan-auditor does NOT evaluate request viability — `agent-architect` (`process-vocabulary` mode) adjudicates that separately.

### Feature-draft (base rules only)

The `feature-draft` target loads `base-rules.md` and nothing else — it adds no codes of its own. Auditing the draft catches base-rule defects (verbs, concerns, metadata, sizing, paths) at the layer where they are fixable, before `feature-final` copies the draft's headers verbatim. The feature-final-only checks below are deferred to the final audit.

### Feature-final extension

| Rule | Codes | Severity |
|------|-------|----------|
| Two-pass plan check (full-audit only) | `MISSING_DRAFT_PLAN`, `MISSING_FINAL_PLAN`, `DRAFT_TASK_REWRITTEN`, `DRAFT_METADATA_CHANGED` | CRITICAL / CRITICAL / ERROR / ERROR |
| No-ABSTRACT-in-feature-final | `ABSTRACT_IN_FEATURE_FINAL_DISALLOWED` | ERROR |
| REUSE-directive existence | `REUSE_PATH_NOT_FOUND` | ERROR |
| EXTRACT-directive sanity | `EXTRACT_NO_CONSUMER` | WARNING |

The `<!-- ABSTRACT-deferred: ... -->` marker emitted by `plan-architect`'s `targets/feature-final.md` is allowed and not flagged. Only the `<!-- ABSTRACT directive applied... -->` annotation and `abstract-migration-phase`-tagged headers trigger `ABSTRACT_IN_FEATURE_FINAL_DISALLOWED`.

### Test-plan extension

| Rule | Codes | Severity |
|------|-------|----------|
| BDD trace | `MISSING_BDD_TRACE`, `BDD_SCENARIO_NOT_FOUND`, `BDD_SOURCE_UNAVAILABLE` | ERROR / ERROR / WARNING |
| Coverage scope | `MISSING_TEST_REFERENCE`, `TEST_TARGET_UNIMPLEMENTED` | ERROR / ERROR |

### Refactor-plan extension

| Rule | Codes | Severity |
|------|-------|----------|
| Sole-input check | `PHASE_NO_FINDING_CITATION`, `PHASE_FINDING_NOT_FOUND`, `APPROVED_FILE_NOT_FOUND` | ERROR / ERROR / CRITICAL |
| Convention-doc declarations | `MISSING_CONVENTION_DOC_TASK` | WARNING |
| ABSTRACT — cited finding exists | `ABSTRACT_FINDING_NOT_FOUND` | CRITICAL |
| ABSTRACT — finding completeness | `ABSTRACT_FINDING_INCOMPLETE` | CRITICAL |
| ABSTRACT — finding verdict | `ABSTRACT_FINDING_NOT_APPROVED` | CRITICAL |
| ABSTRACT — annotation/finding consistency | `ABSTRACT_ANNOTATION_DRIFT` | ERROR |
| ABSTRACT — phase-split execution | `ABSTRACT_PHASE_SPLIT_MISMATCH` | ERROR |

The ABSTRACT rules apply only to phases whose header carries the `abstract-migration-phase` tag (emitted by `plan-architect`'s `targets/refactor-plan.md`). The auditor reads the cited `approved.md` to verify the finding's fields, verdict, and consistency with the inline annotation; it does not re-derive ABSTRACT decisions or re-run `find-call-sites.ts`.

## Severity and Status

| Severity | Meaning | Impact |
|----------|---------|--------|
| **CRITICAL** | Plan is structurally broken or unauditable | Makes plan INVALID |
| **ERROR** | Required element missing or wrong | Makes plan INVALID |
| **WARNING** | Suboptimal but functional | Plan stays VALID |
| **INFO** | Improvement suggestion | Plan stays VALID |

The auditor never inflates or deflates severities — each rule file declares its own severity per violation code, and findings are reported at exactly that level.

## Output

### VALID

```
Status: VALID
Target: [feature-draft | feature-final | test-plan | refactor-plan]
Plan: [plan file path]
Report: [report file path]
Issues: 0 critical, 0 errors, [N] warnings, [N] info

[Optional warnings/info listed here]
```

`phase-audit` adds a `Phase: <N>: [phase-name]` line below `Plan:`.

### INVALID (full-audit)

```
Status: INVALID
Target: [feature-draft | feature-final | test-plan | refactor-plan]
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

### INVALID (phase-audit) — Problem Report

`phase-audit` returns a Problem Report block matching what `plan-architect` (`Mode: update`) expects as input on its next revision pass:

```
Problem Report:
**Reporter:** plan-auditor
**Target:** [plan file path]
**Phase:** <N>: [phase-name]
**Task:** [N.M] | "Phase-level"
**Type:** AMBIGUITY | MISSING_REFERENCE | CONTRADICTION | INVALID_STRUCTURE
**Severity:** BLOCKING
**Confidence:** HIGH | MEDIUM

### Problem
[description, with the rule's identifier code]

### Evidence
- [tool-backed references]

### Attempted Resolution
N/A
```

### Report Persistence

Reports are written with attempt numbering so the audit trail is preserved across revisions:

| Target | Report directory |
|--------|------------------|
| `feature-draft` | `<feature-dir>/plans/plan-audit/draft/` |
| `feature-final` | `<feature-dir>/plans/plan-audit/` |
| `test-plan` | `<feature-dir>/plans/test-plans/plan-audit/` |
| `refactor-plan` | `<feature-dir>/plans/plan-audit/` |

| Mode | Filename |
|------|----------|
| `full-audit` | `plan-audit-report-attempt-<K>.md` |
| `phase-audit` | `phase-<N>-plan-audit-report-attempt-<K>.md` |

K is self-determined by globbing existing report files in the directory and incrementing. Reports are never overwritten.

## Phase-Audit Mode

`phase-audit` is the focused mode used after `plan-architect` (`Mode: update`) revises one phase in response to a Problem Report. The orchestrator dispatches the auditor with `Mode: phase-audit` and `Phase: <N>` to validate the revised phase before re-dispatching the developer.

### What runs in phase-audit

- All base rules (per-task and per-phase, plus code-reference grounding scoped to paths cited inside the phase).
- `feature-final-rules.md`: no-ABSTRACT signal, REUSE existence, EXTRACT sanity (only when the phase IS an EXTRACT phase).
- `test-plan-rules.md`: BDD trace, coverage scope.
- `refactor-plan-rules.md`: sole-input check, convention-doc declarations, all five ABSTRACT phase rules (phase-split executed in scoped form).

### What gets skipped

- Two-pass plan check (cross-phase; requires plan-wide stability).
- Any rule whose evidence requires reading sections outside the phase scope.

These skip rules exist to prevent false positives mid-revision — cross-phase rules need a stable final plan to evaluate correctly.

## Audit-Only Invariant

This agent never executes pipeline scripts. `find-call-sites.ts`, `inventory-utils.ts`, and `curate-approved.ts` belong exclusively to `pattern-analyst`; their data is read from finding-content (`approved.md`), never re-derived here. The auditor's `Bash` tool is used only for `mkdir -p <report-dir>`, `echo > /tmp/.claude-agent-output-target`, and committing its own audit report (path-scoped, via the `commit-to-git` skill with `Agent: plan-auditor`) after the report is written — never to stage or commit plan files, `ROADMAP.md`, or anything under `.project/product/`.

## How to Extend

### Adding a new target

1. Create a new rules file at `.claude/agents/plan-auditor/essentials/<target>-rules.md` extending `base-rules.md`.
2. Update the dispatch contract in `plan-auditor.md` to recognize the new `Target` value.
3. Update both mode files (`full-audit.md`, `phase-audit.md`) with the rule application steps for the new target.
4. Update `.claude/agents/interface-contracts/plan-auditor.contract.md` with the new target's input, output, and rule codes.

### Adding a new rule

1. Decide whether the rule applies to every target (base) or only one (extension). Place it accordingly.
2. Add the rule with its violation code(s), severity, and confidence calibration.
3. If the rule is cross-phase, mark it as `full-audit`-only and document the exclusion in `phase-audit.md`.
4. Update the interface contract's rule-code list.

## Related

- Agent definition: `.claude/agents/plan-auditor/plan-auditor.md`
- Interface contract: `.claude/agents/interface-contracts/plan-auditor.contract.md`
- Self-check protocol: `.claude/agents/plan-auditor/essentials/self-check.md`
- Base rules: `.claude/agents/plan-auditor/essentials/base-rules.md`
- Feature-draft rules: `.claude/agents/plan-auditor/essentials/feature-draft-rules.md`
- Feature-final rules: `.claude/agents/plan-auditor/essentials/feature-final-rules.md`
- Test-plan rules: `.claude/agents/plan-auditor/essentials/test-plan-rules.md`
- Refactor-plan rules: `.claude/agents/plan-auditor/essentials/refactor-plan-rules.md`
- Mode files: `.claude/agents/plan-auditor/modes/full-audit.md`, `.claude/agents/plan-auditor/modes/phase-audit.md`
- Allowed-verbs list (consulted for verb-noun discipline): `.claude/agents/plan-architect/essentials/allowed-verbs.md`
- Vocabulary extension requests: `.claude/docs/vocabulary-extensions/`
