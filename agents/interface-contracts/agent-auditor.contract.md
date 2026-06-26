# agent-auditor Interface Contract

## Input

A path to an agent or skill definition file to review. Artifacts can be at personal or project level. Examples:
- `.claude/agents/my-agent/my-agent.md`
- `.claude/agents/my-agent/my-agent.md`
- `.claude/skills/my-skill/SKILL.md`
- `.claude/skills/my-skill/SKILL.md`

Specify the file path clearly in the prompt:
```
Review the agent definition at: .claude/agents/code-reviewer/code-reviewer.md
```

The auditor automatically detects the artifact's `domain` field from frontmatter and applies domain-specific validation rules when a known domain is found.

## Output

The agent performs TWO mandatory actions:

### 1. Writes Review File (ALWAYS)

**Path:** `.claude/reviews/agent-auditor/DD.MM.YYYY [Agent Name] Review.md`

Contains the COMPLETE report including the Comprehensive Report section.

### 2. Returns Actionable Summary

Returns directly to the calling agent:
- FINAL VERDICT (status + summary)
- Compliance Summary (table + rate, includes domain-specific row if applicable)
- Severity Summary (table)
- Issues & Recommendations (all issues, including domain-specific findings; each issue labeled with Severity and Confidence)
- Checks Summary by Step (icons, includes domain checks section if applicable)
- Review file path

**Does NOT include:** Comprehensive Report (only in file)

### Confidence Values

Every CRITICAL and ERROR finding carries a Confidence value alongside its Severity:

| Confidence | Meaning |
|------------|---------|
| **HIGH** | Direct `file:line` evidence from the reviewed artifact demonstrates the defect (e.g., named field absent from frontmatter, workflow step missing a required section, Glob returned no matches for a cited path). |
| **MEDIUM** | Structural pattern mismatch across the artifact's files (e.g., other constraints carry rationale while this one does not; contract documents a field the workflow never populates). |

LOW-confidence findings are never reported. They are re-investigated once and either lifted to HIGH/MEDIUM with stronger evidence, or dropped. WARNING and INFO findings carry Confidence when the underlying check is heuristic; otherwise it may be omitted.

### Main Agent Protocol

When receiving the reviewer's output, the main agent MUST:

1. **Present to user** the direct output it received (already excludes Comprehensive Report)
2. **Inform user** that the full report (including comprehensive details) is available in the review file

## Overall Status Definitions

| Status | Meaning |
|--------|---------|
| **PASS** | No CRITICAL or ERROR issues found |
| **WARNINGS** | No CRITICAL/ERROR but has WARNING issues |
| **ISSUES FOUND** | Has CRITICAL or ERROR issues that should be fixed |

## Severity Definitions

| Severity | Meaning | Action Required |
|----------|---------|-----------------|
| **CRITICAL** | Agent won't function correctly | Must fix before creation |
| **ERROR** | Violates standards, may cause issues | Should fix |
| **WARNING** | Suboptimal but will work | Consider fixing |
| **INFO** | Suggestion for improvement | Optional |

## Guarantees

- **Review file is ALWAYS written** (not optional) — the write is not gated on self-check outcome; self-check determines only which findings the file contains
- Reviews 71 base validation criteria (sub-agent) or 68 (skill) across 10 categories — including instructional consistency checks (emphasis calibration, constraint rationale, reference-instruction consistency, pattern file completeness) — plus domain-specific checks when a domain is detected
- Domain detection is automatic from artifact's `domain` frontmatter field
- Every finding backed by actual file read
- All findings include file:line references
- Every CRITICAL and ERROR finding carries a Confidence value (HIGH or MEDIUM); LOW-confidence findings are re-investigated or dropped before the summary is compiled, never reported
- Checks for duplication with existing agents/skills at both personal (`.claude/`) and project (`.claude/`) levels
- Advisory only - cannot block creation
- Output format is consistent regardless of findings
