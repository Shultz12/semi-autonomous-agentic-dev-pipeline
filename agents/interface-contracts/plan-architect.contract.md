# plan-architect Interface Contract

## Dispatch Contract

Every invocation passes:

| Field | Values | Required |
|---|---|---|
| `Mode` | `create` \| `update` | Yes |
| `Target` | `feature-draft` \| `feature-final` \| `test-plan` \| `refactor-plan` \| `bugfix-reproduction` \| `bugfix-draft` \| `bugfix-final` \| `deviation` | Yes |
| `Implementation Phase` | integer ≥ 1 | Required when `Target: test-plan`; ignored otherwise |
| `Cycle` | feature slug (e.g. `19-04-2026-pdf-extraction`) | Required for the plan-authoring targets; for `deviation`, replaced by the fields below |
| `Cycle Path` | path to `.project/cycles/<cycle>/` | Same as `Cycle` |

`create` and `update` are both valid for `feature-draft`, `feature-final`, `test-plan`, `refactor-plan`, `bugfix-reproduction`, `bugfix-draft`, and `bugfix-final`. `deviation` is **update-only** (`Mode: create` against it returns `CREATE_UNSUPPORTED_FOR_DEVIATION`).

When `Target: deviation`, these fields replace the feature-derived inputs:

| Field | Values | Required |
|---|---|---|
| `Plan Path` | path to an existing `implementation-plan.md` or `phase-<N>-test-plan.md` | Yes |
| `Completed Phase` | `<N>: <phase-name>` | Yes |
| `Developer Report` | path; its `## Deviation Report` section is the input | Yes |

## Example Invocations

Common case — author a feature draft from approved specs:

```
Mode: create
Target: feature-draft
Cycle: 19-04-2026-pdf-extraction
Cycle Path: .project/cycles/19-04-2026-pdf-extraction
```

Edge case — reconcile a plan after a phase deviation (update-only `deviation` target):

```
Mode: update
Target: deviation
Plan Path: .project/cycles/19-04-2026-pdf-extraction/plans/implementation-plan.md
Completed Phase: 2: format Hebrew date
Developer Report: .project/cycles/19-04-2026-pdf-extraction/execution/developer-reports/phase-2-developer-report.md
```

Bug-fix flow — reproduction plan (Stage 1):

```
Mode: create
Target: bugfix-reproduction
Cycle: 19-04-2026-fix-hebrew-date-parse-crash
Cycle Path: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash
Bug Report: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/specs/bug-report.md
```

Bug-fix flow — fix plan draft (Stage 2 pass 1):

```
Mode: create
Target: bugfix-draft
Cycle: 19-04-2026-fix-hebrew-date-parse-crash
Cycle Path: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash
Bug Report: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/specs/bug-report.md
Investigation Files: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/execution/code-investigations/19-04-2026-14-30-investigation.md
```

Bug-fix flow — fix plan final (Stage 2 pass 2):

```
Mode: create
Target: bugfix-final
Cycle: 19-04-2026-fix-hebrew-date-parse-crash
Cycle Path: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash
Plan Draft Path: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/plans/implementation-plan-draft.md
Bug Report: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/specs/bug-report.md
Investigation Files: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/execution/code-investigations/19-04-2026-14-30-investigation.md
```

## Per-Target Inputs

### `Target: feature-draft`

**Any action:**
- `.project/knowledge/architecture.md`, `overview.md`, `sitemap.md`
- `.project/knowledge/tech-stack/charter.md` — approved-technology allowlist, read from the main root (main-canonical).
- `.claude/agents/developer/essentials/<dev-type>/knowledge-map.md` for each `<dev-type>` the feature touches.

**Mode: create:** SRS + BDD (`CONTEXT.md` and at least one `.feature`) + SDD at `.project/cycles/<cycle>/specs/`.
**Mode: update:** existing `.project/cycles/<cycle>/plans/implementation-plan-draft.md` + revised spec(s).

### `Target: feature-final`

**Any action:**
- `.project/cycles/<cycle>/plans/implementation-plan-draft.md` (preserved).
- `.project/knowledge/tech-stack/charter.md` — approved-technology allowlist, read from the main root (main-canonical).
- Every `.project/knowledge/<type>/_index.md`; convention bodies on token-overlap match.

**Mode: create:** the draft must exist.
**Mode: update:** both draft AND final must exist; optionally a revised draft.

### `Target: test-plan`

**Any action:**
- `Implementation Phase: <N>` (dispatch field).
- `.project/cycles/<cycle>/specs/bdd/CONTEXT.md` and `.project/cycles/<cycle>/specs/bdd/*.feature`.
- `.project/cycles/<cycle>/specs/SRS.md`.
- Implemented code paths in the worktree (extracted from `## Artifacts Produced` and `## Files Modified` of the phase's developer report).

**Mode: create:** code-reviewer findings for phase `<N>`.
**Mode: update:** existing `phase-<N>-test-plan.md` + the trigger (revised BDD, new code paths, or test-runner failures).

### `Target: refactor-plan`

**Any action:**
- `pattern-approved.md` at `.project/cycles/<slug>/refactor-proposals/pattern-approved.md`. **Sole source of work-item content.**
- Reference inputs only: `.project/knowledge/architecture.md`, `overview.md`, `sitemap.md`, and any `.project/knowledge/<type>/_index.md` needed to ground file paths.

**Mode: create:** `approved.md` exists.
**Mode: update:** the refactor `implementation-plan.md` exists; the trigger is an amended `approved.md` or test-runner failures.

### `Target: bugfix-reproduction`

**Any action:**
- `Bug Report:` — `<Cycle Path>/specs/bug-report.md` (required). Supplies the `## Objective` and per-symptom `## Expected Behavior`.
- `Investigation Files:` — zero or more paths under `<Cycle Path>/execution/code-investigations/` (absent on the reproduce-first path).
- `Affected Test Files Hint:` — optional; the bug report's `## Affected Area`.
- `.project/knowledge/architecture.md`, `overview.md`, `sitemap.md` (reference).
- `.claude/agents/developer/essentials/test/knowledge-map.md`.

No SRS/SDD/BDD/charter — a reproduction test exercises existing behavior with the existing test stack.

**Mode: create:** `reproduction-plan.md` does not exist.
**Mode: update:** `reproduction-plan.md` exists; the trigger is a refined investigation or audit finding.

### `Target: bugfix-draft`

**Any action:**
- `Bug Report:` (required) — supplies the `## Objective`.
- `Investigation Files:` — one or more paths (required). Sole content-source for the fix.
- `.project/knowledge/architecture.md`, `overview.md`, `sitemap.md`.
- `.project/knowledge/tech-stack/charter.md` — approved-technology allowlist, read from the main root (main-canonical).
- `.claude/agents/developer/essentials/<dev-type>/knowledge-map.md` per dev-type the fix touches.

No SRS/SDD/BDD.

**Mode: create:** `implementation-plan-draft.md` does not exist.
**Mode: update:** the draft exists; the trigger is a deeper re-investigation or audit finding.

### `Target: bugfix-final`

**Any action:**
- `Plan Draft Path:` — `.project/cycles/<slug>/plans/implementation-plan-draft.md` (required, preserved).
- `Investigation Files:` — the same set passed to the draft (required).
- `Bug Report:` (required).
- `.project/knowledge/tech-stack/charter.md` — read from the main root (main-canonical).
- Every `.project/knowledge/<type>/_index.md`; convention bodies on token-overlap match.
- `.claude/agents/developer/essentials/<dev-type>/knowledge-map.md` per dev-type touched.

No SRS/SDD/BDD. Does NOT run `find-call-sites.ts` or evaluate ABSTRACT viability — restricted to within-cycle REUSE/EXTRACT analysis.

**Mode: create:** the draft must exist; the final must not.
**Mode: update:** both draft AND final must exist.

### `Target: deviation`  (update-only)

**Mode: update:** the existing plan at `Plan Path` (an `implementation-plan.md` or `phase-<N>-test-plan.md`) + the `## Deviation Report` section of the supplied `Developer Report`. Acts on NOTIFY rows only.
**Mode: create:** rejected — `CREATE_UNSUPPORTED_FOR_DEVIATION`.

## Per-Target Outputs

| Target | Output Path | Mode: create | Mode: update |
|---|---|---|---|
| `feature-draft` | `.project/cycles/<cycle>/plans/implementation-plan-draft.md` | Authored from scratch | Rewritten to reflect revised spec |
| `feature-final` | `.project/cycles/<cycle>/plans/implementation-plan.md` | Copy of draft mutated with REUSE/EXTRACT directives | Directive analysis re-run; additive/substitutive diff |
| `test-plan` | `.project/cycles/<cycle>/plans/test-plans/phase-<N>-test-plan.md` | Authored from BDD + implemented code | Revised with phase/task amendments |
| `refactor-plan` | `.project/cycles/<DD-MM-YYYY>-refactor-from-<parent>/plans/implementation-plan.md` or `.project/cycles/<DD-MM-YYYY>-primitives/plans/implementation-plan.md` | Single-pass authoring from `approved.md` | Revised against amended `approved.md` |
| `bugfix-reproduction` | `.project/cycles/<slug>/plans/reproduction-plan.md` | Single-pass authoring from the bug report (+ investigations) | Revised against a refined investigation |
| `bugfix-draft` | `.project/cycles/<slug>/plans/implementation-plan-draft.md` | Authored from investigation(s) + bug report | Rewritten to reflect a deeper investigation |
| `bugfix-final` | `.project/cycles/<slug>/plans/implementation-plan.md` | Copy of draft mutated with REUSE/EXTRACT directives | Directive analysis re-run; additive diff |
| `deviation` | the plan at `Plan Path`, patched in place | — (rejected) | Phases after the completed phase reconciled; routing response returned |

## `Target: deviation` Return

`Mode: update` + `Target: deviation` patches the plan at `Plan Path` — additive/substitutive edits to phases after the completed phase only (one exception: a skipped load-bearing task is restored in the completed phase, which sets `RETRY_PHASE`). Returns a routing response the orchestrator parses:

| Field | Values |
|---|---|
| `Status` | `SUCCESS` \| `ERROR` |
| `Mode` | always `update` |
| `Target` | always `deviation` |
| `Routing` | `PROCEED_NEXT` \| `RETRY_PHASE` |
| `Trigger` | always `DEVIATION` |
| `Change-Level` | `NONE` \| `PATCH` \| `STRUCTURAL` |
| `Target-Phase` | integer — completed phase for `RETRY_PHASE`; next unstarted phase for `PROCEED_NEXT` |
| `Phases-Updated` | list of phase numbers, or `none` |
| `Changelog` | path to the appended `plan-changelog.md` (or test-plan changelog) |
| `Changes` | 1–2 sentence summary, or "No stale references found" |

Every invocation appends a `Trigger: DEVIATION` changelog entry, including `NONE` changes, so the reconciliation is auditable.

## Plan Structure (all targets)

- Verb-noun task headers drawn from the agent's closed verb list. When an unlisted verb is unavoidable, the task carries a `Vocabulary-extension: <path>` field pointing to a request file at `.claude/docs/vocabulary-extensions/<date>-<verb>.md`.
- Per-task metadata block: `Target file(s)`, `Acceptance`, `Concern`, `Effort`. `Concern` is one of: `validation`, `persistence`, `transformation`, `rendering`, `side-effect`, `authorization`, `infrastructure`, `test`, `convention-doc`. `Effort` is one of `S`, `M`, `L` — the task's complexity tier (highest of its file-count, logic, and acceptance-assertion axes), governing the phase effort budget.
- Phase header carries `Developer: backend | frontend | infrastructure | test`.
- Phase sizing: effort-budget based — ≤8 effort points per phase (`S`=1, `M`=2, `L`=3), ≤6 tasks per phase, ≤15 files per phase (touched + new combined). Mandatory boundaries on budget overflow (split even within one Developer Type/subarea), Developer Type change, target subarea change, and commit-dependency boundary.
- Plan header: every plan carries a `## Objective` section (1–2 sentences); test plans additionally carry a `## Meta` section with a `BDD Specs: <path>` line below the Objective. A `## Open Questions` section appears on any target when unresolved questions remain. No plan carries a Quick Reference section; only test plans carry a `## Meta` section.

## Plan Output Guarantees

- Plans carry **no per-task `targets` field**. Read-protocol routing lives in the developer's knowledge map.
- `feature-final` and `bugfix-final` emit directive annotations for **REUSE** and **EXTRACT** only — never ABSTRACT. ABSTRACT-deferred candidates are recorded as `<!-- ABSTRACT-deferred: ... -->` comments.
- `refactor-plan` is the sole emitter of `ABSTRACT directive applied...` annotations and `abstract-migration-phase` phase flags. The annotation cites the approved finding ID; full gate evaluations live in the cited finding, not in the annotation.
- Test plans set `Developer: test` on every phase; every task carries a `Scenario:` field referencing at least one BDD scenario.
- Reproduction plans (`bugfix-reproduction`) set `Concern: test` on every task; every task carries a `Bug-Expectation:` field holding the bug report's `## Expected Behavior` verbatim (the per-task analogue of `Scenario:`). Plan-auditor's `bugfix-reproduction-rules.md` enforces this.
- Refactor plans tagged `convention-doc` tasks dispatch `state-manager` (`refactor-curation` mode) per-phase.
- The Objective is present on every plan, every target; plan-auditor rejects its absence (`MISSING_OBJECTIVE`).

## Errors

| Error | Triggered by | Where |
|---|---|---|
| `MISSING_SPECS: <files>` | SRS/BDD/SDD absent | `feature-draft` Mode: create |
| `MISSING_DRAFT: <cycle>` | draft absent | `feature-draft` Mode: update |
| `MISSING_DRAFT_PLAN: <feature/slug>` | draft absent | `feature-final` Mode: create/update; `bugfix-final` |
| `MISSING_FINAL_PLAN: <feature/slug>` | final absent | `feature-final` Mode: update; `bugfix-final` Mode: update |
| `WORKTREE_ACTIVE: <cycle>` | active worktree blocks design-time edit on main | `feature-draft`/`feature-final` (main-side) |
| `TECH_NOT_IN_CHARTER: <need>` | off-charter technology forced — SDD/requirements (`feature-draft`), the prescribed fix (`bugfix-draft`), or a REUSE/EXTRACT directive (`feature-final`/`bugfix-final`) | `feature-draft`/`feature-final`/`bugfix-draft`/`bugfix-final` |
| `ABSTRACT_IN_FEATURE_FINAL` | internal guard fired — `feature-final` mechanic emitted an ABSTRACT artefact | `feature-final` |
| `MISSING_PHASE_NUMBER` | dispatch omitted `Implementation Phase: <N>` | `test-plan` |
| `MISSING_DEVELOPER_REPORT: phase-<N>` | phase developer report absent | `test-plan` |
| `MISSING_BDD: <cycle>` | BDD context or feature files absent | `test-plan` |
| `MISSING_SRS: <cycle>` | SRS absent | `test-plan` |
| `MISSING_TEST_PLAN: phase-<N>` | per-phase test plan absent | `test-plan` Mode: update |
| `ABSTRACT_FINDING_INCOMPLETE: <finding-id>: missing <fields>` | required ABSTRACT field absent in approved finding | `refactor-plan` |
| `ABSTRACT_FINDING_NOT_APPROVED: <finding-id>` | approved finding has non-APPROVE verdict | `refactor-plan` |
| `MISSING_APPROVED: <slug>` | `pattern-approved.md` absent | `refactor-plan` Mode: create |
| `MISSING_REFACTOR_PLAN: <slug>` | refactor `implementation-plan.md` absent | `refactor-plan` Mode: update |
| `MISSING_BUG_REPORT: <path>` | `bug-report.md` absent | `bugfix-reproduction`/`bugfix-draft` |
| `MISSING_INVESTIGATION: <path>` | investigation file(s) absent | `bugfix-draft`/`bugfix-final` |
| `ABSTRACT_IN_BUGFIX_FINAL` | internal guard fired — `bugfix-final` mechanic emitted an ABSTRACT artefact | `bugfix-final` |
| `CREATE_UNSUPPORTED_FOR_DEVIATION` | `Mode: create` dispatched against the deviation target | `deviation` |
| `MISSING_PLAN: <path>` | plan file absent at `Plan Path` | `deviation` |
| `MISSING_DEVIATION_REPORT: <path>` | developer report lacks a `## Deviation Report` section | `deviation` |

Errors return the code without writing any file. The orchestrator routes the error to the responsible upstream (spec-architect, design-architect, pattern-analyst, pattern-analyst-auditor) for revision. The exception is `TECH_NOT_IN_CHARTER`: the orchestrator surfaces it to the user for resolution via `/tech-stack-architect unblock` rather than routing to an upstream agent.

## Pipeline Role

- **Design-time writer + committer** for `feature-draft` and `feature-final`. On main, checks for `<main-root>/.worktrees/<cycle>/` first (`WORKTREE_ACTIVE` if present — gates main-side edits only, not the worktree-side commit path).
- **Worktree-side writer + committer** for `test-plan`, `refactor-plan`, the three bugfix targets (`bugfix-reproduction`, `bugfix-draft`, `bugfix-final` — authored inside the bugfix worktree), and any in-worktree update. Never writes `ROADMAP.md` or `.project/product/cycles-in-progress/*`.
- **Commits every plan artifact it writes** — draft, implementation plan, refactor plan, per-phase test plan, reproduction plan, bug-fix plan, and deviation reconciliations — via the `commit-to-git` skill with `Agent: plan-architect`, in both main-side and worktree-side contexts. The skill owns the commit form; subjects are `plan(<slug>): …`.

## Guarantees

- The base `create` precondition is "target artifact does not exist"; the base `update` precondition is "target artifact exists". Targets layer additional preconditions.
- The `update` action is additive or substitutive — never destructive — unless the target's update mechanic explicitly defines deletion.
- `implementation-plan-draft.md` is preserved untouched by every `feature-final` pass.
- Plan structure is enforced downstream by `plan-auditor`. Plan-architect emits content; the auditor validates it.
- The agent does not prompt the user. The dispatch contract is the sole input surface.
