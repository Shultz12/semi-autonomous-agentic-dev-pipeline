# INTEGRATION_VERIFICATION Mode

Loaded on-demand when the dispatch carries `Trigger: INTEGRATION_VERIFICATION` — the structural integration check after all phases are complete. It verifies that artifacts exist, are substantive, and are wired into the system; it does NOT run lint/build and does NOT test behavior. Use this file in addition to the base persona's loaded rules (`essentials/review-rules.md` + `essentials/integration-checks.md` + all type review files listed in `Reviewer Types`).

This mode uses the distinct category set `MISSING | STUB | UNWIRED` defined in `essentials/integration-checks.md`, not the standard category set.

## Step 1 — Type review files

Read `essentials/integration-checks.md` and ALL type review files listed in the input's `Reviewer Types` field:

- Backend: `types/backend/backend-review.md`
- Frontend: `types/frontend/frontend-review.md`
- Infrastructure: `types/infrastructure/infrastructure-review.md`

## Step 3 — Read modified files

1. Read the plan at `Plan Path` — extract the phase-artifacts sections to derive requirements (what should exist).
2. Read the feature summary at `Cycle Summary Path` to get the complete file list (what was created/modified).
3. Build an artifact inventory from these two sources.
4. For each requirement, identify which files are expected to fulfill it.
5. Read all listed files to assess their content.

## Step 4 — Diagnostics

Do NOT run lint/build. Execute the 3-level checks from `essentials/integration-checks.md`:

1. **Level 1 — EXISTS:** Glob for each expected artifact file.
2. **Level 2 — SUBSTANTIVE:** Read files that pass Level 1; check against the stub-detection patterns.
3. **Level 3 — WIRED:** Grep for wiring evidence per the type-specific wiring tables in `integration-checks.md` and the loaded type files.

Short-circuit: if an artifact fails Level 1, skip Levels 2 and 3 for that artifact. Capture the output — it is primary evidence for CRITICAL findings.

## Step 5 — Analyze (additions)

Compile MISSING / STUB / UNWIRED findings from the Step 4 results. For each finding, verify it with tool evidence (Glob result for MISSING, Read excerpt for STUB, Grep result for UNWIRED). Limit to 2 passes through the artifact list.

## Step 7 — Review file

- **Filename:** `integration-verification.md`.
- **Title:** feature-titled — `# Feature [Code] Review — [Feature Name]`; no phase number in the title.
- **`phase` frontmatter:** omitted.
- **FAIL body:** integration-specific (the `### Integration Summary` block and the `Evidence:`-bearing per-finding format).
