# Step 11: Create Summary

Compile all findings from steps 1-10 into a structured report.

**Note:** Do NOT write any files in this step. Do NOT return output yet.
You are preparing the report content; step 12 handles the final output.

## Report Structure

Create your report with the following structure **in this exact order**:

```markdown
# [Agent Name] Review Report

**Reviewed:** [DD.MM.YYYY]
**Type:** [Sub-agent | Skill]
**Domain:** [domain-name | Not specified]

---

## FINAL VERDICT

**Overall Status:** [PASS | WARNINGS | ISSUES FOUND]

[2-4 sentence summary of the most urgent and impactful findings. Be direct and actionable. State clearly whether the agent is ready for use and what, if anything, blocks it.]

---

## Compliance Summary

| Category | Checks | Passed | N/A | Issues |
|----------|--------|--------|-----|--------|
| Structural | 6 | [n] | [n] | [n] |
| Core Frontmatter | 4 | [n] | [n] | [n] |
| Type Frontmatter | 4 or 8 | [n] | [n] | [n] |
| Description | 5 | [n] | [n] | [n] |
| Content Sections | 9 or 2 | [n] | [n] | [n] |
| Tools | 5 | [n] | [n] | [n] |
| Patterns | 6 | [n] | [n] | [n] |
| Domain-Specific | [N or 0] | [n] | [n] | [n] |
| Coherence | 8 | [n] | [n] | [n] |
| Content Hygiene | 14 | [n] | [n] | [n] |
| Contract & Guide | 10 | [n] | [n] | [n] |

**Compliance Rate:** [X]% ([passed]/[total] checks passed)

---

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | [n] |
| ERROR | [n] |
| WARNING | [n] |
| INFO | [n] |

---

## Issues & Recommendations

Every CRITICAL and ERROR finding carries a Confidence value — **HIGH** (direct file:line evidence from the reviewed artifact) or **MEDIUM** (structural pattern mismatch across the artifact's files). LOW-confidence findings were re-investigated once in Phase 5 and either lifted to HIGH/MEDIUM or dropped; they never appear here. WARNING and INFO findings also carry Confidence when the underlying check is heuristic; otherwise omit the value.

[For EACH issue found, regardless of severity, include:]

### [SEVERITY] · [CONFIDENCE]: [Descriptive Issue Title]

**Location:** `file:line`

**Issue:** [Detailed explanation of what's wrong, why it matters, and what impact it has]

**Recommendation:** [Specific, actionable steps to fix this issue. Be precise about what to change and where.]

---

[Order issues by severity first (CRITICAL, ERROR, WARNING, INFO), then by confidence within each severity (HIGH before MEDIUM)]
[Include ALL issues that survived the Phase 5 self-check — do not omit any]

---

## Checks Summary by Step

[Brief summary using result icons for quick scanning]

### Step 1: Structural Validation
- [icon] 1.1 Name format (kebab-case)
- [icon] 1.2 File location correct
- [icon] 1.3 File name matches folder
- [icon] 1.4 YAML syntax valid
- [icon] 1.6 Path separators (forward slashes)
- [icon] 1.7 No empty folders

### Step 2: Core Frontmatter
- [icon] 2.1 Name field present and matches
- [icon] 2.2 Description field present
- [icon] 2.3 Model value valid
- [icon] 2.4 Permission mode valid

### Step 3: Type-Specific Frontmatter
[Include 3A checks for sub-agent OR 3B checks for skill]

### Step 4: Description Quality
- [icon] 4.1 Third person voice
- [icon] 4.2 WHAT component present
- [icon] 4.3 WHEN component present
- [icon] 4.4 Trigger keywords present
- [icon] 4.5 Specific enough to differentiate

### Step 5: Content Sections
- [icon] 5.1 Persona (H1 title)
- [icon] 5.2 Mandate section
- [icon] 5.3 Constraints section
- [icon] 5.4 Responsibilities section
- [icon] 5.5 Workflow section
- [icon] 5.x Conditional sections...

### Step 6: Tools Validation
- [icon] 6.1 Tools match stated purpose
- [icon] 6.2 Red flag: Read-only + Write tools
- [icon] 6.3 Red flag: Advisory + Agent tool
- [icon] 6.4 Red flag: Reviewer + Bash
- [icon] 6.5 Permission mode aligns with tools

### Step 7: Patterns Validation
- [icon] 7.1 Appropriate patterns for type
- [icon] 7.2 Loop guards implementation
- [icon] 7.3 Tool execution verification
- [icon] 7.4 File loading strategy
- [icon] 7.5 Pattern file completeness
- [icon] 7.6 Constraint Enforcement Hierarchy compliance

### Step 8: Coherence & Duplication
- [icon] 8.1 Purpose-tools alignment
- [icon] 8.2 Purpose-model alignment
- [icon] 8.3 Purpose-patterns alignment
- [icon] 8.4 Internal consistency
- [icon] 8.5 No agent duplication
- [icon] 8.6 No skill duplication
- [icon] 8.7 Reference-instruction consistency
- [icon] 8.8 Output persistence (self-commit)

### Step 9: Content Hygiene
- [icon] 9.1 No cross-file redundancy
- [icon] 9.2 No information agent can't act on
- [icon] 9.3 No system-enforced constraint duplication
- [icon] 9.4 No self-referential file paths
- [icon] 9.5 No vague instructions with bounded equivalents
- [icon] 9.6 No duplicate content across variants
- [icon] 9.7 No contradictory authority claims
- [icon] 9.8 No cross-boundary knowledge
- [icon] 9.9 No orphaned references
- [icon] 9.10 No redundant indirection
- [icon] 9.11 No cross-boundary role references
- [icon] 9.12 Emphasis calibration
- [icon] 9.13 Constraint rationale
- [icon] 9.14 Rationale discipline

### Step 10: Contract & Guide Validation
- [icon] 10.1 Contract exists
- [icon] 10.2 Required sections present
- [icon] 10.3 Input spec matches capabilities
- [icon] 10.4 Output spec matches output
- [icon] 10.5 No internal implementation details
- [icon] 10.6 Language and format quality
- [icon] 10.7 Multi-mode coverage
- [icon] 10.8 Guide exists
- [icon] 10.9 Guide has required sections
- [icon] 10.10 Guide content accuracy (counts, file trees, behavioral descriptions match agent)

### Domain-Specific Checks
[If domain was detected, list each domain check using its step-based ID (e.g., 1.D1, 7.D1, 9.D1)]
[If no domain, note: "No domain specified — domain checks skipped"]

---

## Comprehensive Report

[THOROUGH, DETAILED documentation including:]

### Step-by-Step Validation Details

[For EACH step (1-10), document:]

#### Step N: [Step Name]

**Check N.X: [Check Name]**

**What I checked:** [Description of what was verified]

**How I verified:** [Tool used, file read, search performed]

**Result:** [PASS/FAIL/WARNING/INFO/N/A]

**Details:** [Full explanation with file:line references where applicable]

---

[Continue for all checks in all steps]

### Duplication Analysis

**Agents Scanned:**
- [agent-name]: [brief purpose] - [overlap finding]
- ...

**Skills Scanned:**
- [skill-name]: [brief purpose] - [overlap finding]
- ...

**Conclusion:** [Summary of duplication analysis]

---

**Review Complete.** This review is advisory only. The decision to proceed rests with you.
```

## When Complete

You have compiled your findings into a structured summary.

**DO NOT write any files yet. DO NOT return output to the calling agent yet.**

Proceed IMMEDIATELY to step 12 for verification and final output.

Read: `steps/12-verify-checklist.md`
