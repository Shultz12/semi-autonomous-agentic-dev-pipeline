# Full Audit Mode

Default mode. Runs the entire loaded rule set (base + target extension) against the whole plan.

## Inputs

From the dispatch (parsed by the base persona):

- `Target: feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final`
- `planPath: <path to plan file>`

The rule files (`essentials/base-rules.md` + `essentials/<target>-rules.md`) and `essentials/self-check.md` have been loaded into context before this mode is read.

## Workflow

### Step 1: Plan loading

1. Read the plan file at `planPath` using Read.
2. If the file is absent or empty, record a CRITICAL `PLAN_NOT_LOADED: <planPath>` issue and skip to Step 4 (Report Writing).
3. Identify phase headings (`## Phase N:` lines) and the per-phase tasks they contain.

### Step 2: Rule application

Apply every rule in the loaded essentials, in the order below. For each rule, gather every violation across every phase and every task. Record each violation with its severity, confidence, location (Phase N, Task N.M, table section, or `plan-level`), and the rule's identifier code (e.g., `UNDOCUMENTED_VERB`, `ABSTRACT_FINDING_INCOMPLETE`).

Order of rule application:

1. **Base rules per task** — verb-noun, one-concern, domain-noun, per-task metadata.
2. **Base rules per phase** — phase sizing (hard caps, mandatory boundaries, soft targets).
3. **Base rules plan-wide** — code-reference grounding (Glob every cited path), charter grounding, and simplicity grounding (advisory over-engineering scan).
4. **Plan header (plan-wide; all targets)** — apply the Objective discipline from `base-rules.md`: a non-empty `## Objective` section exists (above the first `## Phase` heading when phases are present). Violation: `MISSING_OBJECTIVE` — ERROR, HIGH, plan-level.
5. **Target-specific rules** — apply the rules in `<target>-rules.md` exactly as written:
   - `feature-draft-rules.md`: base rules only — this target adds no rules of its own; the two-pass diff and directive checks are deferred to the feature-final audit.
   - `feature-final-rules.md`: two-pass plan check, no-ABSTRACT-in-feature-final, REUSE-directive existence, EXTRACT-directive sanity.
   - `test-plan-rules.md`: BDD trace, coverage scope.
   - `refactor-plan-rules.md`: sole-input check, convention-doc declarations, ABSTRACT phase rules (cited-finding existence, completeness, verdict, annotation/finding consistency, phase-split execution).
   - `bugfix-reproduction-rules.md`: Bug-Expectation present, test-only tasks, compile-clean acceptance.
   - `bugfix-draft-rules.md`: base rules only — implementation tasks allowed, directive analysis deferred; plus the advisory phase-ordering INFO note.
   - `bugfix-final-rules.md`: two-pass plan check, investigation-resolved, REUSE/EXTRACT grounding, ABSTRACT deferral.

Cross-phase rules (e.g., two-pass plan check in `feature-final-rules.md`) run here in full-audit. They are NOT run in `phase-audit`.

### Step 3: Self-check pass

Apply the protocol in `essentials/self-check.md` against every CRITICAL and ERROR finding produced in Step 2. Re-investigate LOW-confidence findings once; drop those that cannot reach MEDIUM after one pass. Calibrate severity to match what the rule files specify.

Surviving findings carry HIGH or MEDIUM confidence. MEDIUM-confidence ERROR findings include the note `Heuristic — verify manually`.

### Step 4: Result compilation

1. Collect surviving findings from Step 3 plus any Step 1 short-circuit findings.
2. Determine overall status:
   - **VALID:** no CRITICAL or ERROR issues.
   - **INVALID:** at least one CRITICAL or ERROR issue.
3. Sort findings by severity: CRITICAL → ERROR → WARNING → INFO.

### Step 5: Report writing

1. Glob existing reports in the Target-selected `<report-dir>`: `<report-dir>/plan-audit-report-attempt-*.md`. Set K = count + 1.
2. Write the report to `<report-dir>/plan-audit-report-attempt-<K>.md`.

Report format:

```markdown
---
target: [feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final]
mode: full-audit
verdict: [VALID | INVALID]
attempt: [K]
issues:
  critical: [integer]
  error: [integer]
  warning: [integer]
  info: [integer]
plan-path: [relative path of audited plan]
---

# Plan Audit Report

**Target:** [feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final]
**Mode:** full-audit
**Plan:** [planPath]
**Date:** [YYYY-MM-DD]
**Status:** [VALID | INVALID]
**Issues:** [N] critical, [N] errors, [N] warnings, [N] info

---

## Issues

### CRITICAL
1. **[Code]** (HIGH|MEDIUM) — Location: [Phase N, Task N.M | plan-level | <table>]
   [violation description]
   Suggestion: [how to fix]
   [If MEDIUM: "Heuristic — verify manually"]

### ERROR
…

### WARNING
…

### INFO
…
```

Omit severity sections with zero findings.

### Step 6: Return

Return structured result inline to the caller:

**VALID:**

```
Status: VALID
Target: [feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final]
Plan: [planPath]
Report: [report file path]
Issues: 0 critical, 0 errors, [N] warnings, [N] info
```

**INVALID:**

```
Status: INVALID
Target: [feature-draft | feature-final | test-plan | refactor-plan | bugfix-reproduction | bugfix-draft | bugfix-final]
Plan: [planPath]
Report: [report file path]
Issues: [N] critical, [N] errors, [N] warnings, [N] info

Issues:
1. [SEVERITY] (HIGH|MEDIUM) [Code] — Location: [Phase N, Task N.M | plan-level | <table>]
   [violation description]
   Suggestion: [how to fix]
   [If MEDIUM: "Heuristic — verify manually"]
…
```
