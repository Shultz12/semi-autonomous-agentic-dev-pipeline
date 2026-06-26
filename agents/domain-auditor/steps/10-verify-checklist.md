# Step 10: Final Verification Checklist

Compare your summary against this complete checklist. **Every item must appear in your summary.**

---

## Base Checklist — 35 Items

### Step 1: Structural (4 checks)
- [ ] 1.1 Domain name is kebab-case
- [ ] 1.2 Agent Architect directory exists
- [ ] 1.3 Agent Auditor directory exists
- [ ] 1.4 All paths use forward slashes

### Step 2: Agent Architect domain.md (7 checks)
- [ ] 2.1 Scope section present with specific criteria
- [ ] 2.2 Required Scans table present
- [ ] 2.3 Optional Scans table present (or justified absence)
- [ ] 2.4 Conventions section present
- [ ] 2.5 Each convention is specific, actionable, verifiable
- [ ] 2.6 Tool Recommendations table present
- [ ] 2.7 Domain Resources section present

### Step 3: Patterns & Templates (7 checks)
- [ ] 3.1 `patterns/_index.md` exists
- [ ] 3.2 Available Patterns table lists all pattern files
- [ ] 3.3 Pattern Selection Guide table present
- [ ] 3.4 Each pattern file has required sections (Purpose, When to Apply, Implementation, Rationale)
- [ ] 3.5 No orphaned patterns (index ↔ files match)
- [ ] 3.6 Template files have valid structure (if exist)
- [ ] 3.7 Templates referenced in Domain Resources (if exist)

### Step 4: Agent Auditor domain.md (6 checks)
- [ ] 4.1 Scope section present
- [ ] 4.2 Domain Checks section present with definitions
- [ ] 4.3 Check IDs follow `<step>.D<n>` format
- [ ] 4.4 Each check has concrete What to verify + Pass/Fail
- [ ] 4.5 Additional Checklist Count matches actual count
- [ ] 4.6 Alignment section with correct domain name

### Step 5: Cross-System Consistency (3 checks)
- [ ] 5.1 Scope descriptions align between Architect and Auditor
- [ ] 5.2 Verifiable conventions have corresponding auditor checks
- [ ] 5.3 Domain name consistent across both systems

### Step 6: Registry Entries (4 checks)
- [ ] 6.1 Domain in Agent Architect `_index.md` Available Domains
- [ ] 6.2 Domain in Agent Architect `_index.md` Decision Matrix
- [ ] 6.3 Domain in Agent Auditor `_index.md` Available Domains
- [ ] 6.4 Domain in Agent Architect `SKILL.md` Reference Registry

### Step 7: Content Hygiene (4 checks)
- [ ] 7.1 No cross-file redundancy
- [ ] 7.2 No orphaned references
- [ ] 7.3 No vague instructions with bounded equivalents
- [ ] 7.4 Domain scope doesn't fully overlap with existing domains

### Conditional Check Reporting Rule

**ALL 35 base checks listed above must appear in the summary — no exceptions.** When a conditional check does not apply (e.g., no templates exist), report it as ⬜ N/A. Never omit a check.

---

## Verification Process

1. **Compare summary to checklist above**
   - Mark each item as present or missing
   - Count how many items are missing

2. **If items are missing** (maximum 3 verification iterations):
   - Do NOT re-read step files
   - Identify the missing check from this checklist
   - Perform that check directly on the domain files
   - Add the result to your summary
   - Re-verify against checklist
   - Repeat until all items present or 3 iterations reached
   - If max iterations reached, report remaining missing checks as ERROR and proceed

3. **Determine overall status:**
   - **PASS**: No CRITICAL or ERROR issues
   - **WARNINGS**: No CRITICAL/ERROR but has WARNING issues
   - **ISSUES FOUND**: Has CRITICAL or ERROR issues

---

## MANDATORY FINAL ACTIONS

After verification is complete, you MUST perform EXACTLY TWO actions in this order.
Failure to complete both actions means your task is INCOMPLETE.

### ACTION 1: WRITE THE HANDOFF FILE

**YOU MUST USE THE WRITE TOOL NOW.**

Execute a Write tool call with:
- **Path:** `.claude/reviews/domain-auditor/DD.MM.YYYY [Domain Name] Domain Review.md`
  - Use current date in DD.MM.YYYY format (e.g., `13.02.2026`)
  - Use domain's display name (capitalized with spaces, e.g., `Dev Tooling`)
  - Example: `.claude/reviews/domain-auditor/13.02.2026 Dev Tooling Domain Review.md`
- **Content:** The COMPLETE report including ALL sections:
  - Header with date
  - FINAL VERDICT
  - Compliance Summary
  - Severity Summary
  - Issues & Recommendations
  - Checks Summary by Step
  - Comprehensive Report (detailed validation documentation)
  - Footer: "Review Complete. This review is advisory only."

Create the `.claude/reviews/domain-auditor/` directory if it does not exist.

**THIS IS NOT OPTIONAL. YOU MUST WRITE THIS FILE BEFORE PROCEEDING.**

### ACTION 2: RETURN THE ACTIONABLE SUMMARY

After writing the file, return DIRECTLY to the calling agent (as your final response) these sections ONLY:

- `# [Domain Name] Domain Review Report` (header with date)
- `## FINAL VERDICT` (status + 2-4 sentence summary)
- `## Compliance Summary` (table + rate)
- `## Severity Summary` (table)
- `## Issues & Recommendations` (all issues)
- `## Checks Summary by Step` (icons for each check)
- `**Handoff file:** .claude/reviews/domain-auditor/[filename].md`

**DO NOT include the Comprehensive Report section in your direct output.**

---

## Result Icons

Use these icons consistently in your Checks Summary:

| Icon | Meaning |
|------|---------|
| ✅ | PASS |
| ❌ | FAIL (CRITICAL or ERROR) |
| ⚠️ | WARNING |
| ℹ️ | INFO |
| ⬜ | N/A |

---

## Review Complete

After completing BOTH actions (Write file AND Return summary), your task is done.
