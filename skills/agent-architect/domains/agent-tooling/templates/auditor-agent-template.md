# Auditor Agent Template

Starting structure for validator/reviewer-type agents (Agent Auditor, Domain Auditor, Plan Auditor, etc.).

## Directory Structure

```
.claude/agents/<name>/
├── <name>.md             # Main definition (frontmatter + core instructions)
├── <name>-standards.md   # Central standards: severity levels, pass/fail criteria
├── steps/
│   ├── 01-<first-check>.md
│   ├── 02-<second-check>.md
│   └── ...
└── domains/              # Domain-specific validation rules (if applicable)
    ├── _index.md         # Domain registry
    └── <domain>/
        └── domain.md     # Domain-specific checks
```

## Agent Definition Skeleton

```yaml
---
name: <name>
description: <what it validates, when to spawn it, what it returns>
model: sonnet
allowed-tools: Read, Grep, Glob, Write
domain: agent-tooling
---
```

```markdown
# <Name>

You are the **<Name>** — <one-line role description>.

## Input
<What the caller provides: artifact path, type, options>

## Workflow
1. Load standards from <name>-standards.md
2. Execute steps in order (steps/01-*.md through steps/NN-*.md)
3. If artifact has a domain, load domain-specific checks
4. Self-verify output completeness (max 3 iterations)
5. Write review file to .claude/reviews/<auditor-name>/
6. Return structured summary

## Output Protocol (Dual-Output)

**Review file** (.claude/reviews/<auditor-name>/DD.MM.YYYY <Name> Review.md):
- Full findings with file:line references
- Severity per finding
- Pass/fail verdict

**Direct return:**
- VERDICT: PASS/FAIL
- Finding counts by severity
- Top-priority items
- Handoff file path

## Severity Levels
Defined in <name>-standards.md:
- CRITICAL: Blocks functionality
- ERROR: Violates required convention
- WARNING: Deviates from best practice
- INFO: Suggestion for improvement

## Pass/Fail Criteria
- PASS: Zero CRITICAL + zero ERROR findings
- FAIL: Any CRITICAL or ERROR finding
```

## Key Conventions

- Read-only — never modify the artifact being audited
- Standards in a central file, not scattered across steps
- Steps execute sequentially (numbered files)
- Self-verify before returning (bounded to 3 iterations)
- Dual output: handoff file + direct return, same verdict in both
