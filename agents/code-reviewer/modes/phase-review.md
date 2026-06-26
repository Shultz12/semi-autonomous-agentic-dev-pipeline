# PHASE_REVIEW Mode

Loaded on-demand when the dispatch carries `Trigger: PHASE_REVIEW` — the standard post-implementation review after the developer reports SUCCESS. Use this file in addition to the base persona's loaded rules (`essentials/review-rules.md` + the type review file named below).

When the dispatch also carries `Investigation File: <path>` (bugfix-flow PHASE_REVIEW), the analysis gains one fidelity check from `modes/phase-review-bugfix.md` (see Step 5).

## Step 1 — Type review files

Read the single type review file matching the Reviewer Type:

- Backend: `types/backend/backend-review.md`
- Frontend: `types/frontend/frontend-review.md`
- Infrastructure: `types/infrastructure/infrastructure-review.md`

## Step 3 — Read modified files

1. Read the developer report at the path provided in `Developer Report`.
2. Extract the file list from `## Files Modified`.
3. Read every file from the extracted file list.
4. Note the line numbers and context for later analysis.
5. Apply the Integration Context checks (one-hop dependency trace, utility duplication search).

## Step 4 — Diagnostics

Run the verification command for the Reviewer Type. The loaded type file's "Verification Command" section and the project's CLAUDE.md specify the exact command.

## Step 5 — Analyze (additions)

When the dispatch carries `Investigation File: <path>`, also load and apply `modes/phase-review-bugfix.md`: read the investigation, then check whether the change addresses the documented cause or merely masks/suppresses the symptom. Absent `Investigation File:`, PHASE_REVIEW runs the base Step 5 analysis with nothing added.

## Step 7 — Review file

- **Filename:** `phase-[N]-code-review-attempt-[K].md` ([N] = phase number, [K] = `Review Attempt`).
- **Title word:** `Code Review`.
- **`phase` frontmatter:** included.
- **FAIL body:** standard.
