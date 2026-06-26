# Domain Architect Guide

## What It Does

The Domain Architect is an interactive skill that creates, updates, and deletes domain knowledge packs for the Agent Architect and Agent Auditor systems.

**Key Points:**
- Domains are modular knowledge packs providing conventions, patterns, templates, and validation rules for specific types of agents
- A single domain spans two systems: Agent Architect (design-time knowledge) and Agent Auditor (validation rules)
- The skill ensures both systems stay synchronized — you never create a domain in one system without the other
- Research-driven: the skill searches for industry best practices before designing conventions
- All content is presented for user approval before writing any files

## When It's Used

The Domain Architect is invoked manually when you need to manage domain knowledge packs.

**Invocation examples:**
- `/domain-architect` — Opens mode selection (create, update, or delete)
- `/domain-architect create` — Start creating a new domain
- `/domain-architect update dev-tooling` — Update the dev-tooling domain
- `/domain-architect delete web-automation` — Delete the web-automation domain

**Common scenarios:**

| Scenario | Mode | Example |
|----------|------|---------|
| New category of agents needs specialized conventions | Create | Adding an "api-design" domain for REST/GraphQL agents |
| Existing domain needs new patterns or conventions | Update | Adding a new pattern to dev-tooling |
| Domain is obsolete or merged into another | Delete | Removing a domain after consolidation |

## How It Works

### Create Mode (7 Phases)

1. **Discovery** — Name the domain, define scope, detect overlap with existing domains
2. **Research** — Structured web search for industry conventions, patterns, and validation criteria
3. **Design** — Draft Agent Architect files: conventions, scanning instructions, patterns, templates
4. **Auditor Design** — Derive validation checks from conventions, assign IDs and severities
5. **Refinement** — Iterate until all decisions are resolved
6. **Validation & Creation** — Preview all files and registry updates, create after approval
7. **Verification** — Optional read-back of created files

### Update Mode (6 Phases)

1. **Target** — Identify domain from args or list available
2. **Load State** — Read all files from both systems, build summary
3. **Changes** — Gather what to change, track with change markers
4. **Research** — Web research for new content being added (conditional)
5. **Refinement** — Iterate, cross-domain pattern discovery for new patterns
6. **Validation & Application** — Preview changes, apply after approval

### Delete Mode (4 Phases)

1. **Target** — Identify domain from args or list available
2. **Impact Analysis** — List files, scan for agents using the domain, show registry changes
3. **Confirmation** — Explicit user approval required
4. **Deletion** — Remove files, update registries, warn about affected agents

## Understanding the Summary

The Domain Summary appears at the start of every response and tracks the evolving design. Key sections:

| Section | What It Shows |
|---------|---------------|
| Scope | What types of agents this domain covers |
| Conventions | Numbered rules that agents in this domain must follow |
| Patterns Designed | Behavioral patterns specific to this domain |
| Cross-Domain Pattern References | Relevant patterns borrowed from other domains |
| Auditor Checks | Validation rules with pass/fail criteria and severity |
| Files to Create/Modify | Complete list of files that will be written |
| Pending Decisions | Questions that need to be resolved before creation |

## Tips for Best Results

- **Be specific about scope** — "agents that process PDF documents" is better than "document agents"
- **Think about verifiability** — every convention should have a clear yes/no test
- **Consider existing domains** — check if your domain overlaps with dev-tooling or web-automation
- **Provide examples** — when designing conventions, give examples of what passes and what fails
- **Don't skip research** — the web research phase surfaces best practices you might not know about

## Limitations

- Does not create the agents themselves — only the domain knowledge they use
- Cannot validate that an existing agent correctly follows its domain's conventions (that's the Agent Auditor's job)
- Web research depends on search quality — niche domains may have fewer results
- The `domain: agent-tooling` field causes the Agent Auditor to apply agent-tooling specific validation checks

## Related Files

- **Skill definition:** `.claude/skills/domain-architect/SKILL.md`
- **Create workflow:** `.claude/skills/domain-architect/modes/create-domain.md`
- **Update workflow:** `.claude/skills/domain-architect/modes/update-domain.md`
- **Delete workflow:** `.claude/skills/domain-architect/modes/delete-domain.md`
- **Domain templates:** `.claude/skills/domain-architect/references/domain-structure.md`
- **Worked examples:** `.claude/skills/domain-architect/references/examples/complete-examples.md`
- **Agent Architect (consumer):** `.claude/skills/agent-architect/SKILL.md`
- **Agent Auditor (consumer):** `.claude/agents/agent-auditor/agent-auditor.md`
