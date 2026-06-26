# Mode: cycle-phase

Per-phase distillation. Wraps the existing Normal Mode flow.

## Inputs (from caller)

```
Mode: cycle-phase
Cycle: <cycle-slug>
Cycle Path: .project/cycles/<cycle>/
Completed Phase: <N> of <total>
Plan Path: <path to implementation-plan.md>

Developer Report: <path to developer report file>
Code Reviews: <list of code review file paths, one per attempt>

Counters:
  Implementation Attempts: <N>
  Test Writing Attempts: <N>
  CODE_BUG Fixes: <N>
  TEST_BUG Fixes: <N>
  Handoff Rebuilds: <N>

Test Artifact Paths:
  Test Plan: <cycle-path>/plans/test-plans/phase-<N>-test-plan.md
  Test Report: <path to test developer report>
  Test Reviews: <list of test review file paths>
  Test Results: <cycle-path>/execution/test-results/phase-<N>-results.md
  Investigations: <list of investigation file paths, or "none">
```

**Re-Execution fields (present only when the phase was re-executed after Level 3 resolution):**

```
Re-Execution: true
Investigation Path: <path to Level 3 investigation file that caused re-execution>
```

## Writes

- `.project/cycles/<cycle>/execution/state/phase-summaries/phase-<N>-summary.md` — write-once archival.
- `.project/cycles/<cycle>/execution/state/phase-summaries/phase-<N>-failed-summary.md` — write-once, re-execution only.
- `.project/cycles/<cycle>/execution/state/execution-index.md` — append phase entry (or create on Phase 1).
- `.project/cycles/<cycle>/execution/state/handoffs-to-developer/handoff.md` — overwritten with residual-only content for phase N+1. Skipped on last phase.
- `.project/cycles/<cycle>/execution/state/handoffs-to-developer/archive/phase-<N>-handoff.md` — `mv` of the previous `handoff.md` before overwrite. On Phase 1, no previous `handoff.md` exists; the archive move is silently skipped.

## Workflow

Read files progressively — each step reads only what it needs.

1. **Read execution-index** — `.project/cycles/<cycle>/execution/state/execution-index.md`. If absent, this is Phase 1 (you will create it). If present, read to understand prior-phase outputs.

2. **Register output path** — Bash: `echo ".project/cycles/<cycle>/execution/state/phase-summaries/phase-<N>-summary.md" > /tmp/.claude-agent-output-target` (substitute feature and N from input).

3. **Read inputs** — read the developer report and all code-review files at the paths provided. Extract artifacts produced, files modified, deviations, and plan corrections. Use the latest code-review attempt's verdict as the canonical outcome; include findings from all attempts in the phase summary. Read the test developer report — extract test file paths from its `## Files Modified` section. Read the implementation plan to find the next phase's `depends_on` field and to determine whether this is the last phase.

4. **Normalize target files to a clean starting state.** Handles the case where a prior dispatch of this same invocation wrote one or more files but crashed before committing. Determine the file set this invocation will write:

   - Always: `state/phase-summaries/phase-<N>-summary.md`, `state/execution-index.md`.
   - When `Re-Execution: true`: also `state/phase-summaries/phase-<N>-failed-summary.md`.
   - When NOT the last phase: also `state/handoffs-to-developer/handoff.md` and `state/handoffs-to-developer/archive/phase-<N>-handoff.md`.

   For each path `P` in the set, run via Bash:

   ```
   if [ -f "<P>" ]; then
     if git ls-files --error-unmatch "<P>" >/dev/null 2>&1; then
       git checkout HEAD -- "<P>"
     else
       rm -f "<P>"
     fi
   fi
   ```

   - File doesn't exist → no-op (the common case for a new invocation).
   - File tracked at HEAD → `git checkout HEAD -- <path>` discards uncommitted changes; previously-committed content survives unchanged.
   - File untracked → `rm` removes the orphan from a crashed prior write (it was never in the audit trail).

5. **Re-execution handling** (only when `Re-Execution: true`):
   - Read the investigation file at `Investigation Path`.
   - Read the existing execution-index entry for this phase (from the failed attempt).
   - Write `state/phase-summaries/phase-<N>-failed-summary.md` using the failed-phase-summary template in `essentials/templates.md`, sourcing failure information from the investigation file.

6. **Write phase summary** — `state/phase-summaries/phase-<N>-summary.md` using the phase-summary template in `essentials/templates.md`. Create the `state/phase-summaries/` directory if it does not exist. Include all required sections: outcome, files created/modified, exports, schema changes, key decisions, dependencies, plan corrections, code review findings, testing. If the write fails (filesystem error, hook rejection), return `Status: ESCALATE` with `Reason: phase-summary-write-failed` and `Commit: none` — do not proceed to step 7, since the execution-index would point at a non-existent summary.

7. **Update execution-index** — append this phase's section to `state/execution-index.md` using the entry template in `essentials/templates.md`. Create the file with its header (template provides) if this is Phase 1. For re-executions, replace the prior phase section with the re-execution entry template, preserving the failed-attempt's removed-artifacts list. If the write fails after step 6 succeeded, return `Status: ESCALATE` with `Reason: execution-index-write-failed` and `Commit: none` — leaves the worktree in a recoverable state (phase summary exists uncommitted; the re-dispatch's normalize step in step 4 clears it and the retry produces a clean commit).

8. **Determine next step:**
   - If this is NOT the last phase → continue to step 9.
   - If this IS the last phase → skip to step 11 (commit the summary + index, then return; the orchestrator dispatches `cycle-close` after every per-phase state-manager dispatch for the last phase has returned).

9. **Archive previous handoff** — if `state/handoffs-to-developer/handoff.md` exists, Bash: `mv .project/cycles/<cycle>/execution/state/handoffs-to-developer/handoff.md .project/cycles/<cycle>/execution/state/handoffs-to-developer/archive/phase-<N>-handoff.md`. Create `state/handoffs-to-developer/archive/` if absent.

10. **Generate handoff** — write `state/handoffs-to-developer/handoff.md` for phase N+1. Create `state/handoffs-to-developer/` if absent. Steps:
    - Read the next phase's `depends_on` field from the plan.
    - Use the execution-index to locate the phase summaries that produced those dependencies.
    - Read those phase summaries.
    - Verify every file path you reference exists (Glob or Read). A non-existent path causes immediate BLOCKED from the next developer.
    - Exclude: code-review findings, attempt counts, rebuild counts, testing statistics.
    - Use the handoff template in `essentials/templates.md`. The base persona's residual-only content rule governs what to include.

11. **Commit the artifacts.** Read `.claude/skills/commit-to-git/SKILL.md` and follow it to commit every path written this invocation in one path-scoped commit. Pass:

    - `Agent: state-manager`
    - `Subject: state(<slug>): phase <N> summary`
    - `Path:` every path written by this invocation. The set depends on the flow:
      - Always include: `state/phase-summaries/phase-<N>-summary.md`, `state/execution-index.md`.
      - When `Re-Execution: true`: also include `state/phase-summaries/phase-<N>-failed-summary.md`.
      - When NOT the last phase: also include `state/handoffs-to-developer/handoff.md` AND `state/handoffs-to-developer/archive/phase-<N>-handoff.md` (naming both source and destination of the archive `mv` so git records the rename atomically as one commit).

    Where `<slug>` is the basename of the feature directory derived from the input's `Cycle Path` (the directory immediately under `.project/cycles/`), and `<N>` is the completed phase number.

    Commit nothing else. One commit per invocation. Capture the resulting short hash for the return. If the commit produced no change (the normalized files matched HEAD and the fresh writes reproduced them byte-for-byte), record `skipped`. If the commit fails (lock contention, hook rejection, transient error), record `failed` and surface it in the return — never report a success hash for a commit that did not happen.

    A failed commit must never block the return from happening; the artifacts are already written and the SubagentStop hook is satisfied.

## Output

**Intermediate phase:**

```
Status: SUCCESS
Mode: cycle-phase
Summary: <path to phase summary>
Handoff: <path to handoff>
Commit: <short-hash> | skipped | failed
```

**Last phase:**

```
Status: SUCCESS
Mode: cycle-phase
Summary: <path to phase summary>
Handoff: none
Commit: <short-hash> | skipped | failed
```

(The last-phase rollup is produced by a separate `cycle-close` dispatch.)

**Write failure:**

```
Status: ESCALATE
Mode: cycle-phase
Reason: phase-summary-write-failed | execution-index-write-failed
Commit: none
```

`Commit:` semantics are documented in `state-manager.md` Output Format Conventions.
