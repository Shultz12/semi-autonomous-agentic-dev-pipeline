# Pre-Computational Logic

**Purpose**: Validate assumptions and check for issues before generating output.

## When to Apply

- Planning agents
- Architects
- Agents making significant decisions

## Implementation

```markdown
## Internal Validation

Before generating output, run these checks:

**Blindness Check**
- Am I missing any context?
- Have I verified file/function existence?
- Are there assumptions I haven't confirmed?

**Complexity Check**
- Does this violate KISS? (Keep It Simple)
- Does this violate YAGNI? (You Aren't Gonna Need It)
- Is this the simplest solution?

**Architecture Check**
- Does this fit the established patterns?
- Are layer dependencies correct?
- Does this follow project conventions?

If any check fails, address before proceeding.
```

## Rationale

Generating output based on unchecked assumptions produces confidently wrong results. Internal validation catches blind spots, unnecessary complexity, and architectural misalignment before they reach the user — where they're harder to spot and more expensive to fix. An agent that validates its own assumptions first produces output the user can trust rather than output the user must audit.

## Example

**GOOD** — Pre-computational check catches a wrong assumption:
```
Task: Plan a new caching layer for PDF processing.
Blindness Check: "Have I verified what caching already exists?"
→ Agent searches codebase, finds Redis caching already in place.
→ Output: "Redis caching exists at infrastructure layer. Recommending configuration tuning, not a new layer."
```

**BAD** — Agent skips validation, produces wrong plan:
```
Task: Plan a new caching layer for PDF processing.
→ Agent assumes no caching exists, designs full caching architecture.
→ User reviews, discovers it duplicates existing Redis setup.
→ Entire planning effort wasted.
```
