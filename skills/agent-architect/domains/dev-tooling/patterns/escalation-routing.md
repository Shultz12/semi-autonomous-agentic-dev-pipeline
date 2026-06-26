# Escalation Routing

## Purpose

Define how pipeline agents handle situations they cannot resolve. Instead of asking the user directly (which bypasses the orchestrator), agents return structured escalation data that the orchestrator routes to the appropriate handler — whether that's a plan update, a user decision prompt, or another agent.

## When to Apply

Apply when the agent:
- Participates in a multi-agent pipeline controlled by an orchestrator
- Could encounter dead ends (ambiguous instructions, missing context, multiple valid approaches)
- Might need human input to proceed but should not communicate with users directly

**Do NOT apply** when:
- The agent is user-facing (interactive skills, CLI commands)
- The agent IS the orchestrator
- The agent always has enough context to complete its work

## Implementation

### 1. Define Escalation Triggers

Enumerate the situations that require escalation:

```markdown
### When to Escalate

- Plan instruction has multiple valid interpretations
- Referenced file/function doesn't exist in the codebase
- Plan contradicts the actual codebase state
- Real-world constraint prevents planned approach (API changed, credentials missing)
- Multiple valid approaches with genuine tradeoffs — user must choose
```

### 2. Define Escalation Categories

Each category routes to a different handler:

```markdown
### Escalation Categories

| Category | When | Routed To |
|----------|------|-----------|
| PLAN | Plan is wrong (broken references, ambiguity, contradictions) | Plan-architect for update |
| CONTEXT | Plan is fine but handoff lacks needed information | State-manager for rebuild |
| CHECKPOINT | Real-world constraint beyond agent's authority | Orchestrator → user |
| DESIGN_DECISION | Multiple valid approaches with genuine tradeoffs | Orchestrator → user → developer |
```

### 3. Define Structured Escalation Format

The escalation message must be parseable by the orchestrator:

```markdown
### Escalation Format

Status: BLOCKED | CHECKPOINT
Blocked By: PLAN | CONTEXT (only for BLOCKED)

## Problem Report
**Phase:** [N]: [phase-name]
**Task:** [N.M] | "Phase-level"
**Type:** AMBIGUITY | MISSING_REFERENCE | CONTRADICTION

### Problem
[1-2 sentences: what exactly is wrong]

### Evidence
- [specific references: file paths, line numbers, task numbers]

### Attempted Resolution
[What was tried before escalating]
```

### 4. Add the "Never Ask Directly" Constraint

```markdown
### Never Do
- Ask the user directly — return your report to the orchestrator. Direct user
  communication bypasses the orchestrator and breaks pipeline routing.
```

### 5. Commit Partial Work Before Escalating

If the agent completed some tasks before hitting the dead end:

```markdown
Before reporting BLOCKED or CHECKPOINT, commit any completed work:
- Commit via the `commit-to-git` skill (`Agent: <name>`): stage the files, subject `wip: Phase N - partial (tasks 1-M)`
- If no tasks were completed, report `Commit: none`
- This gives the orchestrator a clean git boundary for potential revert
```

## Rationale

In multi-agent pipelines, the orchestrator owns the routing logic — it knows which agent can resolve which problem, and it manages user communication. When agents bypass the orchestrator to ask users directly, the orchestrator loses visibility into pipeline state, cannot retry or reroute, and the user receives uncoordinated requests from multiple agents. Structured escalation keeps the orchestrator in control.

## Example

**GOOD** — Developer hits ambiguous plan, returns structured escalation:
```
Status: BLOCKED
Blocked By: PLAN
Report: .project/cycles/auth/execution/developer-reports/phase-3-report.md

## Problem Report
**Phase:** 3: API Endpoints
**Task:** 3.2
**Type:** AMBIGUITY

### Problem
Task says "implement rate limiting" but doesn't specify per-user or per-IP.

### Evidence
- Plan task 3.2: "Add rate limiting to login endpoint"
- No rate limiting pattern exists in codebase (searched shared/utils/)

### Attempted Resolution
Searched for existing rate limiting in codebase — none found.
```

**BAD** — Developer asks user directly:
```
I'm not sure if you want per-user or per-IP rate limiting.
Which do you prefer?
[Orchestrator has no visibility, can't route to plan-architect]
```
