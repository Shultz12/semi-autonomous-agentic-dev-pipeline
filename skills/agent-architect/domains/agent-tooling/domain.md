# Agent-Tooling Domain

Conventions and scanning instructions for agents that create, audit, and maintain other agents, skills, and domains.

## Scope

This domain applies to agents that:
- Create or update agent/skill definitions (CreatArchitector type)
- Validate or review agent/skill quality (Auditor type)
- Manage domain knowledge packs or registries
- Produce interface contracts, guides, or other agent-supporting artifacts

## Agent Types

| Type | Purpose | Interaction Model |
|------|---------|-------------------|
| Architect | Build/update agents, skills, domains | Interactive — conversations with user |
| Auditor | Validate agents, skills, domains against standards | Automated — spawned via Agent tool, returns report |

## Project Scanning

### Required Scans

| Scan | Command | Purpose |
|------|---------|---------|
| Existing agents | `Glob .claude/agents/*/` | Understand established agent patterns |
| Existing skills | `Glob .claude/skills/*/SKILL.md` | Understand established skill patterns |
| Interface contracts | `Glob .claude/agents/interface-contracts/*.contract.md` | Map agent communication protocols |
| Domain registries | `Read .claude/skills/agent-architect/domains/_index.md` | Available domains and selection criteria |
| Auditor domains | `Read .claude/agents/agent-auditor/domains/_index.md` | Available auditor domain checks |

### Optional Scans

| Scan | Command | When |
|------|---------|------|
| Standards files | `Grep "severity" .claude/agents/` | When designing an auditor agent — understand existing severity conventions |
| Summary formats | `Glob .claude/skills/*/essentials/summary-format.md` | When designing an architect agent — discover existing summary patterns |

## Conventions

### Architect-Specific

1. **Summary-driven conversation** — Display a running summary at the start of every response, tracking all decisions made. See [patterns/summary-driven-conversation.md](patterns/summary-driven-conversation.md)
2. **Progressive questioning** — Gather information in tiered dependency order; never ask all questions at once. See [patterns/tiered-progressive-questioning.md](patterns/tiered-progressive-questioning.md)
3. **Mode routing from arguments** — Detect operation mode from invocation arguments; fall back to a selection prompt when ambiguous
4. **Essentials-first loading** — Load essential files (summary format, shared techniques) before mode-specific or domain-specific files
5. **Review integration** — Offer post-creation review via the corresponding auditor before declaring completion. See [patterns/review-integration-cycle.md](patterns/review-integration-cycle.md)
6. **Canonical worked examples** — Include at least one complete worked example per major workflow. Curate diverse examples rather than exhaustively listing edge cases

### Auditor-Specific

7. **Standards-based validation** — Define severity levels (CRITICAL/ERROR/WARNING/INFO) and pass/fail criteria in a central standards file
8. **Step-based sequential workflow** — Use numbered step files (`steps/NN-description.md`) executed in order
9. **Dual-output protocol** — Produce both a persistent review file (`.claude/reviews/<auditor-name>/`) and a direct return summary. See [patterns/dual-output-protocol.md](patterns/dual-output-protocol.md)
10. **Self-verification loop** — Verify output completeness with a bounded maximum of 3 iterations. See [patterns/self-verification-loop.md](patterns/self-verification-loop.md)

### Shared

11. **Dual-system coordination** — When artifacts span multiple systems (e.g., Architect + Auditor domains), create/update both sides together
12. **Interface contracts for outputs** — Agent-tooling agents must create interface contracts (`.claude/agents/interface-contracts/<name>.contract.md`) for any task-spawnable agent they produce
13. **Registry coordination** — When creating/updating domain artifacts, update all related registries atomically
14. **Contrastive teaching** — When defining conventions or validation rules, include GOOD vs BAD examples with concrete explanations of what passes and what fails

## Tool Recommendations

| Agent Type | Recommended Tools | Rationale |
|------------|-------------------|-----------|
| Architect (interactive) | Read, Grep, Glob, Write, Edit, AskUserQuestion, Task | Full file manipulation + user interaction + auditor spawning |
| Auditor (validator) | Read, Grep, Glob, Write | Read-only analysis + handoff file writing; no editing of audited artifacts |
| Meta-orchestrator | Read, Grep, Glob, Task | Coordinates other agents; reads state but delegates work |

## Cross-Domain Pattern References

These patterns from `dev-tooling` apply to agent-tooling agents:

| Pattern | Relevance |
|---------|-----------|
| STOP & WAIT | Architects must pause for user approval before file creation |
| Defense-in-Depth | Auditors validate at multiple layers (structure, content, domain) |
| Loop Guards | Self-verification loops need bounded iteration limits |

## Domain Resources

- **Patterns**: [patterns/_index.md](patterns/_index.md) — 5 domain-specific patterns
- **Architect template**: [templates/architect-skill-template.md](templates/architect-skill-template.md) — Starting structure for architect-type skills
- **Auditor template**: [templates/auditor-agent-template.md](templates/auditor-agent-template.md) — Starting structure for auditor-type agents
