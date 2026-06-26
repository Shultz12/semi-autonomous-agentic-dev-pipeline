# ABSTRACT Migration — Decision Matrix and Finding Contract

Loaded on-demand by `convergence-scout` and `primitives-scout` when an ABSTRACT
candidate is identified, and by `pattern-analyst-auditor` when verifying an ABSTRACT
finding. Single source of truth for the abstraction decision logic. Plan-architect does
NOT read this file directly; it consumes ABSTRACT decisions via the structured-finding
contract below.

## Abstraction Decision Matrix

### Hard Gates

Failing either gate → automatic REJECT verdict; no scoring axes are evaluated.

| Hard gate | Pass condition |
|---|---|
| Type & contract compatibility | Variants return the same type, throw the same error categories, and satisfy the same invariants. No proliferating union types, no generic-parameter explosion forcing explicit `<T>` at every call-site, no casts. |
| Migration tractability | YES to ALL of: (a) codemod handles ≥50% of call-sites (script-confirmed by `find-call-sites.ts` output, including `.svelte` coverage); (b) stragglers are enumerable and bounded (uncertain entries are explicit and listed); (c) resulting code preserves type safety end-to-end. The ≥50% threshold is the hard gate; the ≥80% threshold is consulted separately for the one-phase vs two-phase split. |

### Scoring Axes

Both hard gates must pass. Then ≥2 of the 3 scoring axes must pass for an APPROVE
verdict.

| Axis | Pass condition |
|---|---|
| Variant count | ≥3 narrow variants exist or are in accepted SRSes (speculative roadmap entries do not count) |
| Shape congruence | Variants share ≥80% of parameters; the differing piece is one orthogonal dimension (operator, mode, locale, role) |
| Call-site stability | The generalized form preserves intent at call-sites, OR readability-preserving alias helpers are introduced |

### Verdicts

| Hard gates | Scoring axes | Verdict |
|---|---|---|
| Either fails | (any) | REJECT |
| Both pass | ≥2 of 3 PASS | APPROVE |
| Both pass | ≤1 of 3 PASS | REJECT |

There is no FLAG-FOR-DECISION verdict. The agent decides; the user later approves or
rejects via the curate cycle. No human escalation at the pre-curate stage.

## ABSTRACT Migration Phase Splitting

Consumed by plan-architect's `refactor-plan` target as the `phase-splitting-recommendation`
field. Half-open intervals make boundary cases unambiguous.

- Codemod handles **≥80%** of call-sites → `phase-splitting-recommendation: one-phase`
  (codemod + manual stragglers in the same phase).
- Codemod handles **50% ≤ x < 80%** → `phase-splitting-recommendation: two-phase`
  (separate codemod phase, then manual cleanup phase).
- Codemod handles **<50%** → fails the migration-tractability hard gate (REJECT verdict;
  no APPROVE finding can carry this band). The hard-gate threshold IS 50% (not 80%);
  80% is the one-phase vs two-phase split only.

## Structured ABSTRACT Finding Contract (Verdict-Conditional)

Every ABSTRACT finding with `verdict: APPROVE` MUST contain ALL fields in the block
below. Findings with `verdict: REJECT` need only the minimal subset (`source-file`,
`source-function`, `current-signature`, `verdict: REJECT`, `reject-reason: <text>`); all
other fields are optional and meaningless for REJECTs (the evaluation that produced
REJECT short-circuits the matrix, so unfilled scoring axes / call-site arithmetic /
phase-split recommendation have no value to record).

Plan-architect's `refactor-plan` target enforces the full-field contract as a hard-gate
precondition for APPROVE findings only — REJECTs are dropped by `curate` before
plan-architect sees them. Pattern-analyst-auditor applies the verdict-conditional
completeness check upstream.

```markdown
### Finding <finding-id>: ABSTRACT — generalize <source-function>
- directive: ABSTRACT
- source-file: <repo-relative path to the existing narrow utility>
- source-function: <name of the existing function/symbol>
- current-signature: <narrow utility's current TypeScript signature>
- generalized-signature: <proposed generalized signature>
- srs-citations:                                          # REQUIRED when emitted by `primitives-scout` (≥2 entries); optional otherwise
    - { feature-slug: <slug>, path: .project/cycles/<cycle>/specs/SRS.md }
    - { feature-slug: <slug>, path: .project/cycles/<cycle>/specs/SRS.md }
- hard-gates:
    type-and-contract-compatibility: PASS|FAIL — <one-sentence reasoning>
    migration-tractability:
      codemod-coverage-≥50%: PASS|FAIL — <coverage figure, e.g., "30/32 (.ts: 25/27, .svelte: 5/5)"> — PASS iff coverage ≥50%; the 80% threshold is consulted separately by `phase-splitting-recommendation`, not here.
      stragglers-enumerable: PASS|FAIL — <count of stragglers + brief reason>
      type-safety-preserved: PASS|FAIL — <one-sentence reasoning>
- scoring-axes:
    variant-count: PASS|FAIL — <list of N narrow variants observed>
    shape-congruence: PASS|FAIL — <one-sentence reasoning>
    call-site-stability: PASS|FAIL — <one-sentence reasoning>
- verdict: APPROVE | REJECT
- reject-reason: <text>                                   # REQUIRED when verdict=REJECT; omit when verdict=APPROVE
- call-site-data:
    total: <integer>
    .ts: <integer>
    .svelte: <integer>
    uncertain: <integer>
    sites: []                                             # empty case (rare; e.g., for newly-authored utils not yet called)
    sites:                                                # non-empty case
      - { file: <path>, line: <int>, column: <int>, kind: ts | svelte | uncertain, reason?: <text when uncertain> }
      - { file: <path>, line: <int>, column: <int>, kind: ts | svelte | uncertain, reason?: <text when uncertain> }
- stragglers: []                                          # empty case (e.g., codemod coverage = 100%)
- stragglers:                                             # non-empty case
    - { file: <path>, line: <int>, reason: <text> }
    - { file: <path>, line: <int>, reason: <text> }
- phase-splitting-recommendation: one-phase | two-phase
```

Findings with `verdict: REJECT` are written to the findings file for transparency (so
the user sees the candidate was considered) but `pattern-analyst-auditor` marks them
`REJECT` and `curate` drops them from `approved.md`. Only `verdict: APPROVE` findings
ever reach plan-architect.

## When Verdict Is REJECT on ABSTRACT — Fallback Action

The two scout modes that emit ABSTRACT findings differ in their fallback behavior:

- `convergence-scout` — emit a separate **EXTRACT** finding with the next sequential
  `CF-<n>` ID consolidating the cluster as a new util with a distinct name. The cluster
  still needs consolidation; it just becomes a separately-named util rather than a
  generalized one. Both findings remain in the file for transparency.
- `primitives-scout` — emit a **CREATE** finding for a separate util with a different
  name (avoids signature ambiguity with the existing narrow variant). Both findings
  remain in the file for transparency.

REJECT on ABSTRACT does not mean "do nothing." The fallback differs by flow because the
two scout modes are surfacing different upstream signals.
