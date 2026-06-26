# Full Validation Mode

Default and only mode for spec-auditor. Runs all 5 validation steps against SRS and BDD documents.

## Workflow

### Phase 1: Input Analysis

1. Parse input to extract the feature directory path
2. Determine the specs directory: `<feature-dir>/specs/`
3. Validate the specs directory exists via Glob; if not, return INVALID immediately with CRITICAL issue

### Phase 2: Rules Loading

1. Read `essentials/spec-review-rules.md`
2. Internalize the required sections, fields, and validation rules

### Phase 3: Document Loading

1. Read `<specs-dir>/SRS.md` using Read tool
2. If SRS.md doesn't exist or is empty, return INVALID immediately with CRITICAL issue
3. Extract `active-layers` from SRS frontmatter for conditional section checks
4. Extract feature name from SRS frontmatter `feature` field (used to locate BDD files)
5. Glob `<specs-dir>/bdd/` to discover all BDD files

### Phase 4: Step Execution

Execute each step file in order:

```
steps/01-structure.md       → File presence and SRS section structure
steps/02-requirements.md    → FR-X quality (IDs, acceptance criteria, priority)
steps/03-bdd-validation.md  → CONTEXT.md structure, .feature structure, Gherkin syntax
steps/04-traceability.md    → SRS↔BDD coverage (every FR-X has plausible BDD scenario)
steps/05-content-quality.md → Vague language detection in SRS
```

**For each step:**
1. Read the step file
2. Execute all checks described
3. Record findings with severity (CRITICAL/ERROR/WARNING/INFO)
4. Proceed to next step (no short-circuit)

### Phase 5: Self-Check Findings

Before compiling the result, run two checks against every CRITICAL and ERROR finding produced in Phase 4:

1. **Disconfirmation** — score each finding's evidence against the Evidence Standards. For any finding scoring LOW, re-read the cited section with a targeted Read/Grep call to lift it to HIGH or MEDIUM.
2. **Severity calibration** — verify the assigned severity matches the level the rules specify for that defect class. Do not promote a WARNING to ERROR to add weight, or downgrade an ERROR to WARNING to soften the verdict.

Record a Confidence level (HIGH or MEDIUM) on every surviving CRITICAL or ERROR finding. WARNING and INFO findings also carry a Confidence value but are exempt from the re-investigation loop.

**Loop guard:** One re-investigation pass per finding. A finding still scoring LOW after re-investigation is dropped.

### Phase 6: Result Compilation

1. Collect all surviving issues across all steps
2. Determine overall status:
   - **VALID**: No CRITICAL or ERROR issues
   - **INVALID**: Has at least one CRITICAL or ERROR issue
3. Sort issues by severity (CRITICAL first, then ERROR, WARNING, INFO); within a severity, HIGH confidence before MEDIUM
4. Count issues by severity

### Phase 7: Report Writing

Write the report to the target path registered in step 3 of the agent definition, using the findings collected in Phases 4–6.

Report format:
```markdown
# Spec Audit Report

**Feature:** [feature name]
**Date:** [current date]
**Status:** [VALID | INVALID]
**Issues:** [N] critical, [N] errors, [N] warnings, [N] info

---

## Issues

### CRITICAL
1. **[File]** Section: [section] — [issue description]
   Confidence: [HIGH | MEDIUM]
   Evidence: [direct quote, section reference, or tool-output excerpt]
   Suggestion: [how to fix]

### ERROR
1. **[File]** Section: [section] — [issue description]
   Confidence: [HIGH | MEDIUM]
   Evidence: [direct quote, section reference, or tool-output excerpt]
   Suggestion: [how to fix]

### WARNING
1. **[File]** Section: [section] — [issue description]
   Confidence: [HIGH | MEDIUM]
   Suggestion: [how to fix]

### INFO
1. **[File]** Section: [section] — [issue description]
   Confidence: [HIGH | MEDIUM]
   Suggestion: [how to fix]

---

## Steps Executed

| Step | Focus | Issues Found |
|------|-------|-------------|
| 1 | Structure | [N] |
| 2 | Requirements | [N] |
| 3 | BDD Validation | [N] |
| 4 | Traceability | [N] |
| 5 | Content Quality | [N] |
```

Omit severity sections that have zero issues (e.g., if no CRITICAL issues, omit the CRITICAL heading).

### Phase 7.5: Commit Report

After the report exists on disk (satisfying the completion gate), commit it path-scoped before returning.

1. Read `.claude/skills/commit-to-git/SKILL.md` and follow it to commit the report file.
2. Pass:
   - `Agent: spec-auditor`
   - `Path:` the report file path (written in Phase 7, or recognized at the target path by agent definition step 4)
   - `Subject:` `audit(<slug>): spec audit attempt <K>` where `<slug>` is the basename of the feature directory (the parent of `specs/` — e.g., `<specs-dir>` = `.project/cycles/06-02-2026-user-auth/specs/` → `<slug>` = `06-02-2026-user-auth`) and `<K>` is the attempt number from Phase 7.
3. Commit nothing else. One commit per invocation.
4. Capture the resulting short hash for Phase 8. Map the outcome to a `Commit:` value:
   - Successful commit → `<short-hash>`
   - No-op commit (re-dispatch produced byte-identical content; `commit-to-git` reports skipped) → `skipped`
   - Failed commit (lock contention, hook rejection, transient error) → `failed`

A failed commit must never block the return — the report file is already written and the SubagentStop hook is satisfied.

### Phase 8: Return

Return the structured result to the calling agent using the format defined in the Output Format section of the agent definition (VALID, INVALID, or active-worktree refusal). Every return carries a `Commit:` field per the semantics defined there.
