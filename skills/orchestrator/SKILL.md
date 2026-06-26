---
name: orchestrator
description: Coordinates standard-feature, post-merge refactor, primitives, and bug-fix flows. Reads ROADMAP for the next work item, spawns isolated worktrees, and dispatches pipeline agents phase-by-phase. Use when executing pipeline work via /orchestrator [feature-name|primitives|bug fix] [resume|restart].
disable-model-invocation: true
argument-hint: [feature-name|primitives|bug fix <description>] [resume|restart]
user-invocable: true
domain: dev-tooling
allowed-tools: Read, Write, Agent, Glob, Bash, Skill, AskUserQuestion
---

# Orchestrator

Execute pipeline work flow-by-flow and phase-by-phase by dispatching agents, handling results, and keeping context lean.

**Execution-only** — does not author specs or design documents; dispatches plan-architect to create plans when missing.

## Context Discipline

Every piece of data the orchestrator touches has a clear reason: a dispatch decision or a pass-through to an agent.

- Read ROADMAP at startup. Do not re-read mid-loop unless a routing question requires it.
- Read only the current phase from the plan, not future phases — plan-architect may revise later phases before the orchestrator reaches them, so reading ahead risks acting on stale data.
- Do not re-read a reference file already read this session — `Read` dedupes unchanged files across the conversation; re-reading wastes tokens without adding context.
- Extract routing fields from agent messages (status, verdict, paths, routing flags).
- Pass file paths to downstream agents — do not read report, handoff, investigation, or review file contents.
- Do not accumulate or restate agent output in messages to the user.

## Dispatch Discipline

Every agent dispatch the orchestrator sends ends with this footer:

```
Working Directory: [absolute path to current workspace — worktree path]
Pipeline Root: [absolute path to the pipeline install root — `pipeline_root` from Step 0g]
Reference-Read Resolution: resolve every `.claude/...` pipeline reference (skills, agent
  references) against Pipeline Root, NOT the Working Directory. `.project/...` reads stay
  worktree-relative.
Input Discipline: Read only the file paths explicitly provided in this input.
```

Dispatch templates in this skill and in `references/` omit the footer for brevity — append it to every dispatch input sent to any agent. The footer scopes downstream agents to the paths handed to them, tells them where to `cd` before running Bash commands, and resolves the `.claude/...` references they read (skills, agent references) against the pipeline install root. A dispatched agent runs inside a worktree, which carries only *tracked* files — a project-level pipeline (vendored under `.claude/`) is gitignored (so it is absent from the worktree) and a user-level install lives outside the project repo entirely; either way a worktree-relative `.claude/...` read fails, so the agent resolves those reads against **Pipeline Root**. The handed-in absolute path means a dispatched agent never runs a `git` call to locate the pipeline, which dissolves the `bash-usage` relative-path constraint for `.claude/...` reads.

**Orchestrator CWD:** After `cd`'ing into the workspace at Startup Step 0f, stay there for the rest of the session — use workspace-relative or absolute paths, never re-prefix with `cd .worktrees/[leaf]`.

## Retained State

| Scope | Data | Notes |
|---|---|---|
| All phases | Feature name, slug, feature_slug (refactor only), milestone, total phases, branch (= slug), workspace path, main repo root, pipeline root, feature path, flow type, objective, phase list (number, name, developer type, `abstract-migration-phase` flag, `convention-doc` task presence); for a bug fix: the scenario class and the `Reproduction-Confirmed` test-id(s) | Captured at startup (bug-fix scenario at triage; `Reproduction-Confirmed` at Stage 1) |
| Per phase (reset each phase) | Counters (`impl_attempts`, `test_write_attempts`, `code_bug_fixes`, `test_bug_fixes`, `handoff_rebuilds`, `partial_continuations`); `phase_start_commit`; current handoff path; current phase content; report paths accumulated during phase | Phase content discarded after phase completes |
| Pass-through only | Developer status + report path → code-reviewer, state-manager; code-reviewer verdict + review path → state-manager; test-runner verdict + results path; code-investigator verdict + investigation path; state-manager handoff path retained for next phase | Field extraction only; file contents never read |

## Pipeline I/O

**Reads:**
- `.project/product/ROADMAP.md` — work-item discovery, status classification (startup)
- `.project/product/cycles-in-progress/<slug>.md` — resume verification (startup)
- `[cycle-path]/plans/implementation-plan.md` — phase tasks, objective (feature flow)
- `[cycle-path]/plans/refactor-plan.md` — phase tasks (refactor post-curate stage, primitives post-curate sub-flow)
- `[cycle-path]/execution/.orchestrator-state.md` — intra-phase resume detection
- `[cycle-path]/execution/state/phase-summaries/phase-*-summary.md` — resume cross-verification
- `essentials/` files — operational boundaries, state format (loaded at startup)
- `references/` files — coordination, core loop, counters and escalation, orchestration summary format, recovery paths, diagnostic routing, investigation routing (loaded on-demand)

**Writes:**
- `[cycle-path]/execution/.orchestrator-state.md` — per-dispatch progress tracking for intra-phase resume (git-ignored; never committed)
- `[cycle-path]/execution/orchestration-summaries/phase-[N]-orchestration-summary.md` — per-phase observability (committed by the orchestrator path-scoped via `commit-to-git` at the end of Step I, before state-manager dispatch)
- `[cycle-path]/specs/bug-report.md` — bug-fix flow only; orchestrator-authored at Stage 0 intake and committed path-scoped via `commit-to-git` (writer == committer; see § Git Strategy)

**Orchestrated writes** (via downstream agents):
- `[cycle-path]/execution/developer-reports/` — developer
- `[cycle-path]/execution/code-reviews/` — code-reviewer
- `[cycle-path]/plans/test-plans/` — plan-architect
- `[cycle-path]/execution/plan-changelog.md` — plan-architect
- `[cycle-path]/plans/test-plans/test-plan-changelog.md` — plan-architect
- `[cycle-path]/execution/test-results/` — test-runner
- `[cycle-path]/execution/code-investigations/` — code-investigator
- `[cycle-path]/execution/state/phase-summaries/` — state-manager
- `[cycle-path]/execution/state/handoffs-to-developer/` — state-manager
- `[cycle-path]/execution/manifest.md` — state-manager
- `[cycle-path]/codemods/` — developer (ABSTRACT migration phases)
- `[cycle-path]/execution/<date>-codemod-stragglers-<cycle>.md` — developer (ABSTRACT migration phases)
- `.project/cycles/<slug>/refactor-proposals/` — pattern-analyst, pattern-analyst-auditor
- `.project/product/ROADMAP.md` — progress-tracker
- `.project/product/cycles-in-progress/<slug>.md` — progress-tracker

**ROADMAP and tracking-file discipline.** The orchestrator runs inside a worktree and never writes `.project/product/ROADMAP.md` or any file under `.project/product/cycles-in-progress/` directly — both are main-only by construction and must be updated via the dedicated pipeline-side dispatch. One narrow carve-out: at a refactor or primitives cycle's pre-curate → post-curate transition (Step 5's `APPROVED_PROPOSALS_EXIST` branch), the orchestrator mutates the in-progress refactor or primitives entry's `Stage:` line in `.project/product/ROADMAP.md` directly — the single ROADMAP-write carve-out from `progress-tracker`'s exclusive ownership. Every other ROADMAP write, and every write to `.project/product/cycles-in-progress/`, stays delegated. A worktree-side write to either file outside that carve-out is a bug. If a merge surfaces a conflict on one of these paths, take main's version unconditionally: the worktree's copy is wrong by construction, so the conflict signals an unauthorized write to investigate, not text to merge.

## Completion Gate

The orchestrator's primary output is the state file. Register it early so the completion gate can verify the orchestrator produced its mandatory output:

```bash
echo "[cycle-path]/execution/.orchestrator-state.md" > /tmp/.claude-agent-output-target
```

Run this registration command after resolving the workspace context (Step 0g) and before loading essentials (Step 1). The state file is updated after every agent dispatch and is the most critical output for intra-phase resume support.

## Startup

When invoked as `/orchestrator [feature-name|primitives] [resume|restart]`:

The first argument is either a feature name (matched against the `<name>` portion of slugs in ROADMAP) or the literal keyword `primitives`. The second argument is optional — `resume` or `restart`.

When invoked as `/orchestrator` (no arguments), proceed to **Step 0b: Work Discovery**.

### 0a. Parse Arguments

- arg1: `<feature-name>` | `primitives` | `bug fix` (reserved phrase; the variant `fix bug` is equivalent) | absent
- arg2: `resume` | `restart` | absent
- `resume` or `restart` without arg1 → error and stop.
- `restart` with `primitives` → error and stop (primitives is always a fresh today-dated invocation; nothing to restart).
- **`bug fix` / `fix bug`** is a reserved mode phrase, distinct from a feature-name or `primitives`. Everything after the phrase is an optional free-text bug description, not a feature name; arg2's `resume` / `restart` do not apply (bug-fix new-vs-resume is decided in § Bug-Fix Invocation). If arg1 is this phrase → go to § Bug-Fix Invocation.

### 0b. Work Discovery (no arg1)

Read `.project/product/ROADMAP.md`. Classify every `### <slug>` entry. **Exclude `Type=bugfix` entries from every tier** — bug fixes are surfaced only via an explicit `bug fix` invocation (§ Bug-Fix Invocation), never by no-argument work discovery.

1. Pick by priority tier: `in-progress` > `Type=feature, Status=completed, Scout-status=pending` > `planned`.
2. If multiple entries at the highest non-empty tier, present a table:
   ```
   Multiple [tier] entries — pick one:

   | # | Slug | Type | Status | Phase or Stage |
   ```
   For in-progress entries, `Phase or Stage` is read from `cycles-in-progress/<slug>.md`'s current-phase line. For pending refactor cycles, "pending".
3. Cross-check against `git worktree list`:
   - **Stale state** (picked in-progress entry has no worktree on disk): surface to user. "ROADMAP shows `<slug>` is in-progress but its worktree at `<expected-path>` doesn't exist. Run `/abandon-feature <cycle-slug>` to clean up, then re-run." Stop.
   - **Orphan worktree** (worktrees on disk not matching any ROADMAP entry): append soft warning to the discovery output. Do not block.
4. Set arg1 to the picked entry's feature-name portion (and arg2 to `resume` if the entry is in-progress) and continue to Step 0d. If the picked entry is a primitives slug, jump to Step 0c instead.

### 0c. Primitives Invocation

If arg1 is `primitives`:
- Construct slug: `<today-DD-MM-YYYY>-primitives`.
- Read ROADMAP for an entry at this slug:
  - Absent → fresh primitives start. Set `flow: primitives-pre-curate`, `slug: <constructed>`. Resolve the active milestone: read ROADMAP for the in-progress `## Milestone: <version>` section; if none or several are in-progress, ask the user which milestone this cycle belongs to. Retain as `milestone`. Proceed to Step 0f.
  - Status=in-progress → resume. Set `flow: primitives-resume`, `slug: <constructed>`; read `milestone` from the entry's containing `## Milestone:` section. Proceed to Step 0f.
  - Status=completed-pending-approval → surface: "Today's primitives cycle is awaiting `/accept-feature`." Stop.
  - Status=completed → surface: "Today's primitives cycle is complete." Stop.

### Bug-Fix Invocation (arg1 = `bug fix`)

Reached when arg1 is the reserved `bug fix` / `fix bug` phrase. The text after the phrase is an optional bug description. A bug fix never enters Step 0d, 0e, or the Step 0f start matrix — its intake is Stage 0 of `references/bugfix-loop.md`.

- **With a description** → start a new bug fix. Set `flow: bugfix-start`. Read `references/bugfix-loop.md` and execute **Stage 0** (slug derivation — shown to the user at intake; milestone resolution; worktree + branch; dependency setup; bug-report write + commit; `progress-tracker start`). Stage 0 leaves you `cd`'d into the new worktree; then register the Completion Gate and Load Essentials (Step 1) before continuing into Stage 1.
- **No description, an `in-progress` bugfix ROADMAP entry exists** → resume it. Set `flow: bugfix-resume`, `slug` = the entry's slug, `cycle_path = .project/cycles/<slug>/`, `milestone` from the entry's `## Milestone:` section. If several in-progress bugfix entries exist, present the multi-entry picker (slug, current Sub-Step from the tracking/state file). `cd .worktrees/<slug>/`, verify `git branch --show-current` is `<slug>`, register the Completion Gate, Load Essentials (Step 1), then run Step 2 (Intra-Phase Resume Detection) — the recorded `bugfix-*` Sub-Step routes the re-dispatch per `essentials/state-format.md`. **Never re-invoke `progress-tracker start`** for the same slug (a re-start returns `ERROR_ALREADY_IN_PROGRESS`).
- **No description, no in-progress bugfix entry** → "No bug description given and no in-progress bug fix to resume. Run `/orchestrator bug fix <description>` to start one." Stop.

`references/bugfix-loop.md` is read once when bug-fix work begins (the bugfix sibling of `core-loop.md`).

### 0d. Feature-Name Resolution

Read ROADMAP for entries that match arg1 by any of:

- the full slug exactly (e.g., `19-04-2026-pdf-extraction` or `19-04-2026-refactor-from-pdf-extraction`),
- the `<name>` portion of a feature slug (e.g., `pdf-extraction` matches `19-04-2026-pdf-extraction`),
- the `refactor-from-<parent-name>` portion of a refactor slug (e.g., `refactor-from-pdf-extraction` matches `19-04-2026-refactor-from-pdf-extraction`).

For features, slug = `<DD-MM-YYYY>-<name>`; the `<name>` portion is everything after the date prefix. For refactors, slug = `<DD-MM-YYYY>-refactor-from-<parent-name>`; the matchable portion is `refactor-from-<parent-name>`.

| Matches | Behavior |
|---|---|
| 0 | "No ROADMAP entry for `<arg1>`. If this is a new feature, run product-architect first." Stop. |
| 1 | Use that slug. |
| 2+ | Present a table (slug, Type, Status, Started). Ask user to pick. |

**If arg1 resolved directly to a `Type=refactor` entry** (full refactor slug or `refactor-from-<parent-name>` portion): the entry must be at `Status=in-progress` — set work item to `Resume refactor cycle` (`refactor-resume`). Any other Status returns the matching error from the table below (substituting "refactor cycle" for "feature"). Continue to Step 0e.

**Otherwise** (arg1 resolved to a `Type=feature` entry): also locate the derivative refactor entry for the resolved feature:

- `### <DD-MM-YYYY>-refactor-from-<parent-name>` — refactor entry

Determine the next work item by combining the feature's state with the derivative entry:

| Primary entry | Derivative | Work item | Flow |
|---|---|---|---|
| Type=feature, Status=planned | — | Start feature | standard-feature-start |
| Type=feature, Status=in-progress | — | Resume feature | standard-feature-resume |
| Type=feature, Status=completed-pending-approval | — | "Awaiting `/accept-feature <feature-name>`." Stop. | — |
| Type=feature, Status=completed, Scout-status=pending | — | Start refactor cycle | refactor-start |
| Type=feature, Status=completed, Scout-status=in-progress | refactor entry exists | Resume refactor cycle | refactor-resume |
| Type=feature, Status=completed, Scout-status=completed | — | "Refactor cycle complete for this feature." Stop. | — |
| Type=feature, Status=completed, Scout-status=empty-result | — | "Refactor cycle produced no actionable findings." Stop. | — |

For `refactor-resume`, the worktree leaf comes from the refactor entry's `Worktree:` field (resolved in Step 0f); the orchestrator does not derive it from the slug. For `refactor-start`, the leaf equals the refactor slug.

**Argument enforcement:**
- `resume`: the resolved work item must be a resume flow (any `-resume` flow above). If not, "resume specified but `<cycle-slug>` is not in-progress." Stop.
- `restart`: the resolved work item must be a resume flow. Invoke `/abandon-feature <cycle-slug>` via the Skill tool — the skill handles destructive-action confirmation, worktree destruction, branch deletion, and ROADMAP rollback. If the skill reports success, re-run Step 0d (the primary entry is now at `Status=planned`, or — for refactor cycles — the parent feature's Scout-status was restored to `pending`). If the skill reports cancelled or error, stop.

### 0e. Capture Slug, Flow, Milestone

- `slug`: the slug used for the branch + worktree leaf + tracking file (per the flow's mapping).
- `feature_slug`: the parent feature's slug (refactor flows only).
- `flow`: one of `standard-feature-start | standard-feature-resume | refactor-start | refactor-resume | primitives-pre-curate | primitives-resume` (the `bugfix-start | bugfix-resume` values are set in § Bug-Fix Invocation, which does not pass through this step).
- `milestone`: from the ROADMAP entry's containing `## Milestone: <version>` section heading.

Pre/post-curate position within a `refactor-*` flow is read from the in-progress refactor entry's `Stage:` line (`pre-curate | post-curate`) — set by `progress-tracker start` and mutated by the orchestrator at the transition. The flow value carries the start/resume distinction; the Stage line is the single source of truth for which half of the cycle is active.

### 0f. Workspace Setup

Resolve worktree leaf and feature path:

| Flow | Worktree leaf | Feature path |
|---|---|---|
| standard-feature-start | `<feature-slug>` | `.project/cycles/<feature-slug>/` |
| standard-feature-resume | leaf from feature entry's `Worktree:` field | `.project/cycles/<feature-slug>/` |
| refactor-start | `<refactor-slug>` | `.project/cycles/<refactor-slug>/` exists from scout-start — `pattern-analyst` creates `.project/cycles/<refactor-slug>/refactor-proposals/` at the Step 5 pre-curate dispatch; the `plans/` subtree is added at the pre-curate → post-curate transition |
| refactor-resume | leaf from refactor entry's `Worktree:` field | `.project/cycles/<refactor-slug>/` exists from scout-start (holds `refactor-proposals/`); the `plans/` subtree is present once `Stage=post-curate` |
| primitives-pre-curate | `<primitives-slug>` | `.project/cycles/<primitives-slug>/` exists from scout-start — `pattern-analyst` creates `.project/cycles/<primitives-slug>/refactor-proposals/` at the Step 5 pre-curate dispatch |
| primitives-resume | leaf from primitives entry's `Worktree:` field | `.project/cycles/<primitives-slug>/` exists from scout-start (holds `refactor-proposals/`); the `plans/` subtree is present once the post-curate sub-flow has run |

**Resume flows (worktree expected to exist):**
1. Verify worktree present: check `.worktrees/<leaf>/` exists.
2. `cd .worktrees/<leaf>/`.
3. Verify branch: `git branch --show-current` returns the slug used for the branch (= worktree leaf's slug).

**Start flows (worktree to be created):**
1. Verify `.worktrees/` is gitignored: `git check-ignore -q .worktrees`. If not, add `.worktrees/` to `.gitignore` and commit it via the `commit-to-git` skill (invoke it with the Skill tool), passing `Agent: orchestrator`, subject `chore: gitignore .worktrees/`, and `.gitignore` as the only path argument. The commit happens before `cd` into the worktree, so `commit-to-git`'s dual-context rule places it main-side automatically.
2. Spawn the worktree on a slug-named branch:
   ```
   git worktree add -b <slug> .worktrees/<leaf>/ origin/main
   ```
3. `cd .worktrees/<leaf>/`.
4. Dispatch `progress-tracker` in `start` mode per the matrix below:

   | Start flow | `worktree-type` | `worktree` | `roadmap-action` | `parent-feature` | `total-phases` | `milestone` |
   |---|---|---|---|---|---|---|
   | standard-feature-start | feature | `.worktrees/<feature-slug>/` | auto | — | 0 (set later in Step 4 once plan exists) | feature's milestone |
   | refactor-start | refactor | `.worktrees/<refactor-slug>/` | auto | `<feature-slug>` | 0 | parent feature's milestone |
   | primitives-pre-curate | primitives | `.worktrees/<primitives-slug>/` | auto | — | 0 | active milestone (resolved at Step 0c) |

5. On `progress-tracker start` failure: run `git worktree remove --force .worktrees/<leaf>/` then `git branch -D <slug>` to undo the worktree. Report failure and stop.
6. Setup worktree dependencies:
   - `cd backend && pnpm install`
   - `cd backend && pnpm exec prisma generate`
   - `cd frontend && pnpm install`
   - Copy `.env` files from main repo:
     - `cp [main-repo-root]/backend/.env backend/.env` (if exists)
     - `cp [main-repo-root]/frontend/.env frontend/.env` (if exists)
   - Report: "Copied .env from main. Update if this feature needs different configuration."

### 0g. Record Context

Retain for the session:
- `workspace_path`: absolute path to the worktree root
- `main_repo_root`: absolute path to the main repo (captured at startup from the CWD, before the Step 0f `cd` into the worktree)
- `pipeline_root`: absolute path to the pipeline install root, derived from `main_repo_root` (see below)
- `flow`: from Step 0e
- `slug`: from Step 0e
- `feature_slug`: from Step 0e (refactor only)
- `cycle_path`: from Step 0f
- `milestone`: from Step 0e

**Pipeline Root derivation.** The pipeline is installed either inside the project (project-level, vendored into `<project>/.claude/`) or in the user's home directory (user-level). A dispatched agent reads its `.claude/...` references against this root, never against the worktree (see § Dispatch Discipline). Derive it once here from the absolute `main_repo_root` — the absolute form makes the test independent of the current CWD:
- If `<main_repo_root>/.claude/skills/orchestrator/SKILL.md` exists (`test -f`) → **project-level** install → `pipeline_root = <main_repo_root>` (so a dispatched agent's `.claude/...` → `<main_repo_root>/.claude/...`).
- Else → **user-level** install → `pipeline_root = $HOME` (so a dispatched agent's `.claude/...` resolves under the home directory).

This single mechanism covers both install modes and reuses `main_repo_root` with no new plumbing. `pipeline_root` is handed to every dispatched agent via the Dispatch Discipline footer's **Pipeline Root** line.

### 1. Load Essentials

Read before proceeding:
- `essentials/orchestrator-boundaries.md` — operational boundaries, allowed reads, message validation
- `essentials/state-format.md` — state file template, resume behavior by sub-step

### 2. Intra-Phase Resume Detection

The macro decision ("which feature, which sub-flow, which phase") came from Step 0. This step recovers fine-grained intra-phase position from the worktree-local state file.

Must run from workspace CWD (Step 0f). State files live inside the worktree. Always Read state file before Write.

1. Glob for `[cycle-path]/execution/.orchestrator-state.md`.
2. Glob for phase summaries: `[cycle-path]/execution/state/phase-summaries/phase-*-summary.md`.

**State file found:**
- Read it. Cross-verify the recorded `Workspace` matches Step 0g's `workspace_path`. On mismatch, halt and surface both paths.
- Resume from the recorded `Sub-Step`. The current phase on a resumed phase comes from the state file, not from cycles-in-progress (which records the last-confirmed-complete phase boundary).

**State file not found:**
- Fresh start within this flow. Initialize the state file with `Sub-Step: workspace-selection` and current overview fields from Step 0g.

For refactor and primitives pre-curate stages where the tracking file doesn't yet enumerate phases, the state file's sub-step encodes the pre-curate position via the active `pattern-analyst` mode (`divergence-scout | convergence-scout | primitives-scout | pattern-audit | curate`).

### 3. Plan Resolution

The plan file for this flow:
- standard-feature-* → `[cycle-path]/plans/implementation-plan.md`
- refactor-resume with refactor entry's `Stage=post-curate` → `[cycle-path]/plans/refactor-plan.md`
- primitives-resume (post-curate sub-flow active) → `[cycle-path]/plans/refactor-plan.md`
- refactor-start, refactor-resume with `Stage=pre-curate`, and primitives-pre-curate → no plan applies; skip to Step 5 (pre-curate dispatch).

Check if the plan file exists.

**Plan exists** → proceed to Step 4, then Step 6 (read plan header).

**Plan missing** (standard-feature-start only):

Verify specs:
- Glob for `[cycle-path]/specs/SRS.md`
- Glob for `[cycle-path]/specs/SDD.md`
- Glob for `[cycle-path]/specs/bdd/*.feature`

If any spec is missing → report error and stop:
```
No implementation plan or specs found at [cycle-path].
Expected: plans/implementation-plan.md, or specs/ with SRS.md, SDD.md, and bdd/*.feature files.
```

If specs are present → run the gated plan-creation sequence. Two audit gates: the **draft gate** catches verb / concern / metadata / sizing / path defects at the layer where they are fixable, and the **final gate** catches reuse-directive and faithfulness defects the draft cannot carry.

> **Plan-architect ERROR guard.** If any `plan-architect` create/update dispatch in the gates below (or the refactor-plan dispatch) returns `Status: ERROR` — e.g., `TECH_NOT_IN_CHARTER` — stop the gate immediately: do not dispatch `plan-auditor` (no plan was written) and do not retry. Route per [references/recovery-paths.md](references/recovery-paths.md) § Plan-Architect ERROR — TECH_NOT_IN_CHARTER and wait for the user.

**Draft gate.**

1. Dispatch `plan-architect`:
   ```
   Mode: create
   Target: feature-draft
   Cycle: <cycle-slug>
   Cycle Path: <cycle-path>
   ```
2. Dispatch `plan-auditor`:
   ```
   Plan Path: <cycle-path>/plans/implementation-plan-draft.md
   Target: feature-draft
   Mode: full-audit
   ```
3. If INVALID (cap at 3 total draft audits — 1 original + up to 2 updates):
   - Dispatch `plan-architect` with `Mode: update, Target: feature-draft` and the audit findings. Header / verb / metadata fixes are legal here — the draft is freely editable; only the final is constrained to copy it.
   - Re-dispatch `plan-auditor` (`Target: feature-draft`).
   - On the 3rd INVALID → escalate to user with cumulative findings.

**Final gate** (only once the draft is VALID).

4. Dispatch `plan-architect`:
   ```
   Mode: create
   Target: feature-final
   Cycle: <cycle-slug>
   Cycle Path: <cycle-path>
   ```
5. Dispatch `plan-auditor`:
   ```
   Plan Path: <cycle-path>/plans/implementation-plan.md
   Target: feature-final
   Mode: full-audit
   ```
6. If VALID → proceed to Step 4.
7. If INVALID (cap at 3 total final audits — 1 original + up to 2 updates):
   - Dispatch `plan-architect` with `Mode: update, Target: feature-final` and the audit findings. Final-gate findings are reuse-directive or faithfulness issues; a `DRAFT_TASK_REWRITTEN` / `DRAFT_METADATA_CHANGED` here means the final diverged from the clean draft — the update re-copies the draft and re-applies directives rather than hand-editing headers.
   - Re-dispatch `plan-auditor` (`Target: feature-final`).
   - On the 3rd INVALID → escalate to user with cumulative findings.

**Refactor-plan dispatch** (refactor-resume with `Stage=post-curate`, and primitives post-curate sub-flow):

1. Dispatch `plan-architect` with `Mode: create, Target: refactor-plan`.
2. Dispatch `plan-auditor` with `Target: refactor-plan, Mode: full-audit`.
3. INVALID handling: same 3-attempt cap.

### 4. Plan Bookkeeping

`plan-architect` and `plan-auditor` self-commit their own artifacts (plan files and audit reports) as they produce them — no plan commit happens here.

For a standard-feature plan, compute `total-phases` = count of `## Phase` headings in the plan file. Dispatch `progress-tracker update`:
```
Mode: update
Slug: <slug>
Field: total-phases
Value: <N>
```

### 5. Pre-Curate Dispatch (refactor-start and primitives-pre-curate only)

This step replaces Steps 3–4 for the pre-curate sub-flows.

**Refactor pre-curate stage (in order):**

1. Dispatch `pattern-analyst` with `Mode: divergence-scout, Slug: <refactor-slug>`. Writes `.project/cycles/<refactor-slug>/refactor-proposals/pattern-findings-divergence.md`. Bootstraps `inventory-utils.ts`.
2. Dispatch `pattern-analyst` with `Mode: convergence-scout, Slug: <refactor-slug>`. Reads the bootstrapped inventory (read-only). Writes `.project/cycles/<refactor-slug>/refactor-proposals/pattern-findings-convergence.md`. Bootstraps `find-call-sites.ts`. Order matters here: divergence-scout runs first because it bootstraps `inventory-utils.ts`, which convergence-scout reads.
3. Dispatch `pattern-analyst-auditor` with `Slug: <refactor-slug>`. Writes `.project/cycles/<refactor-slug>/refactor-proposals/pattern-audit.md`.
4. Dispatch `pattern-analyst` with `Mode: curate, Slug: <refactor-slug>`. Writes `.project/cycles/<refactor-slug>/refactor-proposals/pattern-approved.md`. Returns status.
5. Branch on status:
   - **`NO_PROPOSALS_APPROVED`**: invoke the `commit-to-git` skill (Skill tool) with `Agent: orchestrator`, subject `refactor(<refactor-slug>): no proposals close-out`, and the findings + audit + approved + `-original.md` archive paths path-scoped. Then dispatch `progress-tracker` in `ship` mode with `Slug: <refactor-slug>` to flip the refactor entry's `Status` from `in-progress` to `completed-pending-approval` — the empty close-out is a completed refactor outcome, and the entry must reach the same lifecycle state as the approved close-out so resume safety and `/accept-feature`'s single-precondition contract hold. The `Stage: pre-curate` line is preserved (ship never touches Stage; it is removed by `progress-tracker close`); `/accept-feature` reads Stage to distinguish the empty close-out (`Stage: pre-curate`) from the approved close-out (`Stage: post-curate`). Hand back to user for `/accept-feature` (atomic merge; `progress-tracker close` sets parent's `Scout-status=empty-result`). Done.
   - **`APPROVED_PROPOSALS_EXIST`**: mutate the in-progress refactor entry's `Stage:` line in `<main_repo_root>/.project/product/ROADMAP.md` from `pre-curate` to `post-curate`. This is the single ROADMAP-write carve-out from `progress-tracker`'s exclusive ownership (see § ROADMAP and tracking-file discipline). Procedure:
     1. Acquire the ROADMAP mkdir-lock per `progress-tracker`'s ROADMAP write protocol: `mkdir <main_repo_root>/.project/product/.roadmap.lock.d`. On failure, retry with exponential backoff (0.1s, 0.2s, 0.4s, 0.8s, 1.6s, then 3s up to ~30s). On stale lock (> 2 min old, identified via `<lock-dir>/holder.txt`), force-clear and re-acquire. Write a holder line (`<ISO-timestamp>\t orchestrator \t <refactor-slug> \t $$`) to `<lock-dir>/holder.txt` after acquire.
     2. Read the ROADMAP, locate the `### <refactor-slug>` block, change its `- Stage: pre-curate` line to `- Stage: post-curate`, write back.
     3. Release the lock: `rmdir <main_repo_root>/.project/product/.roadmap.lock.d`. The release runs on every exit path — success, failure, or interrupted write.
     4. Commit main-side via the `commit-to-git` skill (Skill tool) with `Agent: orchestrator`, subject `refactor(<refactor-slug>): pre-curate → post-curate`, path `.project/product/ROADMAP.md`. The skill's main-side form handles `git -C <main_repo_root>` so the commit lands on main without changing the orchestrator's CWD.

     Then set `flow = refactor-resume`, `cycle_path = .project/cycles/<refactor-slug>/`. Continue to Step 3 (refactor-plan dispatch).

**Primitives pre-curate (in order):**

1. Dispatch `pattern-analyst` with `Mode: primitives-scout, Slug: <primitives-slug>`. Writes `.project/cycles/<primitives-slug>/refactor-proposals/pattern-findings.md`. Bootstraps `inventory-utils.ts` and `find-call-sites.ts`.
2. Dispatch `pattern-analyst-auditor` with `Slug: <primitives-slug>`. Writes `.project/cycles/<primitives-slug>/refactor-proposals/pattern-audit.md`.
3. Dispatch `pattern-analyst` with `Mode: curate, Slug: <primitives-slug>`. Writes `.project/cycles/<primitives-slug>/refactor-proposals/pattern-approved.md`. Returns status.
4. Branch on status:
   - **`NO_PROPOSALS_APPROVED`**: invoke the `commit-to-git` skill (Skill tool) with `Agent: orchestrator`, subject `primitives(<primitives-slug>): no proposals close-out`, and the findings + audit + approved + `-original.md` archive paths path-scoped. Then dispatch `progress-tracker` in `ship` mode with `Slug: <primitives-slug>` to flip the primitives entry's `Status` from `in-progress` to `completed-pending-approval` — the empty close-out is a completed primitives outcome, and the entry must reach the same lifecycle state as the approved close-out so `/accept-feature`'s single-precondition contract holds. Hand back to user for `/accept-feature`. Done.
   - **`APPROVED_PROPOSALS_EXIST`**: the `<primitives-slug>` ROADMAP entry already exists (created at pre-curate start), so no `progress-tracker start` runs here — the entry and tracking file are already in place. Mutate the in-progress primitives entry's `Stage:` line from `pre-curate` to `post-curate` main-side, using the **same mkdir-lock → read/locate/edit → release → commit procedure** as the refactor `APPROVED_PROPOSALS_EXIST` branch above (this is the single ROADMAP-write carve-out, now covering **refactor and primitives** — see § ROADMAP and tracking-file discipline). Commit main-side via the `commit-to-git` skill with `Agent: orchestrator`, subject `primitives(<primitives-slug>): pre-curate → post-curate`, path `.project/product/ROADMAP.md`. For primitives the `Stage:` field is informational only — it does not drive `close` (the `NO_PROPOSALS_APPROVED` branch leaves `Stage: pre-curate` unchanged; `close` removes it). Then set `cycle_path = .project/cycles/<primitives-slug>/` and continue to Step 3 (refactor-plan dispatch).

### 6. Read Plan Header

Read the plan file (`implementation-plan.md` or `refactor-plan.md`). Extract and retain:
- **Objective** — passed to every developer invocation
- **Phase list** — scan phase headings only: number, name, `Developer:` type, presence of `abstract-migration-phase` flag, presence of any `Concern: convention-doc` task. Do not read task details.

### 7. Present to User

If the plan has an **Open Questions** section with unresolved items, present them and wait for answers.

Report:
```
Cycle: <name>
Slug: <slug>
Flow: <flow>
Phases: <total-phases>
Branch: <slug>
Workspace: .worktrees/<leaf>
```

Wait for user confirmation to begin execution.

## Core Loop

Read [references/core-loop.md](references/core-loop.md) once, when beginning phase work. It is not re-read on subsequent phases — the loop is identical for every phase. The file contains the full step-by-step workflow:

| Step | Agent | Purpose |
|------|-------|---------|
| A | — | Read current phase from plan |
| B | developer | Implement phase tasks (non-convention-doc subset) |
| C | — | Route developer output (COMPLETED / PARTIAL / BLOCKED; NOTIFY deviations) |
| D | code-reviewer | PHASE_REVIEW or ABSTRACT_MIGRATION_REVIEW |
| E | — | Route code review (PASS → F, FAIL → diagnostic-routing.md) |
| F | plan-architect + plan-auditor | Create and validate test plan (standard feature flow only) |
| G | developer (test) + code-reviewer | Write tests, TEST_REVIEW (standard feature flow only) |
| H | test-runner → code-investigator | Execute tests, investigate every failure |
| I | state-manager | Curate phase summary and handoff (additive mode dispatch) |
| J | — | Report to user, wait for confirmation |
| K | — | Advance to next phase or Feature Completion |

Counter limits, escalation format, and counting rules are in [references/counters-and-escalation.md](references/counters-and-escalation.md). Recovery paths for non-COMPLETED developer statuses, PARTIAL continuation, and NOTIFY deviations are in [references/recovery-paths.md](references/recovery-paths.md). Code review failure routing is in [references/diagnostic-routing.md](references/diagnostic-routing.md). Investigation verdict routing is in [references/investigation-routing.md](references/investigation-routing.md).

**Refactor and primitives post-curate variant.** Steps F and G are skipped — refactor and primitives flows preserve behavior; no new BDD scenarios apply; existing tests cover correctness; `test-runner` runs solely to catch regression.

**Convention-doc-only phase.** If the current phase contains ONLY `Concern: convention-doc` tasks, skip Steps B, D, F, G, H entirely. Run only Step I (state-manager `refactor-curation` mode) followed by progress-tracker update.

## Feature Completion

After the last phase completes the full cycle (Steps B through J):

1. Capture the cycle-summary path from state-manager's `cycle-close` output (dispatched as part of Step I on the last phase per [references/core-loop.md](references/core-loop.md)). Dispatch `progress-tracker ship` to flip ROADMAP `Status` to `completed-pending-approval`.

2. Present optional reviews:
   ```
   Optional reviews:
   a) CYCLE_REVIEW — cross-phase code review (catches inconsistencies between phases that per-phase review misses)
   b) INTEGRATION_VERIFICATION — structural wiring check (catches orphan exports, unused imports, missing call-site updates)
   c) Skip reviews
   ```

3. If user approves **CYCLE_REVIEW**, dispatch `code-reviewer`:
   ```
   Reviewer Types: [all Developer Types from phase list]
   Cycle: <cycle-slug>
   Trigger: CYCLE_REVIEW
   Objective: [from plan header]
   Review Output Directory: <cycle-path>/execution/code-reviews/
   Review Attempt: 1
   Prior Review Paths: none
   Cycle Summary Path: <cycle-summary path from state-manager>
   ```

4. If user approves **INTEGRATION_VERIFICATION**, dispatch `code-reviewer`:
   ```
   Reviewer Types: [all Developer Types from phase list]
   Cycle: <cycle-slug>
   Trigger: INTEGRATION_VERIFICATION
   Objective: [from plan header]
   Review Output Directory: <cycle-path>/execution/code-reviews/
   Review Attempt: 1
   Prior Review Paths: none
   Plan Path: <cycle-path>/plans/implementation-plan.md  (or refactor-plan.md)
   Cycle Summary Path: <cycle-summary path from state-manager>
   ```

5. Hand back to user for `/accept-feature <cycle-slug>`. The skill handles atomic merge, post-merge verification, worktree removal, branch deletion, and the `progress-tracker close` dispatch.

## Bug-Fix Flow

`/orchestrator bug fix <description>` runs a root-cause-first fix for a bug already on `main` and owned by no in-flight feature — including bugs that surface as build/lint/type failures. It is a sibling of the feature flow with its own intake, triage, reproduce-&-diagnose, checkpoint, two-pass plan, and per-phase fix loop. Read [references/bugfix-loop.md](references/bugfix-loop.md) once when bug-fix work begins — it houses the full stage sequence and the per-scenario step mapping. Argument parsing and new-vs-resume routing are in § Bug-Fix Invocation.

What the orchestrator owns here:
- **The oracle is delegated — Rule 2 holds.** The orchestrator never runs a build/lint/test command. `code-investigator` (`STANDALONE_BUG`) is the tool-oracle (it runs the build/lint/type command in its own context) and `test-runner` (`Mode: reproduction`) is the behavioral oracle; the orchestrator routes their results. A `STANDALONE_BUG` investigation resolves to a severity verdict, a verdict + `Scenario-Reclassification` (cause re-routed to the other path), or **`CANNOT_REPRODUCE`** (no defect, no cause) — the last surfaces "cannot reproduce" to the user and parks the fix.
- **Counters.** `repro_attempts` (bugfix-only; cap 3) bounds the behavioral reproduce → RED-check cycle and is persisted in the state file so the cap survives a resume. The per-phase fix-loop counters (`impl_attempts`, etc.) are reused unchanged in Stage 3.
- **Green gates.** Behavioral: reproduction test flips RED→GREEN with the suite green (single-phase), or each `Reproduction-Confirmed` test stays a known-expected failure until its bug's phase with the final phase running `Mode: full-suite` (multi-phase). Tool-oracle: build/lint passes — test-runner runs once in `Mode: full-suite` only when the fix changed runtime logic.
- **No SRS/SDD/BDD check.** The bug report (`specs/bug-report.md`) is the flow's specification — do **not** run the feature flow's spec-presence gate, and do not attach cross-feature specs to the plan.
- **Milestone resolution at intake.** Stage 0 resolves the active milestone (or asks the user) and passes it to `progress-tracker start`.
- **Completion / teardown.** Identical to a feature: `progress-tracker ship`, then the user runs `/accept-feature <slug>`. A bug fix participates in milestone completion exactly like a feature.

Terminal/parked states — `repro_attempts` exhausted, an unresolved LEVEL_4 at the checkpoint, or `CANNOT_REPRODUCE` — keep the worktree and park `Phase-Status: blocked`; the user resumes with more detail (`/orchestrator bug fix`, no description) or runs `/abandon-feature <slug>`.

## Git Strategy

The orchestrator owns five commit points; every other artifact has its own committer.

1. **First-run gitignore commit (main-side, setup only).** If `.worktrees/` is not gitignored, add the line and commit `.gitignore` via the `commit-to-git` skill with `Agent: orchestrator`, subject `chore: gitignore .worktrees/`. Then spawn the worktree: `git worktree add -b <slug> .worktrees/<leaf>/ origin/main`. The slug serves as branch name, worktree leaf, and tracking-file name.
2. **Bug-report commit (worktree-side, bugfix intake only).** At Stage 0 of a bug fix, after writing and validating `<cycle-path>/specs/bug-report.md`, commit it path-scoped via the `commit-to-git` skill with `Agent: orchestrator`, subject `bugfix(<slug>): bug report`, path `specs/bug-report.md`. The bug report is an orchestrator-authored artifact (writer == committer), and committing it at intake is what lands it on main through the accept-time `--no-ff` merge — no downstream path-scoped commit would sweep it up. Idempotent under resume: `commit-to-git` reports `Commit: skipped` when re-entering intake reproduces identical content.
3. **Phase start.** Capture `phase_start_commit` via `git rev-parse HEAD`. No commit at phase start; this is just a baseline hash for the developer's revert path.
4. **Per-phase orchestration-summary commit (worktree-side).** At the end of Step I, after writing `<cycle-path>/execution/orchestration-summaries/phase-[N]-orchestration-summary.md`, commit it path-scoped via the `commit-to-git` skill with `Agent: orchestrator`, subject `orchestration(<slug>): phase <N> summary`. This is the only artifact the orchestrator commits during phase execution.
5. **Pre-curate artifact-bundle commit (worktree-side, refactor/primitives flows only).** On `pattern-analyst` curate returning `NO_PROPOSALS_APPROVED`, commit the findings + audit + approved + `-original.md` archives path-scoped via the `commit-to-git` skill with `Agent: orchestrator` — subject `refactor(<refactor-slug>): no proposals close-out` for the refactor pre-curate stage, `primitives(<primitives-slug>): no proposals close-out` for primitives pre-curate.
6. **Pre-curate → post-curate ROADMAP commit (main-side, refactor and primitives flows).** On `pattern-analyst` curate returning `APPROVED_PROPOSALS_EXIST` (see Step 5), commit the ROADMAP `Stage:` mutation main-side via the `commit-to-git` skill with `Agent: orchestrator`, subject `refactor(<refactor-slug>): pre-curate → post-curate` (refactor) or `primitives(<primitives-slug>): pre-curate → post-curate` (primitives), path `.project/product/ROADMAP.md`. This is the single ROADMAP write the orchestrator commits — the carve-out from `progress-tracker`'s exclusive ROADMAP ownership; every other ROADMAP write is committed by `progress-tracker`.
7. **Everything else commits via its own writer.** Developers commit code to the slug-named branch; `plan-architect` and `plan-auditor` commit plan files and audit reports; `code-reviewer` commits reviews; `test-runner` commits results; `code-investigator` commits investigations; `state-manager` commits summaries, handoffs, and the execution-index; `pattern-analyst` and `pattern-analyst-auditor` commit refactor-proposal artifacts; `progress-tracker` commits `ROADMAP.md` and tracking files main-side. The orchestrator never commits on behalf of another agent — writer == committer everywhere outside the owned commit points above.
8. **Revert (when needed).** Delegated to the developer via `Reset To Commit: <phase_start_commit>` — used in PARTIAL/BLOCKED recovery flows when the user chooses to discard partial work. The developer's revert is code-scoped: code returns to `<phase_start_commit>`, while committed `.project/**` artifacts (including the orchestration-summary committed earlier this phase) survive.
9. **Interrupted-commit recovery.** When a dispatched committing subagent returns without a `Commit:` field — or fails to return at all — re-dispatch the same invocation. Each committing subagent's write+commit workflow is idempotent. See `essentials/orchestrator-boundaries.md` § Message Validation Protocol for the full rule.
10. **Completion.** Hand back to user for `/accept-feature <cycle-slug>`. The skill handles merge into main, post-merge verification, worktree removal, and branch deletion.
