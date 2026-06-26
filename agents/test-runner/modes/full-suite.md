# Mode: full-suite

The bugfix final-phase gate and the tool-oracle regression run. Runs the whole project suite; no reports.

## Determine Scope

The scope is the **full project test suite**. No reports are read — the run needs no input beyond the project's standard test command.

## Run

Run the project's standard test command.

## Spec-of-Record

The suite is mixed: feature tests and bugfix reproduction tests run together. Resolve each failing test's spec-of-record **per test** — a feature test against its BDD `.feature` scenario; a bugfix reproduction test against the bug report's `## Expected Behavior`.

## Results File

- **Filename:** the provided `Results Output Path`.
- **Header:** `# Phase [N] Test Results — [Phase Name]`. When the dispatch names `Phase: 0: <sub-step>` (e.g. the tool-oracle regression run), the sub-step name replaces the phase-name portion in the human-readable header (e.g. `# Test Results — tool-oracle-regression`).
- **Frontmatter `phase:` and the commit subject's `phase <N>` token:** the dispatch's `Phase`; for a `Phase: 0: <sub-step>` dispatch, the numeric prefix `0` only — the sub-step name never enters the `phase:` field (Phase Prefix Rule, `formats/results-format.md`).
