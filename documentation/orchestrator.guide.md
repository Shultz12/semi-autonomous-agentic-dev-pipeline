# Orchestrator Guide

## What It Does

Coordinates pipeline execution across three flow types:

- **Standard feature** — implement a planned feature phase-by-phase from a validated `implementation-plan.md`.
- **Scout-and-refactor** — after a feature lands, run a refactor cycle that scans for refactor opportunities (`pattern-analyst` divergence + convergence scouts → `pattern-analyst-auditor` → `pattern-analyst` curate) during its pre-curate stage and, if proposals are approved, executes a refactor plan during its post-curate stage. Every artifact (worktree, branch, ROADMAP entry, feature directory) uses the unified refactor slug `<DD-MM-YYYY>-refactor-from-<parent-name>` for the entire cycle.
- **Primitives** — scan the codebase for sharable primitive utilities (`pattern-analyst` primitives-scout → auditor → curate) and, if approved, execute a refactor plan.

Reads `.project/product/ROADMAP.md` to determine the next work item and the appropriate flow. Spawns an isolated worktree per cycle (`.worktrees/<slug>/`) on a slug-named branch from `origin/main`. Dispatches developer, code-reviewer, plan-architect, plan-auditor, test-runner, code-investigator, state-manager, progress-tracker, pattern-analyst, and pattern-analyst-auditor. Pauses for your confirmation after every completed phase.

**Execution-only.** The orchestrator does not author specs or design documents, never reads source code or agent report contents, and never writes `ROADMAP.md` or per-feature tracking files directly — all such writes are delegated to `progress-tracker`. Merge, post-merge verification, branch deletion, and worktree teardown are handled by `/accept-feature`, not the orchestrator.

## When to Use

After the design pipeline produces specs or a validated plan, or any time you want to pick up where the orchestrator left off.

```
/orchestrator [feature-name|primitives] [resume|restart]
```

**Examples:**

```
/orchestrator                          # List work items from ROADMAP, pick one
/orchestrator pdf-extraction           # Resolve "pdf-extraction" against ROADMAP, infer flow
/orchestrator pdf-extraction resume    # Resume an in-progress cycle without prompting
/orchestrator pdf-extraction restart   # Invoke /abandon-feature, then start fresh
/orchestrator primitives               # Today's primitives cycle (fresh or resume)
```

The first argument is either a **feature name** (matched against the `<name>` portion of slugs like `19-04-2026-<name>`) or the literal keyword `primitives`. The second argument is optional — `resume` (require in-progress) or `restart` (route through `/abandon-feature` first). `restart` with `primitives` is rejected — primitives cycles are always fresh today-dated invocations.

When invoked without arguments, the orchestrator runs **Work Discovery**: it classifies every ROADMAP entry by priority tier (`in-progress` > `Type=feature, Status=completed, Scout-status=pending` > `planned`), cross-checks against `git worktree list`, and either picks automatically (single match) or presents a table for you to choose.

## Flow Resolution

The flow is inferred from ROADMAP state, not asked. For a feature name, the orchestrator combines the primary entry's status with the derivative refactor entry (when one exists):

| Primary entry state | Derivative | Flow |
|---|---|---|
| feature, planned | — | `standard-feature-start` |
| feature, in-progress | — | `standard-feature-resume` |
| feature, completed-pending-approval | — | Stop. "Awaiting `/accept-feature`." |
| feature, completed, Scout-status=pending | — | `refactor-start` |
| feature, completed, Scout-status=in-progress | refactor entry, `Stage=pre-curate` | `refactor-resume` (pre-curate sub-stage) |
| feature, completed, Scout-status=in-progress | refactor entry, `Stage=post-curate` | `refactor-resume` (post-curate sub-stage) |
| feature, completed, Scout-status=completed | — | Stop. "Refactor cycle complete." |
| feature, completed, Scout-status=empty-result | — | Stop. "Refactor cycle produced no actionable findings." |

For `primitives`, the orchestrator constructs the slug `<today-DD-MM-YYYY>-primitives` and checks for an existing entry; absent → fresh, in-progress → resume, completed-pending-approval → stop.

Resume also accepts the refactor slug directly: `/orchestrator <DD-MM-YYYY>-refactor-from-<parent-name>` or `/orchestrator refactor-from-<parent-name>` resolves straight to `refactor-resume`, reading the `Stage` field on the refactor entry to choose the sub-stage. The worktree leaf comes from the entry's `Worktree:` field — the orchestrator does not derive it from the slug.

## Startup

1. **Parse arguments** — feature name or `primitives`, with optional `resume`/`restart`.
2. **Work Discovery** (no arg) — classify ROADMAP entries, pick or prompt.
3. **Primitives invocation** (arg = `primitives`) — construct today's slug, check ROADMAP.
4. **Feature-name resolution** — match arg against ROADMAP slugs; 0 → stop, 1 → use, 2+ → prompt.
5. **Capture slug, flow, milestone** — from the ROADMAP entry and its containing `## Milestone:` heading.
6. **Workspace setup** — for resume flows, verify the worktree at `.worktrees/<leaf>/` exists and `cd` into it. For start flows: verify `.worktrees/` is gitignored, run `git worktree add -b <slug> .worktrees/<leaf>/ origin/main`, `cd` in, dispatch `progress-tracker start`, install dependencies (`pnpm install` in backend + frontend, `pnpm exec prisma generate` in backend), copy `.env` files from main. On `progress-tracker start` failure, the worktree is rolled back (`git worktree remove --force` + `git branch -D`).
7. **Register the state file** as the completion-gate output target.
8. **Load essentials** (`orchestrator-boundaries.md`, `state-format.md`).
9. **Intra-phase resume detection** — read `[cycle-path]/execution/.orchestrator-state.md` if present; resume from the recorded sub-step.
10. **Plan resolution** — if the plan exists, proceed (`plan-architect` and `plan-auditor` self-commit their own artifacts; the orchestrator does not commit plans). If missing for `standard-feature-start` and specs are present, run the gated `plan-architect` + `plan-auditor` sequence — a draft gate (audit the draft, fix at the draft layer) followed by a final gate, each capped at 3 attempts. For pre-curate flows (`refactor-start`, `refactor-resume` at `Stage=pre-curate`, and `primitives-pre-curate`), skip plan resolution and run the pre-curate dispatch instead.
11. **Read plan header** — objective, phase list (number, name, developer type, `abstract-migration-phase` flag, `convention-doc` task presence). Future phase details are not read until that phase is current.
12. **Present to user** — open questions (if any), feature/slug/flow/phases/branch/workspace. Wait for confirmation to begin.

## Phase Execution

Each phase runs the same step sequence (driven by `references/core-loop.md`):

| Step | Agent | Purpose |
|---|---|---|
| A | — | Read current phase from plan |
| B | developer | Implement phase tasks (non-convention-doc subset) |
| C | — | Route developer output (COMPLETED / PARTIAL / BLOCKED; NOTIFY deviations) |
| D | code-reviewer | PHASE_REVIEW or ABSTRACT_MIGRATION_REVIEW (per phase flag) |
| E | — | Route code review (PASS → F; FAIL → diagnostic-routing.md) |
| F | plan-architect + plan-auditor | Create and validate the per-phase test plan |
| G | developer (test) + code-reviewer | Write tests, TEST_REVIEW |
| H | test-runner → code-investigator | Execute tests; every failure routes through code-investigator |
| I | state-manager | Curate phase summary + handoff (additive dispatch) |
| J | — | Report to user, wait for confirmation |
| K | — | Advance to next phase or Feature Completion |

**Refactor and primitives post-curate variant.** Steps F and G are skipped. Refactor work preserves behavior, so no new BDD scenarios apply; `test-runner` runs solely to catch regression.

**Convention-doc-only phase.** If the current phase contains only `Concern: convention-doc` tasks, the orchestrator skips Steps B, D, F, G, H entirely and runs Step I in `refactor-curation` mode followed by `progress-tracker update`.

## Pre-Curate Dispatch

For the scout-and-refactor flow (`refactor-start` and `refactor-resume` at `Stage=pre-curate`):

1. `pattern-analyst` divergence-scout (bootstraps `inventory-utils.ts`).
2. `pattern-analyst` convergence-scout (reads the inventory; bootstraps `find-call-sites.ts`).
3. `pattern-analyst-auditor`.
4. `pattern-analyst` curate. Returns `APPROVED_PROPOSALS_EXIST` or `NO_PROPOSALS_APPROVED`.

For `primitives-pre-curate`: `primitives-scout` → auditor → curate. Same status returns.

Branch on the curate status:

- **`NO_PROPOSALS_APPROVED`** — commit artifacts via the `commit-to-git` skill, dispatch `progress-tracker ship` to flip the refactor entry to `Status=completed-pending-approval` (Stage stays `pre-curate` — the close-out discriminator), then hand back to user for `/accept-feature`. `progress-tracker close` will set the parent feature's `Scout-status=empty-result`. (Primitives intentionally skips the ship dispatch — primitives pre-curate creates no ROADMAP entry, so there is nothing to ship.)
- **`APPROVED_PROPOSALS_EXIST`** — for the scout-and-refactor flow, mutate the refactor entry's `Stage` to `post-curate` (the entry already exists from `refactor-start`); for primitives, dispatch `progress-tracker start` in `append` mode to create the primitives ROADMAP entry. In both cases, reuse the same worktree, then continue to the refactor-plan dispatch and phase loop.

## Developer Return Statuses

The orchestrator routes on three return statuses plus a deviation flag:

| Return | Sub-fields | Routing |
|---|---|---|
| `COMPLETED`, `Has Deviations: false` | — | Proceed to Step D (code review) |
| `COMPLETED`, `Has Deviations: true` | — | Spawn `plan-architect` with `Mode: update` + `Target: deviation`. Plan-architect returns `PROCEED_NEXT` (continue to Step D) or `RETRY_PHASE` (re-dispatch developer for the updated phase) |
| `PARTIAL` | `Reason`, `Residual Artifact` | Per the continuation matrix (see Recovery Flows) |
| `BLOCKED` | `Blocking Cause` | Per the BLOCKED sub-cause router (see Recovery Flows) |

## Code Review Modes

Code-reviewer is dispatched in different modes depending on context:

- **`PHASE_REVIEW`** — standard per-phase review (Step D).
- **`ABSTRACT_MIGRATION_REVIEW`** — used in place of PHASE_REVIEW when the phase carries the `abstract-migration-phase` flag. Additionally receives the path to the approved-findings file.
- **`TEST_REVIEW`** — review of test code written in Step G.
- **`CYCLE_REVIEW`** — optional cross-phase review at Feature Completion (catches inconsistencies between phases).
- **`INTEGRATION_VERIFICATION`** — optional structural wiring check at Feature Completion (catches orphan exports, unused imports, missing call-site updates).

## Diagnostic Routing

When code-reviewer returns FAIL, the orchestrator consults `diagnostic-routing.md` to decide whether to send the issue to `code-investigator` for deeper analysis or directly back to the developer.

Findings are tagged on two axes: **Severity** (`CRITICAL | ERROR | WARNING`) × **Category** (`LOGIC | VALIDATION | INTEGRATION | TYPE | SECURITY | CONVENTION`).

- Any `CRITICAL` finding routes to code-investigator unconditionally.
- "Always diagnose" categories — LOGIC ERROR, SECURITY WARNING, INTEGRATION ERROR — route to code-investigator.
- "Direct to developer" categories — CONVENTION (any), TYPE WARNING — skip investigation.
- "Conditional" categories — VALIDATION ERROR, TYPE ERROR — direct on first failure; investigate on repeat.
- Volume override: 3+ findings in a conditional category route to code-investigator on first failure.

## Investigation Verdicts

When code-investigator returns a verdict, the orchestrator routes per `investigation-routing.md`:

- **`LEVEL_1`** (local fix) — developer fixes per the investigation file; code-reviewer re-reviews. MEDIUM confidence with a failed fix re-invokes investigator at increased depth without counting as another attempt.
- **`LEVEL_2`** (cross-phase fix) — same as LEVEL_1, with a blast-radius warning to the developer; code-reviewer re-reviews all modified files.
- **`LEVEL_3`** (plan deviation) — pauses, escalates the Root Cause + Options to you. Your decision feeds back through code-investigator's resolution mode, then plan-architect updates the plan, plan-auditor validates, and the affected phase restarts with reset counters.
- **`LEVEL_4`** (user intervention) — pauses, presents Competing Hypotheses and "What Would Resolve This"; routes per your direction after resolution.
- **`ACCEPTED_FAILURE`** (test only) — presents the root cause for your confirmation; on confirmation, the test is marked skipped with an inline reason and test-runner re-runs.

## Recovery Flows

### NOTIFY Deviations

Developer COMPLETED with `Has Deviations: true` triggers `plan-architect` with `Mode: update` + `Target: deviation`. Plan-architect returns `Routing`: `PROCEED_NEXT` (continue normally) or `RETRY_PHASE` (re-dispatch developer for the updated phase with `Plan Revised: true`). On `Status: ERROR`, escalates.

### PARTIAL

The continuation matrix branches on `Reason`:

| Reason | Action |
|---|---|
| `turn-limit-approached` | Spawn continuation developer with the residual artifact. |
| `scope-larger-than-estimated` | Same as `turn-limit-approached`, subject to the partial-continuation escalation rule. |
| `partial-build-failure` | Continuation developer focused on the build stragglers in the residual artifact. |
| `transient-environment-issue` | Retry once; second PARTIAL on the same transient cause is treated as BLOCKED. |

The continuation developer reads the residual artifact to learn what's left. `partial_continuations` increments on every continuation; on reaching 3 the orchestrator escalates without spawning another continuation.

### BLOCKED

The router branches on `Blocking Cause`:

- **`handoff-insufficient`** — auto-recoverable. Dispatches `state-manager rebuild` (up to 2 rebuilds per phase). On SUCCESS, re-spawns developer with the enriched handoff and `Resume: true`.
- **`spec-ambiguous`** — escalates. The developer cannot proceed without clarification.
- **`dependency-missing`** — escalates. A required file, module, generated artifact, or upstream feature is absent.
- **`environment-broken`** — escalates. The workspace itself is inconsistent (broken install, missing tooling).

The three escalating causes wait for user input — no auto-recovery.

## Retry Limits

All counters are per-phase, reset at the start of each phase.

| Counter | Limit | Escalation message |
|---|---|---|
| `impl_attempts` | escalates above 3 | "Code quality limit reached for Phase [N]" |
| `test_write_attempts` | escalates above 3 | "Test quality limit reached for Phase [N]" |
| `code_bug_fixes` | escalates above 2 | "Test-detected code bug unresolvable in Phase [N]" |
| `test_bug_fixes` | escalates above 2 | "Test-detected test bug unresolvable in Phase [N]" |
| `handoff_rebuilds` | escalates above 2 | "Context rebuild limit reached for Phase [N]" |
| `partial_continuations` | escalates when count reaches 3 | "Plan miscalibration suspected in Phase [N] — too many PARTIAL continuations" |

Beyond the counter-driven escalations, the orchestrator also escalates on unresolvable investigator attribution, LEVEL_3 / LEVEL_4 verdicts, plan-architect errors, and plan-auditor INVALID after retries.

## State and Resume

Two-level state.

**Macro (cross-tree):** `.project/product/cycles-in-progress/<slug>.md` — phase-boundary granularity. Written exclusively by `progress-tracker`. Survives across worktrees.

**Micro (worktree-local):** `[cycle-path]/execution/.orchestrator-state.md` — per-dispatch sub-step granularity. Written by the orchestrator on every dispatch, user confirmation, escalation, and checkpoint. Captures the current sub-step (e.g., `implementation`, `implementation-review`, `test-planning`, `convention-curation`, etc.), counter values, last action, and report paths.

On resume, the orchestrator `cd`s into the recorded workspace first, reads the state file, and re-enters at the recorded sub-step. All persistent artifacts (code reviews, test results, investigations, summaries) survive interruption. If a return message is missing expected routing fields, the orchestrator re-spawns the agent once before escalating — it never reads the report file to recover.

When invoked with `resume`, the orchestrator verifies the cycle is in-progress before resuming and halts if not. When invoked with `restart`, it invokes `/abandon-feature <feature-name>` via the Skill tool (the skill handles destructive-action confirmation, worktree destruction, branch deletion, and ROADMAP rollback) and then re-runs feature-name resolution.

## Orchestration Summaries

After each phase, the orchestrator writes an observability summary to `[cycle-path]/execution/orchestration-summaries/phase-[N]-orchestration-summary.md` at the start of Step I, before dispatching `state-manager`. The orchestrator then commits the summary path-scoped via the `commit-to-git` skill, with `Agent: orchestrator` and subject `orchestration(<slug>): phase <N> summary`. This is the only artifact the orchestrator commits during phase execution. The summary captures:

- Every file the orchestrator read, with violation flagging against `orchestrator-boundaries.md`.
- Every Bash command run, with violation flagging (per phase: `git rev-parse HEAD` for the phase-start commit, plus `git add` / `git commit` via `commit-to-git` for the summary commit itself; all other allowed commands are startup- or completion-only).
- Every agent dispatched (agent, trigger/mode, status, report path).
- Incidents (re-spawns, escalations, recovery paths, missing files, counter pressure, boundary violations, missing-commit re-dispatches).
- Final counter values.
- User decisions during the phase.

When the orchestrator writes a phase's summary while resumed from a prior session (state-file `Resumed: true`), it prepends a marker noting that phase-tracking data prior to the resume point was lost. The marker fires only on mid-phase resumes; a resume that crosses a phase boundary self-clears at the next phase's per-phase reset, so that next phase's summary is unmarked.

These summaries support post-hoc audit of orchestrator behavior and pipeline pain points (agents not producing expected files, unnecessary retries, boundary violations, interrupted-commit recoveries).

## Feature Completion

After the last phase finishes Step I:

1. `progress-tracker ship` flips ROADMAP `Status` to `completed-pending-approval`.
2. Optional reviews offered: `CYCLE_REVIEW` (cross-phase code review) and/or `INTEGRATION_VERIFICATION` (structural wiring check). Either is dispatched to `code-reviewer` with all phase developer types and the cycle-summary path returned by `state-manager`'s `cycle-close` dispatch.
3. Hands back to user for `/accept-feature <feature-name>`. The skill handles the atomic merge into main, post-merge verification, `progress-tracker close`, worktree removal, branch deletion, and any milestone follow-up (quality-analyst + milestone-archivist on a milestone-completing acceptance).

The orchestrator does not merge, does not run post-merge verification, does not dispatch quality-analyst, and does not delete worktrees or branches.

## Boundaries

The orchestrator inspects nothing it routes. Specifically it never:

- runs git inspection commands (`git log`, `git diff`, `git status`, `git show`) to inspect what an agent did (routing data comes from agent report frontmatter)
- runs build, lint, or test commands (output verification happens via dispatch)
- reads source code, test files, agent report contents, handoff contents, investigation contents, manifest contents, or phase summary contents
- attempts to fix code, build errors, or any issues
- writes `.project/product/ROADMAP.md` or `.project/product/cycles-in-progress/*.md` (delegated to `progress-tracker`)
- commits code, plan files, or another agent's artifacts (writer == committer everywhere — the orchestrator only commits its own three artifacts: the per-phase orchestration-summary, the pre-curate artifact bundle on `NO_PROPOSALS_APPROVED`, and the `.worktrees/` line on first-run gitignore setup)
- runs ad-hoc Bash commands outside the allowed list in `essentials/orchestrator-boundaries.md`

If asked to inspect code or fix issues, the orchestrator redirects: "That's not the orchestrator's role — shall I dispatch [appropriate agent] instead?"

Merge conflicts on ROADMAP or tracking files are always resolved by taking main's version (`git checkout --theirs`) — a conflict on either path means a worktree-side agent wrote to them in violation of the delegation rule, which is a bug to surface, not a merge to judge.

If a dispatched committing subagent returns without a `Commit:` field — or fails to return at all — the orchestrator re-dispatches the same invocation. Each committing subagent's write+commit workflow is idempotent under re-execution; the second attempt produces either a fresh hash or `Commit: skipped` when content matches HEAD. The orchestrator does not inspect git history to verify what happened on the prior attempt — the return-message presence is the sufficient signal.

## Git Strategy

The orchestrator owns three commit points; every other artifact has its own committer.

1. **First-run gitignore commit (main-side).** If `.worktrees/` is not gitignored, the orchestrator commits the `.gitignore` line via the `commit-to-git` skill before spawning the worktree (`git worktree add -b <slug> .worktrees/<leaf>/ origin/main`). The slug serves as branch name, worktree leaf, and tracking-file name.
2. **Phase start.** `phase_start_commit = git rev-parse HEAD` captures a baseline hash for the developer's revert path — no commit here.
3. **Per-phase orchestration-summary commit (worktree-side).** At the end of Step I, after writing the orchestration-summary, the orchestrator commits it path-scoped via the `commit-to-git` skill with `Agent: orchestrator`, subject `orchestration(<slug>): phase <N> summary`.
4. **Pre-curate artifact-bundle commit (worktree-side).** On `pattern-analyst` curate returning `NO_PROPOSALS_APPROVED`, the orchestrator commits the findings + audit + approved + `-original.md` archives path-scoped via `commit-to-git` — subject `refactor(<refactor-slug>): no proposals close-out` for the scout-and-refactor flow, `primitives(<primitives-slug>): no proposals close-out` for primitives pre-curate.
5. **Everything else commits via its own writer.** Developers commit code to the slug-named branch; `plan-architect`/`plan-auditor` commit plan files and audit reports; `code-reviewer` commits reviews; `test-runner` commits results; `code-investigator` commits investigations; `state-manager` commits summaries, handoffs, and the execution-index; `pattern-analyst`/`pattern-analyst-auditor` commit refactor artifacts; `progress-tracker` commits ROADMAP and tracking files main-side.
6. **Revert.** Delegated to the developer via `Reset To Commit: <phase_start_commit>` during PARTIAL/BLOCKED recovery when the user discards partial work. The developer's revert is code-scoped; committed `.project/**` artifacts (including the orchestration-summary) survive.
7. **Interrupted-commit recovery.** When a dispatched committing subagent returns without a `Commit:` field, the orchestrator re-dispatches the same invocation. See `essentials/orchestrator-boundaries.md` for the full Message Validation Protocol.
8. **Completion.** Hand back to user for `/accept-feature`.

## Related Files

| File | Purpose |
|---|---|
| `.claude/skills/orchestrator/SKILL.md` | Skill definition (authoritative) |
| `.claude/skills/orchestrator/essentials/orchestrator-boundaries.md` | Allowed reads, allowed Bash commands, message validation |
| `.claude/skills/orchestrator/essentials/state-format.md` | State file template, sub-step values, resume behavior |
| `.claude/skills/orchestrator/references/core-loop.md` | Per-phase Step A–K workflow |
| `.claude/skills/orchestrator/references/coordination.md` | progress-tracker sequencing, worktree boundary, merge-conflict rule |
| `.claude/skills/orchestrator/references/recovery-paths.md` | NOTIFY deviations, PARTIAL, BLOCKED branches |
| `.claude/skills/orchestrator/references/diagnostic-routing.md` | Code-reviewer FAIL routing (severity × category) |
| `.claude/skills/orchestrator/references/investigation-routing.md` | Code-investigator verdict routing (LEVEL_1–4, ACCEPTED_FAILURE) |
| `.claude/skills/orchestrator/references/counters-and-escalation.md` | Counter limits, escalation format and types |
| `.claude/skills/orchestrator/references/orchestration-summary-format.md` | Per-phase observability template |
| `.claude/skills/accept-feature/SKILL.md` | Merge, post-merge verification, cleanup, milestone follow-up |
| `.claude/skills/abandon-feature/SKILL.md` | Destructive teardown for `restart` and manual cancellation |
| `.claude/agents/interface-contracts/progress-tracker.contract.md` | progress-tracker contract — sole owner of ROADMAP (creation + transitions) and per-feature tracking files |
| `.claude/agents/interface-contracts/developer.contract.md` | Developer agent contract |
| `.claude/agents/interface-contracts/code-reviewer.contract.md` | Code-reviewer agent contract |
| `.claude/agents/interface-contracts/state-manager.contract.md` | State-manager agent contract |
| `.claude/agents/interface-contracts/plan-architect.contract.md` | Plan-architect agent contract |
| `.claude/agents/interface-contracts/plan-auditor.contract.md` | Plan-auditor agent contract |
| `.claude/agents/interface-contracts/test-runner.contract.md` | Test-runner agent contract |
| `.claude/agents/interface-contracts/code-investigator.contract.md` | Code-investigator agent contract |
| `.claude/agents/interface-contracts/pattern-analyst.contract.md` | Pattern-analyst agent contract |
| `.claude/agents/interface-contracts/pattern-analyst-auditor.contract.md` | Pattern-analyst-auditor agent contract |
