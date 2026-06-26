# Skill Template

Use this template when creating skill definition files (SKILL.md).

## Template

```markdown
---
name: [skill-name]
description: [Clear description of what the skill does and when to use it. Include trigger keywords. Write in third person.]
disable-model-invocation: [true | false]
argument-hint: [optional: hint for arguments]
domain: [domain-name]
allowed-tools: [optional: Tool1, Tool2]
model: [optional: haiku | sonnet | opus]
context: [optional: fork]
agent: [optional: Explore | Plan | general-purpose]
---

# [Skill Display Name]

[Brief introduction - 1-2 sentences describing the skill's purpose]

## Quick Start

[Most common usage pattern - code or steps]

## [Main Section 1]

[Content for primary functionality]

## [Main Section 2]

[Content for secondary functionality]

## Reference Materials

For detailed information, see:
- **[Topic]**: [references/file.md](references/file.md)
- **[Topic]**: [references/file.md](references/file.md)

## Examples (if applicable)

### Example 1: [Scenario]
[Input/output example]

### Example 2: [Scenario]
[Input/output example]
```

## Field Reference

### Frontmatter Fields

| Field | Required | Values | Description |
|-------|----------|--------|-------------|
| name | Yes | kebab-case, max 64 chars | Unique identifier |
| description | Yes | max 1024 chars | Discovery trigger (third person) |
| disable-model-invocation | No | true/false | If true, only user can invoke |
| argument-hint | No | String | Autocomplete hint |
| domain | Yes | See domains/_index.md | Knowledge domain for agent-architect |
| allowed-tools | No | Tool list | Restrict available tools |
| model | No | haiku/sonnet/opus | Override model |
| context | No | fork | Run in isolated subagent |
| agent | No | Explore/Plan/general-purpose | Subagent type (requires context: fork) |
| user-invocable | No | true/false | If false, hidden from menu |
| hooks | No | Hook config | Lifecycle hooks |
| hooks.once | No | true/false | Run hook only once per session |

### Description Best Practices

**Write in third person**:
- Good: "Analyzes code for security vulnerabilities"
- Bad: "I analyze code" / "You can use this to analyze"

**Include trigger keywords**:
- Good: "Reviews pull requests, code changes, and diffs for quality issues"
- Bad: "Helps with code review"

**Specify when to use**:
- Good: "Use when reviewing code changes or before merging PRs"
- Bad: (no usage guidance)

## Content Guidelines

### Keep SKILL.md Tight

The body should hold what every invocation needs — purpose, mode routing, core constraints. Push everything else to referenced files:
1. Move content not needed on every invocation to reference files
2. Link from SKILL.md to references
3. Claude loads references only when needed

### Progressive Disclosure Structure

```markdown
# Skill Name

[Core instructions - always loaded]

## Quick Reference
[Most common patterns]

## Detailed Guides
- **Topic A**: See [references/topic-a.md](references/topic-a.md)
- **Topic B**: See [references/topic-b.md](references/topic-b.md)
```

## Complete Examples

For worked examples of different skill types, see [../../references/examples/complete-examples.md](../../references/examples/complete-examples.md#skills):

- **deploy-staging** - Task skill with manual invocation
- **api-conventions** - Knowledge skill with automatic invocation
- **deep-research** - Subagent skill with isolated context (`context: fork`)

## Directory Structure for Skills

### Simple Skill (no references)

```
.claude/skills/[agent-name]/[skill-name]/
└── SKILL.md
```

### Skill with References

```
.claude/skills/[agent-name]/[skill-name]/
├── SKILL.md
└── references/
    ├── guide.md
    ├── examples.md
    └── troubleshooting.md
```

### Skill with Scripts

```
.claude/skills/[agent-name]/[skill-name]/
├── SKILL.md
├── references/
│   └── ...
└── scripts/
    ├── validate.sh
    └── helper.py
```
