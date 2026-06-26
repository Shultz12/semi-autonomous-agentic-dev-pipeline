# Domain Registry

Domains are modular knowledge packs that provide specialized conventions, patterns, templates, and project scanning instructions for different types of agents.

## Available Domains

| Domain | Purpose | Key Content |
|--------|---------|-------------|
| dev-tooling | Agents operating within Claude Code projects using `.claude/` directory structure | File structure guide, 9 behavioral patterns, sub-agent and skill templates, worked examples |
| web-automation | Agents performing web scraping, data extraction, API consumption, or browser automation | Rate limiting, error recovery, data extraction pipeline patterns, web agent template |
| agent-tooling | Agents that create, audit, and maintain other agents, skills, and domains | Summary-driven conversation, progressive questioning, dual-output protocol, architect and auditor templates |

## Decision Matrix

Match the agent's primary purpose to a domain:

| Agent Purpose | Domain | Rationale |
|---------------|--------|-----------|
| Interacts with other agents or skills | dev-tooling | Uses `.claude/` inter-agent communication |
| Creates, modifies, or validates code | dev-tooling | Operates within project structure |
| Manages project workflows or pipelines | dev-tooling | Orchestrates dev-tooling agents |
| Reads or writes `.claude/` files | dev-tooling | Core dev-tooling directory |
| Scrapes websites or extracts web data | web-automation | Web data extraction |
| Consumes REST/GraphQL APIs | web-automation | API interaction patterns |
| Automates browser interactions | web-automation | Browser automation conventions |
| Processes or transforms web-sourced data | web-automation | ETL pipeline patterns |
| Creates or updates agent/skill definitions | agent-tooling | Meta-agent conventions |
| Validates or audits agent/skill quality | agent-tooling | Auditor validation patterns |
| Manages domain knowledge packs or registries | agent-tooling | Registry coordination |

### Ambiguous Cases

If the agent's purpose spans multiple domains:
1. Ask the user which domain is primary using AskUserQuestion
2. The primary domain determines conventions and project scanning
3. Cross-reference patterns from other domains as needed (each domain's `_index.md` notes cross-domain references)

### No Domain Fits

If no existing domain matches the agent's purpose:
1. Inform the user that no existing domain matches
2. Recommend creating a new domain
3. Suggest 3 candidate domain names, recommend one with rationale
4. Use AskUserQuestion to let the user pick a name or provide their own
5. Proceed without domain-specific resources for now
6. Note the new domain in the summary's Pending Decisions

## Domain Loading Sequence

After selecting a domain, load its resources in this order:

1. `domains/<domain>/domain.md` — Conventions and project scanning instructions
2. `domains/<domain>/patterns/_index.md` — Available patterns and selection guide
3. `domains/<domain>/templates/` — Starting points for agent files (load when entering Design phase)
4. `domains/<domain>/examples/` — Worked examples (load on-demand if the domain has them)

## Using Patterns from Other Domains or Projects

Extract patterns and adapt them to the agent being designed. Do not copy verbatim.

When scanning a project for existing agent patterns:
- Read existing agent definitions to understand established conventions
- Identify reusable structural patterns (workflow phases, output formats, validation approaches)
- Adapt patterns to the new agent's specific purpose and constraints

## Adding a New Domain

1. Create directory: `domains/<domain-name>/`
2. Required files:
   - `domain.md` — Scope, project scanning instructions, conventions, tool recommendations
   - `patterns/_index.md` — Pattern registry with selection guide (can start empty with structure only)
3. Optional files:
   - `templates/` — Agent templates specific to this domain
   - `examples/` — Worked examples
4. Add the domain to the "Available Domains" table above
5. Add matching rows to the Decision Matrix
6. Create a corresponding domain in `.claude/agents/agent-auditor/domains/` so the auditor can validate agents using the new domain. The `domain-architect` skill handles both sides; use it when possible.
