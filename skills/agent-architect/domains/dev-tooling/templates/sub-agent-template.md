# Sub-Agent Template

Use this template when creating sub-agent definition files.

## Template

```markdown
---
name: [agent-name]
description: [Clear description of what the agent does and when to use it. Include trigger keywords.]
tools: [Tool1, Tool2, Tool3]
model: [haiku | sonnet | opus | inherit]
domain: [domain-name]
permissionMode: [default | acceptEdits | dontAsk | bypassPermissions | plan]
---

# [Agent Display Name]

You are **[Persona Name]** - [brief persona description].

## Mandate

[One paragraph describing the agent's core purpose and what it must achieve.]

## Core Constraints

<!-- Calibration: match emphasis level to actual severity. Reserve NEVER for genuine safety constraints. Use natural language with rationale for design principles and process guidelines. -->
<!-- Isolation: constraint rationale must be self-contained. Do not reference other agents' roles to justify a constraint (e.g., "that's the developer's job"). See best-practices.md > Boundary Isolation. -->

### Safety Boundaries
1. **NEVER [critical prohibition]** — [consequence that makes this a safety concern]
2. **NEVER [critical prohibition]** — [consequence that makes this a safety concern]

### Operating Principles
- [Design principle or process guideline in natural language]. [Why this matters — what goes wrong without it.]
- [Design principle or process guideline in natural language]. [Why this matters — what goes wrong without it.]

## Responsibilities

1. **[Responsibility 1]**: [Description]
2. **[Responsibility 2]**: [Description]
3. **[Responsibility 3]**: [Description]

## Workflow

<!-- File loading: if the agent loads files dynamically during execution (e.g., one set per
     failing test, one file per discovered issue), document the loading strategy explicitly
     so the agent doesn't pre-load everything upfront. See best-practices.md > File Loading Strategy. -->

### Phase 1: [Phase Name]
[Steps for this phase]

### Phase 2: [Phase Name]
[Steps for this phase]

### Phase 3: [Phase Name]
[Steps for this phase]

## [Pattern Section - if applicable]

[Pattern implementation details]

## Codebase References

<!-- CONDITIONAL: Only include this section for files NOT already loaded by the workflow.
     If the workflow mandates "Read X" in a step, X is already in context — listing it here
     adds tokens without information. See best-practices.md > Avoid Redundant Indirection. -->

When working, consult:
- `[path/to/file.md]` - [What it provides — only files not loaded by workflow steps]

## Output Format

[Define how the agent should format its output]

## Inter-Agent Communication (if applicable)

**Receives from**: [agent-name] via `[execution path or return value]`
**Produces for**: [agent-name] via `[execution path or return value]`

### Handoff Format
[Define the format of handoff files]
```

## Field Reference

### Frontmatter Fields

| Field | Required | Values | Description |
|-------|----------|--------|-------------|
| name | Yes | kebab-case | Unique identifier |
| description | Yes | String | Discovery trigger text |
| tools | No | Tool list | Allowed tools (omit for all) |
| disallowedTools | No | Tool list | Denied tools |
| model | No | haiku/sonnet/opus/inherit | Model selection |
| domain | Yes | See domains/_index.md | Knowledge domain for agent-architect |
| permissionMode | No | See values | Permission handling |
| hooks | No | Hook config | Lifecycle hooks |

### Permission Modes

| Mode | Behavior |
|------|----------|
| default | Standard permission prompts |
| acceptEdits | Auto-accept file edits |
| dontAsk | Auto-deny prompts (allowed tools work) |
| bypassPermissions | Skip all checks (use cautiously) |
| plan | Read-only exploration mode |

### Common Tool Sets

**Read-only**:
```yaml
tools: Read, Grep, Glob
```

**Standard development**:
```yaml
tools: Read, Edit, Write, Bash, Grep, Glob
```

**Review with limited bash**:
```yaml
tools: Read, Grep, Glob, Bash
disallowedTools: Edit, Write
```

## Complete Examples

For worked examples of different sub-agent types, see [../../../references/examples/complete-examples.md](../../../references/examples/complete-examples.md#sub-agents):

- **code-reviewer** - Read-only reviewer with Tool Execution Verification and Loop Guards patterns
- **developer** - Full implementation agent with Search Before Code and Loop Guards patterns
