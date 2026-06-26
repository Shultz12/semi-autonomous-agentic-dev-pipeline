# Mode: phase

The feature pipeline's per-phase run. Runs the full project test suite and attributes any failures against each failing test's BDD spec-of-record. `Implementation Report` and `Test Report` are optional attribution context only — absent or `none` is valid and never narrows the run.

## Determine Scope

The scope is the **full project test suite** — every test the project's standard test command exercises. Reports do not narrow the run: if `Implementation Report` / `Test Report` are provided, read them for attribution context; if they are absent or `none`, skip report-reading and run the standard command regardless.

## Run

Run the project's standard test command (from the project's development configuration already in context — CLAUDE.md / development docs).

## Spec-of-Record

For each failing test, the spec-of-record is the BDD `.feature` scenario in the feature's `specs/` directory that corresponds to the test.

## Results File

- **Filename:** the provided `Results Output Path` — `phase-<N>-results.md` under the feature's `execution/test-results/`.
- **Header:** `# Phase [N] Test Results — [Phase Name]`.
- **Frontmatter `phase:`:** the numeric phase `<N>`.
