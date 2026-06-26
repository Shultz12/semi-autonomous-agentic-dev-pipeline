# Self-Criticism & Disconfirmation

## Purpose

Prevent agents from returning findings based on first impressions or plausible-sounding conclusions. Before finalizing any verdict, the agent systematically challenges its own hypothesis by seeking disconfirming evidence, checking for over-classification, and verifying completeness.

## When to Apply

Apply when the agent:
- Produces verdicts, classifications, or findings that downstream agents act on
- Performs analysis where plausible-sounding but incorrect conclusions are possible
- Classifies severity levels that determine what actions others take
- Attributes root causes or fault to specific components

**Do NOT apply** when:
- The agent performs purely mechanical tasks (formatting, copying, archiving)
- Output is deterministic (file existence checks, counting)
- The agent has no judgment calls in its workflow

## Implementation

Add a self-criticism protocol that runs AFTER analysis but BEFORE writing findings:

```markdown
## Self-Criticism Protocol

Before finalizing any verdict, run these checks:

**Disconfirmation Check**
- What evidence would DISPROVE my current conclusion?
- Have I looked for it? If not, look now.
- If found, does it invalidate the conclusion or merely add nuance?

**Severity Check**
- Am I classifying higher than the evidence supports?
- Could a simpler explanation or fix resolve this?
- Am I creating distinctions where one answer is clearly superior?

**Attribution Check**
- Am I agreeing with a prior agent's classification because it seems plausible, or because I independently verified it?
- What if the prior attribution is wrong — what would the evidence look like?

**Completeness Check**
- Is my finding the actual root cause, or a symptom?
- Would my recommended fix resolve the issue, or just change the error message?
- Have I checked for related findings that share the same root cause?

If any check fails, investigate further before concluding.
```

### Adapting the Protocol

Not every agent needs all four checks. Select the checks relevant to the agent's work:

| Agent Type | Recommended Checks |
|------------|-------------------|
| Investigator / Root Cause Analyst | All four |
| Code Reviewer | Disconfirmation, Severity, Completeness |
| Quality Analyst / Aggregator | Attribution, Completeness |
| Auditor / Validator | Severity, Completeness |

## Rationale

LLMs are prone to confirmation bias — once a hypothesis forms, subsequent analysis tends to confirm rather than challenge it. Explicit disconfirmation steps counteract this by forcing the agent to actively look for evidence against its conclusion. Over-classification wastes human attention on false positives. Symptom-level findings produce bandaid fixes that don't resolve the underlying issue.

## Example

**GOOD** — Investigator challenges its own hypothesis:
```markdown
Hypothesis: Test fails because service method is missing org scope.

Disconfirmation: What if the test expectation is wrong?
→ Read BDD spec: spec says "scoped by organization" ✓
→ Read test: test expects organizationId in query ✓
→ Read implementation: query has no organizationId filter ✗

Conclusion stands — implementation is missing scope. LEVEL_1 with HIGH confidence.
```

**BAD** — Investigator accepts first plausible explanation:
```markdown
Test fails with "expected 1 result, got 3"
→ Probably missing org scope (common issue)
→ Report LEVEL_1: add organizationId filter

[Never checked if the test expectation itself was wrong,
or if the data setup created unexpected records]
```
