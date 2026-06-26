# Step 5: Content Quality

Detect vague or ambiguous language in SRS functional requirements and acceptance criteria.

## Scope

Scan these SRS sections for vague language:
- Section 5 (Functional Requirements) — all FR-X sections
- Acceptance criteria within each FR-X
- Section 6 (Non-Functional Requirements) — with quantification exemption

## Vague Language Patterns

Search for these patterns using Grep (case-insensitive):

### Unquantified Performance Claims

| Pattern | Vague Because |
|---------|---------------|
| "fast" / "quickly" / "quick" | No measurable target |
| "slow" / "slowly" | No measurable target |
| "responsive" / "performant" | No measurable target |
| "real-time" (without latency spec) | Could mean 1ms or 5s |

**Exemption**: If the vague term appears within 3 lines of a quantified value (e.g., "p50: 100ms"), do not flag it. The term is contextualized by the measurement.

### Subjective Quality Claims

| Pattern | Vague Because |
|---------|---------------|
| "user-friendly" / "intuitive" | Not testable |
| "easy" / "simple" / "straightforward" | Not testable |
| "clean" / "elegant" / "modern" | Not testable |
| "good" / "better" / "best" | No comparison baseline |

### Open-Ended Enumerations

| Pattern | Vague Because |
|---------|---------------|
| "etc." / "and so on" / "and more" | Undefined scope |
| "various" / "multiple" (without listing) | Undefined set |
| "other" / "others" (without specifying) | Undefined set |

### Undefined Conditions

| Pattern | Vague Because |
|---------|---------------|
| "as needed" / "when necessary" | Who decides? What triggers it? |
| "if appropriate" / "when applicable" | No criteria defined |
| "some" / "several" / "a few" | Unquantified |
| "reasonable" / "appropriate" / "suitable" | No measurable standard |

## Reporting

For each match:
- WARNING — "**SRS.md** Section: [FR-X or section name] — Vague language: '[matched text]' in '[surrounding context]'. Suggestion: Replace with a specific, measurable criterion"

## Non-Functional Requirements Exemption

In Section 6, only flag vague terms that appear without a quantified alternative in the same subsection. For example:
- "Response times should be fast" → FLAG (no quantification)
- "Response times should be fast. p50: 100ms, p95: 300ms" → DO NOT FLAG (quantified)
