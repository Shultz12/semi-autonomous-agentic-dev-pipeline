# State File Format

## State File

**Path:** `[cycle-path]/execution/.orchestrator-state.md` (git-ignored)

**Update after:** every agent output, user confirmation, escalation, checkpoint.

```markdown
# Orchestrator State

## Overview

- **Cycle:** [name]
- **Slug:** [slug]
- **Feature Slug:** [parent feature's slug, for refactor flows; otherwise "N/A"]
- **Flow:** [standard-feature-start | standard-feature-resume | refactor-start | refactor-resume | primitives-pre-curate | primitives-resume | bugfix-start | bugfix-resume]
- **Milestone:** [version, e.g., v1.2]
- **Branch:** [slug]
- **Plan:** [path or "pending" for pre-curate stages]
- **Workspace:** worktree
- **Worktree Path:** [absolute path]
- **Main Repo Root:** [absolute path]
- **Pipeline Root:** [absolute path — pipeline install root handed to every dispatch footer; re-derivable from Main Repo Root per SKILL.md Step 0g § Pipeline Root derivation]
- **Total Phases:** [N or "0" for pre-curate stages]
- **Current Phase:** [N or "—" for pre-curate stages]
- **Sub-Step:** [see Sub-Step Values below]
- **Phase Status:** [in-progress | awaiting-user-confirmation | escalated | checkpoint]
- **Phase Start Commit:** [hash or "—" for pre-curate stages]
- **Resumed:** [true | false]

## Counters

| Counter | Value |
|---|---|
| Implementation Attempts | [N] |
| Test Writing Attempts | [N] |
| CODE_BUG Fixes | [N] |
| TEST_BUG Fixes | [N] |
| Handoff Rebuilds | [N] |
| Partial Continuations | [N] |
| Reproduction Attempts | [N — bug fix Stage 1 only] |

## Last Action

- **Action:** [e.g., "developer spawned", "code-reviewer PASS", "test-runner FAIL"]
- **Last Handoff:** [path to current handoff.md or "—"]

## Report Paths

| Report | Path |
|---|---|
| Developer Report | [path or "pending"] |
| Code Reviews | [list of paths or "pending"] |
| Test Plan | [path or "pending"] |
| Test Report | [path or "pending"] |
| Test Reviews | [list of paths or "pending"] |
| Test Results | [path or "pending"] |

### Investigations

- [path or "none"]
```

`Reproduction Attempts` (`repro_attempts`) is the bugfix-only Stage 1 counter (cap 3). Unlike the per-phase counters, it is not reset per phase — it spans the reproduce-&-diagnose stage and is persisted here so the cap survives a resume. For non-bugfix flows it stays `0`.

## Sub-Step Values

The bugfix flow uses `bugfix-*` Sub-Step values. Each maps 1:1 to a stage of the bugfix flow (see `references/bugfix-loop.md`). The underlying resume logic for each often mirrors a feature-flow Sub-Step; the distinct naming is for readability — a state file at `Sub-Step: bugfix-investigate` is immediately recognizable as a bugfix-flow investigation, not a feature-flow one.

| Sub-step | Context |
|---|---|
| `workspace-selection` | Workspace resolution and progress-tracker start dispatch |
| `divergence-scout` | refactor pre-curate stage; pattern-analyst divergence-scout dispatch |
| `convergence-scout` | refactor pre-curate stage; pattern-analyst convergence-scout dispatch |
| `primitives-scout` | primitives pre-curate; pattern-analyst primitives-scout dispatch |
| `pattern-audit` | refactor/primitives pre-curate; pattern-analyst-auditor dispatch |
| `curate` | refactor/primitives pre-curate; pattern-analyst curate dispatch |
| `plan-creation` | plan-architect (draft, final) + plan-auditor sequence; agents self-commit their artifacts |
| `implementation` | developer dispatch for the current phase |
| `implementation-review` | code-reviewer PHASE_REVIEW or ABSTRACT_MIGRATION_REVIEW |
| `test-planning` | plan-architect test-plan creation |
| `test-plan-validation` | plan-auditor on test plan |
| `test-writing` | developer (test) dispatch |
| `test-review` | code-reviewer TEST_REVIEW |
| `test-execution` | test-runner |
| `investigation` | code-investigator |
| `awaiting-user` | awaiting user decision (BLOCKED, LEVEL_3, LEVEL_4, ACCEPTED_FAILURE, NOTIFY routing) |
| `state-curation` | state-manager dispatch (cycle-phase or cycle-close) |
| `convention-curation` | state-manager refactor-curation dispatch (convention-doc tasks) |
| `progress-update` | progress-tracker update dispatch |
| `feature-completion` | feature-completion handoff + optional reviews |
| `bugfix-intake` | Bugfix Stage 0: worktree + branch creation, bug-report write + commit, milestone resolution, progress-tracker start dispatch |
| `bugfix-reproduce` | Bugfix Stage 1: plan-architect (`bugfix-reproduction`), plan-auditor, developer (test), code-reviewer (`TEST_REVIEW`), test-runner (`Mode: reproduction`) — the reproduce activity |
| `bugfix-investigate` | Bugfix Stage 1 (continuation): code-investigator (`STANDALONE_BUG`) dispatch — same shape as `investigation`, distinct trigger |
| `bugfix-checkpoint` | Bugfix Stage 1 (terminal): LEVEL_3 / LEVEL_4 / MEDIUM-confidence routing to the user; resolution-mode dispatch — same shape as `awaiting-user`, distinct context |
| `bugfix-plan` | Bugfix Stage 2: plan-architect (`bugfix-draft` and `bugfix-final`) + plan-auditor on each pass — same shape as `plan-creation`, distinct targets |
| `bugfix-fix-phase` | Bugfix Stage 3: per-phase developer (fix from investigation) + code-reviewer (PHASE_REVIEW + bugfix overlay) + test-runner — same shape as `implementation` + `implementation-review` + `test-execution` per phase |

## Resume Behavior by Sub-Step

| Sub-step | Resume behavior |
|---|---|
| `workspace-selection` | Re-resolve workspace; cd into correct worktree |
| `divergence-scout` | Re-dispatch pattern-analyst (divergence-scout mode) |
| `convergence-scout` | Re-dispatch pattern-analyst (convergence-scout mode) |
| `primitives-scout` | Re-dispatch pattern-analyst (primitives-scout mode) |
| `pattern-audit` | Re-dispatch pattern-analyst-auditor |
| `curate` | Re-dispatch pattern-analyst (curate mode) |
| `plan-creation` | Re-dispatch plan-architect/plan-auditor (continuing from where the sequence stopped) |
| `implementation` | Re-dispatch developer (with `Resume: true` if partial work exists) |
| `implementation-review` | Glob for `phase-[N]-code-review-attempt-*.md` (or `phase-[N]-abstract-migration-review-attempt-*.md`) to reconstruct `Prior Review Paths`, then re-dispatch code-reviewer |
| `test-planning` | Re-dispatch plan-architect (test-plan mode) |
| `test-plan-validation` | Re-dispatch plan-auditor on test plan |
| `test-writing` | Re-dispatch developer (test, with `Resume: true` if partial work exists) |
| `test-review` | Glob for `phase-[N]-test-review-attempt-*.md` to reconstruct `Prior Review Paths`, then re-dispatch code-reviewer (TEST_REVIEW) |
| `test-execution` | Re-dispatch test-runner |
| `investigation` | Re-dispatch code-investigator |
| `awaiting-user` | Re-present the prompt to the user |
| `state-curation` | Re-dispatch state-manager (whichever mode was active) |
| `convention-curation` | Re-dispatch state-manager (refactor-curation mode) |
| `progress-update` | Re-dispatch progress-tracker (update mode) |
| `feature-completion` | Re-present optional-reviews prompt |
| `bugfix-intake` | Re-run Stage 0 idempotently — verify/create the worktree + branch, re-write and re-commit the bug report (`commit-to-git` reports `skipped` when unchanged), confirm the `progress-tracker start` entry exists; never re-`start` when the entry is already present |
| `bugfix-reproduce` | Re-enter the Stage 1 reproduce sequence from the recorded point: plan-architect (`bugfix-reproduction`) → plan-auditor → developer (test, `Resume: true` if partial work exists) → code-reviewer (`TEST_REVIEW`, reconstruct `Prior Review Paths` by globbing `phase-0-test-review-attempt-*.md`) → test-runner (`Mode: reproduction`). Honor the persisted `repro_attempts` |
| `bugfix-investigate` | Re-dispatch code-investigator with the `STANDALONE_BUG` trigger — same shape as `investigation` |
| `bugfix-checkpoint` | Re-present the checkpoint to the user — same shape as `awaiting-user`; on the user's decision, re-dispatch code-investigator resolution mode (`Phase: 0: bugfix-checkpoint`) |
| `bugfix-plan` | Re-dispatch plan-architect/plan-auditor continuing the two-pass sequence (`bugfix-draft` then `bugfix-final`) from where it stopped — same shape as `plan-creation` |
| `bugfix-fix-phase` | Re-dispatch the Stage 3 fix loop for the current phase — same shape as `implementation` / `implementation-review` / `test-execution`: re-dispatch developer (`Resume: true` if partial work exists, carrying the `Investigation File`), reconstruct prior review paths by globbing `phase-[N]-code-review-attempt-*.md`, then re-run test-runner per the phase's green gate |

On resume, read the state file, identify the sub-step, and re-enter the loop at that point. All persistent files (code reviews, test results, investigations) survive interruption. On resume, the orchestrator first `cd`s into the workspace recorded in the state file before reading any other paths.

## Resumed Flag

The `Resumed:` field signals whether the current orchestrator session inherited mid-phase work from a prior session. Used by Step I to conditionally mark the orchestration-summary as partial (see `references/orchestration-summary-format.md` § Resume Marker).

Initialization:
- On fresh orchestrator entry (no state file found, initialized with `Sub-Step: workspace-selection`) → `Resumed: false`.
- On orchestrator entry that finds an existing state file (intra-phase resume detection) → `Resumed: true`.

Reset:
- At every new phase's per-phase reset block (see `references/core-loop.md` § For each phase) → `Resumed: false`. The new phase's in-context accumulators start fresh, so the next Step I summary is complete and unmarked. A resume that crosses a phase boundary (e.g., orchestrator dies at sub-step `awaiting-user`, user runs `/orchestrator resume`, orchestrator advances to next phase) self-clears at that boundary.
