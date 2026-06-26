# Domain Auditor - User Guide

## What It Does

The Domain Auditor validates domain knowledge packs before they're put into use. Think of it as a quality control inspector that checks your domain designs against established standards and best practices.

**Key Points:**
- It's **advisory only** - it reports findings but cannot block creation
- It checks **36 base validation criteria** across 7 categories
- It validates **both systems** - Agent Architect domain files and Agent Auditor domain files
- It checks **registry entries** across all required locations
- The final decision to proceed always rests with you

---

## Audit Posture

The auditor reviews packs adversarially: strict, by-the-book, and skeptical. It defaults to doubt — every loaded standard is checked against every pack section and every cross-reference. Borderline issues are surfaced rather than absorbed on the pack author's behalf. Pack content ages faster than spec or code, so a clean verdict is earned by coverage, not by skimming.

Rigor here means coverage. It does **not** mean inflated severities or invented drift. Every CRITICAL or ERROR finding goes through a self-check before reporting:

- **Disconfirmation** — the cited tool output must directly prove the violation. Codebase-drift findings must cite a specific named identifier (function, class, file, flag) and include a Grep/Read result establishing the discrepancy. Conceptual paraphrases that can't be tool-verified are LOW confidence and dropped.
- **Severity calibration** — the assigned severity must match what the standards specify. Severities aren't invented.

Each surviving CRITICAL or ERROR finding carries a **Confidence** value:

| Confidence | What it means |
|------------|---------------|
| **HIGH** | Direct pack quote + tool-verified discrepancy. Required for drift claims. |
| **MEDIUM** | Structural issue confirmed by tool output (missing/empty section, broken cross-reference, orphan term). |

LOW-confidence findings are dropped during self-check and never appear in the report. LOW-confidence drift claims in particular are dropped, not softened to WARNING — soft drift findings create noise that looks authoritative.

---

## When It's Used

The reviewer is typically called by the Domain Architect after you've designed a new domain and given permission to review it. You might also invoke it directly to validate an existing domain.

**Common scenarios:**
- Before finalizing a new domain knowledge pack
- After updating an existing domain
- When auditing domain quality
- When troubleshooting why domain-specific checks aren't working

---

## What It Checks

### 1. Structural Validation (4 checks)
- Domain name follows kebab-case format (`dev-tooling`, not `DevTooling`)
- Agent Architect directory exists with `domain.md`
- Agent Auditor directory exists with `domain.md`
- All file paths use forward slashes

### 2. Agent Architect domain.md Quality (7 checks)
- Scope section present with specific criteria
- Required Scans table present
- Optional Scans table present (or justified absence)
- Conventions section with entries
- Each convention is specific, actionable, verifiable
- Tool Recommendations table present
- Domain Resources section with links

### 3. Patterns & Templates (7 checks)
- Pattern index (`_index.md`) exists
- Available Patterns table lists all files
- Pattern Selection Guide table present
- Each pattern has required sections (Purpose, When to Apply, Implementation, Rationale)
- No orphaned patterns (index and files match)
- Template files well-structured (if present)
- Templates referenced in Domain Resources (if present)

### 4. Agent Auditor domain.md Quality (6 checks)
- Scope section present
- Domain Checks section with definitions
- Check IDs follow `<step>.D<n>` format
- Each check has concrete verification and pass/fail criteria
- Additional Checklist Count matches actual count
- Alignment section with correct domain name

### 5. Cross-System Consistency (3 checks)
- Scope descriptions align between Architect and Auditor
- Verifiable conventions have corresponding auditor checks
- Domain name consistent across both systems

### 6. Registry Entries (4 checks)
- Domain in Agent Architect `_index.md` Available Domains table
- Domain in Agent Architect `_index.md` Decision Matrix
- Domain in Agent Auditor `_index.md` Available Domains table
- Domain in Agent Architect `SKILL.md` Reference Registry

### 7. Content Hygiene (4 checks)
- No cross-file redundancy
- No orphaned references (broken links)
- No vague instructions where specific alternatives exist
- Domain scope doesn't fully overlap with existing domains

---

## Understanding the Report

### Overall Status

| Status | Meaning |
|--------|---------|
| **PASS** | No critical or error-level issues found |
| **WARNINGS** | Functional but has areas for improvement |
| **ISSUES FOUND** | Has critical or error-level issues that should be fixed |

### Severity Levels

| Severity | What It Means | Action |
|----------|---------------|--------|
| **CRITICAL** | Domain won't function correctly | Must fix before use |
| **ERROR** | Violates standards, may cause issues | Should fix |
| **WARNING** | Suboptimal but will work | Consider fixing |
| **INFO** | Suggestion for improvement | Optional |

### Confidence (CRITICAL and ERROR rows)

The Issues & Recommendations table includes a **Confidence** column. CRITICAL and ERROR rows always carry HIGH or MEDIUM. WARNING and INFO rows show `—` unless the auditor chose to assign a value.

- **HIGH** — direct pack quote plus tool-verified discrepancy.
- **MEDIUM** — structural issue confirmed by tool output.

If a finding looks weakly evidenced, check its Confidence value first. Anything in the report has already survived a self-check; LOW-confidence findings were dropped before you saw the report.

---

## Tips for Passing Review

### Quick Wins
1. Use kebab-case for domain names: `dev-tooling` not `DevTooling`
2. Make conventions specific and testable, not vague
3. Use `<step>.D<n>` format for auditor check IDs
4. Register the domain in all 3 registries (Architect index, Auditor index, SKILL.md)

### Common Issues

| Issue | Fix |
|-------|-----|
| "Convention is vague" | Replace "follow best practices" with specific, verifiable rules |
| "Check has vague pass/fail" | Add concrete conditions (e.g., "file exists" not "looks good") |
| "Missing registry entry" | Add domain to all required `_index.md` files and SKILL.md |
| "Scope mismatch" | Align scope descriptions between Architect and Auditor domain files |
| "Orphaned pattern" | Ensure every pattern file is listed in `_index.md` and vice versa |

---

## Limitations

- **Advisory only**: Cannot prevent domain creation
- **No subjective judgments**: Doesn't evaluate whether your domain idea is "good"
- **Convention quality is heuristic**: May flag conventions that are intentionally general
- **Cross-system alignment is semantic**: Compares meaning, not exact wording

---

## Related Files

The reviewer's validation logic is defined in:
```
.claude/agents/domain-auditor/
├── domain-auditor.md           # Main agent definition
├── essentials/
│   └── domain-standards.md     # All validation criteria
└── steps/                      # Step-by-step validation logic
    ├── 01-structural.md
    ├── 02-architect-domain.md
    ├── 03-patterns.md
    ├── 04-auditor-domain.md
    ├── 05-consistency.md
    ├── 06-registry.md
    ├── 07-content-hygiene.md
    ├── 08-self-check.md
    ├── 09-create-summary.md
    └── 10-verify-checklist.md
```

Supporting files:
- `.claude/agents/interface-contracts/domain-auditor.contract.md` - Interface contract
- `.claude/documentation/domain-auditor.guide.md` - This guide

You don't need to read the agent files - they're for the AI. This guide covers everything you need to know as a user.
