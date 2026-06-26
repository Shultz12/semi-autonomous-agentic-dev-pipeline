# Domain Structure Reference

Templates for every file type a domain produces. Use these as starting points during the Design and Auditor Design phases.

---

## 1. Agent Architect `domain.md`

**Path:** `.claude/skills/agent-architect/domains/<domain>/domain.md`

```markdown
# <Domain-Name> Domain

<One-sentence description of what this domain covers.>

## Scope

This domain applies to agents that:
- <Specific criterion 1>
- <Specific criterion 2>
- <Specific criterion 3>

## Project Scanning

Run these scans to understand the target project before designing the agent.

### Required Scans

| Scan | Command | Purpose |
|------|---------|---------|
| <scan name> | <tool command> | <why this scan matters> |

### Optional Scans

| Scan | Command | When |
|------|---------|------|
| <scan name> | <tool command> | <condition for running> |

## Conventions

- **<Convention 1>** — <brief explanation>
- **<Convention 2>** — <brief explanation>
...

## Tool Recommendations

Match tools to agent purpose using minimum necessary access:

| Agent Type | Recommended Tools | Rationale |
|------------|-------------------|-----------|
| <type> | <tools> | <why these tools> |

## Domain Resources

- **Patterns**: [patterns/_index.md](patterns/_index.md) — <N> behavioral patterns with selection guide
- **Templates**: [templates/<name>.md](templates/<name>.md) — <description> (if applicable)
```

### Convention Quality Guidance

Every convention MUST be specific, actionable, and verifiable. An auditor should be able to write a pass/fail rule for each convention.

**GOOD conventions:**
- "All API endpoints must include rate-limiting middleware"
- "File names use kebab-case with `.handler.ts` suffix"
- "YAML frontmatter required on all agent definition files"
- "Forward slashes in all file paths — never backslashes"

**BAD conventions:**
- "APIs should be well-designed" (subjective — what is "well-designed"?)
- "Use good naming conventions" (vague — which naming convention?)
- "Code should be clean" (unmeasurable)
- "Follow best practices" (which practices?)

**Test each convention:** Can you write a grep/glob command or code review rule to verify it? If not, make it more specific.

---

## 2. Agent Architect `patterns/_index.md`

**Path:** `.claude/skills/agent-architect/domains/<domain>/patterns/_index.md`

```markdown
# Patterns Library

Reusable behavioral patterns for <domain-name> agents. Apply based on agent purpose and requirements.

## Available Patterns

| Pattern | Purpose | File |
|---------|---------|------|
| <Pattern Name> | <One-sentence purpose> | [<pattern-name>.md](<pattern-name>.md) |

## Pattern Selection Guide

| Agent Type | Recommended Patterns |
|------------|---------------------|
| <type> | [<Pattern>](<pattern-name>.md), [<Pattern>](<pattern-name>.md) |

## Pattern Combinations

**<Archetype Name>**:
- <Pattern 1>
- <Pattern 2>
- <Pattern 3>

## Cross-Domain Patterns

Patterns from other domains that may be relevant to <domain-name> agents:

| Pattern | Source Domain | Relevance |
|---------|-------------|-----------|
| <Pattern Name> | <domain> | <Why it's relevant> |

To use a cross-domain pattern, read it from the source domain's patterns directory.

---

## Adding New Patterns

When adding a new pattern:
1. Create a new file: `<pattern-name>.md`
2. Follow the structure: Purpose, When to Apply, Implementation, Rationale
3. Add the pattern to the "Available Patterns" table above
4. Add to "Pattern Selection Guide" if applicable
5. Update "Pattern Combinations" if the pattern fits common archetypes
```

---

## 3. Pattern File

**Path:** `.claude/skills/agent-architect/domains/<domain>/patterns/<pattern-name>.md`

```markdown
# <Pattern Name>

## Purpose

<One-sentence description of what this pattern achieves.>

## When to Apply

Use this pattern when:
- <Condition 1>
- <Condition 2>

Do NOT use this pattern when:
- <Counter-condition>

## Implementation

<Step-by-step instructions for applying this pattern in an agent definition.>

1. <Step 1>
2. <Step 2>
3. <Step 3>

### Example

<Short code/markdown example showing the pattern applied.>

## Rationale

<Why this pattern exists. What problem does it prevent? What quality does it ensure?>
```

---

## 4. Agent Auditor `domain.md`

**Path:** `.claude/agents/agent-auditor/domains/<domain>/domain.md`

```markdown
# Domain: <domain-name>

## Scope

<One-sentence description of what this domain covers, matching the Agent Architect domain's scope.>

---

## Domain Checks

Checks are numbered by the base step they extend: `<step>.D<n>`.

### Step <N> Extensions: <Category>

#### Check <N>.D<M>: <Check Title>

**What to verify:**
- <Specific, concrete thing to inspect>
- <Another specific thing>

**Pass/Fail:**
- PASS: <Unambiguous pass condition>
- FAIL [<SEVERITY>]: <Unambiguous fail condition>

---

## Additional Checklist Count

**<N> additional checks** (<list of check IDs>)

---

## Alignment

Domain name `<domain-name>` aligns with Agent Architect's <domain-name> domain.
```

### Auditor Check Quality Guidance

Every check MUST have concrete, unambiguous pass/fail criteria. A reviewer should be able to evaluate it without subjective judgment.

**GOOD checks:**
```
Check 1.D1: File Path Conventions
What to verify:
- All file paths in the agent definition use forward slashes
Pass: No backslash characters found in path strings
Fail [WARNING]: Backslash found in file path
```

```
Check 2.D1: Required Frontmatter Fields
What to verify:
- YAML frontmatter contains "name", "description", and "domain" fields
Pass: All three fields present
Fail [ERROR]: Missing required frontmatter field(s)
```

**BAD checks:**
```
Check 1.D1: Code Quality
What to verify:
- Code is high quality
Pass: Code looks good
Fail: Code looks bad
(Not verifiable — entirely subjective)
```

```
Check 1.D2: Best Practices
What to verify:
- Agent follows best practices
Pass: Best practices followed
Fail: Best practices not followed
(Circular — defines nothing concrete)
```

---

## 5. Registry Update Instructions

### Agent Architect Registry (`.claude/skills/agent-architect/domains/_index.md`)

Add a row to the **Available Domains** table:

```
| <domain-name> | <Purpose description> | <Key content summary> |
```

Add matching rows to the **Decision Matrix** table:

```
| <Agent purpose> | <domain-name> | <Rationale> |
```

### Agent Auditor Registry (`.claude/agents/agent-auditor/domains/_index.md`)

Add a row to the **Available Domains** table:

```
| `<domain-name>` | `domains/<domain-name>/` | <Description> — <N> checks |
```

### Agent Architect SKILL.md Reference Registry

Add domain file entries under the appropriate section in the Reference Registry:

```markdown
**<Domain-name> domain** (<brief scope>):
- [domains/<domain-name>/domain.md](domains/<domain-name>/domain.md) — Conventions, project scanning instructions, tool recommendations
- [domains/<domain-name>/patterns/_index.md](domains/<domain-name>/patterns/_index.md) — Pattern library with selection guide
```

Add template entries if templates were created.
