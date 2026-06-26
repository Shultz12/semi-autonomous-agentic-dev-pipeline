# Handoff Protocol

**Purpose**: Enable communication between agents via files.

> **Note**: This is a custom pattern for complex workflows. For simple sequential agent workflows, consider using official Claude Code subagent delegation with return results. Use file-based handoffs when you need:
> - Structured data persistence between sessions
> - Complex conditional routing based on results
> - Audit trails for agent communication
> - Direct inter-subagent communication (not through main agent)

## When to Apply

- Multi-agent workflows
- Agents that produce output for other agents
- Pipeline architectures
- Complex workflows requiring persistence

## Implementation

```markdown
## Handoff File Structure

Location: `.project/cycles/<cycle>/execution/[artifact-type]/`

**File Format**:
```markdown
# Handoff: [Task Name]

**From**: [producing-agent]
**To**: [receiving-agent]
**Created**: [timestamp]

## Context
[Background information]

## Task
[Specific instructions for receiving agent]

## Deliverables
[What the receiving agent should produce]

## Constraints
[Any limitations or requirements]
```

**Receiving Agent Behavior**:
1. Check handoff directory for new files
2. Process according to instructions
3. Create response handoff OR complete task
4. Clean up processed handoff files
```

## Official Alternatives

For simpler workflows, consider:
- **Subagent delegation**: Main agent delegates to subagent, receives summary results
- **SubagentStop hooks**: Process subagent results via hook scripts
- **Resume mechanism**: Continue subagent work with full context preserved

## Rationale

When agents communicate through implicit context or assumptions, information gets lost or misinterpreted. Structured handoff files create an explicit contract between producing and receiving agents — context, task, and deliverables are unambiguous and auditable. Without a handoff protocol, a receiving agent may lack critical context that the producing agent considered obvious, leading to misaligned output.

## Example

**GOOD** — Structured handoff preserves context:
```markdown
# Handoff: Auth Module Review

**From**: plan-architect
**To**: developer

## Context
Auth module uses SuperTokens with custom session claims for org-level RBAC.

## Task
Implement session claim validation in the guard layer.

## Constraints
- Must use existing VerifySession decorator pattern
- Organization ID comes from session claims, not URL params
```
→ Developer has full context, implements correctly on first pass.

**BAD** — Implicit handoff loses context:
```
plan-architect finishes, developer starts.
Developer sees "implement auth guard" in the plan.
→ Doesn't know SuperTokens is used, writes custom JWT validation.
→ Conflicts with existing auth infrastructure. Rework required.
```
