# ABSTRACT_MIGRATION_REVIEW Mode

Loaded on-demand when the orchestrator dispatches a phase carrying the `abstract-migration-phase` flag. Use this file in addition to the base persona's loaded rules (`essentials/review-rules.md` + all type review files listed in `Reviewer Types`).

## Trigger

ABSTRACT migration phases are emitted by `plan-architect` (`Target: refactor-plan`) — never by `feature-final`. They originate from an approved `pattern-analyst` finding whose `directive: ABSTRACT` is the authoritative work-item source. The orchestrator's input carries:

- `Trigger: ABSTRACT_MIGRATION_REVIEW`
- `Approved Pattern Finding Path: .project/cycles/<slug>/refactor-proposals/pattern-approved.md` — the canonical source for `call-site-data`, `stragglers`, and the `generalized-signature` the phase is supposed to land

## Scope

| Task | Action | Why |
|------|--------|-----|
| T1 — new signature | Review fully | Authored type contract change |
| T2 — codemod script | Review fully | Authored; correctness drives mass changes downstream |
| T2 — codemod tests | Review fully | Verifies codemod correctness on fixtures before mass run |
| T3 — codemod execution | No artifact | Mechanical execution; output verified by T2 tests |
| T4 — build run | No artifact | Pass/fail signal; test-runner reports |
| T5 — manual stragglers (only if T4 captured failures) | Review fully | Authored fixes per file; each is a real authored change |
| Codemod-modified call-sites | SKIP unless tests fail | Per-call-site review duplicates T2's test coverage. If tests fail, narrow review to failing files only. |

## Read Protocol (mode-specific additions)

After the base Step 1 reads:

1. Read the approved pattern finding at the path supplied in `Approved Pattern Finding Path`. Extract:
   - `generalized-signature` (T1 acceptance)
   - `call-site-data` totals (`.ts`, `.svelte`, tractable subtotal)
   - `stragglers` list (T5 enumeration)
2. Read the codemod script at the path under `.project/cycles/<cycle>/codemods/<codemod-slug>.ts`. Extract the modified-file count recorded by developer in T3 (the developer report's `## Artifacts Produced` section).
3. Read the residual stragglers artifact at `.project/cycles/<cycle>/execution/<date>-codemod-stragglers-<cycle>.md` to verify it is empty after T5.

## Step 3 (mode override)

1. Read the developer report at `Developer Report`. Extract:
   - `## Files Modified` — the authored files for T1, T2, T2-tests, T5
   - `## Artifacts Produced` — including the codemod modified-file count from T3
2. Read every authored file from `## Files Modified` (T1 signature file, T2 codemod + tests, T5 straggler fixes). Do NOT read codemod-modified call-sites unless tests fail (see Verification Checklist item 6).

## Verification Checklist

Each item produces zero or one finding. All items must pass for the review to PASS.

1. **Signature integrity (T1)** — Signature change preserves type contract end-to-end (no proliferating union types, no required generic parameters at call-sites, no casts). Mismatch is `CRITICAL × TYPE`.
2. **Bidirectional call-site count match (T2/T3)** — Codemod script's modification count (from `## Artifacts Produced`) matches the `call-site-data` totals in the cited approved finding. Mismatch in **either direction** is a defect: under-count → codemod incomplete; over-count → codebase has drifted from the call-sites recorded in the approved finding and the migration-tractability hard gate may have been silently invalidated. Either case is `CRITICAL × INTEGRATION` and the migration phase fails review.
3. **Codemod test coverage (T2-tests)** — Codemod tests cover the full set of variants the codemod is supposed to transform (per the cited finding's `call-site-data` breakdown). Gaps are `ERROR × VALIDATION`.
4. **Stragglers list completeness and resolution (T5)** — Stragglers list (from the cited finding's `stragglers` field) is complete (no untracked failures beyond what the finding enumerated) and resolved (`.project/cycles/<cycle>/execution/<date>-codemod-stragglers-<cycle>.md` is empty). Untracked stragglers are `CRITICAL × INTEGRATION`; unresolved entries are `ERROR × LOGIC`.
5. **Structured codemod-error coverage (T3 → T5)** — All structured codemod errors (T3 error output: `CALL_SITE_TYPE_MISMATCH`, `AMBIGUOUS_TARGET`, `UNRESOLVABLE_IMPORT`, etc.) are either successfully fixed in T5 or explicitly listed as out-of-scope with a documented reason. Silent omission is `ERROR × LOGIC`.
6. **Call-site failure review (conditional on test failure)** — If T2 codemod tests fail, narrow review to the failing files only and apply standard PHASE_REVIEW rules to each. Findings get `Task: call-site-fail`.

## Per-Finding Output Template (extended)

Same structure as the base persona's template, with an added `Task:` field:

```markdown
## Finding: <id>
Severity: CRITICAL | ERROR | WARNING
Confidence: HIGH | MEDIUM
Category: LOGIC | VALIDATION | INTEGRATION | TYPE | SECURITY | CONVENTION
Task: T1 | T2 | T2-tests | T5 | call-site-fail
File: <path>:<line>
Issue: <one-sentence problem>
Recommended fix: <one sentence>
Suggested knowledge source: <path or "none">
```

The `Task` field allows downstream agents to attribute defects to a specific migration step (signature, codemod, codemod tests, manual stragglers, or call-site failure handling).

## PASS Conditions

All six verification-checklist items pass AND standard rules (universal + per-type) pass on every authored file.
