# Complete Examples

Worked examples based on the existing `dev-tooling` domain. Use these as reference during domain design.

---

## 1. Domain Summary Example

A filled-in running summary for the dev-tooling domain:

```markdown
## Domain Summary: dev-tooling

**Scope:** Agents that operate within Claude Code projects using the `.claude/` directory structure
**Target Agent Types:** reviewer, developer, orchestrator, interactive, validator

### Conventions
1. YAML frontmatter required on all agent and skill definition files
2. kebab-case for all agent names, skill names, and file names
3. Forward slashes in all file paths — never backslashes
4. SKILL.md (exact casing) for skill definition files
5. `<agent-name>.md` for sub-agent definition files (name matches directory)
6. `domain` field required in YAML frontmatter of all agents and skills

### Project Scanning
| Scan | Command | Purpose |
|------|---------|---------|
| Existing agents | `Glob .claude/agents/*/*.md` | Avoid duplication, understand naming |
| Existing skills | `Glob .claude/skills/*/SKILL.md` | Discover available capabilities |
| Interface contracts | `Glob .claude/agents/interface-contracts/*.contract.md` | Understand inter-agent communication |
| User guides | `Glob .claude/documentation/*.guide.md` | Check documentation conventions |
| Project instructions | `Read CLAUDE.md` | Understand project rules |
| Settings | `Read .claude/settings.json` | Understand hooks, permissions |

### Tool Recommendations
| Agent Type | Recommended Tools | Rationale |
|------------|-------------------|-----------|
| Read-only reviewer | Read, Grep, Glob | Cannot modify code, safe for validation |
| Code modifier | Read, Edit, Write, Bash, Grep, Glob | Full development capability |
| Explorer | Read, Grep, Glob | Discovery and research only |
| Orchestrator | Read, Grep, Glob, Task | Delegates work to sub-agents |

### Patterns Designed
| Pattern | Purpose | File |
|---------|---------|------|
| STOP & WAIT | Require user approval before significant actions | stop-and-wait.md |
| Search Before Code | Find existing patterns before creating new | search-before-code.md |
| Loop Guards | Prevent infinite iteration loops | loop-guards.md |
| Pre-Computational Logic | Validate assumptions before generating output | pre-computational-logic.md |
| Tool Execution Verification | Back claims with actual tool output | tool-execution-verification.md |
| Defense-in-Depth | Validate across multiple layers | defense-in-depth.md |
| Handoff Protocol | File-based inter-agent communication | handoff-protocol.md |
| Feedback Loop | Iterate until quality threshold met | feedback-loop.md |
| Progressive Question Flow | Gather information systematically | progressive-question-flow.md |

### Cross-Domain Pattern References
- None (first domain created)

### Templates
- sub-agent-template.md — YAML frontmatter + markdown structure for sub-agents
- skill-template.md — YAML frontmatter + markdown structure for skills

### Auditor Checks
| ID | Description | Severity |
|----|-------------|----------|
| 1.D1 | Internal file organization follows dev-tooling conventions | WARNING |
| 1.D2 | Pipeline participant documents handoff conventions | WARNING |

**Additional Checklist Count:** 2 checks

### Files to Create/Modify
| File | System | Path | Status |
|------|--------|------|--------|
| domain.md | Agent Architect | .claude/skills/agent-architect/domains/dev-tooling/domain.md | New |
| _index.md | Agent Architect | .claude/skills/agent-architect/domains/dev-tooling/patterns/_index.md | New |
| 9 pattern files | Agent Architect | .claude/skills/agent-architect/domains/dev-tooling/patterns/*.md | New |
| sub-agent-template.md | Agent Architect | .claude/skills/agent-architect/domains/dev-tooling/templates/sub-agent-template.md | New |
| skill-template.md | Agent Architect | .claude/skills/agent-architect/domains/dev-tooling/templates/skill-template.md | New |
| domain.md | Agent Auditor | .claude/agents/agent-auditor/domains/dev-tooling/domain.md | New |
| _index.md | Agent Architect | .claude/skills/agent-architect/domains/_index.md | Modified |
| _index.md | Agent Auditor | .claude/agents/agent-auditor/domains/_index.md | Modified |
| SKILL.md | Agent Architect | .claude/skills/agent-architect/SKILL.md | Modified |

### Pending Decisions
(none)

### Recent Changes
(none — loaded from existing)
```

---

## 2. Agent Architect `domain.md` Example

From `.claude/skills/agent-architect/domains/dev-tooling/domain.md`:

```markdown
# Dev-Tooling Domain

Conventions and scanning instructions for agents that operate within Claude Code projects using the `.claude/` directory structure.

## Scope

This domain applies to agents that:
- Create, modify, or validate code within a project
- Interact with other agents or skills via the Task tool or handoff files
- Read or write files under `.claude/`
- Manage project workflows, pipelines, or orchestration

## Project Scanning

Run these scans to understand the target project before designing the agent.

### Required Scans

| Scan | Command | Purpose |
|------|---------|---------|
| Existing agents | `Glob .claude/agents/*/*.md` | Avoid duplication, understand naming patterns |
| Existing skills | `Glob .claude/skills/*/SKILL.md` and `Glob .claude/skills/*/*/SKILL.md` | Discover available capabilities |
| Interface contracts | `Glob .claude/agents/interface-contracts/*.contract.md` | Understand inter-agent communication |
| User guides | `Glob .claude/documentation/*.guide.md` | Check documentation conventions |
| Project instructions | `Read CLAUDE.md` | Understand project rules and patterns |
| Settings | `Read .claude/settings.json` | Understand hooks, permissions, existing config |

### Optional Scans

| Scan | Command | When |
|------|---------|------|
| Pipeline artifacts | `Glob .project/cycles/*/execution/` | If agent will participate in pipelines |
| Custom commands | `Glob .claude/commands/*/` | If agent may need custom commands |
| Existing role definitions | `Glob .agent/roles/*/*.md` | If project uses legacy role patterns |

## Conventions

- **YAML frontmatter required** on all agent and skill definition files
- **kebab-case** for all agent names, skill names, and file names
- **Forward slashes** in all file paths — never backslashes
- **SKILL.md** (exact casing) for skill definition files
- **`<agent-name>.md`** for sub-agent definition files (name matches directory)
- **`domain` field required** in YAML frontmatter of all agents and skills

## Tool Recommendations

Match tools to agent purpose using minimum necessary access:

| Agent Type | Recommended Tools | Rationale |
|------------|-------------------|-----------|
| Read-only reviewer | Read, Grep, Glob | Cannot modify code, safe for validation |
| Code modifier | Read, Edit, Write, Bash, Grep, Glob | Full development capability |
| Explorer | Read, Grep, Glob | Discovery and research only |
| Orchestrator | Read, Grep, Glob, Task | Delegates work to sub-agents |

## Domain Resources

- **File structure**: [references/file-structure.md](../../references/file-structure.md) — Complete `.claude/` directory layout
- **Patterns**: [patterns/_index.md](patterns/_index.md) — 9 behavioral patterns with selection guide
- **Sub-agent template**: [templates/sub-agent-template.md](templates/sub-agent-template.md) — YAML frontmatter + markdown structure
- **Skill template**: [templates/skill-template.md](templates/skill-template.md) — YAML frontmatter + markdown structure
```

---

## 3. Agent Auditor `domain.md` Example

From `.claude/agents/agent-auditor/domains/dev-tooling/domain.md`:

```markdown
# Domain: dev-tooling

## Scope

Agents and skills that operate within Claude Code projects — creating, validating, or managing artifacts in the `.claude/` directory structure.

---

## Domain Checks

Checks are numbered by the base step they extend: `<step>.D<n>`.

### Step 1 Extensions: Structural

#### Check 1.D1: Internal File Organization

**What to verify:**
- Step files (if any) are in a `steps/` subdirectory
- Reference files (if any) are in organized subdirectories
- No loose files dumped in the agent's root alongside the main definition

**Pass/Fail:**
- PASS: Internal file structure follows dev-tooling conventions
- FAIL [WARNING]: Non-standard internal file organization

#### Check 1.D2: Handoff Directory Conventions

**What to verify:**
- If the agent participates in a pipeline (reads from or writes to handoff directories)
- Pipeline artifacts use `.project/cycles/<cycle>/execution/` paths; auditor reviews use `.claude/.archive/`
- Agent documents what it reads from and writes to

**Pass/Fail:**
- PASS: Not a pipeline participant, OR handoff conventions followed
- FAIL [WARNING]: Pipeline participant without documented handoff conventions

---

## Additional Checklist Count

**2 additional checks** (1.D1, 1.D2)

---

## Alignment

Domain name `dev-tooling` aligns with Agent Architect's dev-tooling domain.
```

---

## 4. Pattern File Example

From `.claude/skills/agent-architect/domains/dev-tooling/patterns/stop-and-wait.md` (structure):

```markdown
# STOP & WAIT

## Purpose

Require explicit user approval before taking significant, potentially irreversible actions.

## When to Apply

Use this pattern when:
- The agent creates or modifies files
- The agent makes decisions that are hard to reverse
- The agent interacts with external systems

Do NOT use this pattern when:
- The agent is read-only (exploration, validation)
- Every action is trivially reversible

## Implementation

1. Before any significant action, present a clear summary of what will happen
2. Use AskUserQuestion or explicit prompts to request approval
3. Only proceed after receiving explicit confirmation
4. If denied, offer alternatives or ask for guidance

### Example

```
I'm about to create the following files:
- .claude/agents/my-agent/my-agent.md
- .claude/agents/my-agent/essentials/config.md

Shall I proceed? (Create / Make changes first)
```

## Rationale

Prevents accidental file creation, modification, or deletion. Gives users control over their codebase and ensures they understand what changes will be made before they happen.
```

---

## 5. Registry Update Before/After Example

### Agent Architect `_index.md` — Adding "data-pipeline" domain

**Before:**
```markdown
| Domain | Purpose | Key Content |
|--------|---------|-------------|
| dev-tooling | Agents operating within Claude Code projects using `.claude/` directory structure | File structure guide, 9 behavioral patterns, sub-agent and skill templates, worked examples |
| web-automation | Agents performing web scraping, data extraction, API consumption, or browser automation | Rate limiting, error recovery, data extraction pipeline patterns, web agent template |
```

**After:**
```markdown
| Domain | Purpose | Key Content |
|--------|---------|-------------|
| dev-tooling | Agents operating within Claude Code projects using `.claude/` directory structure | File structure guide, 9 behavioral patterns, sub-agent and skill templates, worked examples |
| web-automation | Agents performing web scraping, data extraction, API consumption, or browser automation | Rate limiting, error recovery, data extraction pipeline patterns, web agent template |
| data-pipeline | Agents managing ETL workflows, data transformations, and pipeline orchestration | Data validation patterns, schema evolution, pipeline monitoring conventions |
```

### Agent Auditor `_index.md` — Adding "data-pipeline" domain

**Before:**
```markdown
| Domain | Directory | Description |
|--------|-----------|-------------|
| `dev-tooling` | `domains/dev-tooling/` | Agents operating within Claude Code projects (`.claude/` structure conventions) — 2 checks |
| `web-automation` | `domains/web-automation/` | Agents performing web scraping, API consumption, or browser automation — 5 checks |
```

**After:**
```markdown
| Domain | Directory | Description |
|--------|-----------|-------------|
| `dev-tooling` | `domains/dev-tooling/` | Agents operating within Claude Code projects (`.claude/` structure conventions) — 2 checks |
| `web-automation` | `domains/web-automation/` | Agents performing web scraping, API consumption, or browser automation — 5 checks |
| `data-pipeline` | `domains/data-pipeline/` | Agents managing ETL workflows, data transformations, and pipeline orchestration — 3 checks |
```
