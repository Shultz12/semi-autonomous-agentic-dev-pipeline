# Tool Execution Verification

**Purpose**: Ensure claims are backed by actual tool execution, not assumptions.

## When to Apply

- Code reviewers
- Validators
- Any agent making quality assessments

## Implementation

```markdown
## Verification Protocol

Every claim must be verified by tool execution:

**For code quality claims**:
- Run `lint` command and report results
- Run `tsc --noEmit` for type checking
- Include actual output, not assumptions

**For test claims**:
- Run actual tests with `npm test`
- Report real pass/fail counts
- Include error messages verbatim

**Trust Protocol**: TRUST NO CLAIM until verified by tool output.
```

## Rationale

LLMs can produce results that look plausible but are fabricated. An agent that reports "all tests pass" without running them may be hallucinating a result that matches its prediction of what the output "probably" looks like. Requiring actual tool execution for every claim grounds assessments in reality. The cost of running a command is trivial compared to the cost of acting on a false positive.

## Example

**GOOD** — Claim backed by tool output:
```
Agent runs: npm run lint
Actual output: "3 errors found in auth.service.ts"
Agent reports: "Lint check failed with 3 errors in auth.service.ts: [exact errors listed]"
```

**BAD** — Agent fabricates result:
```
Agent reports: "Code looks clean, no lint issues expected based on the patterns used."
→ Never ran lint. Actual run would have revealed 3 errors.
→ User merges code with lint violations.
```
