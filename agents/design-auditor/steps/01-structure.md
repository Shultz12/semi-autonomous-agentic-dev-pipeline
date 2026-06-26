# Step 1: Structure Validation

Verify that the SDD file has all required sections, Meta fields are complete, and key tables are present.

## SDD Title

1. Grep for `# Software Design Document:` in SDD.md
2. If not found: WARNING — "SDD title does not follow expected format '# Software Design Document: [Feature Name]'"

## Required Sections

For each entry in the "SDD Required Sections" table in `design-review-rules.md`:
1. Grep for the heading pattern in SDD.md
2. If not found: flag at the severity specified in the rules
3. If found but section body is empty (next heading immediately follows or no content): flag at same severity — "[Section] heading present but section is empty"

### N/A Section Handling

For sections that are present but contain "N/A":
1. Check if the N/A is followed by a reason (e.g., "N/A — no schema changes needed")
2. If "N/A" without reason: WARNING — "[Section] marked N/A without explanation"
3. If "N/A" with reason: no issue (section is validly marked as not applicable)

## Meta Fields

For each field in the "Meta Fields" table in `design-review-rules.md`:
1. Grep for the field pattern in the Meta section
2. If not found: flag at the severity specified
3. If found but value is empty: flag at same severity — "Meta field [field] present but empty"

### Design Confidence Validation

1. Extract the Design Confidence value
2. Verify it is exactly one of: `High`, `Medium`, `Low`
3. If not: ERROR — "Design Confidence must be High, Medium, or Low; found '[value]'"

## Component Architecture Table

1. Verify the Component Architecture section contains a markdown table
2. Verify the table has columns: Component, Responsibility, Layer, Implements
3. Verify at least one data row exists
4. If no table found: ERROR — "Component Architecture section has no table"
5. If table has no data rows: ERROR — "Component Architecture table is empty"

## Design Decision Presence

1. Grep for `### DD-\d+:` in SDD.md
2. If no DD-# found: CRITICAL — "No design decisions (DD-#) found in SDD"
3. Extract all DD-# IDs and verify sequential numbering (DD-1, DD-2, DD-3...)
4. If gap found: ERROR — "Design decision numbering has gap: missing DD-[N]"

### Per-Decision Fields

For each DD-# found:
1. Read the section content (from DD-# heading to next DD-# heading or next H2)
2. Check each required field per "Per-Decision Required Fields" table in rules
3. If field missing: flag at severity specified

## Requirement Traceability Table

1. Verify the Requirement Traceability section contains a markdown table
2. Verify the table has columns: Requirement, SRS Location, Component, Design Decision
3. Verify at least one data row exists
4. If no table: CRITICAL — "Requirement Traceability section has no table"
5. If table has no data rows: ERROR — "Requirement Traceability table is empty"

## Integration Points Table (if section not N/A)

1. If section is not marked N/A:
   - Verify the section contains a markdown table
   - Verify the table has columns: Existing Component, File Location, How New Code Integrates
   - If no table: ERROR — "Integration Points section has no table (use N/A with reason if not applicable)"

## When Complete

Record all findings with their severity levels. Proceed to step 02.
Read: `steps/02-traceability.md`
