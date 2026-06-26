# Patterns Library

Domain-specific patterns for agent-tooling agents. These complement the generic patterns in `dev-tooling`.

## Available Patterns

| Pattern | Purpose | Applies To | File |
|---------|---------|------------|------|
| Summary-Driven Conversation | Maintain running summary of all decisions across responses | Architect | [summary-driven-conversation.md](summary-driven-conversation.md) |
| Tiered Progressive Questioning | Gather information in dependency order with numbered tiers | Architect | [tiered-progressive-questioning.md](tiered-progressive-questioning.md) |
| Dual-Output Protocol | Produce both a persistent handoff file and a direct return summary | Auditor | [dual-output-protocol.md](dual-output-protocol.md) |
| Self-Verification Loop | Iterative completeness check with bounded retries | Auditor | [self-verification-loop.md](self-verification-loop.md) |
| Review Integration Cycle | Post-creation auditor review with fix-and-recheck workflow | Architect | [review-integration-cycle.md](review-integration-cycle.md) |

## Pattern Selection Guide

| Agent Type | Recommended Patterns |
|------------|---------------------|
| Architect (interactive) | Summary-Driven Conversation, Tiered Progressive Questioning, Review Integration Cycle |
| Auditor (validator) | Dual-Output Protocol, Self-Verification Loop |
| Architect + Auditor pair | All five — architects use the first three, auditors use the last two, Review Integration Cycle connects them |

## Cross-Domain Patterns

Also apply these from `dev-tooling`:

| Pattern | When |
|---------|------|
| STOP & WAIT | Before file creation/modification |
| Defense-in-Depth | Multi-layer validation in auditors |
| Loop Guards | Bounding any iteration (including self-verification) |
