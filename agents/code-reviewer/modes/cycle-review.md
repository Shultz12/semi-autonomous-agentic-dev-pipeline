# CYCLE_REVIEW Mode

Loaded on-demand when the dispatch carries `Trigger: CYCLE_REVIEW` — the cross-phase, feature-wide review after all phases are complete. Use this file in addition to the base persona's loaded rules (`essentials/review-rules.md` + all type review files listed in `Reviewer Types`).

## Step 1 — Type review files

Read ALL type review files listed in the input's `Reviewer Types` field:

- Backend: `types/backend/backend-review.md`
- Frontend: `types/frontend/frontend-review.md`
- Infrastructure: `types/infrastructure/infrastructure-review.md`
- Test: `types/test/test-review.md`

## Step 3 — Read modified files

1. Read the feature summary at the path provided in `Cycle Summary Path`.
2. Extract per-phase file lists, developer types, and artifact details from the summary.
3. Read all extracted files.
4. Apply the Integration Context checks (one-hop dependency trace, utility duplication search).

## Step 4 — Diagnostics

Run diagnostics for ALL involved types — one verification command per type in the `Reviewer Types` list.

## Step 5 — Analyze (additions)

Also check cross-phase integration and end-to-end data flow: verify that types, interfaces, and contracts are consistent across all phases.

## Step 7 — Review file

- **Filename:** `cycle-review.md`.
- **Title word:** `Code Review` (feature-titled; no phase number in the title).
- **`phase` frontmatter:** omitted.
- **FAIL body:** standard.
