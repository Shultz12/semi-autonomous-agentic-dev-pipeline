# VERIFICATION_FAILURE Mode

Loaded on-demand when the dispatch carries `Trigger: VERIFICATION_FAILURE` — diagnosing a lint/build failure that persisted after the developer's two fix attempts. Use this file in addition to the base persona's loaded rules (`essentials/review-rules.md` + the type review file named below).

## Step 1 — Type review files

Read the single type review file matching the Reviewer Type:

- Backend: `types/backend/backend-review.md`
- Frontend: `types/frontend/frontend-review.md`
- Infrastructure: `types/infrastructure/infrastructure-review.md`

## Step 3 — Read modified files

1. Read the developer report at the path provided in `Developer Report`.
2. Extract the file list from `## Files Modified`, the error output from `## Original Error Output`, and the fix attempts from `## Fix Attempt Summary`.
3. Read every file from the extracted file list.
4. Note the line numbers and context for later analysis.

## Step 4 — Diagnostics

Run the verification command for the Reviewer Type. The loaded type file's "Verification Command" section and the project's CLAUDE.md specify the exact command. The command's output is primary evidence for the failure.

## Step 7 — Review file

- **Filename:** `phase-[N]-code-review-attempt-[K].md` ([N] = phase number, [K] = `Review Attempt`).
- **Title word:** `Code Review`.
- **`phase` frontmatter:** included.
- **FAIL body:** standard.
