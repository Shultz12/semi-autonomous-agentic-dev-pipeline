# Agent Architect - User Guide

## What It Does

The Agent Architect is an interactive architect that designs and builds Claude Code native agents and skills through structured conversation. Think of it as a guided wizard that walks you through every decision, shows you what it will create, and asks for your approval before writing anything.

**Key Points:**
- Creates **sub-agents, skills, hooks, commands**, and all supporting files
- Works in six modes: **Create**, **Update**, **Test**, plus three pipeline-maintenance modes — **Process Vocabulary**, **Promote Skill**, and **Update Knowledge Map**
- Uses **progressive questioning** — starts broad, gets specific based on your answers
- **Domain-aware** — applies specialized patterns and templates based on agent purpose
- **Never writes files without your explicit approval** — always shows full content first
- **Cannot be invoked by other agents** — manual invocation only via `/agent-architect`

---

## When It's Used

The Agent Architect is invoked manually when you need to create or modify agents and skills. It cannot be called programmatically by other agents (`disable-model-invocation: true`), so no interface contract is needed.

**Invocation examples:**
- `/agent-architect create my-new-agent` — Create mode with a name hint
- `/agent-architect update agent-auditor` — Update an existing agent
- `/agent-architect test my-agent` — Run behavioral tests against an agent
- `/agent-architect process-vocabulary` — Review pending verb additions for `plan-architect`
- `/agent-architect promote-skill <project-path>` — Promote a project-level skill to user level
- `/agent-architect update-knowledge-map <dev-type>` — Apply a row update to the developer's per-dev-type knowledge map
- `/agent-architect` — Interactive mode selection

**Common scenarios:**
- Designing a new sub-agent for a specific task
- Creating a new skill with hooks and supporting files
- Updating an existing agent's responsibilities, patterns, or domain
- Adding supporting files (contracts, guides) to an existing agent
- Processing accumulated vocabulary-extension or knowledge-map proposals from the pipeline

---

## How It Works

### Create Mode

The creation workflow follows five phases:

| Phase | What Happens |
|-------|-------------|
| **Discovery** | Asks about purpose, type (sub-agent vs skill), target audience, and domain |
| **Design** | Builds the agent definition progressively — frontmatter, description, sections, patterns |
| **Refinement** | Suggests improvements, reviews the design with you, iterates on feedback |
| **Validation** | Runs syntax, pattern, and duplication checks before writing files |
| **Review** | Spawns Agent Auditor to validate the result, offers to fix any findings |

### Update Mode

The update workflow loads existing state first, then follows a similar progression:

| Phase | What Happens |
|-------|-------------|
| **Target** | Identifies which agent/skill to update |
| **Load State** | Reads all existing files to understand current design |
| **Changes** | Asks what you want to modify, proposes changes |
| **Refinement** | Shows diffs, iterates on feedback |
| **Validation & Review** | Same as create mode |

### Test Mode

The testing workflow evaluates an existing agent against behavioral test cases:

| Phase | What Happens |
|-------|-------------|
| **Target & Context** | Identifies which agent to test and loads its definition |
| **Test Case Design** | Defines test cases with inputs and behavioral assertions |
| **Execution** | Runs the agent against each test case, capturing outputs |
| **Grading & Review** | Spawns `behavior-grader` to score outputs against assertions; optionally `behavior-analyzer` for cross-run patterns |
| **Iteration** | Surfaces findings and offers refinements to the agent definition |

### Pipeline-Maintenance Modes

These three modes service intake from other pipeline agents — short, focused workflows rather than full design conversations:

| Mode | What It Does |
|------|-------------|
| **Process Vocabulary** | Reviews pending verb-extension requests written by `plan-architect` under `.claude/docs/vocabulary-extensions/`. For each request, dialogues with you to approve/reject/modify, then edits `plan-architect`'s allowed-verbs list and deletes the processed request. |
| **Promote Skill** | Promotes a project-level skill to a user-level developer-skill under `.claude/skills/developer-skills/<dev-type>/<skill-name>/`. Generalizes project-specific patterns, embeds `promoted-from-project-path` metadata, and triggers contract & index maintenance. |
| **Update Knowledge Map** | Applies a row update to a per-dev-type knowledge map at `.claude/agents/developer/essentials/<dev-type>/knowledge-map.md`. Proposals typically originate from `knowledge-curator`. Creates the target file on first use if absent. |

### The Agent Summary

Every response from the Agent Architect starts with a structured summary showing the current state of the design — name, type, domain, status, pending decisions. This gives you a running snapshot of progress.

---

## Domain System

Agents operate in domains that provide specialized patterns, templates, and conventions. The Agent Architect selects a domain early in the conversation.

| Domain | For Agents That... |
|--------|-------------------|
| `dev-tooling` | Operate within Claude Code projects, manage code, orchestrate workflows |
| `web-automation` | Scrape websites, consume APIs, automate browsers |
| `agent-tooling` | Create, audit, and maintain other agents, skills, and domains |

If no domain fits, the Agent Architect will suggest creating a new one and proceed without domain-specific resources.

---

## Common Scenarios

### Creating a Simple Sub-Agent

1. Run `/agent-architect create`
2. Answer questions about purpose, responsibilities, tools needed
3. The architect selects appropriate patterns and a domain
4. Review the generated summary and file contents
5. Approve creation — files are written
6. Agent Auditor runs automatically to validate

### Updating an Agent's Description

1. Run `/agent-architect update my-agent`
2. The architect loads all existing files
3. Tell it what you want to change
4. Review proposed changes (shown as full file content)
5. Approve — only modified files are written

### Adding a New Domain

When the agent's purpose doesn't fit existing domains, the architect will:
1. Inform you no domain matches
2. Suggest 3 candidate domain names with rationale
3. Let you pick or provide your own
4. Note it as a pending decision in the summary

---

## Tips for Best Results

1. **Be specific about purpose** — "Reviews PR descriptions for clarity" is better than "helps with PRs"
2. **Mention similar agents** — If you know of an existing agent to model after, say so
3. **Don't rush approval** — Read the generated files carefully before approving
4. **Let the auditor run** — The post-creation review catches issues early
5. **Use update mode** for changes — Don't manually edit agent files if you can use the guided workflow

---

## Limitations

- **Manual invocation only** — Cannot be called by other agents or automated pipelines
- **One agent at a time** — Designs a single agent per conversation
- **Domain knowledge is bounded** — Only knows patterns for registered domains
- **Cannot execute agents** — Creates definitions but doesn't test runtime behavior
- **No rollback** — Once files are written and approved, there's no automatic undo (use git)

---

## Related Files

The Agent Architect's definition and supporting files:
```
.claude/skills/agent-architect/
├── SKILL.md                           # Main skill definition
├── essentials/
│   ├── summary-format.md              # Summary template and field definitions
│   └── shared-techniques.md           # Questioning, pattern selection, refinement
├── modes/
│   ├── create-agent.md                # Full creation workflow
│   ├── update-agent.md                # Full update workflow
│   ├── test-agent.md                  # Full testing workflow
│   ├── process-vocabulary.md          # Verb-extension intake for plan-architect
│   ├── promote-skill.md               # Project → user-level skill promotion
│   └── update-knowledge-map.md        # Per-dev-type knowledge-map row updates
├── agents/
│   ├── behavior-grader.md             # Grades agent outputs against assertions
│   └── behavior-analyzer.md           # Surfaces patterns across test runs
├── domains/
│   ├── _index.md                      # Domain registry and selection criteria
│   ├── dev-tooling/                   # Dev-tooling domain resources
│   ├── web-automation/                # Web-automation domain resources
│   └── agent-tooling/                 # Agent-tooling domain resources
├── references/
│   ├── best-practices.md              # Agent design principles
│   ├── contract-writing.md            # Interface contract authoring
│   ├── guide-writing.md               # User guide authoring
│   ├── file-structure.md              # Directory layout and naming
│   ├── eval-schemas.md                # JSON schemas for test cases and grading
│   ├── pipeline-role-templates.md     # Role-gated rule content for pipeline agents
│   └── examples/complete-examples.md  # Worked examples
└── scripts/
    ├── validate-agent.sh              # Post-write validation hook
    ├── aggregate_benchmark.py         # Benchmark aggregation for test mode
    ├── generate_review.py             # Test review generator
    └── viewer.html                    # Test result viewer
```

Related documentation:
- [Agent Auditor Guide](agent-auditor.guide.md) — The reviewer that validates agent designs
- `.claude/documentation/agent-architect.guide.md` — This guide

You don't need to read the skill files — they're for the AI. This guide covers everything you need to know as a user.
