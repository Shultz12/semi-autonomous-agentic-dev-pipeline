# Search Before Code

**Purpose**: Ensure existing patterns are discovered before creating new solutions.

## When to Apply

- Developer agents
- Agents that create new files or functions
- Agents that implement features

## Implementation

```markdown
## Pre-Implementation Search

Before writing new code:
1. **Search for existing patterns** using Grep and Glob
2. **Check for similar implementations** in the codebase
3. **Review relevant utilities** in shared directories
4. Only create new code if no suitable existing solution exists

Search targets:
- `shared/utils/` - Common utilities
- Similar feature directories
- Test files for patterns
```

## Rationale

Skipping a codebase search before writing new code leads to duplicate utilities, inconsistent patterns, and wasted effort reimplementing solutions that already exist. An agent that searches first builds on tested, reviewed code and maintains consistency with the rest of the codebase. The cost of a few search queries is negligible compared to the cost of maintaining duplicate implementations.

## Example

**GOOD** — Search discovers existing utility:
```
Task: Format currency values for display.
Agent searches: Grep for "formatCurrency", "formatMoney", "currency" in shared/utils/
→ Finds textUtils.ts:extractMoney() — already handles Hebrew currency formatting.
→ Uses existing utility instead of writing a new formatter.
```

**BAD** — Agent skips search, creates duplicate:
```
Task: Format currency values for display.
Agent immediately writes a new formatCurrency() function.
→ Codebase now has two currency formatters with slightly different behavior.
→ Future developers don't know which to use. Bugs get fixed in one but not the other.
```
