# File Structure Guide

Complete reference for organizing agent files in Claude Code.

## Directory Overview

```
.claude/
├── agents/                    # Sub-agent definitions
│   └── <agent-name>/
│       ├── <agent-name>.md    # Main agent file
│       ├── essentials/        # Agent-specific essentials (optional)
│       └── scripts/           # Agent scripts for hooks (optional)
│
├── skills/                    # Skill definitions
│   └── <agent-name>/          # Skills for specific agent
│       └── <skill-name>/
│           ├── SKILL.md       # Main skill file
│           ├── references/     # Skill references (optional)
│           └── scripts/       # Skill scripts (optional)
│
├── documentation/             # Human-facing guides for agents/skills
│   └── <name>.guide.md        # User guide for specific agent
│
├── commands/                  # Custom slash commands (optional)
│   └── <agent-name>/
│
├── handoffs/                  # Inter-agent communication (custom pattern)
│   └── <agent-name>/          # Handoff files FOR this agent
│
├── settings.json              # Project-wide settings and hooks
│
└── CLAUDE.md                  # Project-level instructions (optional)
```

**Rule**: Only create folders that will contain files. Empty folders are not created.

## Sub-Agent Files

### Main Agent File

**Location**: `.claude/agents/<agent-name>/<agent-name>.md`

**Content**: YAML frontmatter + markdown instructions

```markdown
---
name: agent-name
description: What the agent does and when to use it
tools: Read, Edit, Write
model: sonnet
---

# Agent Name

[Agent instructions]
```

### Agent Essentials (Optional)

**Location**: `.claude/agents/<agent-name>/essentials/`

**Purpose**: Agent-specific files that should always be available

**When to use**:
- Agent needs constant access to specific reference material
- Agent has complex rules that exceed main file length
- Agent requires templates or formats for its work

**Example**:
```
.claude/agents/code-reviewer/
├── code-reviewer.md
└── essentials/
    ├── review-checklist.md
    └── severity-definitions.md
```

### Agent Scripts (Optional)

**Location**: `.claude/agents/<agent-name>/scripts/`

**Purpose**: Executable scripts for hooks or agent operations

**When to use**:
- Agent has PostToolUse/PreToolUse hooks that run validation
- Agent needs automation scripts
- Only create if scripts will be added (no empty folders)

**Example**:
```
.claude/agents/code-reviewer/
├── code-reviewer.md
├── essentials/
│   └── review-checklist.md
└── scripts/
    └── validate-review.sh
```

## Skill Files

### Main Skill File

**Location**: `.claude/skills/<agent-name>/<skill-name>/SKILL.md`

**Important**: File must be named exactly `SKILL.md` (case-sensitive)

```markdown
---
name: skill-name
description: What the skill does (third person)
---

# Skill Name

[Skill instructions]
```

### Skill References (Optional)

**Location**: `.claude/skills/<agent-name>/<skill-name>/references/`

**Purpose**: Extended documentation loaded on demand

**When to use**:
- Main SKILL.md contains material not needed on every invocation (move it to a referenced file loaded on demand)
- Detailed guides for specific features
- Examples and troubleshooting docs

**Example**:
```
.claude/skills/developer/code-patterns/
├── SKILL.md
└── references/
    ├── patterns.md
    ├── examples.md
    └── anti-patterns.md
```

### Skill Scripts (Optional)

**Location**: `.claude/skills/<agent-name>/<skill-name>/scripts/`

**Purpose**: Executable scripts the skill can invoke

**Example**:
```
.claude/skills/developer/testing/
├── SKILL.md
└── scripts/
    ├── run-tests.sh
    └── coverage-report.py
```

## Handoff Files

> **Note**: This is a custom pattern for complex workflows. See [Inter-Agent Communication](#inter-agent-communication) for when to use this vs official patterns.

### Purpose

Enable communication between agents that cannot directly call each other.

### Location

`.project/cycles/<cycle>/execution/<artifact-type>/`

Files are organized by artifact type (e.g., `handoffs/`, `code-reviews/`, `test-results/`, `investigations/`).

### Naming Convention

```
<timestamp>-<producing-agent>-<task-id>.md
```

Example: `20240115-143022-developer-impl-user-auth.md`

### Structure

```markdown
# Handoff: [Task Name]

**From**: [producing-agent]
**To**: [receiving-agent]
**Created**: [ISO timestamp]
**Status**: [pending | processing | completed]

## Context
[Background information the receiving agent needs]

## Task
[Specific instructions or request]

## Deliverables
[What the receiving agent should produce]

## Attachments
[References to relevant files or previous work]
```

### Lifecycle

1. **Producer creates** handoff file in receiver's directory
2. **Receiver checks** directory for pending handoffs
3. **Receiver processes** according to instructions
4. **Receiver updates status** or creates response handoff
5. **Cleanup** - processed handoffs archived or deleted

## Settings File

### Location

`.claude/settings.json`

### Structure

```json
{
  "permissions": {
    "allow": ["Tool(pattern)", "Skill(pattern)"],
    "deny": ["Tool(pattern)"]
  },
  "hooks": {
    "PreToolUse": [...],
    "PostToolUse": [...],
    "SubagentStart": [...],
    "SubagentStop": [...]
  }
}
```

### Hook Configuration

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/validate.sh"
          }
        ]
      }
    ]
  }
}
```

## Documentation Files

### Location

`.claude/documentation/<name>.guide.md`

### Purpose

Human-facing guides that explain what an agent or skill does, when to use it, and how it works. Every agent and skill should have a guide.

### Naming Convention

- File name matches the agent/skill name: `<name>.guide.md`
- Examples: `code-reviewer.guide.md`, `plan-architect.guide.md`, `developer.guide.md`

### When to Create

Every agent and skill gets a guide. Unlike contracts (which are conditional on inter-agent communication), guides are always created.

For guide content and structure, see the [guide-writing reference](guide-writing.md).

## File Naming Conventions

### Agent Names
- **Format**: kebab-case
- **Examples**: `code-reviewer`, `test-architect`, `frontend-developer`

### Skill Names
- **Format**: kebab-case, action-oriented preferred
- **Examples**: `reviewing-code`, `creating-tests`, `deploy-staging`

### File Names
- Agent files: `<agent-name>.md`
- Skill files: `SKILL.md` (exactly)
- Reference files: descriptive kebab-case (e.g., `getting-started.md`)

### Path Rules
- Always use forward slashes (`/`)
- Never use Windows backslashes (`\`)
- Paths are relative within `.claude/` scope

## When to Create Each Type

### Create a Sub-Agent When:
- Task is autonomous and produces self-contained output
- You want to isolate context from main conversation
- Task benefits from specific tool restrictions
- Work can be delegated without frequent back-and-forth

### Create a Skill When:
- Adding reusable knowledge or capability
- Creating a slash command for manual invocation
- Providing reference material Claude can auto-load
- Task requires remaining in main conversation context

### Create Handoff Files When:
- Agents need to communicate but can't call each other
- Workflow involves sequential agent processing
- Audit trail of inter-agent work is needed

### Create Essentials When:
- Agent needs constant access to specific reference
- Main agent file would exceed recommended length
- Agent has complex rules or templates

## Example: Complete Agent Setup

### Developer Agent with Skills

```
.claude/
├── agents/
│   └── developer/
│       ├── developer.md
│       └── essentials/
│           └── coding-standards.md
│
├── skills/
│   └── developer/
│       ├── code-patterns/
│       │   ├── SKILL.md
│       │   └── references/
│       │       └── patterns.md
│       └── testing/
│           ├── SKILL.md
│           └── scripts/
│               └── run-tests.sh
│
└── handoffs/
    └── developer/
        └── (incoming handoffs appear here)
```

### Code Reviewer (Read-Only)

```
.claude/
├── agents/
│   └── code-reviewer/
│       └── code-reviewer.md
│
└── handoffs/
    └── code-reviewer/
        └── (incoming handoffs from developer)
```

## Inter-Agent Communication

Claude Code provides multiple patterns for agents to communicate. Choose based on complexity:

### Official Patterns (Simpler Workflows)

**Subagent Delegation + Return Results**
- Main conversation delegates to subagent
- Subagent completes work and returns summary
- Main conversation continues with results
- Best for: Sequential workflows, isolated tasks

**SubagentStop Hooks**
- Hook fires when subagent completes
- Can read subagent transcript for detailed results
- Best for: Post-processing, logging, validation

**Example**:
```json
{
  "hooks": {
    "SubagentStop": [
      {
        "matcher": "code-reviewer",
        "hooks": [
          {"type": "command", "command": "./scripts/log-review.sh"}
        ]
      }
    ]
  }
}
```

### Custom Pattern: File-Based Handoffs (Complex Workflows)

Use file-based handoffs (e.g., `.project/cycles/<cycle>/execution/`) when you need:
- **Structured data persistence** between sessions
- **Direct inter-subagent communication** (not through main agent)
- **Audit trails** for agent communication
- **Complex conditional routing** based on results
- **Session-to-session state** preservation

**Limitations of official patterns**:
- No structured handoff objects (typed data)
- Subagents cannot talk directly to each other
- Sessions are ephemeral (no built-in persistence)

See [Handoff Files](#handoff-files) for implementation details.