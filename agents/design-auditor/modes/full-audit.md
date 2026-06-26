# Full Validation Mode

Default and only mode for design-auditor. Runs the 4 validation steps against the SDD and writes the audit report.

## Workflow

### Phase 1: Rules Loading

1. Read `essentials/design-review-rules.md`
2. Internalize the required sections, fields, and validation rules

### Phase 2: Document Loading

1. Glob `<specs-dir>/`; if absent, escalate per the `specs/` directory missing case (write the report with the single CRITICAL issue and skip remaining phases)
2. Glob `<specs-dir>/SDD.md`; if absent, escalate per the SDD missing case
3. Read SDD.md; if empty, escalate per the SDD empty case
4. Glob `<specs-dir>/SRS.md`; if absent, escalate per the SRS missing case
5. Read SRS.md
6. Extract all FR-X IDs from the SRS (Grep for `### FR-\d+:`)

### Phase 3: Step Execution

Execute each step file in order:

```
steps/01-structure.md       → SDD section presence and Meta field completeness
steps/02-traceability.md    → SRS↔SDD requirement traceability
steps/03-code-references.md → File path verification via Glob
steps/04-consistency.md     → Internal consistency checks, ASK-FIRST governance for design decisions
```

**For each step:**
1. Read the step file
2. Execute all checks described
3. Record findings with severity (CRITICAL/ERROR/WARNING/INFO)
4. Proceed to next step (no short-circuit)

### Phase 4: Self-Check Findings

Before compiling results, run two checks against every CRITICAL and ERROR finding produced in Phase 3:

1. **Disconfirmation** — confirm the cited evidence directly proves the defect. Classify each finding's confidence against the evidence standards loaded in Phase 1. LOW-confidence findings get one re-investigation pass via a targeted Read or Grep on the cited section; if the finding cannot reach HIGH or MEDIUM, drop it — adversarial rigor means checking everything, not reporting everything.
2. **Severity calibration** — verify the assigned severity matches what the rules file specifies for that class of defect. Downgrade if a WARNING-level rule produced an ERROR finding; upgrade if a CRITICAL-level rule produced a WARNING. Do not invent severities the rules file does not define.

Record a confidence level (HIGH or MEDIUM) on every finding that survives. Findings that cannot reach at least MEDIUM after one re-investigation pass are dropped, not downgraded into WARNING noise.

**Loop guard:** One re-investigation pass per LOW-confidence finding. If a second check would be needed, drop the finding.

### Phase 5: Result Compilation

1. Collect all surviving issues from Phase 4
2. Determine overall status:
   - **VALID**: No CRITICAL or ERROR issues
   - **INVALID**: Has at least one CRITICAL or ERROR issue
3. Sort issues by severity (CRITICAL first, then ERROR, WARNING, INFO)
4. Count issues by severity

### Phase 6: Report Writing

Write the report to the registered output target.

Report format:
```markdown
# Design Audit Report

**Feature:** [feature name]
**Date:** [current date]
**Status:** [VALID | INVALID]
**Issues:** [N] critical, [N] errors, [N] warnings, [N] info

---

## Issues

### CRITICAL
1. **[Section]** (HIGH|MEDIUM) — [issue description]
   Suggestion: [how to fix]

### ERROR
1. **[Section]** (HIGH|MEDIUM) — [issue description]
   Suggestion: [how to fix]

### WARNING
1. **[Section]** (HIGH|MEDIUM) — [issue description]
   Suggestion: [how to fix]

### INFO
1. **[Section]** (HIGH|MEDIUM) — [issue description]
   Suggestion: [how to fix]

---

## Steps Executed

| Step | Focus | Issues Found |
|------|-------|-------------|
| 1 | Structure | [N] |
| 2 | Traceability | [N] |
| 3 | Code References | [N] |
| 4 | Consistency | [N] |
```

Omit severity sections that have zero issues.
