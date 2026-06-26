# Mode: cycle-close

Last-phase rollup. Invoked once per feature, after ALL per-phase state-manager dispatches for the last phase have returned (both `cycle-phase` and, when applicable, `refactor-curation`) and before `/accept-feature` runs.

The trigger is "last phase's per-phase work complete" — not "cycle-phase returned" — so convention-doc-dominated last phases still produce `cycle-summary.md`.

## Inputs (from caller)

```
Mode: cycle-close
Cycle: <cycle-slug>
Cycle Path: .project/cycles/<cycle>/
Total Phases: <N>
Plan Path: <path to implementation-plan.md>
Cycle Review Path: <path to .project/cycles/<cycle>/execution/code-reviews/cycle-review.md, or "none">
```

## Writes

- `.project/cycles/<cycle>/execution/state/cycle-summary.md` — concise rollup: features delivered, artifacts produced, deferred items, accumulated testing statistics.

## Workflow

1. **Read execution-index** — `.project/cycles/<cycle>/execution/state/execution-index.md`. This is the source of truth for what exists; do not glob.

2. **Register output path** — Bash: `echo ".project/cycles/<cycle>/execution/state/cycle-summary.md" > /tmp/.claude-agent-output-target`.

3. **Normalize the cycle-summary file to a known state.** Handles the case where a prior dispatch wrote the file but crashed before committing. Run via Bash, substituting the actual path:

   ```
   if [ -f ".project/cycles/<cycle>/execution/state/cycle-summary.md" ]; then
     if git ls-files --error-unmatch ".project/cycles/<cycle>/execution/state/cycle-summary.md" >/dev/null 2>&1; then
       git checkout HEAD -- ".project/cycles/<cycle>/execution/state/cycle-summary.md"
     else
       rm -f ".project/cycles/<cycle>/execution/state/cycle-summary.md"
     fi
   fi
   ```

   - File doesn't exist → no-op.
   - File tracked at HEAD → discards uncommitted changes; the previously-committed content survives.
   - File untracked → `rm` removes the orphan from a crashed prior write.

4. **Read all phase summaries** — every `state/phase-summaries/phase-<N>-summary.md` enumerated in the execution-index (skip `phase-<N>-failed-summary.md` files; they are referenced for the re-execution roll-up but do not feed the canonical summary content).

5. **Read final code-review** — if `Cycle Review Path` is not "none", Read it. Otherwise skip.

6. **Read final test-results** — locate via execution-index entries' `Test results:` field.

7. **Write `cycle-summary.md`** using the cycle-summary template in `essentials/templates.md`. Consolidate:
   - What was built (2–3 paragraphs).
   - All files created/modified across phases.
   - Schema changes (consolidated).
   - Key architectural decisions (consolidated, with phase attribution).
   - Public API surface (exports, endpoints, components).
   - Dependencies installed (consolidated).
   - Plan corrections (consolidated; explicitly mark "None — plan followed exactly" when applicable).
   - Testing summary (accumulated statistics).
   - Execution statistics (first-pass code-review PASS rate, BLOCKED events, handoff rebuilds, escalations).

8. **Do NOT generate a handoff.** The feature is closing.

9. **Commit the cycle-summary.** Read `.claude/skills/commit-to-git/SKILL.md` and follow it to commit the cycle-summary file path-scoped. Pass:

   - `Agent: state-manager`
   - `Subject: state(<slug>): feature close`
   - `Path:` `.project/cycles/<cycle>/execution/state/cycle-summary.md`

   Where `<slug>` is the basename of the feature directory from the input's `Cycle Path`. The subject drops the `phase <N>` segment because this mode is feature-wide, not per-phase.

   Commit nothing else. One commit per invocation. Capture the resulting short hash for the return. If the commit produced no change (the normalized file matched HEAD and the fresh write reproduced it byte-for-byte), record `skipped`. If the commit fails, record `failed` and surface it in the return.

## Output

```
Status: SUCCESS
Mode: cycle-close
Cycle Summary: <path to cycle-summary.md>
Commit: <short-hash> | skipped | failed
```

`Commit:` semantics are documented in `state-manager.md` Output Format Conventions.
