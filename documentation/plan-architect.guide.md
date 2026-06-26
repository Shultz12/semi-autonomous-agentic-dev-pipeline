# Plan Architect Guide

## What It Does

The Plan Architect authors plan files for the pipeline. It transforms upstream artifacts — specifications, approved refactor findings, and implemented code paths — into phase-structured plans optimized for stateless developer instances.

It is the sole owner of:

- `implementation-plan-draft.md` (feature draft, derived from specs)
- `implementation-plan.md` (final feature plan, with REUSE/EXTRACT directives)
- `phase-<N>-test-plan.md` (per-phase test plan)
- Refactor `implementation-plan.md` (scout-and-refactor or primitives cycle)

**Model:** Claude Sonnet (`claude-sonnet-4-6`)

**Tools:** Read, Glob, Grep, Write, Bash

## Dispatch Contract

Plan-architect does not prompt the user — every invocation is fully specified by the dispatch.

| Field | Values | Required |
|---|---|---|
| `Mode` | `create` \| `update` | Yes |
| `Target` | `feature-draft` \| `feature-final` \| `test-plan` \| `refactor-plan` \| `deviation` | Yes |
| `Implementation Phase` | integer ≥ 1 | Required when `Target: test-plan`; ignored otherwise |

`create` and `update` are both valid for the four plan-authoring targets. The `deviation` target is **update-only** — `Mode: create` against it is rejected. When `Target: deviation`, the dispatch carries `Plan Path`, `Completed Phase`, and `Developer Report` in place of the feature-derived inputs (see the `deviation` target below).

At dispatch, plan-architect loads all four `essentials/*.md` files, the action file for the dispatched mode, and the target file for the dispatched target.

## Targets

### `feature-draft`

Authors `implementation-plan-draft.md` from SRS + BDD + SDD plus project context (`architecture.md`, `overview.md`, `sitemap.md`) and the relevant developer-type knowledge maps. The draft is preserved untouched by every subsequent pass and serves as the auditor's diff baseline against the final plan.

- **Mode: create** — build the draft from scratch.
- **Mode: update** — rewrite the draft against revised SRS/BDD/SDD; the trigger is a spec deviation or design revision.

### `feature-final`

Mutates a copy of the draft by adding REUSE and EXTRACT directives. ABSTRACT directives are never emitted here — feature-final is restricted to within-feature reuse analysis only. ABSTRACT candidates that surface during analysis are recorded as `<!-- ABSTRACT-deferred: ... -->` comments and picked up by the post-merge `pattern-analyst convergence-scout` cycle.

- **Mode: create** — copy draft to final, then mutate with directives. Requires `implementation-plan-draft.md` to exist (else `MISSING_DRAFT_PLAN`).
- **Mode: update** — re-run directive analysis. Requires both draft AND final to exist.

### `test-plan`

Authors `phase-<N>-test-plan.md` per implementation phase. Invoked by the orchestrator after the phase's code-review returns PASS and before test-writing begins. Inputs are BDD scenarios, SRS, implemented code paths from the phase's developer report, and (when present) code-reviewer findings flagging coverage gaps.

Every phase carries `Developer: test`. Every task references at least one BDD scenario via a `Scenario:` field; plan-auditor enforces the trace.

- **Mode: create** — author from BDD + implemented code + code-reviewer findings.
- **Mode: update** — revise against new code paths, revised BDD, or test-runner failures.

### `refactor-plan`

Authors the refactor `implementation-plan.md` for scout-and-refactor and primitives flows. The sole source of work-item content is `.project/cycles/<slug>/refactor-proposals/pattern-approved.md` — every directive (REUSE, EXTRACT, ABSTRACT, REMOVE, RELOCATE) is read from there.

ABSTRACT findings carry a structured payload (source file, generalized signature, hard-gates, scoring-axes, call-site data, stragglers, phase-splitting recommendation). Plan-architect validates the payload as a hard-gate precondition — missing fields fail the dispatch (`ABSTRACT_FINDING_INCOMPLETE`); non-APPROVE verdicts fail (`ABSTRACT_FINDING_NOT_APPROVED`). ABSTRACT migration phases are generated from the validated payload with an inline annotation citing the finding ID; full gate evaluations remain in the approved finding, not in the plan.

When a refactor introduces or modifies a shared utility, the plan declares the corresponding convention-doc update as a separate phase task with `Concern: convention-doc`. The orchestrator routes these tasks to `state-manager` (`refactor-curation` mode) per-phase.

- **Mode: create** — single-pass authoring from `approved.md`.
- **Mode: update** — revise against amended `approved.md` or test-runner failures.

### `deviation`

A reconciliation pass, not authoring — and the one update-only target. The orchestrator dispatches `Mode: update` + `Target: deviation` after a phase completes with NOTIFY-level deviations (the developer changed course in a way worth recording). It applies uniformly to both an `implementation-plan.md` and a per-phase `phase-<N>-test-plan.md`, which is why it carries a `Plan Path` rather than deriving the artifact from the feature. `Mode: create` against this target is rejected (`CREATE_UNSUPPORTED_FOR_DEVIATION`).

The plan is not broken — it may simply hold stale references to code whose name, signature, or location the developer changed. The pass is lightweight: it scans only the phases **after** the completed phase, acts on NOTIFY rows only (SILENT deviations are filtered out upstream), and makes additive or substitutive edits — never destructive, never renumbering. The one exception is a load-bearing task the deviation skipped: that task is restored in the completed phase and the pass returns `RETRY_PHASE` so the orchestrator re-dispatches the developer for it.

Every invocation appends a `Trigger: DEVIATION` entry to the feature's `plan-changelog.md` (or the test-plan changelog), including no-change passes, so the reconciliation is auditable. The return is a routing response the orchestrator parses:

| Field | Values |
|---|---|
| `Routing` | `PROCEED_NEXT` (remaining phases aligned) \| `RETRY_PHASE` (completed phase left a gap) |
| `Change-Level` | `NONE` \| `PATCH` \| `STRUCTURAL` |
| `Target-Phase` | completed phase for `RETRY_PHASE`; next unstarted phase for `PROCEED_NEXT` |
| `Changelog` | path to the appended changelog |

- **Mode: update** — reconcile the phases after the completed phase against the deviation report.
- **Mode: create** — rejected; there is no plan to author.

## Writing Discipline

Every plan honors five rules. Plan-auditor enforces them.

1. **Verb-noun task headers** drawn from a closed verb list. Unlisted verbs require a vocabulary-extension request file at `.claude/docs/vocabulary-extensions/<date>-<verb>.md`, referenced from the task.
2. **One concern per task.** Each task declares one of nine concerns: `validation`, `persistence`, `transformation`, `rendering`, `side-effect`, `authorization`, `infrastructure`, `test`, `convention-doc`. Multi-responsibility tasks are split.
3. **Domain-noun discipline.** Tasks use named domain entities (`Tabu PDF block`, `organization`, `Hebrew date`), not generic terms (`input`, `data`, `payload`).
4. **Per-task metadata block.** Every task carries `Target file(s)`, `Acceptance` (testable predicate), and `Concern` fields.
5. **Plan header.** Feature and refactor plans open with `## Objective` (1–2 sentences) and, when unresolved questions remain, `## Open Questions` (checkbox items). Test plans open with `## Meta` containing a `BDD Specs: <path>` line. No plan carries a `## Quick Reference` section.

## Phase Sizing

Hard caps: ≤10 tasks per phase, ≤15 files per phase (touched + new combined). Mandatory phase boundaries on Developer Type change (`backend` / `frontend` / `infrastructure` / `test`), target-subarea change, and commit-dependency boundary. Soft target: 3–7 tasks per phase when tasks span multiple files or entities.

Every phase header carries `Developer: backend | frontend | infrastructure | test`. The orchestrator uses this to select the developer persona for the phase.

## Pipeline Role

Plan-architect is multi-role depending on which target is dispatched:

- **Design-time writer + committer** for `feature-draft` and `feature-final`. On main it checks for `<main-root>/.worktrees/<cycle-slug>/` before editing — an active worktree blocks the edit (`WORKTREE_ACTIVE`) because the worktree was cut against a specific base and silently changing it would invalidate the running plan; the guard gates main-side edits only.
- **Worktree-side writer + committer** for `test-plan`, `refactor-plan`, and any in-worktree update. Never writes `ROADMAP.md` or `.project/product/cycles-in-progress/*`; ROADMAP transitions are delegated to `progress-tracker`. If a three-way merge ever conflicts on those paths, take main unconditionally — a worktree-side change there is a bug to investigate, not text to merge.
- **Commits every plan artifact it writes**, in both contexts, via the `commit-to-git` skill with `Agent: plan-architect` (subjects `plan(<slug>): …`). The skill owns the path-scoped form and attribution trailer.

## Errors

Plan-architect returns structured error codes without writing any file when preconditions fail. The orchestrator routes the error to the responsible upstream agent for revision. Common codes:

- `MISSING_SPECS: <files>` — `feature-draft` Mode: create requires SRS + BDD + SDD.
- `MISSING_DRAFT_PLAN: <cycle>` — `feature-final` requires the draft to exist.
- `MISSING_FINAL_PLAN: <cycle>` — `feature-final` Mode: update requires the final to exist.
- `WORKTREE_ACTIVE: <cycle>` — design-time edit blocked by active worktree.
- `MISSING_PHASE_NUMBER` — `test-plan` dispatch omitted `Implementation Phase: <N>`.
- `MISSING_BDD: <cycle>` / `MISSING_SRS: <cycle>` / `MISSING_DEVELOPER_REPORT: phase-<N>` — `test-plan` input gaps.
- `MISSING_APPROVED: <slug>` — `refactor-plan` requires `pattern-approved.md`.
- `ABSTRACT_FINDING_INCOMPLETE: <finding-id>: missing <fields>` — approved ABSTRACT finding lacks required payload fields.
- `ABSTRACT_FINDING_NOT_APPROVED: <finding-id>` — approved finding has non-APPROVE verdict.
- `CREATE_UNSUPPORTED_FOR_DEVIATION` — `Mode: create` dispatched against the `deviation` target.
- `MISSING_PLAN: <path>` — the `deviation` target found no plan file at `Plan Path`.
- `MISSING_DEVIATION_REPORT: <path>` — the `deviation` target's developer report lacks a `## Deviation Report` section.

## Related Documentation

- Agent definition: `.claude/agents/plan-architect/plan-architect.md`
- Interface contract: `.claude/agents/interface-contracts/plan-architect.contract.md`
- Essentials (loaded on every dispatch): `.claude/agents/plan-architect/essentials/{allowed-verbs,writing-discipline,phase-sizing,vocabulary-extension}.md`
- Action discipline: `.claude/agents/plan-architect/modes/actions/{create,update}.md`
- Target mechanics: `.claude/agents/plan-architect/modes/targets/{feature-draft,feature-final,test-plan,refactor-plan,deviation}.md`
- Plan-auditor (validates plan-architect output): `.claude/documentation/plan-auditor.guide.md`
- Pattern-analyst (sole owner of ABSTRACT decisions, supplier of approved findings): `.claude/documentation/pattern-analyst.guide.md`
