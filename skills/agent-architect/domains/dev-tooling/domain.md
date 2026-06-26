# Dev-Tooling Domain

Conventions and scanning instructions for agents that operate within Claude Code projects using the `.claude/` directory structure.

## Scope

This domain applies to agents that:
- Create, modify, or validate code within a project
- Interact with other agents or skills via the Agent tool or handoff files
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
| Product state | `Glob .project/**/*` | If agent will participate in feature pipelines |
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
| Orchestrator | Read, Grep, Glob, Agent | Delegates work to sub-agents |

**Note:** Any agent that writes mandatory output files needs Bash for output enforcement registration (see [Output Enforcement](patterns/output-enforcement.md) pattern). If the agent has Write but not Bash, add Bash.

## Domain Resources

- **File structure**: [references/file-structure.md](../../references/file-structure.md) — Complete `.claude/` directory layout, when to create each file type
- **Patterns**: [patterns/_index.md](patterns/_index.md) — 9 behavioral patterns with selection guide
- **Sub-agent template**: [templates/sub-agent-template.md](templates/sub-agent-template.md) — YAML frontmatter + markdown structure
- **Skill template**: [templates/skill-template.md](templates/skill-template.md) — YAML frontmatter + markdown structure
