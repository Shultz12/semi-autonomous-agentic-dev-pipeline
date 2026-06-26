# Severity + Confidence Pairing

## Purpose

Classify every finding along two independent dimensions: severity (impact) and confidence (certainty). This prevents conflating "I'm not sure what's wrong" with "this is a minor issue" — they are orthogonal assessments that drive different downstream actions.

## When to Apply

Apply when the agent:
- Produces findings that other agents or humans must act on
- Classifies issues by severity/priority
- Needs to communicate both "how bad" and "how sure" to downstream consumers
- Has findings that vary in evidence strength

**Do NOT apply** when:
- The agent's output is binary (pass/fail with no gradation)
- All findings have equal weight (checklist compliance)
- The agent doesn't make judgment calls about severity

## Implementation

### Define Severity Levels (closed set)

Choose a severity scale appropriate to the agent's domain. Use a closed set so downstream agents can aggregate mechanically.

```markdown
## Severity Levels

| Level | Name | Criteria | Downstream Action |
|-------|------|----------|-------------------|
| CRITICAL | Blocker | Cannot proceed without fixing | Immediate fix required |
| ERROR | Significant | Incorrect behavior or missing requirement | Fix before completion |
| WARNING | Minor | Style, convention, or optimization issue | Fix if time permits |
```

Or for investigation/root-cause agents:

```markdown
| Level | Name | Criteria | Downstream Action |
|-------|------|----------|-------------------|
| LEVEL_1 | Local | Single file, clear fix | Developer applies exact instructions |
| LEVEL_2 | Cross-cutting | Multiple files, needs context | Developer applies multi-file instructions |
| LEVEL_3 | Design decision | Multiple valid approaches | User chooses approach |
| LEVEL_4 | Human judgment | Investigation exhausted | User evaluates competing hypotheses |
```

### Define Confidence Levels (independent of severity)

```markdown
## Confidence Levels

| Level | Definition | Rule |
|-------|------------|------|
| HIGH | Evidence clearly supports verdict. Disconfirming evidence sought and not found. | Report as-is. |
| MEDIUM | Evidence supports verdict but alternatives couldn't be fully ruled out. | Report with noted uncertainty. |
| LOW | Multiple hypotheses remain plausible. | Do not report — investigate further or escalate. |
```

**Key rule:** LOW confidence findings never reach downstream consumers. The agent either deepens investigation or reframes the uncertainty itself as the finding (e.g., "human judgment required" with HIGH confidence).

### Pair in Output

Every finding carries both dimensions:

```markdown
| # | Severity | Confidence | File | Issue | Fix |
|---|----------|------------|------|-------|-----|
| 1 | ERROR | HIGH | auth.service.ts:42 | Missing org scope | Add where clause |
| 2 | WARNING | MEDIUM | user.dto.ts:15 | Unused field | Remove or prefix with _ |
```

## Rationale

Without confidence pairing, a LOW-confidence CRITICAL finding and a HIGH-confidence CRITICAL finding receive the same treatment — but one might be a false positive that wastes a developer round-trip. Confidence levels let downstream consumers prioritize: fix HIGH-confidence findings first, investigate MEDIUM-confidence ones if time permits. The "LOW never ships" rule prevents speculative findings from entering the pipeline.

## Example

**GOOD** — Investigator pairs severity with confidence:
```markdown
Verdict: LEVEL_2, Confidence: HIGH
Root cause spans auth.service.ts and auth.guard.ts. Evidence from both files
confirms the token validation logic diverges from the spec. Disconfirming evidence
sought (checked if spec was outdated) — spec is current.
```

**BAD** — Investigator conflates uncertainty with low severity:
```markdown
Verdict: LEVEL_1
Probably a minor issue in auth.service.ts. Might also be in the guard but
didn't have time to check thoroughly.
[Actually LEVEL_2 with LOW confidence — should investigate further, not downgrade]
```
