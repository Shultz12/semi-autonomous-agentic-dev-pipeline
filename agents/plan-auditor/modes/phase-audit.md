# Phase Audit Mode

Runs per-task and per-phase rules against a single phase. Used after `plan-architect` (`Mode: update`) revises one phase and the orchestrator needs a fast, scoped re-audit.

## Inputs

From the dispatch (parsed by the base persona):

- `Target: feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final`
- `planPath: <path to plan file>`
- `Phase: <N>` — REQUIRED in this mode.

The rule files (`essentials/base-rules.md` + `essentials/<target>-rules.md`) and `essentials/self-check.md` have been loaded into context before this mode is read.

## Workflow

### Step 1: Plan loading and phase isolation

1. Read the plan file at `planPath` using Read.
2. If the file is absent or empty, record a CRITICAL `PLAN_NOT_LOADED: <planPath>` issue and skip to Step 4 (Report Writing).
3. Locate the `## Phase <N>:` heading. If absent, record a CRITICAL `PHASE_NOT_FOUND: Phase <N>` issue and skip to Step 4.
4. Treat the section from `## Phase <N>:` up to (but not including) the next `## ` heading as the audit scope. All rule applications below operate on this section only.

### Step 2: Rule application (scoped)

Apply only per-task and per-phase rules from the loaded essentials. Skip cross-phase rules — they require a stable final plan and produce false positives mid-revision.

Run:

1. **Base rules per task** — verb-noun, one-concern, domain-noun, per-task metadata.
2. **Base rules per phase** — phase sizing (hard caps, mandatory boundaries, soft targets).
3. **Base rules on cited paths within the phase** — code-reference grounding (Glob every path cited inside the phase scope).
4. **Target-specific per-task / per-phase rules:**
   - `feature-draft-rules.md`: none beyond base — this target adds no per-task or per-phase rules of its own.
   - `feature-final-rules.md`: no-ABSTRACT-in-feature-final (per-phase signal); REUSE-directive existence (per-task); EXTRACT-directive sanity ONLY when the phase scope IS an EXTRACT phase.
   - `test-plan-rules.md`: BDD trace, coverage scope.
   - `refactor-plan-rules.md`: sole-input check (per-phase finding citation); convention-doc declarations (per-phase); ABSTRACT phase rules (cited-finding existence, completeness, verdict, annotation/finding consistency, phase-split execution — phase-split executed in scoped form: verify the cited finding's `phase-splitting-recommendation` against the current phase's structure; if `two-phase` is cited and the phase contains T5, surface a violation noting the companion phase's existence must be checked at full audit).
   - `bugfix-reproduction-rules.md`: Bug-Expectation present, test-only tasks, compile-clean acceptance (all per-task — run).
   - `bugfix-draft-rules.md`: base per-task / per-phase rules only (the phase-ordering advisory is plan-wide — skipped).
   - `bugfix-final-rules.md`: REUSE-directive existence (per-task — run), ABSTRACT-deferral signal (per-phase — run). The two-pass plan check and investigation-resolved check are cross-phase / plan-wide — skipped here.

### Skipped in phase audit

- `feature-final-rules.md` → two-pass plan check (compares draft to full final; requires plan-wide stability).
- `bugfix-final-rules.md` → two-pass plan check and investigation-resolved check (both cross-phase / plan-wide; require the full final plan).
- Plan header check (`MISSING_OBJECTIVE`) — plan-wide; the `## Objective` section sits above the first phase heading, outside any single phase's scope.
- Any plan-wide rule whose evidence requires reading sections outside the phase scope (e.g., counting phases plan-wide).

These rules run in `full-audit` only.

### Step 3: Self-check pass

Apply the protocol in `essentials/self-check.md` against every CRITICAL and ERROR finding produced in Step 2. Re-investigate LOW-confidence findings once; drop those that cannot reach MEDIUM. Surviving findings carry HIGH or MEDIUM confidence.

### Step 4: Report writing

1. Glob existing phase reports in the Target-selected `<report-dir>`: `<report-dir>/phase-<N>-plan-audit-report-attempt-*.md`. Set K = count + 1.
2. Write the report to `<report-dir>/phase-<N>-plan-audit-report-attempt-<K>.md`.

Report format:

```markdown
---
target: [feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final]
mode: phase-audit
verdict: [VALID | INVALID]
attempt: [K]
issues:
  critical: [integer]
  error: [integer]
  warning: [integer]
  info: [integer]
plan-path: [relative path of audited plan]
---

# Plan Audit Report — Phase <N>

**Target:** [feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final]
**Mode:** phase-audit
**Plan:** [planPath]
**Phase:** <N>: [phase-name]
**Date:** [YYYY-MM-DD]
**Status:** [VALID | INVALID]
**Issues:** [N] critical, [N] errors, [N] warnings, [N] info

---

## Issues

(grouped by severity; omit empty sections)
```

### Step 5: Return

**VALID:**

```
Status: VALID
Target: [feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final]
Plan: [planPath]
Phase: <N>: [phase-name]
Report: [report file path]
Issues: 0 critical, 0 errors, [N] warnings, [N] info
```

**INVALID — with Problem Report:**

```
Status: INVALID
Target: [feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final]
Plan: [planPath]
Phase: <N>: [phase-name]
Report: [report file path]
Issues: [N] critical, [N] errors, [N] warnings, [N] info

Problem Report:
**Reporter:** plan-auditor
**Target:** [planPath]
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
