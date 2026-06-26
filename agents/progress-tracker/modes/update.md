# Mode: `update`

**CWD:** Worktree. **Touches:** tracking file only. **Does NOT touch ROADMAP.**

## Input

```
Mode: update
Slug: <slug>
Phase: <N>
Phase-Name: <name>
Phase-Status: <completed | blocked | checkpoint | in-progress>
Phase-Started: <ISO-timestamp>
Phase-Completed: <ISO-timestamp | "—">
```

For Worktree-Types where the tracking file was created without a plan (refactor pre-curate; primitives pre-curate), the caller may pass `Phase: 0` and `Phase-Name: <stage name>` (e.g., `"divergence-scout"`, `"convergence-scout"`, `"auditor"`, `"curate"` — pattern-analyst mode names, which describe the analyst's activity, not slug naming); the Phase history table records stages identically to phases.

## Steps

1. Resolve main-root via `git worktree list --porcelain`.
2. Register output path (Completion Gate):
   ```bash
   echo "<main-root>/.project/product/cycles-in-progress/<slug>.md" > /tmp/.claude-agent-output-target
   ```
3. Read `<main-root>/.project/product/cycles-in-progress/<slug>.md`. If absent → `Status: ERROR` with `Warnings: [tracking-file-missing]`. Indicates `start` was never called or was rolled back.
4. **Idempotent row update** (rerunning with the same `Phase: N` overwrites in place rather than appending):
   - If a row for Phase `<N>` already exists in the Phase history table → overwrite in place.
   - Else → append a new row.
5. Update the **Current state** block: `Phase: <N>` (preserve `of <M>` from the existing header line if present), `Phase-Name`, `Phase-Status`, current ISO timestamp as `Last updated`.
6. Write back.
7. Commit per the `commit-to-git` skill (`Agent: progress-tracker`), subject `progress: phase <N> complete — <slug> [<phase-name>]`, path `.project/product/cycles-in-progress/<slug>.md`.
8. Return.

## Error conditions

- `tracking-file-missing` — tracking file not present on main. Return `Status: ERROR`.
