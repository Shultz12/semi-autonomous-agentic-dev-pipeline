# Mode: rebuild

Triggered when a developer reports `BLOCKED: handoff-insufficient`. Behavior preserved from the existing state-manager Rebuild Mode, with the archive filename suffix updated.

## Inputs (from caller)

```
Mode: rebuild
Cycle: <cycle-slug>
Cycle Path: .project/cycles/<cycle>/
Target Phase: <N — the phase the developer is trying to execute>
Developer Report: <path to developer report>
Rebuild Attempt: 1 | 2
```

The developer report's `## Problem Report` section names the missing context.

## Writes

- `.project/cycles/<cycle>/execution/state/handoffs-to-developer/handoff.md` — rewritten with the missing residual fact added. Built from source artifacts (phase summaries + execution-index), NEVER by rewriting the previous handoff.
- `.project/cycles/<cycle>/execution/state/handoffs-to-developer/archive/phase-<N>-rebuild-<M>-handoff.md` — `mv` of the previous `handoff.md` before overwrite. `M` is the rebuild attempt number.

## Workflow

1. **Read the developer report** at the path provided. Extract the BLOCKED complaint from `## Problem Report` to understand what is missing from the handoff.

2. **Register output path** — Bash: `echo ".project/cycles/<cycle>/execution/state/handoffs-to-developer/handoff.md" > /tmp/.claude-agent-output-target`.

3. **Normalize target files to a clean starting state.** Handles the case where a prior dispatch of this same rebuild attempt wrote one or more files but crashed before committing. The file set is:

   - `state/handoffs-to-developer/handoff.md`
   - `state/handoffs-to-developer/archive/phase-<N>-rebuild-<M>-handoff.md` (where `N` = target phase, `M` = rebuild attempt)

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

   - File doesn't exist → no-op.
   - File tracked at HEAD → discards uncommitted changes; previously-committed content survives.
   - File untracked → `rm` removes the orphan from a crashed prior write.

   After normalize, `state/handoffs-to-developer/handoff.md` is back to the pre-rebuild handoff content (the one that prompted the BLOCKED report) and the archive file (if a prior crashed dispatch had moved it) is gone — ready to re-do the `mv` cleanly.

4. **Read the execution-index** — find which phase produced the missing artifact.

5. **Read the relevant phase summary** — get the detail the developer needs.

6. **Archive current handoff** — Bash: `mv .project/cycles/<cycle>/execution/state/handoffs-to-developer/handoff.md .project/cycles/<cycle>/execution/state/handoffs-to-developer/archive/phase-<N>-rebuild-<M>-handoff.md` (substitute N = target phase, M = rebuild attempt number).

7. **Generate enriched handoff** — write a new `state/handoffs-to-developer/handoff.md` that includes the missing context sourced from the relevant phase summaries. Build from source. Set the handoff frontmatter's `rebuild:` field to `<M>` (this rebuild attempt number) per the Handoff Template in `essentials/templates.md` — a normal `cycle-phase` handoff carries `rebuild: false`.

8. **Commit the rebuild artifacts.** Read `.claude/skills/commit-to-git/SKILL.md` and follow it to commit both paths in one path-scoped commit. Pass:

   - `Agent: state-manager`
   - `Subject: state(<slug>): phase <N> rebuild <M>`
   - `Path:` `state/handoffs-to-developer/handoff.md` AND `state/handoffs-to-developer/archive/phase-<N>-rebuild-<M>-handoff.md` (naming both source and destination of the archive `mv` so git records the rename atomically as one commit).

   Where `<slug>` is the basename of the feature directory from the input's `Cycle Path`, `<N>` is the target phase, and `<M>` is the rebuild attempt number.

   Commit nothing else. One commit per invocation. Capture the resulting short hash for the return. If the commit produced no change (`skipped`) or fails (`failed`), record accordingly.

## Limit

Maximum 2 rebuild attempts per phase. On `Rebuild Attempt: 3` or higher, do not rewrite the handoff — the root cause is plan or spec, not handoff. Return:

```
Status: ESCALATE
Mode: rebuild
Reason: rebuild-attempt-limit-exceeded
Commit: none
```

## Output (success)

```
Status: SUCCESS
Mode: rebuild
Handoff: <path to enriched handoff>
Commit: <short-hash> | skipped | failed
```

`Commit:` semantics are documented in `state-manager.md` Output Format Conventions.
