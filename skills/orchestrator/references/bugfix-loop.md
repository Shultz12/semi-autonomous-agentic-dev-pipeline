# Bug-Fix Loop

Read this file once when beginning a bug fix (at Stage 0), alongside `coordination.md`. It is the bugfix-flow sibling of `core-loop.md`: the stage-by-stage dispatch sequence for `/orchestrator bug fix`. Stages 0–2 are a bugfix-specific prelude; Stage 3 reuses the `core-loop.md` per-phase loop with the per-scenario step mapping below.

`orchestrator-boundaries.md` applies here unchanged. In particular, the orchestrator never runs a build, lint, or test command in the orchestration loop — the **tool-oracle is `code-investigator`** (it runs the build/lint/type command in its own context), exactly as **`test-runner` is the behavioral oracle**. The orchestrator routes their results; it never produces the failing signal itself.

The flow front-loads root-cause analysis so the fix targets the cause, not the symptom. Four gates carry that guarantee: diagnose before planning; a confirmed failing signal exists before any fix code; the plan is built only from the diagnosis; and the fix is proven to remove the cause (reproduction RED→GREEN + suite green, or build/lint passes) with code review checking fidelity to the documented cause.

## Scenario matrix

The scenario class fixes the oracle and which agents run. **Investigator(s) always run; test-dev + test-runner are the optional axis.**

| Scenario | Oracle (green gate) | Investigator(s) | Test-dev | Test-runner |
|---|---|---|---|---|
| **build / type error** | build passes | 1 by default (fan-out on the investigator's recommendation) | skipped | skipped (optional regression run — see Stage 3) |
| **lint error** | lint passes | 1+ | skipped | skipped (optional regression run — see Stage 3) |
| **runtime crash / exception** | reproduction test flips GREEN + suite green | 1+ | required | required |
| **wrong output / logic bug** | reproduction test flips GREEN + suite green | 1+ | required | required |

`build`, `lint`, `type` are the **tool-oracle** scenarios; `crash`, `logic` are the **behavioral** scenarios.

## Triage (choosing the row)

The orchestrator stays lean and never pulls tool output into its own context.

1. **Classify from the description first** (free): `build | lint | type` → tool-oracle; `crash | logic` → behavioral.
2. **If the class is genuinely ambiguous**, prefer **investigate-first** — dispatch `code-investigator` (`STANDALONE_BUG`) with the bug report and let it establish the class; its `Scenario-Reclassification` flag is the safety net. Asking the user one clarifying question is the alternative. **Never run a build/lint/test command to classify** — Boundary Rule 2 holds; the investigator is the oracle.
3. **Heavy diagnostic capture is always delegated** to `code-investigator`, which runs the oracle in its own context and returns ~3 lines plus an investigation-file path.

The orchestrator's first-pass classification is never final: the investigator can reclassify (see § Three investigation outcomes).

## Stage 0 — Intake  (`Sub-Step: bugfix-intake`)

1. **Derive the slug** autonomously from the symptom + affected area — form `<DD-MM-YYYY>-fix-<name>` (e.g. `19-04-2026-fix-hebrew-date-parse-crash`). Reject generic placeholders (`fix-bug`, `fix-error`) and re-derive a descriptive name. This canonical slug is passed verbatim to every downstream component; no component re-derives it.
2. **Resolve the active milestone** — read the ROADMAP for the in-progress `## Milestone: <version>` section; if none or several are in-progress, ask the user which milestone this fix belongs to. Retain as `milestone`.
3. **Create the worktree + branch** (soft-transactional start per `coordination.md`). Before spawning the worktree — while still in the main repo root — capture `main_repo_root` (the current CWD) and derive `pipeline_root` from it per `SKILL.md` Step 0g § Pipeline Root derivation. Both are needed in every downstream dispatch footer (bug fixes dispatch the same worktree-bound agents as the feature flow) and must be recorded before the `cd`. Then:
   ```
   git worktree add -b <slug> .worktrees/<slug>/ origin/main
   ```
   `cd` into the worktree, then run dependency setup (`backend && pnpm install`, `pnpm exec prisma generate`, `frontend && pnpm install`, copy `.env` files) exactly as the feature flow does at Startup Step 0f.
4. **Write `specs/bug-report.md`** into the worktree per § Bug-report format in `SKILL.md`, then validate it (all required frontmatter fields; enums valid; `slug` matches the directory; required `## ` sections present and ordered; the `## Expected Behavior` / `## Actual Behavior` presence matches the scenario class). A malformed bug report is a hard fail — rewrite it or surface to the user; never dispatch downstream with a malformed report. **Commit it** path-scoped via the `commit-to-git` skill (`Agent: orchestrator`, subject `bugfix(<slug>): bug report`, path `specs/bug-report.md`) so it reaches main via the accept-time merge (see `SKILL.md` § Git Strategy).
5. **Dispatch `progress-tracker start`:**
   ```
   Mode: start
   Slug: <slug>
   Worktree-Type: bugfix
   Worktree: .worktrees/<slug>/
   Roadmap-Action: auto
   Total-Phases: 0
   Milestone: <active milestone>
   ```
   `Total-Phases: 0` is intentional and permanent for the tracking file — the bugfix tracking file carries no `of <M>` denominator (like refactor/primitives pre-curate). The real phase count is captured in the orchestrator's state file at Stage 2, never back-filled. On `start` failure, roll back the worktree (`git worktree remove --force` + `git branch -D`) and stop.

Record the bugfix context in the state file (`Flow: bugfix-start`, `Sub-Step: bugfix-intake`, `slug`, `milestone`, `main_repo_root`, `pipeline_root`, `cycle_path = .project/cycles/<slug>/`, the triaged `scenario` class).

## Stage 1 — Reproduce & Diagnose  (`Sub-Step: bugfix-reproduce`, then `bugfix-investigate`)

No fix code is written until a confirmed failing signal grounded in the cause exists. Ordering is flexible: an easy bug reproduces then investigates; a hard-to-reproduce bug investigates first to find the deterministic conditions, then writes the reliably-failing test.

### Behavioral path (`crash`, `logic`)

The reproduction **plan** is authored before the test, so the test dispatch goes through the same plan-driven path every developer dispatch uses.

1. **plan-architect** (`Sub-Step: bugfix-reproduce`):
   ```
   Mode: create
   Target: bugfix-reproduction
   Cycle: <slug>
   Cycle Path: <cycle-path>
   Bug Report: <cycle-path>/specs/bug-report.md
   ```
   Add `Investigation Files: <paths>` only when investigate-first has already produced one (so the reproduction can use the deterministic conditions); add `Affected Test Files Hint: <from bug report ## Affected Area>` when present.
2. **plan-auditor** (single audit loop, 3-attempt cap — 1 original + up to 2 updates):
   ```
   Validate the plan at: <cycle-path>/plans/reproduction-plan.md
   Target: bugfix-reproduction
   Mode: full-audit
   ```
3. **developer (test)** — read the reproduction plan's task(s) and dispatch with them inline; each task carries `Bug-Expectation:` (the bug report's `## Expected Behavior`, verbatim):
   ```
   Developer Type: test
   Cycle: <slug>
   Phase: 0: bugfix-reproduce
   Objective: <restore the expected behavior — see specs/bug-report.md>
   Handoff Path: none
   Report Directory: <cycle-path>/execution/developer-reports/
   Report Name: reproduction-test-report.md

   Tasks:
   [reproduction-plan task(s), each with Bug-Expectation:]
   ```
   All three Stage 1 reproduction dispatches (developer, code-reviewer, test-runner) carry the **pre-plan token `Phase: 0: bugfix-reproduce`** — the reproduction precedes the implementation plan, so it is phase 0 by the pre-plan convention. The reproduction plan's own single-phase heading is internal to the plan; the dispatch token is the pre-plan convention, which keeps every reproduction-stage artifact (report, review, results) numbered phase 0 consistently.
4. **code-reviewer (TEST_REVIEW)** — the reproduction test passes the same gate every feature test does (a FAIL routes back to the developer via standard TEST_REVIEW recovery in `diagnostic-routing.md`):
   ```
   Reviewer Type: test
   Cycle: <slug>
   Phase: 0: bugfix-reproduce
   Trigger: TEST_REVIEW
   Objective: <from bug report>
   Review Output Directory: <cycle-path>/execution/code-reviews/
   Review Attempt: 1
   Prior Review Paths: none
   Developer Report: <cycle-path>/execution/developer-reports/reproduction-test-report.md
   Phase Tasks: [reproduction task(s)]
   ```
   The `Phase: 0:` numeric prefix marks a pre-plan run; code-reviewer renders the review file as `phase-0-test-review-attempt-<K>.md` (reconstruct `Prior Review Paths` on resume by globbing that pattern).
5. **test-runner (`Mode: reproduction`)** — runs **only** the reproduction test(s) and must report **FAIL**:
   ```
   Mode: reproduction
   Cycle: <slug>
   Cycle Path: <cycle-path>
   Phase: 0: bugfix-reproduce
   Test Report: <cycle-path>/execution/developer-reports/reproduction-test-report.md
   Results Output Path: <cycle-path>/execution/test-results/reproduction-results.md
   ```
   `Overall: FAIL` is success — record `Reproduction-Confirmed: <test-id(s)> RED @ <commit>` in the state file; attribution is ignored here. `Overall: PASS` means the test did not capture the bug → refine the test or re-investigate (counts against `repro_attempts`).
6. **code-investigator (`STANDALONE_BUG`)** — root-cause analysis from the failing test + report (`Sub-Step: bugfix-investigate`). See § STANDALONE_BUG dispatch.

**Bundled bugs.** When one bug report describes multiple distinct symptoms, the reproduction plan enumerates them as multiple tasks (one test per symptom, each with its own `Bug-Expectation:`). The `Reproduction-Confirmed` record lists every confirmed test-id.

### Tool-oracle path (`build`, `lint`, `type`)

No reproduction test. Dispatch one **code-investigator (`STANDALONE_BUG`)** directly — it runs the failing command in its own context and is the reproduction oracle (it returns `CANNOT_REPRODUCE` if the command passes and no cause surfaces; see § Three investigation outcomes). It may recommend fan-out.

### STANDALONE_BUG dispatch

```
Mode: investigation
Trigger: STANDALONE_BUG
Cycle: <slug>
Cycle Path: <cycle-path>
Bug Report: <cycle-path>/specs/bug-report.md
Investigation Output Path: <cycle-path>/execution/code-investigations/<DD-MM-YYYY>-HH-MM-investigation.md
Investigation Attempt: <N>
Minimum Depth: 0
```
- **Behavioral, reproduce-first:** also pass `Reproduction Test Report:` and `Reproduction Results:` (the confirmed-RED artifacts).
- **Behavioral, investigate-first:** omit the reproduction artifacts (the investigator works from the bug report + its `## Attached Output`).
- **Tool-oracle:** add `Failing Commands: <one shell command per line>` (the investigator runs each and reads the output in its own context).
- The orchestrator **always supplies `Investigation Output Path`** (the investigator does not self-generate the timestamped filename). On **fan-out**, give each additional investigator its own **distinct** `Investigation Output Path` so the files do not collide.

### Three investigation outcomes (both paths)

Every `STANDALONE_BUG` return resolves to one of three (read the verdict + any flag lines; never read the investigation file content):

1. **Severity verdict (LEVEL_1–LEVEL_4), scenario holds** → proceed to the Checkpoint.
2. **Severity verdict + `Scenario-Reclassification: <class>`** → the cause is established but belongs on the other path. Re-route the matrix row:
   - **tool-oracle → behavioral** (the build passes but the symptom is a logic/crash defect — "pass it down to the tests"): switch to the behavioral path in investigate-first ordering. The investigation already holds the cause + deterministic conditions, so author the reproduction plan/test grounded in it, confirm RED, then go to the Checkpoint.
   - **behavioral → tool-oracle**: drop the test machinery; the build/lint is now the oracle. Go to the Checkpoint.
3. **`CANNOT_REPRODUCE`** → the oracle showed no defect and no cause surfaced. Surface to the user: *"Cannot reproduce the reported failure in a clean worktree at `<commit>`."* Park `blocked` (worktree kept); the user supplies more detail and resumes, or runs `/abandon-feature <slug>`. See § Terminal / parked states.

**Fan-out.** When a return carries `Fan-Out-Recommended: true`, dispatch one additional investigator per cluster (each with its own distinct `Investigation Output Path`), using the per-cluster sketch in the body. The orchestrator never decides fan-out blind — only on the investigator's recommendation.

### `repro_attempts` (behavioral only; cap 3)

Each cycle of write/refine-test → RED-check is one attempt; an attempt may include a re-investigation. The counter is persisted in the state file so the cap survives a resume. The 3rd failure to confirm RED → escalate and park `blocked` (the cause is known/suspected; the test just won't reliably go red). This is distinct from a LEVEL_4 verdict, which routes to the Checkpoint.

## Checkpoint (after diagnosis, before planning)  (`Sub-Step: bugfix-checkpoint`)

Decide by severity + confidence using the **most-cautious verdict across all investigations**:

- `LEVEL_1` or `LEVEL_2` **at HIGH confidence** → **auto-proceed** to Stage 2.
- `LEVEL_3`, `LEVEL_4`, or **any MEDIUM confidence** → **pause**. Present the root cause (and the options for LEVEL_3/4, from the investigator's return) to the user. The user confirms or chooses; route the decision back through **`code-investigator` resolution mode**, which records `resolved: true` in the investigation frontmatter:
  ```
  Mode: resolution
  Phase: 0: bugfix-checkpoint
  Investigation File Path: <investigation path>
  Level: LEVEL_3 | LEVEL_4
  Resolution: <user's chosen option (LEVEL_3) or decision text (LEVEL_4)>
  Rationale: <user's reasoning, or "Not provided">
  ```
  Resolution mode parses the `Phase: 0: bugfix-checkpoint` token and renders its commit subject from the numeric prefix `0`; the investigation file's own frontmatter stays `phase: n/a` (file metadata, distinct from the routing token).
- **LEVEL_4 that resolution returns `INSUFFICIENT`** → park `blocked` (see § Terminal / parked states).

After the resolution is recorded (or on auto-proceed), continue to Stage 2.

## Stage 2 — Plan  (`Sub-Step: bugfix-plan`)

Two passes (draft → final), because the cause may itself be duplicated functionality — REUSE / EXTRACT can legitimately be the prescribed fix. The plan's sole content-source is the investigation file(s) and the bug report. **No SRS/SDD/BDD** — the bug report is this flow's specification; do not run the feature flow's spec-presence check, and do not attach cross-feature specs.

1. **plan-architect (`bugfix-draft`)** → **plan-auditor (`bugfix-draft`)** — single audit pass on verb/concern/metadata/sizing/path-grounding (3-attempt cap):
   ```
   Mode: create
   Target: bugfix-draft
   Cycle: <slug>
   Cycle Path: <cycle-path>
   Bug Report: <cycle-path>/specs/bug-report.md
   Investigation Files: <all investigation paths>
   ```
   ```
   Validate the plan at: <cycle-path>/plans/implementation-plan-draft.md
   Target: bugfix-draft
   Mode: full-audit
   ```
2. **plan-architect (`bugfix-final`)** → **plan-auditor (`bugfix-final`)** — directive analysis (REUSE / EXTRACT); the audit includes the **investigation-resolved** check (`INVESTIGATION_UNRESOLVED` if any cited investigation carries a LEVEL_3/4 verdict without a recorded resolution) (3-attempt cap):
   ```
   Mode: create
   Target: bugfix-final
   Cycle: <slug>
   Cycle Path: <cycle-path>
   Plan Draft Path: <cycle-path>/plans/implementation-plan-draft.md
   Bug Report: <cycle-path>/specs/bug-report.md
   Investigation Files: <same set passed to the draft>
   ```
   ```
   Validate the plan at: <cycle-path>/plans/implementation-plan.md
   Target: bugfix-final
   Mode: full-audit
   ```

**Plan-architect ERROR guard.** If any `plan-architect` dispatch returns `Status: ERROR` (e.g. `TECH_NOT_IN_CHARTER`), it wrote no plan — do not dispatch `plan-auditor` and do not retry. Route per `recovery-paths.md` § Plan-Architect ERROR and wait for the user.

**Phase count → state file.** Once `implementation-plan.md` passes its final audit, count its `## Phase` headings and record that as **Total Phases** in the orchestrator's state file. This value — not the tracking file — drives final-phase detection and the Stage 3 green gates. Do **not** dispatch `progress-tracker update` for `total-phases`: the bugfix tracking file keeps no denominator (`Total-Phases: 0` at intake is intentional and never back-filled).

## Stage 3 — Fix (per phase, from the plan)  (`Sub-Step: bugfix-fix-phase`)

Reuse the `core-loop.md` per-phase loop with this per-scenario mapping:

| core-loop step | Behavioral | Tool-oracle |
|---|---|---|
| B developer (fix from investigation) | ✓ | ✓ |
| C route developer output | ✓ | ✓ |
| D code-reviewer `PHASE_REVIEW` + investigation | ✓ | ✓ |
| E route code review | ✓ | ✓ |
| F/G test plan + test writing | **skipped** (test front-loaded in Stage 1) | **skipped** |
| H test-runner (→ code-investigator on failure) | **every fix phase** (see green gate) | skipped by default; optional regression run if the fix changed runtime logic |
| I state-manager (`cycle-phase`; `cycle-close` on last phase) | ✓ | ✓ |
| J/K report + advance | ✓ | ✓ |

**Step B — developer (Fix Mode from investigation).** Every bugfix fix-phase developer carries the investigation alongside the plan tasks:
```
Developer Type: [phase's Developer: type]
Cycle: <slug>
Phase: [N]: [phase-name]
Objective: [from plan header]
Handoff Path: none   (first fix phase; later phases use the state-manager handoff)
Report Directory: <cycle-path>/execution/developer-reports/
Report Name: phase-[N]-implementation-report.md
Resume: [true only when re-spawning after interruption]

Tasks:
[current phase tasks from implementation-plan.md]

Investigation File: [the investigation file the phase's fix is grounded in]
Instruction: Read the investigation file, apply the prescribed fixes per the plan tasks, then re-run verification.
```

**Step D — code-reviewer (PHASE_REVIEW + investigation fidelity).** Pass the `Investigation File:` so the reviewer loads the bugfix overlay and checks the change for fidelity to the documented cause. A change that masks or suppresses the symptom instead of addressing the cause (a blanket `@ts-ignore`, a swallowing `catch`, a NULL check hiding a wrong default) is `CRITICAL × LOGIC` and fails the phase:
```
Reviewer Type: [phase's type]
Cycle: <slug>
Phase: [N]: [phase-name]
Trigger: PHASE_REVIEW
Objective: [from plan header]
Review Output Directory: <cycle-path>/execution/code-reviews/
Review Attempt: [impl_attempts]
Prior Review Paths: [code_review_paths or none]
Developer Report: [developer report path]
Investigation File: [the same investigation file]
Phase Tasks:
[current phase tasks]
```
Route the review per `diagnostic-routing.md` (PHASE_REVIEW table) — a masking `CRITICAL × LOGIC` always routes to `code-investigator`.

**Step H — test-runner green gates (behavioral):**
- **Single-phase (common):** the one phase runs `Mode: full-suite` and requires every `Reproduction-Confirmed` test GREEN + the whole suite green.
- **Multi-phase, intermediate phases:** run `Mode: targeted` with `Files:` = **every `Reproduction-Confirmed` test file** (from the state file's `Reproduction-Confirmed` record), plus any test files the current plan phase explicitly names. Intermediate gate: among the tests run, the only permitted failures are `Reproduction-Confirmed` test(s) whose bug is not yet fully fixed — any *other* red (a regressed reproduction test, or a plan-named regression test) is a regression and fails the phase. Each `Reproduction-Confirmed` test must flip GREEN no later than the phase that completes its bug (flipping early just means that fix finished early — advance).
  ```
  Mode: targeted
  Cycle: <slug>
  Cycle Path: <cycle-path>
  Phase: [N]: [phase-name]
  Files: [every Reproduction-Confirmed test file; + any plan-named test files]
  Results Output Path: <cycle-path>/execution/test-results/phase-[N]-results.md
  ```
- **Multi-phase, final phase:** run `Mode: full-suite` and require every `Reproduction-Confirmed` test GREEN + the whole suite green.
  ```
  Mode: full-suite
  Cycle: <slug>
  Cycle Path: <cycle-path>
  Phase: [N]: [phase-name]
  Results Output Path: <cycle-path>/execution/test-results/phase-[N]-results.md
  ```
- On any test FAIL that is **not** an expected still-pending reproduction test, dispatch `code-investigator` with `Trigger: TEST_FAILURE` (the plan and manifest exist in Stage 3) and route the verdict per `investigation-routing.md` — the standard core-loop Step H behavior.

**Step H — green gate (tool-oracle):** the build/lint/type pass is the developer's native verification at Step B. Test-runner is skipped by default; run it once in `Mode: full-suite` only when the fix modified **runtime logic** (not a formatting-only or types-only change), to confirm no behavioral regression. Pure cosmetic fixes skip it.

**Mid-fix deepening.** If the developer returns `BLOCKED: spec-ambiguous`, the "spec" is the investigation — **re-run `code-investigator`** (deeper: `Minimum Depth` increased by 1) and then re-plan (re-enter Stage 2), rather than the feature flow's "present to user and wait." Never a quiet workaround.

## Stage 4 — Ship & Accept

On the last phase, Step I dispatches `state-manager` in `cycle-close` mode (the reproduction test's link to the bug is recorded in the feature summary for the audit trail), exactly as the feature flow does. Then:
1. Dispatch `progress-tracker ship` (flips `Status` to `completed-pending-approval`).
2. Hand back to the user for `/accept-feature <slug>` — the skill handles atomic merge, post-merge verification, worktree removal, branch deletion, and the `progress-tracker close` dispatch. The bug report, investigations, and plans land on main via the `--no-ff` merge.

**Milestone completion.** A bugfix entry participates in milestone completion exactly like a feature: when it is the last open entry, `progress-tracker close` flips the milestone to `completed` and surfaces `MilestoneCompleted: v<X.Y>`, and `accept-feature` spawns `milestone-archivist`. No carve-out.

## Terminal / parked states

- **`repro_attempts` exhausted (3)** — the reproduction test cannot be made reliably RED though a cause is known/suspected → `Phase-Status: blocked` (records the ask in the tracking file), worktree kept, stop.
- **LEVEL_4 the user cannot resolve at the Checkpoint** — resolution returns `INSUFFICIENT` → `Phase-Status: blocked`, worktree kept, stop.
- **`CANNOT_REPRODUCE`** — the investigator's oracle showed no defect and no cause surfaced → surface "cannot reproduce the reported failure in a clean worktree" and park `Phase-Status: blocked`, worktree kept, stop.

In every parked case the user supplies more detail and resumes (`/orchestrator bug fix` with no description), or runs `/abandon-feature <slug>` to discard the worktree, branch, ROADMAP entry, and the worktree-local cycle directory.

## Cross-references

- The per-phase loop mechanics (counters reset, phase tracking, Step C routing, Step E routing, Step I state-manager + orchestration-summary, Step J/K) are in `core-loop.md` — Stage 3 reuses them verbatim except for the per-scenario differences above.
- Developer non-COMPLETED routing (PARTIAL, BLOCKED, NOTIFY) is in `recovery-paths.md`. The bugfix override is the `spec-ambiguous` case above (re-investigate, do not wait).
- Code-review failure routing is in `diagnostic-routing.md`; investigation-verdict routing (Stage 3 TEST_FAILURE) is in `investigation-routing.md`.
