# Loop Guards

**Purpose**: Prevent infinite loops in iterative processes.

## When to Apply

- Agents that iterate until success
- Review-and-fix cycles
- Validation loops
- Any process that could run indefinitely

## Implementation

```markdown
## Iteration Limits

**Maximum Attempts**: 2

After each attempt:
1. Log attempt number and outcome
2. If attempt 2 fails with same issue:
   - Stop iteration
   - Report findings to user
   - Request guidance

**Escalation**:
> "I've attempted this twice with the same result. Here's what I found:
> [summary]
> How would you like me to proceed?"
```

## When to Adjust

- **1 attempt**: Trivial checks where the answer is immediately clear (e.g., file existence, syntax validation)
- **2 attempts** (default): Most tasks — allows one recovery attempt without excessive token spend
- **3 attempts**: Complex multi-step processes where early attempts provide incremental progress (e.g., build-fix cycles with cascading errors)

## Rationale

The default of 2 attempts balances recovery opportunity against token cost. A single attempt leaves no room for correcting a minor misstep, but a third attempt on the same error rarely yields a different result — it just burns tokens. When an agent fails twice on the same issue, fresh context or human intervention is more likely to unblock progress than another automated attempt.

## Example

**GOOD** — Loop guard triggers escalation:
```
Attempt 1: Lint fix applied, 3 errors remain.
Attempt 2: Same 3 errors persist after second fix approach.
→ "I've attempted this twice with the same 3 lint errors. The errors appear to be in generated code that shouldn't be modified directly. How would you like me to proceed?"
```

**BAD** — No loop guard, agent spirals:
```
Attempt 1: Lint fix applied, 3 errors remain.
Attempt 2: Different fix, same 3 errors.
Attempt 3: Reverts attempt 2, tries attempt 1 again.
Attempt 4: Combines approaches, introduces 2 new errors.
Attempt 5: ...
(Agent continues indefinitely, consuming tokens and drifting further from a solution)
```
