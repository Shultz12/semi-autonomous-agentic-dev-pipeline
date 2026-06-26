# Step 4: Traceability

Verify that each SRS functional requirement has plausible BDD scenario coverage.

## Approach

BDD scenarios use business language and do not reference FR-X IDs directly. This check uses keyword-based heuristic matching: extract key domain terms from each FR-X and search .feature files for those terms.

This is intentionally WARNING-severity. False positives are possible when scenarios use different phrasing from the SRS requirement name.

## Procedure

### 1. Extract FR-X Requirements

From the SRS, for each FR-X heading:
- Extract the requirement name (e.g., "Assign Task to Team Member" from `### FR-1: Assign Task to Team Member (P0)`)
- Extract 2-3 key domain terms from the name (e.g., "assign", "task", "member")
- Also extract key terms from the first 2-3 acceptance criteria items

### 2. Search BDD Files

For each FR-X:
1. Grep all .feature files in `<specs-dir>/bdd/` for the key domain terms
2. A "match" is defined as: at least 2 of the key domain terms appear in the same .feature file
3. Also search CONTEXT.md's Implementation Mapping table for the terms

### 3. Report Coverage

For each FR-X:
- If at least one .feature file contains a plausible match: no issue
- If no plausible match found: WARNING — "FR-[X]: '[requirement name]' may lack BDD coverage — no scenario mentions key terms [term1, term2, term3]"

### 4. Summary

After checking all FR-X requirements, report:
- Total FR-X count
- FR-X with plausible BDD coverage
- FR-X without coverage (listed)

If all FR-X have coverage: no additional issue
If >50% of FR-X lack coverage: WARNING — "Significant traceability gap: [N] of [M] functional requirements have no plausible BDD scenario coverage"
