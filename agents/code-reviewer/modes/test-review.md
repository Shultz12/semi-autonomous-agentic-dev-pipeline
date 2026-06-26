# TEST_REVIEW Mode

Loaded on-demand when the dispatch carries `Trigger: TEST_REVIEW` — review of test files written by the developer (test type). Use this file in addition to the base persona's loaded rules (`essentials/review-rules.md` + the test type review file named below).

## Step 1 — Type review files

Read `types/test/test-review.md`.

## Step 3 — Read modified files

1. Read the developer report at the path provided in `Developer Report`.
2. Extract the test file list from `## Files Modified`.
3. Read every test file from the extracted file list.
4. Note the line numbers and context for later analysis.

## Step 4 — Diagnostics

Run the verification command for the test type. The loaded `types/test/test-review.md` "Verification Command" section and the project's CLAUDE.md specify the exact command.

## Step 7 — Review file

- **Filename:** `phase-[N]-test-review-attempt-[K].md` ([N] = phase number, [K] = `Review Attempt`).
- **Title word:** `Test Review`.
- **`phase` frontmatter:** included.
- **FAIL body:** standard.
