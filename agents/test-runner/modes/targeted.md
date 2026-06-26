# Mode: targeted

The bugfix intermediate fix-phase run. Runs exactly the test files named in `Files:`; no reports.

## Determine Scope

`Files:` is **required** — a semicolon- or newline-separated list of test file paths. The scope is exactly those files. If `Files:` is absent or empty, the run cannot be scoped — surface that rather than falling back to the full suite.

## Run

Run the project's test command targeting only the files named in `Files:`.

## Spec-of-Record

Resolve each failing test's spec-of-record **per test**, as `full-suite` does — a feature test against its BDD `.feature` scenario; a bugfix reproduction test against the bug report's `## Expected Behavior`.

## Results File

- **Filename:** the provided `Results Output Path`.
- **Header:** `# Phase [N] Test Results — [Phase Name]`.
- **Frontmatter `phase:`:** the dispatch's numeric `Phase`.
