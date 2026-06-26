# Developer Guide

## What It Does

The Developer agent implements a single plan phase with persona-specific knowledge. It receives one phase from the orchestrator, writes code following the plan's instructions, verifies its work, and reports completion (or pauses with explicit remaining work) via a persistent report file plus a structured return message.

**Model:** Claude Opus.

**Input:** A single implementation or test phase (tasks, code references, context, and artifacts from prior phases) provided by the orchestrator, plus a Developer Type (`backend`, `frontend`, `infrastructure`, or `test`).

**Output:** Implemented code files + a per-phase report with an artifacts table, shared-utilities section, implementation reasoning (source-attributed decisions and assumptions), and deviations log. All artifacts (code, report, archived prior runs) are committed in the worktree before return. Returns one of three statuses: `COMPLETED`, `PARTIAL`, or `BLOCKED`, plus a `Commit:` field carrying the final commit hash.

## When It Runs

Spawned by the orchestrator for each implementation phase, after plan-auditor validates the plan. Each phase gets a fresh developer instance with curated context.

```
spec-architect -> design-architect -> plan-architect -> plan-auditor -> orchestrator -> [developer] -> code-reviewer -> test-runner
```

## Developer Types

The developer is a single subagent dispatched with a `Developer Type:` field. Each type loads a different persona file, persona dev-rules, and knowledge map.

| Type | When Used | Knowledge |
|---|---|---|
| **backend** | Services, controllers, repositories | Architecture rules, error handling pattern, security patterns, data isolation |
| **frontend** | Components, pages, state | Framework syntax, component conventions, styling system, route organization |
| **infrastructure** | Database schemas, containerization, migrations | Schema conventions, mapper pattern, services config, environment setup |
| **test** | Test files for implemented code | Testing framework, mocking patterns, AAA pattern, BDD scenario mapping |

**Type selection.** `plan-architect` assigns a Developer Type per phase at plan creation time. The orchestrator reads this field and passes it as the `Developer Type:` dispatch input.

## Read Protocol

Every dispatch loads:

1. Universal dev-rules — `essentials/dev-rules.md`.
2. Per-type persona files — `types/<dev-type>/<dev-type>-dev.md` and `types/<dev-type>/dev-rules.md`.
3. Per-type knowledge map — `essentials/<dev-type>/knowledge-map.md` (routes stack-specific triggers to user-level skills under `.claude/skills/developer-skills/<dev-type>/`).
4. Universal project context — `.project/knowledge/architecture.md`, `overview.md`, `sitemap.md`.
5. Per-type project context — `.project/knowledge/<dev-type>/_index.md` (always) plus `<slug>/_index.md` (if the task targets a feature-slug subdirectory).
6. Handoff file (if `Handoff Path:` provided).
7. Residual artifact (if `Residual Artifact:` provided — PARTIAL continuation only).

**`test` Developer Type is multi-dimensional.** Test tasks span multiple dev-types (e.g., an integration test exercises both backend and frontend code). The developer derives each task's covered dev-types from the task's `Target file(s)` paths and reads only the corresponding `.project/knowledge/<derived-type>/_index.md` files — never pre-emptively all four.

## Return Statuses

The developer returns one of three statuses:

| Status | Meaning | Status-specific fields |
|---|---|---|
| `COMPLETED` | Implementation complete, verification passed | `has-notify-deviations` |
| `PARTIAL` | Some tasks done; remaining work captured in a residual artifact; another developer instance can resume | `residual-artifact`, `reason` |
| `BLOCKED` | Cannot proceed without external action | `blocking-cause` |

**Always present:** a `Commit:` field carrying the hash of the developer's final commit (typically the Step 9 report commit), `none` if no commits were produced this invocation, `skipped` if the would-be commit was a no-op (content byte-identical to HEAD), or `failed` if a commit was attempted but `commit-to-git` returned an error. The orchestrator treats a `failed` value or an absent field as a re-dispatch signal for interrupted-commit recovery.

### PARTIAL Reasons

| Reason | When |
|---|---|
| `turn-limit-approached` | Ran out of turns before finishing all tasks |
| `scope-larger-than-estimated` | Tasks proved larger than the plan estimated |
| `partial-build-failure` | Verification failed after 2 fix attempts on first invocation (retry warranted) |
| `transient-environment-issue` | Flaky environment state likely to resolve on retry |

### BLOCKED Causes

| Cause | When | Orchestrator routing |
|---|---|---|
| `handoff-insufficient` | Plan is fine but handoff lacks prior-phase artifacts | `state-manager rebuild` → re-dispatch developer |
| `spec-ambiguous` | Plan/spec is wrong (broken references, ambiguity, contradictions) | `plan-architect update` on user approval |
| `dependency-missing` | Environment lacks a required package, credential, or service | Surface to user |
| `environment-broken` | Environment is in a broken state (build broken structurally, service unreachable); includes second-fail on PARTIAL continuation | Surface to user |

## 4-Tier Deviation System

Not every unexpected situation requires escalation. The developer applies a tiered response:

| Tier | Situation | Response |
|---|---|---|
| **1** | Bug found in-scope while implementing | Auto-fix, log as SILENT (or NOTIFY if signature changed) |
| **2** | Plan assumes a small helper that doesn't exist | Auto-create if ALL 7 constraints pass, log as NOTIFY |
| **3** | Blocker resolvable via permitted command | Run command from allowlist, log as SILENT or NOTIFY |
| **4** | Architectural change or external constraint required | Escalate as BLOCKED with the matching `blocking-cause` (dependency-missing / environment-broken / spec-ambiguous / handoff-insufficient) |

**Tiers 1–3** are auto-resolved. Every auto-resolution is logged in the COMPLETED report's Deviations table. If any deviation is classified as NOTIFY (externally visible change), the orchestrator forwards a Deviation Report to plan-architect, which scans remaining phases for stale references.

**Tier 4** produces a BLOCKED status — see the BLOCKED Causes table for the routing.

## PARTIAL vs BLOCKED — The Difference

`PARTIAL` says: "I made progress, more work remains, another developer instance can pick up the residual artifact and continue."

`BLOCKED` says: "I cannot proceed regardless of how many times I am invoked again; the resolution requires action outside my scope."

The discriminator on a verification failure: first-invocation 2-attempt fail → `PARTIAL partial-build-failure`; continuation 2-attempt fail → `BLOCKED environment-broken` (the `Residual Artifact:` input is the signal of continuation status).

## ABSTRACT Migration Phases

Phases authored by `plan-architect` from approved `pattern-analyst` findings carry an `abstract-migration-phase` flag on the phase header and an inline annotation citing the approved finding. The developer follows the T1–T5 task spine:

| Task | What |
|---|---|
| **T1** | Rewrite the signature per the finding's `generalized-signature` |
| **T2** | Author a `ts-morph`/`jscodeshift` codemod + tests (reads call-site data from the cited finding — never re-runs `find-call-sites.ts`) |
| **T3** | Run the codemod against the codebase, record diff |
| **T4** | Run build; capture remaining failures as `<date>-codemod-stragglers-<cycle>.md` (this build is diagnostic, not the Step 8 savepoint verification) |
| **T5** | Manual cleanup of stragglers (only if T4 captured failures); update the stragglers residual artifact every 5 files |

For a one-phase recommendation (codemod coverage ≥80%), T1–T5 are all in the same phase. For a two-phase recommendation (50% ≤ coverage < 80%), T1–T4 are in phase A and T5 in phase B.

## Resume vs PARTIAL Continuation

Two distinct mechanisms for re-invocation:

| Mechanism | Trigger input | When to use |
|---|---|---|
| **Resume** | `Resume: true` | Crash recovery after a previous developer invocation died (process killed, environment lost). Developer checks filesystem for substantive artifacts and skips completed tasks. |
| **PARTIAL continuation** | `Residual Artifact: <path>` | Normal handoff between developer instances after a PARTIAL return. Developer reads the residual artifact as the authoritative source for remaining work. |

These are mutually exclusive in practice — Resume operates on filesystem state, PARTIAL continuation operates on an explicit residual artifact.

## Implementation Reasoning (Root Cause Attribution)

Every developer report includes an Implementation Reasoning section with three parts:

1. **Phase Interpretation** — What the developer understood the phase needed to accomplish. Catches misinterpretation early.
2. **Key Decisions** — Non-obvious implementation choices, each tagged with the knowledge source that guided it.
3. **Assumptions** — Things inferred but not explicitly stated, tagged with which source was expected to provide the information.

Source labels:

| Label | Maps to | When to update |
|---|---|---|
| `plan` | Plan task instructions | Plan-architect produced ambiguous/misleading instructions |
| `handoff` | Handoff file | State-manager missed critical context from prior phases |
| `persona` | `types/{persona}/*.md` | Persona knowledge file missed a convention or pattern |
| `knowledge-map` | `essentials/<dev-type>/knowledge-map.md` and the routed skill | Knowledge-map row outdated or user-level skill missing |
| `context-index` | `.project/knowledge/<type>/_index.md` (and routed convention body) | The convention file or its `_index.md` trigger row |
| `base rules` | `essentials/dev-rules.md` | Universal rules need a new constraint or clarification |
| `project rules` | Project CLAUDE.md / CONTEXT.md | Project docs are incomplete or misleading |
| `codebase` | Pattern found via search | N/A — correct behavior |
| `codebase (not found)` | Searched but missed existing code | Search protocol too narrow, or naming discoverability |
| `code-review` | Code review file (fix invocation) | Code-reviewer rule or developer fix application |
| `investigation` | Investigation file (fix invocation) | Code-investigator analysis depth or fix prescription |
| `approved-finding` | Cited approved `pattern-analyst` finding (ABSTRACT migration only) | Finding fields or pattern-analyst-auditor |

**How to use for continuous improvement:** When code-reviewer or code-investigator finds an error, read the developer's Implementation Reasoning to trace which source guided the bad decision. Then update that source file to prevent the same class of error in future phases.

## Shared Utilities Section

Every developer report includes a `## Shared utilities` section with two subsections:

- **Reused** — utilities imported from existing shared locations, by file path
- **Created** — new shared utilities introduced by this phase, by file path and signature

This feeds quality-analyst's reuse-trend detection and knowledge-curator's drift checks.

## Bash Command Allowlist

The developer can only run commands from a strict allowlist. The canonical list lives in `essentials/dev-rules.md` § Permitted Resolution Commands.

**Never permitted:** the test suite (test-runner's domain), `npm install`/`uninstall`, `docker` commands, `git push`, `git reset` outside the Step 2 reset window, and `find-call-sites.ts` (pattern-analyst's domain).

**Permitted git write commands:** `git add`, `git commit` (fresh commits go through the `commit-to-git` skill with `Agent: developer`; subjects are `wip:` for savepoint/partial commits, `report:` for the Step 9 report commit, and `chore:` for Step 2 restore/clear commits), `git commit --amend --no-edit` (folds a fix into the savepoint; reuses the message, so no trailer is re-added), `git checkout -- .`, `git clean -fd`, `git rev-parse HEAD`, and — only in Step 2's `Reset To Commit` window — `git reset --hard <hash>` and `git checkout <hash> -- <path>`. Used inside the Step 8 savepoint pattern, the partial-commit-before-PARTIAL/BLOCKED rule, the Step 9 report commit, and the Step 2 reset/cleanup block.

## Verification Failure Loop

When lint/build fails after implementation:

1. Developer attempts up to 2 self-fix attempts using the savepoint revert pattern.
2. If both attempts fail and this is the **first invocation** for this phase (no `Residual Artifact:` in input): revert to savepoint and return `PARTIAL` with `reason: partial-build-failure`. The orchestrator dispatches a focused continuation.
3. If both attempts fail and this is a **continuation invocation** (`Residual Artifact:` was in input): revert to savepoint and return `BLOCKED` with `blocking-cause: environment-broken` and the ORIGINAL error output. The orchestrator surfaces to the user.

## Ambiguity Loop

When the developer encounters an unclear or broken plan instruction:

1. Developer returns `BLOCKED` with `blocking-cause: spec-ambiguous` and a Problem Report.
2. Orchestrator routes the Problem Report to plan-architect (`Mode: update`).
3. Plan-architect fixes the specific phase.
4. Plan-auditor validates the updated phase (`Mode: phase-audit`).
5. If VALID: orchestrator re-spawns developer with the updated phase + `Plan Revised: true`.
6. If INVALID: plan-auditor's report routes back to plan-architect.

**Retry limit:** 2 rebuilds per phase via state-manager `rebuild` mode for `handoff-insufficient`; for `spec-ambiguous` the orchestrator surfaces to the user.

## Tips for Best Results

1. **Plan quality matters** — Well-written plans with accurate code references lead to smoother implementation
2. **Persona files are project-aware** — Each persona file instructs the developer what to look for in the project's CLAUDE.md
3. **Search-before-code** — The developer searches for existing utilities before creating new ones, reducing duplication
4. **Artifacts tracking** — Every phase produces an artifacts table, enabling context-efficient handoffs
5. **Shared utilities tracking** — Reused/Created sections feed cross-feature pattern analysis
6. **Deviation transparency** — The developer logs every auto-fix in the Deviations table, enabling plan-architect to keep remaining phases accurate
7. **Resume vs Residual Artifact** — Use `Resume: true` for crash recovery; use `Residual Artifact:` for PARTIAL continuation

## Related Documentation

- Agent definition: `.claude/agents/developer/developer.md`
- Interface contract: `.claude/agents/interface-contracts/developer.contract.md`
- Universal rules: `.claude/agents/developer/essentials/dev-rules.md`
- Backend persona: `.claude/agents/developer/types/backend/backend-dev.md`
- Frontend persona: `.claude/agents/developer/types/frontend/frontend-dev.md`
- Infrastructure persona: `.claude/agents/developer/types/infrastructure/infrastructure-dev.md`
- Test persona: `.claude/agents/developer/types/test/test-dev.md`
- Backend knowledge map: `.claude/agents/developer/essentials/backend/knowledge-map.md`
- Frontend knowledge map: `.claude/agents/developer/essentials/frontend/knowledge-map.md`
- Infrastructure knowledge map: `.claude/agents/developer/essentials/infrastructure/knowledge-map.md`
- Test knowledge map: `.claude/agents/developer/essentials/test/knowledge-map.md`
- Pattern-analyst (ABSTRACT finding owner): `.claude/agents/pattern-analyst/pattern-analyst.md`
