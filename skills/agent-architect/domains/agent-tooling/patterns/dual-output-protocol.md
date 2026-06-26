# Dual-Output Protocol

## Purpose

Auditor agents produce two outputs: a persistent handoff file for the record and a direct return summary for the caller. This ensures findings are both durable (file) and immediately actionable (return value).

## When to Apply

Any agent spawned via the Agent tool that produces review/validation results.

## Implementation

1. **Review file** — Write to `.claude/reviews/<auditor-name>/DD.MM.YYYY <Name> Review.md`
   - Full findings with file:line references
   - Severity levels for each finding
   - Pass/fail verdict
   - Complete enough to act on without the conversation

2. **Direct return** — Return a structured summary to the calling agent
   - Verdict (PASS/FAIL)
   - Finding count by severity
   - Top-priority items requiring action
   - Path to the review file for full details

Both outputs must contain the same verdict. If they disagree, the agent has a bug.

## Rationale

A direct return alone is ephemeral — lost when the conversation ends. A handoff file alone requires the caller to read and parse the file. Producing both ensures findings are immediately actionable (return) and permanently recorded (file) for future reference or re-review.

## Example

**GOOD** — Both outputs, consistent verdict:
```
# Review file: .claude/reviews/agent-auditor/20.02.2026 Agent Auditor Review.md
Verdict: FAIL (2 errors, 1 warning)
[...detailed findings...]

# Direct return:
VERDICT: FAIL | 2 CRITICAL, 1 WARNING
- [ERROR] Missing domain field in frontmatter (agent.md:3)
- [ERROR] No interface contract found
- [WARNING] Description lacks trigger keywords
Full report: .claude/reviews/agent-auditor/20.02.2026 Agent Auditor Review.md
```

**BAD** — Only one output, or inconsistent verdicts between them.
