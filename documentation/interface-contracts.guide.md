# Interface Contracts - User Guide

## What They Are

Interface contracts are specification files that define how agents communicate with each other. Each contract describes what input an agent expects, what output it produces, and what guarantees it provides.

**Key Points:**
- Contracts are for **callers** (other agents, orchestrators) not for the agent itself
- They live at `.claude/agents/interface-contracts/<agent-name>.contract.md`
- They ensure consistent, predictable inter-agent communication
- The `find-subagent-contract` skill (`.claude/skills/find-subagent-contract/SKILL.md`) tells the main agent where to find them before it invokes a subagent

---

## Why They Exist

When one agent spawns another via the Agent tool, the calling agent needs to know:
1. **How to format its request** - what fields, what structure
2. **What to expect back** - output format, possible statuses
3. **What it can rely on** - behavioral guarantees

Without contracts, calling agents would need to read the target agent's full definition to understand how to interact with it. Contracts provide a focused, caller-relevant summary.

---

## When to Create One

Create a contract when an agent:
- Is invoked by other agents via the Agent tool
- Participates in a pipeline or workflow with other agents
- Produces structured output that other agents need to parse

**Do NOT create a contract when:**
- The agent is standalone (invoked only by users)
- The agent has no inter-agent communication

---

## How to Read a Contract

Every contract has three required sections:

### Input

Describes what to include in the prompt when spawning this agent. Shows required fields, optional fields, and example invocations.

### Output

Describes what the agent returns. May include multiple output statuses (success, failure, blocked) with different structures for each.

### Guarantees

Lists invariants you can rely on. These are behavioral promises the agent upholds regardless of input.

---

## Available Contracts

| Agent | Contract Path | Purpose |
|-------|---------------|---------|
| agent-auditor | `.claude/agents/interface-contracts/agent-auditor.contract.md` | Validates agent/skill definitions |
| domain-auditor | `.claude/agents/interface-contracts/domain-auditor.contract.md` | Validates domain knowledge packs |
| code-reviewer | `.claude/agents/interface-contracts/code-reviewer.contract.md` | Validates code quality |
| design-architect | `.claude/agents/interface-contracts/design-architect.contract.md` | Creates system design documents |
| developer | `.claude/agents/interface-contracts/developer.contract.md` | Implements plan phases |
| plan-auditor | `.claude/agents/interface-contracts/plan-auditor.contract.md` | Validates plan structure |
| plan-architect | `.claude/agents/interface-contracts/plan-architect.contract.md` | Creates implementation plans |

---

## How to Create One

Interface contracts are created by the Agent Architect during the agent creation workflow. After creating an agent that has inter-agent communication, the architect will:

1. Determine if a contract is needed
2. Draft the contract following the contract-writing guide
3. Show it to you for approval before writing

If you need to create one manually, follow the structure of existing contracts and ensure it includes Input, Output, and Guarantees sections.

---

## Related Documentation

- **Contract lookup protocol**: `.claude/skills/find-subagent-contract/SKILL.md` — loaded by the main agent before invoking a subagent
- **Contracts index**: `.claude/agents/interface-contracts/_index.md`
- **Contract writing guide** (for AI): `.claude/skills/agent-architect/references/contract-writing.md`
- **Individual agent guides**: `.claude/documentation/<agent-name>.guide.md`
