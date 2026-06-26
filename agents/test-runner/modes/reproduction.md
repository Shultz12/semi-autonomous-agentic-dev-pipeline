# Mode: reproduction

The bugfix Stage 1 reproduction run. Runs only the reproduction test file(s) and expects them RED — the bug is still unfixed. `Test Report` is **required**; `Implementation Report` is not used.

## Determine Scope

Read the `Test Report` at the provided path and extract its `## Files Modified` list. The scope is exactly those test files — the reproduction test(s). `Test Report` is required: if it is absent or `none`, the run cannot be scoped — surface that rather than falling back to the full suite.

## Run

Run the project's test command targeting only the reproduction test file(s) from Determine Scope.

## Spec-of-Record

These tests have no `.feature`. Each one's spec-of-record is the bug report's `## Expected Behavior`.

## Results File

This is a pre-plan run — it happens before an implementation plan exists, and the dispatch names the phase as `Phase: 0: bugfix-reproduce`.

- **Filename:** the provided `Results Output Path` (pre-plan naming).
- **Header:** the human-readable title carries the descriptive sub-step name, e.g. `# Test Results — bugfix-reproduce`.
- **Frontmatter `phase:` and the commit subject's `phase <N>` token:** the numeric prefix only — `0`. The descriptive sub-step name never enters the `phase:` field (Phase Prefix Rule, `formats/results-format.md`).
