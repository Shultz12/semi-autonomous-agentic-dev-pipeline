# domain-auditor Interface Contract

## Input

A domain name (kebab-case) to review. The domain must exist in both:
- `.claude/skills/agent-architect/domains/<name>/`
- `.claude/agents/agent-auditor/domains/<name>/`

The prompt should specify the domain name clearly:
```
Review the domain: dev-tooling
```

## Output

The agent performs TWO mandatory actions:

### 1. Writes Handoff File (ALWAYS)

**Path:** `.claude/reviews/domain-auditor/DD.MM.YYYY [Domain Name] Domain Review.md`

Contains the COMPLETE report including the Comprehensive Report section.

### 2. Returns Actionable Summary

Returns directly to the calling agent:
- FINAL VERDICT (status + summary)
- Compliance Summary (table + rate)
- Severity Summary (table)
- Issues & Recommendations (all issues)
- Checks Summary by Step (icons for each check)
- Handoff file path

**Does NOT include:** Comprehensive Report (only in file)

### Main Agent Protocol

When receiving the reviewer's output, the main agent MUST:

1. **Present to user** the direct output it received (already excludes Comprehensive Report)
2. **Inform user** that the full report (including comprehensive details) is available in the handoff file

## Overall Status Definitions

| Status | Meaning |
|--------|---------|
| **PASS** | No CRITICAL or ERROR issues found |
| **WARNINGS** | No CRITICAL/ERROR but has WARNING issues |
| **ISSUES FOUND** | Has CRITICAL or ERROR issues that should be fixed |

## Severity Definitions

| Severity | Meaning | Action Required |
|----------|---------|-----------------|
| **CRITICAL** | Domain won't function correctly | Must fix before use |
| **ERROR** | Violates standards, may cause issues | Should fix |
| **WARNING** | Suboptimal but will work | Consider fixing |
| **INFO** | Suggestion for improvement | Optional |

## Confidence Definitions

Every CRITICAL and ERROR finding in the **Issues & Recommendations** table carries a Confidence value. WARNING and INFO findings may carry one but are not required to.

| Confidence | Meaning |
|------------|---------|
| **HIGH** | Direct quote from the pack plus a tool-verified discrepancy (Grep result, Read excerpt) that proves the violation. Required for any codebase-drift claim. |
| **MEDIUM** | Structural issue confirmed by tool output: missing/empty section via Read, broken cross-reference via Glob, orphan term via Grep. |

LOW-confidence findings are dropped during the agent's self-check step and never appear in output. LOW-confidence codebase-drift claims are dropped, not downgraded to WARNING.

## Issues & Recommendations Schema

The Issues & Recommendations section is a single table with these columns, in order:

| # | Severity | Confidence | Location | Issue | Recommendation |

- **Severity:** CRITICAL | ERROR | WARNING | INFO
- **Confidence:** HIGH | MEDIUM (required for CRITICAL/ERROR; `—` allowed for WARNING/INFO)
- **Location:** `file:line` for pack files; `file:line` or `file` for codebase references
- **Issue:** for codebase-drift findings, must include the verbatim pack quote and the Grep/Read output establishing the discrepancy

## Guarantees

- **Handoff file is ALWAYS written** (not optional)
- Reviews 36 base validation criteria across 7 categories (Structural, Architect Domain, Patterns, Auditor Domain, Consistency, Registry, Content Hygiene)
- Every finding backed by actual file read
- Every CRITICAL/ERROR finding carries a Confidence value (HIGH or MEDIUM); LOW-confidence findings are dropped, not reported
- All findings include file:line references
- Codebase-drift findings cite a specific named identifier (function, class, file, flag) plus a tool-verified discrepancy
- Advisory only — cannot block creation
- Output format is consistent regardless of findings
