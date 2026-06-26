# Architect Skill Template

Starting structure for interactive architect-type skills (Agent Architect, Domain Architect, etc.).

## Directory Structure

```
.claude/skills/<name>/
├── SKILL.md              # Main definition (frontmatter + core instructions)
├── essentials/
│   ├── summary-format.md # Summary template displayed every response
│   └── shared-techniques.md  # Questioning, pattern selection, review integration
├── modes/
│   ├── create-<thing>.md # Creation workflow
│   └── update-<thing>.md # Update workflow
├── domains/              # Domain knowledge packs (if applicable)
│   └── _index.md         # Domain registry
├── references/           # On-demand reference material
│   ├── best-practices.md
│   ├── examples/
│   └── templates/
└── scripts/              # Validation hooks (if applicable)
```

## SKILL.md Skeleton

```yaml
---
name: <name>
description: <what it creates/updates, trigger words, when to use>
user-invocable: true
disable-model-invocation: true
argument-hint: "[create|update] [optional: target name]"
domain: agent-tooling
allowed-tools: Read, Grep, Glob, Write, Edit, AskUserQuestion, Agent
---
```

```markdown
# <Name>

You are the **<Name>** — <one-line role description>.

**On startup:**
1. Read essentials/summary-format.md
2. Determine mode from arguments (create/update/ambiguous → Phase 0)
3. Read the appropriate mode file

## Mandate
<What this architect produces, quality criteria>

## Mode Routing
<Argument parsing rules, fallback to Phase 0>

## Domain System (if applicable)
<How domains are selected and loaded>

## Phase 0: Mode Selection
<AskUserQuestion for create vs update when ambiguous>

## Core Constraints

<!-- Calibration: match emphasis level to actual severity. Reserve NEVER for genuine safety constraints. Use natural language with rationale for design principles and process guidelines. -->

### Safety Boundaries
[Only genuine safety constraints warranting NEVER — each with rationale explaining the consequence]

### Operating Principles
[Design principles and process guidelines — natural language with rationale, no ALL-CAPS emphasis unless genuinely critical]

## Reference Registry
<Categorized file listing: essential, modes, domains, references>

## Validation Checklist
<Pre-creation checks>
```

## Key Conventions

- Start every response with the summary (essentials/summary-format.md)
- Use tiered progressive questioning — don't ask everything at once
- Load essentials before mode-specific files
- Offer auditor review after artifact creation
- Include at least one worked example per major workflow
