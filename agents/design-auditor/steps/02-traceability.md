# Step 2: Traceability Validation

Verify bidirectional traceability between SRS functional requirements and SDD content.

## Approach

This step verifies that every SRS functional requirement appears in the SDD's Requirement Traceability table, and that every entry in the traceability table references a real FR-X from the SRS. It also checks that DD-# references in the traceability table correspond to actual design decisions.

## Procedure

### 1. Extract FR-X IDs from SRS

From the SRS (loaded in Phase 3 of full-audit.md):
1. Grep for all `### FR-\d+:` headings
2. Extract the FR-X ID and requirement name from each heading
3. Build a list of all SRS FR-X IDs (e.g., FR-1, FR-2, FR-3)

### 2. Extract Traceability Table Rows from SDD

From the SDD Requirement Traceability table:
1. Extract the Requirement column values (expected format: `FR-X: [name]`)
2. Extract the SRS Location column values (expected format: `SRS.md:L##`)
3. Extract the Design Decision column values (expected format: `DD-#`)
4. Build a list of all SDD-referenced FR-X IDs

### 3. Forward Check: Every SRS FR-X in Traceability

For each FR-X in the SRS:
1. Check if it appears in the SDD traceability table
2. If not found: ERROR — "FR-[X]: '[name]' from SRS is missing from Requirement Traceability table"

### 4. Backward Check: Every Traceability Row References Real FR-X

For each FR-X in the SDD traceability table:
1. Check if it exists in the SRS
2. If not found: ERROR — "Traceability table references FR-[X] which does not exist in SRS"

### 5. SRS Location Format Check

For each row in the traceability table:
1. Check that the SRS Location column uses `SRS.md:L##` format (regex: `SRS\.md:L\d+`)
2. If format doesn't match: WARNING — "Traceability row for FR-[X] has non-standard SRS Location format: '[value]'"

Note: Line number accuracy is not verified. Line numbers shift when the SRS is edited. Format presence is sufficient.

### 6. Design Decision Reference Check

For each row in the traceability table:
1. Extract the DD-# reference from the Design Decision column
2. Check that a matching `### DD-[N]:` heading exists in the SDD
3. If not found: ERROR — "Traceability row for FR-[X] references DD-[N] which does not exist in SDD"

### 7. Orphan Design Decision Check

For each DD-# in the Design Decisions section:
1. Check if it appears in at least one traceability table row
2. If not found: WARNING — "DD-[N]: '[title]' is not referenced in the Requirement Traceability table"

### 8. DD-# Requirements Field Format Check

For each DD-# in the Design Decisions section:
1. Check the Requirements field for FR-X references with SRS line numbers
2. Expected format: `FR-X (SRS.md:L##)` (regex: `FR-\d+\s*\(SRS\.md:L\d+\)`)
3. If no such format found in the Requirements field: WARNING — "DD-[N] Requirements field does not use FR-X (SRS.md:L##) format"

## Summary

After all checks, report:
- Total SRS FR-X count
- FR-X present in traceability table
- FR-X missing from traceability table (listed)
- Orphan DD-# not in traceability (listed)

## When Complete

Record all findings with their severity levels. Proceed to step 03.
Read: `steps/03-code-references.md`
