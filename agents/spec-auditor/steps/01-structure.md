# Step 1: Structure Validation

Verify that all required files exist and all required SRS sections are present.

## File Presence Checks

### SRS File

1. Glob for `<specs-dir>/SRS.md`
2. If not found: CRITICAL — "SRS.md not found in specs directory"
3. If found but empty: CRITICAL — "SRS.md exists but is empty"

### BDD Directory

1. Glob for `<specs-dir>/bdd/`
2. If not found: ERROR — "BDD directory not found at <specs-dir>/bdd/"

### BDD Files

1. Glob for `<specs-dir>/bdd/CONTEXT.md`
   - If not found: ERROR — "CONTEXT.md not found in bdd directory"
2. Glob for `<specs-dir>/bdd/<feature-name>.feature` (primary feature file)
   - If not found: ERROR — "Primary feature file <feature-name>.feature not found"
3. Glob for `<specs-dir>/bdd/<feature-name>-errors.feature`
   - If not found: INFO — "Consider adding error scenarios in <feature-name>-errors.feature"
4. Glob for `<specs-dir>/bdd/<feature-name>-edge-cases.feature`
   - If not found: INFO — "Consider adding edge case scenarios in <feature-name>-edge-cases.feature"

## SRS Frontmatter Checks

1. Read the first lines of SRS.md for YAML frontmatter (between `---` delimiters)
2. Check each required field per the rules in `spec-review-rules.md` (SRS Frontmatter Fields table)
3. Verify `active-layers` is a non-empty list with items from: backend, frontend, infrastructure
   - If empty or invalid item: ERROR — "Invalid active-layers '[value]'. Must be a non-empty list of: backend, frontend, infrastructure"

## SRS Section Presence

### Required Sections

For each entry in the "Required Sections" table in `spec-review-rules.md`:
1. Grep for the heading pattern in SRS.md
2. If not found: flag at the severity specified in the rules
3. If found but section body is empty (next heading immediately follows): flag as same severity — "[Section] heading present but section is empty"

### Conditional Sections

1. Read `active-layers` from frontmatter
2. For each entry in the "Conditional Sections" table:
   - Check whether the entry's layer is a member of active-layers
   - If condition matches: Grep for the heading pattern
   - If not found: flag at the severity specified

### Optional Sections

For each entry in the "Optional Sections" table:
1. Grep for the heading pattern
2. If not found: INFO — "Optional section [name] not present"

## CONTEXT.md Section Presence

If CONTEXT.md exists:
1. Read the file
2. For each entry in the "CONTEXT.md Required Sections" table:
   - Grep for the heading pattern
   - If not found: flag at the severity specified
