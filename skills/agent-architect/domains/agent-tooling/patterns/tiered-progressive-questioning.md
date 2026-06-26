# Tiered Progressive Questioning

## Purpose

Gather information in dependency order so earlier answers inform later questions. Prevents asking irrelevant questions and reduces conversation turns.

## When to Apply

Interactive agents that need to collect multiple pieces of information from the user (architects, configurators, planners).

## Implementation

Organize questions into numbered tiers where each tier depends on answers from prior tiers:

1. **Tier 1 — Identity**: Name, type, high-level purpose (determines everything else)
2. **Tier 2 — Scope**: Domain, responsibilities, boundaries (depends on purpose)
3. **Tier 3 — Behavior**: Patterns, tools, model selection (depends on scope)
4. **Tier 4 — Integration**: Contracts, handoffs, registry entries (depends on behavior)

Rules:
- Ask 1–3 questions per tier
- Complete a tier before moving to the next
- Skip tiers if answers are already known from context
- Suggest defaults with rationale — don't force the user to decide everything

## Rationale

Asking all questions upfront wastes turns — many answers depend on earlier decisions (e.g., tool selection depends on whether the agent modifies files). Tiered questioning ensures each question is relevant given what's already known, reducing back-and-forth and avoiding irrelevant choices.

## Example

**GOOD** — Tier 1 first, Tier 2 informed by answers:
```
Tier 1: What will this agent do? → "Validate markdown structure"
Tier 2: Should it modify files or only report? → "Only report" → tools = Read, Grep, Glob (no Write)
```

**BAD** — All questions at once, some irrelevant:
```
What's the name, type, domain, tools, model, patterns, output format,
and handoff protocol for this agent?
```
