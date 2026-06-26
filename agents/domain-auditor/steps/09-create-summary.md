# Step 9: Create Summary

Compile the findings that survived the self-check (step 08) into a structured report. CRITICAL and ERROR findings carry HIGH or MEDIUM Confidence; WARNING and INFO findings pass through from steps 1–7 unchanged.

**Note:** Do NOT write any files in this step. Do NOT return output yet.
You are preparing the report content; step 10 handles the final output.

## Report Structure

Create your report with the following structure **in this exact order**:

```markdown
# [Domain Name] Domain Review Report

**Reviewed:** [DD.MM.YYYY]

---

## FINAL VERDICT

**Overall Status:** [PASS | WARNINGS | ISSUES FOUND]

[2-4 sentence summary of the most urgent and impactful findings. Be direct and actionable. State clearly whether the domain is ready for use and what, if anything, blocks it.]

---

## Compliance Summary

| Category | Checks | Passed | N/A | Issues |
|----------|--------|--------|-----|--------|
| Structural | 4 | [n] | [n] | [n] |
| Architect Domain | 7 | [n] | [n] | [n] |
| Patterns | 7 | [n] | [n] | [n] |
| Auditor Domain | 6 | [n] | [n] | [n] |
| Consistency | 3 | [n] | [n] | [n] |
| Registry | 4 | [n] | [n] | [n] |
| Content Hygiene | 4 | [n] | [n] | [n] |

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

| # | Severity | Confidence | Location | Issue | Recommendation |
|---|----------|------------|----------|-------|----------------|
| 1 | [CRITICAL\|ERROR\|WARNING\|INFO] | [HIGH\|MEDIUM\|—] | `file:line` | [What's wrong, why it matters, impact] | [Specific actionable fix — what to change and where] |

**Rules for the table:**
- Order rows by severity: CRITICAL first, then ERROR, WARNING, INFO last.
- Include ALL surviving issues — do not omit any.
- **Confidence column:** required (HIGH or MEDIUM) for every CRITICAL and ERROR row. For WARNING and INFO rows, leave the cell as `—` unless the writer chose to assign a value during the self-check.
- For drift findings, the **Issue** cell must include the verbatim pack quote and the tool output (or its absence) that establishes the discrepancy.
- The **Location** cell uses `file:line` for pack files and `file:line` or `file` for codebase references.

---

## Checks Summary by Step

[Brief summary using result icons for quick scanning]

### Step 1: Structural Validation
- [icon] 1.1 Domain name format (kebab-case)
- [icon] 1.2 Agent Architect directory exists
- [icon] 1.3 Agent Auditor directory exists
- [icon] 1.4 Forward slash paths

### Step 2: Agent Architect domain.md
- [icon] 2.1 Scope section present
- [icon] 2.2 Required Scans table
- [icon] 2.3 Optional Scans table
- [icon] 2.4 Conventions section
- [icon] 2.5 Convention quality
- [icon] 2.6 Tool Recommendations table
- [icon] 2.7 Domain Resources section

### Step 3: Patterns & Templates
- [icon] 3.1 Pattern index exists
- [icon] 3.2 Available Patterns table
- [icon] 3.3 Pattern Selection Guide
- [icon] 3.4 Pattern file required sections
- [icon] 3.5 No orphaned patterns
- [icon] 3.6 Template file structure
- [icon] 3.7 Templates referenced in Domain Resources

### Step 4: Agent Auditor domain.md
- [icon] 4.1 Scope section present
- [icon] 4.2 Domain Checks section
- [icon] 4.3 Check ID format
- [icon] 4.4 Check quality
- [icon] 4.5 Additional Checklist Count accuracy
- [icon] 4.6 Alignment section

### Step 5: Cross-System Consistency
- [icon] 5.1 Scope descriptions align
- [icon] 5.2 Auditable conventions have checks
- [icon] 5.3 Domain name consistent

### Step 6: Registry Entries
- [icon] 6.1 Agent Architect _index.md Available Domains
- [icon] 6.2 Agent Architect _index.md Decision Matrix
- [icon] 6.3 Agent Auditor _index.md Available Domains
- [icon] 6.4 Agent Architect SKILL.md Reference Registry

### Step 7: Content Hygiene
- [icon] 7.1 No cross-file redundancy
- [icon] 7.2 No orphaned references
- [icon] 7.3 No vague instructions
- [icon] 7.4 No scope overlap with existing domains

---

## Comprehensive Report

[THOROUGH, DETAILED documentation including:]

### Step-by-Step Validation Details

[For EACH step (1-7), document:]

#### Step N: [Step Name]

**Check N.X: [Check Name]**

**What I checked:** [Description of what was verified]

**How I verified:** [Tool used, file read, search performed]

**Result:** [PASS/FAIL/WARNING/INFO/N/A]

**Details:** [Full explanation with file:line references where applicable]

---

[Continue for all checks in all steps]

---

**Review Complete.** This review is advisory only. The decision to proceed rests with you.
```

## When Complete

You have compiled your findings into a structured summary.

**DO NOT write any files yet. DO NOT return output to the calling agent yet.**

Proceed IMMEDIATELY to step 10 for verification and final output.

Read: `steps/10-verify-checklist.md`
