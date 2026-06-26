# Step 3: BDD Validation

Validate CONTEXT.md content quality and .feature file structure. Run gherkin-lint for syntax validation.

## CONTEXT.md Content Checks

If CONTEXT.md exists (presence already checked in Step 1):

### Domain Language Table

1. Grep for `## Domain Language` section
2. If present: check for a markdown table (pipe-delimited rows)
3. If table has fewer than 2 data rows: WARNING — "Domain Language table has only [N] entries. Consider defining more domain terms"

### Actors Table

1. Grep for `## Actors` section
2. If present: check for a markdown table
3. If table has fewer than 1 data row: WARNING — "Actors table is empty"

### Implementation Mapping Table

1. Grep for `## Implementation Mapping` section
2. If present: check for a markdown table with Given/When/Then patterns
3. If no Given/When/Then patterns found in table: WARNING — "Implementation Mapping table does not follow Given/When/Then step mapping pattern"

## .feature File Structure Checks

For each .feature file found in `<specs-dir>/bdd/`:

### Feature-Level Tags

1. Read the first line of the file
2. Check for `@domain:` tag: if missing, ERROR — "[file]: Missing @domain: tag"
3. Check for `@priority:` tag: if missing, ERROR — "[file]: Missing @priority: tag"
4. Check for `@layer:` tag: if missing, ERROR — "[file]: Missing @layer: tag"

### Feature Declaration

1. Grep for `Feature:` keyword
2. If not found: CRITICAL — "[file]: No Feature declaration found"
3. If found: check that it has a description (not just `Feature:` with empty text)

### Scenario Presence

1. Grep for `Scenario:` or `Scenario Outline:` keywords
2. Count occurrences
3. If zero: ERROR — "[file]: No scenarios found"

### Scenario Tags

1. For each Scenario/Scenario Outline, check for a tag on the preceding line
2. Expected tags: `@happy-path`, `@error-handling`, `@edge-case`, `@defense-in-depth`
3. If a scenario has no categorization tag: WARNING — "[file]: Scenario '[name]' has no categorization tag (@happy-path, @error-handling, @edge-case, or @defense-in-depth)"

### Scenario Outline Completeness

1. For each `Scenario Outline:` found, check that an `Examples:` table follows before the next Scenario
2. If no Examples table: ERROR — "[file]: Scenario Outline '[name]' has no Examples table"

## Gherkin Syntax Validation (via gherkin-lint)

For each .feature file:

1. Run: `npx gherkin-lint "<file-path>" 2>&1`
2. Check exit code:
   - **Exit 0**: Gherkin syntax valid, no issues
   - **Non-zero exit**: Parse the output for error messages
     - For each error line: ERROR — "[file]: gherkin-lint: [error message]"
3. If `npx` or `gherkin-lint` command not found (exit code 127 or "not found" in output):
   - WARNING — "gherkin-lint is not available. Install with `npm install -D gherkin-lint` for Gherkin syntax validation. Skipping syntax checks for all .feature files."
   - Skip gherkin-lint for all remaining files (do not retry)
