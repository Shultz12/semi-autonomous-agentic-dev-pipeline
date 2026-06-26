# Step 12: Final Verification Checklist

Compare your summary against this complete checklist. **Every item must appear in your summary.**

---

## Base Checklist — 71 Items (Sub-Agent) / 68 Items (Skill)

**Note:** If a domain was detected, add domain-specific checks after step 7 base checks. See "Domain-Specific Checks" section below.

### Step 1: Structural (6 checks)
- [ ] 1.1 Name is kebab-case
- [ ] 1.2 File location correct (agents/ or skills/)
- [ ] 1.3 File name matches (name.md or SKILL.md)
- [ ] 1.4 YAML frontmatter syntax valid
- [ ] 1.6 All paths use forward slashes
- [ ] 1.7 No empty folders defined

### Step 2: Core Frontmatter (4 checks)
- [ ] 2.1 `name` field present and matches folder/file
- [ ] 2.2 `description` field present and non-empty
- [ ] 2.3 `model` value valid (if present)
- [ ] 2.4 `permissionMode` value valid (if present)

### Step 3: Type-Specific Frontmatter

**For Sub-agents (4 checks):**
- [ ] 3A.1 `tools` field format valid
- [ ] 3A.2 `disallowedTools` field format valid
- [ ] 3A.3 No tools/disallowedTools conflict
- [ ] 3A.4 Name/description length reasonable

**For Skills (8 checks):**
- [ ] 3B.1 `allowed-tools` field format valid
- [ ] 3B.2 `context` field value valid (if present)
- [ ] 3B.3 `agent` field present and valid (if context:fork)
- [ ] 3B.4 `user-invocable` is boolean (if present)
- [ ] 3B.5 `disable-model-invocation` is boolean (if present)
- [ ] 3B.6 `argument-hint` is non-empty (if present)
- [ ] 3B.7 `hooks` structure valid (if present)
- [ ] 3B.8 Skill name under 64 characters

### Step 4: Description Quality (5 checks)
- [ ] 4.1 Written in third person (no I/me/my)
- [ ] 4.2 WHAT component present (describes capabilities)
- [ ] 4.3 WHEN component present (usage guidance)
- [ ] 4.4 Trigger keywords present (for discovery)
- [ ] 4.5 Specific enough to differentiate

### Step 5: Content Sections (9 checks sub-agent, 2 skill)
- [ ] 5.1 Persona section (H1 header)
- [ ] 5.2 Mandate section present
- [ ] 5.3 Core Constraints (structured prohibitions and guidelines)
- [ ] 5.4 Responsibilities (numbered list)
- [ ] 5.5 Workflow section (phased approach)
- [ ] 5.6 Output Format (if produces structured output)
- [ ] 5.7 Codebase References (if references files)
- [ ] 5.8 Inter-Agent Communication (if uses handoffs)
- [ ] 5.9 Verification Protocol (if reviewer/validator)

*For skills: 5.10 Title, 5.11 Introduction*

### Step 6: Tools Validation (5 checks)
- [ ] 6.1 Tools match stated purpose
- [ ] 6.2 Red flag checked: Read-only + Write tools
- [ ] 6.3 Red flag checked: Advisory + Agent tool
- [ ] 6.4 Red flag checked: Reviewer + Bash
- [ ] 6.5 Permission mode aligns with tool risk

### Step 7: Behavioral Patterns (6 checks)
- [ ] 7.1 Appropriate patterns for agent type
- [ ] 7.2 Loop guards implemented (if iterates)
- [ ] 7.3 Tool Execution Verification (if reviewer)
- [ ] 7.4 File loading strategy (if multi-file)
- [ ] 7.5 Pattern file completeness (if has pattern files)
- [ ] 7.6 Constraint Enforcement Hierarchy compliance

### Step 8: Coherence & Duplication (8 checks)
- [ ] 8.1 Purpose-tools alignment
- [ ] 8.2 Purpose-model alignment
- [ ] 8.3 Purpose-patterns alignment
- [ ] 8.4 Internal consistency
- [ ] 8.5 Existing agents scanned for overlap
- [ ] 8.6 Existing skills scanned for overlap
- [ ] 8.7 Reference-instruction consistency
- [ ] 8.8 Output persistence (self-commit for project writers)

### Step 9: Content Hygiene (14 checks)
- [ ] 9.1 No cross-file redundancy
- [ ] 9.2 No information agent can't act on
- [ ] 9.3 No system-enforced constraint duplication
- [ ] 9.4 No self-referential file paths
- [ ] 9.5 No vague instructions with bounded equivalents
- [ ] 9.6 No duplicate content across variants
- [ ] 9.7 No contradictory authority claims
- [ ] 9.8 No cross-boundary knowledge
- [ ] 9.9 No orphaned references
- [ ] 9.10 No redundant indirection
- [ ] 9.11 No cross-boundary role references
- [ ] 9.12 Emphasis calibration (proportionate use of NEVER/ALWAYS/MUST)
- [ ] 9.13 Constraint rationale present
- [ ] 9.14 Rationale discipline (judgment rationale compressed, maintainer rationale removed)

### Step 10: Contract & Guide Validation (10 checks)
- [ ] 10.1 Contract exists at expected path
- [ ] 10.2 Required sections present (Input, Output, Guarantees)
- [ ] 10.3 Input spec matches agent capabilities (field-by-field)
- [ ] 10.4 Output spec matches agent output (field-by-field, including written files)
- [ ] 10.5 No internal implementation details exposed
- [ ] 10.6 Language and format quality
- [ ] 10.7 Multi-mode coverage
- [ ] 10.8 Guide exists at expected path
- [ ] 10.9 Guide has required sections
- [ ] 10.10 Guide content accuracy (counts, file trees, behavioral descriptions match agent)

### Domain-Specific Checks (variable)

If a domain was detected, the domain's `domains/<domain>/domain.md` declares its own checklist items (numbered by the base step they extend, e.g., `1.D1`, `7.D1`, `9.D1`). Verify all domain checks from that file are present in the summary.

If no domain was detected: report "Domain checks: N/A (no domain specified)".

### Pipeline Conformance Checks (variable)

If the audited artifact participates in the feature pipeline, `essentials/pipeline-conformance.md` declares role-gated checks (`PC.A*`, `PC.B*`, `PC.C*`) and global checks (`PC.G*`). Verify every check gated on the detected roles, plus all `PC.G*` checks, appears in the summary.

If the artifact is not a pipeline participant: report "Pipeline conformance: N/A (not a pipeline participant)".

### Conditional Check Reporting Rule

**ALL base checks listed above must appear in the summary — no exceptions.** When a conditional
check does not apply to the artifact being reviewed, report it as N/A. Never omit a check.

**Base totals** (always reported):
- Sub-agent reviews: 71 base checks
- Skill reviews: 68 base checks

**Domain additions** (if domain detected):
- Add the domain's declared check count (from `domains/<domain>/domain.md`)
- Total = base + domain additions
- All domain checks must also appear in the summary

**Pipeline conformance additions** (if pipeline participant detected):
- Add the role-gated checks for each detected role plus all global `PC.G*` checks
- Total = base + domain additions + pipeline conformance additions
- All pipeline checks must also appear in the summary

---

## Verification Process

1. **Compare summary to checklist above**
   - Mark each item as present or missing
   - Count how many items are missing

2. **If items are missing:**
   - Do NOT re-read step files
   - Identify the missing check from this checklist
   - Perform that check directly on the artifact
   - Add the result to your summary
   - Re-verify against checklist
   - Repeat until all items present

3. **Determine overall status:**
   - **PASS**: No CRITICAL or ERROR issues
   - **WARNINGS**: No CRITICAL/ERROR but has WARNING issues
   - **ISSUES FOUND**: Has CRITICAL or ERROR issues

---

## MANDATORY FINAL ACTIONS

After verification is complete, you MUST perform EXACTLY TWO actions in this order.
Failure to complete both actions means your task is INCOMPLETE.

### ACTION 1: WRITE THE REVIEW FILE

**YOU MUST USE THE WRITE TOOL NOW.**

Execute a Write tool call with:
- **Path:** `.claude/reviews/agent-auditor/DD.MM.YYYY [Agent Name] Review.md`
  - **Directory is always `.claude/reviews/agent-auditor/`** — your own name as the report's producer, constant for every review. Never substitute the audited artifact's name into the directory: reviewing `code-investigator` still writes to `reviews/agent-auditor/`, not `reviews/code-investigator/`.
  - Use current date in DD.MM.YYYY format (e.g., `3.2.2026`)
  - Only `[Agent Name]` in the filename varies — the display name of the artifact **under review**, its `name` frontmatter in Title Case with spaces, not the caller. Reviewing `agent-auditor` yields `Agent Auditor`; reviewing `code-reviewer` yields `Code Reviewer`.
  - This MUST match the path you registered in Phase 1 — write to that exact file.
  - Example: `.claude/reviews/agent-auditor/3.2.2026 Code Reviewer Review.md`
- **Content:** The COMPLETE report including ALL sections:
  - Header with date and type
  - FINAL VERDICT
  - Compliance Summary
  - Severity Summary
  - Issues & Recommendations
  - Checks Summary by Step
  - Comprehensive Report (detailed validation documentation)
  - Footer: "Review Complete. This review is advisory only."

Create the `.claude/reviews/agent-auditor/` directory if it does not exist.

**THIS IS NOT OPTIONAL. YOU MUST WRITE THIS FILE BEFORE PROCEEDING.**

### ACTION 2: RETURN THE ACTIONABLE SUMMARY

After writing the file, return DIRECTLY to the calling agent (as your final response) these sections ONLY:

- `# [Agent Name] Review Report` (header with date/type)
- `## FINAL VERDICT` (status + 2-4 sentence summary)
- `## Compliance Summary` (table + rate)
- `## Severity Summary` (table)
- `## Issues & Recommendations` (all issues)
- `## Checks Summary by Step` (icons for each check)
- `**Review file:** .claude/reviews/agent-auditor/[filename].md`

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
