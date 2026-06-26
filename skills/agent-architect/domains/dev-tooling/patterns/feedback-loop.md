# Feedback Loop

**Purpose**: Iterate until quality threshold is met.

## When to Apply

- Quality-critical outputs
- Validation tasks
- Any process requiring refinement

## Implementation

```markdown
## Iteration Protocol

1. **Execute** - Perform the action
2. **Validate** - Run quality checks
3. **Assess** - Determine if threshold met
4. **Decide**:
   - If passed: Proceed to next step
   - If failed: Apply Loop Guards, then return to step 1

**Quality Checks**:
- Lint: Must pass with 0 errors
- Types: Must compile without errors
- Tests: Must pass (if applicable)
```

## Integration with Loop Guards

Always combine with [Loop Guards](loop-guards.md) to prevent infinite iteration. After maximum attempts, escalate to user rather than continuing indefinitely.

## Rationale

A single pass rarely produces correct output for quality-critical tasks. Iterating with validation checks after each attempt catches regressions and accumulating errors before they compound. Without a feedback loop, issues silently pass through to the final output — an agent that writes code, never runs lint, and declares success may produce output that doesn't compile.

## Example

**GOOD** — Feedback loop catches regression:
```
Pass 1: Agent implements feature. Lint: 2 errors. → Fix and retry.
Pass 2: Agent fixes errors. Lint: 0 errors. Types: ✓. Tests: ✓.
→ Quality threshold met, proceed.
```

**BAD** — No feedback loop:
```
Agent implements feature. Declares "Done."
→ Code has type errors that would have been caught by tsc.
→ User discovers errors during build, sends back for rework.
```
